// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_IRCODES__
#define __GFCC_IRCODES__

// compile using g++ -Iinclude -DTEST_IRCODES ircodes.cpp

#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <vector>
// #include <unordered_map>

#include <ircodes.h>

using namespace std;

vector<irquad_t> IRDump;

string eps = ""; // empty string (epsilon)

string nextQuadLabel = ""; // label for next (upcoming) instruction

unsigned int totLabels = 0;

_irquad_t::_irquad_t(string opr, string dst, string src1, string src2) : opr(opr), dst(dst), src1(src1), src2(src2) { }

void emit(string dst, string opr, string src1, string src2) { // emit into global (incremental) code stream
    irquad_t q = _irquad_t(opr, dst, src1, src2);
    q.label = nextQuadLabel;
    IRDump.push_back(q);
    nextQuadLabel = eps;
}

void emit(string dst, string opr, string src) { emit(dst, opr, src, eps); }

string newLabel() { return newLabel("LABEL"); }

string newLabel(string prefName) { // generate a unique new label (with preffered name - not guaranteed)
    nextQuadLabel = prefName + "_" + to_string(totLabels++);
    return nextQuadLabel;
}

void dumpIR(ofstream &f, vector<irquad_t> &irArr) { // dump into a file
    int l = irArr.size(), _w = to_string(l).size();

    for (int i = 0; i < l; i++) {
        irquad_t &q = irArr[i];
        if (q.label != eps) f << q.label << " :" << endl;
        f << setw(_w) << (i + 1) << " : ";

        if (q.opr == "goto") {
            if (q.src2 == eps) f << "goto " << q.src1; // goto <src1>
            else f << "if " << q.src2 << " goto " << q.src1; // if <src2> goto <src1>

        } else {
            if (q.opr == eps) f << q.dst << " = " << q.src1; // dst = <src1> [load/store/move]
            else {
                if (q.src2 == eps) f << q.dst << " = " << q.opr << " " << q.src1; // <dst> = <opr> <src1> [unary]
                else f << q.dst << " = " << q.src1 << " " << q.opr << " " << q.src2; // <dst> = <src1> <opr> <src2> [real operations]
            }
        }

        f << endl;
    }
}

#ifdef TEST_IRCODES

void testIRCodes_1() { // a = b*-c + b*-c
    emit("t1", "-", "c"); // t1 = -c
    emit("t2", "*", "b", "t1"); // t2 = b * t1
    emit("t3", "-", "c"); // t3 = -c
    emit("t4", "*", "b", "t3"); // t4 = b * t3
    emit("t5", "+", "t2", "t4"); // t5 = t2 + t4
    newLabel();
    emit("a", eps, "t5"); // a  = t5
    emit("res", "<", "t1", "t2"); // res = t1 < t2
    emit(eps, "goto", "101", "res"); // if res goto 101
    emit(eps, "goto", "104"); // goto 104

    ofstream f; f.open("irTest_1.txt");
    dumpIR(f, IRDump);
    f.close();
}

void testIRCodes_2() { }

void testIRCodes_3() { }

int main() {
    testIRCodes_1();
    testIRCodes_2();
    testIRCodes_3();

    return 0;
}

#endif

#endif
