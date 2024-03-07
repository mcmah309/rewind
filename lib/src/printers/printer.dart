import 'dart:convert';
import 'dart:math';

import 'package:stack_trace/stack_trace.dart';
import 'package:anyhow/anyhow.dart' as anyhow;

import '../ansi_color.dart';
import '../level.dart';
import '../log.dart';

part "pretty_printer.dart";
part "simple_printer.dart";

abstract class Printer {

  const Printer();

  /// Formats the entries to log and returns a list of strings, which are lines.
  List<String> format(
    Level level,
    List<LogField> entries,
    int? framesToKeep,
  );
} 

String _bodyToString(Object body, int? framesToKeep) {
  if (body is Function()) {
    body = body();
  }
  final String stringBody;
  switch (body) {
    case anyhow.Err():
      stringBody = _anyhowErrorToString(body.err, framesToKeep);
    case anyhow.Error():
      stringBody = _anyhowErrorToString(body, framesToKeep);
    case StackTrace():
      stringBody = _modifyStackTrace(body, numberOfFramesToKeep: framesToKeep).toString();
    case Map():
    case Iterable():
      stringBody = JsonEncoder.withIndent('  ', (e) => e.toString()).convert(body);
    case String():
      stringBody = body;
    default:
      stringBody = body.toString();
  }
  return stringBody;
}

String _anyhowErrorToString(anyhow.Error error, int? framesToKeep) {
  final currentModifyStackTrace = anyhow.Error.stackTraceDisplayModifier;
  anyhow.Error.stackTraceDisplayModifier = (stackTrace) {
    return _modifyStackTrace(stackTrace, numberOfFramesToKeep: framesToKeep, startOffset: 1);
  };
  final stringBody = error.toString();
  anyhow.Error.stackTraceDisplayModifier = currentModifyStackTrace;
  return stringBody;
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