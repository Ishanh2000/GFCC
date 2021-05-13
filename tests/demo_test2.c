#include <g5_typo.h>
int f1(int b, char c, float d)
{
    b = b + c;
    d = d + b / 67.7;
    return b + d;
}
float f2(int b, char c, float d)
{
    b = b + c;
    d = d + b / 67.7;
    return b + d;
}
int main()
{
    int a = 10, b = 20;
    float p = 23.3, q = 10;
    char c = '4';
    p = f2(a,0,p);
    g5_printf("a : %d, c : %c, p : %f\n",a,c,p);
    b = f1(a,c,q);
    g5_printf("b : %d, c : %c, q : %f\n",b,c,q);
    p = f1(a,c,q);
    g5_printf("a : %d, c : %c, p : %f\n",a,c,p);
    b = f2(a,c,p);
    g5_printf("b : %d, c : %c, p : %f\n",b,c,p);
    return 0;
}