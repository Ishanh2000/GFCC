// int int x;
// const const int x;
// int newint g;
// newint newint g;
// const static  newint * g;
// int ***(**x);

// int *const const *volatile volatile f;

// int **** (*x)[5][][6]; // PTR >> ARR >> BASE
// int f()(); // PTR >> ARR >> BASE
// int f[](); // PTR >> ARR >> BASE
// int f(); // PTR >> ARR >> BASE
// int f(int, newint); // PTR >> ARR >> BASE
// int x[][];
// int (**F)(); // PTR >> FUNC

// int *const (* volatile f)(); // PTR >> FUNC >> PTR
// float (*f)[4][5][6]; // PTR >> ARR
// int *** (*(*f)(char m))[]; // PTR >> FUNC >> PTR >> ARR >> PTR
// int *(*(*(*(*(*(*f[])[])[])[])[])[])[]; // ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR >> ARR >> PTR (7)
// int *** (*(*f)(char))(); // PTR >> FUNC >> PTR >> FUNC >> PTR

// int f()();
// int f[]();
// int (f())[], (g[])();

// void f(unsigned char a, ...); // FUNC
// const double ff[][][]; // ARR
// const int ** const *volatile l; // PTR
// const unsigned int volatile static;

// int main(int);
// int main(void);

#include <stdio.h>

void func(int f(), int j) {
        f();
}


int (*F)();
int (*F)();

//int F() {
//      return 9;
//}

int long h;
long const long k;

const int main() {
        // goto g;
        const double d[10][10][10];
        int f();
        g :
        func(&f, 89);
        return 0;
}


// int main() {
//     extern int const i;
//     extern int i;
//     int x[][45];
// }

// int main(int ()(), int);
// int main(int [](), int);
// int main(int ()[], int);
// int main(int [][], int);
// int main(int [][78], int);
// int main(int **(*[])[78], void);
// int main(void);


// int main(){
//     char f = 's', m;
//     long  long long *****(***x)[](int*);
//     // int *const volatile* volatile volatile d()[2];
//     // int a;
//     // int a,b;
//     int (*f)(int, char) = func;
//     // {
//         int f = 0;
//     // }
    
// }

// int func(...) { }
// int (*f)(void, void);