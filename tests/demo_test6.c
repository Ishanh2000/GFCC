#include <g5_typo.h>
#include <g5_string.h>

int main() {
	char a[100];
	char c[] = "abcdefghijklmnop";
	char b[100];

  g5_printf("\033[33m"); // just for hiighlighting

	g5_scanf("%s", &a);
	g5_scanf("%s", &b);

	g5_printf("a = \"%s\", strlen(a) = %d\n", a, g5_strlen(a));
	g5_printf("b = \"%s\", strlen(b) = %d\n", b, g5_strlen(b));
	
	g5_printf("strcmp(\"%s\", \"%s\") = %d\n", a, b, g5_strcmp(a, b));
	
	g5_printf("strupr(a) = \"%s\", retval = %d\n", a, g5_strupr(a));
	g5_printf("strupr(b) = \"%s\", retval = %d\n", b, g5_strupr(b));

	g5_printf("strlwr(a) = \"%s\", retval = %d\n", a, g5_strlwr(a));
	g5_printf("strlwr(b) = \"%s\", retval = %d\n", b, g5_strlwr(b));

	g5_printf("strcat(a, b) = %d, a = \"%s\", b = \"%s\"\n", g5_strcat(a, b), a, b);

	g5_printf("strcpy(a, b) = %d, a = \"%s\", b = \"%s\"\n", g5_strcpy(a, b), a, b);
	g5_printf("strcpy(a, \"%s\") = %d, a = \"%s\"\n", c, g5_strcpy(a, c), a);

	g5_printf("strncpy(a, b) = %d, a = \"%s\", b = \"%s\"\n", g5_strncpy(a, b, 2), a, b);

	g5_printf("strrev(a) = \"%s\"\n", g5_strrev(a));


	return 0;
}