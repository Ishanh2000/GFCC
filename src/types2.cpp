// AUM SHREEGANESHAAYA NAMAH||

/************************ NOTE TO THE DEVELOPER ************************
 * SEE <proj_root>/src/include/types2.h for description of various classes,
   members, methods, etc.
 * Search "TODO" for things to do.
 * Search "ASSUMPTIONS" for assumptions.
 * Execution using: g++ -std=c++11 [-DTEST_TYPES] types.cpp -Iinclude && ./a.out
************************************************************************/

#include <iostream>
#include <iomanip>

#include <gfcc_colors.h>
#include <types2.h>

#ifdef DEBUG_TYPES
const static bool dbg = true;
#else
const static bool dbg = false;
#endif

using namespace std;

bool brackPut = false;

static void replace(string &str, const string &a, const string &b) {
    // Replace the instance of a (in str) with b. Only one instance guaranteed.
    int _start = str.find(a);
    if (_start >= 0) str.replace(_start, a.size(), b);
}

static void rm(string &str, const string &a) { // remove all instances of a in str.
    int la = a.size(), _start;
    while ((_start = str.find(a)) >= 0) str.replace(_start, la, "");
}

static void btfy(string &str) { // beautify
    rm(str, "<p>"); rm(str, "<ab>"); rm(str, "<ad>"); rm(str, "<fb>"); rm(str, "<fp>");
}

/******************************************************/
/****************** struct "_qual_t" ******************/
/******************************************************/

_qual_t::_qual_t () { }

_qual_t::_qual_t (bool _isConst, bool _isVoltl) : isConst(_isConst), isVoltl(_isVoltl) { }

/**************************************************/
/****************** class "Type" ******************/
/**************************************************/

grp_t Type::grp() { return NONE_G; }

string Type::_str() { return ""; }

/**************************************************/
/****************** class "Base" ******************/
/**************************************************/

Base::Base() { }

Base::Base(base_t _base) : base(_base) { }

grp_t Base::grp() { return BASE_G; }

/*************************************************/
/****************** class "Ptr" ******************/
/*************************************************/

Ptr::Ptr(class Type *_pt) : pt(_pt) { ptrs.push_back(qual_t()); }

Ptr::Ptr(class Type *_pt, bool _isConst, bool _isVoltl) : pt(_pt) { ptrs.push_back(qual_t(_isConst, _isVoltl)); }

grp_t Ptr::grp() { return PTR_G; };

void Ptr::newPtr() { ptrs.push_back(qual_t()); }

void Ptr::newPtr(struct _qual_t q) { ptrs.push_back(qual_t(q)); }

void Ptr::newPtr(bool _isConst, bool _isVoltl) { ptrs.push_back(qual_t(_isConst, _isVoltl)); }

/*************************************************/
/****************** class "Arr" ******************/
/*************************************************/

Arr::Arr(class Type *_item) : item(_item) { dims.push_back(NULL); }

Arr::Arr(class Type *_item, struct _node_t *_evalNode) : item(_item) { dims.push_back(_evalNode); }

void Arr::newDim() { dims.push_back(NULL); }

void Arr::newDim(struct _node_t *_evalNode) { dims.push_back(_evalNode); }

grp_t Arr::grp() { return ARR_G; }

/**************************************************/
/****************** class "Func" ******************/
/**************************************************/

Func::Func(class Type *_retType) : retType(_retType) { }

void Func::newParam(class Type *t) {
    params.push_back(t);
}

grp_t Func::grp() { return FUNC_G; }

/***************************************************/
/****************** "str" methods ******************/
/***************************************************/

