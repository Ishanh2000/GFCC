#include <stdio.h>
#include <stdlib.h>

int foo(int);
void foo1();
void foo2(int, int, ...);
void foo3(int, int);
// int foo(int j) {
//   return 0;
// }
// void foo1() {
// }
// void foo2(int x, int y, ...) {
// }
// void foo3(int x, int y) {
// }
int main(int argc, char *argv[]) {
  int a, *p;
  float b, *pf;
  unsigned long long c, *d,**e;
  double ee[10];
  int arr[] = { 1, 2 };
  int arr1[12];
  // a = a < p;
  // a = a<b;
  // p = c > d;
  // e = e<e;
  // d =  foo > pf;
  // c = ee < pf;

  // ee[8];
  // ee[8][90];
  // p[90];
  // a[90];
  // e[5][8][4];
  // e['f'+9.0];
  // ee[-4];
  // ee[22222+21212212121212221];
  // ee[pf];
  // ee[a];
  struct _x { int x; int y; } l;
  
  // ee+ p;
  // 1+foo1();
  // ee[foo1()];
  // +foo1();
  // !foo1();
  // !l;


  // ~l;
  // ~main;
  // ~p;
  // ~(ee[7]);
  // ~b;
  // ~arr1;
  // ~y;
  // ~3;
  // ~a;

  // sizeof(void);
  sizeof(main);

  // ++main;
  // ++foo1();
  // ++foo();  // problematic
  // ++arr;
  // ++a;
  // ++p;
  // ++l;

  // switch (arr1) {
  // case arr1:
  //   /* code */
  //   break;
  
  // default:
  //   break;
  // }
  
  // while (foo1) ;

  // !foo();
  // foo1();
  // foo2();
  // foo2(45, 45, "ll");
  // foo3();

  // !foo(8);
  // !foo1();
  // foo2(5, 4, 56);
  // foo2(45, 45, "ll");
  // foo3(1, "ll");

  // foo(0);
  {
    struct loc_t { int x; int y; } d;
    (struct loc_t *[])9;
    (void)9;
    (int)foo1;
  }

  return 0;
}

struct _aaa *myFunc(struct _x*);

struct _aaa *myFunc(struct _x*c) {

}

