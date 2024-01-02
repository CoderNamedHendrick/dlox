import 'package:tool/tool.dart';

import '../dlox.dart';

class ParseError extends Error {}

class Parser {
  late final List<Token> _tokens;
  int _current = 0;

  Parser(List<Token> tokens) : _tokens = tokens;

  Expr? parse() {
    try {
      return _expression();
    } on ParseError catch (_) {
      return null;
    }
  }

  Expr _expression() {
    return _equality();
  }

  Expr _equality() {
    Expr expr = _comparison();

    while (_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      final operator = _previous;
      final right = _comparison();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr _comparison() {
    Expr expr = _term();

    while (_match([
      TokenType.GREATER,
      TokenType.GREATER_EQUAL,
      TokenType.LESS,
      TokenType.LESS_EQUAL
    ])) {
      final operator = _previous;
      final right = _term();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr _term() {
    Expr expr = _factor();

    while (_match([TokenType.MINUS, TokenType.PLUS])) {
      final operator = _previous;
      final right = _factor();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr _factor() {
    Expr expr = _unary();

    while (_match([TokenType.SLASH, TokenType.STAR])) {
      final operator = _previous;
      final right = _unary();
      expr = Binary(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr _unary() {
    if (_match([TokenType.BANG, TokenType.MINUS])) {
      final operator = _previous;
      final right = _unary();
      return Unary(operator: operator, right: right);
    }

    return _primary();
  }

  Expr _primary() {
    if (_match([TokenType.FALSE])) return Literal(value: false);
    if (_match([TokenType.TRUE])) return Literal(value: true);
    if (_match([TokenType.NIL])) return Literal(value: null);

    if (_match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(value: _previous.literal);
    }

    if (_match([TokenType.LEFT_PAREN])) {
      final expr = _expression();
      _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after expression.');
      return Grouping(expression: expr);
    }

    throw _error(_peek, 'Expect expression.');
  }

  // implement ternary
  // Expr _ternary() {
  //   Expr expr = _equality();
  //
  //   if (_match([TokenType.QUESTION_MARK])) {
  //     final right = _expression();
  //     _consume(TokenType.COLON, 'Expect \':\' after expression');
  //     expr =  Binary(left: expr, operator: operator, right: right);
  //   }
  // }

  bool _match(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();

    throw _error(_peek, message);
  }

  ParseError _error(Token token, String message) {
    Lox.error(token, message);
    return ParseError();
  }

  void _synchronize() {
    _advance();

    while (!_isAtEnd) {
      if (_previous.type == TokenType.SEMICOLON) return;

      switch (_peek.type) {
        case TokenType.CLASS:
        case TokenType.FUN:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default:
          break;
      }

      _advance();
    }
  }

  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

  Token _advance() {
    if (!_isAtEnd) _current++;
    return _previous;
  }

  bool get _isAtEnd {
    return _peek.type == TokenType.EOF;
  }

  Token get _peek {
    return _tokens.elementAt(_current);
  }

  Token get _previous {
    return _tokens.elementAt(_current - 1);
  }
}
