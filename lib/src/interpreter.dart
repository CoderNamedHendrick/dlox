import 'package:dlox/dlox.dart';
import 'package:dlox/src/environment.dart';
import 'package:dlox/src/errors.dart';
import 'package:dlox/src/lox_class.dart';
import 'package:dlox/src/lox_instance.dart';
import 'package:tool/tool.dart';
import 'native_functions/native_functions.dart';
import 'return.dart' as re;

class _BreakOutOfLoopException implements Exception {}

final class Interpreter implements ExprVisitor<dynamic>, StmtVisitor<void> {
  final Environment globals = Environment();
  final Map<Expr, int> locals = {};

  late Environment _environment = globals;

  Interpreter() {
    globals.define('clock', _InterpreterCallable());
  }

  void interpret({List<Stmt> statements = const [], Expr? expr}) {
    if (expr != null) return _interpretExpr(expr);

    return _interpretStmts(statements);
  }

  void _interpretStmts(List<Stmt> statements) {
    try {
      for (final statement in statements) {
        _execute(statement);
      }
    } on RuntimeError catch (e) {
      Lox.runtimeError(e);
    }
  }

  void _interpretExpr(Expr expression) {
    try {
      dynamic value = _evaluate(expression);
      print(_stringify(value));
    } on RuntimeError catch (e) {
      Lox.runtimeError(e);
    }
  }

  String _stringify(dynamic object) {
    if (object == null) return 'nil';

    if (object is double) {
      String text = object.toString();
      if (text.endsWith('.0')) {
        text = text.substring(0, text.length - 2); // remove decimal zero
      }
      return text;
    }

    return object.toString();
  }

  @override
  visitAssignExpr(Assign expr) {
    dynamic value = _evaluate(expr.value);

    int? distance = locals[expr];
    if (distance != null) {
      _environment.assignAt(distance, expr.name, value);
    } else {
      globals.assign(expr.name, value);
    }

    return value;
  }

  @override
  visitBinaryExpr(Binary expr) {
    dynamic left = _evaluate(expr.left);
    dynamic right = _evaluate(expr.right);

    return switch (expr.operator.type) {
      TokenType.BANG_EQUAL => !_isEqual(left, right),
      TokenType.EQUAL_EQUAL => _isEqual(left, right),
      TokenType.GREATER => () {
          switch ((left, right)) {
            case (double left, String right):
              return left > right.length;
            case (String left, double right):
              return left.length > right;
            case (String left, String right):
              return left.length > right.length;
          }

          _checkNumberOperands(expr.operator, left, right);
          return (left as double) > (right as double);
        }(),
      TokenType.GREATER_EQUAL => () {
          switch ((left, right)) {
            case (double left, String right):
              return left >= right.length;
            case (String left, double right):
              return left.length >= right;
            case (String left, String right):
              return left.length >= right.length;
          }

          _checkNumberOperands(expr.operator, left, right);
          return (left as double) >= (right as double);
        }(),
      TokenType.LESS => () {
          switch ((left, right)) {
            case (double left, String right):
              return left < right.length;
            case (String left, double right):
              return left.length < right;
            case (String left, String right):
              return left.length < right.length;
          }

          _checkNumberOperands(expr.operator, left, right);
          return (left as double) < (right as double);
        }(),
      TokenType.LESS_EQUAL => () {
          switch ((left, right)) {
            case (double left, String right):
              return left <= right.length;
            case (String left, double right):
              return left.length <= right;
            case (String left, String right):
              return left.length <= right.length;
          }

          _checkNumberOperands(expr.operator, left, right);
          return (left as double) <= (right as double);
        }(),
      TokenType.MINUS => () {
          // from the left, delete characters at the start
          // from the right, delete characters at the end
          switch ((left, right)) {
            case (double left, String right):
              _checkStringNumberLength(expr.operator, right, left);
              return right.substring(left.ceil(), right.length); //
            case (String left, double right):
              _checkStringNumberLength(expr.operator, left, right);
              return left.substring(0, left.length - right.ceil());
          }

          _checkNumberOperands(expr.operator, left, right);
          return (left as double) - (right as double);
        }(),
      TokenType.PLUS => () {
          if (left is double && right is double) {
            return left + right;
          }

          if (left is String && right is String) {
            return left + right;
          }

          // string number addition
          switch ((left, right)) {
            case (String left, double right):
              return left + _stringify(right);
            case (double left, String right):
              return _stringify(left) + right;
          }

          throw RuntimeError(
              expr.operator, 'Operands must be two numbers or two strings.');
        }(),
      TokenType.SLASH => () {
          _checkNumberOperands(expr.operator, left, right);
          if (right == 0) throw ZeroDivisorError(expr.operator);
          return (left as double) / (right as double);
        }(),
      TokenType.STAR => () {
          _checkNumberOperands(expr.operator, left, right);
          return (left as double) * (right as double);
        }(),
      _ => null,
    };
  }

