%{
package fakego

%}

%union {
  s string
  sn syntree_node
}

%token VAR_BEGIN;
%token RETURN;
%token BREAK;
%token FUNC;
%token WHILE;
%token FTRUE;
%token FFALSE;
%token IF;
%token THEN;
%token ELSE;
%token END;
%token STRING_DEFINITION;
%token IDENTIFIER;
%token NUMBER;
%token SINGLE_LINE_COMMENT;
%token DIVIDE_MOD;
%token ARG_SPLITTER;
%token PLUS;
%token MINUS;
%token DIVIDE;
%token MULTIPLY;
%token ASSIGN;
%token MORE;
%token LESS;
%token MORE_OR_EQUAL;
%token LESS_OR_EQUAL;
%token EQUAL;
%token NOT_EQUAL;
%token OPEN_BRACKET;
%token CLOSE_BRACKET;
%token AND;
%token OR;
%token FKFLOAT;
%token PLUS_ASSIGN;
%token MINUS_ASSIGN;
%token DIVIDE_ASSIGN;
%token MULTIPLY_ASSIGN;
%token DIVIDE_MOD_ASSIGN;
%token COLON;
%token FOR;
%token INC;
%token FAKE;
%token FKUUID;
%token OPEN_SQUARE_BRACKET;
%token CLOSE_SQUARE_BRACKET;
%token FCONST;
%token PACKAGE;
%token INCLUDE;
%token IDENTIFIER_DOT;
%token IDENTIFIER_POINTER;
%token STRUCT;
%token IS;
%token NOT; 
%token CONTINUE;
%token YIELD;
%token SLEEP;
%token SWITCH;
%token CASE; 
%token DEFAULT;
%token NEW_ASSIGN;
%token ELSEIF;
%token RIGHT_POINTER;
%token STRING_CAT;
%token OPEN_BIG_BRACKET;
%token CLOSE_BIG_BRACKET;
%token FNULL;

%left PLUS MINUS
%left DIVIDE MULTIPLY DIVIDE_MOD
%left STRING_CAT

%%
  

/* Top level rules */
program: package_head
	include_head
	struct_head
	const_head 
	body 
	;
	
package_head:
	/* empty */
	{
	}
	|
	PACKAGE IDENTIFIER
	{
		log_debug("[yacc]: package %v", $2.s);
		l := yylex.(lexerwarpper).mf
		l.set_package($2.s);
	}
	|
	PACKAGE IDENTIFIER_DOT
	{
		log_debug("[yacc]: package %v", $2.s);
		l := yylex.(lexerwarpper).mf
		l.set_package($2.s);
	}
	
include_head:
	/* empty */
	{
	}
	|
	include_define
	|
	include_head include_define
	;
	
include_define:
	INCLUDE STRING_DEFINITION
	{
		log_debug("[yacc]: include %v", $2.s);
		l := yylex.(lexerwarpper).mf
		l.add_include($2.s);
	}
	;

struct_head:
	/* empty */
	{
	}
	|
	struct_define
	|
	struct_head struct_define
	;

struct_define:
	STRUCT IDENTIFIER struct_mem_declaration END
	{
		log_debug("[yacc]: struct_define %v", $2.s);
		l := yylex.(lexerwarpper).mf
		if ($3.sn) != nil {
			p := ($3.sn).(*struct_desc_memlist_node)
			l.add_struct_desc($2.s, p)
		}
	}
	;
	
struct_mem_declaration: 
	/* empty */
	{
		$$.sn = nil
	}
	| 
	struct_mem_declaration IDENTIFIER 
	{
		log_debug("[yacc]: struct_mem_declaration <- IDENTIFIER struct_mem_declaration");
		p := ($1.sn).(*struct_desc_memlist_node)
		p.add_arg($2.s)
		$$.sn = p
	}
	| 
	IDENTIFIER
	{
		log_debug("[yacc]: struct_mem_declaration <- IDENTIFIER");
		p := &struct_desc_memlist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_arg($1.s)
		$$.sn = p
	}
	;

