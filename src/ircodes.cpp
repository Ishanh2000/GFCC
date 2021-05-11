// AUM SHREEGANESHAAYA NAMAH||
// compile using g++ -Iinclude -DTEST_IRCODES ircodes.cpp
#include <iostream>
#include <iomanip>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_set>
#include <ops.h>

#include <symtab.h>
#include <ircodes.h>

using namespace std;

vector<irquad_t> IRDump;

unordered_set<unsigned int> Labels;

vector<str_t> StrDump;

string eps = ""; // empty string (epsilon)

string nextQuadLabel = ""; // label for next (upcoming) instruction

bool show_eq = false; // to show different types of '=' (deprecated).

unsigned int totLabels = 0;
unsigned int totalTmp = 0;

void resetIRCodes() { // reset all global variables for next file
    IRDump.clear();
    Labels.clear();
    StrDump.clear();
    nextQuadLabel = "";
    totLabels = 0;
    totalTmp = 0;
}

_irquad_t::_irquad_t (string opr, string dst, string src1, string src2) : opr(opr), dst(dst), src1(src1), src2(src2) { }

_irquad_t::_irquad_t (string opr, string dst, class Type * t_dst, string src1, class Type * t_src1, string src2, class Type * t_src2) : opr(opr), dst(dst), src1(src1), src2(src2), t_dst(t_dst), t_src1(t_src1), t_src2(t_src2) { }

_str_t::_str_t (string _contents) : contents(_contents) { }

_str_t::_str_t (string _contents, string _encoding) : contents(_contents), encoding(_encoding) { }

unsigned int nextIdx() {
    return IRDump.size();
}

void emit(string dst, class Type * t_dst, string opr, string src1, class Type * t_src1, string src2, class Type * t_src2) { // emit into global (incremental) code stream
    irquad_t q = _irquad_t(opr, dst, t_dst, src1, t_src1, src2, t_src2);
    q.label = nextQuadLabel;
    IRDump.push_back(q);
    if((opr == "goto" || opr == "ifgoto") && src1 != "---") {
        try
        {
            Labels.insert(stoi(src1));
        }
        catch(...){

        }
    }
    nextQuadLabel = eps;
}

void emit(string dst, class Type *  t_dst, string opr, string src, class Type * t_src) { emit(dst, t_dst, opr, src, t_src, eps, NULL); }

string newLabel() { return newLabel("LABEL"); }

string newLabel(string prefName) { // generate a unique new label (with preffered name - not guaranteed)
    nextQuadLabel = prefName + "_" + to_string(totLabels++);
    return nextQuadLabel;
}

string newTmp() {
    return "0t_" + to_string(totalTmp++);
}

string newTmp(class Type *t) {
    string tmpName = "0t_" + to_string(totalTmp++);
    SymRoot->pushSym(tmpName, t, { 0, 0 });
    return tmpName;
}

void backpatch(vector<unsigned int> & lst, unsigned int jmpinstr) {
    backpatch(lst, to_string(jmpinstr));
}

void backpatch(vector<unsigned int> & lst, string jmpinstr) {
    // * assume if jumpinstr is number then it must be a goto label
    if (!lst.empty()) {
        try
        {
            Labels.insert(stoi(jmpinstr));
        }
        // not a number
        catch(const std::invalid_argument& e)
        {
            std::cerr << "bakpatch: "<< e.what() << ": not making label for " + jmpinstr << '\n';
        }
        catch(...){
            cerr<<"bakpatch: something went wrong while stoi()" << endl;
        }
    }
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
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "int2real", e1, one->type, eps, NULL);
            e1 = tmp;
        }
        if(!r2) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "int2real", e2, three->type, eps, NULL);
            e2 = tmp;
        }
    }
    else {
        if(r1) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "real2int", e1, one->type, eps, NULL);
            e1 = tmp;
        }
        if(r2) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "real2int", e2, three->type, eps, NULL);
            e2 = tmp;
        }
    }
    
    string opr;
    if (tr->grp() == BASE_G) {
        Base* b = (Base*) tr;
        if (priority1[b->base] >= priority1[FLOAT_B]) opr = "real";
    }

    dollar->eval = newTmp(clone(tr));
    // switch(op){
    //     case 'a': opr += "<<"; break;
    //     case 'b': opr += ">>"; break;
    //     default: opr += to_string(op);
    // }
    emit(dollar->eval, tr, opr + op_label, e1, one->type, e2, three->type);
    dollar->type = tr;
    dollar->type->lvalue = false;
}

