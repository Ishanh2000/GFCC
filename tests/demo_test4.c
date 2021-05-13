#include <g5_typo.h>
int main()
{
    int a = 3, c = 0;
    switch(a)
    {
        case 1 :  { a = 5; break; }
        case 2 :  { a = 5; }
        case 3 :  { a = 7; }
        case 4 :  { a++; break; }
        case 7 :  { a = 999; }
        default : { a = 99999; }
    }
    g5_printf("%d\n",a);
    for(a = 6;a < 10; a++)
    {
        int b = a;
        while( b > 5 ){ c++; b--; }
        b = a;
        do{ c--; b--; } while(b > 5);
        g5_printf("%d ",c);
    }
    g5_printf("\n");
    if( a == 9 ) goto bad;
    g5_printf("Control should reach here\n");
    
    bad: ;

    
    return 0;
}