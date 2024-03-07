import 'ansi_color.dart';
import 'level.dart';
import 'log.dart';

abstract class Printer {

  const Printer();

  /// Formats the entries to log and returns a list of strings, which are lines.
  List<String> format(
    Level level,
    List<OutputEntry> entries,
  );
} 