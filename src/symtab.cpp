// AUM SHREEGANESHAAYA NAMAH||

/************************ NOTE TO THE DEVELOPER ************************
 * SEE <proj_root>/src/include/symtab.h for description of various classes,
   members, methods, etc.
 * Search "TODO" for things to do.
 * Search "ASSUMPTIONS" for assumptions.
 * Execution using: g++ [-DSYMTEST] [-DSYMDEBUG] symtab.cpp -Iinclude
************************************************************************/

#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include <symtab.h>
#include <typo.h>

#ifdef DEBUG_SYM
const bool dbg = true;
#else
const bool dbg = false;
#endif

typedef unsigned long int ull;

using namespace std;


bool acceptType(ull type) {
  // analyze type properly. eg: return 0 if "auto static int"
  // TODO
  return true;
}

/*************************************/
/************ CLASS "sym" ************/
/*************************************/
// TODO: see how to prevent instantiation if acceptType(type) == false
sym::sym(string _name, ull _type) : name(_name), type(_type) {
  if (_name == "" || !acceptType(_type)) {
    if (dbg) msg(ERR) << "Invalid name \"" << _name << "\" or type \"" << _type << "\" passed!";
  }
}


/****************************************/
/************ CLASS "symtab" ************/
/****************************************/
symtab::symtab() { } // do nothing - initialization in class declaration

symtab::symtab(symtab* _parent) : parent(_parent) { }

symtab::~symtab() {
  int l1 = subScopes.size(), l2 = syms.size();
  for (int i = 0; i < l1; i++) {
    if (dbg) cout << "Deleting subscope " << i << endl;
    delete subScopes[i];
  }
  for (int i = 0; i < l2; i++) {
    if (dbg) cout << "Deleting " << syms[i]->name << endl;
    delete syms[i];
  }
}

sym* symtab::srchSym(string _name) { // search symbol by name
  if (_name == "") return NULL; // not required, but a speedup.

  int l = syms.size();
  for (int i = 0; i < l; i++) {
    if (syms[i]->name == _name) return syms[i];
  }
  return NULL;
}

bool symtab::pushSym(sym* newSym) {
  if (!newSym || srchSym(newSym->name)) {
    if (dbg) msg(WARN) << "Could not push new symbol in current scope.";
    return false;
  }
  if (dbg) cout << "Pushing " << newSym->name << endl;
  syms.push_back(newSym);
  return true;
}

bool symtab::pushSym(string _name, ull _type) {
  if (_name == "" || !acceptType(_type) || srchSym(_name)) {
    if (dbg) msg(WARN) << "Could not push \"" << _name << "\" in current scope.";
    return false;
  }
  return pushSym(new sym(_name, _type));
  // sym* newSym = new sym(_name, _type);
  // if (!newSym) return false;
  // if (dbg) cout << "inserting " << _name << endl;
  // syms.push_back(newSym);
  // return true;
}


/*****************************************/
/************ class "symRoot" ************/
/*****************************************/
symRoot::symRoot() {
  currScope = root = new symtab(); // handle exception if returns NULL
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
  symtab* new_scope = new symtab(currScope);
  if (!new_scope) return false;
  currScope->subScopes.push_back(new_scope);
  currScope = new_scope;
  if (dbg) cout << "Opening new scope." << endl;
  return true;
}

void symRoot::closeScope() {
  if (currScope && (currScope != root)) {
    if (dbg) cout << "Closing existing scope." << endl;
    currScope = currScope->parent;
  } else {
    if (dbg) msg(WARN) << "Cannot close global scope!";
  }
  // In future, can add functionality to delete currScope - NOT NOW.
  // Hence, "closing" and "deleting" scopes are two DIFFERENT things.
}

sym* symRoot::lookup(string _name) {
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

bool symRoot::pushSym(string _name, ull _type) {
  if (!currScope) return false;
  return currScope->pushSym(_name, _type);
}

void symDump(const char* _fname, symRoot* s) {
  ofstream f(_fname);
  // f << "Namaste!";
  f.close();

}


/******************************************************************/
/************************ TEST SUITES HERE ************************/
/******************************************************************/

void testSym() {
  sym("main", 00);
  sym("", 00);
}

void testSymTab() {
  symtab st;
  st.srchSym("");
  st.pushSym(new sym("praskr", 123));
  st.pushSym("deba", 456);
  st.pushSym(new sym("praskr", 123));
  st.srchSym("padnda");
  st.srchSym("deba");
  st.srchSym("priyanag");
}

void testSymRoot() {
  symRoot sr;
  sr.pushSym("main", 0);
  sr.newScope();
  sr.pushSym("x", 45);
  sr.lookup("x");
  sr.lookup("y");
  sr.pushSym("x", 45);
  sr.newScope(); sr.newScope(); sr.newScope();
  sr.newScope(); sr.newScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.pushSym("main", 0);
  sr.pushSym("maina", 0);
  sr.newScope();
  sr.pushSym("x", 45);
  sr.lookup("x");
  sr.lookup("y");
  sr.pushSym("x", 45);
  sr.newScope(); sr.newScope(); sr.newScope();
  sr.newScope(); sr.newScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.pushSym("maina", 0);
  sr.pushSym("mainb", 0);
  sr.newScope();
  sr.pushSym("x", 45);
  sr.lookup("x");
  sr.lookup("y");
  sr.pushSym("x", 45);
  sr.newScope(); sr.newScope(); sr.newScope();
  sr.newScope(); sr.newScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.closeScope(); sr.closeScope(); sr.closeScope(); sr.closeScope();
  sr.pushSym("mainb", 0);
}

#ifdef TEST_SYM

int main() {
  testSym();
  testSymTab();
  testSymRoot();
  symDump("out.csv", NULL);

  return 0;
}

#endif
