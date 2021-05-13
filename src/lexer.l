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
#include <types2.h>
#include <typo.h>

using namespace std;

%}

%%

"//"([^\n\0])*		{ count(); }
"/*"				{ comment(); }
"#"([^\n\0])*		{ count(); }

"auto"			{ count(); yylval.node = Nd(AUTO, "auto", strg_class_attr, gpos); pushTok(gpos, AUTO, "auto"); return (AUTO); }

"break"			{ count(); yylval.node = Nd(BREAK, "break", jump_attr, gpos); pushTok(gpos, BREAK, "break"); return (BREAK); }

"case"			{ count(); yylval.node = Nd(CASE, "case", label_attr, gpos); pushTok(gpos, CASE, "case"); return (CASE); }

"char"			{ count(); yylval.node = Nd(CHAR, "char", type_spec_attr, gpos); pushTok(gpos, CHAR, "char"); return (CHAR); }

"const"			{ count(); yylval.node = Nd(CONST, "const", type_qual_attr, gpos); pushTok(gpos, CONST, "const"); return (CONST); }

"continue"		{ count(); yylval.node = Nd(CONTINUE, "continue", jump_attr, gpos); pushTok(gpos, CONTINUE, "continue"); return (CONTINUE); }

"default"		{ count(); yylval.node = Nd(DEFAULT, "default", label_attr, gpos); pushTok(gpos, DEFAULT, "default"); return (DEFAULT); }

"do"			{ count(); yylval.node = Nd(DO_WHILE, "do-while", iter_attr, gpos); pushTok(gpos, DO, "do"); return (DO); }

"double"		{ count(); yylval.node = Nd(DOUBLE, "double", type_spec_attr, gpos); pushTok(gpos, DOUBLE, "double"); return (DOUBLE); }

"else"			{ count(); yylval.node = Nd(IF_ELSE_STMT, "if-else-stmt", 0, gpos); pushTok(gpos, ELSE, "else"); return (ELSE); }

"enum"			{ count(); yylval.node = Nd(ENUM, "enum", type_spec_attr, gpos); pushTok(gpos, ENUM, "enum"); return (ENUM); }

"extern"		{ count(); yylval.node = Nd(EXTERN, "extern", strg_class_attr, gpos); pushTok(gpos, EXTERN, "extern"); return (EXTERN); }

"float"			{ count(); yylval.node = Nd(FLOAT, "float", type_spec_attr, gpos); pushTok(gpos, FLOAT, "float"); return (FLOAT); }

"for"			{ count(); yylval.node = Nd(FOR, "for", iter_attr, gpos); pushTok(gpos, FOR, "for"); return (FOR); }

"FILE"			{ count(); yylval.node = Nd(FILE_OBJ, "FILE", type_spec_attr, gpos); pushTok(gpos, FILE_OBJ, "FILE"); return (FILE_OBJ); }

"goto"			{ count(); yylval.node = Nd(GOTO, "goto", jump_attr, gpos); pushTok(gpos, GOTO, "goto"); return (GOTO); }

"if"			{ count(); yylval.node = Nd(IF_STMT, "if-stmt", select_attr, gpos); pushTok(gpos, IF, "if"); return (IF); }

"int"			{ count(); yylval.node = Nd(INT, "int", type_spec_attr, gpos); pushTok(gpos, INT, "int"); return (INT); }

"long"			{ count(); yylval.node = Nd(LONG, "long", type_spec_attr, gpos); pushTok(gpos, LONG, "long"); return (LONG); }

"register"		{ count(); yylval.node = Nd(REGISTER, "register", strg_class_attr, gpos); pushTok(gpos, REGISTER, "register"); return (REGISTER); }

"return"		{ count(); yylval.node = Nd(RETURN, "return", jump_attr, gpos); pushTok(gpos, RETURN, "return"); return (RETURN); }

"short"			{ count(); yylval.node = Nd(SHORT, "short", type_spec_attr, gpos); pushTok(gpos, SHORT, "short"); return (SHORT); }

"signed"		{ count(); yylval.node = Nd(SIGNED, "signed", type_spec_attr, gpos); pushTok(gpos, SIGNED, "signed"); return (SIGNED); }

"sizeof"		{ count(); yylval.node = Nd(SIZEOF, "sizeof", sizeof_attr, gpos); pushTok(gpos, SIZEOF, "sizeof"); return (SIZEOF); }

