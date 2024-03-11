part of "printer.dart";

/// Outputs simple log messages:
/// ```
/// [E] Log message  ERROR: Error info
/// ```
class SimplePrinter implements Printer {
  static final levelPrefixes = {
    Level.trace: '[T]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.fatal: '[FATAL]',
  };

  const SimplePrinter();

  @override
  List<String> format(
    Level level,
    List<LogField> entries,
    int? framesToKeep,
  ) {
    List<String> buffer = [];
    var prefix = levelPrefixes[level]!;
    if (entries.length == 1) {
      buffer.add(prefix);
      final entry = entries.first;
      if (entry.body != null) {
        final String stringBody = _bodyToString(entry.body!, framesToKeep);
        for (var line in stringBody.split("\n")) {
          buffer.add(line);
        }
      }
    } else {
      buffer.add(prefix);
      for (var entry in entries) {
        buffer.add('${entry.header}: ${entry.headerMessage ?? ''}');
        if (entry.body != null) {
          final String stringBody = _bodyToString(entry.body!, framesToKeep);
          for (var line in stringBody.split("\n")) {
            buffer.add('\t$line');
          }
        }
      }
    }

    return buffer;
  }
}
