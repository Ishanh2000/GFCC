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
#include <ops.h>
#include <ircodes.h>

using namespace std;

%}

%union { // Add more if required (but carefully, as type conversions may be required).
	struct _node_t *node;
	unsigned int nxtIstr;
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

// new (copied) introductions
/* %type <node> declarator */
/* New markers */
 /* for if, if-else */
%type <node> M1
/* for for loops */
%type <node> M2
/* for switch case */
%type <node> M3
/* get  next instr line no. */
%type <nxtIstr> M

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
		if (ret) {
			if (ret->type) $$->type = clone(ret->type); // success - start by making a copy of type.
			else { $$->type = new Type(); $$->type->isErr = true; }
		} else {
			repErr($1->pos, "variable undeclared in this scope", _FORE_RED_);
			Type* t = $$->type = new Type(); t->isErr = true;
		}
		if(!$$->type->isErr){
			$$->eval = $$->label; // TODO
			
		}
		$$->type->lvalue = true;
	}
	| CONSTANT { $$ = $1;
		// if this is a char, convert to a number, pass that number in $$->eval
		Type *t = $$->type;
		if (t && t->grp() == BASE_G && (((Base*)t)->base == CHAR_B)) { // char
			$$->eval = char2num($$->label);
		} else $$->eval = $$->label; // number(int/real)
	}
	// get sematic number (means 0x56 = 86, 0227 = 151, etc) during semantic analysis - but ENCODE HERE ITSELF
	| STRING_LITERAL		{ $$ = $1;
		$$->eval = "0s_" + to_string(StrDump.size());
		StrDump.push_back(str_t($$->label));
	} // encode as (const char *) - or some other appropriate enc.
	| '(' expression ')'	{ $$ = $2; }
	;

// todo
postfix_expression
	: primary_expression									{ $$ = $1; } // do nothing
	| postfix_expression '[' expression ']'					{ $$ = op( $2, 0, 2, ej($1), ej($3) );
		Type *t1 = $1->type, *t2 = $3->type; // assume both not NULL
		if (t1->isErr) { repErr($1->pos, "using \"error_type\"", _FORE_RED_); $$->type = t1; }
		if (t2->isErr) { repErr($3->pos, "using \"error_type\"", _FORE_RED_); $$->type = t2; }
		if (!(t1->isErr || t2->isErr)) {
			grp_t g1 = t1->grp(), g2 = t2->grp();
			if (g1 != ARR_G && g1 != PTR_G) { repErr($3->pos, "subscript operator not used on pointer or array", _FORE_RED_); t1->isErr = true; }
			else if (g1 == ARR_G) {
				Arr *a1 = (Arr *) t1;
				int *bound = eval(a1->dims[0]), *query = eval($3);
				if (bound && query) {
					if ((*query < 0) || (*query >= *bound)) repErr($3->pos, "warning: array index not within bound", _FORE_MAGENTA_);
				}
				a1->dims.erase(a1->dims.begin());
				if (a1->dims.size() == 0) { t1 = a1->item; }
			} else {
				Ptr *p1 = (Ptr *) t1; p1->ptrs.pop_back();
				if (p1->ptrs.size() == 0) { t1 = p1->pt; }
			}
			Base *b2 = (Base *) t2;
			if (!(
				(g2 == BASE_G) &&
				(b2->base == CHAR_B || b2->base == INT_B || b2->base == LONG_B || b2->base == LONG_LONG_B || b2->base == ENUM_B)
			)) { repErr($3->pos, "array index not compatible to integer type", _FORE_RED_); t1->isErr = true; }
			$$->type = t1;
		}
		$$->type->lvalue = true;

		$$->eval = $1->eval + "[" + $3->eval + "]"; // handle at assembly code generation
	}
	| postfix_expression '(' ')' {
		$2->tok = FUNC_CALL; $2->label = "() [func-call]"; $2->attr = func_call_attr; $$ = op( $2, 0, 1, ej($1) );
		Type *t = $1->type;
		if (t->isErr) { $$->type = new Base(INT_B); $$->type->isErr = true; }
		else {
 			grp_t g = t->grp();	Func *f = NULL;
			if (g == FUNC_G) f = (Func *)t;
			else if ((g == PTR_G) && (((Ptr*)t)->pt->grp() == FUNC_G)) f = (Func *)(((Ptr*)t)->pt);
			else {
				repErr($1->pos, "called expression is not a function or a function-pointer", _FORE_RED_);
				$$->type = new Base(INT_B); $$->type->isErr = true;
			}

			if (f) {
				if (f->params.size()) {
					Type *_last = f->params.back(); // not NULL (assume)
					if ((_last->grp() == BASE_G) && (((Base *)_last)->base == ELLIPSIS_B))
						repErr($2->pos, string("expected at least ") + to_string(f->params.size() - 1) + " argument(s); specified none", _FORE_RED_);
					else repErr($2->pos, string("expected ") + to_string(f->params.size()) + " argument(s); specified none", _FORE_RED_);
					$$->type = new Base(INT_B); $$->type->isErr = true;
				} else $$->type = clone(f->retType);
			}
		}
		$$->type->lvalue = false;
		if (!$$->type->isErr) { // param h | call main, 1 | r = retval
			emit(eps, "call", $1->eval, "0"); // call <func / func_ptr>, 0
			Type* _t = $$->type;
			if ((!_t) || (_t->grp() != BASE_G) || (((Base*)_t)->base != VOID_B)) {
				emit($$->eval = newTmp(clone(_t)), eps, "$retval"); // call <func / func_ptr>, 0
			}
		}
	}
	| postfix_expression '(' argument_expression_list ')' {
		$2->tok = FUNC_CALL; $2->label = "() [func-call]"; $2->attr = func_call_attr; $$ = op( $2, 0, 2, ej($1), ej($3) );
		int numArg = $3->numChild;

		Type *t = $1->type;
		if (t->isErr) { $$->type = new Base(INT_B); $$->type->isErr = true; }
		else {
 			grp_t g = t->grp();	Func *f = NULL;
			if (g == FUNC_G) f = (Func *)t;
			else if ((g == PTR_G) && (((Ptr*)t)->pt->grp() == FUNC_G)) f = (Func *)(((Ptr*)t)->pt);
			else {
				repErr($1->pos, "called expression is not a function or a function-pointer", _FORE_RED_);
				$$->type = new Base(INT_B); $$->type->isErr = true;
			}

			if (f) {
				if (f->params.size() == 0) {
					repErr($3->pos, string("expected no argument; specified ") + to_string(numArg) + " argument(s)", _FORE_RED_);
					$$->type = new Base(INT_B); $$->type->isErr = true;
				} else {
					Type *_last = f->params.back();
					if ((_last->grp() == BASE_G) && (((Base *)_last)->base == ELLIPSIS_B)) { // ellipsis call
						int least = f->params.size() - 1; // assured least > 0
						if (numArg < least) {
							repErr($3->pos, string("expected at least ") + to_string(least) + " argument(s); specified " + to_string(numArg) + " argument(s)", _FORE_RED_);
							$$->type = new Base(INT_B); $$->type->isErr = true;
						} else {
							bool _good = true;
							for (int i = 0; i < least; i++) {
								Type *proto = f->params[i], *given = $3->ch(i)->type;
								if (!impCast(given, proto)) { // check given against proto
									repErr($3->ch(i)->pos, string("expected argument of type \"") + str(proto) + "\", but got type \"" + str(given) + "\"", _FORE_RED_);
									_good = false;
								}
							}
							if (_good) $$->type = clone(f->retType);
							else { $$->type = new Base(INT_B); $$->type->isErr = true; }
						}
					} else { // not an ellipsis call
						int numProto = f->params.size();
						if (numProto != numArg) {
							repErr($3->pos, string("expected ") + to_string(numProto) + " argument(s); specified " + to_string(numArg) + " argument(s)", _FORE_RED_);
							$$->type = new Base(INT_B); $$->type->isErr = true;
						} else {
							bool _good = true;
							for (int i = 0; i < numProto; i++) {
								Type *proto = f->params[i], *given = $3->ch(i)->type;
								if (!impCast(given, proto)) { // check given against proto
									repErr($3->ch(i)->pos, string("expected argument of type \"") + str(proto) + "\", but got type \"" + str(given) + "\"", _FORE_RED_);
									_good = false;
								}
							}
							if (_good) $$->type = clone(f->retType);
							else { $$->type = new Base(INT_B); $$->type->isErr = true; }
						}
					}
				}
			}
		}
		if (!($$->type)) { $$->type = new Base(INT_B); $$->type->isErr = true; } // just a precaution
		$$->type->lvalue = false;

		if (!$$->type->isErr) { // param h | call main, 1 | r = retval
			int l = $3->numChild;
			for (int i = 0; i < l; i++) {
				node_t *ch = $3->ch(i); if (ch) emit(eps, "param", ch->eval); // param <ch->eval>
			}
			emit(eps, "call", $1->eval, to_string(l)); // call <func / func_ptr>, l
			Type *_t = $$->type;
			if ((!_t) || (_t->grp() != BASE_G) || (((Base*)_t)->base != VOID_B)) {
				emit($$->eval = newTmp(clone(_t)), eps, "$retval"); // call <func / func_ptr>, 0
			}
		}
	}
	| postfix_expression '.' IDENTIFIER						{ $$ = op( $2, 0, 2, ej($1), ej($3) ); // search for definition by name of "struct|union _abc"
		Type *t1 = $1->type;
		if (t1->isErr) { $$->type = t1; }
		else if (!( (t1->grp() == BASE_G) &&  (   ((Base *)t1)->base == STRUCT_B || ((Base *)t1)->base == UNION_B   ))) {
			repErr($1->pos, "left operand for member access is not a struct or a union", _FORE_RED_); t1->isErr = true;
			$$->type = t1;
		} else { // try finding latest definition for the above struct
			// must get name of struct now
			Base *b = (Base *)t1;
			string srch = string((b->base == STRUCT_B) ? "struct " : "union ") + b->subDef->name;
			/* try finding latest definition for the above struct */
			if (!( b->subDef && b->subDef->syms.size() )) {
				repErr($1->pos, srch + " has not yet been defined", _FORE_RED_);
				t1->isErr = true; $$->type = t1;
			} else {
				sym *member = b->subDef->srchSym($3->label);
				if (!member) {
					repErr($3->pos, string("no member named \"") + $3->label + "\" in " + srch, _FORE_RED_); t1->isErr = true;
					$$->type = t1;
				} else $$->type = clone(member->type);
			}
		}
		$$->type->lvalue = true;

		$$->eval = $1->eval + "." + $3->label; // handle at assembly code generation
	}
	| postfix_expression PTR_OP IDENTIFIER					{ $$ = op( $2, 0, 2, ej($1), ej($3) ); // search for definition by name of "struct|union _abc"
		Type *t1 = $1->type;
		if (t1->isErr) { $$->type = t1; }
		else if (!( (t1->grp() == PTR_G) && (((Ptr *)t1)->pt->grp() == BASE_G) && (   ((Base *)(((Ptr *)t1)->pt))->base == STRUCT_B || ((Base *)(((Ptr *)t1)->pt))->base == UNION_B   ))) {
			repErr($1->pos, "left operand for member access is not a pointer to a struct or a union", _FORE_RED_); t1->isErr = true;
			$$->type = t1;
		} else { // try finding latest definition for the above struct
			// must get name of struct now
			Base *b = (Base *)(((Ptr *)t1)->pt);
			string srch = string((b->base == STRUCT_B) ? "struct " : "union ") + b->subDef->name;
			/* try finding latest definition for the above struct */
			if (!( b->subDef && b->subDef->syms.size() )) {
				repErr($1->pos, srch + " has not yet been defined", _FORE_RED_);
				t1->isErr = true; $$->type = t1;
			} else {
				sym *member = b->subDef->srchSym($3->label);
				if (!member) {
					repErr($3->pos, string("no member named \"") + $3->label + "\" in " + srch, _FORE_RED_); t1->isErr = true;
					$$->type = t1;
				} else $$->type = clone(member->type);
			}
		}
		$$->type->lvalue = true;
		$$->eval = $1->eval + "->" + $3->label; // handle at assembly code generation
	}
	| postfix_expression INC_OP								{ $$ = op( $2, 0, 1, ej($1) ); // not allowed on function, array, void, struct, union
		Type *t = $1->type; grp_t g = t->grp();
		if (g == FUNC_G) { repErr($2->pos, "unary increment operator used on a function", _FORE_RED_); t->isErr = true; }
		if (g == ARR_G) { repErr($2->pos, "unary increment operator used on an array", _FORE_RED_); t->isErr = true; }
		if (g == BASE_G) {
			base_t bs = ((Base *) t)->base;
			if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
				repErr($2->pos, "unary increment operator used on pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
			}
			if (((Base *)t)->isConst) {
				repErr($1->pos, "cannot use increment / decrement of a \"const\" value", _FORE_RED_); t->isErr = true;
			}
		}

		$$->eval = newTmp(clone(t));
		emit($$->eval, eps, $1->eval);
		if(g == BASE_G){
			base_t bs = ((Base *) t)->base;
			if(priority1[bs] >= priority1[FLOAT_B]){
				emit($1->eval, "real+", $1->eval, "1");
			}
			else emit($1->eval, "+", $1->eval, "1");
		}
		/* #########TODO for Pointer###########*/
		else emit($1->eval, "+", $1->eval, "1");


		$$->type = t;
		$$->type->lvalue = false;
	}
	| postfix_expression DEC_OP								{ $$ = op( $2, 0, 1, ej($1) ); // not allowed on function, array, void, struct, union
		Type *t = $1->type; grp_t g = t->grp();
		if (g == FUNC_G) { repErr($2->pos, "unary increment operator used on a function", _FORE_RED_); t->isErr = true; }
		if (g == ARR_G) { repErr($2->pos, "unary increment operator used on an array", _FORE_RED_); t->isErr = true; }
		if (g == BASE_G) {
			base_t bs = ((Base *) t)->base;
			if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
				repErr($2->pos, "unary increment operator used on pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
			}
			if (((Base *)t)->isConst) {
				repErr($1->pos, "cannot use increment / decrement of a \"const\" value", _FORE_RED_); t->isErr = true;
			}
		}

		$$->eval = newTmp(clone(t));
		emit($$->eval, eps, $1->eval);
		if(g == BASE_G){
			base_t bs = ((Base *) t)->base;
			if(priority1[bs] >= priority1[FLOAT_B]){
				emit($1->eval, "real-", $1->eval, "1");
			}
			else emit($1->eval, "-", $1->eval, "1");
		}
		/* #########TODO for Pointer###########*/
		else emit($1->eval, "-", $1->eval, "1");
		
		$$->type = t;
		$$->type->lvalue = false;
	}
	;

