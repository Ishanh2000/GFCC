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
#include <types2.h>
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
		if (ret) $$->type = clone(ret->type); // success - start by making a copy of type.
		else {
			repErr($1->pos, "variable undeclared in this scope", _FORE_RED_);
			Type* t = $$->type = new Type(); t->isErr = true;
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
			heir(cnode->type);
			/* while (cnode->tok != IDENTIFIER) { // pass down from "direct_declarator"
				if (cnode->tok == DECLARATOR) cnode = cnode->ch(1); // "decl" + rule 2 of "direct_decl"
				else cnode = cnode->ch(0); // rules 3 - 7 of "direct_decl"
			} // cnode->tok == IDENTIFIER

			sym* retval = SymRoot->lookup(cnode->label);
			// TODO: handle "extern"
			if (retval) {
				stringstream str1; str1 << "multiple declarations of \"" << cnode->label << "\""; repErr(cnode->pos, str1.str(), _FORE_RED_);
				repErr(retval->pos, "previous declaration given here...", _FORE_CYAN_);
				retval->type->base = ERROR_B;
			} else { // copy tp1 into tp2 (partially), delete tp1 (easier to copy tp1 than tp2).
				if (tp2->base != ERROR_B) tp2->base = tp1->base;
				tp2->qual = tp1->qual; tp2->sign = tp1->sign; tp2->strg = tp1->strg;
				tp2->enumDef = tp1->enumDef; tp2->unionDef = tp1->unionDef; tp2->structDef = tp1->structDef;
				SymRoot->pushSym(cnode->label, tp2, cnode->pos); // ASUMPTION: success - can check that too
			} */
		}

		if (useful > 0) {
			edge_t **tmp = (edge_t **) malloc(useful * sizeof(edge_t *)); int curr = 0;
			for (int i = 0; i < l2; i++) if (ch2[i]->node->tok == '=') tmp[curr++] = ch2[i];
			free(ch2); $2->edges = tmp; $2->numChild = useful;
			$$ = $2;
		} else $$ = NULL;
	}
	;

