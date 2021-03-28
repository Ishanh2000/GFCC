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
#include <typo.h>

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

// compound data types
#define enum_b         18     // 0x00040000
#define union_b        19     // 0x00080000
#define struct_b       20     // 0x00100000

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"				{ comment(); }
"#"([^\n\0])*		{ count(); }

"auto"			{ count(); yylval.node = Nd(AUTO, "auto", strg_class_attr, 1 << short_b, gpos); return (AUTO); }

"break"			{ count(); yylval.node = Nd(BREAK, "break", jump_attr, 0, gpos); return (BREAK); }

"case"			{ count(); yylval.node = Nd(CASE, "case", label_attr, 0, gpos); return (CASE); }

"char"			{ count(); yylval.node = Nd(CHAR, "char", type_spec_attr, 1 << char_b, gpos); return (CHAR); }

"const"			{ count(); yylval.node = Nd(CONST, "const", type_qual_attr, 1 << const_b, gpos); return (CONST); }

"continue"		{ count(); yylval.node = Nd(CONTINUE, "continue", jump_attr, 0, gpos); return (CONTINUE); }

"default"		{ count(); yylval.node = Nd(DEFAULT, "default", label_attr, 0, gpos); return (DEFAULT); }

"do"			{ count(); yylval.node = Nd(DO_WHILE, "do-while", iter_attr, 0, gpos); return (DO); }

"double"		{ count(); yylval.node = Nd(DOUBLE, "double", type_spec_attr, 1 << double_b, gpos); return (DOUBLE); }

"else"			{ count(); yylval.node = Nd(IF_ELSE_STMT, "if-else-stmt", select_attr, 0, gpos); return (ELSE); }

"enum"			{ count(); yylval.node = Nd(ENUM, "enum", type_spec_attr, 1 << enum_b, gpos); return (ENUM); }

"extern"		{ count(); yylval.node = Nd(EXTERN, "extern", strg_class_attr, 1 << extern_b, gpos); return (EXTERN); }

"float"			{ count(); yylval.node = Nd(FLOAT, "float", type_spec_attr, 1 << float_b, gpos); return (FLOAT); }

"for"			{ count(); yylval.node = Nd(FOR, "for", iter_attr, 0, gpos); return (FOR); }

"FILE"			{ count(); yylval.node = Nd(FILE_OBJ, "FILE", type_spec_attr, 1 << file_b, gpos); return (FILE_OBJ); }

"goto"			{ count(); yylval.node = Nd(GOTO, "goto", jump_attr, 0, gpos); return (GOTO); }

"if"			{ count(); yylval.node = Nd(IF_STMT, "if-stmt", select_attr, 0, gpos); return (IF); }

"int"			{ count(); yylval.node = Nd(INT, "int", type_spec_attr, 1 << int_b, gpos); return (INT); }

"long"			{ count(); yylval.node = Nd(LONG, "long", type_spec_attr, 1 << long_b, gpos); return (LONG); }

"register"		{ count(); yylval.node = Nd(REGISTER, "register", strg_class_attr, 1 << register_b, gpos); return (REGISTER); }

"return"		{ count(); yylval.node = Nd(RETURN, "return", jump_attr, 0, gpos); return (RETURN); }

"short"			{ count(); yylval.node = Nd(SHORT, "short", type_spec_attr, 1 << short_b, gpos); return (SHORT); }

"signed"		{ count(); yylval.node = Nd(SIGNED, "signed", type_spec_attr, 1 << signed_b, gpos); return (SIGNED); }

"sizeof"		{ count(); yylval.node = Nd(SIZEOF, "sizeof", sizeof_attr, 0, gpos); return (SIZEOF); }

"static"		{ count(); yylval.node = Nd(STATIC, "static", strg_class_attr, 1 << static_b, gpos); return (STATIC); }

"struct"		{ count(); yylval.node = Nd(STRUCT, "struct", type_spec_attr, 1 << struct_b, gpos); return (STRUCT); }

"switch"		{ count(); yylval.node = Nd(SWITCH, "switch", select_attr, 0, gpos); return (SWITCH); }

"typedef"		{ count(); yylval.node = Nd(TYPEDEF, "typedef", strg_class_attr, 1 << typedef_b, gpos); return (TYPEDEF); }

"union"			{ count(); yylval.node = Nd(UNION, "union", type_spec_attr, 1 << union_b, gpos); return (UNION); }

"unsigned"		{ count(); yylval.node = Nd(UNSIGNED, "unsigned", type_spec_attr, 1 << unsigned_b, gpos); return (UNSIGNED); }

"void"			{ count(); yylval.node = Nd(VOID, "void", type_spec_attr, 1 << void_b, gpos); return (VOID); }

"volatile"		{ count(); yylval.node = Nd(VOLATILE, "volatile", type_qual_attr, 1 << volatile_b, gpos); return (VOLATILE); }

"while"			{ count(); yylval.node = Nd(WHILE, "while", iter_attr, 0, gpos); return (WHILE); }

{L}({L}|{D})*	{ count(); yylval.node = nd(IDENTIFIER, strdup(yytext), 0, gpos); return (check_type()); /* returns IDENTIFIER */ }


0[xX]{H}+{IS}?			{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), gpos); return (CONSTANT); }
0{D}+{IS}?				{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), gpos); return (CONSTANT); }
{D}+{IS}?				{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<int_b), gpos); return (CONSTANT); }
L?'(\\.|[^\\'])+'		{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<char_b), gpos); return (CONSTANT); }
{D}+{E}{FS}?			{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), gpos); return (CONSTANT); }
{D}*"."{D}+({E})?{FS}?	{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), gpos); return (CONSTANT); }
{D}+"."{D}*({E})?{FS}?	{ count(); yylval.node = nd(CONSTANT, strdup(yytext), (1<<const_b) | (1<<double_b), gpos); return (CONSTANT); }

