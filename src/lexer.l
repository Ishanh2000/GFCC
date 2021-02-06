D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <stdio.h>
#include "y.tab.h"
#define TAB_LEN 8

void count();
void comment();
int check_type();	

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"			{ comment(); }

"#include"              { count(); return (INCLUDE); }

"auto"			{ count(); return (AUTO); }
"break"			{ count(); return (BREAK); }
"case"			{ count(); return (CASE); }
"char"			{ count(); return (CHAR); }
"const"			{ count(); return (CONST); }
"continue"		{ count(); return (CONTINUE); }
"default"		{ count(); return (DEFAULT); }
"do"			{ count(); return (DO); }
"double"		{ count(); return (DOUBLE); }
"else"			{ count(); return (ELSE); }
"enum"			{ count(); return (ENUM); }
"extern"		{ count(); return (EXTERN); }
"float"			{ count(); return (FLOAT); }
"for"			{ count(); return (FOR); }
"goto"			{ count(); return (GOTO); }
"if"			{ count(); return (IF); }
"int"			{ count(); return (INT); }
"long"			{ count(); return (LONG); }
"register"		{ count(); return (REGISTER); }
"return"		{ count(); return (RETURN); }
"short"			{ count(); return (SHORT); }
"signed"		{ count(); return (SIGNED); }
"sizeof"		{ count(); return (SIZEOF); }
"static"		{ count(); return (STATIC); }
"struct"		{ count(); return (STRUCT); }
"switch"		{ count(); return (SWITCH); }
"typedef"		{ count(); return (TYPEDEF); }
"union"			{ count(); return (UNION); }
"unsigned"		{ count(); return (UNSIGNED); }
"void"			{ count(); return (VOID); }
"volatile"		{ count(); return (VOLATILE); }
"while"			{ count(); return (WHILE); }

{L}({L}|{D})*		{ count(); return (check_type()); }

0[xX]{H}+{IS}?		{ count(); return (CONSTANT); }
0{D}+{IS}?		{ count(); return (CONSTANT); }
{D}+{IS}?		{ count(); return (CONSTANT); }
L?'(\\.|[^\\'])+'	{ count(); return (CONSTANT); }

{D}+{E}{FS}?		{ count(); return (CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ count(); return (CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ count(); return (CONSTANT); }

L?\"(\\.|[^\\"])*\"	{ count(); return (STRING_LITERAL); }

"..."			{ count(); return (ELLIPSIS); }
">>="			{ count(); return (RIGHT_ASSIGN); }
"<<="			{ count(); return (LEFT_ASSIGN); }
"+="			{ count(); return (ADD_ASSIGN); }
"-="			{ count(); return (SUB_ASSIGN); }
"*="			{ count(); return (MUL_ASSIGN); }
"/="			{ count(); return (DIV_ASSIGN); }
"%="			{ count(); return (MOD_ASSIGN); }
"&="			{ count(); return (AND_ASSIGN); }
"^="			{ count(); return (XOR_ASSIGN); }
"|="			{ count(); return (OR_ASSIGN); }
">>"			{ count(); return (RIGHT_OP); }
"<<"			{ count(); return (LEFT_OP); }
"++"			{ count(); return (INC_OP); }
"--"			{ count(); return (DEC_OP); }
"->"			{ count(); return (PTR_OP); }
"&&"			{ count(); return (AND_OP); }
"||"			{ count(); return (OR_OP); }
"<="			{ count(); return (LE_OP); }
">="			{ count(); return (GE_OP); }
"=="			{ count(); return (EQ_OP); }
"!="			{ count(); return (NE_OP); }
";"			{ count(); return (';'); }
("{"|"<%")		{ count(); return ('{'); }
("}"|"%>")		{ count(); return ('}'); }
","			{ count(); return (','); }
":"			{ count(); return (':'); }
"="			{ count(); return ('='); }
"("			{ count(); return ('('); }
")"			{ count(); return (')'); }
("["|"<:")		{ count(); return ('['); }
("]"|":>")		{ count(); return (']'); }
"."			{ count(); return ('.'); }
"&"			{ count(); return ('&'); }
"!"			{ count(); return ('!'); }
"~"			{ count(); return ('~'); }
"-"			{ count(); return ('-'); }
"+"			{ count(); return ('+'); }
"*"			{ count(); return ('*'); }
"/"			{ count(); return ('/'); }
"%"			{ count(); return ('%'); }
"<"			{ count(); return ('<'); }
">"			{ count(); return ('>'); }
"^"			{ count(); return ('^'); }
"|"			{ count(); return ('|'); }
"?"			{ count(); return ('?'); }

[ \t\v\n\f]		{ count(); }
.			{ /* ignore bad characters */ }

%%

int column = 1, token_column = 1, token_line = 1;


/* yywrap() { return 1; } */


void update_location (char c) {
	if (c == '\n') { column = 1; token_line++; }
	else if (c == '\t') column += TAB_LEN - (column % TAB_LEN);
	else column++;
}


void comment() { // multi line comment (MLC)
	column += 2; // since '/*' was never counted
	char c, c_next;

    mlc_loop:
	while ((c = input()) != '*' && c != 0) { // normal characters in an MLC
		token_column = column;
		update_location(c);
	}

	if ((c_next = input()) != '/' && c != 0) {
		// (Lookahead) '*' is not followed by '/'
		unput(c_next);
		goto mlc_loop;
	}

	if (c != 0) { // End of an MLC (but not due to EOF)
		column++; // because we need to take ending '/' into account
		token_column = column;
		update_location(c);
	}
}


void count() {
	token_column = column;
	for (int i = 0; yytext[i] != '\0'; i++) update_location(yytext[i]);

	// ECHO;
}


int check_type() {
	/* pseudo code --- this is what it should check
	*
	*	if (yytext == type_name) return (TYPE_NAME);
	*	return (IDENTIFIER);
	*/

	return (IDENTIFIER); // it actually will only return IDENTIFIER
}


int main (int argc , char *argv[]) {
	if (argc != 2) {
		printf("Number of arguments not matching.\n");
		return -1;
	}

	FILE *temp = fopen(argv[1], "r");
	if (!temp) {
		printf("File does not exist.\n");
		return -1;
	}

	yyin = temp;
	int token;
	printf("%-15s %-15s %-15s %-15s\n", "TOKEN #", "LEXEME", "LINE #", "COLUMN #");

	while ((token = yylex()) > 0) {
		printf("%-15d %-15s %-15d %-15d\n", token, yytext, token_line, token_column);
	}

	return 0;
}
