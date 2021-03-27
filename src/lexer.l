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

const char jump_attr[] = "style=filled,fillcolor=orange";
const char iter_attr[] = "style=filled,fillcolor=lightblue";
const char select_attr[] = "style=filled,fillcolor=yellow";
const char sizeof_attr[] = "style=filled,fillcolor=lightgreen";
const char empty_attr[] = "style=filled,fillcolor=gray"; // empty statment ';' / empty block '{}'

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

"break"			{ count(); yylval.node = mkGenNode2(BREAK, "break", jump_attr, 0, token_line, token_column); return (BREAK); }

"case"			{ count(); yylval.node = mkGenNode2(CASE, "case", "style=filled,fillcolor=magenta", 0, token_line, token_column); return (CASE); }

"char"			{ count(); yylval.node = mkGenNode2(CHAR, "char", type_spec_attr, 1 << char_b, token_line, token_column); return (CHAR); }

"const"			{ count(); yylval.node = mkGenNode2(CONST, "const", type_qual_attr, 1 << const_b, token_line, token_column); return (CONST); }

"continue"		{ count(); yylval.node = mkGenNode2(CONTINUE, "continue", jump_attr, 0, token_line, token_column); return (CONTINUE); }

"default"		{ count(); yylval.node = mkGenNode2(DEFAULT, "default", "style=filled,fillcolor=magenta", 0, token_line, token_column); return (DEFAULT); }

"do"			{ count(); yylval.node = mkGenNode2(DO_WHILE, "do-while", iter_attr, 0, token_line, token_column); return (DO); }

"double"		{ count(); yylval.node = mkGenNode2(DOUBLE, "double", type_spec_attr, 1 << double_b, token_line, token_column); return (DOUBLE); }

"else"			{ count(); yylval.node = mkGenNode2(IF_ELSE_STMT, "if-else-stmt", select_attr, 0, token_line, token_column); return (ELSE); }

"enum"			{ yylval.terminal = "enum"; count(); return (ENUM); }

"extern"		{ count(); yylval.node = mkGenNode2(EXTERN, "extern", strg_class_attr, 1 << extern_b, token_line, token_column); return (EXTERN); }

"float"			{ count(); yylval.node = mkGenNode2(FLOAT, "float", type_spec_attr, 1 << float_b, token_line, token_column); return (FLOAT); }

"for"			{ count(); yylval.node = mkGenNode2(FOR, "for", iter_attr, 0, token_line, token_column); return (FOR); }

"FILE"			{ count(); yylval.node = mkGenNode2(FILE_OBJ, "FILE", type_spec_attr, 1 << file_b, token_line, token_column); return (FILE_OBJ); }

"goto"			{ count(); yylval.node = mkGenNode2(GOTO, "goto", jump_attr, 0, token_line, token_column); return (GOTO); }

"if"			{ count(); yylval.node = mkGenNode2(IF_STMT, "if-stmt", select_attr, 0, token_line, token_column); return (IF); }

"int"			{ count(); yylval.node = mkGenNode2(INT, "int", type_spec_attr, 1 << int_b, token_line, token_column); return (INT); }

"long"			{ count(); yylval.node = mkGenNode2(LONG, "long", type_spec_attr, 1 << long_b, token_line, token_column); return (LONG); }

"register"		{ count(); yylval.node = mkGenNode2(REGISTER, "register", strg_class_attr, 1 << register_b, token_line, token_column); return (REGISTER); }

"return"		{ count(); yylval.node = mkGenNode2(RETURN, "return", jump_attr, 0, token_line, token_column); return (RETURN); }

"short"			{ count(); yylval.node = mkGenNode2(SHORT, "short", type_spec_attr, 1 << short_b, token_line, token_column); return (SHORT); }

"signed"		{ count(); yylval.node = mkGenNode2(SIGNED, "signed", type_spec_attr, 1 << signed_b, token_line, token_column); return (SIGNED); }

"sizeof"		{ count(); yylval.node = mkGenNode2(SIZEOF, "sizeof", sizeof_attr, 0, token_line, token_column); return (SIZEOF); }

"static"		{ count(); yylval.node = mkGenNode2(STATIC, "static", strg_class_attr, 1 << static_b, token_line, token_column); return (STATIC); }

"struct"		{ yylval.terminal = "struct"; count(); return (STRUCT); }