argument_expression_list
	: assignment_expression									{ $$ = op( nd(ARG_EXPR_LIST, "arg-expr-list", { 0, 0 }), 0, 1, ej($1) ); }
	| argument_expression_list ',' assignment_expression	{ $$ = op( $1, 0, 1, ej($3) ); }
	;

unary_expression
	: postfix_expression				{ $$ = $1; }
	| INC_OP unary_expression			{ $$ = op( $1, 0, 1, ej($2) ); // not allowed on function, array, void, struct, union
		Type *t = $2->type; grp_t g = t->grp();
		if (g == FUNC_G) { repErr($2->pos, "unary increment operator used on a function", _FORE_RED_); t->isErr = true; }
		if (g == ARR_G) { repErr($2->pos, "unary increment operator used on an array", _FORE_RED_); t->isErr = true; }
		if (g == BASE_G) {
			base_t bs = ((Base *) t)->base;
			if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
				repErr($2->pos, "unary increment operator used on pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
			}
			if (((Base *)t)->isConst) {
				repErr($1->pos, "cannot use increment / decrement of a \"const\" value", _FORE_RED_); t->isErr = true;
			}
		}

		$$->eval = newTmp(clone(t));
		if(g == BASE_G){
			base_t bs = ((Base *) t)->base;
			if(priority1[bs] >= priority1[FLOAT_B]){
				emit($2->eval, "real+", $2->eval, "1");
			}
			else emit($2->eval, "+", $2->eval, "1");
		}
		/* #########TODO for Pointer###########*/
		else emit($2->eval, "+", $2->eval, "1");
		emit($$->eval, eps, $2->eval);

		$$->type = t;
		$$->type->lvalue = false;
	}
	| DEC_OP unary_expression			{ $$ = op( $1, 0, 1, ej($2) ); // not allowed on function, array, void, struct, union
		Type *t = $2->type; grp_t g = t->grp();
		if (g == FUNC_G) { repErr($2->pos, "unary increment operator used on a function", _FORE_RED_); t->isErr = true; }
		if (g == ARR_G) { repErr($2->pos, "unary increment operator used on an array", _FORE_RED_); t->isErr = true; }
		if (g == BASE_G) {
			base_t bs = ((Base *) t)->base;
			if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
				repErr($2->pos, "unary increment operator used on pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
			}
			if (((Base *)t)->isConst) {
				repErr($1->pos, "cannot use increment / decrement of a \"const\" value", _FORE_RED_); t->isErr = true;
			}
		}

		$$->eval = newTmp(clone(t));
		if(g == BASE_G){
			base_t bs = ((Base *) t)->base;
			if(priority1[bs] >= priority1[FLOAT_B]){
				emit($2->eval, "real-", $2->eval, "1");
			}
			else emit($2->eval, "-", $2->eval, "1");
		}
		/* #########TODO for Pointer###########*/
		else emit($2->eval, "-", $2->eval, "1");
		emit($$->eval, eps, $2->eval);

		$$->type = t;
		$$->type->lvalue = false;
	}
	| unary_operator cast_expression	{ $$ = op( $1, 0, 1, ej($2) );
		Type *t = $2->type; grp_t g = t->grp(); base_t bs; bool tilda_good = false;
		Arr *a; Ptr *p;
		if (t->isErr) { $$->type = t; }
		else switch ($1->tok) {
			case '+' : case '-' :
				if (g != BASE_G) {
					repErr($1->pos, "unary plus/minus used with function, array or pointer", _FORE_RED_); t->isErr = true;
				} else {
					bs = ((Base *)t)->base;
					if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
						repErr($1->pos, "unary plus/minus used with pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
					}
				}
				$$->type = t; $$->type->lvalue = false;
				if ($1->tok == '+') $$->eval = $2->eval;
				else if ($2->tok == CONSTANT) $$->eval = "-" + $2->eval;
				else emit($$->eval = newTmp(clone(t)), "-", $2->eval); // t_1 = - t_0
				break;
			
			case '!' :
				if (g == BASE_G) {
					bs = ((Base *)t)->base;
					if ((bs == VOID_B) || (bs == STRUCT_B) || (bs == UNION_B)) {
						repErr($1->pos, "unary exclamation mark used with pure \"void\" type, a struct or a union", _FORE_RED_); t->isErr = true;
					}
				}
				$$->type = t; $$->type->lvalue = false;
				emit($$->eval = newTmp(clone(t)), "!", $2->eval); // t_1 = ! t_0
				break;
			
			case '~': // bitwise NOT
				if (g == BASE_G) {
					bs = ((Base *)t)->base;
					if ((bs == CHAR_B) || (bs == INT_B) || (bs == LONG_B) || (bs == LONG_LONG_B) || (bs == ENUM_B)) tilda_good = true;
				}
				if (!tilda_good) { repErr($1->pos, "bitwise NOT operator (~) used with incompatible type", _FORE_RED_); t->isErr = true; }
				$$->type = t; $$->type->lvalue = false;
				emit($$->eval = newTmp(clone(t)), "~", $2->eval); // t_1 = ~ t_0
				break;

			case '*' : // only if array, pointer or function
				switch (g) {
					case ARR_G :
						a = (Arr *) t;
						if (a->dims.size() > 1) { a->dims.erase(a->dims.begin()); $$->type = a; }
                		else if (a->dims.size() == 1) $$->type = a->item;
						break;

					case PTR_G :
						p = (Ptr *) t;
						if (p->ptrs.size() > 1) { p->ptrs.pop_back(); $$->type = p; }
						else if (p->ptrs.size() == 1) { $$->type = p->pt; }
						break;

					case FUNC_G : // buggy implementation
						$$->type = t;
						break;

					default : 
						repErr($1->pos, "cannot dereference a value that is not an array, a pointer or a function", _FORE_RED_); t->isErr = true; $$->type = t;
				}
				$$->type->lvalue = true;
				emit($$->eval = newTmp(clone($$->type)), "*", $2->eval); // t_1 = * t_0
				break;

			case '&' :
				if (!(t->lvalue)) {
					repErr($1->pos, "cannot use address-of operator on an rvalue", _FORE_RED_); t->isErr = true; $$->type = t;
				} else if (t->grp() == PTR_G) {
					((Ptr *)t)->newPtr(true, false); // const pointer inserted
					$$->type = t;
				}
				else $$->type = new Ptr(t);
				$$->type->lvalue = false;
				emit($$->eval = newTmp(clone($$->type)), "&", $2->eval); // t_1 = & t_0
		}
	}
	| SIZEOF unary_expression			{ $$ = op( $1, 0, 1, ej($2) );
		$$->eval = to_string(getSize($2->type));
		Base *b = new Base(LONG_B); b->sign = UNSIGNED_X;
		b->isErr |= $2->type->isErr;
		$$->type = b;
		$$->type->lvalue = false;
	}
	| SIZEOF '(' type_name ')'			{ $$ = op( $1, 0, 1, ej($3) );
		$$->eval = to_string(getSize($3->type));
		Base *b = new Base(LONG_B); b->sign = UNSIGNED_X;
		b->isErr |= $3->type->isErr;
		$$->type = b;
		$$->type->lvalue = false;
	}
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
	| '(' type_name ')' cast_expression { $$ = op( nd(CAST_EXPR, "cast_expression", { 0, 0 }), 0, 2, Ej($2, "type", NULL), Ej($4, "expression", NULL) );
		Type *t1 = $2->type, *t2 = $4->type; // assume both not NULL
		t2->isErr |= t1->isErr;
		if (t2->grp() == BASE_G) {
			base_t bs = ((Base*)t2)->base;
			if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) {
				repErr($4->pos, "cannot cast from a pure \"void\", a struct or a union", _FORE_RED_); t1->isErr = true;
			}
		}
		if (!expCast(t2, t1)) {
			repErr($2->pos, string("could not type cast from \"") + str(t2) + "\" to \"" + str(t1) + "\"", _FORE_RED_); t1->isErr = true;
		}
		$$->type = t1;
		$$->type->lvalue = false;
	}
	;

