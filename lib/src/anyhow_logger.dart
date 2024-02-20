import 'dart:convert';
import 'dart:math';

import 'package:anyhow/anyhow.dart' as anyhow;
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'ansi_color.dart';
import 'level.dart';
import 'logging_config.dart';
import 'output/console_output.dart';
import 'output/output.dart';
import 'printer.dart';

/// FORMAT:
/// Object Type
/// Stringified || Stringified Override
/// Appended Message || None
/// Log Id || None
/// Time || None
/// Log-Point StackTrace
/// Object's StackTrace || None
class Log {
  Log._();

  static late Printer _printer;
  static Level? _levelValue;
  static bool _willCreateLogId = true;
  static final uuid = Uuid();
  static DateTime Function()? _timeFn;
  static LoggingConfig? _prodLoggingConfig;
  static LoggingConfig? _devLoggingConfig;
  static late StackTrace Function(StackTrace) _stackTraceModifier;
  static late LogOutput _output;
  static void Function({List<Entry> entries, Level level, String? id})? _onLog;
  static late int _numberOfFramesToKeep;
  static late bool _willCreateStackTraceForLogPoint;

  //************************************************************************//

  /// If called, will set up prod logging with the provided parameters. If not called, it will be called with defaults when run in debug mode.
  static setDevLoggingConfig([LoggingConfig devLoggingConfig = const LoggingConfig.devImpl()]) {
    _devLoggingConfig = devLoggingConfig;
  }

  /// If called, will set up prod logging with the provided parameters. If not called, it will be called with defaults when not run in non-debug mode.
  static setProdLoggingConfig([LoggingConfig prodLoggingConfig = const LoggingConfig.prodImpl()]) {
    _prodLoggingConfig = prodLoggingConfig;
  }

  /// If called, will set up all logging with the provided parameters. If not called, [LoggingConfig.devImpl] is
  /// used in debug mode if [setDevLoggingConfig] is not called.
  /// And [LoggingConfig.prodImpl] is used when in non-debug mode if [setProdLoggingConfig] is not called.
  static setLoggingConfig(LoggingConfig loggingConfig) {
    _levelValue = loggingConfig.level;
    _willCreateLogId = loggingConfig.willCreateLogId;
    _stackTraceModifier = (s) =>
        _modifyStackTrace(s, numberOfFramesToKeep: loggingConfig.methodCount, startOffset: 0);
    anyhow.Error.stackTraceDisplayModifier = (s) =>
        _modifyStackTrace(s, numberOfFramesToKeep: loggingConfig.methodCount, startOffset: 1);
    _numberOfFramesToKeep = loggingConfig.methodCount;
    _timeFn = switch (loggingConfig.timeType) {
      LoggingTimeType.local => () => DateTime.now(),
      LoggingTimeType.utc => () => DateTime.now().toUtc()
    };
    _printer = Printer(
      lineLength: loggingConfig.lineLength,
      colors: loggingConfig.willUseColors,
      printEmojis: loggingConfig.willPrintEmojis,
      willBoxOuput: loggingConfig.willBoxOuput,
    );
    _output = loggingConfig.output;
    _onLog = loggingConfig.onLog;
    _willCreateStackTraceForLogPoint = loggingConfig.willCreateStackTraceForLogPoint;
  }

  static Level get _level {
    if (_levelValue != null) {
      return _levelValue!;
    }
    assert(() {
      if (_devLoggingConfig == null) {
        setLoggingConfig(LoggingConfig.devImpl());
      } else {
        setLoggingConfig(_devLoggingConfig!);
      }
      return true;
    }());
    if (_levelValue == null) {
      if (_prodLoggingConfig == null) {
        setLoggingConfig(LoggingConfig.prodImpl());
      } else {
        setLoggingConfig(_prodLoggingConfig!);
      }
    }
    return _levelValue!;
  }

  //************************************************************************//

  /// debug. See class description on how to use logging levels correctly.
  /// {@template Logging.levelParams}
  /// @param [obj], object to log, can be anything - String, Exception, etc. If type [_LazyFunction], it gets executed
  /// and result is the new [obj]
  /// @param [override], logs the original object type and stacktrace if it exists, but overrides the [obj]s [toString()]
  /// @param [append], appends the message on a new line to message from obj or messageOverride
  /// @param [objStackTrace], stacktrace associated with the [obj]. If [obj] is already an [Error], [anyhow.Err<anyhow.Error>], or [anyhow.Error] the stacktrace is already taken by default.
  /// {@endtemplate}
  static void d(obj, {String? override, String? append, StackTrace? objStackTrace}) {
    if (_level.value <= Level.debug.value) {
      return _applyObjToLog(Level.debug, obj, override, append, objStackTrace);
    }
  }

