// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
// Find "ASSUMPTION" to see all assumptions made.

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdarg>
#include <gfcc_lexer.h>
#include <gfcc_tree.h>
#include <typo.h>
#include <parser.tab.h>

ull_t newNode() {
	return ++currNumNodes;
}

node_t* Nd(int tok, const char* label, const char* attr, ull_t _enc, int _line, int _column) {
	// label is lexeme. attr may be NULL.
	
	node_t *node = (node_t*) malloc(sizeof(node_t)); if (!node) return NULL;

	node->id = newNode(); node->tok = tok;
	node->attr = attr; // no need to copy since not mutating (Heap | Read-Only)
	node->parent = NULL; node->edges = NULL; node->numChild = 0;

	// A STRING_LITERAL label will have "" included
	char * newlabel = strdup(label); // "label", in itself probabbly lies in read-only memory region.
	if (tok == STRING_LITERAL) { // assured that label lies in HEAP
		int end = 0; while(newlabel[end]) end++; newlabel[end - 1] = '\0'; // latter "
		newlabel += 1; // former "
	}
	node->label = newlabel;

	node->enc = _enc; node->line = _line; node->column = _column;

	return node;
}

node_t* nd(int tok, const char* label, ull_t _enc, int _line, int _column) {
	return Nd(tok, label, NULL, _enc, _line, _column); // CAUTION: See for "strdup".
}

edge_t* Ej(node_t* node, const char* label, const char* attr) {
	edge_t* e = (edge_t*) malloc(sizeof(edge_t));
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

	// TODO: some logical error here.
	if (l > 0) {
		node_t* firstChild = parent->edges[0]->node;
		// printf("%s: %d, %d\n", (parent->tok != RETURN) ? "-" : "RETURN", firstChild->line, firstChild->column);
		parent->line = firstChild->line; parent->column = firstChild->column;
	}

	return parent;
}

/*********************************************************************************************/
/******************************* PRINTING RELATED STUFF BEGINS *******************************/
/*********************************************************************************************/

ull_t q_head = 0, q_tail = 0;

int Enqueue(node_t* node) {
	if ( ((q_tail + 1) % (MAX_QUEUE_LENGTH + 1)) == q_head ) return -1;
	Q[q_tail++] = node;
	return 0;
}

node_t* Dequeue() {
	if (q_head == q_tail) return NULL; // empty queue
	node_t* tmp = Q[q_head];
	q_head = (q_head + 1) % (MAX_QUEUE_LENGTH + 1);
	return tmp;
}

int IsEmpty() {
	return (q_tail == q_head);
}

int accept(node_t *node) {
	switch (node->tok)
	{
		case DECL_SPEC_LIST: return 0;
		case PARAM_TYPE_LIST: return 0;
		default: 	return 1;
	}
}

void AstToDot(FILE *f_out, node_t *root) { // Do a DFS/BFS (BFS being done here)
	if (!root) {
		fprintf(f_out, "digraph {\n\t0 [label=\"%s (nothing useful)\",shape=none];\n}\n", fileName);
		return;
	}
	fprintf(f_out, "digraph {\n");
	dotNode(f_out, root); // prints file name
	Enqueue(root);

	while (!IsEmpty()) {
		node_t* curr = Dequeue(); // assume success
		char enforceOrder[300] = ""; int enforceLen = 0;

		for (int i = 0; i < curr->numChild; i++) {
			node_t* tmp_child = curr->edges[i]->node;
			if (accept(tmp_child)) {
				dotNode(f_out, tmp_child);
				dotEdge(f_out, curr, curr->edges[i]);
				Enqueue(tmp_child); // assume success

				char arr[30]; int len = 0; ull_t copy = tmp_child->id;
			        while (copy) { arr[len++] = (copy % 10) + '0'; copy /= 10; } // length found, arr[0 ... len-1] = reverse(child)
			        for (int j = len - 1; j >= 0; j--) enforceOrder[enforceLen++] = arr[j];
        			enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
        			enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';
			}
		}

		if (curr->numChild > 1) {
			enforceOrder[enforceLen - 4] = '\0';
			fprintf(f_out, "\t{ rank = same; %s [style = \"invis\"]; rankdir = LR; }\n", enforceOrder); // rank = same;
		}
	}

	fprintf(f_out, "}\n");
}
