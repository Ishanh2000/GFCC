#include <stdio.h>
#include <stdlib.h>

int foo() {
  return 0;
}
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
  
  // ee+ p;
  

  return 0;
}
