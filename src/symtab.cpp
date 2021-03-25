#include<symtab.h>
#include<string>
#include<vector>

using namespace std;
typedef unsigned long int ull;

class tab_header { // why a separate class just for header? just a mask for string class. - ask Prashant.
  public:
    string name;
    tab_header(){}
};

class sym {
  string name;
  ull type;
  // Derive a scheme: type must have space enough for attributes: isFunc,
  // isStatic, isVolatile, isConst, etc. - will discover with progress.
  // More constructors required apart from a "generic" constrtuctor.
  public:
    // constructor (use initializer list wherever possible, and short names)
    sym(string _name, ull _type) : name(_name), type(_type) { }
    bool matchesName(string _name) { return (name == _name); } // use a shorter name. could make "name" puclic?
  
};


class symtab {
  public:
    tab_header header; // name (string mask)
    symtab* parent = NULL; // parent symbol table
    vector<symtab*> child_scopes; // children symbol tables
    vector<sym*> vars; // symbols
    
    // Keep all constructors and destructors here.
    // symtab() : parent(NULL);
    symtab(symtab* _parent) : parent(_parent) { }
    
    sym* getSym(string name) { // search symbol by name
      if (name == "") return NULL;
      for (int i = 0; i < vars.size(); i++) {
        if (vars[i]->matchesName(name)) return vars[i];
      }
      return NULL;
    }

    void add_symbol(string name, ull type) {
      auto new_symbol = new sym(name, type);
      // TODO add error check, scope check
      vars.push_back(new_symbol);
    }
    

};

class symtab_root {
  symtab* curr_scope;
  symtab* root;
  symtab_root() {
    root = new symtab(NULL);
    curr_scope = root;
  }
  void close_scope() {
    curr_scope = curr_scope->parent;
  }
  void new_scope() {
    symtab* new_scope = new symtab(curr_scope);
    curr_scope->child_scopes.push_back(new_scope);
    curr_scope = new_scope;
  }
  
  sym* lookup(string name) {
    symtab* run_scope = curr_scope;
    sym* symb = NULL;
    while(run_scope != NULL) {
      symb = run_scope->getSym(name);
      if(symb != NULL) {
        return symb;
      }
      run_scope = run_scope->parent;
    }
    return NULL;
  }
};

void testSuite() {

}
