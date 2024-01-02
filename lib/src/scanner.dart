import 'lox.dart';
import 'token.dart';
import 'token_types.dart';

final class Scanner {
  late final String _source;
  late final List<Token> tokens = [];
  int _start = 0;
  int _current = 0;
  int _line = 1;

  static final Map<String, TokenType> _keywords = {
    'and': TokenType.AND,
    'class': TokenType.CLASS,
    'else': TokenType.ELSE,
    'false': TokenType.FALSE,
    'for': TokenType.FOR,
    'fun': TokenType.FUN,
    'if': TokenType.IF,
    'nil': TokenType.NIL,
    'or': TokenType.OR,
    'print': TokenType.PRINT,
    'return': TokenType.RETURN,
    'super': TokenType.SUPER,
    'this': TokenType.THIS,
    'true': TokenType.TRUE,
    'var': TokenType.VAR,
    'while': TokenType.WHILE,
  };

  Scanner(String source) {
    _source = source;
  }

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }

    tokens.add(
      Token(type: TokenType.EOF, lexeme: '', literal: null, line: _line),
    );
    return tokens;
  }

  /*
  dkjeinglejeh
   */
  void _scanToken() {
    void reachCommentEndOfLine() {
      while (_peek != '\n' && !_isAtEnd) {
        _advance();
      }
    }

    void reachMultiBlockCommentEnd() {
      while ((_peek != '*' && _peekNext != '/') && !_isAtEnd) {
        if (_peek == '\n') _line++;
        _advance();
      }

      if (_isAtEnd) {
        Lox.error(tokens.last, 'Unterminated comment');
        return;
      }

      // consume */ end of multi line comment tokens
      _advance();
      _advance();
    }

    String c = _advance();
    return switch (c) {
      '(' => _addToken(TokenType.LEFT_PAREN),
      ')' => _addToken(TokenType.RIGHT_PAREN),
      '{' => _addToken(TokenType.LEFT_BRACE),
      '}' => _addToken(TokenType.RIGHT_BRACE),
      ',' => _addToken(TokenType.COMMA),
      '.' => _addToken(TokenType.DOT),
      '-' => _addToken(TokenType.MINUS),
      '+' => _addToken(TokenType.PLUS),
      ';' => _addToken(TokenType.SEMICOLON),
      '*' => _addToken(TokenType.STAR),
      '?' => _addToken(TokenType.QUESTION_MARK),
      ':' => _addToken(TokenType.COLON),
      '!' => _addToken(_match('=') ? TokenType.BANG_EQUAL : TokenType.BANG),
      '=' => _addToken(_match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL),
      '<' => _addToken(_match('=') ? TokenType.LESS_EQUAL : TokenType.LESS),
      '>' =>
        _addToken(_match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER),
      '/' => () {
          // handling single line comments
          if (_match('/')) {
            reachCommentEndOfLine();
          } else if (_match('*')) {
            reachMultiBlockCommentEnd();
          } else {
            _addToken(TokenType.SLASH);
          }
        }(),
      ' ' => () {},
      '\r' => () {},
      '\t' => () {},
      '\n' => _line++,
      '"' => _string(),
      _ => () {
          if (_isDigit(c)) {
            return _number();
          } else if (_isAlpha(c)) {
            return _identifier();
          } else {
            Lox.error(tokens.last, 'Unexpected character.');
          }
        }(),
    };
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek)) {
      _advance();
    }

    String text = _source.substring(_start, _current);
    TokenType? type = _keywords[text];
    type ??= TokenType.IDENTIFIER;
    _addToken(type);
  }

  void _number() {
    while (_isDigit(_peek)) {
      _advance();
    }

    // Look for a fractional part.
    if (_peek == '.' && _isDigit(_peekNext)) {
      // Consumer the "."
      _advance();

      while (_isDigit(_peek)) {
        _advance();
      }
    }

    _addTokenLiteral(
        TokenType.NUMBER, double.parse(_source.substring(_start, _current)));
  }

  void _string() {
    while (_peek != '"' && !_isAtEnd) {
      if (_peek == '\n') _line++;
      _advance();
    }

    if (_isAtEnd) {
      Lox.error(tokens.last, 'Unterminated string.');
      return;
    }

    // The closing "
    _advance();

    // Trim the surrounding quotes.
    String value = _source.substring(_start + 1, _current - 1);
    _addTokenLiteral(TokenType.STRING, value);
  }

  bool _match(String expected) {
    if (_isAtEnd) return false;
    if (_source[_current] != expected) return false;

    _current++;
    return true;
  }

  String get _peek {
    if (_isAtEnd) return '\u0000';
    return _source[_current];
  }

  bool _isAlpha(String c) {
    return RegExp('[aA-zZ]').hasMatch(c);
  }

  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }

  String get _peekNext {
    // \u0000 unicode for null[end of line]
    if (_current + 1 >= _source.length) return '\u0000';
    return _source[_current + 1];
  }

  bool _isDigit(String c) {
    return RegExp('[0-9]').hasMatch(c);
  }

  bool get _isAtEnd {
    return _current >= _source.length;
  }

  String _advance() {
    _current++;
    return _source[_current - 1];
  }

  void _addToken(TokenType type) {
    _addTokenLiteral(type, null);
  }

  void _addTokenLiteral(TokenType type, dynamic literal) {
    String text = _source.substring(_start, _current);
    tokens.add(Token(type: type, lexeme: text, literal: literal, line: _line));
  }
}