// TODO: handle storage class "typedef"
// A list of three kinds of objects. Also, new child appends to the left.
declaration_specifiers
	: storage_class_specifier                        { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) );
		Base* b = new Base();
		switch ($1->tok) {
			case     AUTO : b->strg = AUTO_S; break;
			case   EXTERN : b->strg = EXTERN_S; break;
			case REGISTER : b->strg = REGISTER_S; break;
			case   STATIC : b->strg = STATIC_S; break;
			case  TYPEDEF : b->strg = TYPEDEF_S; break;
		}
		$$->type = b;
	}
	| storage_class_specifier declaration_specifiers { $$ = op( $2, 1, 0, ej($1) );
		Base* b = (Base *) $$->type;
		if (b->strg != NONE_S) {
			b->isErr = true;
			repErr($2->pos, "more than required or incompatible storage class specifiers given",  _FORE_RED_);
		} else switch ($1->tok) {
			case     AUTO : b->strg = AUTO_S; break;
			case   EXTERN : b->strg = EXTERN_S; break;
			case REGISTER : b->strg = REGISTER_S; break;
			case   STATIC : b->strg = STATIC_S; break;
			case  TYPEDEF : b->strg = TYPEDEF_S; break;
		}
	}
	| type_specifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) );
		Type *b;
		switch ($1->tok) {
			case      VOID : b = new Base(VOID_B); break;
			case      CHAR : b = new Base(CHAR_B); break;
			case     SHORT : b = new Base(SHORT_B); break;
			case       INT : b = new Base(INT_B); break;
			case      LONG : b = new Base(LONG_B); break;
			case     FLOAT : b = new Base(FLOAT_B); break;
			case    DOUBLE : b = new Base(DOUBLE_B); break;
			case    STRUCT : b = new Base(STRUCT_B); break;
			case     UNION : b = new Base(UNION_B); break;
			case      ENUM : b = new Base(ENUM_B); break;
			case    SIGNED : b = new Base(); ((Base *)b)->sign = SIGNED_X; break; // sign changes, not type (type may be decided later)
			case  UNSIGNED : b = new Base(); ((Base *)b)->sign = UNSIGNED_X; break; // sign changes, not type (type may be decided later)
			case TYPE_NAME : b = $1->type; tpdef = true; break; // already specified (due to typedef)
		}
		$$->type = b;
	}
	| type_specifier declaration_specifiers          { $$ = op( $2, 1, 0, ej($1) );
		string stdErs = "more than required or incompatible type specifiers given";
		if (tpdef && ($1->tok == TYPEDEF)) {
			repErr($1->pos, stdErs,  _FORE_RED_); $$->type->isErr = true;
		} else {
			if ($$->type->grp() == BASE_G) { // simple base or a typedef that is a simple base
				Base* b = (Base *) $$->type; base_t base = b->base;
				bool isSpec = (base != NONE_B), signGiven = (b->sign != NONE_X); // whether already specified a base / sign
				switch ($1->tok) {
					case VOID : if (!isSpec) b->base = VOID_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case CHAR : if (!isSpec) b->base = CHAR_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case INT :  if (!isSpec) b->base = INT_B; else if (base == SHORT_B) b->base = SHORT_B; else if (base == LONG_B) b->base = LONG_B;
								else if (base == LONG_LONG_B) b->base = LONG_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case SHORT : if (!isSpec || (base == INT_B)) b->base = SHORT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case LONG : if (!isSpec || (base == INT_B)) b->base = LONG_B; else if (base == LONG_B) b->base = LONG_LONG_B;
								else if (base == DOUBLE_B) b->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case FLOAT : if (!isSpec) b->base = FLOAT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case DOUBLE : if (!isSpec) b->base = DOUBLE_B; else if (base == LONG_B) b->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case SIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) b->sign = SIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNSIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) b->sign = UNSIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case STRUCT : if (!isSpec) b->base = STRUCT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNION : if (!isSpec) b->base = UNION_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case ENUM : if (!isSpec) b->base = ENUM_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; }
				}
			} else { // typedef that is not a simple type
				repErr($1->pos, stdErs, _FORE_RED_); $$->type->isErr = true;
			}
		}
	}
	| type_qualifier                                 { $$ = op( nd(DECL_SPEC_LIST, "decl-specs", { 0, 0 }), 0, 1, ej($1) ); // completed
		Base *b = new Base();
		switch ($1->tok) { case CONST : b->isConst = true; break; case VOLATILE : b->isVoltl = true; }
		$$->type = b;
	}
	| type_qualifier declaration_specifiers          { $$ = op( $2, 1, 0, ej($1) );
		if ($$->type->grp() == BASE_G) { // base or typedef that is a simple base
			Base *b = (Base *) $$->type;
			switch ($1->tok) {
				case    CONST : if (b->isConst) repErr($2->pos, "warning: const specified twice",    _FORE_MAGENTA_); b->isConst = true; break;
				case VOLATILE : if (b->isVoltl) repErr($2->pos, "warning: volatile specified twice", _FORE_MAGENTA_); b->isVoltl = true;
			}
		} else { // typedef that is not a simple base - traverse till the base
			Type *t = $$->type;
			while (t && t->grp() != BASE_G) {
				switch (t->grp()) {
					case  PTR_G : t = ((Ptr *) t)->pt; break;
					case  ARR_G : t = ((Arr *) t)->item; break;
					case FUNC_G : t = ((Func *) t)->retType; break;
				}
			} // assume t != NULL
			switch ($1->tok) {
				case    CONST : if (((Base*)t)->isConst) repErr($2->pos, "warning: const specified twice",    _FORE_MAGENTA_); ((Base*)t)->isConst = true; break;
				case VOLATILE : if (((Base*)t)->isVoltl) repErr($2->pos, "warning: volatile specified twice", _FORE_MAGENTA_); ((Base*)t)->isVoltl = true;
			}
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
	: declarator                 { $$ = $1; brackPut = false; } // handle uselessness at "declaration"
	| declarator '=' initializer { $$ = op( $2, 0, 2, ej($1), ej($3) ); brackPut = false;
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
	| TYPE_NAME						{ $$ = $1; }
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
	: type_specifier specifier_qualifier_list { $$ = op( $2, 1, 0, ej($1) );
		string stdErs = "more than required or incompatible type specifiers given";
		if (tpdef && ($1->tok == TYPEDEF)) {
			repErr($1->pos, stdErs,  _FORE_RED_); $$->type->isErr = true;
		} else {
			if ($$->type->grp() == BASE_G) { // simple base or a typedef that is a simple base
				Base* b = (Base *) $$->type;
				base_t base = b->base; bool isSpec = (base != NONE_B), signGiven = (b->sign != NONE_X); // whether already specified a base / sign
				switch ($1->tok) {
					case VOID : if (!isSpec) b->base = VOID_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case CHAR : if (!isSpec) b->base = CHAR_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case INT :  if (!isSpec) b->base = INT_B; else if (base == SHORT_B) b->base = SHORT_B; else if (base == LONG_B) b->base = LONG_B;
								else if (base == LONG_LONG_B) b->base = LONG_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case SHORT : if (!isSpec || (base == INT_B)) b->base = SHORT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case LONG : if (!isSpec || (base == INT_B)) b->base = LONG_B; else if (base == LONG_B) b->base = LONG_LONG_B;
								else if (base == DOUBLE_B) b->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case FLOAT : if (!isSpec) b->base = FLOAT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case DOUBLE : if (!isSpec) b->base = DOUBLE_B; else if (base == LONG_B) b->base = LONG_DOUBLE_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case SIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) b->sign = SIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNSIGNED : if (!signGiven && (base == CHAR_B || base == SHORT_B || base == INT_B || base == LONG_B || base == LONG_LONG_B)) b->sign = UNSIGNED_X; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case STRUCT : if (!isSpec) b->base = STRUCT_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNION : if (!isSpec) b->base = UNION_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case ENUM : if (!isSpec) b->base = ENUM_B; else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; }
				}
			} else { // typedef that is not a simple type
				repErr($1->pos, stdErs, _FORE_RED_); $$->type->isErr = true;
			}
		}
	}
	| type_specifier                          { $$ = op( nd(SPEC_QUAL_LIST, "spec-qual", { 0, 0 }), 0, 1, ej($1) ); // completed
		Type *b;
		switch ($1->tok) {
			case      VOID : b = new Base(VOID_B); break;
			case      CHAR : b = new Base(CHAR_B); break;
			case     SHORT : b = new Base(SHORT_B); break;
			case       INT : b = new Base(INT_B); break;
			case      LONG : b = new Base(LONG_B); break;
			case     FLOAT : b = new Base(FLOAT_B); break;
			case    DOUBLE : b = new Base(DOUBLE_B); break;
			case    STRUCT : b = new Base(STRUCT_B); break;
			case     UNION : b = new Base(UNION_B); break;
			case      ENUM : b = new Base(ENUM_B); break;
			case    SIGNED : b = new Base(); ((Base *)b)->sign = SIGNED_X; break; // sign changes, not type (type may be decided later)
			case  UNSIGNED : b = new Base(); ((Base *)b)->sign = UNSIGNED_X; break; // sign changes, not type (type may be decided later)
			case TYPE_NAME : b = $1->type; tpdef = true; break; // already specified
		}
		$$->type = b;
	}
	| type_qualifier specifier_qualifier_list { $$ = op( $2, 1, 0, ej($1) );
		if ($$->type->grp() == BASE_G) { // base or typedef that is a simple base
			Base *b = (Base *) $$->type;
			switch ($1->tok) {
				case    CONST : if (b->isConst) repErr($2->pos, "warning: const specified twice",    _FORE_MAGENTA_); b->isConst = true; break;
				case VOLATILE : if (b->isVoltl) repErr($2->pos, "warning: volatile specified twice", _FORE_MAGENTA_); b->isVoltl = true;
			}
		} else { // typedef that is not a simple base - traverse till the base
			Type *t = $$->type;
			while (t && t->grp() != BASE_G) {
				switch (t->grp()) {
					case  PTR_G : t = ((Ptr *) t)->pt; break;
					case  ARR_G : t = ((Arr *) t)->item; break;
					case FUNC_G : t = ((Func *) t)->retType; break;
				}
			} // assume t != NULL
			switch ($1->tok) {
				case    CONST : if (((Base*)t)->isConst) repErr($2->pos, "warning: const specified twice",    _FORE_MAGENTA_); ((Base*)t)->isConst = true; break;
				case VOLATILE : if (((Base*)t)->isVoltl) repErr($2->pos, "warning: volatile specified twice", _FORE_MAGENTA_); ((Base*)t)->isVoltl = true;
			}
		}
	}
	| type_qualifier			              { $$ = op( nd(SPEC_QUAL_LIST, "spec-qual", { 0, 0 }), 0, 1, ej($1) );
		Base *b = new Base();
		switch ($1->tok) { case CONST : b->isConst = true; break; case VOLATILE : b->isVoltl = true; }
		$$->type = b;
	}
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
		Type *t2 = $2->type, *tt = tail(t2);
		if (!t2) $$->type = $1->type;
		else {
			Ptr *dst = (Ptr*)tt, *src = (Ptr*)($1->type); int l = src->ptrs.size();
			switch (tt->grp()) {
				case  PTR_G : // merge src->ptrs into dst->ptrs from left
					for (int i = 0; i < l; i++) dst->ptrs.insert(dst->ptrs.begin(), src->ptrs[l-i-1]);
					break;
				case  ARR_G : ((Arr *) tt)->item = $1->type; break;
				case FUNC_G : ((Func *)tt)->retType = $1->type; break;
			}
			$$->type = t2; t2->isErr |= $1->type->isErr;
		}
	}
	| direct_declarator			{ $$ = $1; }
	;

