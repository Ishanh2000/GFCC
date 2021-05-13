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
  "$f16", "$f17", "$f18", "$f19",                            // More Temporary values
  "$f12", "$f13", "$f14", "$f15",                            // Arguments passed into a function
  "$f20", "$f21", "$f31",                                    // Saved values
};


sym* regDscr[55];
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
  if(delta.dst.Sym) {
    delta.dst.Sym->nxtuse = delta.dst.NxtUse;
    delta.dst.Sym->alive = delta.dst.Alive;
  }
  if(delta.src1.Sym) {
    delta.src1.Sym->nxtuse = delta.src1.NxtUse;
    delta.src1.Sym->alive = delta.src1.Alive;
  }
  if(delta.src2.Sym) {
    delta.src2.Sym->nxtuse = delta.src2.NxtUse;
    delta.src2.Sym->alive = delta.src2.Alive;
  }
  return delta;
}

inst_t getInst(class Type * t)
{
  inst_t I;
  I.load_instr = "lw"; I.store_instr = "sw";
  I.load_const = "li"; I.move_instr = "move";
  if( isReal(t) )
  {
    I.load_instr = "l.s"; I.store_instr = "s.s";
    I.load_const = "li.s"; I.move_instr = "mov.s";
  }
  else if( isChar(t) )
  {
    I.load_instr = "lb"; I.store_instr = "sb";
    I.load_const = "li"; I.move_instr = "move";
  }
  else if( isShort(t) )
  {
    I.load_instr = "lh"; I.store_instr = "sh";
    I.load_const = "li"; I.move_instr = "move";
  }
  else if(isArr(t)) {
    Arr * a = (Arr *)t;
    return getInst(a->item);
  }
  return I;
}

tmp_regs getTmpRegs(class Type * t)
{
  tmp_regs R;
  R.retreg1 = v0; R.retreg2 = v1; R.exreg = a3;
  if( isReal(t) )
  {
    R.retreg1 = f0; R.retreg2 = f2; R.exreg = f14;
  }
  else if(isArr(t)) {
    Arr * a = (Arr *)t;
    return getTmpRegs(a->item);
  }
  return R;
}

