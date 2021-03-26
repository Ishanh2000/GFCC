D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <cstdio>
#include <parser.tab.h>
#include <gfcc_lexer.h>
// #include <symtab.h>

#ifdef COMPLETE
const char type_spec_attr[] = "style=filled,fillcolor=lightgreen,shape=diamond";
const char strg_class_attr[] = "style=filled,fillcolor=lightgreen,shape=diamond";
const char type_qual_attr[] = "style=filled,fillcolor=lightgreen,shape=diamond";
#else
const char *type_spec_attr = NULL;
const char *strg_class_attr = NULL;
const char *type_qual_attr = NULL;
#endif

const char return_attr[] = "style=filled,fillcolor=orange";

// type_specifier
#define void_b          0     // 0x00000001
#define char_b          1     // 0x00000002
#define short_b         2     // 0x00000004
#define int_b           3     // 0x00000008
#define long_b          4     // 0x00000010
#define float_b         5     // 0x00000020
#define double_b        6     // 0x00000040
#define signed_b        7     // 0x00000080
#define unsigned_b      8     // 0x00000100
#define file_b          9     // 0x00000200
#define typename_b     10     // 0x00000400

// const int *const
// const int **a[]

// type_qualifier
#define const_b        11     // 0x00000800
#define volatile_b     12     // 0x00001000

// storage_class_specifier
#define typedef_b      13     // 0x00002000
#define extern_b       14     // 0x00004000
#define static_b       15     // 0x00008000
#define auto_b         16     // 0x00010000
#define register_b     17     // 0x00020000

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"				{ comment(); }
"#"([^\n\0])*		{ count(); }

"auto"			{ count(); yylval.node = mkGenNode2(AUTO, "auto", strg_class_attr, 1 << short_b, token_line, token_column); return (AUTO); }

"break"			{ yylval.terminal = "break"; count(); return (BREAK); }

"case"			{ count(); yylval.node = mkGenNode2(CASE, "case", "style=filled,fillcolor=magenta", 0, token_line, token_column); return (CASE); }

"char"			{ count(); yylval.node = mkGenNode2(CHAR, "char", type_spec_attr, 1 << char_b, token_line, token_column); return (CHAR); }

"const"			{ count(); yylval.node = mkGenNode2(CONST, "const", type_qual_attr, 1 << const_b, token_line, token_column); return (CONST); }

"continue"		{ yylval.terminal = "continue"; count(); return (CONTINUE); }

"default"		{ count(); yylval.node = mkGenNode2(DEFAULT, "default", "style=filled,fillcolor=magenta", 0, token_line, token_column); return (DEFAULT); }

"do"			{ yylval.terminal = "do"; count(); return (DO); }

"double"		{ count(); yylval.node = mkGenNode2(DOUBLE, "double", type_spec_attr, 1 << double_b, token_line, token_column); return (DOUBLE); }

"else"			{ yylval.terminal = "else"; count(); return (ELSE); }

"enum"			{ yylval.terminal = "enum"; count(); return (ENUM); }

"extern"		{ count(); yylval.node = mkGenNode2(EXTERN, "extern", strg_class_attr, 1 << extern_b, token_line, token_column); return (EXTERN); }

"float"			{ count(); yylval.node = mkGenNode2(FLOAT, "float", type_spec_attr, 1 << float_b, token_line, token_column); return (FLOAT); }

"for"			{ yylval.terminal = "for"; count(); return (FOR); }

"FILE"			{ count(); yylval.node = mkGenNode2(FILE_OBJ, "FILE", type_spec_attr, 1 << file_b, token_line, token_column); return (FILE_OBJ); }

"goto"			{ yylval.terminal = "goto"; count(); return (GOTO); }

"if"			{ yylval.terminal = "if"; count(); return (IF); }

"int"			{ count(); yylval.node = mkGenNode2(INT, "int", type_spec_attr, 1 << int_b, token_line, token_column); return (INT); }

"long"			{ count(); yylval.node = mkGenNode2(LONG, "long", type_spec_attr, 1 << long_b, token_line, token_column); return (LONG); }

"register"		{ count(); yylval.node = mkGenNode2(REGISTER, "register", strg_class_attr, 1 << register_b, token_line, token_column); return (REGISTER); }

"return"		{ count(); yylval.node = mkGenNode2(RETURN, "return", return_attr, 0, token_line, token_column); return (RETURN); }

"short"			{ count(); yylval.node = mkGenNode2(SHORT, "short", type_spec_attr, 1 << short_b, token_line, token_column); return (SHORT); }

"signed"		{ count(); yylval.node = mkGenNode2(SIGNED, "signed", type_spec_attr, 1 << signed_b, token_line, token_column); return (SIGNED); }

"sizeof"		{ yylval.terminal = "sizeof"; count(); return (SIZEOF); }

"static"		{ count(); yylval.node = mkGenNode2(STATIC, "static", strg_class_attr, 1 << static_b, token_line, token_column); return (STATIC); }

"struct"		{ yylval.terminal = "struct"; count(); return (STRUCT); }

"switch"		{ yylval.terminal = "switch"; count(); return (SWITCH); }

"typedef"		{ count(); yylval.node = mkGenNode2(TYPEDEF, "typedef", strg_class_attr, 1 << typedef_b, token_line, token_column); return (TYPEDEF); }

"union"			{ yylval.terminal = "union"; count(); return (UNION); }

"unsigned"		{ count(); yylval.node = mkGenNode2(UNSIGNED, "unsigned", type_spec_attr, 1 << unsigned_b, token_line, token_column); return (UNSIGNED); }

"void"			{ count(); yylval.node = mkGenNode2(VOID, "void", type_spec_attr, 1 << void_b, token_line, token_column); return (VOID); }

"volatile"		{ count(); yylval.node = mkGenNode2(VOLATILE, "volatile", type_qual_attr, 1 << volatile_b, token_line, token_column); return (VOLATILE); }

"while"			{ yylval.terminal = "while"; count(); return (WHILE); }

{L}({L}|{D})*				{ count(); yylval.node = nd2(IDENTIFIER, strdup(yytext), 0, token_line, token_column); return (check_type()); /* returns IDENTIFIER */ }

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
"="				{ count(); yylval.node = nd2('=', "=", 0, token_line, token_column); return ('='); }
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

char lexInput() { return yyinput(); } // #define to function

void lexUnput(char c) { unput(c); } // #define to function

/* yywrap() { return 1; } */

// See main.c for this part