multiplicative_expression
	: cast_expression { $$ = $1; }
	| multiplicative_expression '*' cast_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) );
		handle($$,$1,$3,'*', "*");
	 }
	| multiplicative_expression '/' cast_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'/', "/");
	}
	| multiplicative_expression '%' cast_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'%', "%");
	 }
	;

additive_expression
	: multiplicative_expression { $$ = $1; }
	| additive_expression '+' multiplicative_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3));
		handle($$,$1,$3,'+', "+");
	}
	| additive_expression '-' multiplicative_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) );
		handle($$,$1,$3,'-', "-");
	}
	;

shift_expression
	: additive_expression { $$ = $1; }
	| shift_expression LEFT_OP additive_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) );
		handle($$,$1,$3,'a', "<<");
		/* $$->type = bin('a', $1, $3);
		$$->type->lvalue = false; */
	}
	| shift_expression RIGHT_OP additive_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'b', ">>");
	}
	;

relational_expression
	: shift_expression { $$ = $1; }
	| relational_expression '<' shift_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'<', "<");
	 }
	| relational_expression '>' shift_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'>', ">");
		}
	| relational_expression LE_OP shift_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) );
		handle($$,$1,$3,'<', "<=");
		}
	| relational_expression GE_OP shift_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'>', ">=");
		}
	;

equality_expression
	: relational_expression { $$ = $1; }
	| equality_expression EQ_OP relational_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'>', "==");
		}
	| equality_expression NE_OP relational_expression	{ 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'>', "!=");
		}
	;

and_expression
	: equality_expression { $$ = $1; }
	| and_expression '&' equality_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) );
		handle($$,$1,$3,'&', "&");
	}
	;

exclusive_or_expression
	: and_expression { $$ = $1; }
	| exclusive_or_expression '^' and_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'^', "^");
		}
	;

inclusive_or_expression
	: exclusive_or_expression { $$ = $1; }
	| inclusive_or_expression '|' exclusive_or_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3,'|', "|");
		}
	;

logical_and_expression
	: inclusive_or_expression { $$ = $1; }
	| logical_and_expression AND_OP inclusive_or_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3, AND_OP, "&&");
		}
	;

logical_or_expression
	: logical_and_expression { $$ = $1; }
	| logical_or_expression OR_OP logical_and_expression { 
		$$ = op( $2, 0, 2, ej($1), ej($3) ); 
		handle($$,$1,$3, OR_OP, "||");
		}
	;

// TODO
conditional_expression
	: logical_or_expression { $$ = $1; }
	| logical_or_expression '?' expression ':' conditional_expression { $$ = op( $2, 0, 3,
		Ej($1, "condition", NULL), Ej($3, "expr (if TRUE)", NULL), Ej($5, "expr (if FALSE)", NULL)
	); }
	;

