// AUM SHREEGANESHAAYA NAMAH||
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************
 * Use initializer lists for constructors wherever possible.
 * Try using multiple constructors for variability (not immediate requirement).
 * Appropriately use destructor for freeing heap.
************************************************************************/

#ifndef __GFCC_SYMTAB__
#define __GFCC_SYMTAB__
#include <string>
#include <vector>

typedef unsigned long int ull;

// See later if this works (if time permits)
// #define NULL_SYM (-1)
// #define SYM_EXISTS (-2)

using namespace std;

class sym { // SYMBOL
  public:
    string name;
    ull type;
    // Derive a scheme: type must store attributes: isFunc, isStatic, isVolatile, isConst, etc. (must discover with progress)

    // Constructor + Destructors
    sym(string, ull);
};


class symtab { //  SYMBOL TABLE
  public:
    // string name; // table name - first consult for default value
    symtab* parent = NULL;
    vector<symtab*> subScopes; // size() = 0
    vector<sym*> syms; // size() = 0
  
    // Constructor + Destructors
    symtab();
    symtab(symtab*); // parent specified
    ~symtab();

    // Methods
    sym* srchSym(string); // search a symbol by name
    
    // push a symbol (if name and type is proper, and symbol did not pre-exist)
    bool pushSym(sym*);
    bool pushSym(string, ull);
};


class symRoot {
  public:
    // initialize both as global scope. Use constructor in this case.
    symtab *currScope, *root;

    // Constructors + Destructors
    symRoot();
    ~symRoot();

    // Methods
    bool newScope();
    void closeScope(); // no need to report success
    sym* lookup(string);
    bool pushSym(sym*);
    bool pushSym(string, ull);
};

bool acceptType(ull); // check if the given (encoded) type is actually valid

void symDump(const char*, symRoot*); // to dump CSV data for symbol tables

#endif