  @override
  visitCallExpr(Call expr) {
    dynamic callee = _evaluate(expr.callee);
    List arguments = [];
    for (Expr argument in expr.arguments) {
      arguments.add(_evaluate(argument));
    }

    if (callee is! LoxCallable) {
      throw RuntimeError(expr.paren, 'Can only call functions and classes.');
    }

    LoxCallable function = callee;
    if (arguments.length != function.arity) {
      throw RuntimeError(expr.paren,
          'Expect ${function.arity} arguments but got ${arguments.length}.');
    }

    return function.call(this, arguments);
  }

  @override
  visitGetExpr(Get expr) {
    dynamic object = _evaluate(expr.object);
    if (object is LoxInstance) {
      return object.get(expr.name);
    }

    throw RuntimeError(expr.name, 'Only instances have properties.');
  }

  @override
  visitSetExpr(Set expr) {
    dynamic object = _evaluate(expr.object);

    if (object is! LoxInstance) {
      throw RuntimeError(expr.name, 'Only instances have fields.');
    }

    dynamic value = _evaluate(expr.value);
    object.set(expr.name, value);
    return value;
  }

  @override
  visitSuperExpr(Super expr) {
    int? distance = locals[expr];
    if (distance == null) {
      throw RuntimeError(expr.keyword, 'No \'super\' class found');
    }

    LoxClass superclass = _environment.getAt(distance, 'super');

    // "this" instance is always a step behind environment containing the super class.
    LoxInstance object = _environment.getAt(distance - 1, 'this');

    LoxFunction? method = superclass.findMethod(expr.method.lexeme);

    if (method == null) {
      throw RuntimeError(
          expr.method, 'Undefined property \'${expr.method.lexeme}.');
    }

    return method.bind(object);
  }

  @override
  visitThisExpr(This expr) {
    return _lookUpVariable(expr.keyword, expr);
  }

  @override
  visitGroupingExpr(Grouping expr) {
    return _evaluate(expr.expression);
  }

  @override
  visitLiteralExpr(Literal expr) {
    return expr.value;
  }

  @override
  visitLogicalExpr(Logical expr) {
    final left = _evaluate(expr.left);

    if (expr.operator.type == TokenType.OR) {
      if (_isTruthy(left)) return left;
    } else {
      if (!_isTruthy(left)) return left;
    }

    return _evaluate(expr.right);
  }

  @override
  visitUnaryExpr(Unary expr) {
    dynamic right = _evaluate(expr.right);

    return switch (expr.operator.type) {
      TokenType.BANG => !_isTruthy(right),
      TokenType.MINUS => () {
          _checkNumberOperand(expr.operator, right);
          return -(right as double);
        }(),
      _ => null,
    };
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    _evaluate(stmt.expression);
  }

  @override
  void visitLFunctionStmt(LFunction stmt) {
    LoxFunction function = LoxFunction(stmt, _environment, false);
    _environment.define(stmt.name.lexeme, function);
  }

  @override
  void visitPrintStmt(Print stmt) {
    final value = _evaluate(stmt.expression);
    print(_stringify(value));
  }

  @override
  void visitReturnStmt(Return stmt) {
    dynamic value;
    if (stmt.value != null) value = _evaluate(stmt.value!);

    throw re.Return(value);
  }

