%{
// TERMINALS ARE SPECIAL CHARACTERS OR START WITH CAPTIAL ALPHABETS.
// NON-TERMINALS START WITH SMALL ALPHABETS.

// See include files for usage/syntax of "nd", "ej" and "op".

#include <stdio.h>
#include <gfcc_lexer.h>

%}

%union {
	void *node;		// pointer (if node) [use void* to avoid warning - implicit type conversion supported]
	char *terminal;	// lexeme (if terminal)
}

/* Terminals: Don't change this order. */
%token <node> IDENTIFIER CONSTANT STRING_LITERAL // only these three types shall be terminals
%token <node> SIZEOF
%token <node> PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token <node> AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token <node> SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token <node> XOR_ASSIGN OR_ASSIGN TYPE_NAME
%token <node> TYPEDEF EXTERN STATIC AUTO REGISTER
%token <node> CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token <node> STRUCT UNION ENUM ELLIPSIS
%token <node> CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

// Non-Terminals (Add rest, and try in alphabetical order)
%type <node> abstract_declarator additive_expression and_expression argument_expression_list
%type <node> assignment_expression assignment_operator aux cast_expression compound_statement
%type <node> conditional_expression constant_expression declaration declaration_list
%type <node> declaration_specifiers declarator direct_abstract_declarator direct_declarator
%type <node> enumerator enumerator_list enum_specifier equality_expression exclusive_or_expression
%type <node> expression expression_statement external_declaration function_definition
%type <node> identifier_list inclusive_or_expression init_declarator init_declarator_list
%type <node> initializer initializer_list iteration_statement jump_statement labeled_statement
%type <node> logical_and_expression logical_or_expression multiplicative_expression parameter_declaration
%type <node> parameter_list parameter_type_list pointer postfix_expression primary_expression
%type <node> relational_expression selection_statement shift_expression specifier_qualifier_list
%type <node> statement statement_list storage_class_specifier struct_declaration struct_declaration_list
%type <node> struct_declarator struct_declarator_list struct_or_union struct_or_union_specifier
%type <node> translation_unit type_name type_qualifier type_qualifier_list type_specifier
%type <node> unary_expression unary_operator


// Provide types to fixed literals (to avoid warnings)
%type <node> '(' ')' '[' ']' '{' '}'
%type <node> '+' '-' '=' '*' '/' '%'
%type <node> '&' '~' '!' '>' '<' '|' '^'
%type <node> ',' ';' ':' '.'


// Start symbol
%start translation_unit

%%

/***********************************************************************************************/
/************************************** EXPRESSIONS BEGIN **************************************/
/***********************************************************************************************/

primary_expression
	: IDENTIFIER			{ $$ = nd(IDENTIFIER, $1); }
	| CONSTANT				{ $$ = nd(CONSTANT, $1); }
	| STRING_LITERAL		{ $$ = nd(STRING_LITERAL, $1); }
	| '(' expression ')'	{ $$ = $2; }
	;

postfix_expression
	: primary_expression									{ $$ = $1; }
	| postfix_expression '[' expression ']'					{ $$ = op( nd(SUBSCRIPT, $2), 0, 2, ej($1), ej($3) ); }
	| postfix_expression '(' ')'							{ $$ = op( mkGenNode(FUNC_CALL, "() [func-call]", "shape=box"), 0, 1, ej($1) ); }
	| postfix_expression '(' argument_expression_list ')'	{ $$ = op( mkGenNode(FUNC_CALL, "() [func-call]", "shape=box"), 0, 2, ej($1), ej($3) ); }
	| postfix_expression '.' IDENTIFIER						{ $$ = op( nd('.', $2), 0, 2, ej($1), ej(nd(IDENTIFIER, $3)) ); }
	| postfix_expression PTR_OP IDENTIFIER					{ $$ = op( nd(PTR_OP, $2), 0, 2, ej($1), ej(nd(IDENTIFIER, $3)) ); }
	| postfix_expression INC_OP								{ $$ = op( nd(INC_OP, $2), 0, 1, ej($1) ); }
	| postfix_expression DEC_OP								{ $$ = op( nd(DEC_OP, $2), 0, 1, ej($1) ); }
	;

