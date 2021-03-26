%{
// TERMINALS ARE SPECIAL CHARACTERS OR START WITH CAPTIAL ALPHABETS.
// NON-TERMINALS START WITH SMALL ALPHABETS.

// See include files for usage/syntax of "nd", "ej" and "op".

#include <cstdio>
#include <cstdlib>
#include <gfcc_lexer.h>
#include <symtab.h>
#include <typo.h>

edge_t* ek(void* child) {
	return mkEdge((node_t*) child);
}

// sr->pushSym(((node_t*) $1)->label, 0);

%}

%union {
	void *node;		// pointer (if node) [use void* to avoid warning - implicit type conversion supported]
	const char *terminal;	// lexeme (if terminal)
}

/* Terminals: Don't change this order. */
%token <terminal> IDENTIFIER CONSTANT STRING_LITERAL // only these three types shall be terminals
%token <terminal> SIZEOF FILE_OBJ
%token <terminal> PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token <terminal> AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token <terminal> SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token <terminal> XOR_ASSIGN OR_ASSIGN TYPE_NAME
%token <terminal> TYPEDEF EXTERN STATIC AUTO REGISTER
%token <terminal> CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token <terminal> STRUCT UNION ENUM ELLIPSIS
%token <terminal> CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

// Non-Terminals (Add rest, and try in alphabetical order)
%type <node> abstract_declarator additive_expression and_expression argument_expression_list
%type <node> assignment_expression assignment_operator cast_expression compound_statement
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

/* %type <node> return_token */

// Provide types to fixed literals (to avoid warnings)
%type <terminal> '(' ')' '[' ']' '{' '}'
%type <terminal> '+' '-' '=' '*' '/' '%'
%type <terminal> '&' '~' '!' '>' '<' '|' '^'
%type <terminal> ',' ';' ':' '.'


// Start symbol
%start translation_unit

%%

/***********************************************************************************************/
/************************************** EXPRESSIONS BEGIN **************************************/
/***********************************************************************************************/

primary_expression
	: IDENTIFIER			{ $$ = (node_t*) $1; }
	| CONSTANT				{ $$ = nd(CONSTANT, $1); }
	| STRING_LITERAL		{ $$ = nd(STRING_LITERAL, $1); }
	| '(' expression ')'	{ $$ = $2; }
	;

postfix_expression
	: primary_expression									{ $$ = $1; }
	| postfix_expression '[' expression ']'					{ $$ = op( nd(SUBSCRIPT, $2), 0, 2, ek($1), ek($3) ); }
	| postfix_expression '(' ')'							{ $$ = op( mkGenNode(FUNC_CALL, "() [func-call]", "shape=box"), 0, 1, ek($1) ); }
	| postfix_expression '(' argument_expression_list ')'	{ $$ = op( mkGenNode(FUNC_CALL, "() [func-call]", "shape=box"), 0, 2, ek($1), ek($3) ); }
	| postfix_expression '.' IDENTIFIER						{ $$ = op( nd('.', $2), 0, 2, ek($1), ek((void*) $3) ); }
	| postfix_expression PTR_OP IDENTIFIER					{ $$ = op( nd(PTR_OP, $2), 0, 2, ek($1), ek((void*) $3) ); }
	| postfix_expression INC_OP								{ $$ = op( nd(INC_OP, $2), 0, 1, ek($1) ); }
	| postfix_expression DEC_OP								{ $$ = op( nd(DEC_OP, $2), 0, 1, ek($1) ); }
	;

argument_expression_list
	: assignment_expression									{ $$ = op( nd(ARG_EXPR_LIST, "arg-expr-list"), 0, 1, ek($1) ); }
	| argument_expression_list ',' assignment_expression	{ $$ = op( (node_t*)$1, 0, 1, ek($3) ); }
	;

