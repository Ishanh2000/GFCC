// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************/
/***********************************************************************
 * This file is for stuff related to typography on the terminal. This
 * usually includes printing formatted errors, outputs, warnings, etc.
***********************************************************************/

#include <iostream>
#include <iomanip> // setw (set width) manipulation
#include <stdarg.h>
#include <parser.tab.h>
#include <gfcc_lexer.h>
#include <typo.h>

using namespace std;

msg::msg() { }

msg::msg(int _type) : msg_type(_type) { }

msg::~msg() {
    switch (msg_type) {
        case SUCC: cout << _C_BOLD_ << _FORE_GREEN_ << this->str() << _C_NONE_ << endl; break; // can use prefix "SUCCESS: "
        case WARN: cout << _C_BOLD_ << _FORE_YELLOW_ << "WARNING: " << this->str() << _C_NONE_ << endl; break;
        case ERR : cout << _C_BOLD_ << _FORE_RED_ << "ERROR: " << this->str() << _C_NONE_ << endl; break;
        default  : cout << this->str() << endl;
    }
}

int yyerror(const char *s) {
	// cout << fflush << endl;
	cout << _C_BOLD_ << "GFCC : " << fileName << ':' << gpos.line << ':' << gpos.column << ": ";
	cout << _FORE_RED_ << setw(column) << s << " [approx. positions indicated.]" << _C_NONE_ << endl;

	// Here, print from offsets[line-1] till '\n'
	in_file.seekg(offsets[gpos.line - 1]);
	string lineToPrint; getline(in_file, lineToPrint);
	cout << lineToPrint << endl;
	
	// Now, place the '^'. 
	cout << setw(column+1) << _C_BOLD_ << _FORE_RED_ << '^' << _C_NONE_ << endl;
	// confusion in computing column - ask TEAM

	return -1; // check this later on
}

void reportError(int _line, int _column, string str, const char* _color) { // very similar to yyerror
	// cout << fflush << endl;
	cout << _C_BOLD_ << "GFCC : " << fileName << ':' << _line << ':' << _column << ": ";
	cout << _color << setw(_column) << str << " [approx. positions indicated.]" << _C_NONE_ << endl;

	// Here, print from offsets[line-1] till '\n'
	in_file.seekg(offsets[_line - 1]);
	string lineToPrint; getline(in_file, lineToPrint);
	cout << lineToPrint << endl;
	
	// Now, place the '^'.
	cout << setw(_column) << _C_BOLD_ << _color << '^' << _C_NONE_ << endl;
}

void dotNode(ofstream &f, node_t* node) {
	if (!node) return;
	f << "\t" << node->id << " [label=\"";
	if (node->tok == STRING_LITERAL) f << "\\\"" << node->label << "\\\"";
	else f << node->label;
	f << "\\n[" << node->pos.line << ":" << node->pos.column << "]";
	if (node->attr) f << "\"," << node->attr << "];" << endl;
	else f << "\"];" << endl;
}

void dotEdge(ofstream &f, node_t* parent, edge_t* e) { // just a wrapper function
	if (!parent || !e || !(e->node)) return;
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

void AstToDot(ofstream &f, node_t *node) { // Do a DFS/BFS (DFS being done here)
	if (!node) return;
	dotNode(f, node); // print self
	int numChild = node->numChild;
	string enforcer;

	for (int i = 0; i < numChild; i++) {
		node_t* tmp_child = node->ch(i); // node's i-th child
		if (accept(tmp_child)) { // acceptable child
			// do not alter order of statements here.
			AstToDot(f, tmp_child); // DFS sub-call (build sub-tree with child as root, while enforcing order)
			dotEdge(f, node, node->edges[i]);
			enforcer += to_string(tmp_child->id) + " -> ";
		}
	}

	if (numChild > 1) {
		enforcer.erase(enforcer.find_last_of(" -> ") - 3);
		f << "\t{ rank = same; " << enforcer << " [style = \"invis\"]; rankdir = LR; }" << endl;
	}
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
