import 'dart:io';

final class GenerateAst {
  static final String _tab = '    ';

  static void main(List<String> args) {
    try {
      if (args.length != 1) {
        stderr.writeln("Usage: generate_ast <output directory>");
        exit(64);
      }
      String outputDir = args[0];
      _defineAst(outputDir, baseName: 'Expr', types: [
        'Assign    :    Token name, Expr value',
        'Binary    :    Expr left, Token operator, Expr right',
        'Call      :    Expr callee, Token paren, List<Expr> arguments',
        'Grouping  :    Expr expression',
        'Literal   :    dynamic value',
        'Logical   :    Expr left, Token operator, Expr right',
        'Unary     :    Token operator, Expr right',
        'Variable  :    Token name'
      ]);

      _defineAst(outputDir, baseName: 'Stmt', types: [
        'Block      : List<Stmt> statements',
        'Expression : Expr expression',
        'LFunction   : Token name, List<Token> params, List<Stmt> body',
        'If         : Expr condition, Stmt thenBranch, Stmt? elseBranch',
        'Print      : Expr expression',
        'Return     : Token keyword, Expr? value',
        'Var        : Token name, Expr? initializer',
        'While      : Expr condition, Stmt body',
        'Break      : Token token',
      ]);
    } catch (_) {
      rethrow;
    }
  }

  static void _defineAst(String outputDir,
      {required String baseName, required List<String> types}) {
    try {
      String path = '$outputDir/${baseName.toLowerCase()}.dart';
      var writer = File(path).openWrite();

      // import src to provide common imports
      writer.writeln('import \'src.dart\';');
      writer.writeln();

      // define visitor
      _defineVisitor(writer, baseName, types);
      writer.writeln();

      writer.writeln('sealed class $baseName {');
      writer.writeln('${_tab}const $baseName();');
      writer.writeln();
      writer.writeln('${_tab}R accept<R>(${baseName}Visitor<R> visitor);');
      writer.writeln('}');
      writer.writeln(); // newline

      // The AST classes
      for (final type in types) {
        final className = type.split(':')[0].trim();
        final fields = type.split(':')[1].trim();
        _defineType(writer, baseName, className, fields);
        writer.writeln(); // space between each class types
      }

      writer.close();
    } catch (e) {
      rethrow;
    }
  }

  static void _defineVisitor(
      IOSink writer, String baseName, List<String> types) {
    writer.writeln('abstract interface class ${baseName}Visitor<R> {');
    for (final type in types) {
      final typeName = type.split(':')[0].trim();
      writer.writeln(
          '${_tab}R visit$typeName$baseName ($typeName ${baseName.toLowerCase()});');
    }
    writer.writeln('}');
  }

  static void _defineType(
      IOSink writer, String baseName, String className, String fieldList) {
    writer.writeln('final class $className extends $baseName {');
    // fields
    final fields = fieldList.split(',');
    for (final field in fields) {
      writer.writeln('${_tab}final ${field.trim()};');
    }
    writer.writeln();

    // constructor
    writer.writeln('${_tab}const $className({');
    for (final field in fields) {
      final fieldName = field.trim().split(' ')[1];
      writer.writeln('$_tab${_tab}required this.$fieldName,');
    }
    writer.writeln('$_tab});');
    writer.writeln();

    // Visitor pattern
    writer.writeln('$_tab@override');
    writer.writeln('${_tab}R accept<R>(${baseName}Visitor<R> visitor) {');
    writer
        .writeln('$_tab${_tab}return visitor.visit$className$baseName(this);');
    writer.writeln('$_tab}');

    writer.writeln('}');
  }
}
