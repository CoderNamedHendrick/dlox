import 'package:dlox/src/interpreter.dart';
import 'package:dlox/src/lox_instance.dart';
import 'package:dlox/src/native_functions/native_functions.dart';

class LoxClass implements LoxCallable {
  final String name;
  final Map<String, LoxFunction> _methods;

  const LoxClass(this.name, this._methods);

  LoxFunction? findMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    return null;
  }

  @override
  String toString() {
    return name;
  }

  @override
  int get arity {
    LoxFunction? initializer = findMethod('init');
    if (initializer == null) return 0;

    return initializer.arity;
  }

  @override
  call(Interpreter interpreter, List<dynamic> arguments) {
    LoxInstance instance = LoxInstance(this);
    LoxFunction? initializer = findMethod('init');
    if (initializer != null) {
      initializer.bind(instance).call(interpreter, arguments);
    }
    return instance;
  }
}