argument_expression_list
	: assignment_expression									{ $$ = op( nd(ARG_EXPR_LIST, "arg-expr-list"), 0, 1, ej($1) ); }
	| argument_expression_list ',' assignment_expression	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

unary_expression
	: postfix_expression				{ $$ = $1; }
	| INC_OP unary_expression			{ $$ = op( nd(INC_OP, $1), 0, 1, ej($2) ); }
	| DEC_OP unary_expression			{ $$ = op( nd(DEC_OP, $1), 0, 1, ej($2) ); }
	| unary_operator cast_expression	{ $$ = op( $1, 0, 1, ej($2) ); }
	| SIZEOF unary_expression			{ $$ = op( nd(SIZEOF, $1), 0, 1, ej($2) ); }
	| SIZEOF '(' type_name ')'			{ $$ = op( nd(SIZEOF, $1), 0, 1, ej($3) ); }
	;

unary_operator
	: '&' { $$ = nd('&', $1); }
	| '*' { $$ = nd('*', $1); }
	| '+' { $$ = nd('+', $1); }
	| '-' { $$ = nd('-', $1); }
	| '~' { $$ = nd('~', $1); }
	| '!' { $$ = nd('!', $1); }
	;

cast_expression
	: unary_expression { $$ = $1; }
	| '(' type_name ')' cast_expression
		{ $$ = op( nd(CAST_EXPR, "cast_expression"), 0, 2, mkGenEdge($2, "type", NULL), mkGenEdge($4, "expression", NULL) ); }
	;

multiplicative_expression
	: cast_expression { $$ = $1; }
	| multiplicative_expression '*' cast_expression { $$ = op( nd('*', $2), 0, 2, ej($1), ej($3) ); }
	| multiplicative_expression '/' cast_expression { $$ = op( nd('/', $2), 0, 2, ej($1), ej($3) ); }
	| multiplicative_expression '%' cast_expression { $$ = op( nd('%', $2), 0, 2, ej($1), ej($3) ); }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { $$ = op( nd('+', $2), 0, 2, ej($1), ej($3) ); }
	| additive_expression '-' multiplicative_expression { $$ = op( nd('-', $2), 0, 2, ej($1), ej($3) ); }
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression	{ $$ = op( nd(LEFT_OP, $2), 0, 2, ej($1), ej($3) ); }
	| shift_expression RIGHT_OP additive_expression	{ $$ = op( nd(RIGHT_OP, $2), 0, 2, ej($1), ej($3) ); }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression	{ $$ = op( nd('<', $2), 0, 2, ej($1), ej($3) ); }
	| relational_expression '>' shift_expression	{ $$ = op( nd('>', $2), 0, 2, ej($1), ej($3) ); }
	| relational_expression LE_OP shift_expression	{ $$ = op( nd(LE_OP, $2), 0, 2, ej($1), ej($3) ); }
	| relational_expression GE_OP shift_expression	{ $$ = op( nd(GE_OP, $2), 0, 2, ej($1), ej($3) ); }
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression	{ $$ = op( nd(EQ_OP, $2), 0, 2, ej($1), ej($3) ); }
	| equality_expression NE_OP relational_expression	{ $$ = op( nd(NE_OP, $2), 0, 2, ej($1), ej($3) ); }
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression { $$ = op( nd('&', $2), 0, 2, ej($1), ej($3) ); }
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression { $$ = op( nd('^', $2), 0, 2, ej($1), ej($3) ); }
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = op( nd('|', $2), 0, 2, ej($1), ej($3) ); }
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { $$ = op( nd(AND_OP, $2), 0, 2, ej($1), ej($3) ); }
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { $$ = op( nd(OR_OP, $2), 0, 2, ej($1), ej($3) ); }
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { $$ = op(
		mkGenNode(-1, "ternary expr (? :)", NULL), 0, 3,
		mkGenEdge($1, "condition", NULL),
		mkGenEdge($3, "expr (if TRUE)", NULL),
		mkGenEdge($5, "expr (if FALSE)", NULL)
	); }
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

