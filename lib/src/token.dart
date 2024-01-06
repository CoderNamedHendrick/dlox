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

  // overrode the hashcode and == operators while neglecting line since
  // the token can be called in other lines but must be unique by the other
  // parameters.

  @override
  int get hashCode => type.hashCode ^ lexeme.hashCode ^ literal.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Token) return false;

    return other.type == type &&
        other.lexeme == lexeme &&
        other.literal == literal;
  }
}