"static"		{ count(); yylval.node = Nd(STATIC, "static", strg_class_attr, gpos); pushTok(gpos, STATIC, "static"); return (STATIC); }

"struct"		{ count(); yylval.node = Nd(STRUCT, "struct", type_spec_attr, gpos); pushTok(gpos, STRUCT, "struct"); return (STRUCT); }

"switch"		{ count(); yylval.node = Nd(SWITCH, "switch", select_attr, gpos); pushTok(gpos, SWITCH, "switch"); return (SWITCH); }

"typedef"		{ count(); yylval.node = Nd(TYPEDEF, "typedef", strg_class_attr, gpos); pushTok(gpos, TYPEDEF, "typedef"); return (TYPEDEF); }

"union"			{ count(); yylval.node = Nd(UNION, "union", type_spec_attr, gpos); pushTok(gpos, UNION, "union"); return (UNION); }

"unsigned"		{ count(); yylval.node = Nd(UNSIGNED, "unsigned", type_spec_attr, gpos); pushTok(gpos, UNSIGNED, "unsigned"); return (UNSIGNED); }

"void"			{ count(); yylval.node = Nd(VOID, "void", type_spec_attr, gpos); pushTok(gpos, VOID, "void"); return (VOID); }

"volatile"		{ count(); yylval.node = Nd(VOLATILE, "volatile", type_qual_attr, gpos); pushTok(gpos, VOLATILE, "volatile"); return (VOLATILE); }

"while"			{ count(); yylval.node = Nd(WHILE, "while", iter_attr, gpos); pushTok(gpos, WHILE, "while"); return (WHILE); }

{L}({L}|{D})*	{ // IDENTIIFER / TYPE_NAME
    count();
    node_t *n = yylval.node = nd(IDENTIFIER, strdup(yytext), gpos);
    sym *ret = SymRoot->gLookup(n->label);
    if (ret && ret->type && (ret->type->strg == TYPEDEF_S)) {
        n->tok = TYPE_NAME;
        n->type = clone(ret->type);
        n->type->strg = NONE_S;
        pushTok(gpos, TYPE_NAME, yytext);
        return (TYPE_NAME);
    }
    pushTok(gpos, IDENTIFIER, yytext);
    return (IDENTIFIER);
}

0[xX]{H}+{IS}? { /* const int / const long */
    // count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Base *b = new Base(INT_B); b->isConst = true; n->type = b; return (CONSTANT);
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, false);
    Base *b = new Base(cp.isLong ? LONG_B : INT_B); b->sign = cp.isUnsigned ? UNSIGNED_X : SIGNED_X; b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

0{D}+{IS}? { /* const int / const long */
    // count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Base *b = new Base(INT_B); b->isConst = true; n->type = b; return (CONSTANT);
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, false);
    Base *b = new Base(cp.isLong ? LONG_B : INT_B); b->sign = cp.isUnsigned ? UNSIGNED_X : SIGNED_X; b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

{D}+{IS}? { /* const int / const long */
    // count(); node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos); Base *b = new Base(INT_B); b->isConst = true; n->type = b; return (CONSTANT);
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, false);
    Base *b = new Base(cp.isLong ? LONG_B : INT_B); b->sign = cp.isUnsigned ? UNSIGNED_X : SIGNED_X; b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

L?'(\\.|[^\\'])+'		{ // const char
    count();
    node_t* n = yylval.node = nd(CONSTANT, strdup(yytext), gpos);
    Base *b = new Base(CHAR_B); b->isConst = true; n->type = b;

    string s(yytext); int _f = s.find_first_of('\''), _l = s.find_last_of('\''); string ss = s.substr(_f + 1, _l - _f - 1);
    if ((ss[0] != '\\' && (ss.size() > 1)) || ((ss[0] == '\\') && (ss.size() > 2)))
        repErr(gpos, "warning: wide character encountered (will only consider first character)", _FORE_MAGENTA_);

    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
} 


{D}+{E}{FS}? { /* const double / const long double */
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, true);
    Base *b = new Base(cp.isLong ? DOUBLE_B : FLOAT_B); b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

{D}*"."{D}+({E})?{FS}? { /* const double / const long double */
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, true);
    Base *b = new Base(cp.isLong ? DOUBLE_B : FLOAT_B); b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

