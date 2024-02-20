import 'dart:async';

import 'output.dart';

class StreamOutput extends LogOutput {
  late StreamController<List<String>> _controller;
  bool _shouldForward = false;

  StreamOutput() {
    _controller = StreamController<List<String>>(
      onListen: () => _shouldForward = true,
      onPause: () => _shouldForward = false,
      onResume: () => _shouldForward = true,
      onCancel: () => _shouldForward = false,
    );
  }

  Stream<List<String>> get stream => _controller.stream;

  @override
  void output(Output output) {
    if (!_shouldForward) {
      return;
    }

    _controller.add(output.lines);
  }

  @override
  Future<void> destroy() {
    return _controller.close();
  }
}