const_head:
	/* empty */
	{
	}
	|
	const_define
	|
	const_head const_define
	;

const_define:
	FCONST IDENTIFIER ASSIGN explicit_value
	{
		log_debug("[yacc]: const_define %v", $2.s);
		l := yylex.(lexerwarpper).mf
		l.add_const_desc($2.s, $4.sn)
	}
	;

body:
	/* empty */
	{
	}
	|
	function_declaration
	|
	body function_declaration
	;

/* function declaration begin */

function_declaration:
	FUNC IDENTIFIER OPEN_BRACKET function_declaration_arguments CLOSE_BRACKET block END
	{
		log_debug("[yacc]: function_declaration <- block %v", $2.s);
		p := &func_desc_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.funcname = $2.s
		if $4.sn != nil {
			p.arglist = $4.sn.(*func_desc_arglist_node)
		}
		p.block = $6.sn.(*block_node)
		l := yylex.(lexerwarpper).mf
		l.add_func_desc(p)
	}
	|
	FUNC IDENTIFIER OPEN_BRACKET function_declaration_arguments CLOSE_BRACKET END
	{
		log_debug("[yacc]: function_declaration <- empty %v", $2.s);
		p := &func_desc_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.funcname = $2.s
		if $4.sn != nil {
                	p.arglist = $4.sn.(*func_desc_arglist_node)
                }
		p.block = nil
		l := yylex.(lexerwarpper).mf
		l.add_func_desc(p)
	}
	;

function_declaration_arguments: 
	/* empty */
	{
		$$.sn = nil
	}
	| 
	function_declaration_arguments ARG_SPLITTER arg 
	{
		log_debug("[yacc]: function_declaration_arguments <- arg function_declaration_arguments");
		p := ($1.sn).(*func_desc_arglist_node)
		p.add_arg($3.s)
		$$.sn = p
	}
	| 
	arg
	{
		log_debug("[yacc]: function_declaration_arguments <- arg");
		p := &func_desc_arglist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_arg($1.s)
		$$.sn = p
	}
	;

arg : 
	IDENTIFIER
	{
		log_debug("[yacc]: arg <- IDENTIFIER %v", $1.s);
		p := &identifier_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		$$.sn = p
	}
	;
	
function_call:
	IDENTIFIER OPEN_BRACKET function_call_arguments CLOSE_BRACKET 
	{
		log_debug("[yacc]: function_call <- function_call_arguments %v", $1.s);
		p := &function_call_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.fuc = $1.s
		p.prefunc = nil
		if $3.sn != nil {
			p.arglist = ($3.sn).(*function_call_arglist_node)
		}
		p.fakecall = false
		p.classmem_call = false
		$$.sn = p
	} 
	|
	IDENTIFIER_DOT OPEN_BRACKET function_call_arguments CLOSE_BRACKET 
	{
		log_debug("[yacc]: function_call <- function_call_arguments %v", $1.s);
		p := &function_call_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.fuc = $1.s
		p.prefunc = nil
		if $3.sn != nil {
			p.arglist = ($3.sn).(*function_call_arglist_node)
		}
		p.fakecall = false
		p.classmem_call = false
		$$.sn = p
	} 
	|
	function_call OPEN_BRACKET function_call_arguments CLOSE_BRACKET 
	{
		log_debug("[yacc]: function_call <- function_call_arguments");
		p := &function_call_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.fuc = ""
		p.prefunc = $1.sn;
		if $3.sn != nil {
			p.arglist = ($3.sn).(*function_call_arglist_node)
		}
		p.fakecall = false
		p.classmem_call = false
		$$.sn = p
	} 
	|
	function_call COLON IDENTIFIER OPEN_BRACKET function_call_arguments CLOSE_BRACKET 
	{
		log_debug("[yacc]: function_call <- mem function_call_arguments %v", $3.s);
		p := &function_call_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.fuc = $3.s
		p.prefunc = nil
		if $5.sn == nil {
			p.arglist = &function_call_arglist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		} else {
			p.arglist = ($5.sn).(*function_call_arglist_node)
		}
		p.arglist.add_arg($1.sn)
		p.fakecall = false
		p.classmem_call = true
		$$.sn = p
	}
	|
	variable COLON IDENTIFIER OPEN_BRACKET function_call_arguments CLOSE_BRACKET 
	{
		log_debug("[yacc]: function_call <- mem function_call_arguments %v", $3.s);
		p := &function_call_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.fuc = $3.s
		p.prefunc = nil
		if $5.sn == nil {
			p.arglist = &function_call_arglist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		} else {
			p.arglist = ($5.sn).(*function_call_arglist_node)
		}
		p.arglist.add_arg($1.sn)
		p.fakecall = false
		p.classmem_call = true
		$$.sn = p
	} 
	;
	
