// AUM SHREEGANESHAAYA NAMAH||
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************
 * Use initializer lists for constructors wherever possible.
 * Try using multiple constructors for variability (not immediate requirement).
 * Appropriately use destructor for freeing heap.
************************************************************************/

#ifndef __GFCC_LIBDUMP__
#define __GFCC_LIBDUMP__

#include <iostream>
#include <fstream>

extern int lib_reqs; // library requirements (default none)

std::string float2Dec(std::string); // IEEE 754 conversion

void libDumpBasic();
void libDumpTypo();
void libDumpMath();
void libDumpStd();
void libDumpString();

void libDumpSym(int);

void libDumpASM(std::ofstream &, int);

#endif
