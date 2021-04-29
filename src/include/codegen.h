// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_ASM__
#define __GFCC_ASM__

#include <fstream>
#include <vector>

#include <gfcc_lexer.h>
#include <ircodes.h>
#include <symtab.h>

void dumpASM(std::ofstream &, std::vector<irquad_t>); // convert IR code to ASM (mainly MIPS, for "spim" simulator)

#endif
