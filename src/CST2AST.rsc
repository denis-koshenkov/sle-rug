module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f);
}

// Form -> "form" Id "{" Question* "}"
AForm cst2ast(f:(Form)`form <Id name> { <Question* qs> }`) {
  return form(id("<name>", src=name@\loc), [ cst2ast(q) | Question q <- qs ], src=f@\loc);
}

// Question -> ...
AQuestion cst2ast(Question q) {
  switch(q) {
    case q:(Question)`<NormalQuestion nq>`: return qnormal(cst2ast(nq), src=q@\loc);
    case q:(Question)`<ComputedQuestion cq>`: return qcomputed(cst2ast(cq), src=q@\loc);
    case q:(Question)`<IfThen ift>`: return qIfThen(cst2ast(ift), src=q@\loc);
    case q:(Question)`<IfThenElse ifte>`: return qIfThenElse(cst2ast(ifte), src=q@\loc);
    default: throw "Unhandled question: <q>";
  }
}

// NormalQuestion -> Str Id ":" Type
ANormalQuestion cst2ast(nq:(NormalQuestion)`<Str label> <Id qid> : <Type typee>`) {
  return normalQuestion(cst2ast(label), id("<qid>", src=qid@\loc), cst2ast(typee), src=nq@\loc);
}

// ComputedQuestion -> NormalQuestion "=" Expr
AComputedQuestion cst2ast(cq:(ComputedQuestion)`<NormalQuestion nq> = <Expr expr>`) {
  return computedQuestion(cst2ast(nq), cst2ast(expr), src=cq@\loc);
}

// Block -> "{" Question* "}"
ABlock cst2ast(bl:(Block)`{ <Question* qs> }`) {
  return block([ cst2ast(q) | Question q <- qs ], src=bl@\loc);
}

// IfThen -> "if" "(" Expr ")" Block
AIfThen cst2ast(ift:(IfThen)`if ( <Expr expr> ) <Block bl>`) {
  return ifThen(cst2ast(expr), cst2ast(bl), src=ift@\loc);
}

// IfThenElse -> IfThen "else" Block
AIfThenElse cst2ast(ifte:(IfThenElse)`<IfThen ift> else <Block bl>`) {
  return ifThenElse(cst2ast(ift), cst2ast(bl), src=ifte@\loc);
}

// Expr -> ...
AExpr cst2ast(Expr e) {
  switch (e) {
    case e:(Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=e@\loc);
    case e:(Expr)`<Int val>`: return eint(cst2ast(val), src=e@\loc);
    case e:(Expr)`<Bool val>`: return ebool(cst2ast(val), src=e@\loc);
    case e:(Expr)`(<Expr expr>)`: return cst2ast(expr);
    case e:(Expr)`!<Expr expr>`: return not(cst2ast(expr), src=e@\loc);
    case e:(Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> + <Expr rhs>`: return add(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> \> <Expr rhs>`: return greater(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> \< <Expr rhs>`: return less(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case e:(Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

// Type -> "boolean" | "integer" | "string"
AType cst2ast(Type t) {
  return typee("<t>", src=t@\loc);
}

// Lexical: Str -> str
str cst2ast(Str s) {
  return "<s>";
}

// Lexical: Int -> int
int cst2ast(Int val) {
  return toInt("<val>");
}

// Lexical: Bool -> bool
bool cst2ast(Bool val) {
  return fromString("<val>");
}
