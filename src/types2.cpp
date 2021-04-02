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

/******************************************************/
/****************** struct "_qual_t" ******************/
/******************************************************/

_qual_t::_qual_t () { }

_qual_t::_qual_t (bool _isConst, bool _isVoltl) : isConst(_isConst), isVoltl(_isVoltl) { }

/**************************************************/
/****************** class "Type" ******************/
/**************************************************/

grp_t Type::grp() { return NONE_G; }

string Type::str() { return ""; }

/**************************************************/
/****************** class "Base" ******************/
/**************************************************/

Base::Base() { }

Base::Base(base_t _base) : base(_base) { }

grp_t Base::grp() { return BASE_G; }

string Base::str() {
    vector<string> sv;
    
    if (isConst) sv.push_back("const");
    if (isVoltl) sv.push_back("volatile");
    
    switch (strg) {
        case AUTO_S : sv.push_back("auto"); break;
        case EXTERN_S : sv.push_back("extern"); break;
        case REGISTER_S : sv.push_back("register"); break;
        case STATIC_S : sv.push_back("static"); break;
        case TYPEDEF_S : sv.push_back("typedef"); break;
    }

    switch (sign) {
        case SIGNED_X : sv.push_back("signed"); break;
        case UNSIGNED_X : sv.push_back("unsigned"); break;
    }

    switch (base) {
        case ERROR_B : sv.push_back("error_type"); break;
        case VOID_B : sv.push_back("void"); break;
        case CHAR_B : sv.push_back("char"); break;
        case SHORT_B : sv.push_back("short int"); break;
        case INT_B : sv.push_back("int"); break;
        case FLOAT_B : sv.push_back("float"); break;
        case LONG_B : sv.push_back("long int"); break;
        case LONG_LONG_B : sv.push_back("long long int"); break;
        case DOUBLE_B : sv.push_back("double"); break;
        case LONG_DOUBLE_B : sv.push_back("long double"); break;
        // case ENUM_B : sv.push_back("enum"); break;
        // case STRUCT_B : sv.push_back("struct"); break;
        // case UNION_B : sv.push_back("union"); break;
        case ELLIPSIS_B : sv.push_back("..."); break;
    }
    string s;
    int l = sv.size();
    for (int i = 0; i < l; i++) {
        if (i > 0) s += " ";
        s += sv[i];
    }
    return s;
}


/*************************************************/
/****************** class "Ptr" ******************/
/*************************************************/

Ptr::Ptr(class Type *_pt) : pt(_pt) { ptrs.push_back(qual_t()); }

Ptr::Ptr(class Type *_pt, bool _isConst, bool _isVoltl) : pt(_pt) { ptrs.push_back(qual_t(_isConst, _isVoltl)); }

grp_t Ptr::grp() { return PTR_G; };

string Ptr::str() {
    if (!pt) return "";
    string s, tmp; int l = ptrs.size(), _p;
    switch (pt->grp()) {
        case BASE_G : // pointer to base class
            s = pt->str();
            for (int i = 0; i < l; i++) {
                s += " *";
                qual_t q = ptrs[i]; if (q.isConst) s += " const"; if (q.isVoltl) s += " volatile";
            }
            break;
        case ARR_G : // pointer to array
            s = pt->str();
            _p = s.find_first_of('['); if (_p < 0) break; // failure
            
            tmp = "(";
            for (int i = 0; i < l; i++) {
                if (i > 0) tmp += " "; tmp += "*";
                qual_t q = ptrs[i]; if (q.isConst) s += " const"; if (q.isVoltl) s += " volatile";
            }
            tmp += ")";
            s.insert(_p, tmp);
            break;
        case FUNC_G : // pointer to function
            s = pt->str();
            _p = s.find_first_of(')'); if (_p < 0) break; // failure
            
            for (int i = 0; i < l; i++) {
                if (i > 0) tmp += " "; tmp += "*";
                qual_t q = ptrs[i]; if (q.isConst) tmp += " const"; if (q.isVoltl) tmp += " volatile";
            }
            s.insert(_p, tmp);
            break;
        // PTR_G means "pointer to pointer" - should not be encountered
    }
    return s;
}

void Ptr::newPtr() {
    ptrs.push_back(qual_t());
}

void Ptr::newPtr(struct _qual_t q) {
    ptrs.push_back(qual_t(q));
}

void Ptr::newPtr(bool _isConst, bool _isVoltl) {
    ptrs.push_back(qual_t(_isConst, _isVoltl));
}

/*************************************************/
/****************** class "Arr" ******************/
/*************************************************/

Arr::Arr(class Type *_item) : item(_item) { dims.push_back(NULL); }