unary_expression
	: postfix_expression				{ $$ = $1; }
	| INC_OP unary_expression			{ $$ = op( nd(INC_OP, $1), 0, 1, ek($2) ); }
	| DEC_OP unary_expression			{ $$ = op( nd(DEC_OP, $1), 0, 1, ek($2) ); }
	| unary_operator cast_expression	{ $$ = op( (node_t*)$1, 0, 1, ek($2) ); }
	| SIZEOF unary_expression			{ $$ = op( nd(SIZEOF, $1), 0, 1, ek($2) ); }
	| SIZEOF '(' type_name ')'			{ $$ = op( nd(SIZEOF, $1), 0, 1, ek($3) ); }
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
		{ $$ = op( nd(CAST_EXPR, "cast_expression"), 0, 2, mkGenEdge((node_t*)$2, "type", NULL), mkGenEdge((node_t*)$4, "expression", NULL) ); }
	;

multiplicative_expression
	: cast_expression { $$ = $1; }
	| multiplicative_expression '*' cast_expression { $$ = op( nd('*', $2), 0, 2, ek($1), ek($3) ); }
	| multiplicative_expression '/' cast_expression { $$ = op( nd('/', $2), 0, 2, ek($1), ek($3) ); }
	| multiplicative_expression '%' cast_expression { $$ = op( nd('%', $2), 0, 2, ek($1), ek($3) ); }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { $$ = op( nd('+', $2), 0, 2, ek($1), ek($3) ); }
	| additive_expression '-' multiplicative_expression { $$ = op( nd('-', $2), 0, 2, ek($1), ek($3) ); }
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression	{ $$ = op( nd(LEFT_OP, $2), 0, 2, ek($1), ek($3) ); }
	| shift_expression RIGHT_OP additive_expression	{ $$ = op( nd(RIGHT_OP, $2), 0, 2, ek($1), ek($3) ); }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression	{ $$ = op( nd('<', $2), 0, 2, ek($1), ek($3) ); }
	| relational_expression '>' shift_expression	{ $$ = op( nd('>', $2), 0, 2, ek($1), ek($3) ); }
	| relational_expression LE_OP shift_expression	{ $$ = op( nd(LE_OP, $2), 0, 2, ek($1), ek($3) ); }
	| relational_expression GE_OP shift_expression	{ $$ = op( nd(GE_OP, $2), 0, 2, ek($1), ek($3) ); }
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression	{ $$ = op( nd(EQ_OP, $2), 0, 2, ek($1), ek($3) ); }
	| equality_expression NE_OP relational_expression	{ $$ = op( nd(NE_OP, $2), 0, 2, ek($1), ek($3) ); }
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression { $$ = op( nd('&', $2), 0, 2, ek($1), ek($3) ); }
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression { $$ = op( nd('^', $2), 0, 2, ek($1), ek($3) ); }
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = op( nd('|', $2), 0, 2, ek($1), ek($3) ); }
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { $$ = op( nd(AND_OP, $2), 0, 2, ek($1), ek($3) ); }
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { $$ = op( nd(OR_OP, $2), 0, 2, ek($1), ek($3) ); }
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { $$ = op(
		mkGenNode(-1, "ternary expr (? :)", NULL), 0, 3,
		mkGenEdge((node_t*)$1, "condition", NULL),
		mkGenEdge((node_t*)$3, "expr (if TRUE)", NULL),
		mkGenEdge((node_t*)$5, "expr (if FALSE)", NULL)
	); }
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { $$ = op( (node_t*)$2, 0, 2, ek($1), ek($3) ); }
	;

