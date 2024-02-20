import 'dart:async';

/// Log output receives a [Output] from [LogPrinter] and sends it to the
/// desired destination.
///
/// This can be an output stream, a file or a network target. [LogOutput] may
/// cache multiple log messages.
abstract class LogOutput {
  const LogOutput();

  Future<void> init() async {}

  void output(Output output);

  Future<void> destroy() async {}
}

class Output {
  final List<String> lines;

  Output(this.lines);
}