void regFlush(std::ofstream & f, reg_t reg, bool store = true) {
  if(regDscr[reg]) {
    // TODO: sw/sb/... for non 4 byte
    // TODO: offset from $gp
    // always do in case of global
    inst_t I = getInst(regDscr[reg]->type);
    
    // bool isArr = regDscr[reg]->type->grp() == ARR_G;
    if (store && !isArr(regDscr[reg]->type) && !isStruct(regDscr[reg]->type)) {
      if(regDscr[reg]->parent == SymRoot->root) {
        if(!isFuncType(regDscr[reg]->type)) 
          f << '\t' << I.store_instr << " " << reg2str[reg] + ", global_" + regDscr[reg]->name;
      }
      else {
        f << '\t' << I.store_instr << " " << reg2str[reg] + ", -"<< regDscr[reg]->offset <<"($fp)";
      }
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
  inst_t I = getInst(symb->type);
  /* array which is not an argument to the function */
  if(isArr(symb->type) ||  isStruct(symb->type)) {
    if(!symb->isArg) { // Not an argument
      f << '\t' << "subu " << reg2str[reg] + ", $fp, " + to_string(symb->offset);
      f << " # load front addr of array \"" + symb->name + "\" into register "<< endl;
    }
    else {
      f << '\t' << "lw " << reg2str[reg] + ", -"<< symb->offset <<"($fp)";
    f << " # load argument array addr into register (" + symb->name + ")"<< endl;
    }
  }
  else if (load) {
    if(symb->parent == SymRoot->root) {
      if(isFuncType(symb->type))
        f << '\t' << "la " << reg2str[reg] +  ", " + symb->name;
      else
        f << '\t' << I.load_instr << " " << reg2str[reg] +  ", global_" + symb->name;
    }
      
    else 
      f << '\t' << I.load_instr << " " << reg2str[reg] + ", -"<< symb->offset <<"($fp)";
    f << " # load into register (" + symb->name + ")"<< endl;
  }
  // add addrDscr entry
  symb->reg = reg;
  // add regDscr entry
  regDscr[reg] = symb;
}


void resetRegMaps(ofstream &f, bool store = true) {
  /* general registers */
  for(int reg = t0; reg <= t9; reg++){
    regFlush(f, (reg_t) reg, store);
  }
  /* float registers */
  for(int reg = f4; reg <= f19; reg++){
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
  sym *src1 = lastdelta.src1.Sym, *src2 = lastdelta.src2.Sym;
  sym *dst = lastdelta.dst.Sym;
  oprRegs ret;
  
  tmp_regs src1regs = getTmpRegs(q.t_src1);
  tmp_regs src2regs = getTmpRegs(q.t_src2);
  tmp_regs dstregs = getTmpRegs(q.t_dst);
  
  /* return value */
  if (q.src1 == "$retval") {ret.src1Reg = src1regs.retreg1;}
  /* constant */
  else if(!src1) ret.src1Reg = zero;
  else {
    /* already in a reg */
    if (src1->reg != zero) ret.src1Reg = src1->reg;
    /* else get a new reg */
    else {
      /* find a free reg */
      int cand = t0;
      int end = t9;
      int inc = 1;
      if( isReal(q.t_src1) )
      {
        cand = f4; end = f18; inc = 2;
      }
      while (cand <= end) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t) cand, src1);
          ret.src1Reg = (reg_t)cand;
          break;
        }
        cand += inc;
      }
      /* no reg is free */
      if(cand > end) {
        regFlush(f, (reg_t)end);
        regMap(f, (reg_t)end, src1);
        ret.src1Reg = (reg_t)end;
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
      int end = t9;
      int inc = 1;
      if( isReal(q.t_src2) )
      {
        cand = f4; end = f18; inc = 2;
      }
      reg_t cand1 = zero;
      while (cand <= end) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t)cand, src2);
          ret.src2Reg = (reg_t)cand;
          break;
        }
        if(cand1 == zero && cand != ret.src1Reg)
          cand1 = (reg_t)cand;
        cand += inc;
      }
      /* no reg is free */
      if(cand > end) {
        regFlush(f, (reg_t)cand1);
        regMap(f, (reg_t)cand1, src2);
        ret.src2Reg = cand1;
      }
    }
  } // end get reg for src2

  if(!dst) ret.dstReg = zero;
  else {
    /* check if one of src1/src2 register can be directly used */
    // ! don't do it if dest is of the type "a[1][2]..."
    if (lastdelta.dst.Type == 0 && ret.src1Reg!=zero && src1 && src1->nxtuse == -1 && !src1->alive && 0) {
      
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
      int end = t9;
      int inc = 1;
      if( isReal(q.t_dst) )
      {
        // f << "haha" << endl;
        cand = f4; end = f18; inc = 2;
      }
      reg_t cand1 = zero;
      while (cand <= end) {
        if(!regDscr[cand]) {
          regMap(f, (reg_t)cand, dst, false);
          ret.dstReg = (reg_t)cand;
          break;
        }
        if(cand1 == zero && cand != ret.src1Reg && cand != ret.src2Reg)
          cand1 = (reg_t)cand;
        cand += inc;
      }
      /* no reg is free */
      if(cand > end) {
        regFlush(f, (reg_t)cand1);
        regMap(f, (reg_t)cand1, dst, false);
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
    str_t &s = StrDump[i];
    if(s.glbName != eps)
      f << "global_" << s.glbName << ":\t\t" << s.encoding << "\t\t" << s.contents << endl;
  }
  for (int i = 0; i < l; i++) {
    str_t &s = StrDump[i];
    if(s.glbName == eps)
      f << "string_" << i << ":\t\t" << s.encoding << "\t\t" << s.contents << endl;
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
  

  if (quad.src2 != eps && (
      quad.opr == "+" || quad.opr == "-" ||
      quad.opr == "*" || quad.opr == "/" ||
      quad.opr == "real+" || quad.opr == "real-" ||
      quad.opr == "real*" || quad.opr == "real/" ||
      quad.opr == ">" || quad.opr == "<" ||
      quad.opr == ">=" || quad.opr == "<=" ||
      quad.opr == "==" || quad.opr == "&&" || 
      quad.opr == "||" || quad.opr == "&"|| 
      quad.opr == "|"||quad.opr == "<<"||
      quad.opr == ">>"||quad.opr == "^"
      )) binOpr(f, quad);

  else if (quad.opr == eps) assn(f, quad);

  else if (quad.opr == "int2real")
  {
    // Instr
    inst_t Isrc1 = getInst(quad.t_src1);
    inst_t Idst = getInst(quad.t_dst);
    // temp registor for src
    tmp_regs Rsrc1 = getTmpRegs(quad.t_src1);
    // tmp registor for dst
    tmp_regs Rdst = getTmpRegs(quad.t_dst);

    oprRegs Reg = getReg(f,quad);
    string addrDst = loadArrAddr(f, lastdelta.dst, "0");
    string addrSrc1 = loadArrAddr(f, lastdelta.src1, "1");
    if(addrSrc1 != "") { // src1 of type a[][]
      f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + addrSrc1 << endl;
      Reg.src1Reg = Rsrc1.exreg;
    }

    if( Reg.src1Reg == zero ) // constant src1
    {
      f << '\t' << "li $a3, " << quad.src1 << endl;
      Reg.src1Reg = a3;
    }
    if(addrDst != "") { // dst of type a[][]
      f << '\t' << "mtc1 " << reg2str[Reg.src1Reg] << ", " << reg2str[Rdst.exreg] << endl;
      f << '\t' << "cvt.s.w " << reg2str[Rdst.exreg] << ", " << reg2str[Rdst.exreg] << endl; 
      f << '\t' << Idst.store_instr << " " << reg2str[Rdst.exreg] << ", " << addrDst << endl;

    }
    else {
      f << '\t' << "mtc1 " << reg2str[Reg.src1Reg] << ", " << reg2str[Reg.dstReg] << endl;
      f << '\t' << "cvt.s.w " << reg2str[Reg.dstReg] << ", " << reg2str[Reg.dstReg] << endl; 
    }
  }

  else if (quad.opr == "real2int")
  {
    // Instr
    inst_t Isrc1 = getInst(quad.t_src1);
    inst_t Idst = getInst(quad.t_dst);
    // temp registor for src
    tmp_regs Rsrc1 = getTmpRegs(quad.t_src1);
    // tmp registor for dst
    tmp_regs Rdst = getTmpRegs(quad.t_dst);
    oprRegs Reg = getReg(f,quad);

    string addrDst = loadArrAddr(f,lastdelta.dst, "0");
    string addrSrc1 = loadArrAddr(f, lastdelta.src1, "1");
    
    if(addrSrc1 != "") { // src1 of type a[][]
      f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + addrSrc1 << endl;
      Reg.src1Reg = Rsrc1.exreg;
    }
    if( Reg.src1Reg == zero ) // if src1 constant
    {
      f << '\t' << "li.s $f14, " << quad.src1 << endl;
      Reg.src1Reg = f14;
    }
    else
    {
      f << '\t' << "mov.s $f14, " << reg2str[Reg.src1Reg] << endl;
      Reg.src1Reg = f14;
    }
    f << '\t' << "cvt.w.s " << reg2str[Reg.src1Reg] << ", " << reg2str[Reg.src1Reg] << endl;

    if(addrDst != "") { // dst of type a[][]
      f << '\t' << "mfc1 " << reg2str[Rdst.exreg] << ", " << reg2str[Reg.src1Reg] << endl;
      f << '\t' << Idst.store_instr << " " << reg2str[Rdst.exreg] << ", " << addrDst << endl;
    }
    else {
      f << '\t' << "mfc1 " << reg2str[Reg.dstReg] << ", " << reg2str[Reg.src1Reg] << endl;
    }
  }

  else if (quad.opr == "&") {
    oprRegs regs = getReg(f, quad);
    string paramAddr = loadArrAddr(f, lastdelta.src1, "1");
    if(paramAddr != "") {
      // ($fp)
      f << '\t' << "la " << reg2str[regs.dstReg] + ", " + paramAddr;
    }
    else {
      f << '\t' << "la " << reg2str[regs.dstReg] + ", -" + to_string(lastdelta.src1.Sym->offset)
        << "($fp)";
    }
    f << " # " + quad.dst + " = & " + quad.src1 << endl;
  }

  else if (quad.opr == "*") {
    // TODO
  }
  
  else if (quad.opr == "goto") {
    resetRegMaps(f);
    string src1 = quad.src1;
    cout << src1 <<endl;
    if(!src1.empty() &&  src1[0] == 'U'); // TODO: use better check
    else src1 = ("LABEL_" + src1);

    f << "\t" <<"b " + src1 << endl;
  }

  else if (quad.opr == "ifgoto") {
    oprRegs regs = getReg(f, quad);
    resetRegMaps(f);
    string src2Addr = loadArrAddr(f, lastdelta.src2, "1");
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
    
    inst_t Isrc1 = getInst(quad.t_src1);
    tmp_regs Rsrc1 = getTmpRegs(quad.t_src1);
      
    oprRegs regs = getReg(f, quad);
    if (regs.src1Reg == zero) {
      /* constant param */
      // TODO: infer size from const or add a compulsory "temp = const" intr in 3ac
      paramOffset += 4;
      // TODO: make type-based load, store functions
      string loadInst = Isrc1.load_const;
      if(quad.src1.substr(0,7) == "string_")
      {
        Rsrc1.exreg = a3;
        loadInst = "la";
      }
      f << '\t' <<  loadInst+ " " << reg2str[Rsrc1.exreg] + ", " + quad.src1 << endl;
      f << '\t' << Isrc1.store_instr << " " << reg2str[Rsrc1.exreg] + ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
      f << " # load parameter to func" << endl;
    }
    else { // non-const
      int size = lastdelta.src1.Sym->size;
      size = ((size+3)/4)*4;
      string paramAddr = loadArrAddr(f, lastdelta.src1, "1");
      
      if(Isrc1.store_instr != "s.s") Isrc1.store_instr = "sw";

      if(paramAddr != "") { // a[0], a.x complex type
        // TODO:: use better method
        if(lastdelta.src1.Type == 1)
          size = getSize(((Arr *)lastdelta.src1.Sym->type)->item);
        else if(lastdelta.src1.Type == 2) /* struct */
          size = getSize(lastdelta.src1.FinalType);
        size = ((size+3)/4)*4;
        paramOffset += size;
        f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + paramAddr << endl;
        f << '\t' << Isrc1.store_instr << " " << reg2str[Rsrc1.exreg] << ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
        f << " # load parameter to func" << endl;
      }
      else {  // a
        // TODO struct
        if(isArr(lastdelta.src1.Sym->type)) {
          size = 4; // store only pointer to the array in stack
          paramOffset += size;
          f << '\t' << "sw" << " " << reg2str[regs.src1Reg] + ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
        }
        else {
          paramOffset += size;
          f << '\t' << Isrc1.store_instr << " " << reg2str[regs.src1Reg] + ", -" + to_string(paramOffset)+"("+ reg2str[sp] + ")";
        }
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
    inst_t Isrc1 = getInst(quad.t_src1);
    tmp_regs Rsrc1 = getTmpRegs(quad.t_src1);
    oprRegs regs = getReg(f, quad);
    if (regs.src1Reg == zero) {
      f << '\t' << Isrc1.load_const << " " << reg2str[Rsrc1.retreg1] + ", " + quad.src1;
      f << " # load return value" << endl;
    }
    else {
      string src1Addr = loadArrAddr(f, lastdelta.src1, "1");
      if(src1Addr!= ""){
        f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + src1Addr << endl;
        f << '\t' << Isrc1.move_instr << " " + reg2str[Rsrc1.retreg1] + ", " << reg2str[Rsrc1.exreg] << " " << endl;
      }
      else{
        f << '\t' << Isrc1.move_instr << " " << reg2str[Rsrc1.retreg1] + ", " + reg2str[regs.src1Reg];
        f << " # load return value" << endl;
      }
    }  
    f << '\t' << "b " << currFunc + "_ret" << " # jump to return routine" << endl;
  }

  else if (quad.opr == "function end") funcEnd(f, quad);
}


void funcStart(std::ofstream & f, const irquad_t & quad) {
  resetRegMaps(f);
  currFunc = quad.src1;
  f << "\t.globl " + currFunc << endl;
  auto symtabs = SymRoot->currScope->subScopes; // currscope == root
  // search for function scope
  symtab * funTab = NULL;
  for (auto tab: symtabs) {
    if (tab->name == "func " + currFunc) { funTab = tab; break; }
  }
  if(!funTab) {
    cout << "void funcStart():: can't find function scope" << endl;
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
  if(SymRoot->currScope->parent)
  {
    cout << "funcEnd" <<endl;
    SymRoot->currScope = SymRoot->currScope->parent;
  }
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


void binOpr(std::ofstream & f, irquad_t & q) {
  string opr = q.opr;
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  sym *src1 = lastdelta.src1.Sym, *src2 = lastdelta.src2.Sym;
  sym *dst = lastdelta.dst.Sym;
  string instr;
  if( isReal(q.t_dst) )
  {
    if   (opr == "real+") instr     = "add.s";
    else if (opr == "real-") instr  = "sub.s";
    else if (opr == "real*") instr  = "mul.s";
    else if (opr == "real/") instr  = "div.s";
  }
  // TODO: unsigned, float, ...
  // if(opr == "+" || opr == "-" || opr == "*" || opr == "/" ) {
  else
  {
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
  }
    
    inst_t Isrc1 = getInst(q.t_src1);
    inst_t Isrc2 = getInst(q.t_src2);
    inst_t Idst = getInst(q.t_dst);
    tmp_regs Rsrc1 = getTmpRegs(q.t_src1);
    tmp_regs Rsrc2 = getTmpRegs(q.t_src2);
    tmp_regs Rdst = getTmpRegs(q.t_dst);    
    
    // dst = src1 + src2  
    oprRegs regs = getReg(f, q);
    string addrDst = loadArrAddr(f,lastdelta.dst, "0");
    string addrSrc1 = loadArrAddr(f, lastdelta.src1, "1");
    string addrSrc2 = loadArrAddr(f, lastdelta.src2, "2");
    
    if(addrSrc1 != "") {
      f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + addrSrc1 << endl;
      regs.src1Reg = Rsrc1.exreg;
    }
    if(addrSrc2 != "") {
      f << '\t' << Isrc2.load_instr <<" " << reg2str[Rsrc2.retreg2] << " , " + addrSrc2 << endl;
      regs.src2Reg = Rsrc2.retreg2;
    }

    if ( isReal(q.t_dst) && regs.src2Reg == zero )
    {
      f << '\t' << Idst.load_const << " " << reg2str[Rdst.exreg] << ", " << q.src2 << endl;
      q.src2 = reg2str[Rdst.exreg];
    }
    string src2_str = (regs.src2Reg == zero) ? q.src2 : reg2str[regs.src2Reg];
    if( opr != eps && opr[0] == 'r' )
    {
      opr = opr.substr(4);
    }

    if (addrDst != "") {
      // src1 is constant
      if (regs.src1Reg == zero) {
        f << '\t' << Isrc1.load_const << " " << reg2str[Rsrc1.exreg] << ", " + q.src1 << " # load constant"<< endl;
        f << '\t' << instr + " " << reg2str[Rsrc1.exreg] << ", " << reg2str[Rsrc1.exreg] << ", " + src2_str;
        f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
      }
      else {
        f << '\t' << instr + " " << reg2str[Rsrc1.exreg] << ", " + reg2str[regs.src1Reg] + ", " + src2_str;
        f << " # " + q.dst + " = " + q.src1 + " " + opr + " " + q.src2 << endl;
      }
      /* eg. sw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << Isrc1.store_instr << " "
        << reg2str[Rsrc1.exreg] << ", " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    
    else{
      // src1 is constant
      if (regs.src1Reg == zero) {
        f << '\t' << Isrc1.load_const << " " << reg2str[regs.dstReg] + ", " + q.src1 << " # load constant"<< endl;
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
  if(SymRoot->currScope == SymRoot->root) return;
  deltaNxtUse lastdelta = nxtUse.lastdelta;
  oprRegs regs = getReg(f, q);
  
  inst_t Isrc1 = getInst(q.t_src1);
  inst_t Isrc2 = getInst(q.t_src2);
  inst_t Idst = getInst(q.t_dst);
  tmp_regs Rsrc1 = getTmpRegs(q.t_src1);
  tmp_regs Rsrc2 = getTmpRegs(q.t_src2);
  tmp_regs Rdst = getTmpRegs(q.t_dst);    
    
  
  /* just remapping resgisters */
  string addrDst = loadArrAddr(f,lastdelta.dst, "0");
  string addrSrc1 = loadArrAddr(f, lastdelta.src1, "1");

  if (regs.dstReg == regs.src1Reg && lastdelta.dst.Type == 0) {
    /* only for simple type */
    // TODO:: this optimization is disabled in getReg()
    f << "\t # " + q.dst + " = " + reg2str[regs.src1Reg] <<endl;
  }
  /* load a constant */
  else if(regs.src1Reg == zero) {
    // TODO other types
    if(addrDst != ""){ // dst is an array
      // TODO: non-constant offset -- lastdelta.dstArrSymb

      f << '\t' << Isrc1.load_const << " " << reg2str[Rsrc1.exreg] << ", " + q.src1 << endl;

      f << '\t' << Isrc1.store_instr << " "
        << reg2str[Rsrc1.exreg] << ", " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    else {
      f << '\t' << Isrc1.load_const << " " << reg2str[regs.dstReg] + ", " + q.src1;
      f << " # " + q.dst <<endl;
    }
  }

  /* need to move */
  else if(isStruct(lastdelta.dst.FinalType) || isStruct(lastdelta.src1.FinalType)) { // extra checks for sanity
    // extra checks for sanity
    if(!tMatch(lastdelta.dst.FinalType, lastdelta.src1.FinalType))
      cerr << "ERROR: struct = non_struct" << endl;
    
    // if not-complex --> addr is directly in dstReg and srcReg
    if(addrDst == "")
      addrDst = "(" + reg2str[regs.dstReg] + ")";
    if(addrSrc1 == "")
      addrSrc1 = "(" + reg2str[regs.src1Reg] + ")";

    if(addrDst != "($a0)") // if did optimzations in addr calculation
      f << '\t' << "la" << " " << "$a0" << ", " + addrDst << endl;
    if(addrSrc1 != "($a1)") // if did optimzations in addr calculation
      f << '\t' << "la" << " " << "$a1" << ", " + addrSrc1 << endl;
    /* copy struct */
    memCopy(f, a1, a0, getSize(lastdelta.dst.FinalType));
  }
  else{
    if (addrSrc1 != ""){ // src1 complex type
      f << '\t' << Isrc1.load_instr << " " << reg2str[Rsrc1.exreg] << " , " + addrSrc1 << endl;
      regs.src1Reg = Rsrc1.exreg;
    }

    if(addrDst != ""){ // dst complex type
      /* eg. sw $a4, ($a0) ||  lw $a4, 100($t0) */
      f << '\t' << Isrc1.store_instr << " "
        <<  reg2str[regs.src1Reg] + ", " + addrDst
        << " # " + q.dst + "[][]...[]" << endl;
    }
    else { // dst simple type
      f << '\t' << Isrc1.move_instr << " " << reg2str[regs.dstReg] + ", " + reg2str[regs.src1Reg] << endl;
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
      delta.dst.Type = 1;
      string tmp = IR[idx].dst.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.dst.ArrOff.push_back(IR[idx].dst.substr(boxStart+1, boxEnd-boxStart-1));
        delta.dst.ArrSymb.push_back(SymRoot->gLookup(delta.dst.ArrOff.back()));
        boxStart = IR[idx].dst.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].dst.find_first_of(']', boxEnd+1);
      }
      IR[idx].dst = tmp;
    }

    boxStart = IR[idx].src1.find_first_of('[');
    boxEnd = IR[idx].src1.find_first_of(']');

    if(boxStart >= 0 && boxEnd >= 0) {
      delta.src1.Type = 1;
      string tmp = IR[idx].src1.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.src1.ArrOff.push_back(IR[idx].src1.substr(boxStart+1, boxEnd-boxStart-1));
        delta.src1.ArrSymb.push_back(SymRoot->gLookup(delta.src1.ArrOff.back()));
        boxStart = IR[idx].src1.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].src1.find_first_of(']', boxEnd+1);
      }
      IR[idx].src1 = tmp;
    }

    boxStart = IR[idx].src2.find_first_of('[');
    boxEnd = IR[idx].src2.find_first_of(']');

    if(boxStart >= 0 && boxEnd >= 0) {
      delta.src2.Type = 1;
      string tmp = IR[idx].src2.substr(0, boxStart);
      while(boxStart >= 0 && boxEnd >= 0){
        delta.src2.ArrOff.push_back(IR[idx].src2.substr(boxStart+1, boxEnd-boxStart-1));
        delta.src2.ArrSymb.push_back(SymRoot->gLookup(delta.src2.ArrOff.back()));
        boxStart = IR[idx].src2.find_first_of('[', boxEnd+1);
        boxEnd = IR[idx].src2.find_first_of(']', boxEnd+1);
      }
      IR[idx].src2 = tmp;
    }
    /* For struct parsing */
    parseStruct(IR[idx].dst, delta.dst);
    parseStruct(IR[idx].src1, delta.src1);
    parseStruct(IR[idx].src2, delta.src2);

    sym* dstSym = SymRoot->gLookup(IR[idx].dst);
    sym* src1Sym = SymRoot->gLookup(IR[idx].src1);
    sym* src2Sym = SymRoot->gLookup(IR[idx].src2);
    
    if (dbg_print) SymRoot->dump(csv_out2);
    if (dbg_print) csv_out2 << "\n\n\n##################\n\n\n"<<endl;
    // break;
    if (dstSym) {
      delta.dst.Sym    = dstSym;
      delta.dst.NxtUse = dstSym->nxtuse;
      delta.dst.Alive  = dstSym->alive;
      if (dstSym->name[0] == '0')
        dstSym->alive = false;
      dstSym->nxtuse = -1;
      IR[idx].t_dst = dstSym->type;
      if(delta.dst.FinalType == NULL) 
        delta.dst.FinalType = dstSym->type;
    }

    if (src1Sym) {
      delta.src1.Sym    = src1Sym;
      delta.src1.NxtUse = src1Sym->nxtuse;
      delta.src1.Alive  = src1Sym->alive;
      if (src1Sym->name[0] == '0')
        src1Sym->alive = true;
      src1Sym->nxtuse =  idx - leader;
      IR[idx].t_src1 = src1Sym->type;
      if(delta.src1.FinalType == NULL) 
        delta.src1.FinalType = src1Sym->type;
    }

    if (src2Sym) {
      delta.src2.Sym    = src2Sym;
      delta.src2.NxtUse = src2Sym->nxtuse;
      delta.src2.Alive  = src2Sym->alive;
      if (src2Sym->name[0] == '0')
        src2Sym->alive = true;
      src2Sym->nxtuse =  idx - leader;
      IR[idx].t_src2 = src2Sym->type;
      if(delta.src2.FinalType == NULL) 
        delta.src2.FinalType = src2Sym->type;
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