// not handled array bound "constant_expression" type
direct_declarator
	: IDENTIFIER									{ $$ = $1; } // completed
	| '(' declarator ')'							{ $$ = $2; brackPut = true; }
	| direct_declarator '[' constant_expression ']'	{ loc_t bra = $2->pos; $$ = op( $2, 0, 2, ej($1), ej($3) );
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL, $3); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL, $3);
		else {
			Arr *a = (Arr *) last(t1, ARR_G);
			if (a) { a->newDim($3); $$->type = t1; }
			else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		}
		brackPut = false;
	}
	| direct_declarator '[' ']'						{ loc_t bra = $2->pos; $$ = op( $2, 0, 1, ej($1) );
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL);
		else if (last(t1, ARR_G)) {
			repErr(bra, "incomplete array bound: all bounds except first must be specified", _FORE_RED_);
			$$->type = t1; t1->isErr = true;
		} else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		brackPut = false;
	}
	| direct_declarator '(' parameter_type_list ')'	{ loc_t bra = $2->pos; $$ = $1; /* $$ = op( nd(FUNC_PTR, "() [func-ptr]", { 0, 0 }), 0, 2, ej($1), ej($3) ); */
		int l = $3->numChild; bool pureVoid = false, argErr = false; vector<class Type *> v;
		for (int i = 0; i < l; i++) {
			node_t *ch = $3->ch(i); Type *cht = ch->type; v.push_back(cht);
			if ( cht && (cht->grp() == BASE_G) && (((Base*)cht)->base == VOID_B) ) { // i-th arg is "void"
				if (i == 0) { pureVoid = true; continue; }
				repErr(ch->pos, "\"void\" must be the only argument", _FORE_RED_); argErr = true;
			}
		}

		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) {
			Func* f = new Func(NULL); ((Ptr*)tt)->pt = f;
			$$->type = t1; t1->isErr |= argErr;
			if (! (t1->isErr || pureVoid) ) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (!t1) {
			Func *f = new Func(NULL); $$->type = f; f->isErr = argErr;
			if (! ( f->isErr || pureVoid) ) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (last(t1, ARR_G)) {
			repErr(bra, "array of functions", _FORE_RED_); $$->type = t1; t1->isErr = true;
		} else {
			repErr(bra, "function returns a function", _FORE_RED_); $$->type = t1; t1->isErr = true;
		}
		brackPut = false;
	}
	| direct_declarator '(' identifier_list ')'	    { loc_t bra = $2->pos; $$ = $1; /* $$ = op( nd(FUNC_PTR, "() [func-ptr]", { 0, 0 }), 0, 2, ej($1), ej($3) ); */
		int l = $3->numChild; bool pureVoid = false, argErr = false; vector<class Type *> v;
		for (int i = 0; i < l; i++) {
			node_t *ch = $3->ch(i);
			sym *ret = SymRoot->gLookup(ch->label);
			if (!ret) { repErr(ch->pos, "variable undeclared in this scope", _FORE_RED_); argErr = true; v.push_back(NULL); continue; }
			Type *cht = ret->type; v.push_back(cht);
			if ( cht && (cht->grp() == BASE_G) && (((Base *)cht)->base == VOID_B) ) {
				if (i == 0) { pureVoid = true; continue; }
				repErr(ch->pos, "argument of type \"void\"", _FORE_RED_); argErr = true;
			}
		}

		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) {
			Func* f = new Func(NULL); ((Ptr*)tt)->pt = f;
			$$->type = t1; t1->isErr |= argErr;
			if (! (t1->isErr || pureVoid)) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (!t1) {
			Func *f = new Func(NULL); $$->type = f; f->isErr = argErr;
			if (! ( f->isErr || pureVoid)) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (last(t1, ARR_G)) {
			repErr(bra, "array of functions", _FORE_RED_); $$->type = t1; t1->isErr = true;
		} else {
			repErr(bra, "function returns a function", _FORE_RED_); $$->type = t1; t1->isErr = true;
		}
		brackPut = false;
	}
	| direct_declarator '(' ')' { loc_t bra = $2->pos; $$ = op( $2, 0, 1, ej($1) ); $$->tok = FUNC_PTR; $$->label = "() [func-ptr]";
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr*)tt)->pt = new Func(NULL); $$->type = t1; }
		else if (!t1) $$->type = new Func(NULL);
		else if (last(t1, ARR_G)) {
			repErr(bra, "array of functions", _FORE_RED_); $$->type = t1; t1->isErr = true;
		} else {
			repErr(bra, "function returns a function", _FORE_RED_); $$->type = t1; t1->isErr = true;
		}
		brackPut = false;
	}
	;

