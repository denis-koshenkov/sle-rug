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
  switch (atype.typeName) {
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
    tenv += { <nq.id.src, nq.id.name, nq.label, atypeToType(nq.\type)> };
  }
  return tenv;
}

set[Message] startCheck(AForm f) {
  TEnv tenv = collect(f);
  println(tenv);
  UseDef usedef = resolve(f).useDef;
  return check(f, tenv, usedef);
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  for (aq <- f.questions) {
    msgs += check(aq, tenv, useDef);
  }
  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch(q) {
    case qnormal(nq): msgs += check(nq, tenv);
    case qcomputed(cq): msgs += check(cq, tenv, useDef);
    case qIfThen(ifThen): msgs += check(ifThen, tenv, useDef);
    case qIfThenElse(ifThenElse): msgs += check(ifThenElse, tenv, useDef);
  }
  return msgs;
}

set[Message] check(AIfThen ifThen, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += { error("The condition is not of type boolean", ifThen.expr.src) | typeOf(ifThen.expr, tenv, useDef) != tbool()};
  msgs += check(ifThen.expr, tenv, useDef);
  msgs += check(ifThen.block, tenv, useDef);
  return msgs;
}

set[Message] check(AIfThenElse ifThenElse, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  msgs += check(ifThenElse.ifThen, tenv, useDef);
  msgs += check(ifThenElse.block, tenv, useDef);
  return msgs;
}

set[Message] check(ABlock block, TEnv tenv, UseDef useDef) {
set[Message] msgs = {};
  for (q <- block.questions) {
    msgs += check(q, tenv, useDef);
  }
  return msgs;
}

set[Message] check(ANormalQuestion nq, TEnv tenv) {
  set[Message] msgs = {};
  for (defQuestion <- tenv) {
    // produce an error if there are declared questions with the same name but different types.
    if ((defQuestion.name == nq.id.name) && (defQuestion.\type != atypeToType(nq.\type))) {
      msgs += { error("Question with this name already exists, but the type is different", nq.id.src) };
      msgs += { error("Question with this name already exists, but the type is different", defQuestion.def) };
    }
    
    // produce a warning if there are different questions with the same label
    if ((defQuestion.label == nq.label) && (defQuestion.name != nq.id.name)) {
      msgs += { warning("A different question with this label already exists", nq.src) };
      msgs += { warning("A different question with this label already exists", defQuestion.def) };
    }
    
    // produce a warning if there are different labels for occurrences of the same question
    if ((defQuestion.label != nq.label) && (defQuestion.name == nq.id.name)) {
      msgs += { warning("Different labels for the same question", nq.src) };
      msgs += { warning("Different labels for the same question", defQuestion.def) };
    }
  }
  return msgs;
}

set[Message] check(AComputedQuestion cq, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  // produce an error if the type of computed question does not match the type of the expression
  if (atypeToType(cq.nq.\type) != typeOf(cq.expr, tenv, useDef)) {
    msgs += { error("The declared type of the question does not match the type of the expression", cq.nq.\type.src) };  
  }
  msgs += check(cq.nq, tenv);
  msgs += check(cq.expr, tenv, useDef);
  return msgs;
}
  
 
// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
	case not(AExpr nestedExpr): {
	  msgs += { error("Expected expression type: boolean", nestedExpr.src) | typeOf(nestedExpr, tenv, useDef) != tbool() };
	  msgs += check(nestedExpr, tenv, useDef);
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
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
	}
	case less(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
	}
	case leq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
	}
	case geq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
	}
	case eq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
	}
	case neq(AExpr lhs, AExpr rhs): {
	  msgs += errMessagesIntOrStrOperands(lhs, rhs, tenv, useDef);
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

set[Message] errMessagesIntOrStrOperands(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  if (typeOf(lhs, tenv, useDef) == tint()) {
    if (typeOf(rhs, tenv, useDef) != tint())
      msgs += { error("Expected expression type: integer", rhs.src) };
  } else if (typeOf(lhs, tenv, useDef) == tstr()) {
    if (typeOf(rhs, tenv, useDef) != tstr())
      msgs += { error("Expected expression type: string", rhs.src) };
  } else {
    // lhs is neither integer nor string
    if (typeOf(rhs, tenv, useDef) == tint()) {
      msgs += { error("Expected expression type: integer", lhs.src) };
    } else if (typeOf(rhs, tenv, useDef) == tstr()) {
      msgs += { error("Expected expression type: string", lhs.src) };
    } else {
      // lhs and rhs are not string and not integer
      msgs += { error("Expected expression type: integer or string", lhs.src) };
      msgs += { error("Expected expression type: integer or string", rhs.src) };
    }
  }
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
    case greater(_, _): return tbool();
    case less(_, _): return tbool();
    case leq(_, _): return tbool();
    case geq(_, _): return tbool();
    case eq(_, _): return tbool();
    case neq(_, _): return tbool();
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
 
 

