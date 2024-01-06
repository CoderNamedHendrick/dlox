import 'package:dlox/src/interpreter.dart';

abstract interface class LoxCallable {
  const LoxCallable();

  int get arity;

  dynamic call(Interpreter interpreter, List<dynamic> arguments);
}
