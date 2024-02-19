import 'dart:collection';

import 'output.dart';

/// Buffers [Output]s.
class MemoryOutput extends LogOutput {
  /// Maximum events in [buffer].
  final int bufferSize;

  /// A secondary [LogOutput] to also received events.
  final LogOutput? secondOutput;

  /// The buffer of events.
  final ListQueue<Output> buffer;

  MemoryOutput({this.bufferSize = 20, this.secondOutput})
      : buffer = ListQueue(bufferSize);

  @override
  void output(Output output) {
    if (buffer.length == bufferSize) {
      buffer.removeFirst();
    }

    buffer.add(output);

    secondOutput?.output(output);
  }
}