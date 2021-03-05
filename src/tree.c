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

void dotNode(ull_t id, char* label) { // just a wrapper function
	fprintf(temp_out, "\t%lld [label = \"%s\"];\n", id, label);
}

void dotEdge(ull_t parent, ull_t child) { // just a wrapper function
	printf("HERE2 %lld, %lld\n", parent, child);
	fprintf(temp_out, "\t%lld -> %lld;\n", parent, child);
}

ull_t newNode() {
	return ++currNumNodes;
}

int nodeStackPush(ull_t nodeId) {
	if (nodeStackSize == MAX_PARSE_TREE_HEIGHT) return -1;
	nodeStack[nodeStackSize++] = nodeId;
	return 0;
}

ull_t nodeStackPop() {
	if (nodeStackSize) return nodeStack[--nodeStackSize];
	return 0; // 0 is not id for any node
}

ull_t nodeStackTop() {
	if (nodeStackSize) return nodeStack[nodeStackSize-1];
	return 0; // 0 is not id for any node
}

/** ACTION UPON SEEING A RULE (PSEUDO-CODE)
* parent = newNode()
* for childSymbol in { Cn, ..., C2, C1 }: // reverse order
*	child = newNode() IF child is ternminal, ELSE nodeStackPop()
* 	add edge (parent, child)
* nodeStackPush(parent)
*/
void takeAction(const char* str) { // input: parent{attr}|child_N{attr}| ... |child_2{attr}|child_1{attr}
    // use of strtok avoided - vanilla string manipulation is faster.
    int n = strlen(str);
    int start = 0, end = 0;
    int parent_seen = 0; ull_t parentId;
	char enforceOrder[2*n]; // to enforce order by introducing invisible edges (and maybe ranks later on).
	int enforceLen = 0;
	int numChild = 0;

    while (start < n) {
        while (str[end] && (str[end] != ' ')) end++;
        end--;
        
        // now concerned with str[start ... end] (both indices included)
		int sep = start; // index of separator
		while ((sep <= end) && str[sep] != '@') sep++;

		ull_t nodeId;
		// [THE FOLLOWING IF-THEN-ELSE STATEMENT ASSUMES THAT A NON-TERMINAL BEGINS WITH A SMALL ALPHABET]
		if (parent_seen && 'a' <= str[start] && str[start] <= 'z') nodeId = nodeStackPop(); // non-terminal symbol
		else nodeId = ++currNumNodes; // parent OR terminal child
        
		fprintf(temp_out, "\t%lld [label=\"", nodeId);
        for (int i = start; i <= sep - 1; i++) fputc(str[i], temp_out); // str[start ... (sep - 1)] is label (keep inside "")
		fprintf(temp_out, (sep > end) ? "\"" : "\",");
        for (int i = sep + 1; i <= end; i++) fputc(str[i], temp_out); // str[(sep + 1) ... end] are label and attributes
		fprintf(temp_out, "];\n");
        
		if (parent_seen) {
			char arr[25]; int l = 0;
			ull_t num = nodeId;
			while (num) { arr[l++] = (num % 10) + '0'; num /= 10; }
			for (int i = l-1; i >= 0; i--) enforceOrder[enforceLen++] = arr[i];
			enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
			enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';
			// add "nodeId -> " to enforceOrder
		}

		if (parent_seen) numChild++;

        if (!parent_seen) { parentId = nodeId; parent_seen = 1; }
		else fprintf(temp_out, "\t%lld -> %lld;\n", parentId, nodeId); // add edge from parent (parentId) to child (nodeId)

        end = start = end + 2;
    }

	nodeStackPush(parentId);

	// Assume that at least one child exists.
	// So, enforceOrder = "... xyz -> "
	// So, you can go back 3-4 indices successfully.
	if (numChild > 1) {
		enforceOrder[enforceLen - 4] = '\0';
		fprintf(temp_out, "\t{\n");
		fprintf(temp_out, "\t\trank = same;\n");
		fprintf(temp_out, "\t\t%s [style = \"invis\"];\n", enforceOrder);
		fprintf(temp_out, "\t\trankdir = RL;\n"); // right to left (adjusted experimentally)
		fprintf(temp_out, "\t}\n");
	}
}

