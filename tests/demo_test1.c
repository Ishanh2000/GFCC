#include <g5_typo.h>
int main()
{
    int a = 100, b = 12;
    char c = 'a', d = 'b';
    float e = 12.332, f = -67.77;
    short g = 3, h = 4;
    
    //Integer ops
    g5_printf("\nIntegers ops...\n");
    a = a + b;
    g5_printf("%d %d\n",a,b);
    a = a - b;
    g5_printf("%d %d\n",a,b);
    a = a * b;
    g5_printf("%d %d\n",a,b);
    a = a / b;
    g5_printf("%d %d\n",a,b);
    b = a + (a + 1) - ( a / b );
    g5_printf("%d %d\n",a,b);

    //Char ops
    g5_printf("\nChar ops...\n");
    c = c + 1;
    g5_printf("%c %c\n",c,d);
    d = d + c - 'a';
    g5_printf("%c %c\n",c,d);
    d = d - (-3);
    g5_printf("%c %c\n",c,d);

    //Float ops
    g5_printf("\nFloat ops...\n");
    e = e + f;
    g5_printf("%f %f\n",e,f);
    e = e - f;
    g5_printf("%f %f\n",e,f);
    e = e * f;
    g5_printf("%f %f\n",e,f);
    e = e / f;
    g5_printf("%f %f\n",e,f);
    f = e + (e + 1.0) + 3.32 - ( e / f );
    g5_printf("%f %f\n",e,f);

    //Short ops
    g5_printf("\nShort ops...\n");
    g = g + h;
    g5_printf("%d %d\n",g,h);
    g = g - h;
    g5_printf("%d %d\n",g,h);
    g = g * h;
    g5_printf("%d %d\n",g,h);
    g = g / h;
    g5_printf("%d %d\n",g,h);
    h = g + (g+1) - ( g / h );
    g5_printf("%d %d\n",g,h);

    //Mixed ops
    g5_printf("\nMixed ops...\n");
    a = a + e;
    g5_printf("%d %d %c %c %f %f %d %d\n",a,b,c,d,e,f,g,h);
    e = e / b;
    g5_printf("%d %d %c %c %f %f %d %d\n",a,b,c,d,e,f,g,h);
    c = c + b;
    g5_printf("%d %d %c %c %f %f %d %d\n",a,b,c,d,e,f,g,h);
    f = f / 67.3 + h;
    g5_printf("%d %d %c %c %f %f %d %d\n",a,b,c,d,e,f,g,h);
    return 0;
}