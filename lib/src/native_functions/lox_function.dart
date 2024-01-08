import 'package:dlox/src/environment.dart';
import 'package:dlox/src/interpreter.dart';
import 'package:dlox/src/lox_instance.dart';
import 'package:tool/tool.dart';
import '../return.dart' as re;
import 'lox_callable.dart';

/// Native function which calls dart's call interface
class LoxFunction implements LoxCallable {
  final LFunction _declaration;

  // save state of the environment during function declaration
  final Environment _closure;

  // isConstructor initializer
  final bool _isInitializer;

  LoxFunction(this._declaration, this._closure, this._isInitializer);

  LoxFunction bind(LoxInstance instance) {
    Environment environment = Environment(enclosing: _closure);
    environment.define('this', instance);
    return LoxFunction(_declaration, environment, _isInitializer);
  }

  @override
  int get arity => _declaration.params.length;

  @override
  call(Interpreter interpreter, List<dynamic> arguments) {
    Environment environment = Environment(enclosing: _closure);

    for (int i = 0; i < _declaration.params.length; i++) {
      environment.define(_declaration.params[i].lexeme, arguments[i]);
    }

    try {
      interpreter.executeBlock(_declaration.body, environment);
    } on re.Return catch (returnValue) {
      if (_isInitializer) return _closure.getAt(0, 'this');

      return returnValue.value;
    }

    if (_isInitializer) return _closure.getAt(0, 'this');
    return null;
  }

  @override
  String toString() => '<fn ${_declaration.name.lexeme}>';
}