string Base::_str() {
    string s;
    if (isConst) s += "const";
    if (isVoltl) s += "volatile";
    s += " ";
    switch (strg) {
        case AUTO_S : s += "auto"; break;
        case EXTERN_S : s += "extern"; break;
        case REGISTER_S : s += "register"; break;
        case STATIC_S : s += "static"; break;
        case TYPEDEF_S : s += "typedef"; break;
    }
    s += " ";
    switch (sign) {
        case SIGNED_X : s += "signed"; break;
        case UNSIGNED_X : s += "unsigned"; break;
    }
    s += " ";
    switch (base) {
        case ERROR_B : s += "error_type"; break;
        case VOID_B : s += "void"; break;
        case CHAR_B : s += "char"; break;
        case SHORT_B : s += "short int"; break;
        case INT_B : s += "int"; break;
        case FLOAT_B : s += "float"; break;
        case LONG_B : s += "long int"; break;
        case LONG_LONG_B : s += "long long int"; break;
        case DOUBLE_B : s += "double"; break;
        case LONG_DOUBLE_B : s += "long double"; break;
        // case ENUM_B : s += "enum"; break;
        // case STRUCT_B : s += "struct"; break;
        // case UNION_B : s += "union"; break;
        case ELLIPSIS_B : s += "..."; break;
    }
    return s + " <p><ab><ad><fb><fp>"; // return according to expectations of others
    
}

string Ptr::_str() {
    if (!pt) return "";

    string p; int l = ptrs.size();
    for (int i = 0; i < l; i++) {
        p += "*";
        if (ptrs[i].isConst) p += " const ";
        if (ptrs[i].isVoltl) p += " volatile ";
    }
    // p is the string to replace <ptr> in incoming string.

    p += "<ab><ad><fb><fp>";
    if (pt->grp() == ARR_G) { p.insert(0, "("); p.push_back(')'); }
    
    string s = pt->_str();
    replace(s, "<p>", p);

    return s; // return according to expectations of others
}

std::string Arr::_str() {
    if (!item) return "";

    string d; int l = dims.size();
    for (int i = 0; i < l; i++) d += "[]"; // try getting actual number from dims' nodes, if possible.

    string s = item->_str();

    rm(s, "<p>"); rm(s, "<fb>"); rm(s, "<fp>");
    replace(s, "<ab>", "<p>");
    replace(s, "<ad>", d);

    return s; // return according to expectaton of others
}

std::string Func::_str() {
    if (!retType) return "";

    string r = "("; int l = params.size();
    for (int i = 0; i < l; i++) {
        if (i > 0) r += ", "; r += params[i]->_str();
    }
    r += ")";

    string s = retType->_str();
    rm(s, "<p>"); rm(s, "<ab>"); rm(s, "<ad>");
    replace(s, "<fb>", "(<p>)");
    replace(s, "<fp>", r);

    return s; // return according to expectation of others
}


/************************************************/
/****************** TEST SUITE ******************/
/************************************************/

#ifdef TEST_TYPES

#define MAX_TESTNAME_WIDTH 12

void testOut(string testName, string testResult) {
    btfy(testResult);
    cout << _C_BOLD_ << _FORE_GREEN_ << setw(MAX_TESTNAME_WIDTH) << testName << " :";
    cout << _C_NONE_ << " \"" << testResult << "\"" << endl;
}

void testBase() { // const unsigned int volatile static;
    Base* b = new Base();
    b->base = INT_B; b->sign = UNSIGNED_X; b->strg = STATIC_S; b->isConst = true; b->isVoltl = true;
    
    Type* t = b;
    if (t->grp() == BASE_G) testOut("base class", t->_str());
}

void testPtr() { // const int ** const *volatile;
    Base *b = new Base(INT_B); b->isConst = true;
    Ptr* p = new Ptr(b); p->newPtr(true, false); p->newPtr(false, true);

    Type* t = p;
    if (t->grp() == PTR_G) testOut("ptr class", t->_str());
}

void testArr() { // const double [][][];
    Base *b = new Base(DOUBLE_B); b->isConst = true;
    Arr *a = new Arr(b); a->newDim(NULL); a->newDim();

    Type *t = a;
    if (t->grp() == ARR_G) testOut("arr class", t->_str());
}

void testFunc() { // void ()(unsigned char, ...);
    Base *b = new Base(VOID_B);
    Base *b1 = new Base(CHAR_B); b1->sign = UNSIGNED_X;
    Base *b2 = new Base(ELLIPSIS_B);
    Func *f = new Func(b); f->newParam(b1); f->newParam(b2);
    
    Type *t = f;
    if (t->grp() == FUNC_G) testOut("func class", t->_str());
}