assignment_operator
	: '='			{ $$ = (node_t *) $1; }
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
	| expression ',' assignment_expression { $$ = op( nd(',', $2), 0, 2, ek($1), ek($3) ); }
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
// useless iff NULL
declaration
	: declaration_specifiers ';' { $$ = NULL; } // { $$ = $1; }
	| declaration_specifiers init_declarator_list ';' { /* $$ = ($2) ? ($2) : NULL; */

		node_t *ds = (node_t*) $1, *idl = (node_t*) $2;
		edge_t **ch_ds = ds->edges, **ch_idl = idl->edges;
		int len_ds = ds->numChild, len_idl = idl->numChild;

		// construct type encoding from list of declaration_specifiers
		ull_t enc = 0; for (int i = 0; i < len_ds; i++) { enc |= (ch_ds[i]->node->enc); msg(SUCC) << ch_ds[i]->node->label; } // simplicity for now.

		int useful = 0;

		// single pass over variables
		for (int i = 0; i < len_idl; i++) { // first check that there is no var in scope
			node_t *c_node = (ch_idl[i]->node); // "concerned node" - get directly
			if (c_node->tok_type == '=') {
				c_node = (c_node->edges[0]->node); // get from "declarator" part - risky - doesnot take into acount pointer like stuff
				useful++;
			}
			msg(SUCC) << c_node->label;

			if (sr->lookup(c_node->label)) {
				msg(ERR) << c_node->line << ":" << c_node->column << ":: Multiple declaration of \"" << c_node->label << "\". Previous declaration at location " << "sym mein daal dena.";
				exit(E_MULT_DECL);
			} else msg(SUCC) << "Will insert \"" << c_node->label << "\".";
			
			sr->pushSym(c_node->label, enc); // ASUMPTION: success - can check that too
		}

		if (useful > 0) {
			edge_t **tmp = (edge_t **) malloc(useful * sizeof(edge_t *)); int curr = 0;
			for (int i = 0; i < len_idl; i++) if (ch_idl[i]->node->tok_type == '=') tmp[curr++] = ch_idl[i];
			free(ch_idl); idl->edges = tmp; idl->numChild = useful;
			$$ = $2;
		} else $$ = NULL;

	}
	;
// int
// TESTED OK - useless iff NULL
// A list of three kinds of objects. Also, new child appends to the left.
declaration_specifiers
	: storage_class_specifier                        { $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ek($1) ); ((node_t*)$$)->enc = ((node_t*)$1)->enc; } // valid by default
	| storage_class_specifier declaration_specifiers { $$ = op( (node_t*)$2, 1, 0, ek($1) ); }
	| type_specifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ek($1) ); ((node_t*)$$)->enc = ((node_t*)$1)->enc; } // valid by default
	| type_specifier declaration_specifiers          { $$ = op( (node_t*)$2, 1, 0, ek($1) ); }
	| type_qualifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs"), 0, 1, ek($1) ); ((node_t*)$$)->enc = ((node_t*)$1)->enc; } // valid by default
	| type_qualifier declaration_specifiers          { $$ = op( (node_t*)$2, 1, 0, ek($1) ); }
	;

// TESTED OK - useless iff NULL
init_declarator_list
	: init_declarator { $$ = op( nd(INIT_DECL_LIST, "var-list"), 0, 1, ek($1) ); }
	| init_declarator_list ',' init_declarator { $$ = op( (node_t*)$1, 0, 1, ek($3) ); }
	;

// TESTED OK - useless iff NULL
init_declarator
	: declarator                 { $$ = $1; } // handle uselessness at "declaration"
	| declarator '=' initializer { $$ = op( (node_t *) $2, 0, 2, ek($1), ek($3) ); }
	;

// TESTED OK
storage_class_specifier
	: TYPEDEF	{ $$ = (node_t *) $1; }
	| EXTERN	{ $$ = (node_t *) $1; }
	| STATIC	{ $$ = (node_t *) $1; }
	| AUTO		{ $$ = (node_t *) $1; }
	| REGISTER	{ $$ = (node_t *) $1; }
	;

type_specifier
	: VOID							{ $$ = (node_t *) $1; }
	| CHAR							{ $$ = (node_t *) $1; }
	| SHORT							{ $$ = (node_t *) $1; }
	| INT							{ $$ = (node_t *) $1; }
	| LONG							{ $$ = (node_t *) $1; }
	| FLOAT							{ $$ = (node_t *) $1; }
	| DOUBLE						{ $$ = (node_t *) $1; }
	| SIGNED						{ $$ = (node_t *) $1; }
	| UNSIGNED						{ $$ = (node_t *) $1; }
	| FILE_OBJ						{ $$ = (node_t *) $1; }
	| struct_or_union_specifier		{ $$ = $1; }
	| enum_specifier				{ $$ = $1; } // TESTED OK
	| TYPE_NAME						{ $$ = (node_t *) $1; } // never encountered in ANSI C (just a user defined type)
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}' { $$ = op( (node_t*)$1, 0, 2, ek((void*)$2), ek($4) ); }
	| struct_or_union '{' struct_declaration_list '}'            { $$ = op( (node_t*)$1, 0, 1, ek($3) ); }
	| struct_or_union IDENTIFIER                                 { $$ = op( (node_t*)$1, 0, 1, ek((void*)$2) ); }
	;

