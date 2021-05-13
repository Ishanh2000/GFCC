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
#include <codegen.h>
#include <libdump.h>

using namespace std;

string float2Dec(string s) { // IEEE 754 conversion
  union { float f; int d; } var;
  var.f = stof(s);
  return to_string(var.d);
}

void libDumpBasic() {
  // psuh some basic symbols (like NULL)
  // NULL = (void*) 0 [ constant and volatile pointer ]
  SymRoot->pushSym(new sym("NULL", new Ptr(new Base(VOID_B), true, true), { 0, 0, LIB_BASIC }));
  StrDump.push_back(str_t("0", ".word", "NULL"));
}

void libDumpTypo() {
	cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC Typography Library (typo)." << endl << _C_NONE_;
  { // int g5_printf(const char *, ...);
    Base *b = new Base(CHAR_B); b->isConst = true; 
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Base(ELLIPSIS_B));
    SymRoot->pushSym(new sym("g5_printf", fn, { 3, 5, LIB_TYPO }));
  }
  { // void g5_putc(const char)
    Base *b = new Base(CHAR_B); b->isConst = true; 
    Func* fn = new Func(new Base(VOID_B)); fn->newParam(b);
    SymRoot->pushSym(new sym("g5_putc", fn, { 4, 6, LIB_TYPO }));
  }
  { // char g5_getc()
    Func* fn = new Func(new Base(CHAR_B));
    SymRoot->pushSym(new sym("g5_getc", fn, { 5, 6, LIB_TYPO }));
  }
  { // int g5_scanf(const char *, ...);
    Base *b = new Base(CHAR_B); b->isConst = true; 
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Base(ELLIPSIS_B));
    SymRoot->pushSym(new sym("g5_scanf", fn, { 6, 5, LIB_TYPO }));
  }
}

void libDumpMath() {
	cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC Maths Library (math)." << endl << _C_NONE_;
  // global symbols : non-functions
  Base* b = new Base(FLOAT_B); b->isConst = true;    
  SymRoot->pushSym(new sym("G5_M_PI",        clone(b), { 3, 13, LIB_MATH }));
  StrDump.push_back(str_t(float2Dec("3.141592653589793115997963468544185162"), ".word", "G5_M_PI"));
  SymRoot->pushSym(new sym("G5_M_E",         clone(b), { 4, 13, LIB_MATH }));
  StrDump.push_back(str_t(float2Dec("2.718281828459045090795598298427648842"), ".word", "G5_M_E"));
  SymRoot->pushSym(new sym("__G5_M_PREC__",  clone(b), { 5, 13, LIB_MATH }));
  StrDump.push_back(str_t(float2Dec("0.000001"), ".word", "__GFCC_M_PREC__"));
  SymRoot->pushSym(new sym("__G5_M_LOG2__",  clone(b), { 6, 13, LIB_MATH }));
  StrDump.push_back(str_t(float2Dec("0.693147180559945286226763982995180413"), ".word", "__GFCC_M_LOG2__"));
  SymRoot->pushSym(new sym("__G5_M_LOG10__", clone(b), { 7, 13, LIB_MATH }));
  StrDump.push_back(str_t(float2Dec("2.302585092994045901093613792909309268"), ".word", "__GFCC_M_LOG10__"));
  SymRoot->pushSym(new sym("__G5_M_INFTY__", clone(b), { 8, 13, LIB_MATH }));
  StrDump.push_back(str_t("0x7FFFFFFF", ".word", "__GFCC_M_INFTY__"));

  // global symbols : non-functions
  Func* i2i = new Func(new Base(INT_B)); i2i->newParam(new Base(INT_B)); // int ()(int)
  vector<string> i2iNames = { "g5_abs", "g5_fact", "g5_fib" };
  int i2i_l = i2iNames.size();
  for (int i = 0; i < i2i_l; i++) {
    loc_t tmp; tmp.line = 10 + i; tmp.column = 5; tmp.lib = LIB_MATH;
    SymRoot->pushSym(new sym(i2iNames[i], clone(i2i), tmp));
  }
  
  { // float g5_intpow(float, int);
    Func* fn = new Func(new Base(FLOAT_B)); fn->newParam(new Base(FLOAT_B)); fn->newParam(new Base(INT_B));
    SymRoot->pushSym(new sym("g5_intpow", fn, { 13, 7, LIB_MATH }));
  }

  Func* f2f = new Func(new Base(FLOAT_B)); f2f->newParam(new Base(FLOAT_B)); // float ()(float)
  vector<string> f2fNames = {
    "g5_fabs", "g5_sqrt", "g5_exp", // "g5_sin", "g5_cos", "g5_tan",
    // "g5_arcsin", "g5_arccos", "g5_arctan", "g5_sinh", "g5_cosh", "g5_tanh",
    // "g5_log", "g5_log2", "g5_log10", "g5_arcsinh", "g5_arccosh", "g5_arctanh"
  };
  int f2f_l = f2fNames.size();
  for (int i = 0; i < f2f_l; i++) {
    loc_t tmp; tmp.line = 14 + i; tmp.column = 7; tmp.lib = LIB_MATH;
    SymRoot->pushSym(new sym(f2fNames[i], clone(f2f), tmp));
  }
}

