#include <g5_typo.h>

int f1(int a[])
{
    return a[2];
}
int f2(int b[][3])
{
    return b[1][2];
}
float f3(float b[][3])
{
    return b[1][2];
}
int main()
{
    int a[][3] = { {1,2,3}, {5,6,7} };
    float b[][3] = { {1,2,3}, {5,6,7} };
    int p = f1(a);
    int q = f2(a);
    float g = f3(b);
    g5_printf("%d %d %f\n",p,q,g);
    return 0;
}