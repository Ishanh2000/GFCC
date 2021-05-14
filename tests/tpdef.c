#include <g5_typo.h>
#include <g5_std.h>
#include <g5_string.h>

typedef struct _newint {
  int x;
  int y;
} pair;

// int main() { return 0;}
int main() {
  pair p;
  // struct _newint pair p;

	g5_scanf("%d", &p.x);
	g5_scanf("%d", &p.y);

  g5_printf("%d, %d\n", p.x, p.y);



	return 0;
}
int main();

// 9
// 8
// 0
// 1
// 0
// 5
// 0
// 2
// 2
// 5
// 3
// 5
// 6
// 2
// 7
// 4
// 8
// 7
