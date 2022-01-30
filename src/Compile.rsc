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
  '  \<input type=\"<getHTMLInputType(q.\type)>\" id=\"<q.id.name>\" name=\"q.id.name\" onchange=\"updateValue(this);\"\>\<br\>\<br\>
  '\</div\>
  '";
}

// Converts a single computed to HTML
str computedQuestionToHTML(AComputedQuestion q) {
  return "
  '\<div id=\"<q.nq.id.name>Q\" style=\"display: none\"\>
  '  \<label for=\"<q.nq.id.name>\"\><q.nq.label>\</label\>\<br\>
  '  \<input type=\"<getHTMLInputType(q.nq.\type)>\" id=\"<q.nq.id.name>\" name=\"q.id.name\" disabled\>\<br\>\<br\>
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
    default: throw("Wrong abstract type! Cannot generate HTML tpye for it.");
  }
}

str form2js(AForm f) {
  return "";
}
