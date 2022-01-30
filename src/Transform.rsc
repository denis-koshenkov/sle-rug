module Transform

import Syntax;
import Resolve;
import AST;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return form(f.name, flattenQuestionsList(f.questions, ebool(true)));
}

// Flattens the given list of questions.
// The given condition is the condition that should be applied to each of the questions
// (and possibly other conditions, in case of nested if-then-(else) constructs).
list[AQuestion] flattenQuestionsList(list[AQuestion] questions, AExpr condition) {
  list[AQuestion] result = [];
  for (AQuestion q <- questions) {
    result += flattenQuestion(q, condition);
  }
  return result;
}

list[AQuestion] flattenQuestion(AQuestion q, AExpr condition) {
  switch(q) {
    case qnormal(_): {
      return [qIfThen(ifThen(condition, block([q])))];
    }
    case qcomputed(_): {
      return [qIfThen(ifThen(condition, block([q])))];
    }
    case qIfThen(ifThen): {
      return flattenQuestionsList(ifThen.block.questions, and(condition, ifThen.expr));
    }
    case qIfThenElse(ifThenElse): {
      return flattenQuestionsList(ifThenElse.ifThen.block.questions, and(condition, ifThenElse.ifThen.expr)) 
      + flattenQuestionsList(ifThenElse.block.questions, and(condition, not(ifThenElse.ifThen.expr)));
    }
    default: throw("The provided AQuestion is not supported.");
  }
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
 } 
 
 
 

