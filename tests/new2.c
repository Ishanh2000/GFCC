int int x;
const const int x;
int newint g;
newint newint g;
const static  newint * g;
int ***(**x);

int *const const *volatile volatile f;

int **** (*x)[5][][6]; // PTR >> ARR >> BASE
int f()(); // PTR >> ARR >> BASE
int f[](); // PTR >> ARR >> BASE
int f(); // PTR >> ARR >> BASE
int f(int, newint); // PTR >> ARR >> BASE
int x[][];
int (**F)(); // PTR >> FUNC

int *const (* volatile f)(); // PTR >> FUNC >> PTR
float (*f)[4][5][6]; // PTR >> ARR
int *** (*(*f)(char m))[]; // PTR >> FUNC >> PTR >> ARR >> PTR
int *(*(*(*(*(*(*f[])[])[])[])[])[])[]; // ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR (7)
int *** (*(*f)(char))(); // PTR >> FUNC >> PTR >> FUNC >> PTR

int f()();
int f[]();
int (f())[], (g[])();

void f(unsigned char a, ...); // FUNC
const double ff[][][]; // ARR
const int ** const *volatile l; // PTR
const unsigned int volatile static;

int main(int);
int main(void);

#include <stdio.h>



int x (void x) {
        x;
        return 0;
}
char x;
int x;


int x (void * x) {
        return 0;
}



void func(int f, int j, char **x) {
        f+j+k;
}
int *F(char t[][45], int c);

int long h;
long const long k;

const int main(void);
const int main() {
        const double d[10][10][10];
        int f();
        extern int lp;
        int lp;
        extern int lp;
        func(&f, 89);
        return 0;
}