pointer
	: '*'								{ ($1)->tok = DEREF; $$ = $1;
		$$->type = new Ptr(NULL); // get the pointee (pt = NULL) later
	}
	| '*' type_qualifier_list			{ ($1)->tok = DEREF; $$ = $1; // $$ = op( $1, 0, 1, ej($2) );
		Base *b2 = (Base *) ($2->type);
		Ptr *p = new Ptr(NULL, b2->isConst, b2->isVoltl); // get the pointee (pt = NULL) later
		p->isErr = b2->isErr;
		$$->type = p;
	}
	| '*' pointer { ($1)->tok = DEREF; $$ = op( $1, 0, 1, ej($2) );
		$$->type = $2->type; Ptr *p = (Ptr *) ($$->type);
		p->ptrs.insert(p->ptrs.begin(), _qual_t());
	}
	| '*' type_qualifier_list pointer { ($1)->tok = DEREF; $$ = op( $1, 0, 1, ej($3) ); // $$ = op( $1, 0, 2, ej($2), ej($3) );
		$$->type = $3->type;
		Ptr *p = (Ptr *) ($$->type);
		Base *b2 = (Base *) ($2->type);
		p->ptrs.insert(p->ptrs.begin(), _qual_t(b2->isConst, b2->isVoltl));
		p->isErr |= b2->isErr;
	}
	;

