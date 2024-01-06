import 'package:dlox/src/interpreter.dart';
import 'package:tool/tool.dart';
import 'package:stack/stack.dart';

import '../dlox.dart';

enum _FunctionType {
  none,
  function,
  loop;
}

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  late final Interpreter _interpreter;

  final Stack<Map<String, bool>> scopes = Stack();
  _FunctionType _currentFunction = _FunctionType.none;

  Resolver(Interpreter interpreter) {
    _interpreter = interpreter;
  }

  @override
  void visitAssignExpr(Assign expr) {
    _resolveExpr(expr.value);
    _resolveLocal(expr, expr.name);
  }

  @override
  void visitBinaryExpr(Binary expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  void visitBlockStmt(Block stmt) {
    _beginScope();
    resolve(stmt.statements);
    _endScope();
  }

  @override
  void visitBreakStmt(Break stmt) {
    // handle using break in static analysis
    if (_currentFunction == _FunctionType.loop) return;

    Lox.error(stmt.token, 'Can\'t break outside a loop');
  }

  @override
  void visitCallExpr(Call expr) {
    _resolveExpr(expr.callee);

    for (Expr argument in expr.arguments) {
      _resolveExpr(argument);
    }
  }

  @override
  void visitExpressionStmt(Expression stmt) {
    _resolveExpr(stmt.expression);
  }

  @override
  void visitGroupingExpr(Grouping expr) {
    _resolveExpr(expr.expression);
  }

  @override
  void visitIfStmt(If stmt) {
    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.thenBranch);
    if (stmt.elseBranch != null) _resolveStmt(stmt.elseBranch!);
  }

  @override
  void visitLFunctionStmt(LFunction stmt) {
    _declare(stmt.name);
    _define(stmt.name);

    _resolveFunction(stmt, _FunctionType.function);
  }

  @override
  void visitLiteralExpr(Literal expr) {}

  @override
  void visitLogicalExpr(Logical expr) {
    _resolveExpr(expr.left);
    _resolveExpr(expr.right);
  }

  @override
  void visitPrintStmt(Print stmt) {
    _resolveExpr(stmt.expression);
  }

  @override
  void visitReturnStmt(Return stmt) {
    if (_currentFunction == _FunctionType.none) {
      Lox.error(stmt.keyword, 'Can\'t return from top-level code.');
    }

    if (stmt.value != null) _resolveExpr(stmt.value!);
  }

  @override
  void visitUnaryExpr(Unary expr) {
    _resolveExpr(expr.right);
  }

  @override
  void visitVarStmt(Var stmt) {
    _declare(stmt.name);
    if (stmt.initializer != null) {
      _resolveExpr(stmt.initializer!);
    }
    _define(stmt.name);
  }

  @override
  void visitVariableExpr(Variable expr) {
    if (scopes.isNotEmpty && scopes.top()[expr.name.lexeme] == false) {
      Lox.error(
          expr.name, 'Can\'t read local variable in its own initializer.');
    }

    _resolveLocal(expr, expr.name);
  }

  @override
  void visitWhileStmt(While stmt) {
    _FunctionType enclosingFunction = _currentFunction;
    // set the function type to loop to ensure break resolves correctly.
    _currentFunction = _FunctionType.loop;

    _resolveExpr(stmt.condition);
    _resolveStmt(stmt.body);

    _currentFunction = enclosingFunction;
  }

  void resolve(List<Stmt> statements) {
    for (Stmt statement in statements) {
      _resolveStmt(statement);
    }
  }

  void _resolveFunction(LFunction function, _FunctionType type) {
    _FunctionType enclosingFunction = _currentFunction;
    _currentFunction = type;

    _beginScope();
    for (Token param in function.params) {
      _declare(param);
      _define(param);
    }

    resolve(function.body);
    _endScope();
    _currentFunction = enclosingFunction;
  }

  void _beginScope() {
    scopes.push({});
  }

  void _endScope() {
    scopes.pop();
  }

  void _declare(Token name) {
    if (scopes.isEmpty) return;

    final scope = scopes.top();

    // check if a variable has been declared already in scope and report error
    // in static time
    if (scope.containsKey(name.lexeme)) {
      Lox.error(
          name, 'Already declared variable with ${name.lexeme} in this scope.');
    }

    // mark variable as not ready by binding to false
    scope.putIfAbsent(name.lexeme, () => false);
  }

  // mark variable as ready and initialized after initializer expression completes
  void _define(Token name) {
    if (scopes.isEmpty) return;

    scopes.top().update(name.lexeme, (value) => true);
  }

  void _resolveLocal(Expr expr, Token name) {
    final varScopes = scopes.toList();
    for (int i = scopes.length - 1; i >= 0; i--) {
      if (varScopes[i].containsKey(name.lexeme)) {
        _interpreter.resolve(expr, scopes.length - 1 - i);
      }
    }
  }

  void _resolveStmt(Stmt stmt) {
    stmt.accept(this);
  }

  void _resolveExpr(Expr expr) {
    expr.accept(this);
  }
}
