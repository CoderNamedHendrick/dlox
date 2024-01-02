import 'token_types.dart';

final class Token {
  final TokenType type;
  final String lexeme;
  final dynamic literal;
  final int line;

  const Token({
    required this.type,
    required this.lexeme,
    required this.literal,
    required this.line,
  });

  @override
  String toString() {
    return '$type $lexeme $literal';
  }
}
