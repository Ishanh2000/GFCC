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

std::string float2Dec(std::string); // IEEE 754 conversion

void libDumpSym(int);

void libDumpASM(std::ofstream &, int);

#endif