// TESTED OK
struct_or_union
	: STRUCT	{ $$ = nd(STRUCT, $1); }
	| UNION		{ $$ = nd(UNION, $1); }
	;

struct_declaration_list 
	: struct_declaration {$$ = op(nd(ALL_MEMBERS,"member-list"),0,1,ek($1));}
	| struct_declaration_list struct_declaration 
	{$$=op((node_t*)$1, 0, 1, ek($2));}
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' 
	{$$ = op(nd(STRUCT_MEMBER,"member"),0,2,ek($1),ek($2));}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list  {$$ = op((node_t*)$2, 1, 0, ek($1));}
	| type_specifier                           
	{$$ = op(nd(SPEC_QUAL_LIST,"spec-qual"),0,1,ek($1));}
	| type_qualifier specifier_qualifier_list  {$$ = op((node_t*)$2, 1, 0, ek($1));}
	| type_qualifier			   
	{$$ = op(nd(SPEC_QUAL_LIST,"spec-qual"),0,1,ek($1));}
	;

struct_declarator_list
	: struct_declarator  {$$ = op(nd(INIT_DECL_LIST,"var-list"),0,1,ek($1));}
	| struct_declarator_list ',' struct_declarator {$$ = op((node_t*)$1, 0, 1, ek($3));}
	;

struct_declarator
	: declarator {$$=$1;}
	| ':' constant_expression  {$$ = $2;}
	| declarator ':' constant_expression 
	{$$ = op(nd(STRUCT_DECL,"declarator"),0,2,ek($1),ek($3));} 
	;

// TESTED OK
enum_specifier
	: ENUM '{' enumerator_list '}'				{ $$ = op( nd(ENUM, $1), 0, 1, ek($3) ); }
	| ENUM IDENTIFIER '{' enumerator_list '}'	{ $$ = op( nd(ENUM, $1), 0, 2, ek((void*)$2), ek($4) ); }
	| ENUM IDENTIFIER							{ $$ = op( nd(ENUM, $1), 0, 1, ek((void*)$2) ); }
	;

// TESTED OK
enumerator_list
	: enumerator						{ $$ = op( nd(ENUM_LIST, "enum-list"), 0, 1, ek($1) ); }
	| enumerator_list ',' enumerator	{ $$ = op( (node_t*)$1, 0, 1, ek($3) ); }
	;

// TESTED OK
enumerator
	: IDENTIFIER							{ $$ = (node_t *) $1; }
	| IDENTIFIER '=' constant_expression	{ $$ = op( (node_t *) $2, 0, 2, ek((void*)$1), ek($3) ); }
	;

// TESTE OK
type_qualifier
	: CONST		{ $$ = (node_t *) $1; }
	| VOLATILE	{ $$ = (node_t *) $1; }
	;

// TESTED OK
declarator
	: pointer direct_declarator	{ $$ = op( nd(DECLARATOR, "var"), 0, 2, ek($1), ek($2) ); }
	| direct_declarator			{ $$ = $1; }
	;

// TESTED OK
direct_declarator
	: IDENTIFIER									{ $$ = (node_t *) $1; }
	| '(' declarator ')'							{ $$ = $2; }
	| direct_declarator '[' constant_expression ']'	{ $$ = op( nd(SUBSCRIPT, $2), 0, 2, ek($1), ek($3) ); }
	| direct_declarator '[' ']'						{ $$ = op( nd(SUBSCRIPT, $2), 0, 1, ek($1) ); }
	| direct_declarator '(' parameter_type_list ')'	{ $$ = $1;/* $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 2, ek($1), ek($3) ); */ }
	| direct_declarator '(' identifier_list ')'		{ $$ = $1;/* $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 2, ek($1), ek($3) ); */ }
	| direct_declarator '(' ')'						{ $$ = op( nd(FUNC_PTR, "() [func-ptr]"), 0, 1, ek($1) ); }
	;