type_qualifier_list
	: type_qualifier						{ $$ = op( nd(TYPE_QUAL_LIST, "type-quals", { 0, 0 }), 0, 1, ej($1) );
		Base *b = new Base();
		switch ($1->tok) { case CONST : b->isConst = true; break; case VOLATILE : b->isVoltl = true; }
		$$->type = b;
	}
	| type_qualifier_list type_qualifier	{ $$ = op( $1, 0, 1, ej($2) );
		Base *b = (Base *) $$->type;
		switch ($2->tok) {
			case    CONST : if (b->isConst) repErr($2->pos, "warning: const specified twice",    _FORE_MAGENTA_); b->isConst = true; break;
			case VOLATILE : if (b->isVoltl) repErr($2->pos, "warning: volatile specified twice", _FORE_MAGENTA_); b->isVoltl = true;
		}
	}
	;

parameter_type_list
	: parameter_list				{ $$ = $1; }
	| parameter_list ',' ELLIPSIS	{ $$ = op( $1, 0, 1, ej($3) );
		$3->type = new Base(ELLIPSIS_B);
	}
	;

parameter_list
	: parameter_declaration						{ $$ = op( nd(PARAM_TYPE_LIST, "param-types", { 0, 0 }), 0, 1, ej($1) ); }
	| parameter_list ',' parameter_declaration	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