function_call_arguments: 
	/* empty */
	{
		$$.sn = nil
	}
	| 
	function_call_arguments ARG_SPLITTER arg_expr
	{
		log_debug("[yacc]: function_call_arguments <- arg_expr function_call_arguments");
		p := ($1.sn).(*function_call_arglist_node)
		p.add_arg($3.sn)
		$$.sn = p
	}
	| 
	arg_expr
	{
		log_debug("[yacc]: function_call_arguments <- arg_expr");
		p := &function_call_arglist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_arg($1.sn)
		$$.sn = p
	}
	;  

arg_expr:
	expr_value
	{
		log_debug("[yacc]: arg_expr <- expr_value");
		$$.sn = $1.sn
	}
	;

/* function declaration end */

block:
	block stmt 
	{
		log_debug("[yacc]: block <- block stmt");
		p := ($1.sn).(*block_node)
		p.add_stmt($2.sn)
		$$.sn = p
	}
	|
	stmt 
	{
		log_debug("[yacc]: block <- stmt");
		p := &block_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_stmt($1.sn)
		$$.sn = p
	}
	;
  
stmt:
	while_stmt
	{
		log_debug("[yacc]: stmt <- while_stmt");
		$$.sn = $1.sn
	}
	|
	if_stmt
	{
		log_debug("[yacc]: stmt <- if_stmt");
		$$.sn = $1.sn
	}
	|
	return_stmt
	{
		log_debug("[yacc]: stmt <- return_stmt");
		$$.sn = $1.sn
	}
	|
	assign_stmt
	{
		log_debug("[yacc]: stmt <- assign_stmt");
		$$.sn = $1.sn
	}
	|
	multi_assign_stmt
	{
		log_debug("[yacc]: stmt <- multi_assign_stmt");
		$$.sn = $1.sn
	}
	|
	break
	{
		log_debug("[yacc]: stmt <- break");
		$$.sn = $1.sn
	}
	|
	continue
	{
		log_debug("[yacc]: stmt <- continue");
		$$.sn = $1.sn
	}
	|
	expr
	{
		log_debug("[yacc]: stmt <- expr");
		$$.sn = $1.sn
	}
	|
	math_assign_stmt
	{
		log_debug("[yacc]: stmt <- math_assign_stmt");
		$$.sn = $1.sn
	}
	|
	for_stmt
	{
		log_debug("[yacc]: stmt <- for_stmt");
		$$.sn = $1.sn
	}
	|
	for_loop_stmt
	{
		log_debug("[yacc]: stmt <- for_loop_stmt");
		$$.sn = $1.sn
	}
	|
	fake_call_stmt
	{
		log_debug("[yacc]: stmt <- fake_call_stmt");
		$$.sn = $1.sn
	}
	|
	switch_stmt
	{
		log_debug("[yacc]: stmt <- switch_stmt");
		$$.sn = $1.sn
	}
	;

fake_call_stmt:
	FAKE function_call
	{
		log_debug("[yacc]: fake_call_stmt <- fake function_call");
		p := ($2.sn).(*function_call_node)
		p.fakecall = true
		$$.sn = p
	}
	;
	
