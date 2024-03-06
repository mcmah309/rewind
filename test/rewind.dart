import 'package:anyhow/anyhow.dart';
import 'package:test/test.dart';
import 'package:rewind/rewind.dart';

void main() {
  late void Function() logFn;

  test('test1', () {
    final current = StackTrace.current;
    logFn = () => Log.i('test',
        messageOverride: 'override',
        messageAppend: 'append',
        objStackTrace: current);
    func(logFn, 4);
  });

  test('test2', () {
    final current = StackTrace.current;
    logFn =
        () => Log.i('test', messageAppend: 'append', objStackTrace: current);
    func(logFn, 4);
  });

  test('test3', () {
    final current = StackTrace.current;
    logFn = () => Log.i('test', objStackTrace: current);
    func(logFn, 4);
  });

  test('test4', () {
    logFn = () => Log.i('test');
    func(logFn, 4);
  });

  test('test-anyhow1', () {
    logFn = () => Log.i(bail("bailing here"));
    func(logFn, 4);
  });

  test('test-anyhow2', () {
    final current = StackTrace.current;
    logFn = () => Log.i(bail("bailing here"), objStackTrace: current);
    func(logFn, 4);
  });

  test('test-anyhow3', () {
    Error.displayFormat = ErrDisplayFormat.rootCauseFirst;
    logFn = () => Log.i(bail("bailing here"));
    func(logFn, 9);
  });

  test('test-anyhow4', () {
    Error.stackTraceDisplayFormat = StackTraceDisplayFormat.full;
    logFn = () => Log.i(bail("bailing here").context("this is some context"));
    func(logFn, 9);
  });

  test('test-anyhow5', () {
    Error.stackTraceDisplayFormat = StackTraceDisplayFormat.full;
    logFn = () => Log.e(bail("bailing here")
        .context("this is some context")
        .context("How about some more"));
    func(logFn, 8);
  });
}

//************************************************************************//

void func(void Function() logFn, int logAt) {
  if (logAt == 0) {
    logFn();
    return;
  }
  func1(logFn, logAt);
}

void func1(void Function() logFn, int logAt) {
  if (logAt == 1) {
    logFn();
    return;
  }
  func2(logFn, logAt);
}

void func2(void Function() logFn, int logAt) {
  if (logAt == 2) {
    logFn();
    return;
  }
  func3(logFn, logAt);
}

void func3(void Function() logFn, int logAt) {
  if (logAt == 3) {
    logFn();
    return;
  }
  func4(logFn, logAt);
}

void func4(void Function() logFn, int logAt) {
  if (logAt == 4) {
    logFn();
    return;
  }
  func5(logFn, logAt);
}

void func5(void Function() logFn, int logAt) {
  if (logAt == 5) {
    logFn();
    return;
  }
  func6(logFn, logAt);
}

void func6(void Function() logFn, int logAt) {
  if (logAt == 6) {
    logFn();
    return;
  }
  func7(logFn, logAt);
}

void func7(void Function() logFn, int logAt) {
  if (logAt == 7) {
    logFn();
    return;
  }
  func8(logFn, logAt);
}

void func8(void Function() logFn, int logAt) {
  if (logAt == 8) {
    logFn();
    return;
  }
  func9(logFn, logAt);
}

void func9(void Function() logFn, int logAt) {
  if (logAt == 9) {
    logFn();
    return;
  }
  func10(logFn, logAt);
}

void func10(void Function() logFn, int logAt) {
  if (logAt == 10) {
    logFn();
    return;
  }
  //func11(logFn, logAt);
  throw Exception('logAt too high');
}