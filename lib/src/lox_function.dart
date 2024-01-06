import 'package:dlox/src/environment.dart';
import 'package:dlox/src/interpreter.dart';
import 'package:dlox/src/lox_callable.dart';
import 'package:tool/tool.dart';
import 'return.dart' as re;

class LoxFunction implements LoxCallable {
  final LFunction _declaration;

  LoxFunction(this._declaration);

  @override
  int get arity => _declaration.params.length;

  @override
  call(Interpreter interpreter, List<dynamic> arguments) {
    Environment environment = Environment(enclosing: interpreter.globals);

    for (int i = 0; i < _declaration.params.length; i++) {
      environment.define(_declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(_declaration.body, environment);
    } on re.Return catch (returnValue) {
      return returnValue.value;
    }
    return null;
  }

  @override
  String toString() => '<fn ${_declaration.name.lexeme}>';
}