void* makeLeaf(int tok_type, char* label, char* attr) { // label is lexeme. attr may be NULL.
	printf("makeLeaf: Received label = %s\n", label);
	node_t *leaf = (node_t*) malloc(sizeof(node_t));
	leaf->id = newNode(); leaf->tok_type = tok_type;
	// copying, since label == yytext, and contents of yytext change later.
	leaf->label = (char*) malloc(strlen(label) + 1); strcpy(leaf->label, label);
	leaf->parent = NULL; leaf->child = NULL;

	// A STRING_LITERAL label will have "" included
	if (tok_type == STRING_LITERAL) {
		int end = 0; while(label[end]) end++; label[end - 1] = '\0'; // latter "
		label += 1; // former "
	}

	fprintf(temp_out, "\t%lld [label=\"", leaf->id);
	if (tok_type == STRING_LITERAL) fprintf(temp_out, "\\\"%s\\\"", label); else fprintf(temp_out, "%s", label);
	if (attr) fprintf(temp_out, ",%s];\n", attr); else fprintf(temp_out, "\"];\n");

	return (void*) leaf;
}

void* makeOpNode(char* label, char* attr, ...) { // attr may be NULL
	node_t *opNode = (node_t*) malloc(sizeof(node_t));
    opNode->id = newNode(); opNode->parent = NULL; opNode->tok_type = -1;
	// not copying, since label is read-only area of memory [ASSUMPTION]
	opNode->label = label;

    fprintf(temp_out, "\t%lld [label=\"%s\"%s", opNode->id, label, attr ? "," : "];\n");
    if (attr) fprintf(temp_out, "%s];\n", attr);

    va_list args;
    node_t* child;
    // [ASSUMPTION] maximum children = 10, and each is not more than 30 chars long.
    char enforceOrder[300];
    int enforceLen = 0; int numChild = 0;
	node_t* children[10];

	va_start(args, attr);
    child = (node_t*) va_arg(args, void*);
    
	while (child) {
        children[numChild++] = child;

        fprintf(temp_out, "\t%lld -> %lld", opNode->id, child->id);
		
		char* edge_attr = va_arg(args, char*);
		if (edge_attr && edge_attr[0]) fprintf(temp_out, " [%s]", edge_attr);
		fprintf(temp_out, ";\n");
        
        char arr[30]; int l = 0; ull_t copy = child->id;
        while (copy) { arr[l++] = (copy % 10) + '0'; copy /= 10; } // length found, arr[0 ... l-1] = rev(child)
        for (int i = l-1; i >= 0; i--) enforceOrder[enforceLen++] = arr[i];
        enforceOrder[enforceLen++] = ' '; enforceOrder[enforceLen++] = '-';
        enforceOrder[enforceLen++] = '>'; enforceOrder[enforceLen++] = ' ';

        child = (node_t*) va_arg(args, void*);
    }

	va_end(args);

	if (numChild) {
		opNode->child = malloc(numChild * sizeof(node_t*));
		for (int i = 0; i < numChild; i++) opNode->child[i] = children[i];
	} else opNode->child = NULL;

    if (numChild > 1) { // at least two children required for enforcing "order".
        // enforceOrder = "... xyz -> " : Now use NULL just after "xyz"
        enforceOrder[enforceLen - 4] = '\0';
        fprintf(temp_out, "\t{\n");
		fprintf(temp_out, "\t\trank = same;\n");
		fprintf(temp_out, "\t\t%s [style = \"invis\"];\n", enforceOrder);
		fprintf(temp_out, "\t\trankdir = LR;\n"); // right to left (adjusted experimentally)
		fprintf(temp_out, "\t}\n");
    }

    return (void*) opNode;
}

// char* gfcc_strcat(char* a, ...) { // NULL OR 0 terminated
//     if (!a) return a;

//     int len_a = 0; while(a[len_a] != '\0') len_a++; // a[len_a] = '\0' now

//     va_list args;
//     va_start(args, a);
//     char* b = va_arg(args, char*);
//     while (b) {
//         int len_b = 0; while(b[len_b] != '\0') a[len_a++] = b[len_b++];
//         b = va_arg(args, char*);
//     }
//     va_end(args);
//     a[len_a] = '\0';
//     return a;
// }
