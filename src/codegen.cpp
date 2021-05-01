// AUM SHREEGANESHAAYA NAMAH||
// compile using: g++ -Iinclude -DTEST_CODEGEN codegen.cpp
#include <fstream>
#include <iomanip>
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

// convert IR code to ASM (mainly MIPS, for "spim" simulator)

string reg2str[] = {
  "$zero",                                                   // constant 0
  "$at",                                                     // reserved for the assembler
  "$v0", "$v1",                                              // result registers
  "$a0", "$a1", "$a2", "$a3",                                // argument registers 1···4
  "$t0", "$t1", "$t2", "$t3", "$t4", "$t5", "$t6", "$t7",    // temporary registers 0···7
  "$s0", "$s1", "$s2", "$s3", "$s4", "$s5", "$s6", "$s7",    // saved registers 0···7
  "$t8", "$t9",                                              // temporary registers 8···9
  "$k0", "$k1",                                              // kernel registers 0···1
  "$gp", "$sp", "$fp", "$ra"                                 // global data ptr, stack ptr, frame ptr, return addr
};

string freg2str[] =  {
  "$f0", "$f1", "$f2", "$f3",                                 // Function-returned values
  "$f4", "$f5", "$f6", "$f7", "$f8", "$f9", "$f10", "$f11",   // Temporary values
  "$f12", "$f13", "$f14", "$f15",                             // Arguments passed into a function
  "$f16", "$f17", "$f18", "$f19",                             // More Temporary values
  "$f20", "$f21", "$f31",                                     // Saved values
};

sym* regDscr[32];

void _nxtUse::clear() {
  if (this->deltas.size() != 0) {
    cout << "void _nxtUse::clear() " << "delta array not empty on clear"<<endl;
    this->deltas.clear();
  }
}

deltaNxtUse _nxtUse::step() {
  if(this->deltas.empty()) cout << "deltaNxtUse _nxtUse::step() deltas array empty" << endl;
  deltaNxtUse delta = this->deltas.back();
  // store last deltas
  this->lastdelta = delta;
  this->deltas.pop_back();
  if(delta.dstSym) {
    delta.dstSym->nxtuse = delta.dstNxtUse;
    delta.dstSym->alive = delta.dstAlive;
  }
  if(delta.src1Sym) {
    delta.src1Sym->nxtuse = delta.src1NxtUse;
    delta.src1Sym->alive = delta.src1Alive;
  }
  if(delta.src2Sym) {
    delta.src2Sym->nxtuse = delta.src2NxtUse;
    delta.src2Sym->alive = delta.src2Alive;
  }
  return delta;
}

_nxtUse nxtUse;
string currFunc = "";

void regFlush(std::ofstream & f, reg_t reg, bool store = true) {
  if(regDscr[reg]) {
    // TODO: sw/sb/... for non 4 byte
    // TODO: offset from $gp
    if (store) { 
      f << '\t' << "sw " << reg2str[reg]+", -"<< regDscr[reg]->offset <<"($fp)";
      f << " # flush register to stack (" + regDscr[reg]->name + ")"<< endl;
    }
    // clear addrDscr
    regDscr[reg]->reg = zero;
    // clear regDscr
    regDscr[reg] = NULL;
  }
}

void regMap(std::ofstream & f, reg_t reg, sym* symb, bool load = true) {
  // TODO: sw/sb/... for non 4 byte
  // TODO: offset from $gp
  if (load) {
    f << '\t' << "lw " << reg2str[reg]+", -"<< symb->offset <<"($fp)";
    f << " # load into register (" + symb->name + ")"<< endl;
  }
  // add addrDscr entry
  symb->reg = reg;
  // add regDscr entry
  regDscr[reg] = symb;
}


void resetRegMaps(ofstream &f) {
  for(int reg = t0; reg <= t9; reg++){
    regFlush(f, (reg_t) reg);
  }
}


