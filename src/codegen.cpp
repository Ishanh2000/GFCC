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
  "$gp", "$sp", "$fp", "$ra",                                // global data ptr, stack ptr, frame ptr, return addr

  "$f0", "$f1", "$f2", "$f3",                                // Function-returned values
  "$f4", "$f5", "$f6", "$f7", "$f8", "$f9", "$f10", "$f11",  // Temporary values
  "$f12", "$f13", "$f14", "$f15",                            // Arguments passed into a function
  "$f16", "$f17", "$f18", "$f19",                            // More Temporary values
  "$f20", "$f21", "$f31",                                    // Saved values
};


sym* regDscr[32];
_nxtUse nxtUse;
string currFunc = "";
unsigned int paramOffset = 40;
bool semanticErr = false;

void resetCodegen() { // TODO: register flushing, etc.
  currFunc = "";
  paramOffset = 40;
  semanticErr = false;
}


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


void regFlush(std::ofstream & f, reg_t reg, bool store = true) {
  if(regDscr[reg]) {
    // TODO: sw/sb/... for non 4 byte
    // TODO: offset from $gp
    // always do in case of global
    bool isArr = regDscr[reg]->type->grp() == ARR_G;
    if (store && !isArr) {
      f << '\t' << "sw " << reg2str[reg] + ", -"<< regDscr[reg]->offset <<"($fp)";
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
  /* array which is not an argument to the function */
  bool isArr = symb->type->grp() == ARR_G && !symb->isArg;
  if(isArr) {
    f << '\t' << "subu " << reg2str[reg] + ", $fp, " + to_string(symb->offset);
    f << " # load front addr of array \"" + symb->name + "\" into register "<< endl;
  }
  else if (load) {
    f << '\t' << "lw " << reg2str[reg] + ", -"<< symb->offset <<"($fp)";
    f << " # load into register (" + symb->name + ")"<< endl;
  }
  // add addrDscr entry
  symb->reg = reg;
  // add regDscr entry
  regDscr[reg] = symb;
}


void resetRegMaps(ofstream &f, bool store = true) {
  for(int reg = t0; reg <= t9; reg++){
    regFlush(f, (reg_t) reg, store);
  }
}


// int currReg = s0;
// reg_t getSymReg(const std::string & symName) {
//   sym* symb = SymRoot->gLookup(symName);
//   if(!symb) {
//     // constants
//     // array, struct too!!
//     cout << "Not found "<< symName <<endl;
//     return zero;
//   }

//   if(symb->reg != zero)
//     return symb->reg;
//   else {
//     symb->reg = (reg_t) currReg++; // ! adhoc
//     regDscr[symb->reg] = symb;
//     return symb->reg;
//   }
// }


oprRegs getReg(std::ofstream & f, const irquad_t &q) {
  // has sym* of symbols of current operation
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  sym *src1 = lastdelta.src1Sym, *src2 = lastdelta.src2Sym;
  sym *dst = lastdelta.dstSym;
  oprRegs ret;

  /* return value */
  if (q.src1 == "$retval") {ret.src1Reg = v0;}
  /* constant */
  else if(!src1) ret.src1Reg = zero;
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
  } // end get reg for src1

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
  } // end get reg for src2

  if(!dst) ret.dstReg = zero;
  else {
    /* check if one of src1/src2 register can be directly used */
    // ! don't do it if dest is of the type "a[1][2]..."
    if (lastdelta.dstType == 0 && ret.src1Reg!=zero && src1 && src1->nxtuse == -1 && !src1->alive) {
      // soft flush (no need to store for dst) any existing register mapped to dst
      regFlush(f, dst->reg, false);
      // // soft flush (we don't need src1 value further) src1Reg 
      // hard flush (may need src1 value again)
      regFlush(f, ret.src1Reg);
      // soft map (we still needs src1 value) dst to src1Reg
      regMap(f, ret.src1Reg, dst, false);
      ret.dstReg = ret.src1Reg;
    }
    /*
     ! Can't do this as if dstReg = src2Reg and src1 is constant then it will 
     ! first load src1 into dstReg which will erase src2 content.
     ! Need to change logic if want to make this work.
    */
    // else if (ret.src2Reg!=zero && src2->nxtuse == -1 && !src2->alive) {
    //   // soft flush any existing register mapped to dst
    //   regFlush(f, dst->reg, false);
    //   // soft flush src2Reg  
    //   regFlush(f, ret.src2Reg);
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
  } // end get reg for dst

   return ret;
}