parameter_declaration
	: declaration_specifiers declarator            { $$ = op( nd(PARAM_DECL, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) ); }
	| declaration_specifiers abstract_declarator   { $$ = op( nd(PARAM_DECL, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) ); }
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
	| pointer direct_abstract_declarator   { $$ = op( nd(ABSTRACT_DECLARATOR, "abst-decl", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t2 = $2->type, *tt = tail(t2);
		if (!t2) $$->type = $1->type;
		else {
			Ptr *dst = (Ptr*)tt, *src = (Ptr*)($1->type); int l = src->ptrs.size();
			switch (tt->grp()) {
				case  PTR_G : // merge src->ptrs into dst->ptrs from left
					for (int i = 0; i < l; i++) dst->ptrs.insert(dst->ptrs.begin(), src->ptrs[l-i-1]);
					break;
				case  ARR_G : ((Arr *) tt)->item = $1->type; break;
				case FUNC_G : ((Func *)tt)->retType = $1->type; break;
			}
			$$->type = t2; t2->isErr |= $1->type->isErr;
		}
	}
	;

// not handled array bound "constant_expression" type
direct_abstract_declarator
	: '(' abstract_declarator ')'                                { $$ = $2; brackPut = true; }
	| '[' ']'                                                    { $$ = $1; $$->type = new Arr(NULL, NULL); /* neither item nor bound is known */ }
	| '[' constant_expression ']'                                { $$ = op( $1, 0, 1, ej($2)); $$->type = new Arr(NULL, $2); /* item unknown */ }
	| direct_abstract_declarator '[' ']'                         { loc_t bra = $2->pos; $$ = op( $2, 0, 1, ej($1) );
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL);
		else if (last(t1, ARR_G)) {
			repErr(bra, "incomplete array bound: all bounds except first must be specified", _FORE_RED_);
			$$->type = t1; t1->isErr = true;
		} else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		brackPut = false;
	}
	| direct_abstract_declarator '[' constant_expression ']'     { loc_t bra = $2->pos; $$ = op( $2, 0, 2, ej($1), ej($3) );
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL, $3); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL, $3);
		else {
			Arr *a = (Arr *) last(t1, ARR_G);
			if (a) { a->newDim($3); $$->type = t1; }
			else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		}
		brackPut = false;
	}
	| '(' ')'                                                    { $1->tok = ABST_DCLN; $1->label = "() abst-dcln"; $$ = $1;
		$$->type = new Func(NULL); // function of unknown return type
	}
	| '(' parameter_type_list ')'                                { $1->tok = ABST_DCLN; $1->label = "() abst-dcln"; $$ = op( $1, 0, 1, ej($2) );
		int l = $2->numChild; bool pureVoid = false, argErr = false; vector<class Type *> v;
		for (int i = 0; i < l; i++) {
			node_t *ch = $2->ch(i); Type *cht = ch->type; v.push_back(cht);
			if ( cht && (cht->grp() == BASE_G) && (((Base*)cht)->base == VOID_B) ) { // i-th arg is "void"
				if (i == 0) { pureVoid = true; continue; }
				repErr(ch->pos, "\"void\" must be the only argument", _FORE_RED_); argErr = true;
			}
		}

		Func *f = new Func(NULL); $$->type = f; f->isErr = argErr;
		if (!pureVoid) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
	}
	| direct_abstract_declarator '(' ')' { loc_t bra = $2->pos; $2->tok = ABST_DCLN; $2->label = "() abst-dcln"; $$ = op( $2, 0, 1, ej($1) );
		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr*)tt)->pt = new Func(NULL); $$->type = t1; }
		else if (!t1) $$->type = new Func(NULL);
		else if (last(t1, ARR_G)) {
			repErr(bra, "array of functions", _FORE_RED_); $$->type = t1; t1->isErr = true;
		} else {
			repErr(bra, "function returns a function", _FORE_RED_); $$->type = t1; t1->isErr = true;
		}
		brackPut = false;
	}
	| direct_abstract_declarator '(' parameter_type_list ')' { loc_t bra = $2->pos; $2->tok = ABST_DCLN; $2->label = "() abst-dcln"; $$ = op( $2, 0, 2, ej($1), ej($3) );
		int l = $3->numChild; bool pureVoid = false, argErr = false; vector<class Type *> v;
		for (int i = 0; i < l; i++) {
			node_t *ch = $3->ch(i); Type *cht = ch->type; v.push_back(cht);
			if ( cht && (cht->grp() == BASE_G) && (((Base*)cht)->base == VOID_B) ) { // i-th arg is "void"
				if (i == 0) { pureVoid = true; continue; }
				repErr(ch->pos, "\"void\" must be the only argument", _FORE_RED_); argErr = true;
			}
		}

		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) {
			Func* f = new Func(NULL); ((Ptr*)tt)->pt = f;
			$$->type = t1; t1->isErr |= argErr;
			if (! (t1->isErr || pureVoid) ) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (!t1) {
			Func *f = new Func(NULL); $$->type = f; f->isErr = argErr;
			if (! ( f->isErr || pureVoid) ) for (int i = 0; i < l; i++) f->params.push_back(clone(v[i]));
		} else if (last(t1, ARR_G)) {
			repErr(bra, "array of functions", _FORE_RED_); $$->type = t1; t1->isErr = true;
		} else {
			repErr(bra, "function returns a function", _FORE_RED_); $$->type = t1; t1->isErr = true;
		}
		brackPut = false;
	}
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
