#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int foo()
{
  int a, b;

  if (a = b)
    doit();

  if (a == b)
  {
    trydoingit();
  }
  else
    donteventry();

  if (a == b || a == 10 && b == 5)
    doitanyway(a, b);
  else if (cantdoit())
    plsdoit();
  else
  {
    // char str[8] = {'g', 'n', 'i', 'k', 'c', 'u', 'f', '\0'};
    // printf("why can't I do a single %s thing\n", str);
    return plmshlp();
  }
  return 0;
}
