%{
/* PLEASE ENSURE ALL NON-TERMINALS START WITH SMALL ALPHABETS */
/* how to include yytext when terminals are seen? */ 
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

#define MAX_PARSE_TREE_HEIGHT 10000

typedef unsigned long long ull_t;

extern FILE* temp_out;
extern char yytext[];
extern int yylex();
int yyerror(char *s);
extern int column;

void dotStmt(const char*, ...);
void dotNode(ull_t, char*);
void dotEdge(ull_t, ull_t);
void takeAction(const char*);
ull_t newNode();

ull_t currNumNodes = 0; // invariant: currNumNodes > 0 for all existing nodes.
ull_t nodeStack[MAX_PARSE_TREE_HEIGHT];
ull_t nodeStackSize = 0;

%}

%union {
  // for some reason ull_t isn't working
	unsigned long long node;         // if non-terminal
	char *terminal;     // if terminal
}

/* Terminals */
%token <terminal> IDENTIFIER CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME
%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS
%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
/* Non-Terminals */
%type <node> primary_expression postfix_expression argument_expression_list
unary_expression unary_operator cast_expression multiplicative_expression
additive_expression shift_expression relational_expression equality_expression
and_expression  // ! add rest

%start translation_unit

%%

primary_expression
	: IDENTIFIER {
		ull_t parent = newNode();
		dotNode(parent, $1);
		$$ = parent;
		printf("primary_expression -> IDENTIFIER\n");
	}
	| CONSTANT {
		ull_t parent = newNode();
		dotNode(parent, $1);
		$$ = parent;

		// printf("primary_expression -> CONSTANT\n");
		// takeAction("primary_expression CONSTANT");
	}
	| STRING_LITERAL
	| '(' expression ')'
	;

postfix_expression
	: primary_expression {
		$$ = $1;
		printf("postfix_expression -> primary_expression\n");
		// takeAction("postfix_expression primary_expression");
	}
	| postfix_expression '[' expression ']'
	| postfix_expression '(' ')'
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression PTR_OP IDENTIFIER
	| postfix_expression INC_OP
	| postfix_expression DEC_OP
	;

argument_expression_list
	: assignment_expression
	| argument_expression_list ',' assignment_expression
	;

unary_expression
	: postfix_expression {
		printf("unary_expression -> postfix_expression\n");
		$$ = $1;
		// takeAction("unary_expression postfix_expression");
	}
	| INC_OP unary_expression
	| DEC_OP unary_expression
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression {
		$$ = $1;
		printf("cast_expression -> unary_expression\n");
		// takeAction("cast_expression unary_expression");
	}
	| '(' type_name ')' cast_expression
	;

multiplicative_expression
	: cast_expression {
		$$ = $1;
		printf("multiplicative_expression -> cast_expression\n");
		// takeAction("multiplicative_expression cast_expression");
	}
	| multiplicative_expression '*' cast_expression
	| multiplicative_expression '/' cast_expression
	| multiplicative_expression '%' cast_expression
	;

additive_expression
	: multiplicative_expression
	| additive_expression '+' multiplicative_expression {
		ull_t node = newNode();
		dotNode(node, "+");
		dotEdge(node, $1);
		dotEdge(node, $3);
		$$ = node;
		// printf("additive_expression -> additive_expression '+' multiplicative_expression\n");
		// takeAction("additive_expression multiplicative_expression + additive_expression");
	}
	| additive_expression '-' multiplicative_expression
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
	: VOID
	| CHAR
	| SHORT
	| INT
	| LONG
	| FLOAT
	| DOUBLE
	| SIGNED
	| UNSIGNED
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
	: STRUCT
	| UNION
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

int yyerror(char *s) {
	fflush(stdout);
	printf("\n%*s\n%*s\n", column, "^", column, s);
}

void dotStmt(const char* format, ...) { // just a wrapper function
	va_list args;
	va_start(args, format);
	fprintf(temp_out, "\t");
	vfprintf(temp_out, format, args);
	fprintf(temp_out, ";\n");
	va_end(args);
}

