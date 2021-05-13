// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_IRC__
#define __GFCC_IRC__

#include <fstream>
#include <string>
#include <unordered_set>

#include <gfcc_lexer.h>
#include <types2.h>

typedef struct _irquad_t {
    std::string dst = ""; class Type* t_dst = NULL;
    std::string eq = "=";
    std::string opr = "";
    std::string src1 = ""; class Type* t_src1 = NULL;
    std::string src2 = ""; class Type* t_src2 = NULL;
    std::string label = "";
    // some constructors
    _irquad_t(std::string, std::string, std::string, std::string);
    _irquad_t(std::string, std::string, class Type *, std::string, class Type *, std::string, class Type *);
} irquad_t;
typedef struct _str_t { // for strings to be used in ".data" section
    // std::string label = ""; // will uncomment if required
    std::string encoding = ".asciiz";
    std::string contents = ""; // store with any double quotes.
    std::string glbName = "";  // eps if string literal else name of global symbol
    _str_t(std::string, std::string, std::string); // contents, encoding
    _str_t(std::string); // contents
} str_t;

extern std::vector<irquad_t> IRDump;

extern std::unordered_set<unsigned int> Labels;

extern std::vector<str_t> StrDump;

extern std::string eps; // empty string (epsilon)

extern std::string nextQuadLabel; // label for next (upcoming) instruction

extern unsigned int totLabels;

extern unsigned int totalTmp;

extern bool show_eq; // to show different types of '=' (deprecated).

extern unsigned int _w_contents;

extern unsigned int _w_encoding;

extern unsigned int _w_glbName;

unsigned int nextIdx();

void emit(std::string, class Type *, std::string, std::string, class Type *, std::string, class Type *); // emit into global (incremental) code stream

void emit(std::string, class Type *, std::string, std::string, class Type *); // emit into global (incremental) code stream

void dumpIRCode(std::ofstream &, int, int, irquad_t &); // dump single 3AC code into a file

void dumpIR(std::ofstream &f, std::vector<irquad_t> &irArr); // dump 3AC code into a file

void dumpStr(std::ofstream &, std::vector<str_t> &); // dump string literals into a file

std::string newLabel(); // generate a unique new label

std::string newLabel(std::string); // generate a unique new label (with preffered name - not guaranteed)

std::string newTmp(); // generate a unique new temporary

std::string newTmp(class Type *); // store class (after CLONING!) for the temp. var.

void backpatch(std::vector<unsigned int> &, unsigned int);

void backpatch(std::vector<unsigned int> &, std::string);

std::vector<unsigned int> merge(std::vector<unsigned int> &, std::vector<unsigned int> &);

std::vector<unsigned int> merge(std::vector<std::vector<unsigned int>>);

void handle(node_t*,node_t*,node_t*, int, std::string);

Type* handle_as(int ,node_t*,node_t*, std::string &, std::string &, bool, bool);

// revisit 3ac codes once to expand array/member access and addressof operators.
// may be used for optimization purposes too.
void revisit3AC(std::vector <irquad_t> &);

void resetIRCodes(); // reset all global variables for next file

#endif
