// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_ASM__
#define __GFCC_ASM__

enum reg_t {
  zero,                                   // constant 0
  at,                                     // reserved for the assembler
  v0, v1,                                 // result registers
  a0, a1, a2, a3,                         // argument registers 1···4
  t0, t1, t2, t3, t4, t5, t6, t7,         // temporary registers 0···7
  s0, s1, s2, s3, s4, s5, s6, s7,         // saved registers 0···7
  t8, t9,                                 // temporary registers 8···9
  k0, k1,                                 // kernel registers 0···1
  gp, sp, fp, ra,                          // global data ptr, stack ptr, frame ptr, return addr

  f0, f1, f2, f3,                         // Function-returned values
  f4, f5, f6, f7, f8, f9, f10, f11,       // Temporary values
  f12, f13, f14, f15,                     // Arguments passed into a function
  f16, f17, f18, f19,                     // More Temporary values
  f20, f21, f31,                          // Saved values
};

#include <fstream>
#include <vector>
#include <stack>
#include <map>
#include <unordered_map>

#include <gfcc_lexer.h>
#include <ircodes.h>
#include <symtab.h>

extern std::string reg2str[];

extern std::string freg2str[];

extern class sym* regDscr[];

struct deltaNxtUse {
  sym* dstSym = NULL;
  int dstNxtUse = -1;
  bool dstAlive = true;
  sym* src1Sym = NULL;
  int src1NxtUse = -1;
  bool src1Alive = true;
  sym* src2Sym = NULL;
  int src2NxtUse = -1;
  bool src2Alive = true;
};

class _nxtUse {
  public:
    // last changes popped - has sym*s of current line
    deltaNxtUse lastdelta;
    // changes in nxtuse information
    std::vector<deltaNxtUse> deltas;
    void clear();
    deltaNxtUse step();
};

struct oprRegs {
  reg_t dstReg;
  reg_t src1Reg;
  reg_t src2Reg;
};

void regFlush(std::ofstream &, reg_t, bool);

void regMap(std::ofstream &, reg_t, sym*, bool);

void resetRegMaps(std::ofstream &, bool);

void dumpASM(std::ofstream &, const std::vector<irquad_t> &); // convert IR code to ASM (mainly MIPS, for "spim" simulator)

reg_t getSymReg(const std::string &);

oprRegs getReg(std::ofstream &, const irquad_t &q);

void genASM(std::ofstream &, const irquad_t &);

void funcStart(std::ofstream &, const irquad_t &); // preliminaries at beginning of function

void funcEnd(std::ofstream &, const irquad_t &); // preliminaries at end of function

void binOpr(std::ofstream &, const irquad_t &); // handle binary operators

void assn(std::ofstream &, const irquad_t &);

int getNxtLeader(const std::vector<irquad_t> &, int);

#endif
