#include <g5_typo.h>

int f(int *p)
{
    *p = 42;
    return *p;
}

int main()
{
    int x = 0, y;
    int *p = &x;
    int *w = &y;
    int **q = &p;
    *p = 23;
    g5_printf("*%p = %d (%d)\n",p,*p,x);
    y = f(p);
    g5_printf("%d\n",y);
    *( (int*)(*q) ) = 333;
    g5_printf("**%p = %d (%d)\n",q,*p,x);
    return 0;
}