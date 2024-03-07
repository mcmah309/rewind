import 'dart:convert';
import 'dart:math';

import 'package:anyhow/anyhow.dart' as anyhow;
import 'package:rewind/src/output/console_output.dart';
import 'package:rewind/src/printer.dart';
import 'package:rust_core/iter.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:uuid/uuid.dart';

import 'level.dart';
import 'output/output.dart';
import 'pretty_printer.dart';
import 'simple_printer.dart';

part "log_builder.dart";

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

  static Level level = Level.info;
  static LogOutput output = ConsoleOutput();
  static LogLevelConfig debugLogConfig = defaultLogConfig;
  static LogLevelConfig infoLogConfig = defaultLogConfig;
  static LogLevelConfig warningLogConfig = defaultLogConfig;
  static LogLevelConfig errorLogConfig = defaultLogConfig;

  static final _uuid = Uuid();


  //************************************************************************//

  /// debug. See class description on how to use logging levels correctly.
  /// {@template Logging.levelParams}
  /// @param [obj], object to log, can be anything - String, Exception, etc. If type [_LazyFunction], it gets executed
  /// and result is the new [obj]
  /// @param [override], logs the original object type and stacktrace if it exists, but overrides the [obj]s [toString()]
  /// @param [append], appends the message on a new line to message from obj or messageOverride
  /// @param [objStackTrace], stacktrace associated with the [obj]. If [obj] is already an [Error], [anyhow.Err<anyhow.Error>], or [anyhow.Error] the stacktrace is already taken by default.
  /// {@endtemplate}
  static void d(obj,
      {String? override, String? append, StackTrace? objStackTrace}) {
    if (level.value <= Level.debug.value) {
      return _applyObjToLog(Level.debug, obj, override, append, debugLogConfig);
    }
  }

  /// info. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void i(obj,
      {String? override,
      String? append,
      StackTrace? objStackTrace}) {
    if (level.value <= Level.info.value) {
      return _applyObjToLog(
          Level.info, obj, override, append, infoLogConfig);
    }
  }

  /// warning. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void w(obj,
      {String? override,
      String? append,
      StackTrace? objStackTrace}) {
    if (level.value <= Level.warning.value) {
      return _applyObjToLog(
          Level.warning, obj, override, append, warningLogConfig);
    }
  }

  /// error. See class description on how to use logging levels correctly.
  ///
  /// {@macro Logging.levelParams}
  static void e(obj,
      {String? messageOverride,
      String? messageAppend,
      StackTrace? objStackTrace}) {
    if (level.value <= Level.error.value) {
      return _applyObjToLog(
          Level.error, obj, messageOverride, messageAppend, errorLogConfig);
    }
  }

  //************************************************************************//

  static void _applyObjToLog(
      Level level,
      Object objToLog,
      String? messageOverride,
      String? messageAppend,
      LogLevelConfig logConfig) {
    
    String? logId;
    if(logConfig._willCreateLogId){
      logId = _uuid.v4();
    }
    DateTime? time;
    if(logConfig._willCaptureTime){
      time = DateTime.now().toUtc();
    }
    StackTrace? logPointStackTrace;
    if(logConfig._willCreateStackTraceForLogPoint){
      logPointStackTrace = _modifyStackTrace(StackTrace.current, startOffset: 2);
    }
    
    final logEvent = LogEvent(level, objToLog, messageOverride, messageAppend, time, logId, logPointStackTrace);
    //todo add callback
    final outputEntries = logConfig.components.iter().map((e) => e.build(logEvent)).filter((e) => e != null).cast<OutputEntry>().toList();

    final formatted = logConfig.printer.format(level, outputEntries);

    output.output(Output(formatted));
  }
}

class OutputEntry {
  final String? header;
  final String? headerMessage;
  final String? body;

  OutputEntry({this.header, this.headerMessage, this.body});
}

class LogEvent {
  final Level level;
  final Object obj;
  final String? override;
  final String? append;
  final DateTime? time;
  final String? id;
  final StackTrace? logPointStackTrace;

  LogEvent(this.level, this.obj, this.override, this.append,
      this.time, this.id, this.logPointStackTrace);

}


enum LogFeature {
  logId,
  time,
  logPointStackTrace,
}

//todo remove
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