assignment_operator
	: '='			{ $$ = nd('=', $1); }
	| MUL_ASSIGN	{ $$ = nd(MUL_ASSIGN, $1); }
	| DIV_ASSIGN	{ $$ = nd(DIV_ASSIGN, $1); }
	| MOD_ASSIGN	{ $$ = nd(MOD_ASSIGN, $1); }
	| ADD_ASSIGN	{ $$ = nd(ADD_ASSIGN, $1); }
	| SUB_ASSIGN	{ $$ = nd(SUB_ASSIGN, $1); }
	| LEFT_ASSIGN	{ $$ = nd(LEFT_ASSIGN, $1); }
	| RIGHT_ASSIGN	{ $$ = nd(RIGHT_ASSIGN, $1); }
	| AND_ASSIGN	{ $$ = nd(AND_ASSIGN, $1); }
	| XOR_ASSIGN	{ $$ = nd(XOR_ASSIGN, $1); }
	| OR_ASSIGN		{ $$ = nd(OR_ASSIGN, $1); }
	;

expression
	: assignment_expression { $$ = $1; }
	| expression ',' assignment_expression { $$ = op( nd(',', $2), 0, 2, ej($1), ej($3) ); }
	// Here, comma is an operator, and is not treated like a list delimiter
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

// EVERYTHING ABOVE THIS COMMENT HAS BEEN TESTED.

/************************************************************************************************/
/************************************* EXPRESSIONS COMPLETE *************************************/
/************************************** DECLARATIONS BEGIN **************************************/
/************************************************************************************************/

// TESTED OK
declaration
	: declaration_specifiers ';'						{ $$ = $1; }
	| declaration_specifiers init_declarator_list ';'	{ $$ = op( nd(DECLARATION, "declaration"), 0, 2, ej($1), ej($2) ); }
	;

// TESTED OK
// A list of three kinds of objects. Also, new child appends to the left.
declaration_specifiers
	: storage_class_specifier							{ $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ej($1) ); }
	| storage_class_specifier declaration_specifiers	{ $$ = op( $2, 1, 0, ej($1) ); }
	| type_specifier									{ $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ej($1) ); }
	| type_specifier declaration_specifiers				{ $$ = op( $2, 1, 0, ej($1) ); }
	| type_qualifier									{ $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ej($1) ); }
	| type_qualifier declaration_specifiers				{ $$ = op( $2, 1, 0, ej($1) ); }
	;

// TESTED OK
init_declarator_list
	: init_declarator							{ $$ = op( nd(INIT_DECL_LIST, "var-list"), 0, 1, ej($1) ); }
	| init_declarator_list ',' init_declarator	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

// TESTED OK
init_declarator
	: declarator					{ $$ = $1; }
	| declarator '=' initializer	{ $$ = op( nd('=', $2), 0, 2, ej($1), ej($3) ); }
	;

// TESTED OK
storage_class_specifier
	: TYPEDEF	{ $$ = nd(TYPEDEF, $1); }
	| EXTERN	{ $$ = nd(EXTERN, $1); }
	| STATIC	{ $$ = nd(STATIC, $1); }
	| AUTO		{ $$ = nd(AUTO, $1); }
	| REGISTER	{ $$ = nd(REGISTER, $1); }
	;

