module Check

import AST;
import Resolve;
import Message; // see standard library

import IO;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;
  
Type atypeToType(AType atype) {
  switch (atype.typee) {
      case "boolean": return tbool();
      case "integer": return tint();
      case "string": return tstr();
      default: return tunknown();
  }
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  tenv = {};
  for (/ANormalQuestion nq := f) {
    tenv += { <nq.id.src, nq.id.name, nq.label, atypeToType(nq.typee)> };
  }
  return tenv;
}

set[Message] startCheck(AForm f) {
  TEnv tenv = collect(f);
  UseDef usedef = resolve(f).useDef;
  return check(f, tenv, usedef);
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  for (/ANormalQuestion q := f) {
    msgs += check(q, tenv, useDef); 
  }
  
  seenLabels = {};
  for (/ANormalQuestion q := f) {
    if (q.label in seenLabels) {
      msgs += { warning("Question with this label already exists", q.src) };
    } else {
      seenLabels += {q.label};
    }
  }
  println(seenLabels);
  
  // Check that the declared type of computed questions matches the type of the expression.
  for (/AComputedQuestion cq := f) {
    msgs += check(cq, tenv, useDef); 
  }
  
  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  
  return {};
}

set[Message] check(AComputedQuestion cq, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  if (atypeToType(cq.nq.typee) != typeOf(cq.expr, tenv, useDef)) {
    msgs += { error("The declared type of the question does not match the type of the expression", cq.src) };  
  }
  msgs += check(cq.expr, tenv, useDef);
  return msgs;
}
  

set[Message] check(ANormalQuestion nq, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  // produce an error if there are declared questions with the same name but different types.
  for (defQuestion <- tenv) {
    if ((defQuestion.name == nq.id.name) && (defQuestion.\type != atypeToType(nq.typee))) {
      msgs += { error("Question with this name already exists, but the type is different", nq.id.src) };
    }
  }
  
  return msgs;
}
 
// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()

// TODO: REVISIT THIS AND ADD SUPPORT FOR E.G. STRING OPERANDS FOR "=="
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	case not(AExpr expr): {
	  msgs += { error("Expected expression type: boolean", expr.src) | typeOf(expr, tenv, useDef) != tbool() }; 
	  msgs += check(expr, tenv, useDef);
	}
	case mul(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case div(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case add(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case sub(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case greater(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case less(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case leq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case geq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case eq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case neq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOperands(lhs, rhs, tenv, useDef);
	}
	case and(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesBoolOperands(lhs, rhs, tenv, useDef);
	}
	case or(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesBoolOperands(lhs, rhs, tenv, useDef);
	}
  }
  return msgs; 
}

set[Message] errMessagesBoolOperands(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += { error("Expected expression type: boolean", lhs.src) | typeOf(lhs, tenv, useDef) != tbool() };
  msgs += { error("Expected expression type: boolean", rhs.src) | typeOf(rhs, tenv, useDef) != tbool() };   
  msgs += check(lhs, tenv, useDef);
  msgs += check(rhs, tenv, useDef);
  return msgs;
}

set[Message] errMessagesIntOperands(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += { error("Expected expression type: integer", lhs.src) | typeOf(lhs, tenv, useDef) != tint() };
  msgs += { error("Expected expression type: integer", rhs.src) | typeOf(rhs, tenv, useDef) != tint() };   
  msgs += check(lhs, tenv, useDef);
  msgs += check(rhs, tenv, useDef);
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case eint(_): return tint();
    case ebool(_): return tbool();
    case not(_): return tbool();
    case mul(_, _): return tint();
    case div(_, _): return tint();
    case add(_, _): return tint();
    case sub(_, _): return tint();
    case greater(_, _): return tint();
    case less(_, _): return tint();
    case leq(_, _): return tint();
    case geq(_, _): return tint();
    case eq(_, _): return tint();
    case neq(_, _): return tint();
    case and(_, _): return tbool();
    case or(_, _): return tbool();
  }
  return tunknown();
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

