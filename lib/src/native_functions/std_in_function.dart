import 'dart:io';

import 'package:dlox/src/interpreter.dart';
import 'package:dlox/src/native_functions/lox_callable.dart';

/// Native function which calls the dart's std in
class StdInFunction implements LoxCallable {
  @override
  int get arity => 0;

  @override
  call(Interpreter interpreter, List<dynamic> arguments) {
    final input = stdin.readLineSync();

    return input;
  }

  @override
  String toString() => '<stdin native fn>';
}
