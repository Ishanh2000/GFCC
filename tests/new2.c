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

int f()();
int f[]();
int (f())[], (g[])();

// void f(unsigned char a, ...); // FUNC
// const double ff[][][]; // ARR
// const int ** const *volatile l; // PTR
// const unsigned int volatile static;

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