import 'package:dlox/dlox.dart';
import 'package:tool/tool.dart';

void main() {
  Expr expression = Binary(
    left: Unary(
        operator:
            Token(type: TokenType.MINUS, lexeme: '-', literal: null, line: 1),
        right: Literal(value: 123)),
    operator: Token(type: TokenType.STAR, lexeme: '*', literal: null, line: 1),
    right: Grouping(expression: Literal(value: 45.67)),
  );

  Expr expression2 = Binary(
    left: Grouping(
        expression: Binary(
            left: Literal(value: 1),
            operator: Token(
                type: TokenType.PLUS, lexeme: '+', literal: null, line: 1),
            right: Literal(value: 2))),
    operator: Token(type: TokenType.STAR, lexeme: '*', literal: null, line: 1),
    right: Grouping(
        expression: Binary(
            left: Literal(value: 4),
            operator: Token(
                type: TokenType.MINUS, lexeme: '-', literal: null, line: 1),
            right: Literal(value: 3))),
  );

  print(VisitorAstPrinter()
      .print(expression)); // prints (* (- 123) (group 45.67))
  print(FunctionalAstPrinter().print(expression));
  print(ReversePolishNotationAstPrinter()
      .print(expression2)); // prints 1 2 + 4 3 - *
}

final class VisitorAstPrinter implements Visitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
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

final class ReversePolishNotationAstPrinter implements Visitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
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

  String _display(String name, List<Expr> exprs) {
    StringBuffer buffer = StringBuffer();

    for (final expr in exprs) {
      buffer.write(expr.accept(this));
      buffer.write(' ');
    }
    buffer.write(name);

    return buffer.toString();
  }
}

final class FunctionalAstPrinter {
  String print(Expr expr) {
    return _printExpr(expr);
  }

  // print true via pattern matching
  String _printExpr(Expr expr) {
    return switch (expr) {
      Binary(:final left, :final operator, :final right) =>
        _parenthesize(operator.lexeme, [left, right]),
      Literal(:final value) => value == null ? 'nil' : value.toString(),
      Grouping(:final expression) => _parenthesize('group', [expression]),
      Unary(:final operator, :final right) =>
        _parenthesize(operator.lexeme, [right]),
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
