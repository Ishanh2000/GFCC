#include<symtab.h>
#include<string>
#include<vector>

using namespace std;
typedef unsigned long int ull;

class tab_header {
  public:
    std::string name;
    tab_header(){}
};

class symbol {
  string name;
  ull type;
  public:
    symbol(string name, ull type) {
      this->name = name;
      this->type = type;
    }
};


class symtab {
  public:
    symtab* parent;
    vector<symbol*> vars;
    vector<symtab*> child_scopes;
    tab_header header;
  
    symtab(symtab* parent) {
      this->parent = parent;
    }
    
    symbol* search_symbol(string name) {
      // TODO
      return NULL;
    }

    void add_symbol(string name, ull type) {
      auto new_symbol = new symbol(name, type);
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
  
  symbol* lookup(string name) {
    symtab* run_scope = curr_scope;
    symbol* symb = NULL;
    while(run_scope != NULL) {
      symb = run_scope->search_symbol(name);
      if(symb != NULL) {
        return symb;
      }
      run_scope = run_scope->parent;
    }
    return NULL;
  }
};
