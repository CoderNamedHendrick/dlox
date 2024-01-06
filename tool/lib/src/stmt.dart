import 'src.dart';

abstract interface class StmtVisitor<R> {
    R visitBlockStmt (Block stmt);
    R visitExpressionStmt (Expression stmt);
    R visitLFunctionStmt (LFunction stmt);
    R visitIfStmt (If stmt);
    R visitPrintStmt (Print stmt);
    R visitReturnStmt (Return stmt);
    R visitVarStmt (Var stmt);
    R visitWhileStmt (While stmt);
    R visitBreakStmt (Break stmt);
}

sealed class Stmt {
    const Stmt();

    R accept<R>(StmtVisitor<R> visitor);
}

final class Block extends Stmt {
    final List<Stmt> statements;

    const Block({
        required this.statements,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitBlockStmt(this);
    }
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

final class LFunction extends Stmt {
    final Token name;
    final List<Token> params;
    final List<Stmt> body;

    const LFunction({
        required this.name,
        required this.params,
        required this.body,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitLFunctionStmt(this);
    }
}

final class If extends Stmt {
    final Expr condition;
    final Stmt thenBranch;
    final Stmt? elseBranch;

    const If({
        required this.condition,
        required this.thenBranch,
        required this.elseBranch,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitIfStmt(this);
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

final class Return extends Stmt {
    final Token keyword;
    final Expr? value;

    const Return({
        required this.keyword,
        required this.value,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitReturnStmt(this);
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

final class While extends Stmt {
    final Expr condition;
    final Stmt body;

    const While({
        required this.condition,
        required this.body,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitWhileStmt(this);
    }
}

final class Break extends Stmt {
    final Token token;

    const Break({
        required this.token,
    });

    @override
    R accept<R>(StmtVisitor<R> visitor) {
        return visitor.visitBreakStmt(this);
    }
}

