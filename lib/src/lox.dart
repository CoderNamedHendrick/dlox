import 'dart:io';

import 'package:dlox/dlox.dart';
import 'package:dlox/src/errors.dart';
import 'package:dlox/src/interpreter.dart';
import 'package:tool/tool.dart';

import 'parser.dart';

final class Lox {
  static bool _hadError = false;
  static bool _hadRuntimeError = false;

  static final _interpreter = Interpreter();

  static void main(List<String> args) {
    if (args.length > 1) {
      print('Usage: dlox [script]');
      exit(64);
    } else if (args.length == 1) {
      _runFile(args[0]);
    } else {
      _runPrompt();
    }
  }

  static void _runFile(String path) {
    try {
      final file = File.fromUri(Uri.parse(path));
      if (!_isLoxFile(file.path)) {
        stderr.writeln(
            'Invalid file for path: ${file.path}\nPlease ensure it\'s a .dx file ');
        exit(65);
      }

      final bytes = file.readAsStringSync();
      _run(bytes);

      // Indicate an error in the exit code.
      if (_hadError) exit(65);
      if (_hadRuntimeError) exit(70);
    } catch (_) {
      rethrow;
    }
  }

  static void _runPrompt() {
    try {
      for (;;) {
        print('> ');
        String? line = stdin.readLineSync();
        if (line == null) break;
        _run(line);
        _hadError = false;
      }
    } catch (_) {
      rethrow;
    }
  }

  static void _run(String source) {
    Scanner scanner = Scanner(source);
    List<Token> tokens = scanner.scanTokens();
    Parser parser = Parser(tokens);
    final expression = parser.parse();

    // Stop if there is a syntax error
    if (_hadError) return;

    _interpreter.interpret(expression ?? Literal(value: null));
  }

  static void runtimeError(RuntimeError error) {
    stderr.writeln('${error.message}\n[Line ${error.token.line} ]');
    _hadRuntimeError = true;
  }

  static void error(Token token, String message) {
    if (token.type == TokenType.EOF) {
      _report(token.line, ' at end', message);
    } else {
      _report(token.line, 'at \'${token.lexeme}\'', message);
    }
  }

  static void _report(int line, String where, String message) {
    stderr.writeln('[line $line] Error $where: $message');
    _hadError = true;
  }

  static bool _isLoxFile(String filePath) {
    return filePath.split('.').last == 'dx';
  }
}
