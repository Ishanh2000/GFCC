#include <stdio.h>
#define ll long long

const int N = 1e5;
ll a[N];

int main()
{
	int n;
	scanf("%d",&n);
	for(int i=0;i<=n-1;i++) 
		scanf("%d",&a[i]);
	ll *p = a;
	*p = *p*100;
	printf("%d",a[0]);
	return 0;
}