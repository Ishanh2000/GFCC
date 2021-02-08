// AUM SHREEGANESHAAYA NAMAH|| // DIETY INVOCATION
#include <gfcc_meta.h>
#include <gfcc_colors.h>

#ifndef __GFCC_LEXER__
#define __GFCC_LEXER__

// TAB LENGTH
#define TAB_LEN 8

// ERROR CODES
#define E_TOO_FEW_ARGS (-1)
#define E_INV_OPTION (-2)
#define E_O_FLAG_TWICE (-3)
#define E_NUM_IO_UNEQUAL (-4)
#define E_NO_FILES (-5)

char* TOKEN_NAME_ARRAY[] = {
	"IDENTIFIER",
	"CONSTANT",
	"STRING_LITERAL",
	"SIZEOF",
	"PTR_OP",
	"INC_OP",
	"DEC_OP",
	"LEFT_OP",
	"RIGHT_OP",
	"LE_OP",
	"GE_OP",
	"EQ_OP",
	"NE_OP",
	"AND_OP",
	"OR_OP",
	"MUL_ASSIGN",
	"DIV_ASSIGN",
	"MOD_ASSIGN",
	"ADD_ASSIGN",
	"SUB_ASSIGN",
	"LEFT_ASSIGN",
	"RIGHT_ASSIGN",
	"AND_ASSIGN",
	"XOR_ASSIGN",
	"OR_ASSIGN",
	"TYPE_NAME",
	"TYPEDEF",
	"EXTERN",
	"STATIC",
	"AUTO",
	"REGISTER",
	"CHAR",
	"SHORT",
	"INT",
	"LONG",
	"SIGNED",
	"UNSIGNED",
	"FLOAT",
	"DOUBLE",
	"CONST",
	"VOLATILE",
	"VOID",
	"STRUCT",
	"UNION",
	"ENUM",
	"ELLIPSIS",
	"CASE",
	"DEFAULT",
	"IF",
	"ELSE",
	"SWITCH",
	"WHILE",
	"DO",
	"FOR",
	"GOTO",
	"CONTINUE",
	"BREAK",
	"RETURN",
};

void count(); // count characters for every token encountered

void comment(); // [DO NOT CHANGE NAME] for multi-line comment (MLC)

int check_type();

int isEqual(char*, char*, char*); // check if first is equal to second ot third

void lex_err(const char*, ...); // printf wrapper for colorized output

void lex_warn(const char*, ...); // printf wrapper for colorized output

void handle_bad_char(); // to handle errors

#endif
