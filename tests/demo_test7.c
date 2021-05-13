#include <g5_typo.h>
#include <g5_math.h>

int main()
{
    int a = -123, i;
    float p = 23.3, q = -23.1;
    g5_printf("Absolute of %d = %d\n", a, g5_abs(a));
    for(i = -2;i<=10;i++)
    {
        g5_printf("Factorial/Fibo no. %d = %d : %d\n", i, g5_fact(i),g5_fib(i));
    }
    // Function as param to another function
    g5_printf("\n%f raised to power %d = %f\n", p, 3, g5_intpow(p,g5_abs(-3)));
    g5_printf("%f raised to power %d = %f\n", p, -3, g5_intpow(p,-3));

    g5_printf("\nAbsolute of %f = %f\n", q, g5_fabs(q));

    g5_printf("\nSqrt of %f = %f\n", g5_fabs(q), g5_sqrt(g5_fabs(q)));

    q = -12.2;
    g5_printf("\nSqrt of %f = %f\n", g5_fabs(q), g5_exp(g5_fabs(q)));

    return 0;
}