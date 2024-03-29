import 'src.dart';

abstract interface class ExprVisitor<R> {
    R visitAssignExpr (Assign expr);
    R visitBinaryExpr (Binary expr);
    R visitCallExpr (Call expr);
    R visitGetExpr (Get expr);
    R visitSetExpr (Set expr);
    R visitSuperExpr (Super expr);
    R visitThisExpr (This expr);
    R visitGroupingExpr (Grouping expr);
    R visitLiteralExpr (Literal expr);
    R visitLogicalExpr (Logical expr);
    R visitUnaryExpr (Unary expr);
    R visitVariableExpr (Variable expr);
}

sealed class Expr {
    const Expr();

    R accept<R>(ExprVisitor<R> visitor);
}

final class Assign extends Expr {
    final Token name;
    final Expr value;

    const Assign({
        required this.name,
        required this.value,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitAssignExpr(this);
    }
}

final class Binary extends Expr {
    final Expr left;
    final Token operator;
    final Expr right;

    const Binary({
        required this.left,
        required this.operator,
        required this.right,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitBinaryExpr(this);
    }
}

final class Call extends Expr {
    final Expr callee;
    final Token paren;
    final List<Expr> arguments;

    const Call({
        required this.callee,
        required this.paren,
        required this.arguments,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitCallExpr(this);
    }
}

final class Get extends Expr {
    final Expr object;
    final Token name;

    const Get({
        required this.object,
        required this.name,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitGetExpr(this);
    }
}

final class Set extends Expr {
    final Expr object;
    final Token name;
    final Expr value;

    const Set({
        required this.object,
        required this.name,
        required this.value,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitSetExpr(this);
    }
}

final class Super extends Expr {
    final Token keyword;
    final Token method;

    const Super({
        required this.keyword,
        required this.method,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitSuperExpr(this);
    }
}

final class This extends Expr {
    final Token keyword;

    const This({
        required this.keyword,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitThisExpr(this);
    }
}

final class Grouping extends Expr {
    final Expr expression;

    const Grouping({
        required this.expression,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitGroupingExpr(this);
    }
}

final class Literal extends Expr {
    final dynamic value;

    const Literal({
        required this.value,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitLiteralExpr(this);
    }
}

final class Logical extends Expr {
    final Expr left;
    final Token operator;
    final Expr right;

    const Logical({
        required this.left,
        required this.operator,
        required this.right,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitLogicalExpr(this);
    }
}

final class Unary extends Expr {
    final Token operator;
    final Expr right;

    const Unary({
        required this.operator,
        required this.right,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitUnaryExpr(this);
    }
}

final class Variable extends Expr {
    final Token name;

    const Variable({
        required this.name,
    });

    @override
    R accept<R>(ExprVisitor<R> visitor) {
        return visitor.visitVariableExpr(this);
    }
}