int currReg = s0;
reg_t getSymReg(const std::string & symName) {
  sym* symb = SymRoot->gLookup(symName);
  if(!symb) {
    // constants
    // array, struct too!!
    cout << "Not found "<< symName <<endl;
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


oprRegs getReg(std::ofstream & f, const irquad_t &q) {
  // has sym* of symbols of current operation
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  sym *src1 = lastdelta.src1Sym, *src2 = lastdelta.src2Sym;
  sym *dst = lastdelta.dstSym;
  oprRegs ret;

  /* constant */
  if(!src1) ret.src1Reg = zero;
  else {
    /* already in a reg */
    if (src1->reg != zero) ret.src1Reg = src1->reg;
    /* else get a new reg */
    else {
      /* find a free reg */
      int cand = t0;
      while (cand <= t9) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t) cand, src1);
          ret.src1Reg = (reg_t)cand;
          break;
        }
        cand++;
      }
      /* no reg is free */
      if(cand > t9) {
        regFlush(f, t9);
        regMap(f, t9, src1);
        ret.src1Reg = t9;
      }
    }
  }

  /* constant */
  if(!src2) ret.src2Reg = zero;
  else {
    /* already in a reg */
    if (src2->reg != zero) ret.src2Reg = src2->reg;
    /* else get a new reg */
    else {
      /* find a free reg */
      int cand = t0;
      reg_t cand1 = zero;
      while (cand <= t9) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t)cand, src2);
          ret.src2Reg = (reg_t)cand;
          break;
        }
        if(cand1 == zero && cand != ret.src1Reg)
          cand1 = (reg_t)cand;
        cand++;
      }
      /* no reg is free */
      if(cand > t9) {
        regFlush(f, cand1);
        regMap(f, cand1, src2);
        ret.src2Reg = cand1;
      }
    }
  }

  if(!dst) ret.dstReg = zero; // shoud never happen?
  else {
    /* check if one of src1/src2 register can be directly used */
    if (ret.src1Reg!=zero && src1->nxtuse == -1 && !src1->alive) {
      // soft flush (no need to store for dst) any existing register mapped to dst
      regFlush(f, dst->reg, false);
      // soft flush (we don't need src1 value further) src1Reg 
      regFlush(f, ret.src1Reg, false);
      // soft map (we still needs src1 value) dst to src1Reg
      regMap(f, ret.src1Reg, dst, false);
      ret.dstReg = ret.src1Reg;
    }
    /*
     ! Can't do this as if dstReg = sr2Reg and src1 is constant then it will 
     ! first load src1 into dstReg which will erase src2 content.
     ! Need to change logic if want to make this work.
    */
    // else if (ret.src2Reg!=zero && src2->nxtuse == -1 && !src2->alive) {
    //   // soft flush any existing register mapped to dst
    //   regFlush(f, dst->reg, false);
    //   // soft flush src2Reg  
    //   regFlush(f, ret.src2Reg, false);
    //   // soft map dst to src2Reg (we )
    //   regMap(f, ret.src2Reg, dst, false);
    //   ret.dstReg = ret.src2Reg;
    // }
    /* if already in a register */
    else if (dst->reg != zero) ret.dstReg = dst->reg;
    /* else get a new reg */
    else {
      /* find a free reg */
      int cand = t0;
      reg_t cand1 = zero;
      while (cand <= t9) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t)cand, dst, false);
          ret.dstReg = (reg_t)cand;
          break;
        }
        if(cand1 == zero && cand != ret.src1Reg && cand != ret.src2Reg)
          cand1 = (reg_t)cand;
        cand++;
      }
      /* no reg is free */
      if(cand > t9) {
        regFlush(f, cand1);
        regMap(f, cand1, dst, false);
        ret.dstReg = cand1;
      }
    }
  }
   return ret;
}


void dumpASM(ofstream &f, const vector<irquad_t> & IR) {
  // clear reg
  for(int i = 0; i<32; i++){
    regDscr[i] = NULL;
  }

  int lenIR = IR.size();
  int currleader = 0;
  cout<< "Leader at: " << 0 << endl;
  while(currleader < lenIR) {
    int nxtleader = getNxtLeader(IR, currleader);
    cout<< "Leader at: " << nxtleader << endl;
    // gen code for a main block
    // if label exist to this statement
    if(Labels.find(currleader) != Labels.end()) {
      resetRegMaps(f);
      f << "LABEL_" + to_string(currleader)+ ":"<< endl;
    }
    while(currleader < nxtleader) {
      //  TODO: flush, reset etc
      // // Flush before any jump
      // if(currleader == nxtleader-1) resetRegMaps(f);
      genASM(f, IR[currleader]);
      currleader++;
    }
  }
}


