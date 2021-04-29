// AUM SHREEGANESHAAYA NAMAH||
// compile using: g++ -Iinclude -DTEST_CODEGEN codegen.cpp
#include <fstream>
#include <vector>

#include <ircodes.h>
#include <codegen.h>

using namespace std;

enum reg {
  zero,                                   // constant 0
  at,                                     // reserved for the assembler
  v0, v1,                                 // result registers
  a0, a1, a2, a3,                         // argument registers 1···4
  t0, t1, t2, t3, t4, t5, t6, t7,         // temporary registers 0···7
  s0, s1, s2, s3, s4, s5, s6, s7,         // saved registers 0···7
  t8, t9,                                 // temporary registers 8···9
  k0, k1,                                 // kernel registers 0···1
  gp, sp, fp, ra                          // global data ptr, stack ptr, frame ptr, return addr
};

string currFunc = "";

// convert IR code to ASM (mainly MIPS, for "spim" simulator)



void dumpASM(ofstream &f, vector<irquad_t> & IR) {
  int lenIR = IR.size();
  unsigned int currleader = 0;

  while(currleader < lenIR) {
    unsigned int nxtleader = getNxtLeader(IR, currleader);
    
    // gen code for a main block
    while(currleader < nxtleader) {
      //  TODO: flush, reset etc
      genASM(f, IR[currleader]);
      currleader++;
    }
  }
}


unsigned int getNxtLeader(vector<irquad_t> & IR, unsigned int leader) {
  int lenIR = IR.size();
  for(auto idx = leader; idx < lenIR; idx++) {
    if(IR[idx].opr == "goto" || IR[idx].opr == "ifgoto" ||
       IR[idx].opr == "call" || IR[idx].opr == "func" ||
       IR[idx].opr == "return" || IR[idx].opr == "newScope" ||
       IR[idx].opr == "closeScope") {
         return idx+1;
       }
  }
  return lenIR;
}




void genASM(std::ofstream & f, irquad_t & quad) {

  if(quad.opr == "func") genfun(f, quad);
  else if (quad.opr == "return") 
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
}


void genfun(std::ofstream & f, irquad_t & quad)
{
    // func:
    currFunc = quad.src1;
    auto symtabs = SymRoot->currScope->subScopes;
    symtab * funTab;
    for(auto tab: symtabs) {
      if(tab->name == "func "+currFunc) {
        funTab = tab;
        break;
      }
    }
    
    f << currFunc << ":" << endl;
    f << '\t' << "move" << " $fp, $sp" << " # " << endl;
    f << '\t' << "subu"<< " $sp, $sp, 64"<< " # frame size = 32, just because..." << endl;
    f << '\t' << "sw"<< " $ra, 60($sp)"<< " # return address" << endl;
    f << '\t' << "sw"<< " $fp, 56($sp)"<< " # frame pointer of caller" << endl;
    f << '\t' << "sw"<< " $s0, 52($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s1, 48($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s2, 44($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s3, 40($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s4, 36($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s5, 32($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s6, 28($sp)"<< " # callee saved register" << endl;
    f << '\t' << "sw"<< " $s7, 24($sp)"<< " # callee saved register" << endl;
    
    f << '\t' << "b "+ currFunc + "_def" << endl;

    f << currFunc+"_ret" << ":" << endl;
    f << '\t' << "lw"<< " $ra, 60($sp)"<< " # restore return address" << endl;
    f << '\t' << "lw"<< " $fp, 56($sp)"<< " # restore frame pointer of caller" << endl;
    f << '\t' << "lw"<< " $s0, 52($sp)"<< " # restore frame pointer of caller" << endl;
    f << '\t' << "lw"<< " $s1, 48($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s2, 44($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s3, 40($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s4, 36($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s5, 32($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s6, 28($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "lw"<< " $s7, 24($sp)"<< " # restore callee saved register" << endl;
    f << '\t' << "addu"<< " $sp, $sp, 64"<< " # restore stack pointer of caller" << endl;
    if (currFunc == "main") {
      f << '\t' << "li"<< " $v0, 10"<< " # # syscall code 10 is for exit" << endl;
      f << '\t' << "syscall" << " # make the syscall" << endl;
    }
    else f << '\t' << "jr"<< " $ra"<< " # return to caller" << endl;
    
    f << currFunc+"_def" << ":" << endl;
    

    for(auto symbol: funTab->syms) {
      if(symbol->name[0] != '0') {
        // DO something
      }
    }
}

#ifdef TEST_CODEGEN

void testcodegen() { // a = b*-c + b*-c
    emit("t1", "-", "c"); // t1 = -c
    emit("t2", "*", "b", "t1"); // t2 = b * t1
    cout<<nextIdx()<<endl;
    emit("t3", "-", "c"); // t3 = -c
    emit("t4", "*", "b", "t3"); // t4 = b * t3
    emit("t5", "+", "t2", "t4"); // t5 = t2 + t4
    newLabel();
    emit("a", eps, "t5"); // a  = t5
    emit("res", "<", "t1", "t2"); // res = t1 < t2
    emit(eps, "goto", "101", "res"); // if res goto 101
    emit(eps, "goto", "104"); // goto 104

    ofstream f; f.open("ircodegen_1.txt");
    dumpASM(f, IRDump);
    f.close();
}

int main() {

}

#endif