type_specifier
	: VOID							{ $$ = nd(VOID, $1); }
	| CHAR							{ $$ = nd(CHAR, $1); }
	| SHORT							{ $$ = nd(SHORT, $1); }
	| INT							{ $$ = nd(INT, $1); }
	| LONG							{ $$ = nd(LONG, $1); }
	| FLOAT							{ $$ = nd(FLOAT, $1); }
	| DOUBLE						{ $$ = nd(DOUBLE, $1); }
	| SIGNED						{ $$ = nd(SIGNED, $1); }
	| UNSIGNED						{ $$ = nd(UNSIGNED, $1); }
	| struct_or_union_specifier		{ $$ = $1; }
	| enum_specifier				{ $$ = $1; } // TESTED OK
	| TYPE_NAME						{ $$ = nd(TYPE_NAME, $1); } // never encountered in ANSI C (just a user defined type)
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	{$$ = op($1,0,2,ej(nd(IDENTIFIER,$2)),ej($4));}
	| struct_or_union '{' struct_declaration_list '}'
	{$$ = op($1,0,1,ej($3));}
	| struct_or_union IDENTIFIER
	{$$ = op($1,0,1,ej(nd(IDENTIFIER,$2)));}
	;

// TESTED OK
struct_or_union
	: STRUCT	{ $$ = nd(STRUCT, $1); }
	| UNION		{ $$ = nd(UNION, $1); }
	;

struct_declaration_list 
	: struct_declaration {$$ = op(nd(ALL_MEMBERS,"member-list"),0,1,ej($1));}
	| struct_declaration_list struct_declaration 
	{$$=op($1,0,1,ej($2));}
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' 
	{$$ = op(nd(STRUCT_MEMBER,"member"),0,2,ej($1),ej($2));}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list  {$$ = op($2,1,0,ej($1));}
	| type_specifier                           
	{$$ = op(nd(SPEC_QUAL_LIST,"spec-qual"),0,1,ej($1));}
	| type_qualifier specifier_qualifier_list  {$$ = op($2,1,0,ej($1));}
	| type_qualifier			   
	{$$ = op(nd(SPEC_QUAL_LIST,"spec-qual"),0,1,ej($1));}
	;

struct_declarator_list
	: struct_declarator  {$$ = op(nd(INIT_DECL_LIST,"var-list"),0,1,ej($1));}
	| struct_declarator_list ',' struct_declarator {$$ = op($1,0,1,ej($3));}
	;

struct_declarator
	: declarator {$$=$1;}
	| ':' constant_expression  {$$ = $2;}
	| declarator ':' constant_expression 
	{$$ = op(nd(STRUCT_DECL,"declarator"),0,2,ej($1),ej($3));} 
	;

// TESTED OK
enum_specifier
	: ENUM '{' enumerator_list '}'				{ $$ = op( nd(ENUM, $1), 0, 1, ej($3) ); }
	| ENUM IDENTIFIER '{' enumerator_list '}'	{ $$ = op( nd(ENUM, $1), 0, 2, ej(nd(IDENTIFIER, $2)), ej($4) ); }
	| ENUM IDENTIFIER							{ $$ = op( nd(ENUM, $1), 0, 1, ej(nd(IDENTIFIER, $2)) ); }
	;

// TESTED OK
enumerator_list
	: enumerator						{ $$ = op( nd(ENUM_LIST, "enum-list"), 0, 1, ej($1) ); }
	| enumerator_list ',' enumerator	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

// TESTED OK
enumerator
	: IDENTIFIER							{ $$ = nd(IDENTIFIER, $1); }
	| IDENTIFIER '=' constant_expression	{ $$ = op( nd('=', $2), 0, 2, ej(nd(IDENTIFIER, $1)), ej($3) ); }
	;

// TESTE OK
type_qualifier
	: CONST		{ $$ = nd(CONST, $1); }
	| VOLATILE	{ $$ = nd(VOLATILE, $1); }
	;

// TESTED OK
declarator
	: pointer direct_declarator	{ $$ = op( nd(DECLARATOR, "var"), 0, 2, ej($1), ej($2) ); }
	| direct_declarator			{ $$ = $1; }
	;