void dumpASM(ofstream &f, vector<irquad_t> & IR) {
  f << "\t\t.data" << endl; // first print static data (strings)
  int l = StrDump.size();
  for (int i = 0; i < l; i++) {
    f << "string_" << i << ":\t\t" << StrDump[i].encoding << "\t\t\"" << StrDump[i].contents << "\"" << endl;
  }

  f << endl << endl;
  f << "\t\t.text" << endl << endl; // code section begins
  
  for(int i = 0; i < 32; i++) regDscr[i] = NULL; // clear regs

  int lenIR = IR.size();
  int currleader = 0;
  cout<< "Leader at: " << 0 << endl;
  while(currleader < lenIR) {
    int nxtleader = getNxtLeader(IR, currleader);
    cout<< "Leader at: " << nxtleader << endl;
    
    // if label exist to this statement
    if(Labels.find(currleader) != Labels.end()) {
      resetRegMaps(f);
      f << "LABEL_" + to_string(currleader)+ ":"<< endl;
    }
    else if(IR[currleader].opr == "label") {
      resetRegMaps(f);
      f << IR[currleader].src1+ ":"<< endl;
    }

    // gen code for a main block
    while(currleader < nxtleader) {
      //  TODO: flush, reset etc
      f << endl << "#### "; dumpIRCode(f, 5, currleader, IR[currleader]); f << " ####" << endl;
      genASM(f, IR[currleader]);
      currleader++;
    }
  }
}