Type* handle_as(int op,node_t* one,node_t* three, std::string & e1, std::string & e2, bool r1,bool r2) {

    Type* tr;

    tr = bin(op, one, three);
    if(isReal(tr)) {
        if(!r1) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "int2real", e1, one->type, eps, NULL);
            e1 = tmp;
        }
        if(!r2) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "int2real", e2, three->type, eps, NULL);
            e2 = tmp;
        }
    }
    else {
        if(r1) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "real2int", e1, one->type, eps, NULL);
            e1 = tmp;
        }
        if(r2) {
            string tmp = newTmp(clone(tr));
            emit(tmp, tr, "real2int", e2, three->type, eps, NULL);
            e2 = tmp;
        }
    }

    return tr;
}

void dumpStr(ofstream &f, vector<str_t> &strArr) { // dump string literals into a file
    f << ".data" << endl << endl;
    int l = strArr.size(), _w = to_string(l).size() + 3;

    for (int i = 0; i < l; i++) {
        str_t &s = strArr[i];
        f << setw(_w) << "0s_" + to_string(i) << " : ";
        f << setw(10) << s.encoding << " \"" << s.contents << "\"" << endl;
    }
    
    f << endl;
}

void dumpIRCode(ofstream &f, int _w, int i, irquad_t &q) { // dump single 3AC code into a file
    if (q.label != eps) f << q.label << " :" << endl;
    f << setw(_w) << (i) << " : ";

    // goto <src1>
    if (q.opr == "goto") f << "goto " << q.src1;

    // label <src1>
    else if (q.opr == "label") f << "label " << q.src1;
    
    // if <src2> then goto <src1>
    else if (q.opr == "ifgoto") f << "if " << q.src2 << " then goto " << q.src1;
    
    // call <src1>, <src2>
    else if (q.opr == "call") f << "call " << q.src1 << ", " << q.src2;
    
    // param <src1>
    else if (q.opr == "param") f << "param " << q.src1;
    
    // func <src1>
    else if (q.opr == "func") f << "function <" + q.src1 << "> :";

    // return <src1>
    else if (q.opr == "return") f << ((q.src1 == eps) ? "return" : "return ") << q.src1;

    // scope related stuff
    else if ((q.opr == "newScope") || (q.opr == "closeScope")) {
        // do not print if not a regular scope
        // if (q.src1.substr(0, 5) != "func ") f << q.opr << " " << q.src1;
        f << q.opr << " " << q.src1;
    }

    else if (q.opr == "function end") f << q.opr << endl;
    
    // dst = <src1> [load/store/move]
    else if (q.opr == eps) f << q.dst << " " << (show_eq ? q.eq : "=") << " " << q.src1;

    else {
        // <dst> = <opr> <src1> [unary]
        if (q.src2 == eps) f << q.dst << " " << (show_eq ? q.eq : "=") << " " << q.opr << " " << q.src1;

        // <dst> = <src1> <opr> <src2> [actually "binary" operations]
        else f << q.dst << " " << (show_eq ? q.eq : "=") << " " << q.src1 << " " << q.opr << " " << q.src2;
    }
}

void dumpIR(ofstream &f, vector<irquad_t> &irArr) { // dump 3AC codes into a file
    f << ".text" << endl << endl;
    int l = irArr.size(), _w = to_string(l).size();
    for (int i = 0; i < l; i++) { dumpIRCode(f, _w, i, irArr[i]); f << endl; }
    f << endl;
}

void revisit3AC(vector <irquad_t> & codes) {
    vector <irquad_t> codes2;
    unsigned int l = codes.size(), diff = 0;
    for (unsigned int i = 0; i < l; i++) {
        irquad_t q = codes[i]; // make a copy

        // TASK 1: LABEL MODIFICATION
        if (q.opr == "goto" || q.opr == "ifgoto") q.src1 = to_string(stoul(q.src1) + diff);

        // TASK 2: NOW TRANSFORM THE INSTRUCTION q AND APPEND TO codes2
        // if (q.opr == "+") { // transform to 2 instructions
        //     irquad_t q1(q.src1, "+", q.src1, "0"); // doing nothing
        //     codes2.push_back(q1);
        //     codes2.push_back(q);
        // }
    }
    codes = codes2; // literally copying everything (overwriting)
}


#ifdef TEST_IRCODES
vector<unsigned int> nextlist = {1,2,5};

// IMPORTANT : check new definition of emit() and change tests accordingly 

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
