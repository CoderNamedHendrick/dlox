import 'package:dlox/dlox.dart';
import 'package:dlox/src/environment.dart';
import 'package:dlox/src/errors.dart';
import 'package:tool/tool.dart';

final class Interpreter implements ExprVisitor<dynamic>, StmtVisitor<void> {
  Environment _environment = Environment();

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
    _environment.assign(expr.name, value);
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
  void visitPrintStmt(Print stmt) {
    final value = _evaluate(stmt.expression);
    print(_stringify(value));
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
    return _environment.get(expr.name);
  }

  @override
  void visitBlockStmt(Block stmt) {
    _executeBlock(stmt.statements, Environment(enclosing: _environment));
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
      _execute(stmt.body);
    }
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

  void _executeBlock(List<Stmt> statements, Environment environment) {
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
