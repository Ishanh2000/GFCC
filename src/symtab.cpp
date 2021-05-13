// AUM SHREEGANESHAAYA NAMAH||

/************************ NOTE TO THE DEVELOPER ************************
 * SEE <proj_root>/src/include/symtab.h for description of various classes,
   members, methods, etc.
 * Search "TODO" for things to do.
 * Search "ASSUMPTIONS" for assumptions.
 * Execution using: g++ [-DSYMTEST] [-DSYMDEBUG] symtab.cpp -Iinclude
************************************************************************/

#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_map>

#include <symtab.h>
#include <types2.h>
#include <typo.h>
#include <ircodes.h>

#ifdef DEBUG_SYM
const bool dbg = true;
#else
const bool dbg = false;
#endif

typedef unsigned long int ull;

using namespace std;

symRoot *SymRoot = new symRoot();

string csvHeaders = "LIBRARY, LOCATION, NAME, SIZE, OFFSET, IS_FUNC_ARG, NXTUSE, ALIVE, TYPE, DETAILED_TYPE";

void resetSymtab() { // reset appropriate global variables
  delete SymRoot;
  SymRoot = new symRoot();
}

/*************************************/
/************ CLASS "sym" ************/
/*************************************/

sym::sym(string _name, class Type* _type, loc_t _pos, bool isArg) : name(_name), type(_type), pos(_pos), size(getSize(_type)), isArg(isArg) {
  if (_name == "" && dbg) msg(ERR) << "Invalid name \"" << _name << "\" or type \"" << str(_type) << "\" passed!";
}

// sym::sym(string _name, class Type* _type, loc_t _pos) : name(_name), type(_type), pos(_pos), size(getSize(_type)) {
//   if (_name == "" && dbg) msg(ERR) << "Invalid name \"" << _name << "\" or type \"" << str(_type) << "\" passed!";
// }

void sym::dump(ofstream &f) {
  f << setw(4);
  switch (lib) { // LIBRARY
    case      0x0 : f << "----,"; break;
    case LIB_MATH : f << "MATH,"; break;
    case LIB_TYPO : f << "TYPE,"; break;
    case LIB_STD  : f << " STD,"; break;
    // case LIB_FILE : f << "FILE,"; break;
    // case LIB_TIME : f << "TIME,"; break;
  }
  f << setw(8) << "(" + to_string(pos.line) + ":" + to_string(pos.column) << "), "; // LOCATION
  f << setw(20) << name << ", "; // NAME
  f << setw(3) << size << ", "; // SIZE
  if (offset) f << setw(3) << offset << ", "; else f << setw(3) << "-" << ", "; // OFFSET
  f << setw(5) << (isArg ? "TRUE" : "FALSE") << ", "; // IS_FUNC_ARG
  f << setw(3) << nxtuse << ", "; // NXTUSE - not required in final project
  f << setw(3) << alive << ", "; // ALIVE - not required in final project
  if (type) switch (type->grp()) { // TYPE
    case BASE_G : f << "--------, "; break;
    case  PTR_G : f << " POINTER, "; break;
    case  ARR_G : f << "   ARRAY, "; break;
    case FUNC_G : f << "FUNCTION, "; break;
  } else f << "-----------, ";
  f << "\"" << str(type) << "\"" << endl; // DETAILED TYPE
}


/****************************************/
/************ CLASS "symtab" ************/
/****************************************/
symtab::symtab() { } // do nothing - initialization in class declaration

symtab::symtab(string _name) : name(_name) { }

symtab::symtab(symtab *_parent) : parent(_parent) { }

symtab::symtab(string _name, symtab *_parent) : name(_name), parent(_parent) { }

symtab::~symtab() {
  int l1 = subScopes.size(), l2 = syms.size();
  for (int i = 0; i < l1; i++) {
    if (dbg) cout << "Deleting subscope \"" << subScopes[i]->name << "\"." << endl;
    delete subScopes[i];
  }
  for (int i = 0; i < l2; i++) {
    if (dbg) cout << "Deleting " << syms[i]->name << endl;
    delete syms[i];
  }
}

sym* symtab::srchSym(string _name) { // search symbol by name
  if (_name == "") return NULL; // not required, but a speedup.
  
  if( map_syms.find(_name) != map_syms.end() )
    return map_syms[_name];
  return NULL;
}

bool symtab::pushSym(sym* newSym) {
  if (!newSym || srchSym(newSym->name)) {
    if (dbg) msg(WARN) << "Could not push new symbol in current scope.";
    return false;
  }

  if (newSym->name.substr(0, 6) == "struct"
   || newSym->name.substr(0, 5) == "union"
   || newSym->name.substr(0, 4) == "enum") {
    newSym->offset = 0;
  }

  else { /* offset from $fp or $gp */
    unsigned short size = getSize(newSym->type);
    if(newSym->type->grp() == ARR_G && newSym->isArg)
      size = 4; // store only pointer to the array in stack
    
    this->offset += size/4 * 4;
    if(size % 4) this->offset += 4;
    // offset of symbol
    newSym->offset = this->offset;
  }

  if (dbg) cout << "Pushing " << newSym->name << endl;
  syms.push_back(newSym);
  map_syms[newSym->name] = newSym;
  newSym->parent = this;
  return true;
}

bool symtab::pushSym(string _name, class Type* _type, loc_t _pos, bool isArg) {
  if (_name == "" || srchSym(_name)) {
    if (dbg) msg(WARN) << "Could not push \"" << _name << "\" in current scope.";
    return false;
  }
  sym* tmp = new sym(_name, _type, _pos, isArg);
  tmp->parent = this;
  return pushSym(tmp);
}

