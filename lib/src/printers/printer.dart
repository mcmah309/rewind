import 'dart:convert';

import 'package:anyhow/anyhow.dart' as anyhow;

import '../ansi_color.dart';
import '../level.dart';
import '../log.dart';
import '../utils.dart';

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
      stringBody = modifyStackTrace(body, numberOfFramesToKeep: framesToKeep).toString();
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
    return modifyStackTrace(stackTrace, numberOfFramesToKeep: framesToKeep, startOffset: 1);
  };
  final stringBody = error.toString();
  anyhow.Error.stackTraceDisplayModifier = currentModifyStackTrace;
  return stringBody;
}