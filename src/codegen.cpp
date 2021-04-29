// AUM SHREEGANESHAAYA NAMAH||
// compile using: g++ -Iinclude -DTEST_CODEGEN codegen.cpp
#include <fstream>
#include <vector>

#include <ircodes.h>
#include <codegen.h>

using namespace std;


string currFunc = "";

// convert IR code to ASM (mainly MIPS, for "spim" simulator)



void dumpASM(ofstream &f, vector<irquad_t> & IR) {
  int lenIR = IR.size();
  unsigned int currleader = 0;

  while(currleader < lenIR) {
    unsigned int nxtleader = getNxtLeader(IR, currleader);
    cout<< "Nxt Leader: " << nxtleader << endl;
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
  if(quad.opr == "func") funcStart(f, quad);
  else if (quad.opr == "return") 
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
  else if (quad.opr == "function end") funcEnd(f, quad);
}


void funcStart(std::ofstream & f, irquad_t & quad) {
  currFunc = quad.src1;
  auto symtabs = SymRoot->currScope->subScopes;
  symtab * funTab;
  for (auto tab: symtabs) {
    if (tab->name == "func " + currFunc) { funTab = tab; break; }
  }

  // 40 for possible $t0---$t9
  unsigned short s_offest = funTab->offset + 40;

  f << currFunc << ":" << endl;
  f << '\t' << "sw"<< " $ra, -4($sp)"<< " # return address" << endl;
  f << '\t' << "sw"<< " $fp, -8($sp)"<< " # frame pointer of caller" << endl;
  f << '\t' << "move" << " $fp, $sp" << " # begin new frame" << endl;
  f << '\t' << "subu"<< " $sp, $sp, "<< s_offest << " # expad frame" << endl;
  f << '\t' << "sw"<< " $s0, -12($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s1, -16($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s2, -20($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s3, -24($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s4, -28($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s5, -32($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s6, -36($fp)"<< " # callee saved register" << endl;
  f << '\t' << "sw"<< " $s7, -40($fp)"<< " # callee saved register" << endl;

}

void funcEnd(std::ofstream & f, irquad_t & quad) {
  f << currFunc + "_ret :" << endl;
  f << '\t' << "lw"<< " $s7, -40($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s6, -36($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s5, -32($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s4, -28($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s3, -24($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s2, -20($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s1, -16($fp)" << " # restore callee saved register" << endl;
  f << '\t' << "lw"<< " $s0, -12($fp)" << " # restore frame pointer of caller" << endl;
  f << '\t' << "move" << " $sp, $fp" << " # close current frame" << endl;
  f << '\t' << "lw"<< " $fp, -8($sp)" << " # restore frame pointer of caller" << endl;
  f << '\t' << "lw"<< " $ra, -4($sp)" << " # restore return address" << endl;

  if (currFunc == "main") {
    /* exit routine */
    f << '\t' << "li"<< " $v0, 10"<< " # # syscall code 10 is for exit" << endl;
    f << '\t' << "syscall" << " # make exit syscall" << endl;
  }
  else f << '\t' << "jr"<< " $ra"<< " # return to caller" << endl;
  
  f << endl;
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