// TESTED OK
direct_declarator
	: IDENTIFIER									{ $$ = nd(IDENTIFIER, $1); }
	| '(' declarator ')'							{ $$ = $2; }
	| direct_declarator '[' constant_expression ']'	{ $$ = op( nd(SUBSCRIPT, $2), 0, 2, ej($1), ej($3) ); }
	| direct_declarator '[' ']'						{ $$ = op( nd(SUBSCRIPT, $2), 0, 1, ej($1) ); }
	| direct_declarator '(' parameter_type_list ')'	{ $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 2, ej($1), ej($3) ); }
	| direct_declarator '(' identifier_list ')'		{ $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 2, ej($1), ej($3) ); }
	| direct_declarator '(' ')'						{ $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 1, ej($1) ); }
	;

// TESTED OK
pointer
	: '*'								{ $$ = nd(DEREF, $1); }
	| '*' type_qualifier_list			{ $$ = op( nd(DEREF, $1), 0, 1, ej($2) ); }
	| '*' pointer						{ $$ = op( nd(DEREF, $1), 0, 1, ej($2) ); }
	| '*' type_qualifier_list pointer	{ $$ = op( nd(DEREF, $1), 0, 2, ej($2), ej($3) ); }
	;

// TESTED OK
type_qualifier_list
	: type_qualifier						{ $$ = op( nd(TYPE_QUAL_LIST, "type-quals"), 0, 1, ej($1) ); }
	| type_qualifier_list type_qualifier	{ $$ = op( $1, 0, 1, ej($2) ); }
	;

// TESTED OK
parameter_type_list
	: parameter_list				{ $$ = $1; }
	| parameter_list ',' ELLIPSIS	{ $$ = op( $1, 0, 1, ej(nd(ELLIPSIS, $3)) ); }
	;

// TESTED OK
parameter_list
	: parameter_declaration						{ $$ = op( nd(PARAM_TYPE_LIST, "param-types"), 0, 1, ej($1) ); }
	| parameter_list ',' parameter_declaration	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

parameter_declaration
	: declaration_specifiers declarator            { $$ = op( nd(PARAM_DECL, "param-decl"), 0, 2, ej($1), ej($2) ); }
	| declaration_specifiers abstract_declarator   { $$ = op( nd(PARAM_DECL, "param-decl"), 0, 2, ej($1), ej($2) ); }
	| declaration_specifiers                       { $$ = $1; }
	;

identifier_list
	: IDENTIFIER                       { printf("IL1\n"); $$ = op( nd(ID_LIST, "identifiers"), 0, 1, ej(nd(IDENTIFIER, $1)) ); }
	| identifier_list ',' IDENTIFIER   { printf("IL2\n"); $$ = op( $1, 0, 1, ej(nd(IDENTIFIER, $3)) );}
	;

type_name
	: specifier_qualifier_list                        { $$ = op( nd(TYPE_NAME, "type-name"), 0, 1, ej($1) ); }
	| specifier_qualifier_list abstract_declarator    { $$ = op( $1, 0, 1, ej($2) ); }
	;

abstract_declarator
	: pointer                              { $$ = $1; }
	| direct_abstract_declarator           { $$ = $1; }
	| pointer direct_abstract_declarator   { $$ = op( nd(ABSTRACT_DECLARATOR, "abst-decl"), 0, 2, ej($1), ej($2) ); }
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'                                { $$ = $2; }
	| '[' ']'                                                    { $$ = nd(SUBSCRIPT, "[]"); }
	| '[' constant_expression ']'                                { $$ = op(nd(SUBSCRIPT, $1), 0, 1, ej($2)); }
	| direct_abstract_declarator '[' ']'                         { $$ = op( nd(SUBSCRIPT, $2), 0, 1, ej($1) ); }
	| direct_abstract_declarator '[' constant_expression ']'     { $$ = op( nd(SUBSCRIPT, $2), 0, 2, ej($1), ej($3) ); }
	| '(' ')'                                                    { $$ = nd(ABSTRACT_DECLN, "() abst-declaration"); }
	| '(' parameter_type_list ')'                                { $$ = op(nd(ABSTRACT_DECLN, "() abst-declaration"), 0 ,1, ej($2)); }
	| direct_abstract_declarator '(' ')'                         { $$ = op(nd(ABSTRACT_DECLN, "() abst-declaration"), 0 ,1, ej($1)); }
	| direct_abstract_declarator '(' parameter_type_list ')'     { $$ = op( nd(ABSTRACT_DECLN, "() abst-declaration"), 0, 2, ej($1), ej($3) ); }
	;

