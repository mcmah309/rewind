import 'dart:convert';

import 'package:rewind/src/log.dart';

import 'level.dart';
import 'printer.dart';

/// Outputs simple log messages:
/// ```
/// [E] Log message  ERROR: Error info
/// ```
class SimplePrinter implements Printer {
  static final levelPrefixes = {
    //Level.trace: '[T]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    //Level.fatal: '[FATAL]',
  };

  const SimplePrinter();

  @override
  List<String> format(Level level, List<OutputEntry> entries) {
    List<String> buffer = [];
    var prefix = levelPrefixes[level]!;
    for (var entry in entries) {
      buffer.add('$prefix${entry.header}${entry.headerMessage ?? ''}');
      if (entry.body != null) {
        for (var line in entry.body!.split("\n")) {
          buffer.add('\t$line');
        }
      }
    }

    return buffer;
  }
}
