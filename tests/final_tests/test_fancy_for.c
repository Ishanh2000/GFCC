#include<stdio.h>

int main();

int main(){
  int a = 0,b = 0,c = 100;
  for(;;)
  {
    a++;
    if(a>c*10){
      b--;
      break;
    }
  }
  for(a = 100;;){
    a--;
    if(a == 10)
    {
      a = 0;
      continue;
    }
    if(a<c*-3){
      break;
    }
  }
  a = 10;
  for(;a>1;)
  {
    a--;
  }
  for(;;a++){
    if(a>10)break;
  }

  return 0;
}