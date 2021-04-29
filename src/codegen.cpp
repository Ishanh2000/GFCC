// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_ASM__
#define __GFCC_ASM__

#include <fstream>
#include <vector>

#include <ircodes.h>
#include <codegen.h>

using namespace std;

// convert IR code to ASM (mainly MIPS, for "spim" simulator)
void dumpASM(ofstream &f, vector<irquad_t> IR) {
  int lenIR = IR.size();
  for (int i = 0; i < lenIR; i++) {
    
  }
}

#endif
