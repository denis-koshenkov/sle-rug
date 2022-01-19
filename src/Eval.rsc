module Eval

import AST;
import Resolve;

import IO;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv venv = ();
  for (/ANormalQuestion q := f) {
    switch (q.\type.typeName) {
      case "boolean": venv += (q.id.name : vbool(false));
      case "integer": venv += (q.id.name : vint(0));
      case "string": venv += (q.id.name : vstr(""));
    }
  }
  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (q <- f.questions) {
    venv = eval(q, inp, venv);
  }
  return venv; 
}

// evaluate conditions for branching,
// evaluate inp and computed questions to return updated VEnv
VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch (q) {
    case qnormal(nq): {
      // Update this question if inp updates it
      if (nq.id.name == inp.question) {
        venv[nq.id.name] = inp.\value;
        print("Updated: ");
        print(nq.id.name);
        print(" to ");
        println(inp.\value);
      }
    }
    
    case qcomputed(cq): {
      // Evaluate the expression of the computed question
      venv[cq.nq.id.name] = eval(cq.expr, venv);
    }
    
    case qIfThen(ifThen): {
      // If the condition is true, evaluate all questions in the block
      if (eval(ifThen.expr, venv) == vbool(true)) {
        for (nestedQ <- ifThen.block.questions) {
          venv = eval(nestedQ, inp, venv);
        }
      }
    }
    
    case qIfThenElse(ifThenElse): {
      if (eval(ifThenElse.ifThen.expr, venv) == vbool(true)) {
        // Evaluate questions in the "if" block if the condition is true
        for (nestedQ <- ifThenElse.ifThen.block.questions) {
          venv = eval(nestedQ, inp, venv);
        }
      } else {
      	// Evaluate questions in the "else" block if the condition is false
        for (nestedQ <- ifThenElse.block.questions) {
          venv = eval(nestedQ, inp, venv);
        }
      }
    }
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case eint(int intVal): return vint(intVal);
    case ebool(bool boolVal): return vbool(boolVal);
    case estr(str strVal): return vstr(strVal);
    case not(AExpr nestedExpr): return vbool(!(eval(nestedExpr, venv).b));
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case greater(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsGreater(lhs, rhs, venv);
    case less(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsLess(lhs, rhs, venv);
    case leq(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsLeq(lhs, rhs, venv);
    case geq(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsGeq(lhs, rhs, venv);
    case equal(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsEq(lhs, rhs, venv);
    case neq(AExpr lhs, AExpr rhs): return resolveIntOrStrOperandsNeq(lhs, rhs, venv);
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    default: throw "Unsupported expression <e>";
  }
}

Value resolveIntOrStrOperandsGreater(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n > evalRhs.n);
    case vstr(_): return vbool(evalLhs.s > evalRhs.s);
    default: throw "Wrong operands type";
  }
}

Value resolveIntOrStrOperandsLess(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n < evalRhs.n);
    case vstr(_): return vbool(evalLhs.s < evalRhs.s);
    default: throw "Wrong operands type";
  }
}

Value resolveIntOrStrOperandsLeq(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n <= evalRhs.n);
    case vstr(_): return vbool(evalLhs.s <= evalRhs.s);
    default: throw "Wrong operands type";
  }
}

Value resolveIntOrStrOperandsGeq(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n >= evalRhs.n);
    case vstr(_): return vbool(evalLhs.s >= evalRhs.s);
    default: throw "Wrong operands type";
  }
}

Value resolveIntOrStrOperandsEq(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n == evalRhs.n);
    case vstr(_): return vbool(evalLhs.s == evalRhs.s);
    default: throw "Wrong operands type";
  }
}

Value resolveIntOrStrOperandsNeq(AExpr lhs, AExpr rhs, VEnv venv) {
  Value evalLhs = eval(lhs, venv);
  Value evalRhs = eval(rhs, venv);
  switch (evalLhs) {
    case vint(_): return vbool(evalLhs.n != evalRhs.n);
    case vstr(_): return vbool(evalLhs.s != evalRhs.s);
    default: throw "Wrong operands type";
  }
}