Arr::Arr(class Type *_item, struct _node_t *_evalNode) : item(_item) { dims.push_back(_evalNode); }

void Arr::newDim() {
    dims.push_back(NULL);
}

void Arr::newDim(struct _node_t *_evalNode) {
    dims.push_back(_evalNode);
}

grp_t Arr::grp() { return ARR_G; }

std::string Arr::str() {
    if (!item) return "";
    string s;
    switch (item->grp()) {
        case BASE_G: s += item->str(); break; // array of base types
        case  PTR_G: s += item->str(); break; // array of pointers
        // other cases (ARR_G - array of arrays, FUNC_G - array of functions) should not be possible
    }
    int l = dims.size();
    s += " ";
    for (int i = 0; i < l; i++) s += "[]"; // try getting actual number from dims' nodes, if possible.

    return s;
}

/**************************************************/
/****************** class "Func" ******************/
/**************************************************/

Func::Func(class Type *_retType) : retType(_retType) { }

void Func::newParam(class Type *t) {
    params.push_back(t);
}

grp_t Func::grp() { return FUNC_G; }

std::string Func::str() {
    if (!retType) return "";
    string s = retType->str();
    s += " ()(";

    int l = params.size();
    for (int i = 0; i < l; i++) {
        if (i > 0) s += ", ";
        s += params[i]->str();
    }
    s += ")";
    return s;
}


/************************************************/
/****************** TEST SUITE ******************/
/************************************************/

#ifdef TEST_TYPES

#define MAX_TESTNAME_WIDTH 12

void testOut(string testName, string testResult) {
    cout << _C_BOLD_ << _FORE_GREEN_ << setw(MAX_TESTNAME_WIDTH) << testName << " :";
    cout << _C_NONE_ << " \"" << testResult << "\"" << endl;
}

void testBase() { // const unsigned int volatile static;
    Base* b = new Base();
    b->base = INT_B; b->sign = UNSIGNED_X; b->strg = STATIC_S; b->isConst = true; b->isVoltl = true;
    
    Type* t = b;
    if (t->grp() == BASE_G) testOut("base class", t->str());
}

void testPtr() { // const int ** const *volatile;
    Base *b = new Base(INT_B); b->isConst = true;
    Ptr* p = new Ptr(b); p->newPtr(true, false); p->newPtr(false, true);

    Type* t = p;
    if (t->grp() == PTR_G) testOut("ptr class", t->str());
}

void testArr() { // const double [][][];
    Base *b = new Base(DOUBLE_B); b->isConst = true;
    Arr *a = new Arr(b); a->newDim(NULL); a->newDim();

    Type *t = a;
    if (t->grp() == ARR_G) testOut("arr class", t->str());
}

void testFunc() { // void ()(unsigned char, ...);
    Base *b = new Base(VOID_B);
    Base *b1 = new Base(CHAR_B); b1->sign = UNSIGNED_X;
    Base *b2 = new Base(ELLIPSIS_B);
    Func *f = new Func(b); f->newParam(b1); f->newParam(b2);
    
    Type *t = f;
    if (t->grp() == FUNC_G) testOut("func class", t->str());
}

void testComplex_1() { // int *const (* volatile f)(); // surprisingly, a "const" (pointer or value) can be returned.
    Base *b = new Base(INT_B);
    Ptr *pb = new Ptr(b, true, false);
    Func *f = new Func(pb);
    Ptr *p = new Ptr(f, false, true);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_1", t->str());
}

void testComplex_2() { // float (*f)[4][5][6];
    Base *b = new Base(FLOAT_B);
    Arr *a = new Arr(b, NULL); a->newDim(); a->newDim(NULL);
    Ptr *p = new Ptr(a);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_2", t->str());
}

void testComplex_3() { // int *** (*(*)(char))[]
    Base *b = new Base(INT_B); // int
    testOut("1", b->str());

    Ptr *p = new Ptr(b); p->newPtr(); p->newPtr(); // int ***
    testOut("2", p->str());
    
    Arr *a = new Arr(p); // int*** []
    testOut("3", a->str());
    
    Ptr *pa = new Ptr(a); // int *** (*) []
    testOut("4", pa->str());
    
    Func *f = new Func(pa); f->newParam(new Base(CHAR_B)); // int *** (*()(char))[]
    testOut("5", f->str());

    Ptr *pf = new Ptr(f); // // int *** (*(*)(char))[]
    testOut("6", pf->str());

    // Type *t = pf;
    // if (t->grp() == PTR_G) testOut("complex_3", t->str());
}

int main(){
	// testBase();
	// testPtr();
	// testArr();
	// testFunc();

    // testComplex_1();
    // testComplex_2();
    testComplex_3();
	
	return 0;	
}

#endif
