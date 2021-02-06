D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <stdio.h>
#include <string.h>
#include "y.tab.h"

#define TAB_LEN 8
#define GFCC_LEXER_VERSION "0.0.1"
#define VERSION_DATE "February 8, 2021"

#define E_TOO_FEW_ARGS (-1)
#define E_INV_OPTION (-2)
#define E_OUTPUT_TWICE (-3)
#define E_NUM_IO_UNEQUAL (-4)
#define E_NO_FILES (-5)

void count();
void comment();
int check_type();	
void gfcc_lexer_help();

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

int isEqual(char* option, char* a, char* b) { // return 1 iff option matched a OR b
	if (!(a || b)) return 0;
	if (!a) return !strcmp(option, b); // compare with b if a not given
	if (!b) return !strcmp(option, a);
	return !strcmp(option, a) || !strcmp(option, b);
}

int main (int argc , char *argv[]) {
	// ARGC TOO FEW
	if (argc < 2) {
		printf("ERROR: Too few arguments. Use \"-h\" or \"--help\" for help.\n");
		return E_TOO_FEW_ARGS;
	}

	// HELP - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--help", "-h")) {
		gfcc_lexer_help();
		return 0;
	}

	// VERSION - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--version", "-v")) {
		printf("GFCC Lexer Version: v%s (%s)\n", GFCC_LEXER_VERSION, VERSION_DATE);
		return 0;
	}

	// ALL - MUST SPECIFY JUST AFTER EXECUTABLE'S NAME
	int all = isEqual(argv[1], "--all", "-a");


	// CHECK FILE LIST AND ALSO SEARCH OPTION [--output|-o]
	int start = 1 + all, o_flag_index = -1;
	for (int i = start; i < argc; i++) {
		if (isEqual(argv[i], "--output", "-o")) {
			if (o_flag_index < 0) o_flag_index = i;
			else {
				printf("ERROR: Option [--output|-o] specified twice. Use \"--help\" or \"-h\" for help.\n");
				return E_OUTPUT_TWICE;
			}
			continue;
		}

		if (argv[i][0] == '-') {
			printf("ERROR: Invalid option \"%s\". Use \"--help\" or \"-h\" for help.\n", argv[i]);
			return E_INV_OPTION;
		}
	}

	int total_files;
	if (o_flag_index < 0) total_files = argc - start; // -o was never specified. Output on STDOUT
	else if ((total_files = o_flag_index - start) != (argc - o_flag_index - 1)) { // check no. of input and output files are equal
		printf("ERROR: Number of input and files must be equal. Use \"--help\" or \"-h\" for help.\n");
		return E_NUM_IO_UNEQUAL;
	}

	// printf("Reached here! start = %d, total_files = %d, o_flag_index = %d\n", start, total_files, o_flag_index);
	if (total_files < 1) {
		printf("ERROR: Specify at least one file as input. See \"--help\" or \"-h\" for help.\n");
		return E_NO_FILES;
	}

	int file_failures = 0;
	for (int i = 0; i < total_files; i++) {
		// OPEN FILE	
		FILE *temp_in = fopen(argv[start + i], "r"), *temp_out = stdout;
		if (!temp_in) {
			printf("WARNING: Problem opening file \"%s\". Skipping it.\n", argv[start + i]);
			file_failures++;
			continue;
		}
		if ( o_flag_index >= 0 && !(temp_out = fopen(argv[o_flag_index + i + 1], "w")) ) {
			printf("WARNING: Problem writing to file \"%s\". Output will print to STDOUT.\n", argv[o_flag_index + i + 1]);
			file_failures++;
			temp_out = stdout;
		}
		
		yyin = temp_in;
		if (temp_out == stdout) {
			printf(i > 0 ? "================================================================\n\n" : "");
			printf("Token Stream for file \"%s\":\n", argv[start + i]);
		}
		
		fprintf(temp_out, "%-15s %-15s %-15s %-15s\n", "TOKEN #", "LEXEME", "LINE #", "COLUMN #");
		fprintf(temp_out, "--------------- --------------- --------------- ---------------\n");

		column = token_line = token_column = 1;

		int token;
		while ((token = yylex()) > 0) fprintf(temp_out, "%-15d %-15s %-15d %-15d\n", token, yytext, token_line, token_column);
	}

	return file_failures;
}

void gfcc_lexer_help() {
  printf("Usage: <exec-name> [--help|-h] [--version|-v] [--all|-a] files... [--output|-o] output-files...\n");
  printf("\n");
  printf("Options:\n");
  printf("\t --help \t\t -h \t\t: Help.\n");
  printf("\t --version \t\t -v \t\t: Version and release date. Maybe author names/licenses.\n");
  printf("\t --output \t\t -o \t\t: Names of output files in the same order as inputs are specified.\n");
  printf("\t --all \t\t -a \t\t: All information (including token type, lexeme address, type, etc.).\n");
  printf("\n");
  printf("NOTES:\n");
  printf("\t 1) Specify output files AFTER input files.\n");
  printf("\t 2) The number of output files must be EQUAL to the number of input files.\n");
  printf("\n");
}
