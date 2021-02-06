#include <stdio.h>

int main()
{
	int n; cin>>n;
	if( n > 1 )
	{
		n = n*2;
		if( n > 10 ) goto tgt;
	}
	n -= 10;
	tgt : ;
	return 0;
}