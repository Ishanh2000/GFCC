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

typedef struct _token_t {
	int id; // type
	char* lexeme; // keep this NULL terminated (as usual)
	int line;
	int column;
} token_t;

// make this const
extern char* TOKEN_NAME_ARRAY[];
int column, token_column, token_line, tab_len, colorize, bad_char_seen;
FILE *yyin, *yyout, *temp_out;
char* yytext;

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

#endif

