#include <stdio.h>

int main()
{
	in t n, exit_m;
	scanf("%d",&n);
	while(n&1==1)
	{
		printf("hello");
		n ^=1;
	}

	return 0;
}