// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************/
/***********************************************************************
 * This file is for stuff related to typography on the terminal. This
 * usually includes printing formatted errors, outputs, warnings, etc.
***********************************************************************/

#include <iostream>
#include <stdarg.h>
#include <parser.tab.h>
#include <gfcc_lexer.h>
#include <typo.h>

using namespace std;

msg::msg() { }

msg::msg(int _type) : msg_type(_type) { }

msg::~msg() {
    switch (msg_type) {
        case SUCC: std::cout << _C_BOLD_ << _FORE_GREEN_ << this->str() << _C_NONE_ << std::endl; break; // can use prefix "SUCCESS: "
        case WARN: std::cout << _C_BOLD_ << _FORE_YELLOW_ << "WARNING: " << this->str() << _C_NONE_ << std::endl; break;
        case ERR : std::cout << _C_BOLD_ << _FORE_RED_ << "ERROR: " << this->str() << _C_NONE_ << std::endl; break;
        default  : std::cout << this->str() << std::endl;
    }
}

int yyerror(const char *s) {
	fflush(stdout);
	printf("\n%*s\n%d:%d:: %*s\n", column, "^", gpos.line, gpos.column, column, s);
	return -1; // check this later on
}

void dotNode(std::ofstream &f, node_t* node) {
	f << "\t" << node->id << " [label=\"";
	if (node->tok == STRING_LITERAL) f << "\\\"" << node->label << "\\\"";
	else f << node->label;
	f << "\\n[" << node->pos.line << ":" << node->pos.column << "]";
	if (node->attr) f << "\"," << node->attr << "];" << endl;
	else f << "\"];" << endl;
}

void dotEdge(std::ofstream &f, node_t* parent, edge_t* e) { // just a wrapper function
	f << "\t" << parent->id << " -> " << e->node->id;
	const char *label = e->label, *attr = e->attr;

	if (label || attr) {
		f << " [";
		if (label) f << "label=\"" << label << "\"";
		if (label && attr) f << ",";
		if (attr) f << attr;
		f << "]";
	}

	f << ";" << endl;
}

void lex_err(const char* format, ...) { // [Deprecated] printing errors
	va_list args;
	va_start(args, format);
	if (!temp_out) printf(_FORE_RED_);
	fprintf(temp_out ? temp_out : stdout, "ERROR: ");
	vfprintf(temp_out ? temp_out : stdout, format, args);
	if (!temp_out) printf(_C_NONE_);
	va_end(args);
}

void lex_warn(const char* format, ...) { // [Deprecated] printing warnings
	va_list args;
	va_start(args, format);
	if (!temp_out) printf(_FORE_YELLOW_);
	fprintf(temp_out ? temp_out : stdout, "WARNING: ");
	vfprintf(temp_out ? temp_out : stdout, format, args);
	if (!temp_out) printf(_C_NONE_);
	va_end(args);
}

#ifdef TEST_TYPO

int main() {
    msg() << "This " << "is " << "a " << "normal prompt!";
    msg(SUCC) << "This " << "is " << "a " << "success!";
    msg(WARN) << "This " << "is " << "a " << "warning!";
    msg(ERR) << "This " << "is " << "an " << "error!";
    string x = "string";
    const char y[] = "const char []";
    char z[] = "char []";
    msg(SUCC) << x << " OK";
    msg(SUCC) << y << " OK";
    msg(SUCC) << z << " OK";
    lex_err("This is an old style error, int = %d\n", 123);
    lex_warn("This is an old style warning, int = %d\n", 123);

    return 0;
}

#endif
