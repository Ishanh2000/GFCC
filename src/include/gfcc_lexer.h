// AUM SHREEGANESHAAYA NAMAH|| // DIETY INVOCATION
#include <stdio.h>
#include <gfcc_meta.h>
#include <gfcc_colors.h>

#ifndef __GFCC_LEXER__
#define __GFCC_LEXER__

// TAB LENGTH
#define TAB_LEN 8

// ERROR CODES
#define E_TOO_FEW_ARGS		(-1)
#define E_INV_OPTION		(-2)
#define E_O_FLAG_TWICE		(-3)
#define E_NUM_IO_UNEQUAL	(-4)
#define E_NO_FILES			(-5)
#define E_TAB_LEN			(-6)

#define MAX_PARSE_TREE_HEIGHT 10000

typedef unsigned long long ull_t;

typedef struct _token_t {
	int id; // type
	char* lexeme; // keep this NULL terminated (as usual)
	int line;
	int column;
} token_t;

typedef struct _node_t {
	ull_t id;
	int tok_type; // [ IDENTIFIER | CONSTANT | STRING_LITERAL ] (else -1)
	char* label; // keep this NULL terminated (as usual)
	struct _node_t *parent;
	struct _node_t **child;
	int numChild;
} node_t;

extern char* TOKEN_NAME_ARRAY[]; // make this const

int column, token_column, token_line, tab_len, colorize, bad_char_seen;

FILE *yyin, *yyout, *temp_out;

char* yytext;

ull_t currNumNodes, nodeStackSize;

extern ull_t nodeStack[];


void lexUnput(char);

char lexInput(void);

void count(); // count characters for every token encountered

void comment(); // [DO NOT CHANGE NAME] for multi-line comment (MLC)

int check_type();

int isEqual(char*, char*, char*); // check if first is equal to second ot third

void lex_err(const char*, ...); // printf wrapper for colorized output

void lex_warn(const char*, ...); // printf wrapper for colorized output

void handle_bad_char(); // to handle errors

char* getTokenName(int, char*); // get token name (type) using TOKEN_NAME_ARRAY

void fprintTokens(FILE*, token_t*, unsigned long int, int); // TRY USING THIS FOR SCANNING (LEXICAL ANALYSIS)

void update_location(char);

// int yyarse();

// int yywrap();

int yylex();

int yyerror(char*);

void dotStmt(const char*, ...);

void dotNode(ull_t, char*);

void dotEdge(ull_t, ull_t);

void takeAction(const char*);

ull_t newNode();

// makeLeaf(label, attr);
void* makeLeaf(int, char*, char*); // attr may be NULL

// makeLeaf(opLabel, opAttr, child_1, attr_1, child_2, attr_2, . . . , child_n, attr_n, 0);
void* makeOpNode(char*, char*, ...); // attr may be NULL

// char* gfcc_strcat(char* a, ...); // NULL OR 0 terminated

ull_t makeOpNode2(char*, ...);

#endif

