#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <gfcc_lexer.h>

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
