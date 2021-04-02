%{
// AUM SHREEGANESHAAYA NAMAH||
/************************ NOTE TO THE DEVELOPER(S) ************************
 * TERMINALS ARE SPECIAL CHARACTERS OR START WITH CAPTIAL ALPHABETS.
 * NON-TERMINALS START WITH SMALL ALPHABETS.
 * See include files for usage/syntax of "nd", "ej" and "op".
**************************************************************************/

#include <cstdlib>
#include <sstream>

#include <gfcc_lexer.h>
#include <symtab.h>
#include <typo.h>

using namespace std;

%}

%union { // Add more if required (but carefully, as type conversions may be required).
	struct _node_t *node;
}

/* Terminals: Don't change this order. */
%token <node> IDENTIFIER CONSTANT STRING_LITERAL
%token <node> SIZEOF FILE_OBJ
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
%type <node> '(' ')' '[' ']' '{' '}' '+' '-' '=' '*' '/' '%' '&' '~' '!' '>' '<' '|' '^' ',' ';' ':' '.' '?'

// Start symbol
%start translation_unit

%%

/***********************************************************************************************/
/************************************** EXPRESSIONS BEGIN **************************************/
/***********************************************************************************************/

primary_expression
	: IDENTIFIER			{ $$ = $1;
		sym* ret = SymRoot->gLookup($1->label);
		if (ret) { $$->type = new Type(); *($$->type) = *($1->type); } // success - start by making a copy of type.
		else {
			repErr($1->pos, "variable undeclared in this scope (will set variable to \"error\" type)", _FORE_RED_);
			Type* tp = $$->type = new Type(); tp->base = ERROR_B;
		}
	}
	| CONSTANT				{ $$ = $1; } // get sematic number (means 0x56 = 86, 0227 = 151, etc) during semantic analysis - but ENCODE HERE ITSELF
	| STRING_LITERAL		{ $$ = $1; } // encode as (const char *) - or some other appropriate enc.
	| '(' expression ')'	{ $$ = $2; }
	;

