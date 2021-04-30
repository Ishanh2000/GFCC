// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_IRC__
#define __GFCC_IRC__

#include <fstream>
#include <string>

#include <gfcc_lexer.h>
#include <types2.h>

typedef struct _irquad_t {
    std::string dst = "";
    std::string opr = "";
    std::string src1 = "";
    std::string src2 = "";
    std::string label = "";
    // some constructors
    _irquad_t(std::string, std::string, std::string, std::string);
} irquad_t;
typedef struct _str_t { // for strings to be used in ".data" section
    // std::string label = ""; // will uncomment if required
    std::string encoding = ".asciiz";
    std::string contents = ""; // store without any double quotes.
    _str_t(std::string, std::string); // contents, encoding
    _str_t(std::string); // contents
} str_t;

extern std::vector<irquad_t> IRDump;

extern std::vector<str_t> StrDump;

extern std::string eps; // empty string (epsilon)

extern std::string nextQuadLabel; // label for next (upcoming) instruction

extern unsigned int totLabels;

extern unsigned int totalTmp;

unsigned int nextIdx();

void emit(std::string, std::string, std::string, std::string); // emit into global (incremental) code stream

void emit(std::string, std::string, std::string); // emit into global (incremental) code stream

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

void resetIRCodes(); // reset all global variables for next file

#endif