void dotNode(ull_t id, char* label) { // just a wrapper function
	fprintf(temp_out, "\t%lld [label = \"%s\"];\n", id, label);
}

void dotEdge(ull_t parent, ull_t child) { // just a wrapper function
	printf("HERE2 %lld, %lld\n", parent, child);
	fprintf(temp_out, "\t%lld -> %lld;\n", parent, child);
}

ull_t newNode() {
	return ++currNumNodes;
}

int nodeStackPush(ull_t nodeId) {
	if (nodeStackSize == MAX_PARSE_TREE_HEIGHT) return -1;
	nodeStack[nodeStackSize++] = nodeId;
	return 0;
}

ull_t nodeStackPop() {
	if (nodeStackSize) return nodeStack[--nodeStackSize];
	return 0; // 0 is not id for any node
}

ull_t nodeStackTop() {
	if (nodeStackSize) return nodeStack[nodeStackSize-1];
	return 0; // 0 is not id for any node
}


/** ACTION UPON SEEING A RULE (PSEUDO-CODE)
* parent = newNode()
* for childSymbol in { Cn, ..., C2, C1 }: // reverse order
*	child = newNode() IF child is ternminal, ELSE nodeStackPop()
* 	add edge (parent, child)
* nodeStackPush(parent)
*/
void takeAction(const char* str) { // input: parent{attr}|child_N{attr}| ... |child_2{attr}|child_1{attr}
    // use of strtok avoided - vanilla string manipulation is faster.
    int n = strlen(str);
    int start = 0, end = 0;
    int parent_seen = 0; ull_t parentId;
	char enforceOrder[2*n]; // to enforce order by introducing invisible edges (and maybe ranks later on).
	int enforceLen = 0;
	int numChild = 0;

    while (start < n) {
        while (str[end] && (str[end] != ' ')) end++;
        end--;
        
        // now concerned with str[start ... end] (both indices included)
		int sep = start; // index of separator
		while ((sep <= end) && str[sep] != '@') sep++;

		ull_t nodeId;
		// [THE FOLLOWING IF-THEN-ELSE STATEMENT ASSUMES THAT A NON-TERMINAL BEGINS WITH A SMALL ALPHABET]
		if (parent_seen && 'a' <= str[start] && str[start] <= 'z') nodeId = nodeStackPop(); // non-terminal symbol
		else nodeId = ++currNumNodes; // parent OR terminal child
        
		fprintf(temp_out, "\t%lld [label=\"", nodeId);
        for (int i = start; i <= sep - 1; i++) fputc(str[i], temp_out); // str[start ... (sep - 1)] is label (keep inside "")
		fprintf(temp_out, (sep > end) ? "\"" : "\",");
        for (int i = sep + 1; i <= end; i++) fputc(str[i], temp_out); // str[(sep + 1) ... end] are label and attributes
		fprintf(temp_out, "];\n");
        
		if (parent_seen) {
			char arr[25]; int l = 0;
			ull_t num = nodeId;
			while (num) { arr[l++] = (num % 10) + '0'; num /= 10; }
			for (int i = l-1; i >= 0; i--) enforceOrder[enforceLen++] = arr[i];
			enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
			enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';
			// add "nodeId -> " to enforceOrder
		}

		if (parent_seen) numChild++;

        if (!parent_seen) { parentId = nodeId; parent_seen = 1; }
		else fprintf(temp_out, "\t%lld -> %lld;\n", parentId, nodeId); // add edge from parent (parentId) to child (nodeId)

        end = start = end + 2;
    }

	nodeStackPush(parentId);

	// Assume that at least one child exists.
	// So, enforceOrder = "... xyz -> "
	// So, you can go back 3-4 indices successfully.
	if (numChild > 1) {
		enforceOrder[enforceLen - 4] = '\0';
		fprintf(temp_out, "\t{\n");
		fprintf(temp_out, "\t\trank = same;\n");
		fprintf(temp_out, "\t\t%s [style = \"invis\"];\n", enforceOrder);
		fprintf(temp_out, "\t\trankdir = RL;\n"); // right to left (adjusted experimentally)
		fprintf(temp_out, "\t}\n");
	}
}
