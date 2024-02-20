import 'output.dart';

/// Default implementation of [LogOutput].
///
/// It sends everything to the system console.
class ConsoleOutput extends LogOutput {
  const ConsoleOutput();

  @override
  void output(Output output) {
    output.lines.forEach(print);
  }
}
