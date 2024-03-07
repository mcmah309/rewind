part of "log.dart";



final defaultLogConfig = LogLevelConfig.def(
  Level.info,
  printer: PrettyPrinter(),
);

class LogLevelConfig {
  final Level level;
  final Printer printer;
  final List<LogComponent> components;

  bool _willCreateLogId = false;
  bool _willCaptureTime = false;
  bool _willCreateStackTraceForLogPoint = false;

  LogLevelConfig.def(this.level, {this.printer = const SimplePrinter()})
      : components = const [
          ObjectTypeLogComponent(),
          StringifiedLogComponent(),
          AppendLogComponent(),
          IdLogComponent(),
          TimeLogComponent(),
          LogPointComponent(),
        ],
        _willCreateLogId = true,
        _willCaptureTime = true,
        _willCreateStackTraceForLogPoint = true;

  LogLevelConfig(this.level, {this.printer = const SimplePrinter(), required this.components}) {
    for (final component in components) {
      for (final toCapture in component.toCapture) {
        switch (toCapture) {
          case ToCapture.id:
            _willCreateLogId = true;
            break;
          case ToCapture.time:
            _willCaptureTime = true;
            break;
          case ToCapture.logPoint:
            _willCreateStackTraceForLogPoint = true;
            break;
        }
      }
    }
  }

  @override
  bool operator ==(Object other) {
    return other is LogLevelConfig && other.level == level;
  }

  @override
  int get hashCode => level.hashCode;
}

enum ToCapture {
  id,
  time,
  logPoint,
}

abstract class LogComponent {
  /// Additional information to capture for the log.
  List<ToCapture> get toCapture;

  const LogComponent();

  OutputEntry? build(LogEvent event);
}

class ObjectTypeLogComponent extends LogComponent {
  const ObjectTypeLogComponent();

  @override
  OutputEntry build(LogEvent event) {
    return OutputEntry(
      header: 'Object Type',
      headerMessage: event.obj.runtimeType.toString(),
    );
  }

  @override
  List<ToCapture> get toCapture => const [];
}

class StringifiedLogComponent extends LogComponent {
  final int ifHasStacktraceKeep;

  const StringifiedLogComponent({this.ifHasStacktraceKeep = 6});

  @override
  OutputEntry build(LogEvent event) {
    final header = event.override == null ? 'Stringified' : 'Stringified Override';
    final message = event.override ?? _objToString(event.obj, ifHasStacktraceKeep);
    return OutputEntry(
      header: header,
      body: message,
    );
  }

  @override
  List<ToCapture> get toCapture => const [];
}

class AppendLogComponent extends LogComponent {
  const AppendLogComponent();

  @override
  OutputEntry? build(LogEvent event) {
    if (event.append == null) {
      return null;
    }
    return OutputEntry(
      header: 'Appended Message',
      headerMessage: event.append!,
    );
  }

  @override
  List<ToCapture> get toCapture => const [];
}

class IdLogComponent extends LogComponent {
  const IdLogComponent();

  @override
  OutputEntry build(LogEvent event) {
    return OutputEntry(
      header: 'Log ID',
      headerMessage: event.id!,
    );
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.id];
}

enum TimeZone { local, utc }

class TimeLogComponent extends LogComponent {
  final TimeZone time;

  // Dev Note: The time is always originally in UTC.
  const TimeLogComponent([this.time = TimeZone.utc]);

  @override
  OutputEntry build(LogEvent event) {
    return OutputEntry(
        header: 'Log Time',
        headerMessage: switch (time) {
          TimeZone.local => event.time!.toLocal().toIso8601String(),
          TimeZone.utc => event.time!.toIso8601String(),
        });
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.time];
}

class LogPointComponent extends LogComponent {
  /// The number of frames to keep in the stack trace.
  final int framesToKeep;

  const LogPointComponent({this.framesToKeep = 6});

  @override
  OutputEntry build(LogEvent event) {
    return OutputEntry(
        header: 'Object StackTrace',
        body: _modifyStackTrace(event.logPointStackTrace!,
                numberOfFramesToKeep: framesToKeep, startOffset: 1)
            .toString());
  }

  @override
  List<ToCapture> get toCapture => const [ToCapture.logPoint];
}

StackTrace _modifyStackTrace(StackTrace stackTrace,
    {int? numberOfFramesToKeep, int startOffset = 0}) {
  Trace trace = Trace.from(stackTrace);
  List<Frame> frames = trace.frames;
  List<Frame> newFrames = [];
  if (numberOfFramesToKeep != null) {
    numberOfFramesToKeep = min(numberOfFramesToKeep + startOffset, frames.length);
  } else {
    numberOfFramesToKeep = frames.length;
  }

  for (int i = startOffset; i < numberOfFramesToKeep; i++) {
    Frame f = frames[i];
    newFrames.add(Frame(f.uri, f.line, f.column, f.member));
  }

  Trace newTrace = Trace(newFrames);
  return newTrace;
}

String _objToString(Object obj, int ifHasStacktraceKeep) {
  if (obj is Function()) {
    obj = obj();
  }
  switch (obj) {
    case Iterable():
    case Map():
      var encoder = JsonEncoder.withIndent('  ', _toEncodableFallback);
      return encoder.convert(obj);
    case Error():
      if (obj.stackTrace != null) {
        return _modifyStackTrace(obj.stackTrace!, numberOfFramesToKeep: ifHasStacktraceKeep)
            .toString();
      }
      return obj.toString();
    case anyhow.Err():
      // todo
      return obj.toString();
    case anyhow.Error():
      // todo
      return obj.toString();
    default:
      return obj.toString();
  }
}