void symtab::dump(ofstream &f, string scopePath) {
  f << "############ Scope = " << scopePath << name << " ############," << endl;
  
  // First print symbols, then scopes; just a random decision.
  // CAUTION: Will NOT reflect the history of symbols in CSV file.
  int l1 = syms.size(), l2 = subScopes.size();
  for (int i = 0; i < l1; i++) syms[i]->dump(f); // ASSUMPTION: none is NULL
  f << endl;
  for (int i = 0; i < l2; i++) subScopes[i]->dump(f, scopePath + name + " >> "); // ASSUMPTION: none is NULL
  
}


/*****************************************/
/************ class "symRoot" ************/
/*****************************************/
symRoot::symRoot() {
  currScope = root = new symtab("Global"); // handle exception if returns NULL
  if (dbg) {
    if (!root) msg(WARN) << "Could not open global scope.";
    else cout << "Global scope opened succesfully." << endl;
  }
}

symRoot::~symRoot() {
  delete root;
}

bool symRoot::newScope() {
  if (!currScope) return false;
  return newScope( "_unnamed_" + to_string(currScope->subScopes.size()) );
}

bool symRoot::newScope(string scope_name) {
  if (!currScope) return false;
  symtab* new_scope = new symtab(scope_name, currScope);
  if (!new_scope) return false;
  emit(eps, NULL, "newScope", scope_name, NULL);
  currScope->subScopes.push_back(new_scope);
  
  /* offset: initialise for a child */
  if(currScope == root) new_scope->offset = 40; // function in global scope
  else new_scope->offset = currScope->offset; // new scope in a function

  currScope = new_scope;
  if (dbg) cout << "Opening new scope \"" << scope_name << "\"." << endl;
  return true;
}

void symRoot::closeScope() {
  if (currScope && (currScope != root)) {
    string name = currScope->name;
    if (dbg) cout << "Closing existing scope \"" << name << "\"." << endl;
    
    if (name.substr(0, 9) == "_unnamed_")
      emit(eps, NULL, "closeScope", currScope->name, NULL);
    else if (name.substr(0, 5) == "func ")
      emit(eps, NULL, "function end", eps, NULL);

    /* offset */
    // global scope offset from $gp is independent from its child scopes
    if(currScope->parent != root) {
      // child scope will increase offset (w.r.t $sp) of parent
      currScope->parent->offset = currScope->offset;
    }

    currScope = currScope->parent;
  } else {
    if (dbg) msg(WARN) << "Cannot close global scope!";
  }
  // In future, can add functionality to delete currScope - NOT NOW.
  // Hence, "closing" and "deleting" scopes are two DIFFERENT things.
}

sym* symRoot::lookup(string _name) {
  if (!currScope) return NULL;
  return currScope->srchSym(_name);
}

sym* symRoot::gLookup(string _name) {
  symtab* run_scope = currScope;

  while (run_scope) {
    sym* symb = run_scope->srchSym(_name);
    if (symb) return symb; // found
    run_scope = run_scope->parent; // check in parent
  }

  return NULL; // not found
}

bool symRoot::pushSym(sym* newSym) {
  if (!currScope) return false;
  return currScope->pushSym(newSym);
}

bool symRoot::pushSym(string _name, class Type* _type, loc_t _pos, bool isArg) {
  if (!currScope) return false;
  return currScope->pushSym(_name, _type, _pos, isArg);
}

void symRoot::dump(ofstream &f) {
  if (!root) return; // nothing to do
  root->dump(f, "");
}

bool isFuncScope(class symtab *scope) {
  if (!scope) return false; // should return true as per current use
  return (scope->name.substr(0, 5) == "func ");
}

/******************************************************************/
/************************ TEST SUITES HERE ************************/
/******************************************************************/

#ifdef TEST_SYM

void testSym() {
  sym("main", NULL, { 0, 0 });
  sym("", NULL, { 0, 0 });
}

void testSymTab() {
  symtab _st;
  _st.srchSym("");
  _st.pushSym(new sym("praskr", NULL, { 0, 0 }));
  _st.pushSym("deba", NULL, { 0, 0 });
  _st.pushSym(new sym("praskr", NULL, { 0, 0 }));
  _st.srchSym("padnda");
  _st.srchSym("deba");
  _st.srchSym("priyanag");
}

void testSymRoot() {
  symRoot _sr;
  _sr.pushSym("main", NULL, { 0, 0 });
  _sr.newScope();
  _sr.pushSym("x", NULL, { 0, 0 });
  _sr.lookup("x");
  _sr.lookup("y");
  _sr.pushSym("x", NULL, { 0, 0 });
  _sr.newScope(); _sr.newScope("for_loop"); _sr.newScope();
  _sr.newScope(); _sr.newScope();
  _sr.newScope(); _sr.closeScope(); _sr.newScope(); _sr.closeScope();
  _sr.closeScope(); _sr.closeScope(); _sr.closeScope(); _sr.closeScope();
  _sr.closeScope(); _sr.closeScope(); _sr.closeScope(); _sr.closeScope();
  _sr.pushSym("main", NULL, { 0, 0 });
  _sr.pushSym("maina", NULL, { 0, 0 });
  
  ofstream f("out.csv");
  f << "# File Name: <must_get_somehow>" << endl << endl;
  f << "SYMBOL NAME , SYMBOL TYPE" << endl << endl;
  _sr.dump(f);
  f.close();
}


int main() {
  testSym();
  testSymTab();
  testSymRoot();

  return 0;
}

#endif