// todo
assignment_expression
	: conditional_expression { $$ = $1; }
	| unary_expression assignment_operator assignment_expression { $$ = op( $2, 0, 2, ej($1), ej($3) );
		Type *t1 = $1->type, *t2 = $3->type;
		bool r1 = isReal(t1), r2 = isReal(t2);
		string e1 = $1->eval, e2 = $3->eval;
		t1->isErr |= t2->isErr;
		Type *tr;
		string stdErs = "incompatible operand types under assigment operator";
		if (t1->lvalue) {
			Base *b = (Base*)t1; Ptr *p = (Ptr*)t1; Arr *a; grp_t g = t1->grp();
			bool isConst = ((g == BASE_G) && (b->isConst)) || ((g == PTR_G) && (p->ptrs.back().isConst));
			if (isConst) {
				repErr($1->pos, "cannot assign to a \"const\" value", _FORE_RED_); t1->isErr = true;

			} else switch ($2->tok) {
				case '=' :
					tr = t2;
					if (!impCast(t2, t1)) { repErr($2->pos, stdErs, _FORE_RED_); t1->isErr = true; }
					break;
				
				case MUL_ASSIGN : case DIV_ASSIGN :
					tr = handle_as('*',$1,$3,e1,e2,r1,r2);
					if (!impCast(tr, t1)) { repErr($2->pos, stdErs, _FORE_RED_); t1->isErr = true; }
					break;

				case MOD_ASSIGN :
					tr = handle_as('%',$1,$3,e1,e2,r1,r2);
					if (!impCast(tr, t1)) { repErr($2->pos, stdErs, _FORE_RED_); t1->isErr = true; }
					break;

				case ADD_ASSIGN : case SUB_ASSIGN :
					tr = handle_as('+',$1,$3,e1,e2,r1,r2);
					if (!impCast(tr, t1)) { repErr($2->pos, stdErs, _FORE_RED_); t1->isErr = true; }
					break;

				case LEFT_ASSIGN : case RIGHT_ASSIGN : case AND_ASSIGN : case XOR_ASSIGN : case OR_ASSIGN :
					if (!impCast(bin('&', $1, $3), t1)) { repErr($2->pos, stdErs, _FORE_RED_); t1->isErr = true; }
					break;
			}
		} else { repErr($1->pos, "left operand for '=' is not an lvalue", _FORE_RED_); t1->isErr = true; }
		$$->type = t1;

		if(tr && !tr->isErr) { // TODO remove tr check
			string opr;
			if(tr->grp() == BASE_G) {
				Base* b = (Base*) tr;
				if(priority1[b->base] >= priority1[FLOAT_B] ) {
					opr = "real";
				}
			}
			switch($2->tok) {
				case '=' : opr = "="; break;
				case MUL_ASSIGN : opr += "*"; break;
				case DIV_ASSIGN : opr += "/"; break;
				case MOD_ASSIGN : opr += "%"; break;
				case ADD_ASSIGN : opr += "+"; break;
				case SUB_ASSIGN : opr += "-"; break;
				case LEFT_ASSIGN : opr = "<<"; break;
				case RIGHT_ASSIGN : opr = ">>"; break;
				case AND_ASSIGN : opr = "&"; break;
				case XOR_ASSIGN : opr = "^"; break;
				case OR_ASSIGN : opr = "|"; break;
			}
			
			bool cast_flag = false;
			if(isReal(tr) != isReal(t1)) {
				cast_flag = true;
			}
			
			if(opr == "="){
				opr = eps;
				if(cast_flag) {
					if(isReal(t1)) opr = "int2real";
					else opr = "real2int";
				}
				emit($1->eval, opr, e2);
			}
			else{
				if(cast_flag) {
					string tmp = newTmp(clone(t1));
					emit(tmp, opr, e1, e2);
					emit($1->eval, isReal(t1) ? "int2real" : "real2int", tmp, eps);
				}
				else emit($1->eval, opr, e1, e2);
			}
			
			$$->eval = e1;
		}
	}
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

// Here, comma is an operator, and is not treated like a list delimiter (aka 'separator')
expression
	: assignment_expression { $$ = $1; }
	| expression ',' assignment_expression { $$ = op( $2, 0, 2, ej($1), ej($3) ); $$->type = $3->type; } // comma returns first operand's type;
	;

constant_expression
	: conditional_expression { $$ = $1; }
	;

/************************************************************************************************/
/************************************* EXPRESSIONS COMPLETE *************************************/
/************************************** DECLARATIONS BEGIN **************************************/
/************************************************************************************************/

// possible to declare a function / function pointer twice - default extern.
// possible to declare variable twice - under "extern" keyword.

// useless iff NULL
declaration
	: declaration_specifiers ';' { $$ = NULL; } // do nothing as decl_specs aleardy vallidated
	| declaration_specifiers init_declarator_list ';' { // start declaring / defining
		edge_t **ch2 = $2->edges;
		int l1 = $1->numChild, l2 = $2->numChild, useful = 0;
		Type *t1 = $1->type;

		// single pass over variables
		for (int i = 0; i < l2; i++) { // first check that there is no var in scope
			node_t *cnode = $2->ch(i); // "concerned node" - get directly
			Type *t2 = cnode->type; node_t *initNode = NULL; loc_t eqPos;

			// pass down tree $2 until name & position found.
			if (cnode->tok == '=') {
				initNode = cnode->ch(1); eqPos = cnode->pos; cnode = cnode->ch(0); useful++;
				if (t1->strg == EXTERN_S) repErr($1->pos, "initialized after using \"extern\"", _FORE_RED_);
			} // "init_declarator"
			while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0); // rules of "direct_decl"
			
			sym* retval = SymRoot->lookup(cnode->label);
			if (!retval) {
				Type *tt = tail(t2); // [tt == NULL] iff [t2 == NULL]
				// good to go - check if void for non-function, non-pointer
				if ((t1->grp() == BASE_G) && (((Base*)t1)->base == VOID_B)) { // t2's tail must not be array or NULL
					if (!t2) { repErr(cnode->pos, "pure \"void\" type given", _FORE_RED_); t1->isErr = true; } // void x;
					else if (tt->grp() == ARR_G) { repErr(cnode->pos, "array of \"voids\" given", _FORE_RED_); t2->isErr = true; } // void x[];
				}
				if (t2 && t2->grp() == ARR_G && (((Arr *)t2)->dims[0] == NULL)) { // get the dimension using initNode
					if (initNode) {
						if (initNode->tok == INIT_LIST) {
							node_t* n = nd(CONSTANT, to_string(initNode->numChild).c_str(), initNode->pos);
							Base *b = new Base(INT_B); b->isConst = true; n->type = b;
							((Arr *) t2)->dims[0] = n;
						} else if (initNode->tok == STRING_LITERAL) {
							initNode = str2arr(initNode); // initNode is now an array (INIT_LIST)
							node_t* n = nd(CONSTANT, to_string(initNode->numChild).c_str(), initNode->pos);
							Base *b = new Base(INT_B); b->isConst = true; n->type = b;
							((Arr *) t2)->dims[0] = n;
						}
					}
				}
				Type *ut = unify(t1, t2); grp_t g = ut->grp();
				if ( (g == FUNC_G) || ( (g == PTR_G) && ((Ptr *)ut)->pt && (((Ptr *)ut)->pt->grp() == FUNC_G) ) )
				ut->strg = EXTERN_S; // if a function (or a pointer to a function) strg is EXTERN_S
				if (!checkArrDims(ut)) { // go over t2 recursively and check that all array bounds must be present
					repErr(cnode->pos, "array bounds incomplete", _FORE_RED_); ut->isErr = true;
				}
				if (t1->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
					Base *_b = (Base *) t1;
					if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
						if (!tt || (tt->grp() != PTR_G)) {
							repErr(cnode->pos, "struct / union not yet defined", _FORE_RED_); continue; // should we continue? or must set isErr = true?
						}
					}
				}
				if (initNode) {
					bool lhsIsArr = (ut->grp() == ARR_G), rhsIsArr = (initNode->tok == INIT_LIST);
					if (lhsIsArr && rhsIsArr) arrayInit(eqPos, cnode->label, (Arr*)clone(ut), initNode, { 0 }); // a[][23] = {...}
					else if (lhsIsArr) repErr(eqPos, "cannot initialize array using a scalar", _FORE_RED_); // a[2] = 45;
					else if (rhsIsArr) repErr(eqPos, "cannot initialize scalar using an array", _FORE_RED_); // *a = {1, 2, 7}
					else { // first check compatibitlity impCast(from = initNode->type, to = ut); Assume not related to array
						if (!impCast(initNode->type, ut)) {
							repErr(eqPos, "cannot implicitly typecast from \"" + str(initNode->type) + "\" to \"" + str(ut) + "\"", _FORE_RED_);
						}
						emit(cnode->label, eps, initNode->eval);
					}
					
				}
				SymRoot->pushSym(cnode->label, ut, cnode->pos);

			} else { // already exists - check if "extern" or a "function"
				if ((retval->type->strg != EXTERN_S) && (t1->strg != EXTERN_S) && (t2 && (t2->grp() != FUNC_G))) {
					repErr(cnode->pos, "variable redefined in this scope", _FORE_RED_); continue;
				}
				
				if (!extMatch(retval->type, unify(t1, t2))) { // just check that retval->type matched t1 union t2
					repErr(cnode->pos, "incompatibe redeclaration", _FORE_RED_);
					repErr(retval->pos, "previous declaration here ...", _FORE_CYAN_);
				} else retval->pos = cnode->pos; // update last declaration position
			}
		}

		if (useful > 0) {
			edge_t **tmp = (edge_t **) malloc(useful * sizeof(edge_t *)); int curr = 0;
			for (int i = 0; i < l2; i++) if (ch2[i]->node->tok == '=') tmp[curr++] = ch2[i];
			free(ch2); $2->edges = tmp; $2->numChild = useful;
			$$ = $2;
		} else $$ = NULL;
	}
	;

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
			case    STRUCT : case UNION : b = $1->type; break;
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
					case STRUCT : if (!isSpec) { b->base = STRUCT_B; b->subDef = ((Base *)($1->type))->subDef; } else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNION : if (!isSpec) { b->base = UNION_B; b->subDef = ((Base *)($1->type))->subDef; } else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
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


