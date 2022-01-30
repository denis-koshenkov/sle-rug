module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

//-------------------------------------- HTML compilation -------------------------------------------------

// Generates HTML code for Aform
// Form fields for each question will be generated, but
// all of them will be set to invisible by doing style="display: none".
// JS will be in charge of displaying all the right questions depending
// on the evaluation of guards.
HTML5Node form2html(AForm f) {
  return html("
    '  \<head\>
    '    \<title\><f.name.name>\</title\>
	'    \<script src=\"<f.src[extension="js"].file>\"\>\</script\>
    '  \</head\>
    '  \<body\>
	'    \<form name=\"<f.name.name>Form\" action=\"\"\>
	'      <questionsToHTML(f.questions)>
	'      \<input type=\"submit\" value=\"Submit\"\>
	'    \</form\>
	'  \</body\>
    '");
}

// Converts a list of AQuestions to HTML
str questionsToHTML(list[AQuestion] questions) {
  str res = "";
  for (AQuestion q <- questions) { 
    res += qToHTML(q); 
  }
  return res;
}

// Convets a single AQuestion to HTML
str qToHTML(AQuestion q) {
  switch(q) {
    case qnormal(nq): {
      return normalQuestionToHTML(nq);
    }
    case qcomputed(cq): {
      return computedQuestionToHTML(cq);
    }
    case qIfThen(ifThen): {
      return questionsToHTML(ifThen.block.questions);
    }
    case qIfThenElse(ifThenElse): {
      // Generate code for both "then" and "else" blocks
      return questionsToHTML(ifThenElse.ifThen.block.questions) + questionsToHTML(ifThenElse.block.questions);
    }
    default: throw("Wrong question provided! Cannot generate HTML code.");
  }
}

// Converts a single normal (non-computed question) to HTML
str normalQuestionToHTML(ANormalQuestion q) {
  return "
  '\<div id=\"<q.id.name>Q\" style=\"display: none\"\>
  '  \<label for=\"<q.id.name>\"\><q.label>\</label\>\<br\>
  '  \<input type=\"<getHTMLInputType(q.\type)>\" id=\"<q.id.name>\" name=\"<q.id.name>\" onchange=\"updateValue(this);\"\>\<br\>\<br\>
  '\</div\>
  '";
}

// Converts a single computed to HTML
str computedQuestionToHTML(AComputedQuestion q) {
  return "
  '\<div id=\"<q.nq.id.name>Q\" style=\"display: none\"\>
  '  \<label for=\"<q.nq.id.name>\"\><q.nq.label>\</label\>\<br\>
  '  \<input type=\"<getHTMLInputType(q.nq.\type)>\" id=\"<q.nq.id.name>\" name=\"<q.nq.id.name>\" disabled\>\<br\>\<br\>
  '\</div\>
  '";
}

// Given an asbtract type, returns the string representation of
// the corresponding "type" attribute of the "input" HTML element
str getHTMLInputType(AType \type) {
  switch(\type.typeName) {
    case "boolean": return "checkbox";
    case "integer": return "number";
    case "string": return "text";
    default: throw("Wrong abstract type! Cannot generate HTML type for it.");
  }
}

//-------------------------------------- JS compilation -------------------------------------------------

// Generates JS code for the given form
str form2js(AForm f) {
  return generateVenvJs(f) + 
  "
  'let valueModified = true;
  '
  'window.addEventListener(\"DOMContentLoaded\", (event) =\> {
  '  showUpdatedComputedValues();
  '  showHideQuestions();
  '});
  '
  'function updateValue(node) {
  '  if (node.type == \"checkbox\") {
  '    venv[node.id] = node.checked;
  '  } else if (node.type == \"number\") {
  '    let numValue = Number(node.value);
  '    if (Number.isNaN(numValue) || !Number.isSafeInteger(numValue)) {
  '      alert(\"Only integers between -(2^53 - 1) and 2^53 - 1 are accepted. Please try again.\");
  '      return;
  '	   } else {
  '      venv[node.id] = node.value;
  '    }
  '  } else {
  '    // A string text field was entered into
  '    venv[node.id] = node.value;
  '  }
  '  recomputeQuestions();
  '  while (valueModified) {
  '    recomputeQuestions();
  '  }
  '  showUpdatedComputedValues();
  '  showHideQuestions();
  '}
  " 
  + generateFunctionShowHideQuestions(f)
  + generateFunctionRecomputeQuestions(f)
  + generateFunctionShowUpdatedComputedValues(f)
  ;
}

// Generates JS code for the function ShowUpdatedComputedValues()
// It modifies HTML nodes of computed question and sets them
// to their current venv values
str generateFunctionShowUpdatedComputedValues(AForm f) {
  return "
  'function showUpdatedComputedValues() {
  '  <generateShowUpdatedComputedValues(f)>
  '}
  ";
}

// Generates JS code to update the HTML nodes
// of all computed questions
str generateShowUpdatedComputedValues(AForm f) {
  str res = "";
  for (/AComputedQuestion cq := f) {
    res += genShowUpdatedComputedQuestion(cq);
  }
  return res;
}

// Generates JS code to update the HTML node of a computed question
// according to its value in the venv
str genShowUpdatedComputedQuestion(AComputedQuestion cq) {
  return "document.getElementById(\"<cq.nq.id.name>\").value = venv[\"<cq.nq.id.name>\"];\n";
}


// Generates JS code for the function "recomputeQuestions()".
// This function recomputes the values of the computed questions
// according to the values in venv, and stores the result also in venv.
str generateFunctionRecomputeQuestions(AForm f) {
  return "
  'function recomputeQuestions() {
  '  valueModified = false;
  '  <for (/AComputedQuestion cq := f) {>
  '    <genRecomputeQuestion(cq)><}>
  '}
  ";
}

// Generates JS code to recompute the given computed question.
// Sets valueModified to "true" if the value of the question gets modified.
// This value helps mimic Rascal's "solve" construct.
str genRecomputeQuestion(AComputedQuestion cq) {
  return "
  'if (venv[\"<cq.nq.id.name>\"] != (<expr2JsCode(cq.expr)>)) {
  '  venv[\"<cq.nq.id.name>\"] = (<expr2JsCode(cq.expr)>);
  '  valueModified = true;
  '}
  ";
}

// Given an AForm, generate JS code for the "showHideQuestions" function.
// This function shows/hides questions according to the current values of 
// the variables in the venv.
str generateFunctionShowHideQuestions(AForm f) {
  return "
  'function showHideQuestions() {
  '  <generateShowHideQuestions(f.questions, true)>
  '}
  ";
}

// Given a list of abstract questions, shows or hides them 
// (and all of their potential nested questions, according to the boolean "show"
str generateShowHideQuestions(list[AQuestion] questions, bool show) {
  str res = "";
  for (AQuestion q <- questions) { 
    res += generateShowHideQuestion(q, show) + "\n"; 
  }
  return res;
}

// Given an abstract question, shows or hides it (and all its potential nested questions)
// according to the boolean "show"
str generateShowHideQuestion(AQuestion q, bool show) {
  switch(q) {
    case qnormal(nq): {
      if (show) {
        return genShowQuestion(nq.id.name);
      } else {
        return genHideQuestion(nq.id.name);
      }
    }
    case qcomputed(cq): {
      if (show) {
        return genShowQuestion(cq.nq.id.name);
      } else {
        return genHideQuestion(cq.nq.id.name);
      }
    }
    case qIfThen(ifThen): {
      return genShowHideIfThen(ifThen, show);
    }
    case qIfThenElse(ifThenElse): {
      return genShowHideIfThenElse(ifThenElse, show);
    }
    default: throw("Wrong question provided! Cannot generate JS code.");
  }
}

// Generates code to show or hide all questions (including nested ifThen(Else) blocks)
// in the ifThen block, depending on the guard.
str genShowHideIfThen(AIfThen ifThen, bool show) {
  if (show) {
    return "
    'if (<expr2JsCode(ifThen.expr)>) {
    ' <generateShowHideQuestions(ifThen.block.questions, true)>
    '} else {
    ' <generateShowHideQuestions(ifThen.block.questions, false)>
    '}";
  } else {
    // Hide all questions in the "then block"
    return "<generateShowHideQuestions(ifThen.block.questions, false)>";
  }
}

// Generates code to toggle between showing/hiding questions in the "then"
// block or in the "else" block, depending on the guard.
str genShowHideIfThenElse(AIfThenElse ifThenElse, bool show) {
  if (show) {
    return "
    'if (<expr2JsCode(ifThenElse.ifThen.expr)>) {
    ' <generateShowHideQuestions(ifThenElse.ifThen.block.questions, true)>
    ' <generateShowHideQuestions(ifThenElse.block.questions, false)>
    '} else {
    ' <generateShowHideQuestions(ifThenElse.ifThen.block.questions, false)>
    ' <generateShowHideQuestions(ifThenElse.block.questions, true)>
    '}";
  } else {
    // Hide all questions, both in "then" and "else" blocks
    return "
    ' <generateShowHideQuestions(ifThenElse.ifThen.block.questions, false)>
    ' <generateShowHideQuestions(ifThenElse.block.questions, false)>
    "; 
  }
}

// Generates JS code to show question with id name
str genShowQuestion(str name) {
  return "document.getElementById(\"<name>Q\").style.display = \'\';";
}

// Generates JS code to hide question with id name
str genHideQuestion(str name) {
  return "document.getElementById(\"<name>Q\").style.display = \'none\';";
}

// Generates a string representation of an expression
// in JS code
str expr2JsCode(AExpr expr) {
  switch(expr) {
    case ref(id(str x)): return "venv[\"<x>\"]";
    case eint(int intVal): return "<intVal>";
    case ebool(bool boolVal): return "<boolVal>";
    case estr(str strVal): return strVal;
    case not(AExpr nestedExpr): return "!(<expr2JsCode(nestedExpr)>)";
    case mul(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) * (<expr2JsCode(rhs)>)";
    case div(AExpr lhs, AExpr rhs): return "Math.floor((<expr2JsCode(lhs)>) / (<expr2JsCode(rhs)>))";
    case add(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) + (<expr2JsCode(rhs)>)";
    case sub(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) - (<expr2JsCode(rhs)>)";
    case greater(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) \> (<expr2JsCode(rhs)>)";
    case less(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) \< (<expr2JsCode(rhs)>)";
    case leq(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) \<= (<expr2JsCode(rhs)>)";
    case geq(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) \>= (<expr2JsCode(rhs)>)";
    case equal(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) == (<expr2JsCode(rhs)>)";
    case neq(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) != (<expr2JsCode(rhs)>)";
    case and(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) && (<expr2JsCode(rhs)>)";
    case or(AExpr lhs, AExpr rhs): return "(<expr2JsCode(lhs)>) || (<expr2JsCode(rhs)>)";
    default: throw "Unsupported expression <expr>";
  }
}

// --------------------------- Generate Venv for JS --------------------------------------------

// Generates the declaration of the "venv" object in JS
str generateVenvJs(AForm f) {
  return "venv = {<for (/ANormalQuestion q := f) {>
  '  <getVenvFieldForQuestion(q)><}>
  '}
  '";
}

// Generates a line for the declaration of the venv object.
// Uses the id of the question and the default value of the question according to its type
str getVenvFieldForQuestion(ANormalQuestion q) {
  return "\"<q.id.name>\": <getDefaultValue(q.\type)>,";
}

// Given an Abstract type, return a string representation
// of the default value for that AType (0 for integers, "" for strings etc)
str getDefaultValue(AType \type) {
  switch(\type.typeName) {
    case "boolean": return "false";
    case "integer": return "0";
    case "string": return "\"\"";
    default: throw("Wrong abstract type!");
  }
}
