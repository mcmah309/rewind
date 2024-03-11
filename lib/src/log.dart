import 'package:rewind/src/output/console_output.dart';
import 'package:rewind/src/printers/printer.dart';
import 'package:rewind/src/utils.dart';
import 'package:rust_core/iter.dart';
import 'package:uuid/uuid.dart';

import 'level.dart';
import 'output/output.dart';

part "log_builder.dart";

/// Logging interface.
class Log {
  Log._();

  static Level level = Level.info;
  static LogOutput output = ConsoleOutput();

  static LogLevelConfig defaultLogConfig = LogLevelConfig.def(
    printer: PrettyPrinter(),
  );
  static LogLevelConfig traceLogConfig = defaultLogConfig;
  static LogLevelConfig debugLogConfig = defaultLogConfig;
  static LogLevelConfig infoLogConfig = defaultLogConfig;
  static LogLevelConfig warningLogConfig = defaultLogConfig;
  static LogLevelConfig errorLogConfig = defaultLogConfig;
  static LogLevelConfig fatalLogConfig = defaultLogConfig;

  static final _uuid = Uuid();

  //************************************************************************//

  /// trace.
  ///
  /// {@template Logging.levelParams}
  /// @param [obj], object to log, can be anything - String, Exception, etc. If type [Function()], it gets executed
  /// and result is the new [obj]
  /// @param [override], the original log object is still passed around, but the stringified version of the [obj] is replaced with this.
  /// @param [append], appends the message to the log entry.
  /// {@endtemplate}
  static void t(obj, {String? override, String? append}) {
    if (level.value <= Level.trace.value) {
      return _applyObjToLog(Level.trace, obj, override, append, traceLogConfig);
    }
  }

  /// debug.
  ///
  /// {@macro Logging.levelParams}
  static void d(obj, {String? override, String? append}) {
    if (level.value <= Level.debug.value) {
      return _applyObjToLog(Level.debug, obj, override, append, debugLogConfig);
    }
  }

  /// info.
  ///
  /// {@macro Logging.levelParams}
  static void i(obj, {String? override, String? append}) {
    if (level.value <= Level.info.value) {
      return _applyObjToLog(Level.info, obj, override, append, infoLogConfig);
    }
  }

  /// warning.
  ///
  /// {@macro Logging.levelParams}
  static void w(obj, {String? override, String? append}) {
    if (level.value <= Level.warning.value) {
      return _applyObjToLog(
          Level.warning, obj, override, append, warningLogConfig);
    }
  }

  /// error.
  ///
  /// {@macro Logging.levelParams}
  static void e(obj, {String? messageOverride, String? messageAppend}) {
    if (level.value <= Level.error.value) {
      return _applyObjToLog(
          Level.error, obj, messageOverride, messageAppend, errorLogConfig);
    }
  }

  /// fatal.
  ///
  /// {@macro Logging.levelParams}
  static void f(obj, {String? messageOverride, String? messageAppend}) {
    if (level.value <= Level.fatal.value) {
      return _applyObjToLog(
          Level.fatal, obj, messageOverride, messageAppend, fatalLogConfig);
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
    if (logConfig._willCreateLogId) {
      logId = _uuid.v4();
    }
    DateTime? time;
    if (logConfig._willCaptureTime) {
      time = DateTime.now().toUtc();
    }
    StackTrace? logPointStackTrace;
    if (logConfig._willCreateStackTraceForLogPoint) {
      logPointStackTrace = modifyStackTrace(StackTrace.current, startOffset: 2);
    }

    final logEvent = LogEvent(level, objToLog, messageOverride, messageAppend,
        time, logId, logPointStackTrace);

    logConfig.onLog?.call(logEvent);

    final outputEntries = logConfig.components
        .iter()
        .map((e) => e.build(logEvent))
        .filter((e) => e != null)
        .cast<LogField>()
        .toList();

    final formatted =
        logConfig.printer.format(level, outputEntries, logConfig.framesToKeep);

    output.output(Output(formatted));
  }
}

/// A field of a log entry.
class LogField {
  final String? header;
  final String? headerMessage;

  /// Usually a string, but if not, the printer will handle it
  final Object? body;

  LogField({this.header, this.headerMessage, this.body});
}

class LogEvent {
  final Level level;
  final Object obj;
  final String? override;
  final String? append;
  final DateTime? time;
  final String? id;
  final StackTrace? logPointStackTrace;

  LogEvent(this.level, this.obj, this.override, this.append, this.time, this.id,
      this.logPointStackTrace);
}

enum LogFeature {
  logId,
  time,
  logPointStackTrace,
}