for_stmt:
	FOR block ARG_SPLITTER cmp ARG_SPLITTER block THEN block END
	{
		log_debug("[yacc]: for_stmt <- block cmp block");
		p := &for_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($4.sn).(*cmp_stmt)
		p.beginblock = ($2.sn).(*block_node)
		p.endblock = ($6.sn).(*block_node)
		p.block = ($8.sn).(*block_node)
		$$.sn = p
	}
	|
	FOR block ARG_SPLITTER cmp ARG_SPLITTER block THEN END
	{
		log_debug("[yacc]: for_stmt <- block cmp");
		p := &for_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($4.sn).(*cmp_stmt)
		p.beginblock = ($2.sn).(*block_node)
		p.endblock = ($6.sn).(*block_node)
		p.block = nil
		$$.sn = p
	}
	;

for_loop_value:
	explicit_value
	{
		log_debug("[yacc]: for_loop_value <- explicit_value");
		$$.sn = $1.sn
	}
	|
	variable
	{
		log_debug("[yacc]: for_loop_value <- variable");
		$$.sn = $1.sn
	}
    ;

for_loop_stmt:
	FOR var ASSIGN for_loop_value RIGHT_POINTER for_loop_value ARG_SPLITTER for_loop_value THEN block END
	{
		log_debug("[yacc]: for_loop_stmt <- block");
		p := &for_loop_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}

		p.iter = $2.sn
		p.begin = $4.sn
		p.end = $6.sn
		p.step = $8.sn
		p.block = $10.sn.(*block_node)

		$$.sn = p
	}
	|
	FOR var ASSIGN for_loop_value RIGHT_POINTER for_loop_value ARG_SPLITTER for_loop_value THEN END
	{
		log_debug("[yacc]: for_loop_stmt <- block");
		p := &for_loop_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}

		p.iter = $2.sn
		p.begin = $4.sn
		p.end = $6.sn
		p.step = $8.sn
		p.block = nil

		$$.sn = p
	}
	;

while_stmt:
	WHILE cmp THEN block END 
	{
		log_debug("[yacc]: while_stmt <- cmp block");
		p := &while_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = ($4.sn).(*block_node)
		$$.sn = p
	}
	|
	WHILE cmp THEN END 
	{
		log_debug("[yacc]: while_stmt <- cmp");
		p := &while_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = nil
		$$.sn = p
	}
	;
	
if_stmt:
	IF cmp THEN block elseif_stmt_list else_stmt END
	{
		log_debug("[yacc]: if_stmt <- cmp block");
		p := &if_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = ($4.sn).(*block_node)
		if $5.sn != nil {
			p.elseifs = ($5.sn).(*elseif_stmt_list)
		}
		if $6.sn != nil {
			p.elses = ($6.sn).(*else_stmt)
		}
		$$.sn = p
	}
	|
	IF cmp THEN elseif_stmt_list else_stmt END
	{
		log_debug("[yacc]: if_stmt <- cmp");
		p := &if_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = nil
		if $4.sn != nil {
			p.elseifs = ($4.sn).(*elseif_stmt_list)
		}
		if $5.sn != nil {
			p.elses = ($5.sn).(*else_stmt)
		}
		$$.sn = p;
	}
	;
	