// TESTED OK
pointer
	: '*'								{ $$ = nd(DEREF, $1); }
	| '*' type_qualifier_list			{ $$ = nd(DEREF, $1); /* $$ = op( nd(DEREF, $1), 0, 1, ek($2) ); */ }
	| '*' pointer						{ $$ = op( nd(DEREF, $1), 0, 1, ek($2) ); }
	| '*' type_qualifier_list pointer	{ $$ = op( nd(DEREF, $1), 0, 1, ek($3) ); /* $$ = op( nd(DEREF, $1), 0, 2, ek($2), ek($3) ); */ }
	;

// TESTED OK
type_qualifier_list
	: type_qualifier						{ $$ = op( nd(TYPE_QUAL_LIST, "type-quals"), 0, 1, ek($1) ); }
	| type_qualifier_list type_qualifier	{ $$ = op( (node_t*)$1, 0, 1, ek($2) ); }
	;

// TESTED OK
parameter_type_list
	: parameter_list				{ $$ = $1; }
	| parameter_list ',' ELLIPSIS	{ $$ = op( (node_t*)$1, 0, 1, ek(nd(ELLIPSIS, $3)) ); }
	;

// TESTED OK
parameter_list
	: parameter_declaration						{ $$ = op( nd(PARAM_TYPE_LIST, "param-types"), 0, 1, ek($1) ); }
	| parameter_list ',' parameter_declaration	{ $$ = op( (node_t*)$1, 0, 1, ek($3) ); }
	;

parameter_declaration
	: declaration_specifiers declarator            { $$ = op( nd(PARAM_DECL, "param-decl"), 0, 2, ek($1), ek($2) ); }
	| declaration_specifiers abstract_declarator   { $$ = op( nd(PARAM_DECL, "param-decl"), 0, 2, ek($1), ek($2) ); }
	| declaration_specifiers                       { $$ = $1; }
	;

identifier_list
	: IDENTIFIER                       { $$ = op( nd(ID_LIST, "identifiers"), 0, 1, ek((void*)$1) ); }
	| identifier_list ',' IDENTIFIER   { $$ = op( (node_t*)$1, 0, 1, ek((void*)$3) );}
	;

type_name
	: specifier_qualifier_list                        { $$ = op( nd(TYPE_NAME, "type-name"), 0, 1, ek($1) ); }
	| specifier_qualifier_list abstract_declarator    { $$ = op( (node_t*)$1, 0, 1, ek($2) ); }
	;

abstract_declarator
	: pointer                              { $$ = $1; }
	| direct_abstract_declarator           { $$ = $1; }
	| pointer direct_abstract_declarator   { $$ = op( nd(ABSTRACT_DECLARATOR, "abst-decl"), 0, 2, ek($1), ek($2) ); }
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'                                { $$ = $2; }
	| '[' ']'                                                    { $$ = nd(SUBSCRIPT, "[]"); }
	| '[' constant_expression ']'                                { $$ = op(nd(SUBSCRIPT, $1), 0, 1, ek($2)); }
	| direct_abstract_declarator '[' ']'                         { $$ = op( nd(SUBSCRIPT, $2), 0, 1, ek($1) ); }
	| direct_abstract_declarator '[' constant_expression ']'     { $$ = op( nd(SUBSCRIPT, $2), 0, 2, ek($1), ek($3) ); }
	| '(' ')'                                                    { $$ = nd(ABSTRACT_DECLN, "() abst-declaration"); }
	| '(' parameter_type_list ')'                                { $$ = op(nd(ABSTRACT_DECLN, "() abst-declaration"), 0 ,1, ek($2)); } // ! Will handle
	| direct_abstract_declarator '(' ')'                         { $$ = op(nd(ABSTRACT_DECLN, "() abst-declaration"), 0 ,1, ek($1)); }
	| direct_abstract_declarator '(' parameter_type_list ')'     { $$ = op( nd(ABSTRACT_DECLN, "() abst-declaration"), 0, 2, ek($1), ek($3) ); }
	;

// TESTED OK
initializer
	: assignment_expression			{ $$ = $1; }
	| '{' initializer_list '}'		{ $$ = $2; }
	| '{' initializer_list ',' '}'	{ $$ = $2; }
	;

