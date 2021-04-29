// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_ASM__
#define __GFCC_ASM__

#include <fstream>
#include <vector>

#include <gfcc_lexer.h>
#include <ircodes.h>
#include <symtab.h>
#include <map>

enum reg_t {
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

void dumpASM(std::ofstream &, std::vector<irquad_t> &); // convert IR code to ASM (mainly MIPS, for "spim" simulator)

unsigned int getNxtLeader(std::vector<irquad_t> &, unsigned int);

void genASM(std::ofstream &, irquad_t &);

void funcStart(std::ofstream &, irquad_t &); // preliminaries at beginning of function

void funcEnd(std::ofstream &, irquad_t &); // preliminaries at end of function

struct addr {
	reg_t reg;
	
};
class processMb {
	public:
		std::map<reg_t, sym*> regDscr;
		std::map<sym*, addr> addDscr;
};

#endif
