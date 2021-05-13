#include <stdio.h>
int f1(int a[],float b[])
{
    return a[2];
}
float f2(int a[],float b[])
{
    return b[2];
}

int main()
{
    int a[5] = {1,2,3,4,5};
    int b[] = {2,2,3.8,2,3};
    float c[] = {2.3,3.4,1.43,2.322};
    int i = 0;
    a[1] = f1(a,c);
    c[1] = f2(a,c);
    for(i=0;i<5;i++)
    {
        printf("%d ",a[i]);
    }
    printf("\n"); 
    i = 0;
    while(i < 5)
    {
        printf("%f ",c[i]);
        i++;
    }
    printf("\n");
    a[1] = f2(a,b);
    c[1] = f1(a,c);
    for(i=0;i<5;i++)
    {
        printf("%d ",a[i]);
    }
    printf("\n"); 
    i = 0;
    while(i < 5)
    {
        printf("%f ",c[i]);
        i++;
    }
    printf("\n");
    return 0;
}