L?\"(\\.|[^\\"])*\"		{ count(); yylval.node = nd(STRING_LITERAL, strdup(yytext), 0, gpos); return (STRING_LITERAL); /* TODO: const char * */ }

"..."			{ count(); yylval.node = nd(ELLIPSIS, "...", 0, gpos); return (ELLIPSIS); }
">>="			{ count(); yylval.node = nd(RIGHT_ASSIGN, ">>=", 0, gpos); return (RIGHT_ASSIGN); }
"<<="			{ count(); yylval.node = nd(LEFT_ASSIGN, "<<=", 0, gpos); return (LEFT_ASSIGN); }
"+="			{ count(); yylval.node = nd(ADD_ASSIGN, "+=", 0, gpos); return (ADD_ASSIGN); }
"-="			{ count(); yylval.node = nd(SUB_ASSIGN, "-=", 0, gpos); return (SUB_ASSIGN); }
"*="			{ count(); yylval.node = nd(MUL_ASSIGN, "*=", 0, gpos); return (MUL_ASSIGN); }
"/="			{ count(); yylval.node = nd(DIV_ASSIGN, "/=", 0, gpos); return (DIV_ASSIGN); }
"%="			{ count(); yylval.node = nd(MOD_ASSIGN, "%=", 0, gpos); return (MOD_ASSIGN); }
"&="			{ count(); yylval.node = nd(AND_ASSIGN, "&=", 0, gpos); return (AND_ASSIGN); }
"^="			{ count(); yylval.node = nd(XOR_ASSIGN, "^=", 0, gpos); return (XOR_ASSIGN); }
"|="			{ count(); yylval.node = nd(OR_ASSIGN, "|=", 0, gpos); return ( OR_ASSIGN); }
">>"			{ count(); yylval.node = nd(RIGHT_OP, ">>", 0, gpos); return (RIGHT_OP); }
"<<"			{ count(); yylval.node = nd(LEFT_OP, "<<", 0, gpos); return (LEFT_OP); }
"++"			{ count(); yylval.node = nd(INC_OP, "++", 0, gpos); return (INC_OP); }
"--"			{ count(); yylval.node = nd(DEC_OP, "--", 0, gpos); return (DEC_OP); }
"->"			{ count(); yylval.node = nd(PTR_OP, "->", 0, gpos); return (PTR_OP); }
"&&"			{ count(); yylval.node = nd(AND_OP, "&&", 0, gpos); return (AND_OP); }
"||"			{ count(); yylval.node = nd(OR_OP, "||", 0, gpos); return (OR_OP); }
"<="			{ count(); yylval.node = nd(LE_OP, "<=", 0, gpos); return (LE_OP); }
">="			{ count(); yylval.node = nd(GE_OP, ">=", 0, gpos); return (GE_OP); }
"=="			{ count(); yylval.node = nd(EQ_OP, "==", 0, gpos); return (EQ_OP); }
"!="			{ count(); yylval.node = nd(NE_OP, "!=", 0, gpos); return (NE_OP); }
";"				{ count(); yylval.node = Nd(';', "; [empty-stmt]", empty_attr, 0, gpos); return (';'); }
("{"|"<%")		{ count(); yylval.node = Nd(EMPTY_BLOCK, "{ }", empty_attr, 0, gpos); return ('{'); }
("}"|"%>")		{ count(); yylval.node = NULL; /* NULL passed since '}' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return ('}'); }
","				{ count(); yylval.node = nd(',', ",", 0, gpos); return (','); } //  TESTED OK
":"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (':'); }
"="				{ count(); yylval.node = nd('=', "=", 0, gpos); return ('='); }
"("				{ count(); yylval.node = nd('(', "()", 0, gpos); /* Change 'tok' and 'label' depending upon context. */ return ('('); }
")"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (')'); }
("["|"<:")		{ count(); yylval.node = nd(SUBSCRIPT, "[]", 0, gpos); return ('['); }
("]"|":>")		{ count(); yylval.node = NULL; /* NULL passed since ']' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (']'); }
"."				{ count(); yylval.node = nd('.', ".", 0, gpos); return ('.'); }
"&"				{ count(); yylval.node = nd('&', "&", 0, gpos); return ('&'); }
"!"				{ count(); yylval.node = nd('!', "!", 0, gpos); return ('!'); }
"~"				{ count(); yylval.node = nd('~', "~", 0, gpos); return ('~'); }
"-"				{ count(); yylval.node = nd('-', "-", 0, gpos); return ('-'); }
"+"				{ count(); yylval.node = nd('+', "+", 0, gpos); return ('+'); }
"*"				{ count(); yylval.node = nd('*', "*", 0, gpos); /* Change 'tok' to DEREF if used as pointer. */ return ('*'); }
"/"				{ count(); yylval.node = nd('/', "/", 0, gpos); return ('/'); }
"%"				{ count(); yylval.node = nd('%', "%", 0, gpos); return ('%'); }
"<"				{ count(); yylval.node = nd('<', "<", 0, gpos); return ('<'); }
">"				{ count(); yylval.node = nd('>', ">", 0, gpos); return ('>'); }
"^"				{ count(); yylval.node = nd('^', "^", 0, gpos); return ('^'); }
"|"				{ count(); yylval.node = nd('|', "|", 0, gpos); return ('|'); }
"?"				{ count(); yylval.node = nd(TERNARY_EXPR, "ternary expr (? :)", 0, gpos); return ('?'); }

[ \t\v\n\f]		{ count(); }
.				{ count(); handle_bad_char(); }

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return yyinput(); } // Transform #define to function

void lexUnput(char c) { unput(c); } // Transform #define to function

/* yywrap() { return 1; } */
