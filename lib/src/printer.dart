import 'ansi_color.dart';
import 'anyhow_logger.dart';
import 'level.dart';

/// [Printer] for output.
class Printer {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = '─';
  static const singleDivider = '┄';

  static final Map<Level, AnsiColor> defaultLevelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  static final Map<Level, String> defaultLevelEmojis = {
    Level.trace: '',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.fatal: '👾',
  };

  /// Controls the length of the divider lines.
  final int lineLength;

  /// Whether ansi colors are used to color the output.
  final bool colors;

  /// Whether emojis are prefixed to the log line.
  final bool printEmojis;

  /// Controls the colors used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelColors].
  final Map<Level, AnsiColor>? levelColors;

  /// Controls the emojis used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelEmojis].
  final Map<Level, String>? levelEmojis;

  final bool willBoxOuput;

  String _topBorder = '';
  //String _middleBorder = '';
  String _bottomBorder = '';

  Printer({
    this.lineLength = 120,
    this.colors = true,
    this.printEmojis = true,
    this.levelColors,
    this.levelEmojis,
    this.willBoxOuput = true,
  }) {
    var doubleDividerLine = StringBuffer();
    var singleDividerLine = StringBuffer();
    for (var i = 0; i < lineLength - 1; i++) {
      doubleDividerLine.write(doubleDivider);
      singleDividerLine.write(singleDivider);
    }

    _topBorder = '$topLeftCorner$doubleDividerLine';
    //_middleBorder = '$middleCorner$singleDividerLine';
    _bottomBorder = '$bottomLeftCorner$doubleDividerLine';
  }

  AnsiColor _getLevelColor(Level level) {
    AnsiColor? color;
    if (colors) {
      color = levelColors?[level] ?? defaultLevelColors[level];
    }
    return color ?? const AnsiColor.none();
  }

  String _getEmoji(Level level) {
    if (printEmojis) {
      final String? emoji = levelEmojis?[level] ?? defaultLevelEmojis[level];
      if (emoji != null) {
        return '$emoji ';
      }
    }
    return '';
  }

  List<String> format(
    Level level,
    List<Entry> entries,
  ) {
    List<String> buffer = [];
    var verticalLineAtLevel = willBoxOuput ? '$verticalLine ' : '';
    var color = _getLevelColor(level);
    if (willBoxOuput) buffer.add(color(_topBorder));

    var emoji = _getEmoji(level);
    for (var entry in entries) {
      buffer.add(
          '${color('$verticalLineAtLevel$emoji${entry.header}')}${entry.headerMessage ?? ''}');
      if (entry.message != null) {
        for (var line in entry.message!.split("\n")) {
          buffer.add('${color(verticalLineAtLevel)}\t$line');
        }
      }
    }
    if (willBoxOuput) buffer.add(color(_bottomBorder));

    return buffer;
  }
}