elseif_stmt_list:
	/* empty */
	{
		$$.sn = nil
	}
	| 
	elseif_stmt_list elseif_stmt
	{
		log_debug("[yacc]: elseif_stmt_list <- elseif_stmt_list elseif_stmt");
		p := ($1.sn).(*elseif_stmt_list)
		p.add_stmt($2.sn)
		$$.sn = p
	}
	| 
	elseif_stmt
	{
		log_debug("[yacc]: elseif_stmt_list <- elseif_stmt");
		p := &elseif_stmt_list{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_stmt($1.sn)
		$$.sn = p
	}
	;
	
elseif_stmt:
	ELSEIF cmp THEN block
	{
		log_debug("[yacc]: elseif_stmt <- ELSEIF cmp THEN block");
		p := &elseif_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = ($4.sn).(*block_node)
		$$.sn = p
	}
	|
	ELSEIF cmp THEN
	{
		log_debug("[yacc]: elseif_stmt <- ELSEIF cmp THEN block");
		p := &elseif_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ($2.sn).(*cmp_stmt)
		p.block = nil
                $$.sn = p
	}
	;
	
else_stmt:
	/*empty*/
	{
		$$.sn = nil
	}
	|
	ELSE block
	{
		log_debug("[yacc]: else_stmt <- block");
		p := &else_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.block = ($2.sn).(*block_node)
                $$.sn = p
	}
	|
	ELSE
	{
		log_debug("[yacc]: else_stmt <- empty");
		p := &else_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.block = nil
                $$.sn = p
	}
	;

cmp:
	OPEN_BRACKET cmp CLOSE_BRACKET
	{
		log_debug("[yacc]: cmp <- ( cmp )");
		$$.sn = $2.sn
	}
	|
	cmp AND cmp
	{
		log_debug("[yacc]: cmp <- cmp AND cmp");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "&&"
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp OR cmp
	{
		log_debug("[yacc]: cmp <- cmp OR cmp");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "||"
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value LESS cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value LESS cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "<"
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value MORE cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value MORE cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ">"
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value EQUAL cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value EQUAL cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "=="
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value MORE_OR_EQUAL cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value MORE_OR_EQUAL cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = ">="
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value LESS_OR_EQUAL cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value LESS_OR_EQUAL cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "<="
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	cmp_value NOT_EQUAL cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value NOT_EQUAL cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "!="
		p.left = $1.sn
		p.right = $3.sn
                $$.sn = p
	}
	|
	FTRUE
	{
		log_debug("[yacc]: cmp <- true");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "true"
		p.left = nil
		p.right = nil
                $$.sn = p
	}
	|
	FFALSE
	{
		log_debug("[yacc]: cmp <- false");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "false"
		p.left = nil
		p.right = nil
                $$.sn = p
	}
	|
	IS cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value IS cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "is"
		p.left = $2.sn
		p.right = nil
                $$.sn = p
	}
	|
	NOT cmp_value
	{
		log_debug("[yacc]: cmp <- cmp_value NOT cmp_value");
		p := &cmp_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = "not";
		p.left = $2.sn
		p.right = nil
                $$.sn = p
	}
	;

cmp_value:
	explicit_value
	{
		log_debug("[yacc]: cmp_value <- explicit_value");
		$$.sn = $1.sn
	}
	|
	variable
	{
		log_debug("[yacc]: cmp_value <- variable");
		$$.sn = $1.sn
	}
	|
	expr
	{
		log_debug("[yacc]: cmp_value <- expr");
		$$.sn = $1.sn
	}
	;
	
return_stmt:
	RETURN return_value_list
	{
		log_debug("[yacc]: return_stmt <- RETURN return_value_list");
		p := &return_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.returnlist = ($2.sn).(*return_value_list_node)
		$$.sn = p
	}
	|
	RETURN
	{
		log_debug("[yacc]: return_stmt <- RETURN");
		p := &return_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.returnlist = nil
		$$.sn = p
	}
	;
 
return_value_list:
	return_value_list ARG_SPLITTER return_value
	{
		log_debug("[yacc]: return_value_list <- return_value_list return_value");
		p := ($1.sn).(*return_value_list_node)
		p.add_arg($3.sn)
		$$.sn = p
	}
	|
	return_value
	{
		log_debug("[yacc]: return_value_list <- return_value");
		p := &return_value_list_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_arg($1.sn)
		$$.sn = p
	}
	;
 
return_value:
	explicit_value
	{
		log_debug("[yacc]: return_value <- explicit_value");
		$$.sn = $1.sn
	}
	|
	variable
	{
		log_debug("[yacc]: return_value <- variable");
		$$.sn = $1.sn
	}
	|
	expr
	{
		log_debug("[yacc]: return_value <- expr");
		$$.sn = $1.sn
	}
	;

assign_stmt:
	var ASSIGN assign_value
	{
		log_debug("[yacc]: assign_stmt <- var assign_value");
		p := &assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.value = $3.sn
		p.isnew = false
		$$.sn = p
	}
	|
	var NEW_ASSIGN assign_value
	{
		log_debug("[yacc]: new assign_stmt <- var assign_value");
		p := &assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.value = $3.sn
		p.isnew = true;
		$$.sn = p
	}
	;

multi_assign_stmt:
	var_list ASSIGN function_call
	{
		log_debug("[yacc]: multi_assign_stmt <- var_list function_call");
		p := &multi_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.varlist = ($1.sn).(*var_list_node)
		p.value = $3.sn
		p.isnew = false
		$$.sn = p
	}
	|
	var_list NEW_ASSIGN function_call
	{
		log_debug("[yacc]: new multi_assign_stmt <- var_list function_call");
		p := &multi_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.varlist = ($1.sn).(*var_list_node)
		p.value = $3.sn
		p.isnew = true
		$$.sn = p
	}
	;
	
var_list:
	var_list ARG_SPLITTER var
	{
		log_debug("[yacc]: var_list <- var_list var");
		p := ($1.sn).(*var_list_node)
		p.add_arg($3.sn)
		$$.sn = p
	}
	|
	var
	{
		log_debug("[yacc]: var_list <- var");
		p := &var_list_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_arg($1.sn)
		$$.sn = p
	}
	;
	
assign_value:
	explicit_value
	{
		log_debug("[yacc]: assign_value <- explicit_value");
		$$.sn = $1.sn
	}
	|
	variable
	{
		log_debug("[yacc]: assign_value <- variable");
		$$.sn = $1.sn
	}
	|
	expr
	{
		log_debug("[yacc]: assign_value <- expr");
		$$.sn = $1.sn
	}
	;
	
math_assign_stmt :
	variable PLUS_ASSIGN assign_value
	{
		log_debug("[yacc]: math_assign_stmt <- variable assign_value");
		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "+="
		p.value = $3.sn
		$$.sn = p
	}
	|
	variable MINUS_ASSIGN assign_value
	{
		log_debug("[yacc]: math_assign_stmt <- variable assign_value");
		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "-="
		p.value = $3.sn
		$$.sn = p
	}
	|
	variable DIVIDE_ASSIGN assign_value
	{
		log_debug("[yacc]: math_assign_stmt <- variable assign_value");
		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "/="
		p.value = $3.sn
		$$.sn = p
	}
	|
	variable MULTIPLY_ASSIGN assign_value
	{
		log_debug("[yacc]: math_assign_stmt <- variable assign_value");
		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "*="
		p.value = $3.sn
		$$.sn = p
	}
	|
	variable DIVIDE_MOD_ASSIGN assign_value
	{
		log_debug("[yacc]: math_assign_stmt <- variable assign_value");
		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "%="
		p.value = $3.sn
		$$.sn = p
	}
	|
	variable INC
	{
		log_debug("[yacc]: math_assign_stmt <- variable INC");
		pp := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		pp.str = "1"
		pp.ty = EVT_NUM

		p := &math_assign_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.vr = $1.sn
		p.oper = "+="
		p.value = pp
		$$.sn = p
	}
	;
	
var:
	VAR_BEGIN IDENTIFIER
	{
		log_debug("[yacc]: var <- VAR_BEGIN IDENTIFIER %v", $2.s);
		p := &var_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $2.s
		$$.sn = p
	}
	|
	variable
	{
		log_debug("[yacc]: var <- variable");
		$$.sn = $1.sn
	}
	;

variable:
	IDENTIFIER
	{
		log_debug("[yacc]: variable <- IDENTIFIER %v", $1.s);
		p := &variable_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		$$.sn = p
	}
	|
	IDENTIFIER OPEN_SQUARE_BRACKET expr_value CLOSE_SQUARE_BRACKET
	{
		log_debug("[yacc]: container_get_node <- IDENTIFIER[expr_value] %v", $1.s);
		p := &container_get_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.container = $1.s
		p.key = $3.sn
		$$.sn = p
	}
	|
	IDENTIFIER_POINTER
	{
		log_debug("[yacc]: variable <- IDENTIFIER_POINTER %v", $1.s);
		p := &struct_pointer_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		$$.sn = p
	}
	|
	IDENTIFIER_DOT
	{
		log_debug("[yacc]: variable <- IDENTIFIER_DOT %v", $1.s);
		p := &variable_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		$$.sn = p
	}
	;

expr:
	OPEN_BRACKET expr CLOSE_BRACKET
	{
		log_debug("[yacc]: expr <- (expr)");
		$$.sn = $2.sn
	}
	|
	function_call
	{
		log_debug("[yacc]: expr <- function_call");
		$$.sn = $1.sn
	}
	|
	math_expr
	{
		log_debug("[yacc]: expr <- math_expr");
		$$.sn = $1.sn
	}
	;

math_expr:
	OPEN_BRACKET math_expr CLOSE_BRACKET
	{
		log_debug("[yacc]: math_expr <- (math_expr)");
		$$.sn = $2.sn
	}
	|
	expr_value PLUS expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = "+"
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	|
	expr_value MINUS expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = "-"
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	|
	expr_value MULTIPLY expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = "*"
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	|
	expr_value DIVIDE expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = "/"
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	|
	expr_value DIVIDE_MOD expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = "%"
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	|
	expr_value STRING_CAT expr_value
	{
		log_debug("[yacc]: math_expr <- expr_value %v expr_value", $2.s);
		p := &math_expr_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.oper = ".."
		p.left = $1.sn
		p.right = $3.sn
		$$.sn = p
	}
	;	

expr_value:
	math_expr
	{
		log_debug("[yacc]: expr_value <- math_expr");
		$$.sn = $1.sn
	}
	|
	explicit_value
	{
		log_debug("[yacc]: expr_value <- explicit_value");
		$$.sn = $1.sn
	}
	|
	function_call
	{
		log_debug("[yacc]: expr_value <- function_call");
		$$.sn = $1.sn
	}
	|
	variable
	{
		log_debug("[yacc]: expr_value <- variable");
		$$.sn = $1.sn
	}
	;
	
explicit_value:
	FTRUE 
	{
		log_debug("[yacc]: explicit_value <- FTRUE");
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_TRUE
		$$.sn = p
	}
	|
	FFALSE 
	{
		log_debug("[yacc]: explicit_value <- FFALSE");
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_FALSE
		$$.sn = p
	}
	|
	NUMBER 
	{
		log_debug("[yacc]: explicit_value <- NUMBER %v", $1.s);
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_NUM
		$$.sn = p
	}
	|
	FKUUID
	{
		log_debug("[yacc]: explicit_value <- FKUUID %v", $1.s);
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_UUID
		$$.sn = p
	}
	|
	STRING_DEFINITION 
	{
		log_debug("[yacc]: explicit_value <- STRING_DEFINITION %v", $1.s);
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_STR
		$$.sn = p
	}
	|
	FKFLOAT
	{
		log_debug("[yacc]: explicit_value <- FKFLOAT %v", $1.s);
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_FLOAT
		$$.sn = p
	}
	|
	FNULL
	{
		log_debug("[yacc]: explicit_value <- FNULL %v", $1.s);
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = $1.s
		p.ty = EVT_NULL
		$$.sn = p
	}
	|
	OPEN_BIG_BRACKET const_map_list_value CLOSE_BIG_BRACKET
	{
		log_debug("[yacc]: explicit_value <- const_map_list_value");
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = ""
		p.ty = EVT_MAP
		p.v = $2.sn
		$$.sn = p
	}
	|
	OPEN_SQUARE_BRACKET const_array_list_value CLOSE_SQUARE_BRACKET
	{
		log_debug("[yacc]: explicit_value <- const_array_list_value");
		p := &explicit_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.str = ""
		p.ty = EVT_ARRAY
		p.v = $2.sn
		$$.sn = p
	}
	;
      
const_map_list_value:
	/* empty */
	{
		log_debug("[yacc]: const_map_list_value <- null");
		p := &const_map_list_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		$$.sn = p
	}
	|
	const_map_value
	{
		log_debug("[yacc]: const_map_list_value <- const_map_value");
		p := &const_map_list_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_ele($1.sn)
		$$.sn = p
	}
	|
	const_map_list_value const_map_value
	{
		log_debug("[yacc]: const_map_list_value <- const_map_list_value const_map_value");
		p := ($1.sn).(*const_map_list_value_node)
		p.add_ele($2.sn)
		$$.sn = p
	}
	;
	
const_map_value:
	explicit_value COLON explicit_value
	{
		log_debug("[yacc]: const_map_value <- explicit_value");
		p := &const_map_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.k = $1.sn
		p.v = $3.sn
		$$.sn = p
	}
	;

const_array_list_value:
	/* empty */
	{
		log_debug("[yacc]: const_array_list_value <- null");
		p := &const_array_list_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		$$.sn = p
	}
	|
	explicit_value
	{
		log_debug("[yacc]: const_array_list_value <- explicit_value");
		p := &const_array_list_value_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_ele($1.sn)
		$$.sn = p
	}
	|
	const_array_list_value explicit_value
	{
		log_debug("[yacc]: const_array_list_value <- const_array_list_value explicit_value");
		p := ($1.sn).(*const_array_list_value_node)
		p.add_ele($2.sn)
		$$.sn = p
	}
	;
	
break:
	BREAK 
	{
		log_debug("[yacc]: break <- BREAK");
		p := &break_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		$$.sn = p
	}
	;
	
continue:
	CONTINUE 
	{
		log_debug("[yacc]: CONTINUE");
		p := &continue_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		$$.sn = p
	}
	;

switch_stmt:
	SWITCH cmp_value switch_case_list DEFAULT block END
	{
		log_debug("[yacc]: switch_stmt");
		p := &switch_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = $2.sn
		p.caselist = $3.sn
		p.def = $5.sn
		$$.sn = p
	}
	|
	SWITCH cmp_value switch_case_list DEFAULT END
	{
		log_debug("[yacc]: switch_stmt");
		p := &switch_stmt{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = $2.sn
		p.caselist = $3.sn
		p.def = nil
		$$.sn = p
	}
	;
	
switch_case_list:
	switch_case_define
	{
		log_debug("[yacc]: switch_case_list <- switch_case_define");
		p := &switch_caselist_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.add_case($1.sn)
		$$.sn = p
	}
	|
	switch_case_list switch_case_define
	{
		log_debug("[yacc]: switch_case_list <- switch_case_list switch_case_define");
		p := ($1.sn).(*switch_caselist_node)
		p.add_case($2.sn)
		$$.sn = p
	}
	;

switch_case_define:
	CASE cmp_value THEN block
	{
		log_debug("[yacc]: switch_case_define");
		p := &switch_case_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = $2.sn
		p.block = $4.sn
		$$.sn = p
	}
	|
	CASE cmp_value THEN
	{
		log_debug("[yacc]: switch_case_define");
		p := &switch_case_node{syntree_node_base: syntree_node_base{yylex.(lexerwarpper).yyLexer.(*Lexer).Line()}}
		p.cmp = $2.sn
		p.block = nil
		$$.sn = p
	}
	;
	
%%

func init() {
	yyErrorVerbose = true // set the global that enables showing full errors
}