"switch"		{ count(); yylval.node = mkGenNode2(SWITCH, "switch", select_attr, 0, token_line, token_column); return (SWITCH); }

"typedef"		{ count(); yylval.node = mkGenNode2(TYPEDEF, "typedef", strg_class_attr, 1 << typedef_b, token_line, token_column); return (TYPEDEF); }

"union"			{ yylval.terminal = "union"; count(); return (UNION); }

"unsigned"		{ count(); yylval.node = mkGenNode2(UNSIGNED, "unsigned", type_spec_attr, 1 << unsigned_b, token_line, token_column); return (UNSIGNED); }

"void"			{ count(); yylval.node = mkGenNode2(VOID, "void", type_spec_attr, 1 << void_b, token_line, token_column); return (VOID); }

"volatile"		{ count(); yylval.node = mkGenNode2(VOLATILE, "volatile", type_qual_attr, 1 << volatile_b, token_line, token_column); return (VOLATILE); }

"while"			{ count(); yylval.node = mkGenNode2(WHILE, "while", iter_attr, 0, token_line, token_column); return (WHILE); }

{L}({L}|{D})*	{ count(); yylval.node = nd2(IDENTIFIER, strdup(yytext), 0, token_line, token_column); return (check_type()); /* returns IDENTIFIER */ }


0[xX]{H}+{IS}?			{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), token_line, token_column); return (CONSTANT); }
0{D}+{IS}?				{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), token_line, token_column); return (CONSTANT); }
{D}+{IS}?				{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), token_line, token_column); return (CONSTANT); }
L?'(\\.|[^\\'])+'		{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<char_b), token_line, token_column); return (CONSTANT); }
{D}+{E}{FS}?			{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), token_line, token_column); return (CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), token_line, token_column); return (CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ count(); yylval.node = nd2(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), token_line, token_column); return (CONSTANT); }

L?\"(\\.|[^\\"])*\"		{ count(); yylval.node = nd2(STRING_LITERAL, strdup(yytext), 0, token_line, token_column); return (STRING_LITERAL); /* TODO: const char * */ }

"..."			{ count(); yylval.node = nd2(ELLIPSIS, "...", 0, token_line, token_column); return (ELLIPSIS); }
">>="			{ count(); yylval.node = nd2(RIGHT_ASSIGN, ">>=", 0, token_line, token_column); return (RIGHT_ASSIGN); }
"<<="			{ count(); yylval.node = nd2(LEFT_ASSIGN, "<<=", 0, token_line, token_column); return (LEFT_ASSIGN); }
"+="			{ count(); yylval.node = nd2(ADD_ASSIGN, "+=", 0, token_line, token_column); return (ADD_ASSIGN); }
"-="			{ count(); yylval.node = nd2(SUB_ASSIGN, "-=", 0, token_line, token_column); return (SUB_ASSIGN); }
"*="			{ count(); yylval.node = nd2(MUL_ASSIGN, "*=", 0, token_line, token_column); return (MUL_ASSIGN); }
"/="			{ count(); yylval.node = nd2(DIV_ASSIGN, "/=", 0, token_line, token_column); return (DIV_ASSIGN); }
"%="			{ count(); yylval.node = nd2(MOD_ASSIGN, "%=", 0, token_line, token_column); return (MOD_ASSIGN); }
"&="			{ count(); yylval.node = nd2(AND_ASSIGN, "&=", 0, token_line, token_column); return (AND_ASSIGN); }
"^="			{ count(); yylval.node = nd2(XOR_ASSIGN, "^=", 0, token_line, token_column); return (XOR_ASSIGN); }
"|="			{ count(); yylval.node = nd2(OR_ASSIGN, "|=", 0, token_line, token_column); return ( OR_ASSIGN); }
">>"			{ count(); yylval.node = nd2(RIGHT_OP, ">>", 0, token_line, token_column); return (RIGHT_OP); }
"<<"			{ count(); yylval.node = nd2(LEFT_OP, "<<", 0, token_line, token_column); return (LEFT_OP); }
"++"			{ count(); yylval.node = nd2(INC_OP, "++", 0, token_line, token_column); return (INC_OP); }
"--"			{ count(); yylval.node = nd2(DEC_OP, "--", 0, token_line, token_column); return (DEC_OP); }
"->"			{ count(); yylval.node = nd2(PTR_OP, "->", 0, token_line, token_column); return (PTR_OP); }
"&&"			{ count(); yylval.node = nd2(AND_OP, "&&", 0, token_line, token_column); return (AND_OP); }
"||"			{ count(); yylval.node = nd2(OR_OP, "||", 0, token_line, token_column); return (OR_OP); }
"<="			{ count(); yylval.node = nd2(LE_OP, "<=", 0, token_line, token_column); return (LE_OP); }
">="			{ count(); yylval.node = nd2(GE_OP, ">=", 0, token_line, token_column); return (GE_OP); }
"=="			{ count(); yylval.node = nd2(EQ_OP, "==", 0, token_line, token_column); return (EQ_OP); }
"!="			{ count(); yylval.node = nd2(NE_OP, "!=", 0, token_line, token_column); return (NE_OP); }

