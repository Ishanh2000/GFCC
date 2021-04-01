D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{

#include <iostream>
#include <cstdio>


#include <parser.tab.h>
#include <gfcc_lexer.h>
#include <symtab.h>
#include <types.h>
#include <typo.h>

using namespace std;

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"				{ comment(); }
"#"([^\n\0])*		{ count(); }

"auto"			{ count(); yylval.node = Nd(AUTO, "auto", strg_class_attr, gpos); return (AUTO); }

"break"			{ count(); yylval.node = Nd(BREAK, "break", jump_attr, gpos); return (BREAK); }

"case"			{ count(); yylval.node = Nd(CASE, "case", label_attr, gpos); return (CASE); }

"char"			{ count(); yylval.node = Nd(CHAR, "char", type_spec_attr, gpos); return (CHAR); }

"const"			{ count(); yylval.node = Nd(CONST, "const", type_qual_attr, gpos); return (CONST); }

"continue"		{ count(); yylval.node = Nd(CONTINUE, "continue", jump_attr, gpos); return (CONTINUE); }

"default"		{ count(); yylval.node = Nd(DEFAULT, "default", label_attr, gpos); return (DEFAULT); }

"do"			{ count(); yylval.node = Nd(DO_WHILE, "do-while", iter_attr, gpos); return (DO); }

"double"		{ count(); yylval.node = Nd(DOUBLE, "double", type_spec_attr, gpos); return (DOUBLE); }

"else"			{ count(); yylval.node = Nd(IF_ELSE_STMT, "if-else-stmt", 0, gpos); return (ELSE); }

"enum"			{ count(); yylval.node = Nd(ENUM, "enum", type_spec_attr, gpos); return (ENUM); }

"extern"		{ count(); yylval.node = Nd(EXTERN, "extern", strg_class_attr, gpos); return (EXTERN); }

"float"			{ count(); yylval.node = Nd(FLOAT, "float", type_spec_attr, gpos); return (FLOAT); }

"for"			{ count(); yylval.node = Nd(FOR, "for", iter_attr, gpos); return (FOR); }

"FILE"			{ count(); yylval.node = Nd(FILE_OBJ, "FILE", type_spec_attr, gpos); return (FILE_OBJ); }

"goto"			{ count(); yylval.node = Nd(GOTO, "goto", jump_attr, gpos); return (GOTO); }

"if"			{ count(); yylval.node = Nd(IF_STMT, "if-stmt", select_attr, gpos); return (IF); }

"int"			{ count(); yylval.node = Nd(INT, "int", type_spec_attr, gpos); return (INT); }

"long"			{ count(); yylval.node = Nd(LONG, "long", type_spec_attr, gpos); return (LONG); }

"register"		{ count(); yylval.node = Nd(REGISTER, "register", strg_class_attr, gpos); return (REGISTER); }

"return"		{ count(); yylval.node = Nd(RETURN, "return", jump_attr, gpos); return (RETURN); }

"short"			{ count(); yylval.node = Nd(SHORT, "short", type_spec_attr, gpos); return (SHORT); }

"signed"		{ count(); yylval.node = Nd(SIGNED, "signed", type_spec_attr, gpos); return (SIGNED); }

"sizeof"		{ count(); yylval.node = Nd(SIZEOF, "sizeof", sizeof_attr, gpos); return (SIZEOF); }

"static"		{ count(); yylval.node = Nd(STATIC, "static", strg_class_attr, gpos); return (STATIC); }

"struct"		{ count(); yylval.node = Nd(STRUCT, "struct", type_spec_attr, gpos); return (STRUCT); }

"switch"		{ count(); yylval.node = Nd(SWITCH, "switch", select_attr, gpos); return (SWITCH); }

"typedef"		{ count(); yylval.node = Nd(TYPEDEF, "typedef", strg_class_attr, gpos); return (TYPEDEF); }

"union"			{ count(); yylval.node = Nd(UNION, "union", type_spec_attr, gpos); return (UNION); }

"unsigned"		{ count(); yylval.node = Nd(UNSIGNED, "unsigned", type_spec_attr, gpos); return (UNSIGNED); }

"void"			{ count(); yylval.node = Nd(VOID, "void", type_spec_attr, gpos); return (VOID); }

"volatile"		{ count(); yylval.node = Nd(VOLATILE, "volatile", type_qual_attr, gpos); return (VOLATILE); }

"while"			{ count(); yylval.node = Nd(WHILE, "while", iter_attr, gpos); return (WHILE); }

{L}({L}|{D})*	{ count(); yylval.node = nd(IDENTIFIER, strdup(yytext), gpos); return (check_type()); /* returns IDENTIFIER */ }


0[xX]{H}+{IS}?			{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = INT_B; tp->qual.isConst = true; return (CONSTANT); } // const int / const long
0{D}+{IS}?				{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = INT_B; tp->qual.isConst = true; return (CONSTANT); } // const int / const long
{D}+{IS}?				{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = INT_B; tp->qual.isConst = true; return (CONSTANT); } // const int / const long
L?'(\\.|[^\\'])+'		{ // const char
    count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = CHAR_B; tp->qual.isConst = true;
    string s(yytext); int _f = s.find_first_of('\''), _l = s.find_last_of('\''); string ss = s.substr(_f + 1, _l - _f - 1);
    if ((ss[0] != '\\' && (ss.size() > 1)) || ((ss[0] == '\\') && (ss.size() > 2)))
        repErr(gpos, "warning: wide character encountered (will only consider first character)", _FORE_MAGENTA_);
    return (CONSTANT);
} 
{D}+{E}{FS}?			{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = DOUBLE_B; tp->qual.isConst = true; return (CONSTANT); } // const double / const long double
{D}*"."{D}+({E})?{FS}?	{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = DOUBLE_B; tp->qual.isConst = true; return (CONSTANT); } // const double / const long double
{D}+"."{D}*({E})?{FS}?	{ count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = DOUBLE_B; tp->qual.isConst = true; return (CONSTANT); } // const double / const long double