// useless iff NULL
init_declarator
	: declarator                 { $$ = $1; brackPut = false; } // handle uselessness at "declaration"
	| declarator '=' initializer { $$ = op( $2, 0, 2, ej($1), ej($3) ); brackPut = false;
		Type *t1 = $1->type;
		if (t1 && (t1->grp() == FUNC_G)) {
			repErr($2->pos, "function initialized like a variable", _FORE_RED_);
			t1->isErr = true;
		}
		$$->type=t1;
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
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}' { $$ = op( $1, 0, 2, ej($2), ej($4) );
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		
		SymRoot->currScope->name = $2->label;
		SymRoot->closeScope();
		// check if there exists a "defined" struct using lookup
		// if yes, generate error - duplicate definition
		// else go just like rule 2, but also insert a struct definition in current scope.
		sym *ret = SymRoot->lookup(string(($1->tok == STRUCT) ? "struct " : "union ") + $2->label);
		bool _good = true;
		if (ret) {
			Type *rt = ret->type;
			if (rt && (rt->grp() == BASE_G)) {
				Base *rb = (Base *) rt;
				if (((rb->base == STRUCT_B) || (rb->base == UNION_B)) && (rb->subDef->syms.size())) {
					repErr($2->pos, "redefinition of struct / union (will default to type \"error_type\")", _FORE_RED_);
					repErr(ret->pos, "previous definition given here", _FORE_CYAN_);
					_good = false;
				}
			}
		}

		if (_good) {
			Base *b = new Base(($1->tok == STRUCT) ? STRUCT_B : UNION_B);
			b->subDef = SymRoot->currScope->subScopes.back();
			$$->type = clone(b);
			SymRoot->currScope->subScopes.pop_back();
			// reset all offsets for symtab* b->subDef
			resetOffset($1->tok, b->subDef);
			SymRoot->pushSym(string(($1->tok == STRUCT) ? "struct " : "union ") + $2->label, b, $2->pos);
		} else {
			SymRoot->currScope->subScopes.pop_back();
			Base *b = new Base(INT_B); b->isErr = true; // we must send something up the tree - even if erroneous
			$$->type = clone(b);
		}
	}
	| struct_or_union '{' struct_declaration_list '}'            { $$ = op( $1, 0, 1, ej($3) );
		Base *b = new Base(($1->tok == STRUCT) ? STRUCT_B : UNION_B);
		b->subDef = SymRoot->currScope;
		// reset all offsets for symtab* b->subDef
		resetOffset($1->tok, b->subDef);
		$$->type = clone(b);

		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name.replace(0, 8, "__struct_");
		SymRoot->closeScope(); SymRoot->currScope->subScopes.pop_back();
	}
	| struct_or_union IDENTIFIER                                 { $$ = op( $1, 0, 1, ej($2) );
		// check if there exists a "defined" struct using gLookup
		// if yes, $$->type = clone of the returned lookup type
		// else just insert a new Base() with subDef = NULL
		sym *ret = SymRoot->gLookup(string(($1->tok == STRUCT) ? "struct " : "union ") + $2->label); bool defExists = false;
		if (ret) {
			Type* rt = ret->type;
			if (rt && (rt->grp() == BASE_G)) {
				Base *rb = (Base *) rt;
				if ( ((rb->base == STRUCT_B) || (rb->base == UNION_B)) && (rb->subDef->syms.size()) ) {
					$$->type = clone(ret->type); defExists = true;
				}
			}
		}

		if (!defExists) {
			Base *b = new Base(($1->tok == STRUCT) ? STRUCT_B : UNION_B);
			b->subDef = new symtab($2->label);
			$$->type = clone(b);
			SymRoot->pushSym(string(($1->tok == STRUCT) ? "struct " : "union ") + $2->label, b, $2->pos);
		}
	}
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
	: specifier_qualifier_list struct_declarator_list ';' { $$ = op( nd(STRUCT_MEMBER, "member", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t1 = $1->type; int l = $2->numChild;
		// assume new scope already opened.
		for (int i = 0; i < l; i++) {
			node_t *cnode = $2->ch(i); // a declarator
			Type *t2 = cnode->type;

			while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0); // rules of "direct_decl"

			sym* retval = SymRoot->lookup(cnode->label);
			if (retval) repErr(cnode->pos, "variable redefined in this struct / union", _FORE_RED_); // already exists
			else {
				Type *tt = tail(t2); // [tt == NULL] iff [t2 == NULL]
				// check for void
				if ((t1->grp() == BASE_G) && (((Base*)t1)->base == VOID_B)) { // t2's tail must not be array or NULL
					if (!t2) { repErr(cnode->pos, "pure \"void\" type given", _FORE_RED_); t1->isErr = true; } // void x;
					else if (tt->grp() == ARR_G) { repErr(cnode->pos, "array of \"voids\" given", _FORE_RED_); t2->isErr = true; } // void x[];
				}
				Type *ut = unify(t1, t2);
				if (!checkArrDims(ut)) { // go over t2 recursively and check that all array bounds must be present
					repErr(cnode->pos, "array bounds incomplete", _FORE_RED_); ut->isErr = true;
				}
				SymRoot->pushSym(cnode->label, ut, cnode->pos);
			} 
		}
	}
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
					case STRUCT : if (!isSpec) { b->base = STRUCT_B; b->subDef = ((Base *)($1->type))->subDef; } else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
					case UNION : if (!isSpec) { b->base = UNION_B; b->subDef = ((Base *)($1->type))->subDef; } else { repErr($1->pos, stdErs,  _FORE_RED_); b->isErr = true; } break;
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
			case    STRUCT : case UNION : b = $1->type; break;
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

// assume only rule 1 is used.
struct_declarator
	: declarator              { $$ = $1; } // nothing to do
	| ':' constant_expression { $$ = $2; } // TODO : handle later - when time permits
	| declarator ':' constant_expression { $$ = op( nd(STRUCT_DECL, "declarator", { 0, 0 }), 0, 2, ej($1), ej($3) ); } // TODO : handle later - when time permits
	;

enum_specifier
	: ENUM '{' enumerator_list '}'				{ $$ = op( $1, 0, 1, ej($3) );
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name.replace(0, 8, "enumType_");
		SymRoot->closeScope(); SymRoot->currScope->subScopes.pop_back();
	}
	| ENUM IDENTIFIER '{' enumerator_list '}'	{ $$ = op( $1, 0, 2, ej($2), ej($4) );
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name.replace(0, 8, "enumType_");
		SymRoot->closeScope(); SymRoot->currScope->subScopes.pop_back();
	}
	| ENUM IDENTIFIER							{ $$ = op( $1, 0, 1, ej($2) ); SymRoot->closeScope(); }
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
	: IDENTIFIER									{ $$ = $1; }
	| '(' declarator ')'							{ $$ = $2; brackPut = true; }
	| direct_declarator '[' constant_expression ']'	{ loc_t bra = $2->pos; $$ = op( $2, 0, 2, ej($1), ej($3) );
		int *bound = eval($3); bool negErr = bound && (*bound < 0);
		if (negErr) repErr($3->pos, "negative array bound specified", _FORE_RED_);

		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL, $3); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL, $3);
		else {
			Arr *a = (Arr *) last(t1, ARR_G);
			if (a) { a->newDim($3); $$->type = t1; }
			else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		}
		brackPut = false;
		$$->type->isErr |= negErr;
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
	| direct_declarator '(' parameter_type_list ')'	{ loc_t bra = $2->pos; /* $$ = $1; */ $$ = op( nd(FUNC_PTR, "() [func-ptr]", { 0, 0 }), 0, 2, ej($1), ej($3) );
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
	: declaration_specifiers declarator            { $$ = op( nd(PARAM_DECL+2000, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t1 = $1->type, *t2 = $2->type, *tt = tail(t2);
        if (t1->strg != NONE_S) { repErr($1->pos, "storage class specifier given in parameter", _FORE_RED_); t1->isErr = true; }
        /* node_t *cnode = $2; // "concerned node" - get directly
        while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0); */
        if ((t1->grp() == BASE_G) && (((Base*)t1)->base == VOID_B)) { // t2's tail must not be array or NULL
            if (!t2) { repErr($2->pos, "pure \"void\" type given", _FORE_RED_); t1->isErr = true; } // void x;
            else if (tt->grp() == ARR_G) { repErr($2->pos, "array of \"voids\" given", _FORE_RED_); t2->isErr = true; } // void x[];
        }
        $$->type = unify(t1, t2); // Arr >> pointer >> funcs >> ptrs
		if (t1->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
			Base *_b = (Base *) t1;
			if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
				if (!tt || (tt->grp() != PTR_G)) {
					repErr($2->pos, "struct / union not yet defined", _FORE_RED_);
					$$->type->isErr = true;
				}
			}
		}
	}
	| declaration_specifiers abstract_declarator   { $$ = op( nd(PARAM_DECL, "param-decl", { 0, 0 }), 0, 2, ej($1), ej($2) );
		Type *t1 = $1->type, *t2 = $2->type, *tt = tail(t2);
        if (t1->strg != NONE_S) { repErr($1->pos, "storage class specifier given in parameter", _FORE_RED_); t1->isErr = true; }
        if ((t1->grp() == BASE_G) && (((Base*)t1)->base == VOID_B)) { // t2's tail must not be array or NULL
            if (!t2) { repErr($2->pos, "pure \"void\" type given", _FORE_RED_); t1->isErr = true; } // void x;
            else if (tt->grp() == ARR_G) { repErr($2->pos, "array of \"voids\" given", _FORE_RED_); t2->isErr = true; } // void x[];
        }
        $$->type = unify(t1, t2);
		if (t1->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
			Base *_b = (Base *) t1;
			if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
				if (!tt || (tt->grp() != PTR_G)) {
					repErr($2->pos, "struct / union not yet defined", _FORE_RED_);
					$$->type->isErr = true;
				}
			}
		}
	}
	| declaration_specifiers                       { $$ = $1;
        if ($1->type->strg != NONE_S) { repErr($1->pos, "storage class specifier given in parameter", _FORE_RED_); $1->type->isErr = true; }

		if ($1->type->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
			Base *_b = (Base *)($1->type);
			if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
				repErr($1->pos, "struct / union not yet defined", _FORE_RED_);
				$$->type->isErr = true;
			}
		}
	}
	;

