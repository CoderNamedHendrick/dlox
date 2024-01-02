import 'src.dart';

abstract interface class StmtVisitor<R> {
    R visitExpressionStmt (Expression stmt);
    R visitPrintStmt (Print stmt);
}

sealed class Stmt {
    const Stmt();

    R accept<R>(StmtVisitor<R> visitor);
}

final class Expression extends Stmt {
    final Expr expression;

    const Expression({
        required this.expression,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitExpressionStmt(this);
    }
}

final class Print extends Stmt {
    final Expr expression;

    const Print({
        required this.expression,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitPrintStmt(this);
    }
}

