/// This class handles colorizing of terminal output.
class AnsiColor {
  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const ansiEsc = '\x1B[';

  /// Reset all colors and options for current SGRs to terminal defaults.
  static const ansiDefault = '${ansiEsc}0m';

  final int? code;

  const AnsiColor.none() : code = null;

  const AnsiColor(this.code);

  @override
  String toString() {
    if (code != null) {
      return '${ansiEsc}38;5;${code}m'; // foreground
      // return '${ansiEsc}48;5;${bg}m'; // background
    }
    return "";
  }

  String call(String msg) {
    if (code != null) {
      // ignore: unnecessary_brace_in_string_interps
      return '${this}$msg$ansiDefault';
    } else {
      return msg;
    }
  }
}
