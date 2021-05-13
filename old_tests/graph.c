#include <g5_typo.h>
#include <g5_std.h>
#include <g5_string.h>

// matrix representation

struct _vtx_t {
	char color; // 'w' = unvisited, 'g' = visiting, 'b' = visited
	int nbrs[100]; // neighbours (matrix representation)
};

struct _graph_t {
  int N; // total vertices
	struct _vtx_t *vts; // vertices
};

void unVisitGraph(struct _graph_t *G) {
	int i;
	for (i = 0; i < G->N; i++)	G->vts->color = 'w';
	g5_printf("  ... Graph Unvisited.\n");
}

void insertEdge(struct _graph_t *G, int x, int y) { // x to y
	G->vts[x-1].nbrs[y-1] = 1;
}

void Do_DFS_Visit(struct _graph_t *G, int i) {
	int i;
	G->vts[i].color = 'g';
	for (i = 0; i < G->N; i++) {

		// if (G->vts[i].nbrs[j])
	}
}

void DFS(struct _graph_t *G) {
	int i;
	for (i = 0; i < G->N; i++) Do_DFS_Visit(&G, i);
}

int main() {
	struct _graph_t G;
	g5_printf("Enter number of vertices (1 - 100): ");
	g5_scanf("%d", &G.N);
	while (G.N < 1 || G.N > 100) {
		g5_printf("Enter number of vertices (** 1 - 100 **): ");
		g5_scanf("%d", &G.N);
	}

	G.vts = g5_malloc(G.N * 404); // do using sizeof() operator
	g5_printf("G.vts = %p\n", G.vts);
	if (G.vts) {
		g5_printf("Unvisiting Graph ...  ");
		unVisitGraph(&G);

		{ // edge scanning
			char proceed = 1;
			while (proceed) {
				int x, y;
				g5_printf("Enter an edge (eg. 1 2): \n");
				g5_scanf("%d %d", &x, &y);
				if (x == y || x < 1 || x > G.N || y < 1 || y > G.N)
					g5_printf("Invalid vertices. Ignoring them.\n");
				else insertEdge(&G, x, y);
				g5_printf("Wish to give another edge? (y/n): ");
				g5_scanf("%c", &proceed);
				if (proceed == 'n') proceed = 0;				
			}
		}

		// DFS here
		DFS(&G);

	} else {
		g5_printf("Could not allocate space for vertices. Exiting...\n");
		g5_exit(-1);
	}

 return 0;
}