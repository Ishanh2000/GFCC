// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
// Find "ASSUMPTION" to see all assumptions made.
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <cstring>
#include <cstdarg>

#include <gfcc_lexer.h>
#include <gfcc_tree.h>
#include <typo.h>
#include <parser.tab.h>

using namespace std;

node_t* node_t::ch (int i) {
	if ((!edges) || (i < 0) || (i >= numChild) || (!(edges[i]))) return NULL;
	return edges[i]->node;
}

ull_t newNode() {
	return ++currNumNodes;
}

node_t* Nd(int tok, const char* label, const char* attr, loc_t pos) {
	// label is lexeme. attr may be NULL.

	node_t *node = new node_t; if (!node) return NULL;

	node->id = newNode(); node->tok = tok;
	node->attr = attr; // no need to copy since not mutating (Heap | Read-Only)
	node->parent = NULL; node->edges = NULL; node->numChild = 0;

	// A STRING_LITERAL label will have "" included
	char * newlabel = strdup(label); // "label", in itself probabbly lies in read-only memory region.
	if (tok == STRING_LITERAL) { // assured that label lies in HEAP
		int end = 0; while (newlabel[end]) end++; newlabel[end - 1] = '\0'; // latter "
		newlabel += 1; // former "
	}
	node->label = newlabel;

	node->pos = pos; node->type = NULL;
	node->offset = 0;
	node->eval = "";

	return node;
}

node_t* nd(int tok, const char* label, loc_t pos) {
	return Nd(tok, label, NULL, pos); // CAUTION: See for "strdup".
}

edge_t* Ej(node_t* node, const char* label, const char* attr) {
	edge_t* e = new edge_t;
	if (!e) return NULL;
	e->node = node; e->label = label; e->attr = attr;
	return e;
}

edge_t* ej(node_t* child) {
	return Ej(child, NULL, NULL);
}

node_t* op(node_t *parent, int l, int r, ...) { // attr may be NULL
	if (!parent) return NULL;
	if ((l < 1) && (r < 1)) return parent; // nothing to do
	int curr = parent->numChild;
	edge_t **tmp = (edge_t**) malloc((curr + l + r) * sizeof(edge_t*));
	if (!tmp) return NULL; // is this bad? Should we print on STDOUT/STDERR? Or should we return (-1)?

	va_list args;
	va_start(args, r);

	// LEFT CHILDREN (TO BE APPENDED BEFORE THE PARENT'S EXISTING CHILDREN)
	for (int i = 0; i < l; i++) {
		edge_t *e = (edge_t*) va_arg(args, edge_t*); tmp[i] = e;
		if (e) e->node->parent = parent;
	}

	// PARENT'S OWN CHILDREN (ORDER PRESERVED)
	for (int i = 0; i < curr; i++) tmp[l + i] = parent->edges[i]; // copy current edges

	// RIGHT CHILDREN (TO BE APPENDED AFTER THE PARENT'S EXISTING CHILDREN)
	for (int i = l + curr; i < curr + l + r; i++) {
		edge_t *e = (edge_t*) va_arg(args, edge_t*); tmp[i] = e;
		if (e) e->node->parent = parent;
	}

	va_end(args);

	free(parent->edges);
	parent->edges = tmp;
	parent->numChild += (l + r);

	// update parent's compounded location
	node_t* firstChild = parent->ch(0);
	parent->pos.line = firstChild->pos.line; parent->pos.column = firstChild->pos.column;

	return parent;
}

void purgeAST(node_t *root) {
	if (!root) return;
	int numChild = root->numChild;
	for (int i = 0; i < numChild; i++) {
		purgeAST(root->ch(i));
		if (root->edges) delete root->edges[i];
	}
	delete root;
}

bool accept(node_t *node) {
	if (!node) return false;
	switch (node->tok) {
		case DECL_SPEC_LIST: return 0;
		case PARAM_TYPE_LIST: return 0;
		default: return 1;
	}
}

