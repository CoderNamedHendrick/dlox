import 'src.dart';

abstract interface class StmtVisitor<R> {
    R visitExpressionStmt (Expression stmt);
    R visitPrintStmt (Print stmt);
    R visitVarStmt (Var stmt);
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

final class Var extends Stmt {
    final Token name;
    final Expr? initializer;

    const Var({
        required this.name,
        required this.initializer,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitVarStmt(this);
    }
}

