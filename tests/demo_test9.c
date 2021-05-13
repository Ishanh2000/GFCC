#include <g5_typo.h>
#include <g5_std.h>

int main() {
	char a[100];
  int *x;

	g5_scanf("%s", &a);
	g5_printf("a = \"%s\", g5_atoi(a) = %d\n", a, g5_atoi(a));

  
	{ // testing malloc
    g5_printf("x = \"%p\"\n", x = g5_malloc(5 * sizeof(int)));
    g5_printf("x = \"%p\"\n", x = g5_malloc(5 * sizeof(int)));
    x[2] = 23; *x = -943;
	  g5_printf("x = %p, x[2] = %d, *x = %d\n", x, x[2], *x);
    g5_printf("x = \"%p\"\n", x = (int*)g5_malloc(-20));
    g5_printf("x = \"%p\"\n", x = (int*)g5_malloc(0));
  }
    
	{ // testing calloc
    g5_printf("x = \"%p\"\n", x = g5_calloc(1, 100));
    g5_printf("x = \"%p\"\n", x = g5_calloc(5, 5 * sizeof(int)));
    g5_printf("x = \"%p\"\n", x = (int*)g5_calloc(-1, -20));
    g5_printf("x = \"%p\"\n", x = (int*)g5_calloc(0, 5 * sizeof(int)));
  }
  
  
  g5_free(x);

  g5_exit(9);


	return 0;
}