postfix_expression
	: primary_expression									{ $$ = $1; }
	| postfix_expression '[' expression ']'					{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| postfix_expression '(' ')' {
		$2->tok = FUNC_CALL; $2->label = "() [func-call]"; $2->attr = func_call_attr;
		$$ = op( $2, 0, 1, ej($1) );
	}
	| postfix_expression '(' argument_expression_list ')' {
		$2->tok = FUNC_CALL; $2->label = "() [func-call]"; $2->attr = func_call_attr;
		$$ = op( $2, 0, 2, ej($1), ej($3) );
	}
	| postfix_expression '.' IDENTIFIER						{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| postfix_expression PTR_OP IDENTIFIER					{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| postfix_expression INC_OP								{ $$ = op( $2, 0, 1, ej($1) ); }
	| postfix_expression DEC_OP								{ $$ = op( $2, 0, 1, ej($1) ); }
	;

argument_expression_list
	: assignment_expression									{ $$ = op( nd(ARG_EXPR_LIST, "arg-expr-list", { 0, 0 }), 0, 1, ej($1) ); }
	| argument_expression_list ',' assignment_expression	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

unary_expression
	: postfix_expression				{ $$ = $1; }
	| INC_OP unary_expression			{ $$ = op( $1, 0, 1, ej($2) ); }
	| DEC_OP unary_expression			{ $$ = op( $1, 0, 1, ej($2) ); }
	| unary_operator cast_expression	{ $$ = op( $1, 0, 1, ej($2) ); }
	| SIZEOF unary_expression			{ $$ = op( $1, 0, 1, ej($2) ); }
	| SIZEOF '(' type_name ')'			{ $$ = op( $1, 0, 1, ej($3) ); }
	;

unary_operator
	: '&' { $$ = $1; }
	| '*' { $$ = $1; }
	| '+' { $$ = $1; }
	| '-' { $$ = $1; }
	| '~' { $$ = $1; }
	| '!' { $$ = $1; }
	;

cast_expression
	: unary_expression { $$ = $1; }
	| '(' type_name ')' cast_expression { $$ = op(
		nd(CAST_EXPR, "cast_expression", { 0, 0 }), 0, 2, Ej($2, "type", NULL), Ej($4, "expression", NULL)
	); }
	;

multiplicative_expression
	: cast_expression { $$ = $1; }
	| multiplicative_expression '*' cast_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| multiplicative_expression '/' cast_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| multiplicative_expression '%' cast_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| additive_expression '-' multiplicative_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| shift_expression RIGHT_OP additive_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| relational_expression '>' shift_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| relational_expression LE_OP shift_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| relational_expression GE_OP shift_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| equality_expression NE_OP relational_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { $$ = op( $2, 0, 3,
		Ej($1, "condition", NULL), Ej($3, "expr (if TRUE)", NULL), Ej($5, "expr (if FALSE)", NULL)
	); }
	;

assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

assignment_operator
	: '='			{ $$ = $1; }
	| MUL_ASSIGN	{ $$ = $1; }
	| DIV_ASSIGN	{ $$ = $1; }
	| MOD_ASSIGN	{ $$ = $1; }
	| ADD_ASSIGN	{ $$ = $1; }
	| SUB_ASSIGN	{ $$ = $1; }
	| LEFT_ASSIGN	{ $$ = $1; }
	| RIGHT_ASSIGN	{ $$ = $1; }
	| AND_ASSIGN	{ $$ = $1; }
	| XOR_ASSIGN	{ $$ = $1; }
	| OR_ASSIGN		{ $$ = $1; }
	;

// Here, comma is an operator, and is not treated like a list delimiter
expression
	: assignment_expression { $$ = $1; }
	| expression ',' assignment_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

/************************************************************************************************/
/************************************* EXPRESSIONS COMPLETE *************************************/
/************************************** DECLARATIONS BEGIN **************************************/
/************************************************************************************************/

// useless iff NULL
declaration
	: declaration_specifiers ';' { $$ = NULL; }
	| declaration_specifiers init_declarator_list ';' {
		edge_t **ch1 = $1->edges, **ch2 = $2->edges;
		int l1 = $1->numChild, l2 = $2->numChild, useful = 0;
		Type *tp1 = $1->type;

		// single pass over variables
		for (int i = 0; i < l2; i++) { // first check that there is no var in scope
			node_t *cnode = $2->ch(i); // "concerned node" - get directly
			Type *tp2 = cnode->type;

			// pass down tree $2 until name & position found.
			if (cnode->tok == '=') { cnode = cnode->ch(0); useful++; } // "init_declarator"
			while (cnode->tok != IDENTIFIER) { // pass down from "direct_declarator"
				if (cnode->tok == DECLARATOR) cnode = cnode->ch(1); // "decl" + rule 2 of "direct_decl"
				else cnode = cnode->ch(0); // rules 3 - 7 of "direct_decl"
			} // cnode->tok == IDENTIFIER

			sym* retval = SymRoot->lookup(cnode->label);
			// TODO: handle "extern"
			if (retval) {
				stringstream str1; str1 << "multiple declarations of \"" << cnode->label << "\" (will set variable to \"error\" type)"; repErr(cnode->pos, str1.str(), _FORE_RED_);
				repErr(retval->pos, "previous declaration given here...", _FORE_CYAN_);
				retval->type->base = ERROR_B;
			} else { // copy tp1 into tp2 (partially), delete tp1 (easier to copy tp1 than tp2).
				if (tp2->base != ERROR_B) tp2->base = tp1->base;
				tp2->qual = tp1->qual; tp2->sign = tp1->sign; tp2->strg = tp1->strg;
				tp2->enumDef = tp1->enumDef; tp2->unionDef = tp1->unionDef; tp2->structDef = tp1->structDef;
				SymRoot->pushSym(cnode->label, tp2, cnode->pos); // ASUMPTION: success - can check that too
			}
		}

		delete tp1;

		if (useful > 0) {
			edge_t **tmp = (edge_t **) malloc(useful * sizeof(edge_t *)); int curr = 0;
			for (int i = 0; i < l2; i++) if (ch2[i]->node->tok == '=') tmp[curr++] = ch2[i];
			free(ch2); $2->edges = tmp; $2->numChild = useful;
			$$ = $2;
		} else $$ = NULL;
	}
	;

// TODO: handle storage class "typedef"
// useless iff NULL
// A list of three kinds of objects. Also, new child appends to the left.
declaration_specifiers
	: storage_class_specifier                        { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) );
		Type* tp = $$->type = new Type();
		switch ($1->tok) { case AUTO : tp->strg = AUTO_S; break;
			case EXTERN : tp->strg = EXTERN_S; break; case REGISTER : tp->strg = REGISTER_S; break;
			case STATIC : tp->strg = STATIC_S; break; case TYPEDEF : tp->strg = TYPEDEF_S;
		}
	}
	| storage_class_specifier declaration_specifiers { $$ = op( $2, 1, 0, ej($1) ); Type* tp = $$->type;
		bool isStrg = (tp->strg != NONE_S);
		string stdErs = "more than required or incompatible storage class specifiers given (will set variable to \"error\" type)";
		switch ($1->tok) {
			case AUTO : if (!isStrg) tp->strg = AUTO_S; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case EXTERN : if (!isStrg) tp->strg = EXTERN_S; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case REGISTER : if (!isStrg) tp->strg = REGISTER_S; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case STATIC : if (!isStrg) tp->strg = STATIC_S; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case TYPEDEF : if (!isStrg) tp->strg = TYPEDEF_S; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
		}
	}
	| type_specifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) ); // FILE_OBJ and TYPE_NAME not taken into account
		Type* tp = $$->type = new Type();
		switch ($1->tok) {
			case VOID : tp->base = VOID_B; break; case CHAR : tp->base = CHAR_B; break;
			case SHORT : tp->base = SHORT_B; break; case INT : tp->base = INT_B; break;
			case LONG : tp->base = LONG_B; break; case FLOAT : tp->base = FLOAT_B; break;
			case DOUBLE : tp->base = DOUBLE_B; break; case STRUCT : tp->base = STRUCT_B; break;
			case UNION : tp->base = UNION_B; break; case ENUM : tp->base = ENUM_B; break;
			case SIGNED : tp->sign = SIGNED_X; break; case UNSIGNED : tp->sign = UNSIGNED_X; break; // sign changes, not type (type may be decided later)
		}
	}
	| type_specifier declaration_specifiers          { $$ = op( $2, 1, 0, ej($1) ); Type* tp = $$->type;
		bool isSpec = (tp->base != NONE_B); // see whether already specified a basic type
		bool signGiven = (tp->sign != NONE_X); // see whether already specified a sign
		base_type_t base = tp->base;
		string stdErs = "more than required or incompatible type specifiers given (will set variable to \"error\" type)";
		switch ($1->tok) {
			case VOID : if (!isSpec) tp->base = VOID_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case CHAR : if (!isSpec) tp->base = CHAR_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case INT :  if (!isSpec) tp->base = INT_B; else if (base == SHORT_B) tp->base = SHORT_B; else if (base == LONG_B) tp->base = LONG_B;
						else if (base == LONG_LONG_B) tp->base = LONG_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case SHORT : if (!isSpec || (base == INT_B)) tp->base = SHORT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case LONG : if (!isSpec || (base == INT_B)) tp->base = LONG_B; else if (base == LONG_B) tp->base = LONG_LONG_B;
						else if (base == DOUBLE_B) tp->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case FLOAT : if (!isSpec) tp->base = FLOAT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case DOUBLE : if (!isSpec) tp->base = DOUBLE_B; else if (base == LONG_B) tp->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case SIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) tp->sign = SIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case UNSIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) tp->sign = UNSIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case STRUCT : if (!isSpec) tp->base = STRUCT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case UNION : if (!isSpec) tp->base = UNION_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; } break;
			case ENUM : if (!isSpec) tp->base = ENUM_B; else { repErr($1->pos, stdErs,  _FORE_RED_); tp->base = ERROR_B; }
		}
	}
	| type_qualifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) );
		Type* t = $$->type = new Type();
		switch ($1->tok) { case CONST : t->qual.isConst = true; break; case VOLATILE : t->qual.isVolatile = true; }
	}
	| type_qualifier declaration_specifiers          { $$ = op( $2, 1, 0, ej($1) ); Type* t = $$->type;
		switch ($1->tok) {
			case CONST : if (t->qual.isConst) { repErr($2->pos, "const specified twice", _FORE_RED_); t->base = ERROR_B; } else t->qual.isConst = true; break;
			case VOLATILE : if (t->qual.isVolatile) { repErr($2->pos, "volatile specified twice", _FORE_RED_); t->base = ERROR_B; } else t->qual.isVolatile = true;
		}
	}
	;

