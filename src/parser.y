%{
// TERMINALS ARE SPECIAL CHARACTERS OR START WITH CAPTIAL ALPHABETS.
// NON-TERMINALS START WITH SMALL ALPHABETS.

// See include files for usage/syntax of "makeLeaf", "makeOpNode".

#include <stdio.h>
#include <gfcc_lexer.h>

%}

%union {
	void *node;		// pointer (if non-terminal)
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


// Provide types to fixed literals (to avoid warnings)
%type <node> '(' ')' '[' ']' '{' '}'
%type <node> '+' '-' '=' '*'
%type <node> '&' '~' '!'
%type <node> ',' ';' ':'


// Start symbol
%start translation_unit

%%

primary_expression
	: IDENTIFIER { $$ = makeLeaf(IDENTIFIER, $1, NULL); }
	| CONSTANT { $$ = makeLeaf(CONSTANT, $1, NULL); }
	| STRING_LITERAL { $$ = makeLeaf(STRING_LITERAL, $1, NULL); }
	| '(' expression ')' { $$ = $2; }
	;

postfix_expression
	: primary_expression { $$ = $1; }
	| postfix_expression '[' expression ']' { $$ = makeOpNode("[]", NULL, $1, NULL, $3, NULL, 0); }
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '.' IDENTIFIER { $$ = makeOpNode(".", NULL, $1, NULL, makeLeaf(IDENTIFIER, $3, NULL), NULL, 0); }
	| postfix_expression PTR_OP IDENTIFIER { $$ = makeOpNode("->", NULL, $1, NULL, makeLeaf(IDENTIFIER, $3, NULL), NULL, 0); }
	| postfix_expression INC_OP	{ $$ = makeOpNode("++", NULL, $1, NULL, 0); }
	| postfix_expression DEC_OP { $$ = makeOpNode("++", NULL, $1, NULL, 0); }
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression
	| INC_OP unary_expression { $$ = makeOpNode($1, NULL, $2, NULL, 0); }
	| DEC_OP unary_expression { $$ = makeOpNode($1, NULL, $2, NULL, 0); }
	| unary_operator cast_expression { $$ = makeOpNode(NULL, (char*)$1, $2, NULL, 0); }
	| SIZEOF unary_expression { $$ = makeOpNode($1, NULL, $2, NULL, 0); }
	| SIZEOF '(' type_name ')' { $$ = makeOpNode($1, NULL, $3, NULL, 0); }
	;

unary_operator
	: '&' { $$ = makeLeaf('&', $1, NULL); }
	| '*' { $$ = makeLeaf('*', $1, NULL); }
	| '+' { $$ = makeLeaf('+', $1, NULL); }
	| '-' { $$ = makeLeaf('-', $1, NULL); }
	| '~' { $$ = makeLeaf('~', $1, NULL); }
	| '!' { $$ = makeLeaf('!', $1, NULL); }
	;

cast_expression
	: unary_expression
	| '(' type_name ')' cast_expression { $$ = makeOpNode("cast_expression", NULL, $2, "label=type", $4, "label=expression", 0); }
	;

multiplicative_expression
	: cast_expression
	| multiplicative_expression '*' cast_expression { $$ = makeOpNode("*", NULL, $1, NULL, $3, NULL, 0); }
	| multiplicative_expression '/' cast_expression { $$ = makeOpNode("/", NULL, $1, NULL, $3, NULL, 0); }
	| multiplicative_expression '%' cast_expression { $$ = makeOpNode("%", NULL, $1, NULL, $3, NULL, 0); }
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression { $$ = makeOpNode("+", NULL, $1, NULL, $3, NULL, 0); }
	| additive_expression '-' multiplicative_expression { $$ = makeOpNode("-", NULL, $1, NULL, $3, NULL, 0); }
	;

shift_expression
	: additive_expression
	| shift_expression LEFT_OP additive_expression
	| shift_expression RIGHT_OP additive_expression
	;

relational_expression
	: shift_expression
	| relational_expression '<' shift_expression
	| relational_expression '>' shift_expression
	| relational_expression LE_OP shift_expression
	| relational_expression GE_OP shift_expression
	;

equality_expression
	: relational_expression
	| equality_expression EQ_OP relational_expression
	| equality_expression NE_OP relational_expression
	;

and_expression
	: equality_expression
	| and_expression '&' equality_expression
	;

exclusive_or_expression
	: and_expression
	| exclusive_or_expression '^' and_expression
	;

inclusive_or_expression
	: exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;

logical_and_expression
	: inclusive_or_expression
	| logical_and_expression AND_OP inclusive_or_expression
	;

logical_or_expression
	: logical_and_expression
	| logical_or_expression OR_OP logical_and_expression
	;

conditional_expression
	: logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
	;

assignment_expression
	: conditional_expression
	| unary_expression assignment_operator assignment_expression
	;

assignment_operator
	: '='
	| MUL_ASSIGN
	| DIV_ASSIGN
	| MOD_ASSIGN
	| ADD_ASSIGN
	| SUB_ASSIGN
	| LEFT_ASSIGN
	| RIGHT_ASSIGN
	| AND_ASSIGN
	| XOR_ASSIGN
	| OR_ASSIGN
	;

expression
	: assignment_expression
	| expression ',' assignment_expression
	;

constant_expression
	: conditional_expression
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';'
	;

declaration_specifiers
	: storage_class_specifier
	| storage_class_specifier declaration_specifiers
	| type_specifier
	| type_specifier declaration_specifiers
	| type_qualifier
	| type_qualifier declaration_specifiers
	;

init_declarator_list
	: init_declarator
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: declarator
	| declarator '=' initializer
	;

storage_class_specifier
	: TYPEDEF
	| EXTERN
	| STATIC
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID			{ $$ = makeLeaf(VOID, $1, NULL); }
	| CHAR			{ $$ = makeLeaf(CHAR, $1, NULL); }
	| SHORT			{ $$ = makeLeaf(SHORT, $1, NULL); }
	| INT			{ $$ = makeLeaf(INT, $1, NULL); }
	| LONG			{ $$ = makeLeaf(LONG, $1, NULL); }
	| FLOAT			{ $$ = makeLeaf(FLOAT, $1, NULL); }
	| DOUBLE		{ $$ = makeLeaf(DOUBLE, $1, NULL); }
	| SIGNED		{ $$ = makeLeaf(SIGNED, $1, NULL); }
	| UNSIGNED		{ $$ = makeLeaf(UNSIGNED, $1, NULL); }
	| struct_or_union_specifier
	| enum_specifier
	| TYPE_NAME
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union IDENTIFIER
	;

struct_or_union
	: STRUCT { $$ = makeLeaf(STRUCT, $1, NULL); }
	| UNION { $$ = makeLeaf(UNION, $1, NULL); }
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: declarator
	| ':' constant_expression
	| declarator ':' constant_expression
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' constant_expression
	;

type_qualifier
	: CONST
	| VOLATILE
	;

declarator
	: pointer direct_declarator
	| direct_declarator
	;

direct_declarator
	: IDENTIFIER
	| '(' declarator ')'
	| direct_declarator '[' constant_expression ']'
	| direct_declarator '[' ']'
	| direct_declarator '(' parameter_type_list ')'
	| direct_declarator '(' identifier_list ')'
	| direct_declarator '(' ')'
	;

pointer
	: '*'
	| '*' type_qualifier_list
	| '*' pointer
	| '*' type_qualifier_list pointer
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list
	| parameter_list ',' ELLIPSIS
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list
	| specifier_qualifier_list abstract_declarator
	;

abstract_declarator
	: pointer
	| direct_abstract_declarator
	| pointer direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' constant_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' constant_expression ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: assignment_expression
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list
	: initializer
	| initializer_list ',' initializer
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{' statement_list '}'
	| '{' declaration_list '}'
	| '{' declaration_list statement_list '}'
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

statement_list
	: statement
	| statement_list statement
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement
	| IF '(' expression ')' statement ELSE statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	;

jump_statement
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement
	| declarator declaration_list compound_statement
	| declarator compound_statement
	;

%%

// See tree.c for this part
