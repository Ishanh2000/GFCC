#include <g5_typo.h>
#include <g5_std.h>

int main() {
	char a[100];
  int *x;

	g5_scanf("%s", &a);
	g5_printf("a = \"%s\", g5_atoi(a) = %d\n", a, g5_atoi(a));

  
	{ // testing malloc
    g5_printf("x = \"%p\"\n", x = g5_malloc(20));
    g5_printf("x = \"%p\"\n", x = g5_malloc(20));
    g5_printf("x = \"%p\"\n", x = (int*)g5_malloc(-20));
    g5_printf("x = \"%p\"\n", x = (int*)g5_malloc(0));
  }
    
	{ // testing calloc
    g5_printf("x = \"%p\"\n", x = g5_calloc(1, 100));
    g5_printf("x = \"%p\"\n", x = g5_calloc(5, 4));
    g5_printf("x = \"%p\"\n", x = (int*)g5_calloc(-1, -20));
    g5_printf("x = \"%p\"\n", x = (int*)g5_calloc(0, 20));
  }
  
  // x[2] = 23;
	// g5_printf("x = %p, x[2] = \"%d\"\n", x, x[2]);
  
  g5_free(x);

  g5_exit(9);


	return 0;
}