  /// info. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void i(obj, {String? messageOverride, String? messageAppend, StackTrace? objStackTrace}) {
    if (_level.value <= Level.info.value) {
      return _applyObjToLog(Level.info, obj, messageOverride, messageAppend, objStackTrace);
    }
  }

  /// warning. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void w(obj, {String? messageOverride, String? messageAppend, StackTrace? objStackTrace}) {
    if (_level.value <= Level.warning.value) {
      return _applyObjToLog(Level.warning, obj, messageOverride, messageAppend, objStackTrace);
    }
  }

  /// error. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void e(obj, {String? messageOverride, String? messageAppend, StackTrace? objStackTrace}) {
    if (_level.value <= Level.error.value) {
      return _applyObjToLog(Level.error, obj, messageOverride, messageAppend, objStackTrace);
    }
  }

  //************************************************************************//

  static void _applyObjToLog(Level level, Object objToLog, String? messageOverride,
      String? messageAppend, StackTrace? objStackTrace) {
    final time = _timeFn!();

    if (objToLog is _LazyFunction) {
      objToLog = objToLog();
    }
    if (objToLog is Map || objToLog is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      objToLog = encoder.convert(objToLog);
    }
    List<Entry> entries = [];
    entries.add(
        Entry("Object Type: ", EntryType.objectType, headerMessage: "${objToLog.runtimeType}"));
    if (messageOverride == null) {
      entries.add(Entry("Stringified:", EntryType.stringified, message: objToLog.toString()));
    } else {
      entries.add(
          Entry("Stringified Override:", EntryType.stringifiedOverride, message: messageOverride));
    }
    if (messageAppend != null) {
      entries.add(Entry("Appended Message:", EntryType.appendedMessage, message: messageAppend));
    }
    String? id;
    if (_willCreateLogId) {
      id = uuid.v4();
      entries.add(Entry("Log Id: ", EntryType.logId, headerMessage: id));
    }
    entries.add(Entry("Time: ", EntryType.time,
        headerMessage: "$time  ${time.isUtc ? " (UTC)" : " (Local)"}"));
    if (_willCreateStackTraceForLogPoint) {
      final stackTraceFromLogPoint = _modifyStackTrace(StackTrace.current,
          startOffset: 2, numberOfFramesToKeep: _numberOfFramesToKeep);
      entries.add(Entry("Log-Point StackTrace:", EntryType.logPointStackTrace,
          message: stackTraceFromLogPoint.toString()));
    }
    if (objStackTrace != null) {
      entries.add(Entry("Object StackTrace:", EntryType.objectStackTrace,
          message: _stackTraceModifier(objStackTrace).toString()));
    } else {
      switch (objToLog) {
        case Error(): // Could be a panic too
          if (objToLog.stackTrace != null) {
            objStackTrace = _stackTraceModifier(objToLog.stackTrace!); //todo maybe modify
            entries.add(Entry("Object's StackTrace:", EntryType.objectStackTrace,
                message: objStackTrace.toString()));
          }
          break;
        default:
          break;
      }
    }

    final output = _printer.format(level, entries);

    _onLog?.call(entries: entries, level: Level.debug, id: id);
    _output.output(Output(output));
  }
}

class Entry {
  final String header;
  final EntryType type;
  final String? headerMessage;
  final String? message;

  Entry(this.header, this.type, {this.headerMessage, this.message});
}

enum EntryType {
  objectType,
  stringified,
  stringifiedOverride,
  appendedMessage,
  logId,
  time,
  logPointStackTrace,
  objectStackTrace
}

// Handles any object that is causing JsonEncoder() problems
Object _toEncodableFallback(dynamic object) {
  return object.toString();
}

StackTrace _modifyStackTrace(StackTrace stackTrace,
    {int? numberOfFramesToKeep, int startOffset = 0}) {
  Trace trace = Trace.from(stackTrace);
  List<Frame> frames = trace.frames;
  List<Frame> newFrames = [];
  if (numberOfFramesToKeep != null) {
    numberOfFramesToKeep = min(numberOfFramesToKeep + startOffset, frames.length);
  } else {
    numberOfFramesToKeep = frames.length;
  }

  for (int i = startOffset; i < numberOfFramesToKeep; i++) {
    Frame f = frames[i];
    newFrames.add(Frame(f.uri, f.line, f.column, f.member));
  }

  Trace newTrace = Trace(newFrames);
  return newTrace;
}

typedef _LazyFunction = Object Function();
