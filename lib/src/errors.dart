import '../dlox.dart';

class RuntimeError extends Error {
  final Token token;
  final String message;

  RuntimeError(this.token, this.message);
}

class ZeroDivisorError extends RuntimeError {
  ZeroDivisorError(Token token)
      : super(token, 'Zero isn\'t permissible divisor');
}