void genASM(ofstream & f, irquad_t & quad) {
  if (quad.src1.substr(0, 2) == "0s") quad.src1.replace(0, 2, "string");
  if (quad.src2.substr(0, 2) == "0s") quad.src2.replace(0, 2, "string");
  
  deltaNxtUse lastdelta = nxtUse.step();

  if (quad.opr == "+" || quad.opr == "-" ||
      quad.opr == "*" || quad.opr == "/" ||
      quad.opr == ">" || quad.opr == "<" ||
      quad.opr == ">=" || quad.opr == "<=" ||
      quad.opr == "==" || quad.opr == "&&" || 
      quad.opr == "||" || quad.opr == "&"|| 
      quad.opr == "|"||quad.opr == "<<"||
      quad.opr == ">>"||quad.opr == "^") binOpr(f, quad);
 
  else if (quad.opr == eps) assn(f, quad);
  
  else if (quad.opr == "goto") {
    // resetRegMaps(f);
    string src1 = quad.src1;
    cout << src1 <<endl;
    if(!src1.empty() &&  src1[0] == 'U'); // TODO: use better check
    else src1 = ("LABEL_" + src1);

    f << "\t" <<"b " + src1 << endl;
  }

  else if (quad.opr == "ifgoto") {
    oprRegs regs = getReg(f, quad);
    // resetRegMaps(f);
    string src2Addr = loadArrAddr(f, lastdelta.src2Sym, lastdelta.src2ArrSymb,
                                lastdelta.src2ArrOff, lastdelta.src2Type, "1");
    if (src2Addr != "") {
      f << '\t' << "lw $a3 , " + src2Addr << endl;
      f << "\t" <<"bnez $a3, LABEL_" + quad.src1 << endl;
    }
    else f << "\t" <<"bnez " + reg2str[regs.src2Reg] + ", LABEL_" + quad.src1 << endl;
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
    cout << "opening scope" + quad.src1 << endl;
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
    cout << "closing " + quad.src1<<endl;
    SymRoot->currScope = SymRoot->currScope->parent;
  }

  else if(quad.opr == "func") funcStart(f, quad);
  
  else if(quad.opr == "param") {
    
    oprRegs regs = getReg(f, quad);
    if (regs.src1Reg == zero) {
      /* constant param */
      // TODO: infer size from const or add a compulsory "temp = const" intr in 3ac
      paramOffset += 4;
      // TODO: make type-based load, store functions
      string loadInst = "li";
      if(quad.src1.substr(0,7) == "string_")
        loadInst = "la";
      f << '\t' <<  loadInst+ " " << reg2str[a0] + ", " + quad.src1 << endl;
      f << '\t' << "sw " << reg2str[a0] + ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
      f << " # load parameter to func" << endl;
    }
    else {
      int size = lastdelta.src1Sym->size;
      string paramAddr = loadArrAddr(f, lastdelta.src1Sym, lastdelta.src1ArrSymb,
                                      lastdelta.src1ArrOff, lastdelta.src1Type, "1");
      if(paramAddr != "") {
        size = getSize(((Arr *)lastdelta.src1Sym->type)->item);
        paramOffset += size;
        f << '\t' << "lw $a3 , " + paramAddr << endl;
        f << '\t' << "sw " << "$a3, -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
        f << " # load parameter to func" << endl;
      }
      else {
        if(lastdelta.src1Sym->type->grp() == ARR_G)
        size = 4; // store only pointer to the array in stack
        paramOffset += size;
        f << '\t' << "sw " << reg2str[regs.src1Reg] + ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
        f << " # load parameter to func" << endl;
      }
    }
  }

  else if(quad.opr == "call") {
    // reset param offset
    paramOffset = 40;
    resetRegMaps(f);
    f << '\t' << "jal " << quad.src1 << " # call " + quad.src1 << endl;
  }

  else if (quad.opr == "return") {
    // resetRegMaps(f);
    // TODO
    oprRegs regs = getReg(f, quad);
    if (regs.src1Reg == zero) {
      f << '\t' << "li " << reg2str[v0] + ", " + quad.src1;
      f << " # load return value" << endl;
    }
    else {
      string src1Addr = loadArrAddr(f, lastdelta.src1Sym, lastdelta.src1ArrSymb,
                                      lastdelta.src1ArrOff, lastdelta.src1Type, "1");
      if(src1Addr!= ""){
        f << '\t' << "lw $a3 , " + src1Addr << endl;
        f << '\t' << "move " + reg2str[v0] + ", $a3" << endl;
      }
      else{
        f << '\t' << "move " << reg2str[v0] + ", " + reg2str[regs.src1Reg];
        f << " # load return value" << endl;
      }
    }  
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
  }

  else if (quad.opr == "function end") funcEnd(f, quad);
}


