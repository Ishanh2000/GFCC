// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_ASM__
#define __GFCC_ASM__

#include <fstream>
#include <vector>

#include <gfcc_lexer.h>
#include <ircodes.h>
#include <symtab.h>

void dumpASM(std::ofstream &, std::vector<irquad_t> &); // convert IR code to ASM (mainly MIPS, for "spim" simulator)

unsigned int getNxtLeader(std::vector<irquad_t> &, unsigned int);

void genASM(std::ofstream &, irquad_t &);

void funcStart(std::ofstream &, irquad_t &); // preliminaries at beginning of function

void funcEnd(std::ofstream &, irquad_t &); // preliminaries at end of function

#endif
