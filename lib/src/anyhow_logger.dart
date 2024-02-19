import 'dart:convert';
import 'dart:math';

import 'package:anyhow/anyhow.dart' as anyhow;
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'level.dart';
import 'output/console_output.dart';
import 'output/output.dart';
import 'printer.dart';

typedef LoggingFunction = void Function(dynamic message,
    {DateTime? time, Object? error, StackTrace? stackTrace});

enum LoggingTimeType {
  local,
  utc,
}

class LoggingConfig {
  final Level level;
  final int methodCount;
  final int errorMethodCount;
  final bool willCreateLogId;
  final LoggingTimeType timeType;
  final void Function({Object item, Level level, String? id})? onLog;

  const LoggingConfig(
      {required this.level,
      required this.methodCount,
      required this.errorMethodCount,
      required this.willCreateLogId,
      required this.timeType,
      required this.onLog});

  const LoggingConfig.devImpl(
      {this.level = Level.debug,
      this.methodCount = 2,
      this.errorMethodCount = 6,
      this.willCreateLogId = true,
      this.timeType = LoggingTimeType.local,
      this.onLog});

  const LoggingConfig.prodImpl(
      {this.level = Level.error,
      this.methodCount = 0,
      this.errorMethodCount = 6,
      this.willCreateLogId = false,
      this.timeType = LoggingTimeType.utc,
      this.onLog});
}

/// Log Output Format:
/// - Log Object Type
/// - StackTrace When Log Util Was Called
/// - Formatted Message From Object
///   - Optional: Object StackTrace If A Known Type And Present
/// See [README.md] file in package for appropriate usage
/// 
/// 
/// 
/// Object Type
/// Stringified || Stringified Override
/// Appended Message
/// Log Id
/// Time
/// Object's StackTrace || None
/// Log-Point StackTrace || None
class Log {
  Log._();

  static late Printer _printer;

  static Level? _levelValue;

  /// If true, will create a code to associate with the log, useful for for associating logs with an on screen error
  static bool _willCreateLogId = true;

  static final uuid = Uuid();
  static DateTime Function()? _timeFn;
  static LoggingConfig? _prodLoggingConfig;
  static LoggingConfig? _devLoggingConfig;
  static late StackTrace Function(StackTrace) _stackTraceModifier;

  static LogOutput output = ConsoleOutput();

  /// If provided, will be called with the processed log item, the log level, and the log id. Useful for sending logs to a server
  /// or for displaying logs in a custom way.
  static void Function({Object item, Level level, String? id})? _onLog;

  //************************************************************************//

  /// If called, will set up prod logging with the provided parameters. If not called, it will be called with defaults when run in debug mode.
  static setDevLoggingConfig([LoggingConfig devLoggingConfig = const LoggingConfig.devImpl()]) {
    _devLoggingConfig = devLoggingConfig;
  }

  /// If called, will set up prod logging with the provided parameters. If not called, it will be called with defaults when not run in debug mode.
  static setProdLoggingConfig([LoggingConfig prodLoggingConfig = const LoggingConfig.prodImpl()]) {
    _prodLoggingConfig = prodLoggingConfig;
  }

  /// If called, will set up all logging with the provided parameters. If not called, [LoggingConfig.devImpl] is
  /// used in debug mode if [setDevLoggingConfig] is not called.
  /// And [LoggingConfig.prodImpl] is used when not in debug mode if [setProdLoggingConfig] is not called.
  static setLoggingConfig(LoggingConfig loggingConfig) {
    _levelValue = loggingConfig.level;
    _willCreateLogId = loggingConfig.willCreateLogId;
    _stackTraceModifier = (s) =>
        _modifyStackTrace(s, numberOfFramesToKeep: loggingConfig.errorMethodCount, startOffset: 0);
    anyhow.Error.stackTraceDisplayModifier = (s) =>
        _modifyStackTrace(s, numberOfFramesToKeep: loggingConfig.errorMethodCount, startOffset: 1);
    _timeFn = switch (loggingConfig.timeType) {
      LoggingTimeType.local => () => DateTime.now(),
      LoggingTimeType.utc => () => DateTime.now().toUtc()
    };
    _printer = Printer(
            stackTraceBeginIndex: 0,
            methodCount: loggingConfig.methodCount,
            errorMethodCount: loggingConfig.errorMethodCount,
            lineLength: 120,
            colors: true,
            printEmojis: true,
            noBoxingByDefault: false);
    _onLog = loggingConfig.onLog;
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
  /// @param [messageOverride], logs the original object/stacktrace, but overrides the message if one already exists
  /// @param [messageAppend], appends the message on a new line to message from obj or messageOverride
  /// @param [objStackTrace], stacktrace associated with the [obj]. If [obj] is already an [Error] or
  /// [ExceptionWithStackTrace] the stacktrace is already taken by default.
  /// {@endtemplate}
  static void d(obj, {String? messageOverride, String? messageAppend, StackTrace? objStackTrace}) {
    if (_level.value <= Level.debug.value) {
      return _applyObjToLog(Level.debug, obj, messageOverride, messageAppend, objStackTrace);
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
    final stackTraceFromLogPoint = _modifyStackTrace(StackTrace.current, startOffset: 2);
    
    if (objToLog is _LazyFunction) {
      objToLog = objToLog();
    }
    if (objToLog is Map || objToLog is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      objToLog = encoder.convert(objToLog);
    }
    List<Entry> entries = [];
    entries.add(Entry("Object Type: ", headerMessage: "${objToLog.runtimeType}"));
    if (messageOverride == null) {
      entries.add(Entry("Stringified:", message: objToLog.toString()));
    } else {
      entries.add(Entry("Stringified Override:", message: messageOverride));
    }
    if (messageAppend != null) {
      entries.add(Entry("Appended Message:", message: messageAppend));
    }
    String? id;
    if (_willCreateLogId) {
      id = uuid.v4();
      entries.add(Entry("Log Id: ", headerMessage: id));
    }
    entries.add(Entry("Time: ", headerMessage: "$time  ${time.isUtc ? " (UTC)" : " (Local)"}"));
    entries.add(Entry("Log-Point StackTrace:", message: stackTraceFromLogPoint.toString()));
    if (objStackTrace != null) {
      entries.add(Entry("Object StackTrace:", message: _stackTraceModifier(objStackTrace).toString()));
    }
    else {
        switch (objToLog) {
          case Error(): // Could be a panic too
            if (objToLog.stackTrace != null) {
              objStackTrace = _stackTraceModifier(objToLog.stackTrace!);//todo maybe modify
              entries.add(Entry("Object's StackTrace:", message: objStackTrace.toString()));
            }
            break;
          default:
            break;
        }
      }
    
    //_onLog?.call(item: finalMessage, level: Level.debug, id: id); // todo

    final x = _printer.formatAndPrint(level, entries);
    output.output(Output(x));
    //logFn(finalMessage, error: logObjectType, stackTrace: stackTraceFromLogPoint, time: time);
  }

  // Handles any object that is causing JsonEncoder() problems
  static Object _toEncodableFallback(dynamic object) {
    return object.toString();
  }
}

StackTrace _modifyStackTrace(StackTrace stackTrace,
    {int? numberOfFramesToKeep, int startOffset = 0}) {
  Trace trace = Trace.from(stackTrace);
  List<Frame> frames = trace.frames;
  List<Frame> newFrames = [];
  if (numberOfFramesToKeep != null) {
    numberOfFramesToKeep = min(numberOfFramesToKeep, frames.length);
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