// TESTED OK
initializer_list
	: initializer						{ $$ = op( nd(INIT_LIST, "array"), 0, 1, ek($1) ); }
	| initializer_list ',' initializer	{
		/* THIS CODE WORKS, BUT USE ONLY WHEN SIMULTANEOUS PRINTING IS NOT GOING ON */
		// if (((node_t*)$3)->tok_type == INIT_LIST) { // array within an array
		// 	node_t* parent = (node_t*)$3, *tmp = (node_t*)$1;
		// 	int n = parent->numChild;
		// 	for (int i = 0; i < n; i++) {
		// 		tmp = op( tmp, 0, 1, ek(parent->edges[i]->node) );
		// 		// hide edge - ineffective (this code adds NEW invisible edges, but doesn't hide old ones)
		// 		fprintf(temp_out, "\t%lld -> %lld [style = \"invis\"];\n", parent->id, parent->edges[i]->node->id);
		// 	}
		// 	fprintf(temp_out, "\t%lld [style = \"invis\"];\n", parent->id); // hide parent
		// 	free(parent->edges); parent->edges = NULL;
		// 	$$ = tmp;
		// } else $$ = op( (node_t*)$1, 0, 1, ek($3) );
		$$ = op( (node_t*)$1, 0, 1, ek($3) );
	}
	;

statement
	: labeled_statement    { $$ = $1; }
	| compound_statement   { $$ = $1; }
	| expression_statement { $$ = $1; }
	| selection_statement  { $$ = $1; }
	| iteration_statement  { $$ = $1; }
	| jump_statement       { $$ = $1; }
	;

// TESTED OK
labeled_statement
	: IDENTIFIER ':' statement                { ((node_t*) $1)->attr = "style=filled,fillcolor=magenta"; $$ = op( (node_t*) $1, 0, 1, ek($3) ); }
	| CASE constant_expression ':' statement  { $$ = op( (node_t*) $1, 0, 2, ek($2), ek($4) ); }
	| DEFAULT ':' statement                   { $$ = op( (node_t*) $1 , 0, 1, ek($3) ); }
	;

// TESTED OK - useless iff EMPTY_BLOCK (can't substitute NULL, since EMPTY_BLOCK is still a valid function definition)
compound_statement
	: '{' '}'                                 { $$ = nd(EMPTY_BLOCK, $1); }
	| '{' statement_list '}'                  { $$ = ($2) ? ($2) : nd(EMPTY_BLOCK, $1); }
	| '{' declaration_list '}'                { $$ = ($2) ? ($2) : nd(EMPTY_BLOCK, $1); }
	| '{' declaration_list statement_list '}' {
		if (($2) && ($3)) { $$ = op( nd(GEN_BLOCK, "block"), 0, 2, ek($2), ek($3) ); }
		else if ($2) { $$ = $2; } // only useful decl. list.
		else if ($3) { $$ = $3; } // only useful stmt. list.
		else { $$ = nd(EMPTY_BLOCK, $1); } // empty block
	}
	;

// TESTED OK - useless iff NULL
declaration_list
	: declaration { $$ = ($1) ? op( nd(DECL_LIST, "declarations"), 0, 1, ek($1) ) : NULL; }
	| declaration_list declaration	{
		if ($1 && $2) { $$ = op( (node_t*)$1, 0, 1, ek($2) ); } // both useful - simply append
		else if ($1) { $$ = $1; } // new child not useful
		else if ($2) { $$ = op( nd(DECL_LIST, "declarations"), 0, 1, ek($2) ); } // first useful child
		else { $$ = NULL; }
	}
	;

// TESTED OK
statement_list
	: statement                { $$ = op( nd(STMT_LIST, "stmt-list"), 0, 1, ek($1) ); }
	| statement_list statement { $$ = op( (node_t*)$1, 0, 1, ek($2) ); }
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
		mkGenEdge((node_t*)$3, "cond", NULL), mkGenEdge((node_t*)$5, "stmts", NULL)
	); }
	| IF '(' expression ')' statement ELSE statement { $$ = op(
		mkGenNode(IF_ELSE_STMT, "if-else-stmt", "style=filled,fillcolor=yellow"), 0, 3,
		mkGenEdge((node_t*)$3, "cond", NULL), mkGenEdge((node_t*)$5, "stmts (if TRUE)", NULL), mkGenEdge((node_t*)$7, "stmts (if FALSE)", NULL)
	); }
	| SWITCH '(' expression ')' statement { $$ = op(
		mkGenNode(SWITCH, $1, "style=filled,fillcolor=yellow"), 0, 2,
		mkGenEdge((node_t*)$3, "expr", NULL), mkGenEdge((node_t*)$5, "stmts", NULL)
	); }
	;

