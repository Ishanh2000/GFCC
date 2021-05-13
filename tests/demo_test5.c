#include <g5_typo.h>

int fact(int n)
{
    if( n <= 1 ) return 1;
    return n*fact(n-1);
}

int main()
{
    int i;
    for(i=0;i<=10;i++)
    {
        g5_printf("Factorial of %d = %d\n",i,fact(i));
    }
    return 0;
}