// useless iff NULL
init_declarator_list
	: init_declarator { $$ = op( nd(INIT_DECL_LIST, "var-list", { 0, 0 }), 0, 1, ej($1) ); }
	| init_declarator_list ',' init_declarator { $$ = op( $1, 0, 1, ej($3) ); }
	;

// PARTIALLY DONE - TEST RULE 1
// useless iff NULL
init_declarator
	: declarator                 { $$ = $1;	} // handle uselessness at "declaration"
	| declarator '=' initializer { $$ = op( $2, 0, 2, ej($1), ej($3) );
		$$->type = $1->type;
		// TODO: Check assignment compatibility of declarator with intializer.
	}
	;

storage_class_specifier
	: TYPEDEF	{ $$ = $1; }
	| EXTERN	{ $$ = $1; }
	| STATIC	{ $$ = $1; }
	| AUTO		{ $$ = $1; }
	| REGISTER	{ $$ = $1; }
	;

type_specifier
	: VOID							{ $$ = $1; }
	| CHAR							{ $$ = $1; }
	| SHORT							{ $$ = $1; }
	| INT							{ $$ = $1; }
	| LONG							{ $$ = $1; }
	| FLOAT							{ $$ = $1; }
	| DOUBLE						{ $$ = $1; }
	| SIGNED						{ $$ = $1; }
	| UNSIGNED						{ $$ = $1; }
	| FILE_OBJ						{ $$ = $1; }
	| struct_or_union_specifier		{ $$ = $1; }
	| enum_specifier				{ $$ = $1; }
	| TYPE_NAME						{ $$ = $1; } // never encountered in ANSI C (just a user defined type)
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}' { $$ = op( $1, 0, 2, ej($2), ej($4) ); }
	| struct_or_union '{' struct_declaration_list '}'            { $$ = op( $1, 0, 1, ej($3) ); }
	| struct_or_union IDENTIFIER                                 { $$ = op( $1, 0, 1, ej($2) ); }
	;