void genASM(std::ofstream & f, const irquad_t & quad) {
  
  deltaNxtUse lastdelta = nxtUse.step();

  if (quad.opr == "+" || quad.opr == "-" ||
      quad.opr == "*"|| quad.opr == "/" ||
      quad.opr == ">" || quad.opr == "<" ||
      quad.opr == "&&" || quad.opr == "||") binOpr(f, quad);
 
  else if (quad.opr == eps) assn(f, quad);
  
  else if (quad.opr == "goto") {
    resetRegMaps(f);
    f << "\t" <<"b LABEL_" + quad.src1 << endl;
  }

  else if (quad.opr == "ifgoto") {
    oprRegs regs = getReg(f, quad);
    resetRegMaps(f);
    f << "\t" <<"bnez " + reg2str[regs.src2Reg] + ", LABEL_" + quad.src1 << endl;
  }
  
  else if (quad.opr == "newScope") {
    // resetRegMaps(f);
    /* find scope */
    string scopeName = quad.src1;
    auto symtabs = SymRoot->currScope->subScopes; // currscope == root
    symtab * scopeTab;
    for (auto tab: symtabs) {
      if (tab->name == scopeName ) { scopeTab = tab; break; }
    }
    cout << "opening scope" + quad.src1<<endl;
    // change scope
    SymRoot->currScope = scopeTab;
    for (sym* symb: scopeTab->syms) {
      /* sanity checks */
      if (symb->reg != zero) 
        cout << "void genASM(std::ofstream & f, const irquad_t & quad) \"newscope\" error1"<<endl;
      if (symb->nxtuse != -1)
        cout << "void genASM(std::ofstream & f, const irquad_t & quad) \"newscope\" error3"<<endl;
      symb->reg = zero;
      // temproraies dead and variables are alive
      symb->alive = (symb->name[0] == '0') ? false : true;
      symb->nxtuse = -1;
    }
  }
  
  else if(quad.opr == "closeScope") {
    // resetRegMaps(f);
    // close scope
    SymRoot->currScope = SymRoot->currScope->parent;
  }

  else if(quad.opr == "func") funcStart(f, quad);
  
  else if (quad.opr == "return") {
    resetRegMaps(f);
    // TODO
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
  }

  else if (quad.opr == "function end") funcEnd(f, quad);


}


