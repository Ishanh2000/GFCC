#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <gfcc_lexer.h>
#include <parser.tab.h>

// Find "ASSUMPTION" to see all assumptions made.

int yyerror(char *s) {
	fflush(stdout);
	printf("\n%*s\n%*s\n", column, "^", column, s);
}

void dotStmt(const char* format, ...) { // just a wrapper function
	va_list args;
	va_start(args, format);
	fprintf(temp_out, "\t");
	vfprintf(temp_out, format, args);
	fprintf(temp_out, ";\n");
	va_end(args);
}

void dotNode(node_t* node) {
	fprintf(temp_out, "\t%lld [label=\"", node->id);
	if (node->tok_type == STRING_LITERAL) fprintf(temp_out, "\\\"%s\\\"", node->label);
	else fprintf(temp_out, "%s", node->label);
	if (node->attr) fprintf(temp_out, ",%s];\n", node->attr);
	else fprintf(temp_out, "\"];\n");
}

void dotEdge(node_t* parent, edge_t* e) { // just a wrapper function
	fprintf(temp_out, "\t%lld -> %lld", parent->id, e->node->id);
	char *label = e->label, *attr = e->attr;
	
	if (label || attr) {
		fprintf(temp_out, " [");
		if (label) fprintf(temp_out, "label=\"%s\"", label);
		if (label && attr) fprintf(temp_out, ",");
		if (attr) fprintf(temp_out, "%s", attr);
		fprintf(temp_out, "]");
	}

	fprintf(temp_out, ";\n");
}

ull_t newNode() {
	return ++currNumNodes;
}

/** ACTION UPON SEEING A RULE (PSEUDO-CODE)
* parent = newNode()
* for childSymbol in { Cn, ..., C2, C1 }: // reverse order
*	child = newNode() IF child is ternminal, ELSE nodeStackPop()
* 	add edge (parent, child)
* nodeStackPush(parent)
*/

node_t* mkGenNode(int tok_type, char* label, char* attr) { // label is lexeme. attr may be NULL.
	node_t *node = (node_t*) malloc(sizeof(node_t)); if (!node) return NULL;
	
	node->id = newNode(); node->tok_type = tok_type;
	node->attr = attr; // no need to copy since not mutating (Heap | Read-Only)
	node->parent = NULL;
	node->edges = NULL;
	node->numChild = 0;

	// A STRING_LITERAL label will have "" included
	if (tok_type == STRING_LITERAL) { // assured that label lies in HEAP
		int end = 0; while(label[end]) end++; label[end - 1] = '\0'; // latter "
		label += 1; // former "
	}
	node->label = label; // no need to copy since not mutating (Heap | Read-Only)

	dotNode(node);

	return node;
}

node_t* mkNode(int tok_type, char* label) {
	return mkGenNode(tok_type, label, NULL);
}

node_t* (*nd)(int, char*) = mkNode; // short form

edge_t* mkGenEdge(node_t* node, char* label, char* attr) {
	edge_t* e = (edge_t*) malloc(sizeof(edge_t));
	if (!e) return NULL;
	e->node = node; e->label = label; e->attr = attr;
	return e;
}

edge_t* mkEdge(node_t* child) {
	return mkGenEdge(child, NULL, NULL);
}

edge_t* (*ej)(node_t*) = mkEdge;

node_t* mkOpNode(node_t *parent, int l, int r, ...) { // attr may be NULL
	if (!parent) return NULL;
	if (!(l || r)) return parent; // nothing to do
	int curr = parent->numChild;
	edge_t **tmp = (edge_t**) malloc((curr + l + r) * sizeof(edge_t*));
	if (!tmp) return NULL; // is this bad? Should we print on STDOUT/STDERR? Or should we return (-1)?

	char enforceOrder[300] = ""; int enforceLen = 0;

	va_list args;
	va_start(args, r);
	for (int i = 0; i < l; i++) {
		edge_t *e = (edge_t*) va_arg(args, edge_t*); tmp[i] = e;
		if (e) e->node->parent = parent;

		dotEdge(parent, e);
		
		char arr[30]; int len = 0; ull_t copy = e->node->id;
        while (copy) { arr[len++] = (copy % 10) + '0'; copy /= 10; } // length found, arr[0 ... len-1] = reverse(child)
        for (int j = len - 1; j >= 0; j--) enforceOrder[enforceLen++] = arr[j];
        enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
        enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';
	}

	if (l > 1) { // enforce order among left new children
		enforceOrder[enforceLen - 4] = '\0';
		fprintf(temp_out, "\t{ rank = same; %s [style = \"invis\"]; rankdir = LR; }\n", enforceOrder);
	}

	if (l && curr) fprintf(temp_out,
		"\t{ rank = same; %lld -> %lld [style = \"invis\"]; rankdir = LR; }\n",
		tmp[l-1]->node->id, parent->edges[0]->node->id
	); // enforce order between rightmost left new child and leftmost current child
	
	for (int i = 0; i < curr; i++) tmp[l + i] = parent->edges[i]; // copy current edges

	enforceOrder[0] = '\0'; enforceLen = 0;
	for (int i = l + curr; i < curr + l + r; i++) {
		edge_t *e = (edge_t*) va_arg(args, edge_t*); tmp[i] = e;
		if (e) e->node->parent = parent;

		dotEdge(parent, e);

		char arr[30]; int len = 0; ull_t copy = e->node->id;
        while (copy) { arr[len++] = (copy % 10) + '0'; copy /= 10; } // length found, arr[0 ... len-1] = reverse(child)
        for (int j = len - 1; j >= 0; j--) enforceOrder[enforceLen++] = arr[j];
        enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
        enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';
	}

	if (r > 1) { // enforce order among right new children
		enforceOrder[enforceLen - 4] = '\0';
		fprintf(temp_out, "\t{ rank = same; %s [style = \"invis\"]; rankdir = LR; }\n", enforceOrder);
	}

	if (curr && r) fprintf(temp_out,
		"\t{ rank = same; %lld -> %lld [style = \"invis\"]; rankdir = LR; }\n",
		tmp[l+curr]->node->id, parent->edges[curr-1]->node->id
	); // enforce order between leftmost right new child and rightmost current child
	
	va_end(args);
	
	free(parent->edges);
	parent->edges = tmp;
	parent->numChild += (l + r);

	return parent;
}

node_t* (*op)(node_t*, int, int, ...) = mkOpNode;
