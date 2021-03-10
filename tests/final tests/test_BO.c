#include <stdio.h>

int main()
{
	int g[10];
	int a; char b; float c;
	int d = 100, e = 123;
	a = 10;
	c = (float)a;
	a = a&d|e;
	a *= b;
	b ^= c;
	c &= d;
	a = a>>1;
	b = b<<a;
	return 0; 
}