module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(AId name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = qnormal(ANormalQuestion nquestion)
  | qcomputed(AComputedQuestion cquestion)
  | qIfThen(AIfThen ifThen)
  | qIfThenElse(AIfThenElse ifThenElse)
  ;
  
data ANormalQuestion(loc src = |tmp:///|)
  = normalQuestion(str label, AId id, AType \type)
  ;
  
data AComputedQuestion(loc src = |tmp:///|)
  = computedQuestion(ANormalQuestion nq, AExpr expr)
  ;
  
data ABlock(loc src = |tmp:///|)
  = block(list[AQuestion] questions)
  ;
  
data AIfThen(loc src = |tmp:///|)
  = ifThen(AExpr expr, ABlock block)
  ;
  
data AIfThenElse(loc src = |tmp:///|)
  = ifThenElse(AIfThen ifThen, ABlock block)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | eint(int intVal)
  | ebool(bool boolVal)
  | not(AExpr expr)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | greater(AExpr lhs, AExpr rhs)
  | less(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = \type(str typeName);