// TESTED OK
initializer
	: assignment_expression			{ $$ = $1; }
	| '{' initializer_list '}'		{ $$ = $2; }
	| '{' initializer_list ',' '}'	{ $$ = $2; }
	;

// TESTED OK
initializer_list
	: initializer						{ $$ = op( nd(INIT_LIST, "array"), 0, 1, ej($1) ); }
	| initializer_list ',' initializer	{
		/* THIS CODE WORKS, BUT USE ONLY WHEN SIMULTANEOUS PRINTING IS NOT GOING ON */
		// if (((node_t*)$3)->tok_type == INIT_LIST) { // array within an array
		// 	node_t* parent = (node_t*)$3, *tmp = (node_t*)$1;
		// 	int n = parent->numChild;
		// 	for (int i = 0; i < n; i++) {
		// 		tmp = op( tmp, 0, 1, ej(parent->edges[i]->node) );
		// 		// hide edge - ineffective (this code adds NEW invisible edges, but doesn't hide old ones)
		// 		fprintf(temp_out, "\t%lld -> %lld [style = \"invis\"];\n", parent->id, parent->edges[i]->node->id);
		// 	}
		// 	fprintf(temp_out, "\t%lld [style = \"invis\"];\n", parent->id); // hide parent
		// 	free(parent->edges); parent->edges = NULL;
		// 	$$ = tmp;
		// } else $$ = op( $1, 0, 1, ej($3) );
		$$ = op( $1, 0, 1, ej($3) );
	}
	;

statement
	: labeled_statement		{ $$ = $1; }
	| compound_statement	{ $$ = $1; }
	| expression_statement	{ $$ = $1; }
	| selection_statement	{ $$ = $1; }
	| iteration_statement	{ $$ = $1; }
	| jump_statement		{ $$ = $1; }
	;

// TESTED OK
labeled_statement
	: IDENTIFIER ':' statement
		{ $$ = op( mkGenNode(IDENTIFIER, $1, "style=filled,fillcolor=magenta"), 0, 1, ej($3) ); }
	| CASE constant_expression ':' statement
		{ $$ = op( mkGenNode(CASE, $1, "style=filled,fillcolor=magenta"), 0, 2, ej($2), ej($4) ); }
	| DEFAULT ':' statement
		{ $$ = op( mkGenNode(DEFAULT, $1, "style=filled,fillcolor=magenta"), 0, 1, ej($3) ); }
	;

// TESTED OK
compound_statement
	: '{' '}'											{ $$ = nd(EMPTY_BLOCK, "{}"); }
	| '{' statement_list '}'							{ $$ = $2; }
	| '{' declaration_list '}'							{ $$ = $2; }
	| '{' declaration_list statement_list '}'			{ $$ = op( nd(GEN_BLOCK, "block"), 0, 2, ej($2), ej($3) ); }
	;

// TESTED OK
declaration_list
	: declaration					{ $$ = op( nd(DECL_LIST, "declarations"), 0, 1, ej($1) ); }
	| declaration_list declaration	{ $$ = op( $1, 0, 1, ej($2) ); }
	;

// TESTED OK
statement_list
	: statement					{ $$ = op( nd(-1, "stmt-list"), 0, 1, ej($1) ); }
	| statement_list statement	{ $$ = op( $1, 0, 1, ej($2) ); }
	;

// TESTED OK
expression_statement
	: ';'				{ $$ = mkGenNode(';', "; [empty-stmt]", "style=filled,fillcolor=gray"); }
	| expression ';'	{ $$ = $1; }
	;