  @override
  void visitVarStmt(Var stmt) {
    dynamic value;
    if (stmt.initializer != null) {
      value = _evaluate(stmt.initializer!);
    }

    _environment.define(stmt.name.lexeme, value);
  }

  @override
  visitVariableExpr(Variable expr) {
    return _lookUpVariable(expr.name, expr);
  }

  dynamic _lookUpVariable(Token name, Expr expr) {
    int? distance = locals[expr];
    if (distance != null) {
      return _environment.getAt(distance, name.lexeme);
    } else {
      return globals.get(name);
    }
  }

  @override
  void visitBlockStmt(Block stmt) {
    executeBlock(stmt.statements, Environment(enclosing: _environment));
  }

  @override
  void visitClassStmt(Class stmt) {
    dynamic superclass;
    if (stmt.superclass != null) {
      superclass = _evaluate(stmt.superclass!);
      if (superclass is! LoxClass) {
        throw RuntimeError(
            stmt.superclass!.name, 'Superclass must be a class.');
      }
    }

    _environment.define(stmt.name.lexeme, null);

    if (stmt.superclass != null) {
      _environment = Environment(enclosing: _environment);
      _environment.define('super', superclass);
    }

    Map<String, LoxFunction> methods = {};
    for (LFunction method in stmt.methods) {
      LoxFunction function =
          LoxFunction(method, _environment, method.name.lexeme == 'init');
      methods.putIfAbsent(method.name.lexeme, () => function);
    }

    LoxClass klass =
        LoxClass(stmt.name.lexeme, superclass as LoxClass?, methods);

    if (superclass != null) {
      _environment = _environment.enclosing!;
    }

    _environment.assign(stmt.name, klass);
  }

  @override
  void visitIfStmt(If stmt) {
    if (_isTruthy(_evaluate(stmt.condition))) {
      _execute(stmt.thenBranch);
    } else if (stmt.elseBranch != null) {
      _execute(stmt.elseBranch!);
    }
  }

  @override
  void visitWhileStmt(While stmt) {
    while (_isTruthy(_evaluate(stmt.condition))) {
      try {
        _execute(stmt.body);
      } on _BreakOutOfLoopException {
        break;
      }
    }
  }

  @override
  void visitBreakStmt(Break stmt) {
    if (_environment.enclosing != null) {
      throw _BreakOutOfLoopException();
    }

    throw RuntimeError(
        stmt.token, 'Break statement cannot be used outside a loop.');
  }

  _checkStringNumberLength(Token token, String string, double number) {
    if (string.length >= number) return;
    throw RuntimeError(token, 'Operand value must be not exceed string length');
  }

  _checkNumberOperand(Token operator, dynamic operand) {
    if (operand is double) return;
    throw RuntimeError(operator, "Operand must be a number");
  }

  _checkNumberOperands(Token operator, dynamic left, dynamic right) {
    if (left is double && right is double) return;
    throw RuntimeError(operator, "Operands must be numbers");
  }

  bool _isTruthy(dynamic object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool _isEqual(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null) return false;

    return a == b;
  }

  dynamic _evaluate(Expr expr) {
    return expr.accept(this);
  }

  void _execute(Stmt stmt) {
    stmt.accept(this);
  }

  void resolve(Expr expr, int depth) {
    locals[expr] = depth;
  }

  // var a = 10; while (a < 15) { if (a == 13) break; a = a + 1; print a; } print a;
  void executeBlock(List<Stmt> statements, Environment environment) {
    final previous = _environment;
    try {
      _environment = environment;

      for (final statement in statements) {
        _execute(statement);
      }
    } finally {
      _environment = previous;
    }
  }
}

final class _InterpreterCallable implements LoxCallable {
  const _InterpreterCallable();

  @override
  int get arity => 0;

  @override
  call(Interpreter interpreter, List<dynamic> arguments) {
    return (DateTime.now().millisecond / 1000).toDouble();
  }

  @override
  String toString() => '<clock native fn>';
}