identifier_list
	: IDENTIFIER                       { $$ = op( nd(ID_LIST, "identifiers", { 0, 0 }), 0, 1, ej($1) ); }
	| identifier_list ',' IDENTIFIER   { $$ = op( $1, 0, 1, ej($3) ); }
	;

type_name
	: specifier_qualifier_list                        { $$ = op( nd(TYPE_NAME, "type-name", { 0, 0 }), 0, 1, ej($1) ); $$->type = $1->type; }
	| specifier_qualifier_list abstract_declarator    { $$ = op( $1, 0, 1, ej($2) );
		Type *t1 = $1->type, *t2 = $2->type, *tt = tail(t2);
        if (t1->strg != NONE_S) { repErr($1->pos, "storage class specifier given in parameter", _FORE_RED_); t1->isErr = true; }
        if ((t1->grp() == BASE_G) && (((Base*)t1)->base == VOID_B)) { // t2's tail must not be array or NULL
            if (!t2) { repErr($2->pos, "pure \"void\" type given", _FORE_RED_); t1->isErr = true; } // void x;
            else if (tt->grp() == ARR_G) { repErr($2->pos, "array of \"voids\" given", _FORE_RED_); t2->isErr = true; } // void x[];
        }
        $$->type = unify(t1, t2);
		/* if (t1->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
			Base *_b = (Base *) t1;
			if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
				if (!tt || (tt->grp() != PTR_G)) {
					repErr($2->pos, "struct / union not yet defined", _FORE_RED_); $$->type->isErr = true;
				}
			}
		} */
	}
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
	| '[' constant_expression ']'                                { $$ = op( $1, 0, 1, ej($2));
		$$->type = new Arr(NULL, $2); /* item unknown */
		int *bound = eval($2); bool negErr = bound && (*bound < 0);
		if (negErr) repErr($2->pos, "negative array bound specified", _FORE_RED_);
		$$->type->isErr |= negErr;
	}
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
		int *bound = eval($3); bool negErr = bound && (*bound < 0);
		if (negErr) repErr($3->pos, "negative array bound specified", _FORE_RED_);

		Type *t1 = $1->type, *tt = tail(t1);
		if (brackPut && tt && (tt->grp() == PTR_G)) { ((Ptr *)tt)->pt = new Arr(NULL, $3); $$->type = t1; }
		else if (!t1) $$->type = new Arr(NULL, $3);
		else {
			Arr *a = (Arr *) last(t1, ARR_G);
			if (a) { a->newDim($3); $$->type = t1; }
			else { repErr(bra, "function returns an array", _FORE_RED_); $$->type = t1; t1->isErr = true; }
		}
		brackPut = false;
		$$->type->isErr |= negErr;
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
	| '{' initializer_list '}'		{ $$ = $2;
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name.replace(0, 8, "__array__");
		SymRoot->closeScope(); SymRoot->currScope->subScopes.pop_back();
	}
	| '{' initializer_list ',' '}'	{ $$ = $2;
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name.replace(0, 8, "__array__");
		SymRoot->closeScope(); SymRoot->currScope->subScopes.pop_back();
	}
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
M3 : CASE constant_expression ':' {
		$$ = $2;
		$$->caselist.push_back(nextIdx());
		string tmp = $2->eval;
		$$->eval = newTmp(clone($$->type));
		emit($$->eval,"==","---",tmp);
		$$->truelist.push_back(nextIdx());
		emit(eps, "ifgoto", "---", $$->eval);
		$$->falselist.push_back(nextIdx());
		emit(eps,"goto","---");
		// CHECK LATER
		// $$->eval = tmp;
	}

labeled_statement
	: IDENTIFIER ':' { emit(eps, "label", "USER_LABEL_" + string($1->label)); } statement{ ($1)->attr = label_attr; $$ = op( $1, 0, 1, ej($4) ); }
	| M3 M statement  { 
		// $$ = op( $1, 0, 2, ej($2), ej($6) );
		Type *t = $1->type; grp_t g = t->grp();
		if (g != BASE_G) repErr($1->pos, "invalid expression type for case label", _FORE_RED_);
		else {
			base_t bs = ((Base*)t)->base;
			if (!(bs == CHAR_B || bs == INT_B || bs == LONG_B || bs == LONG_LONG_B || bs == ENUM_B))
				repErr($1->pos, "invalid expression type for case label", _FORE_RED_);
		}
		backpatch($1->truelist,$2);
		$3->nextlist = merge($3->nextlist,$1->falselist);
		$$->breaklist = $3->breaklist;
		$$->nextlist = $3->nextlist;
		$$->contlist = $3->contlist;
		$$->caselist = $1->caselist;
		backpatch($$->nextlist,nextIdx());

	}
	| DEFAULT ':' statement                   { $$ = op( $1 , 0, 1, ej($3) ); 
		$$->nextlist = $3->nextlist;
		$$->breaklist = $3->breaklist;
	}
	;

// useless iff EMPTY_BLOCK (can't substitute NULL, since EMPTY_BLOCK is still a valid function definition)
compound_statement
	: '{' '}'                                 { $$ = $1; 
		for (int i = IRDump.size() - 1; i >= 0; i--)
			if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
		SymRoot->currScope->name = "__empty__" + SymRoot->currScope->name; // replace(0, 8, "__empty__");
		SymRoot->closeScope(); 
	}
	| '{' statement_list '}'                  { $$ = ($2) ? ($2) : ($1); SymRoot->closeScope(); }
	| '{' declaration_list '}'                { $$ = ($3) ? ($3) : ($1); SymRoot->closeScope(); }
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
	: statement                { $$ = op( nd(STMT_LIST, "stmt-list", { 0, 0 }), 0, 1, ej($1) ); 
															 $$->nextlist = $1->nextlist;
															 $$->contlist = $1->contlist;
															 $$->breaklist = $1->breaklist;
															 $$->caselist = $1->caselist;
															}
	| statement_list M statement {
			$$ = op( $1, 0, 1, ej($3) ); 
			$$->nextlist = $3->nextlist;
			$$->breaklist = merge($1->breaklist, $3->breaklist);
			$$->contlist = merge($1->contlist, $3->contlist);
			$$->caselist = merge($1->caselist, $3->caselist);
			backpatch($1->nextlist, $2);
		}
	;

expression_statement
	: ';'				{ $$ = $1; }
	| expression ';'	{ $$ = $1; }
	;