";"				{ count(); yylval.node = mkGenNode2(';', "; [empty-stmt]", empty_attr, 0, token_line, token_column); return (';'); } // TESTED OK
("{"|"<%")		{ count(); yylval.node = mkGenNode2(EMPTY_BLOCK, "{ }", empty_attr, 0, token_line, token_column); return ('{'); } // TESTED OK
("}"|"%>")		{ count(); yylval.node = NULL; /* NULL passed since '}' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return ('}'); } // TESTED OK
","				{ count(); yylval.node = nd2(',', ",", 0, token_line, token_column); return (','); } //  TESTED OK
":"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (':'); } // TESTED OK
"="				{ count(); yylval.node = nd2('=', "=", 0, token_line, token_column); return ('='); } // TESTED OK
"("				{ count(); yylval.node = nd2('(', "()", 0, token_line, token_column); /* Change 'tok_type' and 'label' depending upon context. */ return ('('); } // TESTED OK
")"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (')'); } // TESTED OK
("["|"<:")		{ count(); yylval.node = nd2(SUBSCRIPT, "[]", 0, token_line, token_column); return ('['); } // TESTED OK
("]"|":>")		{ count(); yylval.node = NULL; /* NULL passed since ']' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (']'); } // TESTED OK
"."				{ count(); yylval.node = nd2('.', ".", 0, token_line, token_column); return ('.'); } // TESTED OK
"&"				{ count(); yylval.node = nd2('&', "&", 0, token_line, token_column); return ('&'); } // TESTED OK
"!"				{ count(); yylval.node = nd2('!', "!", 0, token_line, token_column); return ('!'); } // TESTED OK
"~"				{ count(); yylval.node = nd2('~', "~", 0, token_line, token_column); return ('~'); } // TESTED OK
"-"				{ count(); yylval.node = nd2('-', "-", 0, token_line, token_column); return ('-'); } // TESTED OK
"+"				{ count(); yylval.node = nd2('+', "+", 0, token_line, token_column); return ('+'); } // TESTED OK
"*"				{ count(); yylval.node = nd2('*', "*", 0, token_line, token_column); /* Change 'tok_type' to DEREF if used as pointer. */ return ('*'); } // TESTED OK
"/"				{ count(); yylval.node = nd2('/', "/", 0, token_line, token_column); return ('/'); } // TESTED OK
"%"				{ count(); yylval.node = nd2('%', "%", 0, token_line, token_column); return ('%'); } // TESTED OK
"<"				{ count(); yylval.node = nd2('<', "<", 0, token_line, token_column); return ('<'); } // TESTED OK
">"				{ count(); yylval.node = nd2('>', ">", 0, token_line, token_column); return ('>'); } // TESTED OK
"^"				{ count(); yylval.node = nd2('^', "^", 0, token_line, token_column); return ('^'); } // TESTED OK
"|"				{ count(); yylval.node = nd2('|', "|", 0, token_line, token_column); return ('|'); } // TESTED OK
"?"				{ count(); yylval.node = nd2(TERNARY_EXPR, "ternary expr (? :)", 0, token_line, token_column); return ('?'); } // TESTED OK

[ \t\v\n\f]		{ count(); }
.				{ count(); handle_bad_char(); }

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return yyinput(); } // #define to function

void lexUnput(char c) { unput(c); } // #define to function

/* yywrap() { return 1; } */

// See main.c for this part
