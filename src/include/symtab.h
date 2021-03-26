// AUM SHREEGANESHAAYA NAMAH||
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************
 * Use initializer lists for constructors wherever possible.
 * Try using multiple constructors for variability (not immediate requirement).
 * Appropriately use destructor for freeing heap.
************************************************************************/

#ifndef __GFCC_SYMTAB__
#define __GFCC_SYMTAB__
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

typedef unsigned long int ull;

// See later if this works (if time permits)
// #define NULL_SYM (-1)
// #define SYM_EXISTS (-2)

class sym { // SYMBOL
  public:
    std::string name;
    ull type;
    // Derive a scheme: type must store attributes: isFunc, isStatic, isVolatile, isConst, etc. (must discover with progress)

    // Constructor + Destructors
    sym(std::string, ull);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};


class symtab { //  SYMBOL TABLE
  public:
    std::string name = "_unnamed_"; // table name (should reflect context)
    symtab* parent = NULL;
    std::vector<symtab*> subScopes; // size() = 0
    std::vector<sym*> syms; // size() = 0
  
    // Constructor + Destructors
    symtab();
    symtab(std::string); // name given
    symtab(symtab *); // parent specified
    symtab(std::string, symtab *); // name and parent both specified
    ~symtab();

    // Methods
    sym* srchSym(std::string); // search a symbol by name
    
    // push a symbol (if name and type is proper, and symbol did not pre-exist)
    bool pushSym(sym*);
    bool pushSym(std::string, ull);

    void dump(std::ofstream &, std::string); // dump all info into (opened writable) file, scopePath
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
    bool newScope(std::string); // name given
    void closeScope(); // no need to report success
    sym* lookup(std::string);
    sym* gLookup(std::string);
    bool pushSym(sym*);
    bool pushSym(std::string, ull);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};

bool acceptType(ull); // check if the given (encoded) type is actually valid

extern symRoot *sr;

#endif
