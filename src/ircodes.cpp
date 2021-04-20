// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_IRCODES__
#define __GFCC_IRCODES__

// compile using g++ -Iinclude -DTEST_IRCODES ircodes.cpp

#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <vector>
#include <ops.h>
// #include <unordered_map>

#include <ircodes.h>

using namespace std;

vector<irquad_t> IRDump;

string eps = ""; // empty string (epsilon)

string nextQuadLabel = ""; // label for next (upcoming) instruction

unsigned int totLabels = 0;
unsigned int totalTmp = 0;

_irquad_t::_irquad_t(string opr, string dst, string src1, string src2) : opr(opr), dst(dst), src1(src1), src2(src2) { }

unsigned int nextIdx() {
    return IRDump.size();
}

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

string newTmp() {
    return "t_" + to_string(totalTmp++);
}

void backpatch(vector<unsigned int> & lst, unsigned int jmpinstr) {
    backpatch(lst, to_string(jmpinstr));
}

void backpatch(vector<unsigned int> & lst, string jmpinstr) {
    for(auto i: lst){
        IRDump[i].src1 = jmpinstr;
    }
    lst = {};
}

std::vector<unsigned int>  merge(
    std::vector<unsigned int> & l1, std::vector<unsigned int> &l2) {
    std::vector<unsigned int> merged = l1;
    merged.insert(merged.end(), l2.begin(), l2.end());
    return merged;
}

std::vector<unsigned int> merge(std::vector<std::vector<unsigned int>> vl) {
    std::vector<unsigned int> merged;
    for(auto lst: vl){
        merged.insert(merged.end(), lst.begin(), lst.end());
    }
    return merged;
}



void handle(node_t* dollar, node_t* one, node_t* three, int op, string op_label) {

    string e1 = one->eval, e2 = three->eval;
    bool r1 = isReal(one->type), r2 = isReal(three->type);
    Type *tr = bin(op, one, three);
    if(isReal(tr)) {
        if(!r1) {
            string tmp = newTmp();
            emit(tmp, "int2real", e1, eps);
            e1 = tmp;
        }
        if(!r2) {
            string tmp = newTmp();
            emit(tmp, "int2real", e2, eps);
            e2 = tmp;
        }
    }
    else {
        if(r1) {
            string tmp = newTmp();
            emit(tmp, "real2int", e1, eps);
            e1 = tmp;
        }
        if(r2) {
            string tmp = newTmp();
            emit(tmp, "real2int", e2, eps);
            e2 = tmp;
        }
    }
    string opr;
    if(tr->grp() == BASE_G) {
            Base* b = (Base*) tr;
            if(priority1[b->base] >= priority1[FLOAT_B] ) {
                opr = "real";
            }
    }
    dollar->eval = newTmp();
    // switch(op){
    //     case 'a': opr += "<<"; break;
    //     case 'b': opr += ">>"; break;
    //     default: opr += to_string(op);
    // }
    emit(dollar->eval, opr+op_label, e1, e2);
    dollar->type = tr;
    dollar->type->lvalue = false;


}

Type* handle_as(int op,node_t* one,node_t* three, std::string & e1, std::string & e2, bool r1,bool r2) {

    Type* tr;

    tr = bin(op, one, three);
    if(isReal(tr)) {
        if(!r1) {
            string tmp = newTmp();
            emit(tmp, "int2real", e1, eps);
            e1 = tmp;
        }
        if(!r2) {
            string tmp = newTmp();
            emit(tmp, "int2real", e2, eps);
            e2 = tmp;
        }
    }
    else {
        if(r1) {
            string tmp = newTmp();
            emit(tmp, "real2int", e1, eps);
            e1 = tmp;
        }
        if(r2) {
            string tmp = newTmp();
            emit(tmp, "real2int", e2, eps);
            e2 = tmp;
        }
    }

    return tr;
}

void dumpIR(ofstream &f, vector<irquad_t> &irArr) { // dump into a file
    int l = irArr.size(), _w = to_string(l).size();

    for (int i = 0; i < l; i++) {
        irquad_t &q = irArr[i];
        if (q.label != eps) f << q.label << " :" << endl;
        f << setw(_w) << (i) << " : ";

        if (q.opr == "goto") {
            f << "goto " << q.src1; // goto <src1>
        }
        else if (q.opr == "ifgoto") {
            f << "if " << q.src2 << " then goto " << q.src1; // if <src2> then goto <src1>
        }
         else {
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
vector<unsigned int> nextlist = {1,2,5};

void testIRCodes_1() { // a = b*-c + b*-c
    emit("t1", "-", "c"); // t1 = -c
    emit("t2", "*", "b", "t1"); // t2 = b * t1
    cout<<nextIdx()<<endl;
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

void testIRCodes_2() { 
    emit(eps, "goto", "---"); // goto ---
    emit(eps, "goto", "---"); // goto ---
    emit(eps, "goto", "---"); // goto ---
    emit(eps, "goto", "---"); // goto ---
    emit(eps, "goto", "---"); // goto ---
    emit(eps, "goto", "---"); // goto ---
    backpatch(nextlist, "100");
    ofstream f; f.open("irTest_2.txt");
    dumpIR(f, IRDump);
    f.close();
}

void testIRCodes_3() { }

int main() {
    // testIRCodes_1();
    testIRCodes_2();
    testIRCodes_3();

    return 0;
}

#endif

#endif