// TESTED OK
selection_statement
	: IF '(' expression ')' statement { $$ = op(
		mkGenNode(IF_STMT, "if-stmt", "style=filled,fillcolor=yellow"), 0, 2,
		mkGenEdge($3, "cond", NULL), mkGenEdge($5, "stmts", NULL)
	); }
	| IF '(' expression ')' statement ELSE statement { $$ = op(
		mkGenNode(IF_ELSE_STMT, "if-else-stmt", "style=filled,fillcolor=yellow"), 0, 3,
		mkGenEdge($3, "cond", NULL), mkGenEdge($5, "stmts (if TRUE)", NULL), mkGenEdge($7, "stmts (if FALSE)", NULL)
	); }
	| SWITCH '(' expression ')' statement { $$ = op(
		mkGenNode(SWITCH, $1, "style=filled,fillcolor=yellow"), 0, 2,
		mkGenEdge($3, "expr", NULL), mkGenEdge($5, "stmts", NULL)
	); }
	;

iteration_statement
	: WHILE '(' expression ')' statement { $$ = op(
		mkGenNode(WHILE, $1, "style=filled,fillcolor=lightblue"), 0, 2,
		mkGenEdge($3, "expr", NULL), mkGenEdge($5, "stmts", NULL)
	); }
	| DO statement WHILE '(' expression ')' ';' { $$ = op(
		mkGenNode(DO_WHILE, "do-while", "style=filled,fillcolor=lightblue"), 0, 2,
		mkGenEdge($2, "stmts", NULL), mkGenEdge($5, "expr", NULL)
	); }
	| FOR '(' expression_statement expression_statement ')' statement { $$ = op(
		mkGenNode(FOR, $1, "style=filled,fillcolor=lightblue"), 0, 3,
		mkGenEdge($3, "expr", NULL), mkGenEdge($4, "expr", NULL), mkGenEdge($6, "stmts", NULL)
	); }
	| FOR '(' expression_statement expression_statement expression ')' statement  { $$ = op(
		mkGenNode(FOR, $1, "style=filled,fillcolor=lightblue"), 0, 4,
		mkGenEdge($3, "expr", NULL), mkGenEdge($4, "expr", NULL), mkGenEdge($5, "expr", NULL), mkGenEdge($7, "stmts", NULL)
	); }
	;

jump_statement
	: GOTO IDENTIFIER ';'	{ $$ = op( mkGenNode(GOTO, $1, "style=filled,fillcolor=orange"), 0, 1, ej(nd(IDENTIFIER, $2)) ); }
	| CONTINUE ';'			{ $$ = mkGenNode(CONTINUE, $1, "style=filled,fillcolor=orange"); }
	| BREAK ';'				{ $$ = mkGenNode(BREAK, $1, "style=filled,fillcolor=orange"); }
	| RETURN ';'			{ $$ = mkGenNode(RETURN, $1, "style=filled,fillcolor=orange"); }
	| RETURN expression ';'	{ $$ = op( mkGenNode(RETURN, $1, "style=filled,fillcolor=orange"), 0, 1, ej($2) ); }
	;

translation_unit
	: external_declaration					{ $$ = op( mkGenNode(-1, fileName, "shape=box"), 0, 1, ej($1) ); }
	| translation_unit external_declaration	{ $$ = op( $1, 0, 1, ej($2) ); }
	;

external_declaration
	: function_definition		{ $$ = $1; }
	| declaration				{ $$ = $1; }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement { $$ = op(nd(FUNC_DEF,"function_definition"), 0, 3, ej($2), ej($3), ej($4)); }
	| declaration_specifiers declarator compound_statement { $$ = op(nd(FUNC_DEF,"function_definition"), 0, 2, ej($2), ej($3)); }
	| declarator declaration_list compound_statement { $$ = op(nd(FUNC_DEF,"function_definition"), 0, 2, ej($2), ej($3)); }
	| declarator compound_statement { $$ = op(nd(FUNC_DEF,"function_definition"), 0, 1, ej($2)); }
	;

%%

// See tree.c for this part
