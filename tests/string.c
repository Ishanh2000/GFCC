#include <g5_typo.h>
#include <g5_string.h>

int main() {
	// char a[] = "Hello";
	char a[100];
	char b[100];

	g5_scanf("%s", &a);
	g5_scanf("%s", &b);

	g5_printf("a = \"%s\", strlen(a) = %d\n", a, g5_strlen(a));
	g5_printf("b = \"%s\", strlen(b) = %d\n", b, g5_strlen(b));
	
	g5_printf("strcmp(%s, %s) = %d\n", a, b, g5_strcmp(a, b));
	
	g5_printf("strupr(a) = \"%s\", retval = %d\n", a, g5_strupr(a));
	g5_printf("strupr(b) = \"%s\", retval = %d\n", b, g5_strupr(b));

	g5_printf("strlwr(a) = \"%s\", retval = %d\n", a, g5_strlwr(a));
	g5_printf("strlwr(b) = \"%s\", retval = %d\n", b, g5_strlwr(b));

	g5_printf("strcat(a, b) = %d, a = \"%s\", b = \"%s\"\n", g5_strcat(a, b), a, b);


	return 0;
}