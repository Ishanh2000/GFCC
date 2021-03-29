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
#include <unordered_map>

#include <gfcc_lexer.h>
#include <types.h>

typedef unsigned long int ull;

extern std::string csvHeaders;

// See later if this works (if time permits)
// #define NULL_SYM (-1)
// #define SYM_EXISTS (-2)

class sym { // SYMBOL
  public:
    std::string name;
    Type* type = NULL;
    loc_t pos; // there can be two positions - last defined / last declared - later, if time permits
    // type_expr* tp;
    // Derive a scheme: type must store attributes: isFunc, isStatic, isVolatile, isConst, etc. (must discover with progress)

    // Constructor + Destructors
    sym(std::string, Type*, loc_t);
    // sym(std::string, type_expr*, loc_t);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};


class symtab { //  SYMBOL TABLE
  public:
    std::string name = "_unnamed_"; // table name (should reflect context)
    symtab* parent = NULL;
    std::vector<symtab*> subScopes; // size() = 0
    std::vector<sym*> syms; // size() = 0
    std::unordered_map <std::string,sym*> map_syms;
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
    bool pushSym(std::string, Type*, loc_t);
    // bool pushSym(std::string, type_expr*, loc_t);

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
    bool pushSym(std::string, Type*, loc_t);
    // bool pushSym(std::string, type_expr*, loc_t);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};

bool acceptType(Type*); // check if the given (encoded) type is actually valid
// bool acceptType(type_expr*); // check if the given (encoded) type is actually valid

extern symRoot *SymRoot;

#endif
