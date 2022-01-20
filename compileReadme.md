# Actions taken on user input

## If the user inputs a string/integer/boolean
All expressions have to reevaluated:
- Expressions that show the results of the computed questions
- Expressions that are guards for if-else

The results of these expressions have to be shown: 
- The questions shown/hidden
- The correct values for computed questions shown


## If the user presses the submit button
Nothing happens?

# Deisgn
In JS, we need just one function that will be called upon entry to any text field (string/integer), and upon checking/unchecking the checkbox. This function needs to update expressions
of computed questions and show/hide the correct questions.

## Evaluating if-statements
Traverse the AST:
- Each normal question at the "top" level is displayed (so empty list of consitions).
- Each computed question at the "top" level is displayed (so empty list of consitions).
- Each IfThen or IfThenElse. Copy the condition directly to JS code, and create an if statement.
In the "if" part, display all questions from the original if part. If there is an else part, add
to the "if" part the non-displaying of all questions in the "else" part.
In the "else" part, display all questions from the original "else" part. Also,
hide all the questions from the otiginal "if" part.

For IfThen:
- Create "if" with the guard.
- Traverse the questions in the original "if" block and add their display to the "if" block. This is simply a call to displayBlock(), which also handles nested IfThens/IfThenElses.
- Create an "else" block and add the non-displaying of all questions in the original "if" block. This is simply a call to hideBlock(), which also hides all nested blocks.

For IfThenElse:
- Create "if" with the guard.
- Traverse the questions in the original "if" block and add them to the "if" block. This is simply a call to displayBlock(), which also handles nested IfThens/IfThenElses. 
- Traverse the questions in the original "else" block and add non-displaying of them to the "if" block. This includes all questions from nested block, since it is a call to hideBlock().
- Traverse the questions in the original "else" block and add the displaying of them to the "else" block. This is a call to displayBlock().
- Create an "else" block and add the non-displaying of all questions in the original "if" block. This is a call to hideBlock().

Functions on IfThen/IfThenElse:
- processIfThen(): creates if, calls displayBlock on the original "if" block. Creates "else", calls hideBlock() on the original "if" block.
- processIfThenElse(): creates if, calls displayBlock on the original "if" block. Calls hideBlock() on the original "else" block. Creates "else", calls displayBlock on the original "else" block. Calls "hideBlock" on the original "if" block.

Functions:
- createIf(AExpr expr):           outputs "if (expr) {"
- displayBlock(ABlock block):     outputs: "display for each question in the block, with recursive calls to process nested blocks"
- hideBlock(ABlock block):        outputs: "hide for each question in the block, including nested blocks"
- createElse():                   outputs: } "else" {
- printClosingCurly():            outputs: "}"



## Computing the values of computed questions
For each computed question, add its expression to the "recomputeQuestions()" function.
Whenever this function is called, the question value will be computed.

## Compilation process to JS
1. Create venv. For each normalQuestion (including ones in computedQuestions), write the
question ID and its default value depending on its type (0, false or "").
2. Write "let valueModified = true;"
3. Copy the "updateValue" function.
4. Create the "showHideQuestions" function.
Traverse the AST do the process described above.
5. Create the "recomputeQuestions" function.
For each computed question, convert AExpr to JS code that computes the expression.
Use Math.floor to enforce integer division. Or shouold I?
Assign the value to the question if in venv. Don't forget the modifiedValue boolean.
6. Create the "showUpdatedComputedValues" function.
For each computed question, create code for updating the value of the HTML node.

