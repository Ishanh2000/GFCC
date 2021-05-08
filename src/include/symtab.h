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
#include <types2.h>
#include <codegen.h>

typedef unsigned long int ull;

class sym { // SYMBOL
  public:
    std::string name;
    class Type* type = NULL;
    loc_t pos; // there can be two positions - last defined / last declared - later, if time permits
    int lib = 0x0; // what library does this symbol belongs to
    short unsigned int size = 1;
    unsigned int offset; // offset from the $fp or $gp (0 iff type like struct definition)

    /* register of the symbol */
    reg_t reg = zero;

    /*
      * if the symbol is alive or not.
      * -- local variables are always alive
      * -- temproraies are dead at start and end
    */
    bool alive = false;
    /* next use in the current mainblock */
    int nxtuse = -1;

    sym(std::string, class Type*, loc_t);
    sym(std::string, class Type*, loc_t, int);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};


class symtab { //  SYMBOL TABLE
  public:
    std::string name = "_unnamed_"; // table name (should reflect context)
    symtab* parent = NULL;
    std::vector<symtab*> subScopes;
    std::vector<sym*> syms;
    std::unordered_map <std::string,sym*> map_syms;
    /*
      * offset from the $fp or $gp of the last symbol present in
      * this symtab or any of its children. This value will get
      * updated as more symbols are added
     */
    unsigned int offset;

    symtab();
    symtab(std::string); // name given
    symtab(symtab *); // parent specified
    symtab(std::string, symtab *); // name and parent both specified
    ~symtab();

    
    sym* srchSym(std::string); // search a symbol by name
    
    // push a symbol (if name and type is proper, and symbol did not pre-exist)
    bool pushSym(sym*);
    bool pushSym(std::string, class Type*, loc_t);

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
    bool pushSym(std::string, class Type*, loc_t);
    void dump(std::ofstream &); // dump all info into (opened writable) file
};

extern std::string csvHeaders;

extern symRoot *SymRoot;

bool isFuncScope(class symtab *);

void libDumpSym(int);

void resetSymtab(); // reset appropriate global variables

#endif
