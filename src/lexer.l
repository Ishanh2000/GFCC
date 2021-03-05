D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <stdio.h>
#include <parser.tab.h>
#include <gfcc_lexer.h>

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"				{ comment(); }
"#"([^\n\0])*		{ count(); }


"auto"			{ yylval.terminal = yytext; count(); return (AUTO); }
"break"			{ yylval.terminal = yytext; count(); return (BREAK); }
"case"			{ yylval.terminal = yytext; count(); return (CASE); }
"char"			{ yylval.terminal = yytext; count(); return (CHAR); }
"const"			{ yylval.terminal = yytext; count(); return (CONST); }
"continue"		{ yylval.terminal = yytext; count(); return (CONTINUE); }
"default"		{ yylval.terminal = yytext; count(); return (DEFAULT); }
"do"			{ yylval.terminal = yytext; count(); return (DO); }
"double"		{ yylval.terminal = yytext; count(); return (DOUBLE); }
"else"			{ yylval.terminal = yytext; count(); return (ELSE); }
"enum"			{ yylval.terminal = yytext; count(); return (ENUM); }
"extern"		{ yylval.terminal = yytext; count(); return (EXTERN); }
"float"			{ yylval.terminal = yytext; count(); return (FLOAT); }
"for"			{ yylval.terminal = yytext; count(); return (FOR); }
"goto"			{ yylval.terminal = yytext; count(); return (GOTO); }
"if"			{ yylval.terminal = yytext; count(); return (IF); }
"int"			{ yylval.terminal = yytext; count(); return (INT); }
"long"			{ yylval.terminal = yytext; count(); return (LONG); }
"register"		{ yylval.terminal = yytext; count(); return (REGISTER); }
"return"		{ yylval.terminal = yytext; count(); return (RETURN); }
"short"			{ yylval.terminal = yytext; count(); return (SHORT); }
"signed"		{ yylval.terminal = yytext; count(); return (SIGNED); }
"sizeof"		{ yylval.terminal = yytext; count(); return (SIZEOF); }
"static"		{ yylval.terminal = yytext; count(); return (STATIC); }
"struct"		{ yylval.terminal = yytext; count(); return (STRUCT); }
"switch"		{ yylval.terminal = yytext; count(); return (SWITCH); }
"typedef"		{ yylval.terminal = yytext; count(); return (TYPEDEF); }
"union"			{ yylval.terminal = yytext; count(); return (UNION); }
"unsigned"		{ yylval.terminal = yytext; count(); return (UNSIGNED); }
"void"			{ yylval.terminal = yytext; count(); return (VOID); }
"volatile"		{ yylval.terminal = yytext; count(); return (VOLATILE); }
"while"			{ yylval.terminal = yytext; count(); return (WHILE); }

{L}({L}|{D})*				{ yylval.terminal = strdup(yytext); printf("LEXER: %s\n", yytext); count(); return (check_type()); /* returns IDENTIFIER */ }

0[xX]{H}+{IS}?				{ yylval.terminal = yytext; count(); return (CONSTANT); }
0{D}+{IS}?					{ yylval.terminal = yytext; count(); return (CONSTANT); }
{D}+{IS}?					{ yylval.terminal = yytext; count(); return (CONSTANT); }
L?'(\\.|[^\\'])+'			{ yylval.terminal = yytext; count(); return (CONSTANT); /* Why not? */ }
{D}+{E}{FS}?				{ yylval.terminal = yytext; count(); return (CONSTANT); }
{D}*"."{D}+({E})?{FS}?		{ yylval.terminal = yytext; count(); return (CONSTANT); }
{D}+"."{D}*({E})?{FS}?		{ yylval.terminal = yytext; count(); return (CONSTANT); }

L?\"(\\.|[^\\"])*\"			{ yylval.terminal = yytext; count(); return (STRING_LITERAL); }

"..."			{ yylval.terminal = yytext; count(); return (ELLIPSIS); }
">>="			{ yylval.terminal = yytext; count(); return (RIGHT_ASSIGN); }
"<<="			{ yylval.terminal = yytext; count(); return (LEFT_ASSIGN); }
"+="			{ yylval.terminal = yytext; count(); return (ADD_ASSIGN); }
"-="			{ yylval.terminal = yytext; count(); return (SUB_ASSIGN); }
"*="			{ yylval.terminal = yytext; count(); return (MUL_ASSIGN); }
"/="			{ yylval.terminal = yytext; count(); return (DIV_ASSIGN); }
"%="			{ yylval.terminal = yytext; count(); return (MOD_ASSIGN); }
"&="			{ yylval.terminal = yytext; count(); return (AND_ASSIGN); }
"^="			{ yylval.terminal = yytext; count(); return (XOR_ASSIGN); }
"|="			{ yylval.terminal = yytext; count(); return (OR_ASSIGN); }
">>"			{ yylval.terminal = yytext; count(); return (RIGHT_OP); }
"<<"			{ yylval.terminal = yytext; count(); return (LEFT_OP); }
"++"			{ yylval.terminal = yytext; count(); return (INC_OP); }
"--"			{ yylval.terminal = yytext; count(); return (DEC_OP); }
"->"			{ yylval.terminal = yytext; count(); return (PTR_OP); }
"&&"			{ yylval.terminal = yytext; count(); return (AND_OP); }
"||"			{ yylval.terminal = yytext; count(); return (OR_OP); }
"<="			{ yylval.terminal = yytext; count(); return (LE_OP); }
">="			{ yylval.terminal = yytext; count(); return (GE_OP); }
"=="			{ yylval.terminal = yytext; count(); return (EQ_OP); }
"!="			{ yylval.terminal = yytext; count(); return (NE_OP); }
";"				{ yylval.terminal = yytext; count(); return (';'); }
("{"|"<%")		{ yylval.terminal = yytext; count(); return ('{'); }
("}"|"%>")		{ yylval.terminal = yytext; count(); return ('}'); }
","				{ yylval.terminal = yytext; count(); return (','); }
":"				{ yylval.terminal = yytext; count(); return (':'); }
"="				{ yylval.terminal = yytext; count(); return ('='); }
"("				{ yylval.terminal = yytext; count(); return ('('); }
")"				{ yylval.terminal = yytext; count(); return (')'); }
("["|"<:")		{ count(); printf("LEXER2: %s\n", yytext); return ('['); }
("]"|":>")		{ count(); return (']'); }
"."				{ yylval.terminal = yytext; count(); return ('.'); }
"&"				{ yylval.terminal = yytext; count(); return ('&'); }
"!"				{ yylval.terminal = yytext; count(); return ('!'); }
"~"				{ yylval.terminal = yytext; count(); return ('~'); }
"-"				{ yylval.terminal = yytext; count(); return ('-'); }
"+"				{ yylval.terminal = yytext; count(); return ('+'); }
"*"				{ yylval.terminal = yytext; count(); return ('*'); }
"/"				{ yylval.terminal = yytext; count(); return ('/'); }
"%"				{ yylval.terminal = yytext; count(); return ('%'); }
"<"				{ yylval.terminal = yytext; count(); return ('<'); }
">"				{ yylval.terminal = yytext; count(); return ('>'); }
"^"				{ yylval.terminal = yytext; count(); return ('^'); }
"|"				{ yylval.terminal = yytext; count(); return ('|'); }
"?"				{ yylval.terminal = yytext; count(); return ('?'); }

[ \t\v\n\f]		{ count(); }
.				{ count(); handle_bad_char(); }

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return input(); } // #define to function

void lexUnput(char c) { unput(c); } // #define to function

/* yywrap() { return 1; } */

// See main.c for this part
