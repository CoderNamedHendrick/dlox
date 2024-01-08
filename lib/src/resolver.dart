import 'package:dlox/src/interpreter.dart';
import 'package:tool/tool.dart';
import 'package:stack/stack.dart';

import '../dlox.dart';

enum _FunctionType {
  none,
  function,
  initializer,
  method,
  loop;
}

enum _ClassType {
  none,
  klass;
}

class Resolver implements ExprVisitor<void>, StmtVisitor<void> {
  late final Interpreter _interpreter;

  final Stack<Map<String, bool>> scopes = Stack();
  final Stack<Map<Token, bool>> variableUsedInScope = Stack();
  _FunctionType _currentFunction = _FunctionType.none;
  _ClassType _currentClass = _ClassType.none;

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
  void visitClassStmt(Class stmt) {
    _ClassType enclosingClass = _currentClass;
    _currentClass = _ClassType.klass;

    _declare(stmt.name);
    _define(stmt.name);

    _beginScope();
    scopes.top().putIfAbsent('this', () => true);

    for (LFunction method in stmt.methods) {
      _FunctionType declaration = _FunctionType.method;
      if (method.name.lexeme == 'init') {
        declaration = _FunctionType.initializer;
      }

      _resolveFunction(method, declaration);
    }

    _endScope();

    _currentClass = enclosingClass;
  }

  @override
  void visitBreakStmt(Break stmt) {
    // handle using break in static analysis
    if (_currentFunction == _FunctionType.loop) return;

    Lox.error(stmt.token, 'Can\'t use \'break\' outside a loop');
  }

  @override
  void visitCallExpr(Call expr) {
    _resolveExpr(expr.callee);

    for (Expr argument in expr.arguments) {
      _resolveExpr(argument);
    }
  }

  @override
  void visitGetExpr(Get expr) {
    _resolveExpr(expr.object);
  }

  @override
  void visitSetExpr(Set expr) {
    _resolveExpr(expr.value);
    _resolveExpr(expr.object);
  }

  @override
  void visitThisExpr(This expr) {
    if (_currentClass == _ClassType.none) {
      Lox.error(expr.keyword, 'Can\'t use \'this\' outside of a class.');
      return;
    }
    _resolveLocal(expr, expr.keyword);
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

    if (stmt.value != null) {
      if (_currentFunction == _FunctionType.initializer) {
        Lox.error(stmt.keyword, 'Can\'t return a value from an initializer.');
      }

      _resolveExpr(stmt.value!);
    }
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
    variableUsedInScope.push({});
  }

  void _endScope() {
    for (final varUseInScope in variableUsedInScope.toList()) {
      for (final MapEntry(key: Token token, value: bool isUsed)
          in varUseInScope.entries) {
        if (!isUsed) {
          Lox.error(token, 'variable declared but never used');
        }
      }
    }

    scopes.pop();
    variableUsedInScope.pop();
  }

  void _declare(Token name) {
    if (scopes.isEmpty) return;
    if (variableUsedInScope.isEmpty) return;

    final scope = scopes.top();
    final variableScope = variableUsedInScope.top();

    // check if a variable has been declared already in scope and report error
    // in static time
    if (scope.containsKey(name.lexeme)) {
      Lox.error(
          name, 'Already declared variable with ${name.lexeme} in this scope.');
    }

    // mark variable as created but not used
    variableScope.putIfAbsent(name, () => false);
    // mark variable as not ready by binding to false
    scope.putIfAbsent(name.lexeme, () => false);
  }

  // mark variable as ready and initialized after initializer expression completes
  void _define(Token name) {
    if (scopes.isEmpty) return;

    scopes.top().update(name.lexeme, (value) => true);
  }

  void _resolveLocal(Expr expr, Token name) {
    final useScopes = variableUsedInScope.toList();
    final varScopes = scopes.toList();

    for (int i = scopes.length - 1; i >= 0; i--) {
      if (varScopes[i].containsKey(name.lexeme)) {
        // no need to set use to true for resolving this expressions
        if (expr is! This) {
          // mark variable as used in scope.
          useScopes[i].update(name, (value) => true);
        }
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
