import 'package:dlox/dlox.dart';
import 'package:tool/tool.dart';

void main() {
  List<Stmt> statement = [
    Print(expression: Literal(value: 'Hello world')),
    Var(
        name: Token(
            type: TokenType.IDENTIFIER, lexeme: 'd', literal: null, line: 1),
        initializer: Literal(value: 8)),
    Var(
        name: Token(
            type: TokenType.IDENTIFIER, lexeme: 'c', literal: null, line: 1),
        initializer: null),
    Block(statements: [
      Var(
        name: Token(
            type: TokenType.IDENTIFIER, lexeme: 'a', literal: null, line: 1),
        initializer: Literal(value: 2),
      ),
      Print(
        expression: Binary(
          left: Literal(value: 5),
          operator:
              Token(type: TokenType.PLUS, lexeme: '+', literal: null, line: 1),
          right: Literal(value: 8),
        ),
      )
    ]),
    Block(statements: [
      Var(
        name: Token(
            type: TokenType.IDENTIFIER, lexeme: 'a', literal: null, line: 1),
        initializer: Literal(value: 2),
      ),
      Print(
        expression: Binary(
          left: Literal(value: 5),
          operator:
              Token(type: TokenType.PLUS, lexeme: '+', literal: null, line: 1),
          right: Literal(value: 8),
        ),
      ),
      Block(statements: [
        Var(
          name: Token(
              type: TokenType.IDENTIFIER, lexeme: 'a', literal: null, line: 1),
          initializer: Literal(value: 2),
        ),
        Print(
          expression: Binary(
            left: Literal(value: 5),
            operator: Token(
                type: TokenType.PLUS, lexeme: '+', literal: null, line: 1),
            right: Literal(value: 8),
          ),
        )
      ]),
      Block(statements: [
        Var(
          name: Token(
              type: TokenType.IDENTIFIER, lexeme: 'a', literal: null, line: 1),
          initializer: Literal(value: 2),
        ),
        Print(
          expression: Binary(
            left: Literal(value: 5),
            operator: Token(
                type: TokenType.PLUS, lexeme: '+', literal: null, line: 1),
            right: Literal(value: 8),
          ),
        )
      ])
    ])
  ];

  print(VisitorAstPrinter().printStatements(statement));
  print(ReversePolishNotationAstPrinter().printStatements(statement));
  print(FunctionalAstPrinter().printStatements(statement));
}

final class VisitorAstPrinter
    implements ExprVisitor<String>, StmtVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  String printStatements(List<Stmt> stmts) {
    StringBuffer buffer = StringBuffer();
    for (final statement in stmts) {
      buffer.write(statement.accept(this));
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return _parenthesize('group', [expr.expression]);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return 'nil';
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return _parenthesize(expr.operator.lexeme, [expr.right]);
  }

  @override
  String visitVariableExpr(Variable expr) {
    return _parenthesize('var', [expr]);
  }

  @override
  String visitAssignExpr(Assign expr) {
    return _parenthesize(expr.name.lexeme, [expr.value]);
  }

  @override
  String visitBlockStmt(Block stmt) {
    StringBuffer buffer = StringBuffer();
    buffer.write('|--SOB  ');
    for (final statement in stmt.statements) {
      buffer.write(statement.accept(this));
    }

    buffer.write('  EOB--|  ');
    return buffer.toString();
  }

  @override
  String visitExpressionStmt(Expression stmt) {
    return stmt.expression.accept(this);
  }

  @override
  String visitPrintStmt(Print stmt) {
    return _parenthesize('-->', [stmt.expression]);
  }

  @override
  String visitVarStmt(Var stmt) {
    return _parenthesize(
      '${stmt.name.lexeme} --> ',
      [stmt.initializer ?? Literal(value: null)],
    );
  }

  String _parenthesize(String name, List<Expr> exprs) {
    StringBuffer buffer = StringBuffer();

    buffer.write('($name');
    for (final expr in exprs) {
      buffer.write(' ');
      buffer.write(expr.accept(this));
    }
    buffer.write(')');

    return buffer.toString();
  }
}

final class ReversePolishNotationAstPrinter
    implements ExprVisitor<String>, StmtVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  String printStatements(List<Stmt> stmts) {
    StringBuffer buffer = StringBuffer();
    for (final statement in stmts) {
      buffer.write(statement.accept(this));
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return _display(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return _display('', [expr.expression]);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == null) return 'nil';
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return _display(expr.operator.lexeme, [expr.right]);
  }

  @override
  String visitVariableExpr(Variable expr) {
    return _display('', [expr]);
  }

  @override
  String visitBlockStmt(Block stmt) {
    StringBuffer buffer = StringBuffer();
    buffer.write('|--SOB  ');
    for (final statement in stmt.statements) {
      buffer.write(statement.accept(this));
    }

    buffer.write('  EOB--|  ');
    return buffer.toString();
  }

  @override
  String visitExpressionStmt(Expression stmt) {
    return stmt.expression.accept(this);
  }

  @override
  String visitPrintStmt(Print stmt) {
    return _display('-->', [stmt.expression]);
  }

  @override
  String visitVarStmt(Var stmt) {
    return _display(
      '${stmt.name.lexeme} --> ',
      [stmt.initializer ?? Literal(value: null)],
    );
  }

  String _display(String name, List<Expr> exprs) {
    StringBuffer buffer = StringBuffer();

    for (final expr in exprs) {
      buffer.write(expr.accept(this));
      buffer.write(' ');
    }
    buffer.write(name);

    return buffer.toString();
  }

  @override
  String visitAssignExpr(Assign expr) {
    return _display(expr.name.lexeme, [expr.value]);
  }
}

final class FunctionalAstPrinter {
  String print(Expr expr) {
    return _printExpr(expr);
  }

  String printStatements(List<Stmt> stmts) {
    StringBuffer buffer = StringBuffer();
    for (final statement in stmts) {
      buffer.write(_printStmt(statement));
      buffer.writeln();
    }
    return buffer.toString();
  }

  // print true via pattern matching
  String _printExpr(Expr expr) {
    return switch (expr) {
      Assign(:final name, :final value) => _parenthesize(name.lexeme, [value]),
      Binary(:final left, :final operator, :final right) =>
        _parenthesize(operator.lexeme, [left, right]),
      Literal(:final value) => value == null ? 'nil' : value.toString(),
      Grouping(:final expression) => _parenthesize('group', [expression]),
      Unary(:final operator, :final right) =>
        _parenthesize(operator.lexeme, [right]),
      Variable() => _parenthesize('var', [expr]),
    };
  }

  String _printStmt(Stmt stmt) {
    return switch (stmt) {
      Block(:final statements) => () {
          StringBuffer buffer = StringBuffer();
          buffer.write('|--SOB  ');
          for (final statement in statements) {
            buffer.write(_printStmt(statement));
          }

          buffer.write('  EOB--|  ');
          return buffer.toString();
        }(),
      Expression(:final expression) => _printExpr(expression),
      Print(:final expression) => _parenthesize('-->', [expression]),
      Var(:final name, :final initializer) => _parenthesize(
          '${name.lexeme} -->',
          [initializer ?? Literal(value: null)],
        ),
    };
  }

  String _parenthesize(String name, List<Expr> exprs) {
    StringBuffer buffer = StringBuffer();

    buffer.write('($name');
    for (final expr in exprs) {
      buffer.write(' ');
      buffer.write(_printExpr(expr));
    }
    buffer.write(')');

    return buffer.toString();
  }
}
