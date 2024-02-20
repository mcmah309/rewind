import 'package:anyhow_logging/src/output/output.dart';

import 'anyhow_logger.dart';
import 'level.dart';
import 'output/console_output.dart';

class LoggingConfig {
  /// The level of the logger.
  final Level level;

  /// The number of methods calls to display in the stack traces.
  final int methodCount;

  /// Whether to create a log id for each log. Useful for associating logs with an on screen error.
  final bool willCreateLogId;

  /// The type of time to use in logs. Apps in production may want to use UTC time.
  final LoggingTimeType timeType;

  /// The output to use for logs. Defaults to ConsoleOutput.
  final LogOutput output;

  /// Whether to use colors in the output. Defaults to true in dev mode and false in prod mode.
  final bool willUseColors;

  /// The length of the line to use for the divider.
  final int lineLength;

  /// Whether to print emojis in the output. Defaults to true in dev mode and false in prod mode.
  final bool willPrintEmojis;

  /// Whether to box the output. Defaults to true in dev mode and false in prod mode.
  final bool willBoxOuput;

  /// Whether to create a stack trace for log points. Defaults to true in dev mode and false in prod mode.
  final bool willCreateStackTraceForLogPoint;

  /// If provided, will be called with the processed log item, the log level, and the log id. Useful for sending logs to a server
  final void Function({List<Entry> entries, Level level, String? id})? onLog;

  const LoggingConfig(
      {required this.level,
      required this.methodCount,
      required this.willCreateLogId,
      required this.timeType,
      required this.output,
      required this.willUseColors,
      required this.lineLength,
      required this.willPrintEmojis,
      required this.willBoxOuput,
      required this.willCreateStackTraceForLogPoint,
      required this.onLog});

  const LoggingConfig.devImpl(
      {this.level = Level.debug,
      this.methodCount = 6,
      this.willCreateLogId = true,
      this.timeType = LoggingTimeType.local,
      this.output = const ConsoleOutput(),
      this.willUseColors = true,
      this.lineLength = 120,
      this.willPrintEmojis = true,
      this.willBoxOuput = true,
      this.willCreateStackTraceForLogPoint = true,
      this.onLog});

  const LoggingConfig.prodImpl(
      {this.level = Level.error,
      this.methodCount = 6,
      this.willCreateLogId = false,
      this.timeType = LoggingTimeType.utc,
      this.output = const ConsoleOutput(),
      this.willUseColors = false,
      this.lineLength = 120,
      this.willPrintEmojis = false,
      this.willBoxOuput = false,
      this.willCreateStackTraceForLogPoint = false,
      this.onLog});
}

enum LoggingTimeType {
  local,
  utc,
}