void funcStart(std::ofstream & f, const irquad_t & quad) {
  // resetRegMaps(f);
  currFunc = quad.src1;
  auto symtabs = SymRoot->currScope->subScopes; // currscope == root
  // search for function scope
  symtab * funTab;
  for (auto tab: symtabs) {
    if (tab->name == "func " + currFunc) { funTab = tab; break; }
  }
  // change scope
  SymRoot->currScope = funTab;
  // initialise reg for all symbols to "zero"
  for (sym* symb: funTab->syms) {
    /* sanity checks */
    if (symb->reg != zero) 
      cout << "void funcStart(std::ofstream & f, const irquad_t & quad) error1"<<endl;
    if (symb->nxtuse != -1)
      cout << "void funcStart(std::ofstream & f, const irquad_t & quad) error3"<<endl;
    /* redundant steps */
    symb->reg = zero;
    // temproraies dead and variables are alive
    symb->alive = (symb->name[0] == '0') ? false : true;
    symb->nxtuse = -1;
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


void funcEnd(std::ofstream & f, const irquad_t & quad) {
  // resetRegMaps(f);
  // close scope
  SymRoot->currScope = SymRoot->currScope->parent;
  f << currFunc + "_ret:" << endl;
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


void binOpr(std::ofstream & f, const irquad_t & q) {
  string opr = q.opr;
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  sym *src1 = lastdelta.src1Sym, *src2 = lastdelta.src2Sym;
  sym *dst = lastdelta.dstSym;
  
  // TODO: unsigned, float, ...
  // if(opr == "+" || opr == "-" || opr == "*" || opr == "/" ) {
    string instr;
    if      (opr == "+") instr = "add";
    else if (opr == "-") instr = "sub";
    else if (opr == "*") instr = "mul";
    else if (opr == "/") instr = "div";
    else if (opr == "==") instr = "seq";
    else if (opr == ">") instr = "sgt";
    else if (opr == "<") instr = "slt";
    else if (opr == ">=") instr = "sge";
    else if (opr == "<=") instr = "sle";
    else if (opr == "&&") instr = "and";
    else if (opr == "||") instr = "or";

    // dst = src1 + src2  
    oprRegs regs = getReg(f, q);
    string src2_str = (regs.src2Reg == zero) ? q.src2 : reg2str[regs.src2Reg];
    // src1 is constant
    if (regs.src1Reg == zero) {
      f << '\t' << "li " << reg2str[regs.dstReg] + ", " + q.src1 << " # load constant"<< endl;
      f << '\t' << instr + " " << reg2str[regs.dstReg] + ", " + reg2str[regs.dstReg] + ", " + src2_str;
      f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
      return;
    }
    f << '\t' << instr + " " << reg2str[regs.dstReg] + ", " + reg2str[regs.src1Reg] + ", " + src2_str;
    f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
  // }
}


void assn(ofstream & f, const irquad_t &q) {
    oprRegs regs = getReg(f, q);
    /* just remapping resgisters */
    if (regs.dstReg == regs.src1Reg) {
      f << "\t # " + q.dst + " = " + reg2str[regs.src1Reg] <<endl;
    }
    /* load a constant */
    else if(regs.src1Reg == zero) {
      // TODO other types
      f << '\t' << "li " << reg2str[regs.dstReg] + ", " + q.src1;
      f << " # " + q.dst <<endl;
    }
    /* need to move */
    else {
      f << '\t' << "move " << reg2str[regs.dstReg] + ", " + reg2str[regs.src1Reg] ;
      f << " # move " + q.dst + " = " + q.src1 << endl;
    }
}


int getNxtLeader(const vector<irquad_t> & IR, int leader) {
  int lenIR = IR.size();
  int nxtLeader = lenIR;
  // find next leader
  for(auto idx = leader; idx < lenIR; idx++) {
    if(IR[idx].opr == "goto" || IR[idx].opr == "ifgoto" ||
       IR[idx].opr == "call" || IR[idx].opr == "func" ||
       IR[idx].opr == "return" || IR[idx].opr == "newScope" ||
       IR[idx].opr == "closeScope" || IR[idx].opr == "function end" ||
       Labels.find(idx+1) != Labels.end()
       ) 
    {
      nxtLeader = idx + 1;
      break;
    }
  }

  bool dbg_print = false;
  if(leader == 1) dbg_print = true;

  nxtUse.clear();
  ofstream csv_out2;
  if (dbg_print) csv_out2.open("1_tmp.csv");
  // backward pass in the current main block

  for (int idx = nxtLeader - 1; idx >= leader; idx--) {
    deltaNxtUse delta;
    sym* dstSym = SymRoot->gLookup(IR[idx].dst);
    sym* src1Sym = SymRoot->gLookup(IR[idx].src1);
    sym* src2Sym = SymRoot->gLookup(IR[idx].src2);
    
    if (dbg_print) SymRoot->dump(csv_out2);
    if (dbg_print) csv_out2 << "\n\n\n##################\n\n\n"<<endl;
    // break;
    if (dstSym) {
      delta.dstSym = dstSym;
      delta.dstNxtUse = dstSym->nxtuse;
      delta.dstAlive = dstSym->alive;
      if (dstSym->name[0] == '0')
        dstSym->alive = false;
      dstSym->nxtuse = -1;
    }

    if (src1Sym) {
      delta.src1Sym = src1Sym;
      delta.src1NxtUse = src1Sym->nxtuse;
      delta.src1Alive = src1Sym->alive;
      if (src1Sym->name[0] == '0')
        src1Sym->alive = true;
      src1Sym->nxtuse =  idx - leader;
    }

    if (src2Sym) {
      delta.src2Sym = src2Sym;
      delta.src2NxtUse = src2Sym->nxtuse;
      delta.src2Alive = src2Sym->alive;
      if (src2Sym->name[0] == '0')
        src2Sym->alive = true;
      src2Sym->nxtuse =  idx - leader;
    }
    nxtUse.deltas.push_back(delta);
  } // backward pass in the current main block
  if (dbg_print) SymRoot->dump(csv_out2);
  return nxtLeader;
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
