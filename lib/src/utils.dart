import 'dart:math';

import 'package:stack_trace/stack_trace.dart';

StackTrace modifyStackTrace(StackTrace stackTrace,
    {int? numberOfFramesToKeep, int startOffset = 0}) {
  Trace trace = Trace.from(stackTrace);
  List<Frame> frames = trace.frames;
  List<Frame> newFrames = [];
  if (numberOfFramesToKeep != null) {
    numberOfFramesToKeep =
        min(numberOfFramesToKeep + startOffset, frames.length);
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
