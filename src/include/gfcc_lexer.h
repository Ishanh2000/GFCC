// AUM SHREEGANESHAAYA NAMAH|| // DIETY INVOCATION
#ifndef __GFCC_LEXER__
#define __GFCC_LEXER__

#include <cstdio>
#include <gfcc_meta.h>
#include <gfcc_colors.h>

// TAB LENGTH
#define TAB_LEN 8

// ERROR CODES
#define E_TOO_FEW_ARGS		(-1)
#define E_INV_OPTION		(-2)
#define E_O_FLAG_TWICE		(-3)
#define E_NUM_IO_UNEQUAL	(-4)
#define E_NO_FILES			(-5)
#define E_TAB_LEN			(-6)

#define UNINIT				(-10)
#define INIT				(-11)
#define FUNC_CALL			(-12) // () is function call
#define SUBSCRIPT			(-13) // [] is subscript operator
#define DEREF				(-14) //  * is dereference operator
#define ARG_EXPR_LIST		(-15) // comma separated expression-arguments passed to a function call
#define ENUM_LIST			(-16) // comma separated enum-values
#define TYPE_QUAL_LIST		(-17) // whitespace separated type qualifiers (strings of [const,volatile])
#define PARAM_TYPE_LIST		(-18) // comma separated parameter type list (for declaring function pointers)
#define ID_LIST				(-19) // comma separated identifier list (for declaring function pointers)
#define EMPTY_BLOCK			(-20) // { }
#define GEN_BLOCK			(-21) // general block (first declarations, then statements)
#define DECL_LIST			(-22) // comma separated declaration list (multiple declaration statements, only specified at a block's beginning)
#define STMT_LIST			(-23) // whitespace separated statement list
#define IF_STMT				(-24) // if statement
#define IF_ELSE_STMT		(-25) // if-else statement
#define TR_UNIT				(-26) // whole translation unit (full file)
#define CAST_EXPR			(-27) // cast expression
#define DECL_SPEC_LIST		(-28) // whitespace separated declaration specifiers (not meaningful for execution/AST)
#define INIT_DECL_LIST		(-29) // comma separated list of variables (that are being declared, maybe initialized)
#define DECLARATION			(-30) // declaration (specifiers, then list of variables)
#define SPEC_QUAL_LIST		(-31) // whitespace separated list of specifier qualifiers
#define STRUCT_DECLN_LIST	(-32) // whitespace separated list of struct declarations
#define STRUCT_DECL			(-33) // struct declaration (qualifier list and declarator list)
#define STRUCT_DECL_LIST	(-34) // whitespace separated list of struct declarations

#define FUNC_PTR			(-35) // function pointer
#define DECLARATOR			(-36) // declarator (general variable, a, b[], c[90], *x, (*func)(), etc.)
#define INIT_LIST			(-37) // Array initializer list
#define DO_WHILE			(-38) // Do while iteration statement
#define STRUCT_MEMBER			(-39) // Used to denote a member in struct/union	
#define ALL_MEMBERS			(-40) // To denote all members of a struct/union as a parent node
#define ABSTRACT_DECLARATOR (-41) //Denote the abstracgt declarations like int *, int [], etc.
#define PARAM_DECL          (-42) //parameter declarations
#define ABSTRACT_DECLN      (-43)//() used in abstract declratoins 
#define FUNC_DEF            (-44)
typedef unsigned long long ull_t;

typedef struct _token_t {
	int id; // type
	const char* lexeme;
	int line;
	int column;
} token_t;

typedef struct _node_t {
	ull_t id;
	int tok_type; // [ IDENTIFIER | CONSTANT | STRING_LITERAL | some other | -1 ] (else -1, usually for internal nodes)
	const char* label;
	const char* attr;
	struct _node_t *parent;
	int numChild;
	struct _edge_t **edges;
	// int line, column; // for error reporting
} node_t;

typedef struct _edge_t {
	struct _node_t *node;
	const char *label;
	const char *attr;
} edge_t;

extern const char* TOKEN_NAME_ARRAY[]; // make this const

extern int column, token_column, token_line, tab_len, colorize, bad_char_seen;

extern FILE *yyin, *yyout, *temp_out;

extern char *fileName, *yytext;

extern ull_t currNumNodes;

extern ull_t q_head, q_tail; // enqueue at tail, dequeue from head

extern node_t* AstRoot;

void lexUnput(char);

char lexInput(void);

void count(); // count characters for every token encountered

void comment(); // [DO NOT CHANGE NAME] for multi-line comment (MLC)

int check_type();

int isEqual(const char*, const char*, const char*); // check if first is equal to second ot third

void lex_err(const char*, ...); // printf wrapper for colorized output

void lex_warn(const char*, ...); // printf wrapper for colorized output

void handle_bad_char(); // to handle errors

const char* getTokenName(int, const char*); // get token name (type) using TOKEN_NAME_ARRAY

void fprintTokens(FILE*, token_t*, unsigned long int, int); // TRY USING THIS FOR SCANNING (LEXICAL ANALYSIS)

void update_location(char);

// int yyarse();

// int yywrap();

extern "C" int yylex();

int yyerror(const char*);

void dotStmt(const char*, ...);

void dotNode(FILE *, node_t*);

void dotEdge(FILE *, node_t*, edge_t*);

ull_t newNode();

// token_type, label, attr
node_t* mkGenNode(int, const char*, const char*); // attr may be NULL

// token_type, label
node_t* mkNode(int, const char*); // attr will be passed to mkGenNode as NULL

extern node_t* (*nd)(int, const char*); // short form

// child, label, attr
edge_t* mkGenEdge(node_t*, const char*, const char*); // label, attr may be NULL

// child
edge_t* mkEdge(node_t*); // label, attr will be passed to mkGenEdge as NULL

extern edge_t* (*ej)(node_t*); // short form

// parent, numLeft, numRight, edge_1, edge_2, ...
node_t* mkOpNode(node_t*, int, int, ...);

extern node_t* (*op)(node_t*, int, int, ...); // short form

// void ASTToDot(FILE*, node_t*); // temp_out, root

// char* cat(char*, char*);

int Enqueue(node_t *);

node_t *Dequeue();

int IsEmpty();

int accept(node_t *node);

void AstToDot(FILE *, node_t *);

#endif