struct_or_union
	: STRUCT	{ $$ = $1; }
	| UNION		{ $$ = $1; }
	;

struct_declaration_list 
	: struct_declaration                         { $$ = op( nd(ALL_MEMBERS, "member-list", { 0, 0 }), 0, 1, ej($1) ); }
	| struct_declaration_list struct_declaration { $$ = op( $1, 0, 1, ej($2) ); }
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';' { $$ = op( nd(STRUCT_MEMBER, "member", { 0, 0 }), 0, 2, ej($1), ej($2) ); }
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list { $$ = op( $2, 1, 0, ej($1) ); }
	| type_specifier                          { $$ = op( nd(SPEC_QUAL_LIST, "spec-qual", { 0, 0 }), 0, 1, ej($1) ); }
	| type_qualifier specifier_qualifier_list { $$ = op( $2, 1, 0, ej($1) ); }
	| type_qualifier			              { $$ = op( nd(SPEC_QUAL_LIST, "spec-qual", { 0, 0 }), 0, 1, ej($1) ); }
	;

struct_declarator_list
	: struct_declarator                            { $$ = op( nd(INIT_DECL_LIST, "var-list", { 0, 0 }), 0, 1, ej($1) ); }
	| struct_declarator_list ',' struct_declarator { $$ = op( $1, 0, 1, ej($3) ); }
	;

struct_declarator
	: declarator              { $$ = $1; }
	| ':' constant_expression { $$ = $2; }
	| declarator ':' constant_expression { $$ = op( nd(STRUCT_DECL, "declarator", { 0, 0 }), 0, 2, ej($1), ej($3) ); }
	;

enum_specifier
	: ENUM '{' enumerator_list '}'				{ $$ = op( $1, 0, 1, ej($3) ); }
	| ENUM IDENTIFIER '{' enumerator_list '}'	{ $$ = op( $1, 0, 2, ej($2), ej($4) ); }
	| ENUM IDENTIFIER							{ $$ = op( $1, 0, 1, ej($2) ); }
	;

enumerator_list
	: enumerator						{ $$ = op( nd(ENUM_LIST, "enum-list", { 0, 0 }), 0, 1, ej($1) ); }
	| enumerator_list ',' enumerator	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

