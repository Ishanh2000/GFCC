#include <stdio.h>
#include <string.h>

int main() 
{
	char a[100];
	scanf("%s",a);
	int len = strlen(a);
	for(int i=0;i<len/2;i++)
	{
		a[i] = a[len-1-i];
	}
	printf("Reversed string : %s\n",a);
	return 0;
}