void libDumpStd() {
	cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC Standard Library (std)." << endl << _C_NONE_;
  { // int g5_exit(int);
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Base(INT_B));
    SymRoot->pushSym(new sym("g5_exit", fn, { 3, 5, LIB_STD }));
  }
}

void libDumpString() {
	cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC String Library (string)." << endl << _C_NONE_;
  { // int g5_strlen(const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b));
    SymRoot->pushSym(new sym("g5_strlen", fn, { 3, 5, LIB_STRING }));
  }
  { // int g5_strcmp(const char *, const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Ptr(clone(b)));
    SymRoot->pushSym(new sym("g5_strcmp", fn, { 4, 5, LIB_STRING }));
  }
  { // int g5_strupr(const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b));
    SymRoot->pushSym(new sym("g5_strupr", fn, { 5, 5, LIB_STRING }));
  }
  { // int g5_strlwr(const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b));
    SymRoot->pushSym(new sym("g5_strlwr", fn, { 6, 5, LIB_STRING }));
  }
  { // int g5_strcat(const char *, const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Ptr(clone(b)));
    SymRoot->pushSym(new sym("g5_strcat", fn, { 7, 5, LIB_STRING }));
  }
  { // int g5_strcpy(const char *, const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Ptr(clone(b)));
    SymRoot->pushSym(new sym("g5_strcpy", fn, { 8, 5, LIB_STRING }));
  }
  { // int g5_strncpy(const char *, const char *, int);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Base(INT_B)); fn->newParam(new Ptr(b)); fn->newParam(new Ptr(clone(b))), fn->newParam(new Base(INT_B));
    SymRoot->pushSym(new sym("g5_strncpy", fn, { 9, 5, LIB_STRING }));
  }
  { // char *g5_strrev(const char *);
    Base *b = new Base(CHAR_B); b->isConst = true;
    Func* fn = new Func(new Ptr(new Base(CHAR_B))); fn->newParam(new Ptr(b));
    SymRoot->pushSym(new sym("g5_strrev", fn, { 10, 5, LIB_STRING }));
  }
}

void libDumpSym(int lib_reqs) { // insert libraries symbols into SymRoot
  libDumpBasic();  
  if (lib_reqs & LIB_MATH  ) libDumpMath();
  if (lib_reqs & LIB_TYPO  ) libDumpTypo();
  if (lib_reqs & LIB_STD   ) libDumpStd();
  if (lib_reqs & LIB_STRING) libDumpString();
}

void libDumpASM(ofstream &f, int lib_reqs) {
  if (lib_reqs & LIB_TYPO) {
    f << "## GFCC TYPOGRAPHY LIBRARY" << endl;
    f << ifstream("./src/lib/g5_typo.asm").rdbuf() << endl << endl;
  }

  if (lib_reqs & LIB_MATH) {
    f << "## GFCC MATHS LIBRARY" << endl << endl;
    f << ifstream("./src/lib/g5_math.asm").rdbuf() << endl << endl;
  }  

  if (lib_reqs & LIB_STD) {
    f << "## GFCC STANDARD LIBRARY" << endl;
    f << ifstream("./src/lib/g5_std.asm").rdbuf() << endl << endl;
  }

  if (lib_reqs & LIB_STRING) {
    f << "## GFCC STRING LIBRARY" << endl;
    f << ifstream("./src/lib/g5_string.asm").rdbuf() << endl << endl;
  }
}


