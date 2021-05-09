#include <stdio.h>
#include <stdlib.h>

// void func1(const char *g) {
//   g++;
//   return;
// }

// void func(char* a, char b) {
//   a += b;

// }

int main() {
  // char str[] = "abcd";
  // int a[5][6][7][8];
  // &a[0][1][2][3];
  g5_printf("Hello %p, %s\n", 538571822); // 0x2019f42e
  g5_exit(9);
  g5_putc('\n');
  g5_putc('5');
  g5_putc('f');
  g5_putc('6');
  g5_putc('\n');

  // g5_printf("Hello %f\n", 12.003); // "Hello12.003"
  // g5_printf("Hello %d\n", g5_printf("Hello%f", 12.003)); // expect = 1 // "Hello12.003Hello 1"
  // g5_printf("Hello %dIITK, %c, %d\n, %s, %d\n", 89, 'c', 890, "MOOKIT", g5_printf("Hello%f", 12.003));
  
  return 0;
}
// int main(int argc, char *argv[]) {
  // int x = 90;
  // char y = 'b';
  // unsigned int a = 100;
  // int b = -10;
  // int c = a*b;
  // long long * p,*q,*r;
  // double pp;
  // p = *p*a;
  // p = p + 10;
  // r = p+*q;

  // c = a & (int)pp;
  // use -l=math
  // pp += GFCC_M_PI;
  // pp += gfcc_sin(GFCC_M_PI/2);
  // g5_printf("%s, %c", "kk", 'b');
  // g5_printf("%d, %c", x, y);
  // func1((char *)0);
  // func((char *)0, 'a');
//   return 0;
// }

// int main() {
//   return 0;
// }

// int g5_printf () {
//   return 6;
// }
