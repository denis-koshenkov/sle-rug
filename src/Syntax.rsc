module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = NormalQuestion
  | ComputedQuestion
  | IfThen
  | IfThenElse
  ;
  
syntax NormalQuestion
  = Str Id ":" Type;
  
syntax ComputedQuestion
  = NormalQuestion "=" "(" Expr ")";
  
syntax Block
  = "{" Question* "}";
  
syntax IfThen
  = "if" "(" Expr ")" Block;
  
syntax IfThenElse
  = IfThen "else" Block;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | bracket "(" Expr ")"
  | right "!" Expr
  > left Expr "*" Expr
  | left Expr "/" Expr
  > left Expr "+" Expr
  | left Expr "-" Expr
  > left Expr "\>" Expr
  | left Expr "\<" Expr
  | left Expr "\<=" Expr
  | left Expr "\>=" Expr
  > left Expr "==" Expr
  | left Expr "!=" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;
  
syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;
  
lexical Str
  = "\"" [^\"]* "\"";

lexical Int 
  = "0"
  | "-"?[1-9][0-9]*
  ;

lexical Bool
  = "true"
  | "false"
  ;



