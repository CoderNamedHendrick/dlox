import 'package:dlox/src/errors.dart';

import 'token.dart';

class Environment {
  final Environment? enclosing;
  final _values = <String, dynamic>{};

  Environment({this.enclosing});

  dynamic get(Token name) {
    if (_values.containsKey(name.lexeme)) {
      return _values[name.lexeme];
    }

    if (enclosing != null) return enclosing!.get(name);

    throw RuntimeError(name, 'Undefined variable \'${name.lexeme}\'.');
  }

  void assign(Token name, dynamic value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    if (enclosing != null) {
      enclosing!.assign(name, value);
      return;
    }

    throw RuntimeError(name, 'Undefined variable \'${name.lexeme}\'.');
  }

  void define(String name, dynamic value) {
    _values.putIfAbsent(name, () => value);
  }
}