enumerator
	: IDENTIFIER							{ $$ = $1; }
	| IDENTIFIER '=' constant_expression	{ $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

type_qualifier
	: CONST		{ $$ = $1; }
	| VOLATILE	{ $$ = $1; }
	;

declarator
	: pointer direct_declarator	{ $$ = op( nd(DECLARATOR, "var", { 0, 0 }), 0, 2, ej($1), ej($2) ); // copy pointers to direct_declarator
		Type* tp = $$->type = $2->type;
		tp->ptrs = $1->type->ptrs; // copied pointers
		delete $1->type; $1->type = NULL;
	}
	| direct_declarator			{ $$ = $1; }
	;

// Check existence of "IDENTIFIER" later
// check whether all bounds given if not in parameter list - declaration level
// do not lookup variable if in parameter list
direct_declarator
	: IDENTIFIER									{ $$ = $1; $1->type = new Type(); }
	| '(' declarator ')'							{ $$ = $2; expectSub = true; }
	| direct_declarator '[' constant_expression ']'	{ $$ = op( $2, 0, 2, ej($1), ej($3) );
		Type *t, *t1 = $1->type; bool _good = false;
		if (expectSub && t1->isPtr()) { t = $$->type = new Type(); t->sub = t1; _good = true; }
		else if (t1->isFunc()) repErr($1->pos, "function returns an array (will set variable to \"error\" type)", _FORE_RED_);
		else { t = $$->type = t1; _good = true; }
		expectSub = false;
		
		// check $3's type -> must be acceptable as array bound -> set _good accordingly

		if (_good) t->newArrBnd($3);
		else { t = $$->type = t1; t->base = ERROR_B; }
	}
	| direct_declarator '[' ']'						{ $$ = op( $2, 0, 1, ej($1) );
		Type *t, *t1 = $1->type; bool _good = false;
		if (expectSub && t1->isPtr()) { t = $$->type = new Type(); t->sub = t1; _good = true; }
		else if (t1->isFunc()) repErr($1->pos, "function returns an array (will set variable to \"error\" type)", _FORE_RED_);
		else if (t1->isArr()) repErr($1->pos, "incomplete array bound: all bounds except first must be specified (will set variable to \"error\" type)", _FORE_RED_); // unspecified non-first bound
		else { t = $$->type = t1; _good = true; }
		expectSub = false;

		if (_good) t->newArrBnd();
		else { t = $$->type = t1; t->base = ERROR_B; }
	}
	| direct_declarator '(' parameter_type_list ')'	{ $$ = $1; // $$ = op( nd(FUNC_PTR, "() [func-ptr]", { 0, 0 }), 0, 2, ej($1), ej($3) );
		Type *t, *t1 = $1->type; bool _good = false;
		if (expectSub && t1->isPtr()) { t = $$->type = new Type(); t->sub = t1; _good = true; }
		else if (t1->isFunc()) repErr($1->pos, "function returns a function (will set variable to \"error\" type)", _FORE_RED_); // must not be a function
		else if (t1->isArr()) repErr($1->pos, "array of functions (will set variable to \"error\" type)", _FORE_RED_);
		else { t = $$->type = t1; _good = true; }
		expectSub = false;

		if (_good) {
			int l = $3->numChild; // check (1) there must be no pure "void" type, (2) ellipsis occurence
			for (int i = 0; i < l; i++) { node_t* ch = $3->ch(i); Type* ti = ch->type; // check whether "ti" is a good type
				t->newFuncParam(ti);
			}
		} else { t = $$->type = t1; t->base = ERROR_B; }
	}
	| direct_declarator '(' identifier_list ')'	{ $$ = $1; // $$ = op( nd(FUNC_PTR, "() [func-ptr]", { 0, 0 }), 0, 2, ej($1), ej($3) );
		repErr($3->pos, "warning: parameter names without any declaration specifiers", _FORE_MAGENTA_);
		Type *t, *t1 = $1->type; bool _good = false;
		if (expectSub && t1->isPtr()) { t = $$->type = new Type(); t->sub = t1; _good = true; }
		else if (t1->isFunc()) repErr($1->pos, "function returns a function (will set variable to \"error\" type)", _FORE_RED_); // must not be a function
		else if (t1->isArr())  repErr($1->pos, "array of functions (will set variable to \"error\" type)", _FORE_RED_); // unspecified non-first bound
		else { t = $$->type = t1; _good = true; }
		expectSub = false;

		if (_good) {
			int l = $3->numChild; // check (1) there must be no pure "void" type, (2) ellipsis occurence
			for (int i = 0; i < l; i++) {
				node_t* ch = $3->ch(i); sym* ret = SymRoot->gLookup(ch->label);
				if (ret) t->newFuncParam(ret->type); // assume this was a good type (since it was already inserted)
				else {
					t->base = ERROR_B; repErr(ch->pos, "variable undeclared in this scope (will set variable to \"error\" type)", _FORE_RED_); // coordi
				}
			}
		} else { t = $$->type = t1; t->base = ERROR_B; }
	}
	| direct_declarator '(' ')' { $$ = op( $2, 0, 1, ej($1) ); $$->type = $1->type; $$->tok = FUNC_PTR;	$$->label = "() [func-ptr]";
		Type *t, *t1 = $1->type; bool _good = false;
		if (expectSub && t1->isPtr()) { t = $$->type = new Type(); t->sub = t1; _good = true; }
		else if (t1->isFunc()) repErr($1->pos, "function returns a function (will set variable to \"error\" type)", _FORE_RED_); // must not be a function
		else if (t1->isArr()) repErr($1->pos, "array of functions (will set variable to \"error\" type)", _FORE_RED_);
		else { t = $$->type = t1; _good = true; }
		expectSub = false;

		if (_good) {
			Type* tmp = new Type(); tmp->base = VOID_B; tmp->strg = AUTO_S; t->newFuncParam(tmp); // void argument
		} else { t = $$->type = t1; t->base = ERROR_B; }
	}
	;

pointer
	: '*'								{ ($1)->tok = DEREF; $$ = $1;
		Type *t = $$->type = new Type(); t->ptrs.push_back(qual_t());
	}
	| '*' type_qualifier_list			{ ($1)->tok = DEREF; $$ = $1; // $$ = op( $1, 0, 1, ej($2) );
		Type *t = $$->type = $2->type; t->ptrs.push_back(t->qual);
		t->qual.isConst = t->qual.isVolatile = false; // clean the slate
	}
	| '*' pointer { ($1)->tok = DEREF; $$ = op( $1, 0, 1, ej($2) );
		Type *t = $$->type = $2->type; t->ptrs.insert(t->ptrs.begin(), qual_t());
	}
	| '*' type_qualifier_list pointer { ($1)->tok = DEREF; $$ = op( $1, 0, 1, ej($3) ); // $$ = op( $1, 0, 2, ej($2), ej($3) );
		Type *t2 = $2->type, *t3 = $3->type, *t = $$->type = t3;
		t->ptrs.insert(t->ptrs.begin(), t2->qual);
		if (t2->base == ERROR_B || t3->base == ERROR_B) t->base = ERROR_B;
		delete t2;
	}
	;

type_qualifier_list
	: type_qualifier						{ $$ = op( nd(TYPE_QUAL_LIST, "type-quals", { 0, 0 }), 0, 1, ej($1) );
		Type* t = $$->type = new Type();
		switch ($1->tok) { case CONST : t->qual.isConst = true; break; case VOLATILE : t->qual.isVolatile = true; }
	}
	| type_qualifier_list type_qualifier	{ $$ = op( $1, 0, 1, ej($2) ); Type* t = $$->type;
		switch ($2->tok) {
			case CONST : if (t->qual.isConst) { repErr($2->pos, "const specified twice", _FORE_RED_); t->base = ERROR_B; } else t->qual.isConst = true; break;
			case VOLATILE : if (t->qual.isVolatile) { repErr($2->pos, "volatile specified twice", _FORE_RED_); t->base = ERROR_B; } else t->qual.isVolatile = true;
		}
	}
	;

parameter_type_list
	: parameter_list				{ $$ = $1; }
	| parameter_list ',' ELLIPSIS	{ $$ = op( $1, 0, 1, ej($3) ); Type* t3 = $3->type = new Type(); t3->base = ELLIPSIS_B; }
	;

parameter_list
	: parameter_declaration						{ $$ = op( nd(PARAM_TYPE_LIST, "param-types", { 0, 0 }), 0, 1, ej($1) ); }
	| parameter_list ',' parameter_declaration	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

parameter_declaration
	: declaration_specifiers declarator            { $$ = op( nd(PARAM_DECL, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t1 = $1->type, *t2 = $2->type, *t = $$->type = t2; // delete t1
		// copy t1 into t2 (partially)
		if (t1->strg != NONE_S) { // t1 must not carry any storage class
			t->base = ERROR_B; repErr($1->pos, "storage class specified for parameter", _FORE_RED_);
		} else if (checkVoid(t1, t2)) { // how to check void ?  t1->base == VOID_B and t1->
			t->base = ERROR_B; repErr($1->pos, "variable declared void", _FORE_RED_);
		} else {
			t->base = t1->base; t->qual = t1->qual; t->sign = t1->sign; t->strg = t1->strg;
			t->enumDef = t1->enumDef; t->unionDef = t1->unionDef; t->structDef = t1->structDef;
		}
		if (t1->base == ERROR_B || t2->base == ERROR_B) t->base = ERROR_B;
		delete t1;
	}
	| declaration_specifiers abstract_declarator   { $$ = op( nd(PARAM_DECL, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t1 = $1->type, *t2 = $2->type, *t = $$->type = t2; // delete t1
		if (t1->base == ERROR_B || t2->base == ERROR_B) t->base = ERROR_B;
		else { // copy t1 into t2 (partially)
			if (t1->strg != NONE_S) { // t1 must not carry any storage class
				t->base = ERROR_B; repErr($1->pos, "storage class specified for parameter", _FORE_RED_);
			} else {
				t->base = t1->base; t->qual = t1->qual; t->sign = t1->sign; t->strg = t1->strg;
				t->enumDef = t1->enumDef; t->unionDef = t1->unionDef; t->structDef = t1->structDef;
			}
		}
		delete t1;
	}
	| declaration_specifiers                       { $$ = $1; }
	;

identifier_list
	: IDENTIFIER                       { $$ = op( nd(ID_LIST, "identifiers", { 0, 0 }), 0, 1, ej($1) ); }
	| identifier_list ',' IDENTIFIER   { $$ = op( $1, 0, 1, ej($3) ); }
	;

type_name
	: specifier_qualifier_list                        { $$ = op( nd(TYPE_NAME, "type-name", { 0, 0 }), 0, 1, ej($1) ); }
	| specifier_qualifier_list abstract_declarator    { $$ = op( $1, 0, 1, ej($2) ); }
	;

abstract_declarator
	: pointer                              { $$ = $1; }
	| direct_abstract_declarator           { $$ = $1; }
	| pointer direct_abstract_declarator   { $$ = op( nd(ABSTRACT_DECLARATOR, "abst-decl", { 0, 0 }), 0, 2, ej($1), ej($2) ); }
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'                                { $$ = $2; }
	| '[' ']'                                                    { $$ = $1; }
	| '[' constant_expression ']'                                { $$ = op( $1, 0, 1, ej($2)); }
	| direct_abstract_declarator '[' ']'                         { $$ = op( $2, 0, 1, ej($1) ); }
	| direct_abstract_declarator '[' constant_expression ']'     { $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	| '(' ')'                                                    { $1->tok = ABST_DCLN; $1->label = "() abst-dcln"; $$ = $1; }
	| '(' parameter_type_list ')'                                { $1->tok = ABST_DCLN; $1->label = "() abst-dcln"; $$ = op( $1, 0, 1, ej($2) ); } // ! Will handle
	| direct_abstract_declarator '(' ')'                         { $2->tok = ABST_DCLN; $2->label = "() abst-dcln"; $$ = op( $2, 0, 1, ej($1) ); }
	| direct_abstract_declarator '(' parameter_type_list ')'     { $2->tok = ABST_DCLN; $2->label = "() abst-dcln"; $$ = op( $2, 0, 2, ej($1), ej($3) ); }
	;

initializer
	: assignment_expression			{ $$ = $1; }
	| '{' initializer_list '}'		{ $$ = $2; }
	| '{' initializer_list ',' '}'	{ $$ = $2; }
	;

initializer_list
	: initializer						{ $$ = op( nd(INIT_LIST, "array", { 0, 0 }), 0, 1, ej($1) ); }
	| initializer_list ',' initializer	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

statement
	: labeled_statement    { $$ = $1; }
	| compound_statement   { $$ = $1; }
	| expression_statement { $$ = $1; }
	| selection_statement  { $$ = $1; }
	| iteration_statement  { $$ = $1; }
	| jump_statement       { $$ = $1; }
	;

labeled_statement
	: IDENTIFIER ':' statement                { ($1)->attr = label_attr; $$ = op( $1, 0, 1, ej($3) ); }
	| CASE constant_expression ':' statement  { $$ = op( $1, 0, 2, ej($2), ej($4) ); }
	| DEFAULT ':' statement                   { $$ = op( $1 , 0, 1, ej($3) ); }
	;

// useless iff EMPTY_BLOCK (can't substitute NULL, since EMPTY_BLOCK is still a valid function definition)
compound_statement
	: '{' '}'                                 { $$ = $1; SymRoot->closeScope(); }
	| '{' statement_list '}'                  { $$ = ($2) ? ($2) : ($1); SymRoot->closeScope(); }
	| '{' declaration_list '}'                { $$ = ($2) ? ($2) : ($1); SymRoot->closeScope(); }
	| '{' declaration_list statement_list '}' {
		if (($2) && ($3)) { $$ = op( nd(GEN_BLOCK, "block", { 0, 0 }), 0, 2, ej($2), ej($3) ); }
		else if ($2) { $$ = $2; } // only useful decl. list.
		else if ($3) { $$ = $3; } // only useful stmt. list.
		else { $$ = ( $1); } // empty block
		SymRoot->closeScope();
	}
	;

// useless iff NULL
declaration_list
	: declaration { $$ = ($1) ? op( nd(DECL_LIST, "declarations", { 0, 0 }), 0, 1, ej($1) ) : NULL; }
	| declaration_list declaration	{
		if ($1 && $2) { $$ = op( $1, 0, 1, ej($2) ); } // both useful - simply append
		else if ($1) { $$ = $1; } // new child not useful
		else if ($2) { $$ = op( nd(DECL_LIST, "declarations", { 0, 0 }), 0, 1, ej($2) ); } // first useful child
		else { $$ = NULL; }
	}
	;

statement_list
	: statement                { $$ = op( nd(STMT_LIST, "stmt-list", { 0, 0 }), 0, 1, ej($1) ); }
	| statement_list statement { $$ = op( $1, 0, 1, ej($2) ); }
	;

expression_statement
	: ';'				{ $$ = $1; }
	| expression ';'	{ $$ = $1; }
	;

selection_statement
	: IF '(' expression ')' statement { $$ = op( $1, 0, 2,
		Ej($3, "cond", NULL), Ej($5, "stmts", NULL)
	); }
	| IF '(' expression ')' statement ELSE statement { $$ = op( $6, 0, 3,
		Ej($3, "cond", NULL), Ej($5, "stmts (if TRUE)", NULL), Ej($7, "stmts (if FALSE)", NULL)
	); }
	| SWITCH '(' expression ')' statement { $$ = op( $1, 0, 2,
		Ej($3, "expr", NULL), Ej($5, "stmts", NULL)
	); }
	;

iteration_statement
	: WHILE '(' expression ')' statement { $$ = op( $1, 0, 2,
		Ej($3, "expr", NULL), Ej($5, "stmts", NULL)
	); }
	| DO statement WHILE '(' expression ')' ';' { $$ = op( $1, 0, 2,
		Ej($2, "stmts", NULL), Ej($5, "expr", NULL)
	); }
	| FOR '(' expression_statement expression_statement ')' statement { $$ = op( $1, 0, 3,
		Ej($3, "expr", NULL), Ej($4, "expr", NULL), Ej($6, "stmts", NULL)
	); }
	| FOR '(' expression_statement expression_statement expression ')' statement  { $$ = op( $1, 0, 4,
		Ej($3, "expr", NULL), Ej($4, "expr", NULL), Ej($5, "expr", NULL), Ej($7, "stmts", NULL)
	); }
	;

jump_statement
	: GOTO IDENTIFIER ';'	{ $$ = op( $1, 0, 1, ej($2) ); }
	| CONTINUE ';'			{ $$ = $1; }
	| BREAK ';'				{ $$ = $1; }
	| RETURN ';'			{ $$ = $1; }
	| RETURN expression ';'	{ $$ = op( $1, 0, 1, ej($2) ); }
	;

translation_unit
	: external_declaration	{ AstRoot = ($$ = ($1) ? op( Nd(-1, fileName, file_name_attr, { 0, 0 }), 0, 1, ej($1) ) : NULL); } // Bad lincoln
	| translation_unit external_declaration	{
		if ($1 && $2) { $$ = op( $1, 0, 1, ej($2) ); }
		else if ($1) { $$ = $1; } // new child useless
		else if ($2) { $$ = op( Nd(-1, fileName, file_name_attr, { 0, 0 }), 0, 1, ej($2) ); } // Bad lincoln
		else { $$ = NULL; }
		AstRoot = $$;
	}
	;

external_declaration
	: function_definition		{ $$ = $1; }
	| declaration { $$ = ($1) ? ($1) : NULL; }
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
		$$ = ($3)
		? op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 3, ej($2), ej($3), ej($4) )
		: op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($2), ej($4) );
	}
	| declaration_specifiers declarator compound_statement { $$ = op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($2), ej($3)); }
	| declarator declaration_list compound_statement {
		$$ = ($2)
		? op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 3, ej($1), ej($2), ej($3) )
		: op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($1), ej($3) );
	}
	| declarator compound_statement { $$ = op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($1), ej($2) ); }
	;

%%