// void, struct, union not allowed
selection_statement
	: M1 statement
		{ 
			/* $$ = op( $1, 0, 2, Ej($3, "cond", NULL), Ej($6, "stmts", NULL) ); */
			Type *t = $1->type;
			if (t->grp() == BASE_G) {
				base_t bs = ((Base*)t)->base;
				if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) repErr($1->pos, "expression is of pure \"void\" type, a struct or a union", _FORE_RED_);
			}
			$$->nextlist = merge({$1->falselist, $1->nextlist, $2->nextlist});
			$$->breaklist = merge({$1->breaklist, $2->breaklist});
			$$->contlist = merge({$1->contlist, $2->contlist});
			backpatch($$->nextlist, nextIdx());
		}

	| M1 statement ELSE 
		{
			backpatch($1->falselist, nextIdx());
		}
	statement 
		{ 
			/* $$ = op( $7, 0, 3, Ej($3, "cond", NULL), Ej($6, "stmts (if TRUE)", NULL), Ej($9, "stmts (if FALSE)", NULL) ); */
			Type *t = $1->type;
			if (t->grp() == BASE_G) {
				base_t bs = ((Base*)t)->base;
				if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) repErr($1->pos, "expression is of pure \"void\" type, a struct or a union", _FORE_RED_);
			}
			$$->nextlist = merge({$1->nextlist, $2->nextlist, $5->nextlist});
			$$->breaklist = merge({$2->breaklist, $5->breaklist});
			$$->contlist = merge({$2->contlist, $5->contlist});
			backpatch($$->nextlist, nextIdx());
		}
	| SWITCH '(' expression ')' statement { $$ = op( $1, 0, 2, Ej($3, "expr", NULL), Ej($5, "stmts", NULL) );
		Type *t = $3->type; grp_t g = t->grp();
		if (g != BASE_G) repErr($3->pos, "invalid expression type for switch statement", _FORE_RED_);
		else {
			base_t bs = ((Base*)t)->base;
			if (!(bs == CHAR_B || bs == INT_B || bs == LONG_B || bs == LONG_LONG_B || bs == ENUM_B))
				repErr($3->pos, "invalid expression type for switch statement", _FORE_RED_);
		}
		backpatch($5->caselist, $3->eval);
		backpatch($5->nextlist, nextIdx());
		backpatch($5->breaklist, nextIdx());
		$$->contlist = $5->contlist;		
	}
	;

M1: IF '(' expression ')'
	{
		emit(eps, "ifgoto", to_string(nextIdx()+2), $3->eval);
		$3->falselist.push_back(nextIdx());
		emit(eps, "goto", "---");
		backpatch($3->truelist, nextIdx());
		$$ = $3;
	}



iteration_statement
	: WHILE '('	M expression ')' 
		{
			emit(eps, "ifgoto", to_string(nextIdx()+2), $4->eval);
			$4->falselist.push_back(nextIdx());
			emit(eps, "goto", "---");
			backpatch($4->truelist, nextIdx());
		}
	statement { 
		$$ = op( $1, 0, 2, Ej($4, "expr", NULL), Ej($7, "stmts", NULL) );
		Type *t = $4->type;
		if (t->grp() == BASE_G) {
			base_t bs = ((Base*)t)->base;
			if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) repErr($4->pos, "expression is of pure \"void\" type, a struct or a union", _FORE_RED_);
		}
		emit(eps, "goto", to_string($3));
		backpatch($7->nextlist, $3);
		backpatch($7->contlist, $3);
		$$->nextlist = merge({$7->breaklist, $4->falselist});
		backpatch($$->nextlist, nextIdx());

	}
	| DO M statement WHILE '(' M expression ')' ';' {
		$$ = op( $1, 0, 2, Ej($3, "stmts", NULL), Ej($7, "expr", NULL) );
		Type *t = $7->type;
		if (t->grp() == BASE_G) {
			base_t bs = ((Base*)t)->base;
			if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) repErr($7->pos, "expression is of pure \"void\" type, a struct or a union", _FORE_RED_);
		}
		emit(eps, "ifgoto", to_string($2), $7->eval);
		backpatch($3->nextlist, $6);
		backpatch($3->contlist, $6);
		backpatch($7->nextlist, $2);
		backpatch($7->truelist, $2);
		$$->nextlist = merge({$3->breaklist, $7->falselist});
		backpatch($$->nextlist, nextIdx());
	}
	| FOR '(' expression_statement M M2 ')' M statement 
		{ 
			/* $$ = op( $1, 0, 3, Ej($3, "expr", NULL), Ej($4, "expr", NULL), Ej($6, "stmts", NULL) ); */
			emit(eps, "goto", to_string($4));
			backpatch($8->nextlist, $4);
			backpatch($8->contlist, $4);
			backpatch($5->truelist, $7);
			backpatch($3->nextlist, $4);
			$$->nextlist = merge({$8->breaklist, $5->falselist});
			backpatch($$->nextlist, nextIdx());
		}

	| FOR '(' expression_statement M M2 M expression 
		{
			emit(eps, "goto", to_string($4));
			backpatch($7->nextlist, $4);
		}
	')' M statement  
		{
			/* $$ = op( $1, 0, 4, Ej($3, "expr", NULL), Ej($5, "expr", NULL), Ej($7, "expr", NULL), Ej($7, "stmts", NULL) ); */
			Type *t = $7->type;
			if (t->grp() == BASE_G) {
				base_t bs = ((Base*)t)->base;
				if (bs == VOID_B || bs == STRUCT_B || bs == UNION_B) repErr($7->pos, "expression is of pure \"void\" type, a struct or a union", _FORE_RED_);
			}
			emit(eps, "goto", to_string($6));
			backpatch($11->nextlist, $6);
			backpatch($11->contlist, $6);
			backpatch($5->truelist, $10);
			backpatch($3->nextlist, $4);
			$$->nextlist = merge({$11->breaklist, $5->falselist});
			backpatch($$->nextlist, nextIdx());
		}
	;

M2 : expression_statement 
	{
		$$ = $1;
		$$->truelist.push_back(nextIdx());
		emit(eps, "ifgoto", "---", $1->eval);
		$$->falselist.push_back(nextIdx());
		emit(eps, "goto", "---");
	}

