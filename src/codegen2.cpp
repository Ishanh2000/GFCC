// AUM SHREEGANESHAAYA NAMAH||
// compile using: g++ -Iinclude -DTEST_CODEGEN codegen.cpp
#include <fstream>
#include <iomanip>
#include <vector>

#include <ircodes.h>
#include <codegen.h>
#include <symtab.h>


using namespace std;

void libDumpASM(ofstream &f, int lib_reqs) {
  if (lib_reqs & LIB_MATH) {
    f << "## GFCC MATHS LIBRARY" << endl << endl;
    // then do apropriate appending stuff
  }
  
  if (lib_reqs & LIB_TYPO) {
    f << "## GFCC TYPOGRAPHY LIBRARY" << endl;
    f << ifstream("./src/lib/g5_typo.asm").rdbuf() << endl << endl;
  }

  if (lib_reqs & LIB_STD) {
    f << "## GFCC STANDARD LIBRARY" << endl;
    f << ifstream("./src/lib/g5_std.asm").rdbuf() << endl << endl;
  }
}

