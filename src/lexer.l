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

"auto"			{ yylval.terminal = "auto"; count(); return (AUTO); }
"break"			{ yylval.terminal = "break"; count(); return (BREAK); }
"case"			{ yylval.terminal = "case"; count(); return (CASE); }
"char"			{ yylval.terminal = "char"; count(); return (CHAR); }
"const"			{ yylval.terminal = "const"; count(); return (CONST); }
"continue"		{ yylval.terminal = "continue"; count(); return (CONTINUE); }
"default"		{ yylval.terminal = "default"; count(); return (DEFAULT); }
"do"			{ yylval.terminal = "do"; count(); return (DO); }
"double"		{ yylval.terminal = "double"; count(); return (DOUBLE); }
"else"			{ yylval.terminal = "else"; count(); return (ELSE); }
"enum"			{ yylval.terminal = "enum"; count(); return (ENUM); }
"extern"		{ yylval.terminal = "extern"; count(); return (EXTERN); }
"float"			{ yylval.terminal = "float"; count(); return (FLOAT); }
"for"			{ yylval.terminal = "for"; count(); return (FOR); }
"goto"			{ yylval.terminal = "goto"; count(); return (GOTO); }
"if"			{ yylval.terminal = "if"; count(); return (IF); }
"int"			{ yylval.terminal = "int"; count(); return (INT); }
"long"			{ yylval.terminal = "long"; count(); return (LONG); }
"register"		{ yylval.terminal = "register"; count(); return (REGISTER); }
"return"		{ yylval.terminal = "return"; count(); return (RETURN); }
"short"			{ yylval.terminal = "short"; count(); return (SHORT); }
"signed"		{ yylval.terminal = "signed"; count(); return (SIGNED); }
"sizeof"		{ yylval.terminal = "sizeof"; count(); return (SIZEOF); }
"static"		{ yylval.terminal = "static"; count(); return (STATIC); }
"struct"		{ yylval.terminal = "struct"; count(); return (STRUCT); }
"switch"		{ yylval.terminal = "switch"; count(); return (SWITCH); }
"typedef"		{ yylval.terminal = "typedef"; count(); return (TYPEDEF); }
"union"			{ yylval.terminal = "union"; count(); return (UNION); }
"unsigned"		{ yylval.terminal = "unsigned"; count(); return (UNSIGNED); }
"void"			{ yylval.terminal = "void"; count(); return (VOID); }
"volatile"		{ yylval.terminal = "volatile"; count(); return (VOLATILE); }
"while"			{ yylval.terminal = "while"; count(); return (WHILE); }

{L}({L}|{D})*				{ yylval.terminal = strdup(yytext); count(); return (check_type()); /* returns IDENTIFIER */ }

0[xX]{H}+{IS}?				{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }
0{D}+{IS}?					{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }
{D}+{IS}?					{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }
L?'(\\.|[^\\'])+'			{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); /* Why not? */ }
{D}+{E}{FS}?				{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }
{D}*"."{D}+({E})?{FS}?		{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }
{D}+"."{D}*({E})?{FS}?		{ yylval.terminal = strdup(yytext); count(); return (CONSTANT); }

L?\"(\\.|[^\\"])*\"			{ yylval.terminal = strdup(yytext); count(); return (STRING_LITERAL); }

"..."			{ yylval.terminal = "..."; count(); return (ELLIPSIS); }
">>="			{ yylval.terminal = ">>="; count(); return (RIGHT_ASSIGN); }
"<<="			{ yylval.terminal = "<<="; count(); return (LEFT_ASSIGN); }
"+="			{ yylval.terminal = "+="; count(); return (ADD_ASSIGN); }
"-="			{ yylval.terminal = "-="; count(); return (SUB_ASSIGN); }
"*="			{ yylval.terminal = "*="; count(); return (MUL_ASSIGN); }
"/="			{ yylval.terminal = "/="; count(); return (DIV_ASSIGN); }
"%="			{ yylval.terminal = "%="; count(); return (MOD_ASSIGN); }
"&="			{ yylval.terminal = "&="; count(); return (AND_ASSIGN); }
"^="			{ yylval.terminal = "^="; count(); return (XOR_ASSIGN); }
"|="			{ yylval.terminal = "|="; count(); return (OR_ASSIGN); }
">>"			{ yylval.terminal = ">>"; count(); return (RIGHT_OP); }
"<<"			{ yylval.terminal = "<<"; count(); return (LEFT_OP); }
"++"			{ yylval.terminal = "++"; count(); return (INC_OP); }
"--"			{ yylval.terminal = "--"; count(); return (DEC_OP); }
"->"			{ yylval.terminal = "->"; count(); return (PTR_OP); }
"&&"			{ yylval.terminal = "&&"; count(); return (AND_OP); }
"||"			{ yylval.terminal = "||"; count(); return (OR_OP); }
"<="			{ yylval.terminal = "<="; count(); return (LE_OP); }
">="			{ yylval.terminal = ">="; count(); return (GE_OP); }
"=="			{ yylval.terminal = "=="; count(); return (EQ_OP); }
"!="			{ yylval.terminal = "!="; count(); return (NE_OP); }
";"				{ yylval.terminal = ";"; count(); return (';'); }
("{"|"<%")		{ yylval.terminal = "{}"; count(); return ('{'); }
("}"|"%>")		{ yylval.terminal = NULL; count(); return ('}'); }
","				{ yylval.terminal = ","; count(); return (','); }
":"				{ yylval.terminal = ":"; count(); return (':'); }
"="				{ yylval.terminal = "="; count(); return ('='); }
"("				{ yylval.terminal = "("; count(); return ('('); }
")"				{ yylval.terminal = ")"; count(); return (')'); }
("["|"<:")		{ yylval.terminal = "[]"; count(); return ('['); }
("]"|":>")		{ yylval.terminal = NULL; count(); return (']'); }
"."				{ yylval.terminal = "."; count(); return ('.'); }
"&"				{ yylval.terminal = "&"; count(); return ('&'); }
"!"				{ yylval.terminal = "!"; count(); return ('!'); }
"~"				{ yylval.terminal = "~"; count(); return ('~'); }
"-"				{ yylval.terminal = "-"; count(); return ('-'); }
"+"				{ yylval.terminal = "+"; count(); return ('+'); }
"*"				{ yylval.terminal = "*"; count(); return ('*'); }
"/"				{ yylval.terminal = "/"; count(); return ('/'); }
"%"				{ yylval.terminal = "%"; count(); return ('%'); }
"<"				{ yylval.terminal = "<"; count(); return ('<'); }
">"				{ yylval.terminal = ">"; count(); return ('>'); }
"^"				{ yylval.terminal = "^"; count(); return ('^'); }
"|"				{ yylval.terminal = "|"; count(); return ('|'); }
"?"				{ yylval.terminal = "?"; count(); return ('?'); }

[ \t\v\n\f]		{ count(); }
.				{ count(); handle_bad_char(); }

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return input(); } // #define to function

void lexUnput(char c) { unput(c); } // #define to function

/* yywrap() { return 1; } */

// See main.c for this part