iteration_statement
	: WHILE '(' expression ')' statement { $$ = op(
		mkGenNode(WHILE, $1, "style=filled,fillcolor=lightblue"), 0, 2,
		mkGenEdge((node_t*)$3, "expr", NULL), mkGenEdge((node_t*)$5, "stmts", NULL)
	); }
	| DO statement WHILE '(' expression ')' ';' { $$ = op(
		mkGenNode(DO_WHILE, "do-while", "style=filled,fillcolor=lightblue"), 0, 2,
		mkGenEdge((node_t*)$2, "stmts", NULL), mkGenEdge((node_t*)$5, "expr", NULL)
	); }
	| FOR '(' expression_statement expression_statement ')' statement { $$ = op(
		mkGenNode(FOR, $1, "style=filled,fillcolor=lightblue"), 0, 3,
		mkGenEdge((node_t*)$3, "expr", NULL), mkGenEdge((node_t*)$4, "expr", NULL), mkGenEdge((node_t*)$6, "stmts", NULL)
	); }
	| FOR '(' expression_statement expression_statement expression ')' statement  { $$ = op(
		mkGenNode(FOR, $1, "style=filled,fillcolor=lightblue"), 0, 4,
		mkGenEdge((node_t*)$3, "expr", NULL), mkGenEdge((node_t*)$4, "expr", NULL), mkGenEdge((node_t*)$5, "expr", NULL), mkGenEdge((node_t*)$7, "stmts", NULL)
	); }
	;

jump_statement
	: GOTO IDENTIFIER ';'	{ $$ = op( mkGenNode(GOTO, $1, "style=filled,fillcolor=orange"), 0, 1, ek((void*)$2) ); }
	| CONTINUE ';'			{ $$ = mkGenNode(CONTINUE, $1, "style=filled,fillcolor=orange"); }
	| BREAK ';'				{ $$ = mkGenNode(BREAK, $1, "style=filled,fillcolor=orange"); }
	| RETURN ';'			{ $$ = (void*) $1; }
	| RETURN expression ';'	{ $$ = op( (node_t*) $1, 0, 1, ek($2) ); }
	;

translation_unit
	: external_declaration	{ AstRoot = (node_t*)($$ = ($1) ? op( mkGenNode(-1, fileName, "shape=box"), 0, 1, ek($1) ) : NULL); }
	| translation_unit external_declaration	{
		if ($1 && $2) { $$ = op( (node_t*)$1, 0, 1, ek($2) ); }
		else if ($1) { $$ = $1; } // new child useless
		else if ($2) { $$ = op( mkGenNode(-1, fileName, "shape=box"), 0, 1, ek($2) ); }
		else { $$ = NULL; }
		AstRoot = (node_t*)$$;
	}
	;

external_declaration
	: function_definition		{ $$ = $1; }
	| declaration { $$ = ($1) ? ($1) : NULL; }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
		$$ = ($3)
		? op( nd(FUNC_DEF, "function_definition"), 0, 3, ek($2), ek($3), ek($4) )
		: op( nd(FUNC_DEF, "function_definition"), 0, 2, ek($2), ek($4) );
	}
	| declaration_specifiers declarator compound_statement { $$ = op(nd(FUNC_DEF,"function_definition"), 0, 2, ek($2), ek($3)); }
	| declarator declaration_list compound_statement {
		$$ = ($2)
		? op( nd(FUNC_DEF, "function_definition"), 0, 3, ek($1), ek($2), ek($3) )
		: op( nd(FUNC_DEF, "function_definition"), 0, 2, ek($1), ek($3) );
	}
	| declarator compound_statement { $$ = op( nd(FUNC_DEF, "function_definition"), 0, 2, ek($1), ek($2) ); }
	;

%%

// See tree.c for this part
