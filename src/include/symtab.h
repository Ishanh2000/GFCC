#ifndef __GFCC_SYMTAB__
#define __GFCC_SYMTAB__
#include<string>
#include<vector>
using namespace std;
typedef unsigned long int ull;


class tab_header {
  public:
    string name;
    tab_header(){}
};


class sym {
  string name;
  ull type;
  public:
    sym(string name, ull type){}
    bool matchesName(string);
};


class symtab {
  public:
    symtab* parent;
    vector<sym*> vars;
    vector<symtab*> child_scopes;
    tab_header header;
  
    symtab(symtab* parent) {}
    sym* search_symbol(string name);
    void add_symbol(string name, ull type);
};


class symtab_root {
  symtab* curr_scope;
  symtab* root;
  symtab_root() {
    root = new symtab(NULL);
    curr_scope = root;
  }
  void close_scope() { }
  void new_scope();
  sym* lookup(string name);
};

#endif