void testComplex_1() { // int *const (* volatile f)(); // surprisingly, a "const" (pointer or value) can be returned.
    Base *b = new Base(INT_B);
    Ptr *pb = new Ptr(b, true, false);
    Func *f = new Func(pb);
    Ptr *p = new Ptr(f, false, true);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_1", t->_str());
}

void testComplex_2() { // float (*f)[4][5][6];
    Base *b = new Base(FLOAT_B);
    Arr *a = new Arr(b, NULL); a->newDim(); a->newDim(NULL);
    Ptr *p = new Ptr(a);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_2", t->_str());
}

void testComplex_3() { // int *** (*(*)(char))[]
    Base *b = new Base(INT_B); // int
    Ptr *p = new Ptr(b); p->newPtr(); p->newPtr(); // int ***
    Arr *a = new Arr(p); // int*** []
    Ptr *pa = new Ptr(a); // int *** (*) []
    Func *f = new Func(pa); f->newParam(new Base(CHAR_B)); // int *** (*()(char))[]
    Ptr *pf = new Ptr(f); // int *** (*(*)(char))[]

    Type *t = pf;
    if (t->grp() == PTR_G) {
        string _s = t->_str();
        rm(_s, "<p>"); rm(_s, "<ab>"); rm(_s, "<ad>"); rm(_s, "<fb>"); rm(_s, "<fp>");
        cout << _s.find("<ab>") << endl;
        cout << _s << endl;
    }
}

void testComplex_4() { // int *(*(*(*(*(*(*[])[])[])[])[])[])[]
    Base *b = new Base(INT_B); // int
    Ptr *p1 = new Ptr(b); // int *
    Arr *a1 = new Arr(p1); // int *[]
    Ptr *p2 = new Ptr(a1); // int *(*)[]
    Arr *a2 = new Arr(p2); // int *(*[])[]
    Ptr *p3 = new Ptr(a2); // int *(*(*)[])[]
    Arr *a3 = new Arr(p3); // int *(*(*[])[])[]
    Ptr *p4 = new Ptr(a3); // int *(*(*(*)[])[])[]
    Arr *a4 = new Arr(p4); // int *(*(*(*[])[])[])[]
    Ptr *p5 = new Ptr(a4); // int *(*(*(*(*)[])[])[])[]
    Arr *a5 = new Arr(p5); // int *(*(*(*(*[])[])[])[])[]
    Ptr *p6 = new Ptr(a5); // int *(*(*(*(*(*)[])[])[])[])[]
    Arr *a6 = new Arr(p6); // int *(*(*(*(*(*[])[])[])[])[])[]
    Ptr *p7 = new Ptr(a6); // int *(*(*(*(*(*(*)[])[])[])[])[])[]
    Arr *a7 = new Arr(p7); // int *(*(*(*(*(*(*[])[])[])[])[])[])[]

    Type *t = a7;
    if (t->grp() == ARR_G) {
        string _s = t->_str();
        cout << _s << endl;
    }
}

void testComplex_5() { // int *** (*(*)(char))()
    cout << "Here" << endl;
    Base *b = new Base(INT_B); // int
    testOut("1", b->_str());
    Ptr *p = new Ptr(b); p->newPtr(); p->newPtr(); // int ***
    testOut("2", p->_str());
    Func *f = new Func(p); // int*** ()()
    testOut("3", f->_str());
    Ptr *pf = new Ptr(f); // int *** (*) ()
    testOut("4", pf->_str());
    Func *ff = new Func(pf); ff->newParam(new Base(CHAR_B)); // int *** (*()(char)) ()
    testOut("5", ff->_str());
    Ptr *pff = new Ptr(ff); // int *** (*(*)(char))()
    testOut("6", pff->_str());

    // Type *t = pff;
    // if (t->grp() == PTR_G) testOut("complex_5", t->_str());    
}

int main(){
	// testBase();
	// testPtr();
	// testArr();
	// testFunc();

    // testComplex_1();
    // testComplex_2();
    // testComplex_3();
    // testComplex_4();
    testComplex_5();
	
	return 0;	
}

#endif