L?\"(\\.|[^\\"])*\"		{ count(); node_t* n = yylval.node = nd(STRING_LITERAL, strdup(yytext), gpos); Type* tp = n->type = new Type(); tp->base = CHAR_B; tp->qual.isConst = true; tp->ptrs.push_back(qual_t()); return (STRING_LITERAL); } // const char *

"..."			{ count(); yylval.node = nd(ELLIPSIS, "...", gpos); return (ELLIPSIS); }
">>="			{ count(); yylval.node = nd(RIGHT_ASSIGN, ">>=", gpos); return (RIGHT_ASSIGN); }
"<<="			{ count(); yylval.node = nd(LEFT_ASSIGN, "<<=", gpos); return (LEFT_ASSIGN); }
"+="			{ count(); yylval.node = nd(ADD_ASSIGN, "+=", gpos); return (ADD_ASSIGN); }
"-="			{ count(); yylval.node = nd(SUB_ASSIGN, "-=", gpos); return (SUB_ASSIGN); }
"*="			{ count(); yylval.node = nd(MUL_ASSIGN, "*=", gpos); return (MUL_ASSIGN); }
"/="			{ count(); yylval.node = nd(DIV_ASSIGN, "/=", gpos); return (DIV_ASSIGN); }
"%="			{ count(); yylval.node = nd(MOD_ASSIGN, "%=", gpos); return (MOD_ASSIGN); }
"&="			{ count(); yylval.node = nd(AND_ASSIGN, "&=", gpos); return (AND_ASSIGN); }
"^="			{ count(); yylval.node = nd(XOR_ASSIGN, "^=", gpos); return (XOR_ASSIGN); }
"|="			{ count(); yylval.node = nd(OR_ASSIGN, "|=", gpos); return ( OR_ASSIGN); }
">>"			{ count(); yylval.node = nd(RIGHT_OP, ">>", gpos); return (RIGHT_OP); }
"<<"			{ count(); yylval.node = nd(LEFT_OP, "<<", gpos); return (LEFT_OP); }
"++"			{ count(); yylval.node = nd(INC_OP, "++", gpos); return (INC_OP); }
"--"			{ count(); yylval.node = nd(DEC_OP, "--", gpos); return (DEC_OP); }
"->"			{ count(); yylval.node = nd(PTR_OP, "->", gpos); return (PTR_OP); }
"&&"			{ count(); yylval.node = nd(AND_OP, "&&", gpos); return (AND_OP); }
"||"			{ count(); yylval.node = nd(OR_OP, "||", gpos); return (OR_OP); }
"<="			{ count(); yylval.node = nd(LE_OP, "<=", gpos); return (LE_OP); }
">="			{ count(); yylval.node = nd(GE_OP, ">=", gpos); return (GE_OP); }
"=="			{ count(); yylval.node = nd(EQ_OP, "==", gpos); return (EQ_OP); }
"!="			{ count(); yylval.node = nd(NE_OP, "!=", gpos); return (NE_OP); }
";"				{ count(); yylval.node = Nd(';', "; [empty-stmt]", empty_attr, gpos); return (';'); }
("{"|"<%")		{ count(); yylval.node = Nd(EMPTY_BLOCK, "{ }", empty_attr, gpos); if (SymRoot) SymRoot->newScope(); return ('{'); }
("}"|"%>")		{ count(); yylval.node = NULL; /* NULL passed since '}' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return ('}'); }
","				{ count(); yylval.node = nd(',', ",", gpos); return (','); } //  TESTED OK
":"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (':'); }
"="				{ count(); yylval.node = nd('=', "=", gpos); return ('='); }
"("				{ count(); yylval.node = nd('(', "()", gpos); /* Change 'tok' and 'label' depending upon context. */ return ('('); }
")"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (')'); }
("["|"<:")		{ count(); yylval.node = nd(SUBSCRIPT, "[]", gpos); return ('['); }
("]"|":>")		{ count(); yylval.node = NULL; /* NULL passed since ']' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ return (']'); }
"."				{ count(); yylval.node = nd('.', ".", gpos); return ('.'); }
"&"				{ count(); yylval.node = nd('&', "&", gpos); return ('&'); }
"!"				{ count(); yylval.node = nd('!', "!", gpos); return ('!'); }
"~"				{ count(); yylval.node = nd('~', "~", gpos); return ('~'); }
"-"				{ count(); yylval.node = nd('-', "-", gpos); return ('-'); }
"+"				{ count(); yylval.node = nd('+', "+", gpos); return ('+'); }
"*"				{ count(); yylval.node = nd('*', "*", gpos); /* Change 'tok' to DEREF if used as pointer. */ return ('*'); }
"/"				{ count(); yylval.node = nd('/', "/", gpos); return ('/'); }
"%"				{ count(); yylval.node = nd('%', "%", gpos); return ('%'); }
"<"				{ count(); yylval.node = nd('<', "<", gpos); return ('<'); }
">"				{ count(); yylval.node = nd('>', ">", gpos); return ('>'); }
"^"				{ count(); yylval.node = nd('^', "^", gpos); return ('^'); }
"|"				{ count(); yylval.node = nd('|', "|", gpos); return ('|'); }
"?"				{ count(); yylval.node = nd(TERNARY_EXPR, "ternary expr (? :)", gpos); return ('?'); }

[ \t\v\n\f]		{ count(); }
.				{ count(); handle_bad_char(); }

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return yyinput(); } // Transform #define to function

void lexUnput(char c) { unput(c); } // Transform #define to function

/* yywrap() { return 1; } */
