// AUM SHREEGANESHAAYA NAMAH||
// compile using: g++ -Iinclude -DTEST_CODEGEN codegen.cpp
#include <fstream>
#include <vector>

#include <ircodes.h>
#include <codegen.h>
#include <symtab.h>

#ifdef DEBUG_CODEGEN
static bool dbg = true;
#else
static bool dbg = false;
#endif


using namespace std;
 
string currFunc = "";

// convert IR code to ASM (mainly MIPS, for "spim" simulator)

sym* regDscr[32];

void dummy() {}
string reg2str[] = {
  "$zero",                                           // constant 0
  "$at",                                             // reserved for the assembler
  "$v0", "$v1",                                       // result registers
  "$a0", "$a1", "$a2", "$a3",                           // argument registers 1···4
  "$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7",   // temporary registers 0···7
  "$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7",   // saved registers 0···7
  "$t8", "$t9",                                       // temporary registers 8···9
  "$k0", "$k1",                                       // kernel registers 0···1
  "$gp", "$sp", "$fp", "$ra"                            // global data ptr, stack ptr, frame ptr, return addr
};

void resetRegMaps(ofstream &f) {
  for(int i = t0; i < t9; i++){
    if(regDscr[i]) {
      // TODO: sw/sb/... for non 4 byte
      f << '\t' << "sw " << reg2str[i]+", -"<<regDscr[i]->offset <<"($fp)";
      f << " # flush register to stack" << endl;
      regDscr[i]->reg = zero;
      regDscr[i] = NULL;
    }
  }
}

int currReg = t0;
reg_t getSymReg(std::string & symName) {
  sym* symb = SymRoot->gLookup(symName);
  if(!symb) {
    if (dbg) cout<<"seg fault here :/" << endl;
    return zero;
  }

  if(symb->reg != zero)
    return symb->reg;
  else {
    symb->reg = (reg_t) currReg++; // ! adhoc
    regDscr[symb->reg] = symb;
    return symb->reg;
  }
}

void dumpASM(ofstream &f, vector<irquad_t> & IR) {
  // clear reg
  for(int i = 0; i<32; i++){
    regDscr[i] = NULL;
  }

  int lenIR = IR.size();
  unsigned int currleader = 0;

  while(currleader < lenIR) {
    unsigned int nxtleader = getNxtLeader(IR, currleader);
    cout<< "Nxt Leader: " << nxtleader << endl;
    resetRegMaps(f);
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
    // TODO
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
  else if (quad.opr == "function end") funcEnd(f, quad);
  else if (quad.opr == eps) {
    reg_t srcReg = getSymReg(quad.src1), dstReg = getSymReg(quad.dst);
    if(srcReg == zero) {
      // TODO other types
      f << '\t' << "li " << reg2str[dstReg] + ", " + quad.src1 << endl;
    }
    else {
      f << '\t' << "move " << reg2str[dstReg] + ", " + reg2str[srcReg] ;
      f << " # move" << endl;
    }
  }
}


void funcStart(std::ofstream & f, irquad_t & quad) {
  currFunc = quad.src1;
  auto symtabs = SymRoot->currScope->subScopes; // currscope == root
  symtab * funTab;
  for (auto tab: symtabs) {
    if (tab->name == "func " + currFunc) { funTab = tab; break; }
  }

  // initialise reg for all symbols to "zero"
  for (sym* symb: funTab->syms) {
    symb->reg = zero;
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
