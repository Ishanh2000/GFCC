// AUM SHREEGANESHAAYA NAMAH||
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************
 * Use initializer lists for constructors wherever possible.
 * Try using multiple constructors for variability (not immediate requirement).
 * Appropriately use destructor for freeing heap.
************************************************************************/

#ifndef __GFCC_LIBDUMP__
#define __GFCC_LIBDUMP__

#include <fstream>

void libDumpSym(int);

void libDumpASM(std::ofstream &, int);

#endif
