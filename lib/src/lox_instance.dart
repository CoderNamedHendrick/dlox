import 'package:dlox/src/errors.dart';
import 'package:dlox/src/lox_class.dart';
import 'package:dlox/src/native_functions/lox_function.dart';

import '../dlox.dart';

class LoxInstance {
  final LoxClass _klass;
  final Map<String, dynamic> _fields = {};

  LoxInstance(this._klass);

  dynamic get(Token name) {
    if (_fields.containsKey(name.lexeme)) {
      return _fields[name.lexeme];
    }

    LoxFunction? method = _klass.findMethod(name.lexeme);
    if (method != null) return method.bind(this);

    throw RuntimeError(name, 'Undefined property \'${name.lexeme}\'.');
  }

  void set(Token name, dynamic value) {
    _fields[name.lexeme] = value;
  }

  @override
  String toString() {
    return '${_klass.name} instance';
  }
}
