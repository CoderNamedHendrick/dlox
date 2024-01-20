import 'package:tool/tool.dart';

import '../dlox.dart';

class ParseError extends Error {}

class Parser {
  late final List<Token> _tokens;
  int _current = 0;

  Parser(List<Token> tokens) : _tokens = tokens;

  List<Stmt> parse() {
    List<Stmt?> statements = <Stmt?>[];
    while (!_isAtEnd) {
      statements.add(_declaration());
    }

    statements = statements
        .where((element) => element != null)
        .map((e) => e as Stmt)
        .toList();

    return statements as List<Stmt>;
  }

  Expr? parseExpression() {
    try {
      return _expression();
    } on ParseError {
      return null;
    }
  }

  Expr _expression() {
    return _assignment();
  }

  Stmt? _declaration() {
    try {
      if (_match([TokenType.CLASS])) return _classDeclaration();
      if (_match([TokenType.FUN])) return _function('function');
      if (_match([TokenType.VAR])) return _varDeclaration();

      return _statement();
    } on ParseError catch (_) {
      _synchronize();
      if (Lox.isReplRun) rethrow;
      return null;
    }
  }

  Stmt _classDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, 'Expect class name.');
    Variable? superclass;
    if (_match([TokenType.LESS])) {
      _consume(TokenType.IDENTIFIER, "Expect superclass name.");
      superclass = Variable(name: _previous);
    }

    _consume(TokenType.LEFT_BRACE, 'Expects \'{\' before class body.');

    List<LFunction> methods = [];
    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd) {
      methods.add(_function('method'));
    }

    _consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after class body.');

    return Class(name: name, superclass: superclass, methods: methods);
  }

  Stmt _statement() {
    if (_match([TokenType.FOR])) return _forStatement();
    if (_match([TokenType.IF])) return _ifStatement();
    if (_match([TokenType.PRINT])) return _printStatement();
    if (_match([TokenType.RETURN])) return _returnStatement();
    if (_match([TokenType.WHILE])) return _whileStatement();
    if (_match([TokenType.BREAK])) return _breakStatement();
    if (_match([TokenType.LEFT_BRACE])) return Block(statements: _block());

    return _expressionStatement();
  }

  Stmt _forStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'for\'.');

    Stmt? initializer;
    if (_match([TokenType.SEMICOLON])) {
      initializer = null;
    } else if (_match([TokenType.VAR])) {
      initializer = _varDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    Expr? condition;
    if (!_check(TokenType.SEMICOLON)) {
      condition = _expression();
    }
    _consume(TokenType.SEMICOLON, 'Expect \';\' after for loop condition.');

    Expr? increment;
    if (!_check(TokenType.RIGHT_PAREN)) {
      increment = _expression();
    }
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after clauses.');

    Stmt body = _statement();

    if (increment != null) {
      body = Block(statements: [
        body,
        Expression(expression: increment),
      ]);
    }

    condition ??= Literal(value: true);
    body = While(condition: condition, body: body);

    if (initializer != null) {
      body = Block(statements: [initializer, body]);
    }

    return body;
  }

  Stmt _ifStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'if\'.');
    Expr condition = _expression();
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after if condition.');

    Stmt thenBranch = _statement();
    Stmt? elseBranch;
    if (_match([TokenType.ELSE])) {
      elseBranch = _statement();
    }

    return If(
      condition: condition,
      thenBranch: thenBranch,
      elseBranch: elseBranch,
    );
  }

  Stmt _printStatement() {
    final value = _expression();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after value.');
    return Print(expression: value);
  }

  Stmt _varDeclaration() {
    Token name = _consume(TokenType.IDENTIFIER, 'Expect variable name.');

    Expr? initializer;
    if (_match([TokenType.EQUAL])) {
      initializer = _expression();
    }

    _consume(TokenType.SEMICOLON, 'Expect \';\' after variable declaration.');
    return Var(name: name, initializer: initializer ?? Literal(value: null));
  }

  Stmt _returnStatement() {
    Token keyword = _previous;
    Expr? value;
    if (!_check(TokenType.SEMICOLON)) {
      value = _expression();
    }

    _consume(TokenType.SEMICOLON, 'Expect \';\' after return value.');
    return Return(keyword: keyword, value: value);
  }

  Stmt _whileStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'while\'.');
    final condition = _expression();
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after condition.');
    final body = _statement();

    return While(condition: condition, body: body);
  }

  Stmt _breakStatement() {
    // check for a previous while token else throw error
    if (!_checkPreviousForNearestWhile()) {
      throw _error(_previous, 'Break statement cannot be used outside a loop');
    }

    _consume(TokenType.SEMICOLON, 'Expect \';\' after \'break\'.');
    // keep break token to communicate error location if it fails
    return Break(token: _previous);
  }

  Stmt _expressionStatement() {
    final expr = _expression();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after value.');
    return Expression(expression: expr);
  }

  LFunction _function(String kind) {
    Token name = _consume(TokenType.IDENTIFIER, 'Expect $kind name.');
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after $kind name.');
    List<Token> parameters = [];

    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        if (parameters.length >= 255) {
          _error(_peek, 'Can\'t have more than 255 parameters.');
        }

        parameters
            .add(_consume(TokenType.IDENTIFIER, 'Expect parameter name.'));
      } while (_match([TokenType.COMMA]));
    }
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after parameters.');

    _consume(TokenType.LEFT_BRACE, 'Expect \'{\' before $kind body.');
    List<Stmt> body = _block();

    return LFunction(name: name, params: parameters, body: body);
  }

  List<Stmt> _block() {
    List<Stmt?> statements = [];

    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd) {
      statements.add(_declaration());
    }

    _consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after block.');
    statements = statements
        .where((element) => element != null)
        .map((e) => e as Stmt)
        .toList();

    return statements as List<Stmt>;
  }

  Expr _assignment() {
    Expr expr = _or();

    if (_match([TokenType.EQUAL])) {
      Token equals = _previous;
      Expr value = _assignment();

      if (expr is Variable) {
        Token name = expr.name;
        return Assign(name: name, value: value);
      } else if (expr is Get) {
        Get get = expr;
        return Set(object: get.object, name: get.name, value: value);
      }

      _error(equals, 'Invalid assignment target.');
    }

    return expr;
  }

  Expr _or() {
    Expr expr = _and();

    while (_match([TokenType.OR])) {
      final operator = _previous;
      final right = _and();
      expr = Logical(left: expr, operator: operator, right: right);
    }

    return expr;
  }

  Expr _and() {
    Expr expr = _equality();

    while (_match([TokenType.AND])) {
      final operator = _previous;
      final right = _equality();
      expr = Logical(left: expr, operator: operator, right: right);
    }

    return expr;
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

    return _call();
  }

  Expr _call() {
    Expr expr = _primary();

    while (true) {
      if (_match([TokenType.LEFT_PAREN])) {
        expr = _finishCall(expr);
      } else if (_match([TokenType.DOT])) {
        Token name =
            _consume(TokenType.IDENTIFIER, 'Expect property name after \'.\'.');
        expr = Get(object: expr, name: name);
      } else {
        break;
      }
    }

    return expr;
  }

  Expr _finishCall(Expr callee) {
    List<Expr> arguments = [];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        if (arguments.length >= 255) {
          _error(_peek, 'Can\'t have more than 255 arguments.');
        }
        arguments.add(_expression());
      } while (_match([TokenType.COMMA]));
    }

    Token paren =
        _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after arguments.');

    return Call(callee: callee, paren: paren, arguments: arguments);
  }

  Expr _primary() {
    if (_match([TokenType.FALSE])) return Literal(value: false);
    if (_match([TokenType.TRUE])) return Literal(value: true);
    if (_match([TokenType.NIL])) return Literal(value: null);

    if (_match([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(value: _previous.literal);
    }

    if (_match([TokenType.SUPER])) {
      Token keyword = _previous;
      _consume(TokenType.DOT, 'Expect \'.\' after \'super\'.');
      Token method =
          _consume(TokenType.IDENTIFIER, 'Expect superclass method name.');
      return Super(keyword: keyword, method: method);
    }

    if (_match([TokenType.THIS])) return This(keyword: _previous);

    if (_match([TokenType.IDENTIFIER])) {
      return Variable(name: _previous);
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
    if (!Lox.isReplRun) Lox.error(token, message);
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

  bool _checkPreviousForNearestWhile() {
    if (_isAtEnd) return false;
    bool whileExists = false;
    int whileLocation = 0;
    for (int i = _current; i >= 0; i--) {
      if (_tokens[i].type == TokenType.WHILE) {
        whileLocation = i;
      }

      // tells us where the next block ends
      if (_tokens[i].type == TokenType.RIGHT_BRACE) {
        final previousBlockEnd = i;

        // position of while comes after previous block ends
        // which would imply the nearest while started the block with
        // break statement
        if (whileLocation > previousBlockEnd) {
          whileExists = true;
          return whileExists;
        }
      }

      // gotten to the start of the file, while has the only block in file
      if (i == 0 && whileLocation > 0) {
        whileExists = true;
      }
    }

    return whileExists;
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