void funcStart(std::ofstream & f, const irquad_t & quad) {
  // resetRegMaps(f);
  currFunc = quad.src1;
  f << "\t.globl " + currFunc << endl;
  auto symtabs = SymRoot->currScope->subScopes; // currscope == root
  // search for function scope
  symtab * funTab;
  for (auto tab: symtabs) {
    if (tab->name == "func " + currFunc) { funTab = tab; break; }
  }
  // change scope
  SymRoot->currScope = funTab;
  // initialise reg for all symbols to "zero"
  // cout << "C:" << quad.src1 << endl;
  // cout << "A:" << funTab << endl;
  // cout << "B:" << funTab->name << endl;
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

  f << currFunc << ":" << endl;
  f << '\t' << "sw"<< " $ra, -4($sp)"<< " # return address" << endl;
  f << '\t' << "sw"<< " $fp, -8($sp)"<< " # frame pointer of caller" << endl;
  f << '\t' << "move" << " $fp, $sp" << " # begin new frame" << endl;
  f << '\t' << "subu"<< " $sp, $sp, "<< funTab->offset << " # expad frame" << endl; // 40 for possible $t0---$t9
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
  // soft flush every register
  resetRegMaps(f, false);
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
    if   (opr == "+") instr     = "addu";
    else if (opr == "-") instr  = "subu";
    else if (opr == "*") instr  = "mul";
    else if (opr == "/") instr  = "div";
    else if (opr == "==") instr = "seq";
    else if (opr == ">") instr  = "sgt";
    else if (opr == "<") instr  = "slt";
    else if (opr == ">=") instr = "sge";
    else if (opr == "<=") instr = "sle";
    else if (opr == "&&") instr = "and";  // TODO $a = ($a == 0)
    else if (opr == "||") instr = "or";
    else if (opr == "&") instr = "and";
    else if (opr == "|") instr = "or";
    else if (opr == "<<") instr = "sll";
    else if (opr == ">>") instr = "sra";
    else if (opr == "^") instr = "xor";

    // dst = src1 + src2  
    oprRegs regs = getReg(f, q);
    string addrDst = loadArrAddr(f,lastdelta.dstSym, 
                                lastdelta.dstArrSymb, 
                                lastdelta.dstArrOff, lastdelta.dstType, "0");
    string addrSrc1 = loadArrAddr(f, lastdelta.src1Sym, 
                                   lastdelta.src1ArrSymb, 
                                   lastdelta.src1ArrOff, lastdelta.src1Type, "1");
    string addrSrc2 = loadArrAddr(f, lastdelta.src2Sym, 
                                   lastdelta.src2ArrSymb, 
                                   lastdelta.src2ArrOff, lastdelta.src2Type, "2");
    if(addrSrc1 != "") {
      f << '\t' << "lw $a3 , " + addrSrc1 << endl;
      regs.src1Reg = a3;
    }
    if(addrSrc2 != "") {
      f << '\t' << "lw $v1 , " + addrSrc2 << endl;
      regs.src2Reg = v1;
    }

    string src2_str = (regs.src2Reg == zero) ? q.src2 : reg2str[regs.src2Reg];


    if (addrDst != "") {
      // src1 is constant
      if (regs.src1Reg == zero) {
        f << '\t' << "li " << "$a3, " + q.src1 << " # load constant"<< endl;
        f << '\t' << instr + " " << "$a3, $a3, " + src2_str;
        f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
      }
      else {
        f << '\t' << instr + " " << "$a3, " + reg2str[regs.src1Reg] + ", " + src2_str;
        f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
      }
      /* eg. sw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << "sw "
        <<  "$a3, " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    
    else{
      // src1 is constant
      if (regs.src1Reg == zero) {
        f << '\t' << "li " << reg2str[regs.dstReg] + ", " + q.src1 << " # load constant"<< endl;
        f << '\t' << instr + " " << reg2str[regs.dstReg] + ", " + reg2str[regs.dstReg] + ", " + src2_str;
        f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
        return;
      }
      f << '\t' << instr + " " << reg2str[regs.dstReg] + ", " + reg2str[regs.src1Reg] + ", " + src2_str;
      f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
    }
  // }
}


void assn(ofstream & f, const irquad_t &q) {
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  oprRegs regs = getReg(f, q);
  /* just remapping resgisters */
  string addrDst = loadArrAddr(f,lastdelta.dstSym, 
                                lastdelta.dstArrSymb, 
                                lastdelta.dstArrOff, lastdelta.dstType, "0");
  string addrSrc1 = loadArrAddr(f, lastdelta.src1Sym, 
                                   lastdelta.src1ArrSymb, 
                                   lastdelta.src1ArrOff, lastdelta.src1Type, "1");
  if (regs.dstReg == regs.src1Reg && lastdelta.dstType == 0) {
    f << "\t # " + q.dst + " = " + reg2str[regs.src1Reg] <<endl;
  }
  /* load a constant */
  else if(regs.src1Reg == zero) {
    // TODO other types
    if(addrDst != ""){ // dst is an array
      // TODO: non-constant offset -- lastdelta.dstArrSymb

      f << '\t' << "li $a3, " + q.src1 << endl;

      f << '\t' << "sw "
        <<  "$a3, " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    else {
      f << '\t' << "li " << reg2str[regs.dstReg] + ", " + q.src1;
      f << " # " + q.dst <<endl;
    }
  }

  /* need to move */
  else {
    if(addrDst != "" && addrSrc1 != ""){ // both array
      /* eg. lw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << "lw $a3 , " + addrSrc1 << endl;

      /* eg. sw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << "sw "
        <<  "$a3, " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    else if(addrDst != "" && addrSrc1 == ""){ // dst array
      /* eg. sw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << "sw "
        <<  reg2str[regs.src1Reg] + ", " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    else if(addrDst == "" && addrSrc1 != ""){ // src1 array
      /* eg. lw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << "lw $a3 , " + addrSrc1 << endl;
      f << '\t' << "move " << reg2str[regs.dstReg] + ", " + "$a3" << endl;
    }
    else if(addrDst == "" && addrSrc1 == ""){ // both non-array
      f << '\t' << "move " << reg2str[regs.dstReg] + ", " + reg2str[regs.src1Reg] ;
      f << " # move " + q.dst + " = " + q.src1 << endl;
    }
  }
}

/** 1. Find next leader
 *  2. Process the next mainblock
 *      a. backward pass to get "alive", "nxtUse"
 *      b. search operands in symbol table
 *      c. process for array, struct, etc
 * 
**/
int getNxtLeader(vector<irquad_t> & IR, int leader) {
  int lenIR = IR.size();
  int nxtLeader = lenIR;
  // find next leader
  for(auto idx = leader; idx < lenIR; idx++) {
    if(IR[idx].opr == "goto" || IR[idx].opr == "ifgoto" ||
       IR[idx].opr == "call" || IR[idx].opr == "return" ||
       IR[idx].opr == "newScope" || IR[idx].opr == "closeScope" ||
       IR[idx].opr == "function end" || IR[idx].opr == "func" ||
       IR[idx+1].opr == "label" || Labels.find(idx+1) != Labels.end()
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
  if (dbg_print) csv_out2.open("tests/1_tmp.csv");
  // backward pass in the current main block

  for (int idx = nxtLeader - 1; idx >= leader; idx--) {
    deltaNxtUse delta;

    int boxStart, boxEnd;

    boxStart = IR[idx].dst.find_first_of('[');
    boxEnd = IR[idx].dst.find_first_of(']');

    if(boxStart >= 0 && boxEnd >= 0) {
      delta.dstType = 1;
      string tmp = IR[idx].dst.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.dstArrOff.push_back(IR[idx].dst.substr(boxStart+1, boxEnd-boxStart-1));
        delta.dstArrSymb.push_back(SymRoot->gLookup(delta.dstArrOff.back()));
        boxStart = IR[idx].dst.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].dst.find_first_of(']', boxEnd+1);
      }
      IR[idx].dst = tmp;
    }

    boxStart = IR[idx].src1.find_first_of('[');
    boxEnd = IR[idx].src1.find_first_of(']');

    if(boxStart >= 0 && boxEnd >= 0) {
      delta.src1Type = 1;
      string tmp = IR[idx].src1.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.src1ArrOff.push_back(IR[idx].src1.substr(boxStart+1, boxEnd-boxStart-1));
        delta.src1ArrSymb.push_back(SymRoot->gLookup(delta.src1ArrOff.back()));
        boxStart = IR[idx].src1.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].src1.find_first_of(']', boxEnd+1);
      }
      IR[idx].src1 = tmp;
    }

    boxStart = IR[idx].src2.find_first_of('[');
    boxEnd = IR[idx].src2.find_first_of(']');

    if(boxStart >= 0 && boxEnd >= 0) {
      delta.src2Type = 1;
      string tmp = IR[idx].src2.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.src2ArrOff.push_back(IR[idx].src2.substr(boxStart+1, boxEnd-boxStart-1));
        delta.src2ArrSymb.push_back(SymRoot->gLookup(delta.src2ArrOff.back()));
        boxStart = IR[idx].src2.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].src2.find_first_of(']', boxEnd+1);
      }
      IR[idx].src2 = tmp;
    }

    sym* dstSym = SymRoot->gLookup(IR[idx].dst);
    sym* src1Sym = SymRoot->gLookup(IR[idx].src1);
    sym* src2Sym = SymRoot->gLookup(IR[idx].src2);
    
    if (dbg_print) SymRoot->dump(csv_out2);
    if (dbg_print) csv_out2 << "\n\n\n##################\n\n\n"<<endl;
    // break;
    if (dstSym) {
      delta.dstSym    = dstSym;
      delta.dstNxtUse = dstSym->nxtuse;
      delta.dstAlive  = dstSym->alive;
      if (dstSym->name[0] == '0')
        dstSym->alive = false;
      dstSym->nxtuse = -1;
    }

    if (src1Sym) {
      delta.src1Sym    = src1Sym;
      delta.src1NxtUse = src1Sym->nxtuse;
      delta.src1Alive  = src1Sym->alive;
      if (src1Sym->name[0] == '0')
        src1Sym->alive = true;
      src1Sym->nxtuse =  idx - leader;
    }

    if (src2Sym) {
      delta.src2Sym    = src2Sym;
      delta.src2NxtUse = src2Sym->nxtuse;
      delta.src2Alive  = src2Sym->alive;
      if (src2Sym->name[0] == '0')
        src2Sym->alive = true;
      src2Sym->nxtuse =  idx - leader;
    }
    nxtUse.deltas.push_back(delta);
  } // backward pass in the current main block
  if (dbg_print) SymRoot->dump(csv_out2);
  return nxtLeader;
}

string loadArrAddr(ofstream & f, const sym* symb,
                        vector<sym*> offsetSymb, 
                        vector<string> offset, int type, string pos) {
  /*
    * pos:  0 for dst (use $a0, $a3)
    *       1 for src1 (use $a1, $a3)
    *       2 for src2 (use $a2, $a3)
  */

  if(!symb || type != 1) {
    // cout << "string loadArrAddr: Called for non-array" << endl;
    return "";
  }

  string addrReg = "$a" + pos;

  f << "\t #### <Load array address> ###" << endl;
  
  
  vector<int> dimSize;
  Arr *a = (Arr *) symb->type;
  for(auto dim: a->dims) {
    int * sizePtr = eval(dim);
    if(!sizePtr) {
      cout << "string loadArrAddr: eval(dim) failed for a dimension" << endl;
      dimSize.push_back(INT16_MAX);
    }
    else dimSize.push_back(*sizePtr);
  }
  
  /* for array part */
  if(dimSize.size() > offset.size())
    cout << "string loadArrAddr: some problem in semantic analysis" << endl;
  
  int constOffset = 0, dimWidth = getSize(a->item);
  bool allConst = true;
  for(int i = dimSize.size()-1; i>=0; i--) {
    if(!offsetSymb[i]) {
      /* constant  operand*/
      constOffset += stoi(offset[i]) * dimWidth;
    }
    else {
      /* variable offset */
      /* eg. lw $a3, -44($fp) */
      f << '\t' << "lw $a3, -" + to_string(offsetSymb[i]->offset) + "($fp)"
        << " # load " + offsetSymb[i]->name << endl;
      /* eg. mul $a3, $a3, dimWidth */
      if (dimWidth != 1)
        f << '\t' << "mul $a3, $a3, " + to_string(dimWidth)
          << " # multiply with dimWidth" << endl;
      
      if(allConst){
        allConst = false;
        // base + currOffset
        /* eg. addu $a0, $t0, $a3 */
        f << '\t' << "addu " + addrReg + ", " + reg2str[symb->reg] +", $a3"
          << " # offset calc" << endl;
      }
      else 
        // offsetTillNow + currOffset
        /* eg. addu $a0, $a0, $a3 */
        f << '\t' << "addu " + addrReg + ", " + addrReg + ", $a3" 
          << " # offset calc" << endl;
    }
    dimWidth *= dimSize[i];
  }
  f << "\t #### </Load array address> ###" << endl;
  /* eg. "10($t0)" */
  if(allConst) return to_string(constOffset) + "("+reg2str[symb->reg]+")";
  /* eg. "$a0" */
  else {
    if (constOffset)
    /* addu $a0, $a0, constOffset */
    f << '\t' << "addu " + addrReg + ", " + addrReg + ", " + to_string(constOffset) 
          << " # add const offset" << endl;
    return "("+addrReg+")";
  }

  /* for pointer part */
  // TODO: pointer
  return "aa";
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