{D}+"."{D}*({E})?{FS}? { /* const double / const long double */
    count();
    char *lexstr = strdup(yytext);
    const_t cp = constParse(lexstr, true);
    Base *b = new Base(cp.isLong ? DOUBLE_B : FLOAT_B); b->isConst = true;
    node_t* n = yylval.node = nd(CONSTANT, lexstr, gpos);
    n->type = b; n->eval = cp.label;
    if (cp.multiWarn != "") repErr(gpos, "multiple incompatible specifications \"" + cp.multiWarn + "\" given for a constant", _FORE_RED_);
    else if (cp.limitWarn) repErr(gpos, "warning: value " + string(strdup(yytext)) + " too big to fit for " + str(b), _FORE_MAGENTA_);
    pushTok(gpos, CONSTANT, yytext);
    return (CONSTANT);
}

L?\"(\\.|[^\\"])*\"		{ // const char *
    count();
    node_t* n = yylval.node = nd(STRING_LITERAL, strdup(yytext), gpos);
    Base *b = new Base(CHAR_B); b->isConst = true; n->type = new Ptr(b);
    pushTok(gpos, STRING_LITERAL, yytext);
    return (STRING_LITERAL);
}


"..."			{ count(); yylval.node = nd(ELLIPSIS, "...", gpos); pushTok(gpos, ELLIPSIS, "..."); return (ELLIPSIS); }
">>="			{ count(); yylval.node = nd(RIGHT_ASSIGN, ">>=", gpos); pushTok(gpos, RIGHT_ASSIGN, ">>="); return (RIGHT_ASSIGN); }
"<<="			{ count(); yylval.node = nd(LEFT_ASSIGN, "<<=", gpos); pushTok(gpos, LEFT_ASSIGN, "<<="); return (LEFT_ASSIGN); }
"+="			{ count(); yylval.node = nd(ADD_ASSIGN, "+=", gpos); pushTok(gpos, ADD_ASSIGN, "+="); return (ADD_ASSIGN); }
"-="			{ count(); yylval.node = nd(SUB_ASSIGN, "-=", gpos); pushTok(gpos, SUB_ASSIGN, "-="); return (SUB_ASSIGN); }
"*="			{ count(); yylval.node = nd(MUL_ASSIGN, "*=", gpos); pushTok(gpos, MUL_ASSIGN, "*="); return (MUL_ASSIGN); }
"/="			{ count(); yylval.node = nd(DIV_ASSIGN, "/=", gpos); pushTok(gpos, DIV_ASSIGN, "/="); return (DIV_ASSIGN); }
"%="			{ count(); yylval.node = nd(MOD_ASSIGN, "%=", gpos); pushTok(gpos, MOD_ASSIGN, "%="); return (MOD_ASSIGN); }
"&="			{ count(); yylval.node = nd(AND_ASSIGN, "&=", gpos); pushTok(gpos, AND_ASSIGN, "&="); return (AND_ASSIGN); }
"^="			{ count(); yylval.node = nd(XOR_ASSIGN, "^=", gpos); pushTok(gpos, XOR_ASSIGN, "^="); return (XOR_ASSIGN); }
"|="			{ count(); yylval.node = nd(OR_ASSIGN, "|=", gpos); pushTok(gpos, OR_ASSIGN, "|="); return (OR_ASSIGN); }
">>"			{ count(); yylval.node = nd(RIGHT_OP, ">>", gpos); pushTok(gpos, RIGHT_OP, ">>"); return (RIGHT_OP); }
"<<"			{ count(); yylval.node = nd(LEFT_OP, "<<", gpos); pushTok(gpos, LEFT_OP, "<<"); return (LEFT_OP); }
"++"			{ count(); yylval.node = nd(INC_OP, "++", gpos); pushTok(gpos, INC_OP, "++"); return (INC_OP); }
"--"			{ count(); yylval.node = nd(DEC_OP, "--", gpos); pushTok(gpos, DEC_OP, "--"); return (DEC_OP); }
"->"			{ count(); yylval.node = nd(PTR_OP, "->", gpos); pushTok(gpos, PTR_OP, "->"); return (PTR_OP); }
"&&"			{ count(); yylval.node = nd(AND_OP, "&&", gpos); pushTok(gpos, AND_OP, "&&"); return (AND_OP); }
"||"			{ count(); yylval.node = nd(OR_OP, "||", gpos); pushTok(gpos, OR_OP, "||"); return (OR_OP); }
"<="			{ count(); yylval.node = nd(LE_OP, "<=", gpos); pushTok(gpos, LE_OP, "<="); return (LE_OP); }
">="			{ count(); yylval.node = nd(GE_OP, ">=", gpos); pushTok(gpos, GE_OP, ">="); return (GE_OP); }
"=="			{ count(); yylval.node = nd(EQ_OP, "==", gpos); pushTok(gpos, EQ_OP, "=="); return (EQ_OP); }
"!="			{ count(); yylval.node = nd(NE_OP, "!=", gpos); pushTok(gpos, NE_OP, "!="); return (NE_OP); }
";"				{ count(); yylval.node = Nd(';', "; [empty-stmt]", empty_attr, gpos); pushTok(gpos, ';', ";"); return (';'); }
("{"|"<%")		{ count(); yylval.node = Nd(EMPTY_BLOCK, "{ }", empty_attr, gpos); if (SymRoot) SymRoot->newScope(); pushTok(gpos, '{', "{"); return ('{'); }
("}"|"%>")		{ count(); yylval.node = NULL; /* NULL passed since '}' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ pushTok(gpos, '}', "}"); return ('}'); }
","				{ count(); yylval.node = nd(',', ",", gpos); pushTok(gpos, ',', ","); return (','); }
":"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ pushTok(gpos, ':', ":"); return (':'); }
"="				{ count(); yylval.node = nd('=', "=", gpos); pushTok(gpos, '=', "="); return ('='); }
"("				{ count(); yylval.node = nd('(', "()", gpos); /* Change 'tok' and 'label' depending upon context. */ pushTok(gpos, '(', "("); return ('('); }
")"				{ count(); yylval.node = NULL; /* NULL passed since ':' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ pushTok(gpos, ')', ")"); return (')'); }
("["|"<:")		{ count(); yylval.node = nd(SUBSCRIPT, "[]", gpos); pushTok(gpos, '[', "["); return ('['); }
("]"|":>")		{ count(); yylval.node = NULL; /* NULL passed since ']' is not useful to parser. BE CAREFUL WHEN PASSING NULL */ pushTok(gpos, ']', "]"); return (']'); }
"."				{ count(); yylval.node = nd('.', ".", gpos); pushTok(gpos, '.', "."); return ('.'); }
"&"				{ count(); yylval.node = nd('&', "&", gpos); pushTok(gpos, '&', "&"); return ('&'); }
"!"				{ count(); yylval.node = nd('!', "!", gpos); pushTok(gpos, '!', "!"); return ('!'); }
"~"				{ count(); yylval.node = nd('~', "~", gpos); pushTok(gpos, '~', "~"); return ('~'); }
"-"				{ count(); yylval.node = nd('-', "-", gpos); pushTok(gpos, '-', "-"); return ('-'); }
"+"				{ count(); yylval.node = nd('+', "+", gpos); pushTok(gpos, '+', "+"); return ('+'); }
"*"				{ count(); yylval.node = nd('*', "*", gpos); /* Change 'tok' to DEREF if used as pointer. */ pushTok(gpos, '*', "*"); return ('*'); }
"/"				{ count(); yylval.node = nd('/', "/", gpos); pushTok(gpos, '/', "/"); return ('/'); }
"%"				{ count(); yylval.node = nd('%', "%", gpos); pushTok(gpos, '%', "%"); return ('%'); }
"<"				{ count(); yylval.node = nd('<', "<", gpos); pushTok(gpos, '<', "<"); return ('<'); }
">"				{ count(); yylval.node = nd('>', ">", gpos); pushTok(gpos, '>', ">"); return ('>'); }
"^"				{ count(); yylval.node = nd('^', "^", gpos); pushTok(gpos, '^', "^"); return ('^'); }
"|"				{ count(); yylval.node = nd('|', "|", gpos); pushTok(gpos, '|', "|"); return ('|'); }
"?"				{ count(); yylval.node = nd(TERNARY_EXPR, "ternary expr (? :)", gpos); pushTok(gpos, '?', "?"); return ('?'); }

[ \t\v\n\f]		{ count(); }
.				{
    count();
    handle_bad_char();
    struct _token_t _tmp(gpos, 0, yytext); _tmp.bad = true;
    tokDump.push_back(_tmp);
}

%%

// SYMBOLS DEFINED BY FLEX/LEX USING #define HAVE BEEN PUT INSIDE A WRAPPER.
// SO FUNCTION-LIKE SYMBOL IS ACTUALLY A FUNCTION.

char lexInput() { return yyinput(); } // Transform #define to function

void lexUnput(char c) { unput(c); } // Transform #define to function

/* yywrap() { return 1; } */
