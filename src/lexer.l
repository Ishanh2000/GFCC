D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <stdio.h>
#include <string.h>
#include <y.tab.h>
#include <stdarg.h>
#include <gfcc_lexer.h>

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"			{ comment(); }
"#"([^\n\0])*		{ count(); }


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
.			{ count(); handle_bad_char(); }

%%

// Please do not change their names.
int column = 1, token_column = 1, token_line = 1;
int colorize = 0; // to colorize output (supported by modern terminals)

/* yywrap() { return 1; } */


void update_location (char c) {
	if (c == '\n') { column = 1; token_line++; }
	else if (c == '\t') column += TAB_LEN - ((column - 1) % TAB_LEN);
	else column++;
}


void comment() { // multi line comment (MLC)
	column += 2; /* since '/*' start was never counted */
	char c, c_next;

    mlc_loop:
	while ((c = input()) != '*' && c != 0) { // normal characters in an MLC
		token_column = column;
		update_location(c);
	}

	if ((c_next = input()) != '/' && c != 0) { // (Lookahead) '*' is not followed by '/'
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
	if (!option || !(a || b)) return 0;
	if (!a) return !strcmp(option, b); // compare with b if a not given
	if (!b) return !strcmp(option, a);
	return !strcmp(option, a) || !strcmp(option, b);
}

void handle_bad_char() {
	lex_err("Bad character seen at line %d, column %d.\n", token_line, token_column);
}


int main (int argc , char *argv[]) {
	colorize = 1;
	// ARGC TOO FEW
	if (argc < 2) {
		lex_err("Too few arguments. Use \"--help\" or \"-h\" for help.\n");
		return E_TOO_FEW_ARGS;
	}

	// HELP - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--help", "-h")) {	gfcc_lexer_help(); return 0; }


	// VERSION - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--version", "-v")) { gfcc_lexer_version(); return 0; }

	


	// ALL - MUST SPECIFY JUST AFTER EXECUTABLE'S NAME (NOT IMPLEMENTING NOW)
	int all = 0; // all = isEqual(argv[1], "--all", "-a");


	// CHECK FILE LIST AND ALSO SEARCH OPTION [--output|-o]
	int start = 1 + all, o_flag_index = -1;
	for (int i = start; i < argc; i++) {
		if (isEqual(argv[i], "--output", "-o")) {
			if (o_flag_index < 0) o_flag_index = i;
			else {
				lex_err("Option [--output|-o] specified twice. Use \"--help\" or \"-h\" for help.\n");
				return E_O_FLAG_TWICE;
			}
			continue;
		}

		if (argv[i][0] == '-') {
			lex_err("Invalid option \"%s\". Use \"--help\" or \"-h\" for help.\n", argv[i]);
			return E_INV_OPTION;
		}
	}

	int total_files;
	if (o_flag_index < 0) total_files = argc - start; // -o was never specified. Output on STDOUT
	else if ((total_files = o_flag_index - start) != (argc - o_flag_index - 1)) { // check no. of input and output files are equal
		lex_err("Number of input and files must be equal. Use \"--help\" or \"-h\" for help.\n");
		return E_NUM_IO_UNEQUAL;
	}

	if (total_files < 1) {
		lex_err("Specify at least one file as input. See \"--help\" or \"-h\" for help.\n");
		return E_NO_FILES;
	}

	int file_failures = 0;
	for (int i = 0; i < total_files; i++) {
		// OPEN FILE	
		FILE *temp_in = fopen(argv[start + i], "r"), *temp_out = stdout;
		if (!temp_in) {
			printf(i > 0 ? "\n" : "");
			lex_warn("File \"%s\" does not exist or problem reading it. Skipping it.\n", argv[start + i]);
			file_failures++;
			continue;
		}
		if ( o_flag_index >= 0 && !(temp_out = fopen(argv[o_flag_index + i + 1], "w")) ) {
			printf(i > 0 ? "\n" : "");
			lex_warn("Problem writing to file \"%s\". Output will print to STDOUT.\n", argv[o_flag_index + i + 1]);
			file_failures++;
			temp_out = stdout;
		}
		
		yyin = temp_in;
		if (temp_out == stdout) {
			printf(i > 0 ? "\n" : "");
			printf("Token Stream for file \"%s\":\n", argv[start + i]);
		}
		
		fprintf(temp_out, "%s%s", _C_BOLD_, _FORE_GREEN_);
		fprintf(temp_out, "%-8s %-18s %-30s %-8s %-8s\n", "TOKEN #", "TOKEN NAME", "LEXEME", "LINE #", "COLUMN #");
		fprintf(temp_out, "-------- ------------------ ------------------------------ -------- --------\n");
		fprintf(temp_out, _C_NONE_);
		
		column = token_line = token_column = 1;

		int token, total_tokens = 0;
		while ((token = yylex()) > 0) {
			char* token_name = (token < IDENTIFIER || token > RETURN) ? yytext : TOKEN_NAME_ARRAY[token - IDENTIFIER];
			fprintf(temp_out, "%-8d %-18s %-30s %-8d %-8d\n", token, token_name, yytext, token_line, token_column);
			total_tokens++;
		}

		fprintf(temp_out, "%s%s", _C_BOLD_, _FORE_GREEN_);
		fprintf(temp_out, "*** TOTAL TOKENS = %d ***\n", total_tokens);
		fprintf(temp_out, _C_NONE_);
	}

	return file_failures;
}

void gfcc_lexer_version() {
	printf("GFCC Lexer Version: v%s (%s)\n", GFCC_LEXER_VERSION, VERSION_DATE);
}

void gfcc_lexer_help() {
	printf("%s", lexer_help);
}

void lex_warn(const char* format, ...) {
	va_list args;
	va_start(args, format);
	if (colorize) printf(_FORE_YELLOW_);
	printf("WARNING: ");
	vprintf(format, args);
	printf(_C_NONE_);
	va_end(args);

}

void lex_err(const char* format, ...) {
	va_list args;
	va_start(args, format);
	if (colorize) printf(_FORE_RED_);
	printf("ERROR: ");
	vprintf(format, args);
	printf(_C_NONE_);
	va_end(args);

}