jump_statement
	: GOTO IDENTIFIER ';'	{ $$ = op( $1, 0, 1, ej($2) );
												 emit(eps, "goto", "USER_LABEL_" + string($2->label)); } // ignore for now
	| CONTINUE ';'			{ $$ = $1; 
											$$->contlist.push_back(nextIdx()); emit(eps, "goto", "---");}
	| BREAK ';'				{ $$ = $1; 
										$$->breaklist.push_back(nextIdx()); emit(eps, "goto", "---");}
	| RETURN ';'			{ $$ = $1;
		symtab* curr = SymRoot->currScope;
		while (!isFuncScope(curr)) { if (!curr) break; curr = curr->parent; }
		if (curr) {
			sym* funcSym = curr->parent->srchSym(curr->name.substr(5));
			Type *retType = NULL;
			if (funcSym && (funcSym->type) && (funcSym->type->grp() == FUNC_G))
				retType = ((Func*)(funcSym->type))->retType;
			if (retType && (retType->grp() == BASE_G) && (((Base*)retType)->base != VOID_B)) {
				repErr($1->pos, "no scalar returned for a non-void returning function", _FORE_RED_);
				repErr(funcSym->pos, "previous declaration available here", _FORE_CYAN_);
			}
		}
		emit(eps, "return", eps);
	} // TODO: check if current function is actually "VOID_B"
	| RETURN expression ';'	{ $$ = op( $1, 0, 1, ej($2) );
		symtab* curr = SymRoot->currScope;
		while (!isFuncScope(curr)) { if (!curr) break; curr = curr->parent; }
		if (curr) {
			sym* funcSym = curr->parent->srchSym(curr->name.substr(5));
			Type *retType = NULL;
			if (funcSym && (funcSym->type) && (funcSym->type->grp() == FUNC_G))
				retType = ((Func*)(funcSym->type))->retType;
			if (retType && !(impCast($2->type, retType))) { // check implicit typecasting from $2->type to retType
				repErr($2->pos, "cannot impicitly typecast from \"" + str($2->type) + "\" to \"" + str(retType) + "\"", _FORE_RED_);
				repErr(funcSym->pos, "previous declaration available here", _FORE_CYAN_);
			}
		}
		emit(eps, "return", $2->eval);
	}
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
	| declaration_specifiers declarator { // will not work for STATIC functions defined later
		// t1 - must not take some values, take care of STATIC_S too.
		// t2 - FUNC_G, function parameters must not be abstract (but not recursively)
		// unify t1 and t2. Get decl's identifier name - must not be already defined
		string funcName;
		Type *t1 = $1->type, *t2 = $2->type; strg_t s1 = t1->strg; bool _good = false;
		if (s1 == AUTO_S || s1 == REGISTER_S || s1 == TYPEDEF_S) {
			repErr($1->pos, "incompatible storage class specifier for function definition", _FORE_RED_);
		} else if (!t2 || (t2->grp() != FUNC_G)) repErr($2->pos, "variable defined like a function", _FORE_RED_);
		else { // assume params are not abstract for now
			Type *tt = tail(t2), *ut = unify(t1, t2);
			node_t *cnode = $2; while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0);
			funcName = string(cnode->label);
			sym *ret = SymRoot->currScope->parent->srchSym(cnode->label);
			if (ret) {
				if (ret->type->strg != EXTERN_S) {
					repErr(cnode->pos, "symbol redefinition", _FORE_RED_);
					repErr(ret->pos, "previous definition given here", _FORE_CYAN_);
				} else if (!extMatch(ret->type, ut)) {
					repErr($2->pos, "definition does not match previous declaration", _FORE_RED_);
					repErr(ret->pos, "previous declaration given here", _FORE_CYAN_);
				} else { ret->type->strg = NONE_S; ret->pos = cnode->pos; _good = true; }
			} else { // good to go
				bool _err = false;
				if (t1->grp() == BASE_G) { // if struct or union and not defined, check that the declarator has pointer tail - else generate error.
					Base *_b = (Base *) t1;
					if ( ((_b->base == STRUCT_B) || (_b->base == UNION_B)) && !(_b->subDef->syms.size())) {
						if (!tt || (tt->grp() != PTR_G)) {
							repErr(cnode->pos, "struct / union not yet defined", _FORE_RED_); _err = true;
						}
					}
				}
				if (_err) _good = false;
				else {
					SymRoot->currScope->parent->pushSym(cnode->label, ut, cnode->pos);
					SymRoot->currScope->name = string("func ") + cnode->label;
					for (int i = IRDump.size() - 1; i >= 0; i--) {
						if (IRDump[i].opr == "newScope") { IRDump.erase(IRDump.begin() + i); break; }
					}
					// go back in IRDump and delete the first "newScope"
					_good = true;
				}				
			}

			emit(eps, "func", funcName);

			// now insert parameters.
			if (_good) { // works for simple functions ans function params only - do not use a complicated declarator (like function pointers)
				Func *f = (Func *)t2; int l = f->params.size();
				node_t *cnode = $2;
				if (cnode->tok == DECLARATOR) cnode = cnode->ch(1);
				cnode = cnode->ch(1); // cnode->tok = PARAM_TYPE_LIST
				for (int i = 0; i < l; i++) {
					node_t * x = cnode->ch(i);
					if (x->tok != ELLIPSIS) {
						if (x->tok != (PARAM_DECL + 2000)) {
							repErr(x->pos, "used an abstract declaration during function definition", _FORE_RED_); break;
						}
						x = x->ch(1); while (x->tok != IDENTIFIER) x = x->ch((x->tok== DECLARATOR) ? 1 : 0);
					}
					SymRoot->pushSym(x->label, f->params[i], x->pos, true);
				}
			}
		}
	} compound_statement { $$ = op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($2), ej($4));
		node_t *cnode = $2; while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0);
		sym* funcSym = SymRoot->gLookup(cnode->label);
		Type *retType = NULL;
		if (funcSym && (funcSym->type) && (funcSym->type->grp() == FUNC_G))
			retType = ((Func*)(funcSym->type))->retType;
		if (!( retType && (retType->grp() == BASE_G) && (((Base*)retType)->base == VOID_B) )) {
			// check for all statements for a return statement
			node_t *snode = $4;
			if (snode && snode->tok == GEN_BLOCK) snode = snode->ch(1);
			// now snode is a node whose children are all statements.
			int l = snode->numChild;
			bool existsReturn = false;
			for (int i = 0; i < l; i++) {
				node_t* ch = snode->ch(i);
				if (ch && (ch->tok == RETURN)) { existsReturn = true; break; }
			}
			if (!existsReturn) {
				if (snode->ch(l-1)) snode = snode->ch(l-1);
				repErr(snode->pos, "return statement missing at end of non-void function", _FORE_MAGENTA_);
				repErr(funcSym->pos, "previous declaration given here", _FORE_CYAN_);
			}
		}
		if ($4->tok == EMPTY_BLOCK) { // rename the scope to "func <function name>"
			int l = SymRoot->currScope->subScopes.size();
			cout << SymRoot->currScope->subScopes[l-1]->name << endl;
			SymRoot->currScope->subScopes[l-1]->name = SymRoot->currScope->subScopes[l-1]->name.substr(9);
      emit(eps, "function end", eps);
			
			/* SymRoot->currScope->subScopes[l-1]->name = "func func1"; */
		}
	}
	| declarator declaration_list compound_statement {
		$$ = ($2)
		? op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 3, ej($1), ej($2), ej($3) )
		: op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($1), ej($3) );
	}
	| declarator {
		string funcName;
		repErr($1->pos, "warning: will default to \"int\" type", _FORE_MAGENTA_);
		Type *t1 = new Base(INT_B), *t2 = $1->type; bool _good = false;
		if (!t2 || (t2->grp() != FUNC_G)) repErr($1->pos, "variable defined like a function", _FORE_RED_);
		else { // assume params are not abstract for now
			Type *ut = unify(t1, t2);
			node_t *cnode = $1; while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0);
			sym *ret = SymRoot->currScope->parent->srchSym(cnode->label);
			if (ret) {
				if (ret->type->strg != EXTERN_S) {
					repErr(cnode->pos, "function redefinition", _FORE_RED_);
					repErr(ret->pos, "previous definition given here", _FORE_CYAN_);
				} else if (!extMatch(ret->type, ut)) {
					repErr($1->pos, "definition does not match previous declaration", _FORE_RED_);
					repErr(ret->pos, "previous declaration given here", _FORE_CYAN_);
				} else { ret->type->strg = NONE_S; ret->pos = cnode->pos; _good = true; }
			} else { // good to go
				SymRoot->currScope->parent->pushSym(cnode->label, ut, cnode->pos);
				SymRoot->currScope->name = string("func ") + cnode->label;
				funcName = string(cnode->label);
				_good = true;
			}
			
			emit(eps, "func", funcName);

			if (_good) { // works for simple functions ans function params only - do not use a complicated declarator (like function pointers)
				Func *f = (Func *)t2; int l = f->params.size();
				node_t *cnode = $1;
				if (cnode->tok == DECLARATOR) cnode = cnode->ch(1);
				cnode = cnode->ch(1); // cnode->tok = PARAM_TYPE_LIST
				for (int i = 0; i < l; i++) {
					node_t * x = cnode->ch(i);
					if (x->tok != ELLIPSIS) {
						if (x->tok != (PARAM_DECL + 2000)) {
							repErr(x->pos, "used an abstract declaration during function definition", _FORE_RED_); break;
						}
						x = x->ch(1); while (x->tok != IDENTIFIER) x = x->ch((x->tok== DECLARATOR) ? 1 : 0);
					}
					SymRoot->pushSym(x->label, f->params[i], x->pos);
					sym* justPushed = SymRoot->gLookup(x->label);
					if (justPushed) justPushed->isArg = true;
				}
			}
		}
	} compound_statement { $$ = op( nd(FUNC_DEF, "function_definition", { 0, 0 }), 0, 2, ej($1), ej($3) );
		node_t *cnode = $1; while (cnode->tok != IDENTIFIER) cnode = cnode->ch((cnode->tok == DECLARATOR) ? 1 : 0);
		sym* funcSym = SymRoot->gLookup(cnode->label);
		Type *retType = NULL;
		if (funcSym && (funcSym->type) && (funcSym->type->grp() == FUNC_G))
			retType = ((Func*)(funcSym->type))->retType;
		if (!( retType && (retType->grp() == BASE_G) && (((Base*)retType)->base == VOID_B) )) {
			// check for all statements for a return statement
			node_t *snode = $3;
			if (snode && snode->tok == GEN_BLOCK) snode = snode->ch(1);
			// now snode is a node whose children are all statements.
			int l = snode->numChild;
			bool existsReturn = false;
			for (int i = 0; i < l; i++) {
				node_t* ch = snode->ch(i);
				if (ch && (ch->tok == RETURN)) { existsReturn = true; break; }
			}
			if (!existsReturn) {
				if (snode->ch(l-1)) snode = snode->ch(l-1);
				repErr(snode->pos, "return statement missing at end of non-void function", _FORE_MAGENTA_);
				repErr(funcSym->pos, "previous declaration given here", _FORE_CYAN_);
			}
		}
	}
	;

	M: %empty { $$ = nextIdx(); }

%%
