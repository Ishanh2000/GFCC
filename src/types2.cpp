// AUM SHREEGANESHAAYA NAMAH||

/************************ NOTE TO THE DEVELOPER ************************
 * SEE <proj_root>/src/include/types2.h for description of various classes,
   members, methods, etc.
 * Search "TODO" for things to do.
 * Search "ASSUMPTIONS" for assumptions.
 * Execution using: g++ -std=c++11 -Iinclude [-DTEST_TYPES_2] [-DDEBUG_TYPES_2] types2.cpp && ./a.out
 * String related stuff after class methods, before test suites.
************************************************************************/

#include <iostream>
#include <iomanip>

#include <gfcc_colors.h>
#include <types2.h>
#include <symtab.h>

// debugging does not work as of yet - actually not required
#ifdef DEBUG_TYPES_2
const static bool dbg = true;
#else
const static bool dbg = false;
#endif

using namespace std;

bool brackPut = false;
bool tpdef = false;

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

void Func::newParam(class Type *t) { params.push_back(t); }

grp_t Func::grp() { return FUNC_G; }


/****************************************************/
/****************** string methods ******************/
/****************************************************/

static void replace(string &str, const string &a, const string &b) {
    // Replace the instance of a (in str) with b. Only one instance guaranteed.
    int _start = str.find(a);
    if (_start >= 0) str.replace(_start, a.size(), b);
}

static void rm(string &str, const string &a) { // remove all instances of a in str.
    int la = a.size(), _start;
    while ((_start = str.find(a)) >= 0) str.replace(_start, la, "");
}

string str(class Type *t) {
    if (!t) return "";

    if (t->isErr) return "error_type";

    string str;

    switch (t->strg) {
        case AUTO_S : str += "auto "; break;
        case EXTERN_S : str += "extern "; break;
        case REGISTER_S : str += "register "; break;
        case STATIC_S : str += "static "; break;
        case TYPEDEF_S : str += "typedef "; break;
    }

    str += t->_str();
    
    rm(str, "<p>"); rm(str, "<ab>"); rm(str, "<ad>");
    rm(str, "<fb>"); rm(str, "<fp>");
    rm(str, "  ");
    
    // undesired : "( ", " )", add more ...
    int _start;
    while ((_start = str.find("( ")) >= 0) str.replace(_start, 2, "(");
    while ((_start = str.find(" )")) >= 0) str.replace(_start, 2, ")");
    while ((_start = str.find(" ,")) >= 0) str.replace(_start, 2, ",");
    
    // NOTE: Assured that all double spaces ("  ") removed.
    if (str[0] == ' ') str.erase(0, 1);
    if (str.back() == ' ') str.pop_back();
    
    return str;
}

string Base::_str() {
    vector<string> sv;
    if (isConst) sv.push_back("const");
    if (isVoltl) sv.push_back("volatile");

    switch (sign) {
        case SIGNED_X : sv.push_back("signed"); break;
        case UNSIGNED_X : sv.push_back("unsigned"); break;
    }
    string tmp; int _l;
    switch (base) {
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
        case STRUCT_B : case UNION_B :
            tmp = tmp + ((base == STRUCT_B) ? "struct " : "union ") + subDef->name;
            if (subDef->syms.size()) {
                tmp += " { ";
                _l = subDef->syms.size();
                for (int i = 0; i < _l; i++) {
                    if (i) tmp += ", ";
                    tmp += subDef->syms[i]->name + " [" + str(subDef->syms[i]->type) + "]";
                }
                tmp += " }";
            } else tmp += " <not yet defined>";


            sv.push_back(tmp);
            break;
        case ELLIPSIS_B : sv.push_back("..."); break;
    }
    string s; int l = sv.size();
    for (int i = 0; i < l; i++) s = s + sv[i] + " ";
    return s + "<p><ab><ad><fb><fp>"; // return according to expectations of others
}

string Ptr::_str() {
    if (!pt) return "";

    string p; int l = ptrs.size();
    for (int i = 0; i < l; i++) {
        p += "*";
        if (ptrs[i].isConst) p += " const ";
        if (ptrs[i].isVoltl) p += " volatile ";
    } // p is the string to replace <p> in incoming string.

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
        if (i > 0) r += ", "; r += params[i] ? (params[i]->_str()) : "<unknown>";
    }
    r += ")";

    string s = retType->_str();
    rm(s, "<p>"); rm(s, "<ab>"); rm(s, "<ad>");
    replace(s, "<fb>", "(<p>)");
    replace(s, "<fp>", r);

    return s; // return according to expectation of others
}

/*************************************************/
/****************** CLONE MAKER ******************/
/*************************************************/

class Type *clone(class Type *t) {
    if (!t) return NULL;
    Base *b; Ptr *p; Arr *a; Func *f;
    switch (t->grp()) {
        case BASE_G :
            b = new Base(); *b = *((Base *) t); return b;

        case PTR_G :
            p = new Ptr(NULL); *p = *((Ptr *) t); p->pt = clone(((Ptr*) t)->pt); return p;

        case ARR_G :
            a = new Arr(NULL); *a = *((Arr *) t); a->item = clone(((Arr *) t)->item); return a;

        case FUNC_G :
            f = new Func(NULL); *f = *((Func *) t); f->retType = clone(((Func *) t)->retType);
            int l = ((Func *) t)->params.size();
            f->params.clear();
            for (int i = 0; i < l; i++) f->params.push_back(clone(((Func *) t)->params[i]));
            return f;
    }
    Type *c = new Type(); *c = *t; return c;
}


/*************************************************/
/****************** TAIL FINDER ******************/
/*************************************************/

class Type *tail(class Type *t) { // to get tail (last in linked list)
    if (!t) return NULL;
    switch (t->grp()) {
        case BASE_G : return t;
        case  PTR_G : if (((Ptr *)t)->pt) return tail(((Ptr *)t)->pt); else return t;
        case  ARR_G : if (((Arr *)t)->item) return tail(((Arr *)t)->item); else return t;
        case FUNC_G : if (((Func *)t)->retType) return tail(((Func *)t)->retType); else return t;
    }
    return t;
}

class Type *last(class Type *t, grp_t g) { // get last instance of grp type 'g' for linked list 't'. Return NULL is doesn't exist.
    if (!t) return NULL;
    Type *found = NULL;
    while (t) {
        grp_t cg = t->grp();
        if (cg == g) found = t;
        switch (cg) { // now get next of t
            case NONE_G : case BASE_G : t = NULL; break;
            case  PTR_G : t = ((Ptr *) t)->pt; break;
            case  ARR_G : t = ((Arr *) t)->item; break;
            case FUNC_G : t = ((Func *) t)->retType; break;
        }
    }
    return found;
}

void heir(class Type* t) {
    bool isErr = false;
    while (t) {
        isErr |= t->isErr;
        switch (t->grp()) {
            case NONE_G : cout << "NONE_G"; t = NULL; break;
            case BASE_G : cout << "BASE_G"; t = NULL; break;
            case  PTR_G : cout <<  "PTR_G"; t = ((Ptr *) t)->pt; break;
            case  ARR_G : cout <<  "ARR_G"; t = ((Arr *) t)->item; break;
            case FUNC_G : cout << "FUNC_G"; t = ((Func *) t)->retType; break;
        }
        if (t) cout << " >> ";
    }
    if (isErr) cout << _FORE_RED_ << " [ERROR]" << _C_NONE_;
    cout << endl;
}

class Type *unify(class Type *t1, class Type *t2) { // decl_specs with declarator
    if (!(t1 || t2)) return NULL;
    if (!t2) return t1; // simple case (int x;)
    if (!t1) return NULL;
    Type *tt = tail(t2);
    switch (tt->grp()) {
        case  PTR_G : ((Ptr *)tt)->pt = clone(t1); break;
        case  ARR_G : ((Arr *)tt)->item = clone(t1); break;
        case FUNC_G : ((Func*)tt)->retType = clone(t1); break;
    }
    t2->isErr |= t1->isErr; t2->strg = t1->strg;
    return t2;
}

bool extMatch(class Type *prev, class Type *curr) { // match under "extern"
    if (!prev || !curr) return false;
    prev = clone(prev); curr = clone(curr);
    prev->strg = NONE_S; curr->strg = NONE_S;
    return tMatch(prev, curr);
}

bool tMatch(class Type *prev, class Type *curr) {
    if (!prev || !curr) return false;
    if (prev->isErr || curr->isErr) return false;

    while (prev || curr) {
        if (!prev || !curr) return false;
        if (prev->isErr || curr->isErr) return false;
        grp_t g = prev->grp();
        if (g != curr->grp()) return false;
        Base *b1, *b2; Ptr *p1, *p2; Arr *a1, *a2; Func *f1, *f2; int l1, l2;
        switch (g) {
            case NONE_G : prev = curr = NULL; break;
            
            case BASE_G : b1 = (Base *)prev; b2 = (Base *)curr;
                if ( (b1->base != b2->base) || (b1->sign != b2->sign) || (b1->strg != b2->strg)
                || (b1->isConst != b2->isConst) || (b1->isVoltl != b2->isVoltl)) return false;
                prev = curr = NULL; break;
            
            case  PTR_G : p1 = (Ptr *)prev; p2 = (Ptr *)curr;
                l1 = p1->ptrs.size(); l2 = p2->ptrs.size();
                if (l1 != l2) return false;
                for (int i = 0; i < l1; i++) {
                    qual_t q1 = p1->ptrs[i], q2 = p2->ptrs[i];
                    if ((q1.isConst != q2.isConst) || (q1.isVoltl != q2.isVoltl)) return false;
                }
                prev = p1->pt; curr = p2->pt; break;

            case  ARR_G : a1 = (Arr *)prev; a2 = (Arr *)curr;
                l1 = a1->dims.size(); l2 = a2->dims.size();
                if (l1 != l2) return false;
                // check that array bounds must be equal - later
                prev = ((Arr *)prev)->item; curr = ((Arr *)curr)->item; break;

            case FUNC_G : f1 = (Func*)prev; f2 = (Func*)curr;
                l1 = f1->params.size(); l2 = f2->params.size();
                if (l1 != l2) return false;
                for (int i = 0; i < l1; i++) if (!tMatch(f1->params[i], f2->params[i])) return false;
                prev = f1->retType; curr = f2->retType; break;
        }
    }
    return true;
}

bool checkArrDims(class Type *t) { // recursively check that all array bounds must be present
    if (!t) return true;
    Arr *a;
    switch (t->grp()) {
        case NONE_G : case BASE_G : return true;
        case PTR_G : t = ((Ptr *)t)->pt; break;
        case FUNC_G : t = ((Func *)t)->retType; break;
        case ARR_G : a = (Arr *)t;
            if (a->dims[0] == NULL) return false;
        
            t = a->item; break;
    }
    return true;
}

bool impCast(class Type *from, class Type *to) { // implicit type-casting
    if (!from || !to) return false;
    grp_t gf = from->grp(), gt = to->grp();
    Base *bf = (Base *)from, *bt = (Base *)to;
    Ptr *pf = (Ptr *)from, *pt = (Ptr *)to;
    Arr *af = (Arr *)from, *at = (Arr *)to;
    Func *ff = (Func *)from, *ft = (Func *)to;
    
    if (gf == BASE_G && gt == BASE_G) {
        // conversion TO a void, struct or union is not allowed
        return !(bt->base == VOID_B || bt->base == STRUCT_B || bt->base == UNION_B);
    }



    if (gt == PTR_G && (pt->pt->grp() == BASE_G) && (((Base *)(pt->pt))->base == VOID_B)) {
        if (gf == PTR_G || gf == ARR_G || gf == FUNC_G) return true; // any pointer/array/function is convertible to void *
    }

    // arr/func -> ptr
    // but not opposite
    if (gf == PTR_G && (gt == ARR_G || gt == FUNC_G)) return false;


    return true;
}

bool expCast(class Type *from, class Type *to) { // explicit type-casting (may differ from implicit version)
    if (!from || !to) return false;
    grp_t gf = from->grp(), gt = to->grp();
    Base *bf = (Base *)from, *bt = (Base *)to;
    Ptr *pf = (Ptr *)from, *pt = (Ptr *)to;
    Arr *af = (Arr *)from, *at = (Arr *)to;
    Func *ff = (Func *)from, *ft = (Func *)to;
    
    if (gf == BASE_G && gt == BASE_G) {
        // conversion TO a void, struct or union is not allowed
        return !(bt->base == VOID_B || bt->base == STRUCT_B || bt->base == UNION_B);
    }



    if (gt == PTR_G && (pt->pt->grp() == BASE_G) && (((Base *)(pt->pt))->base == VOID_B)) {
        if (gf == PTR_G || gf == ARR_G || gf == FUNC_G) return true; // any pointer/array/function is convertible to void *
    }

    // arr/func -> ptr
    // but not opposite
    if (gf == PTR_G && (gt == ARR_G || gt == FUNC_G)) return false;


    return true;
}



/************************************************/
/****************** TEST SUITE ******************/
/************************************************/

#ifdef TEST_TYPES_2

#define MAX_TESTNAME_WIDTH 12

void testOut(string testName, string testResult) {
    cout << _C_BOLD_ << _FORE_GREEN_ << setw(MAX_TESTNAME_WIDTH) << testName << " :";
    cout << _C_NONE_ << " \"" << testResult << "\"" << endl;
}

void testBase() { // const unsigned int volatile static;
    Base* b = new Base();
    b->base = INT_B; b->sign = UNSIGNED_X; b->strg = STATIC_S; b->isConst = true; b->isVoltl = true;
    
    Type* t = b;
    if (t->grp() == BASE_G) testOut("base class", str(t));
    testOut("clone_base", str(clone(t)));
}

void testPtr() { // const int ** const *volatile;
    Base *b = new Base(INT_B); b->isConst = true;
    Ptr* p = new Ptr(b); p->newPtr(true, false); p->newPtr(false, true);

    Type* t = p;
    if (t->grp() == PTR_G) testOut("ptr class", str(t));
    testOut("clone_ptr", str(clone(t)));
}

void testArr() { // const double [][][];
    Base *b = new Base(DOUBLE_B); b->isConst = true;
    Arr *a = new Arr(b); a->newDim(NULL); a->newDim();

    Type *t = a;
    if (t->grp() == ARR_G) testOut("arr class", str(t));
    testOut("clone_arr", str(clone(t)));
}

void testFunc() { // void ()(unsigned char, ...);
    Base *b = new Base(VOID_B);
    Base *b1 = new Base(CHAR_B); b1->sign = UNSIGNED_X;
    Base *b2 = new Base(ELLIPSIS_B);
    Func *f = new Func(b); f->newParam(b1); f->newParam(b2);
    
    Type *t = f;
    if (t->grp() == FUNC_G) testOut("func class", str(t));
    testOut("clone_func", str(clone(t)));
}

void testComplex_1() { // int *const (* volatile f)(); // surprisingly, a "const" (pointer or value) can be returned.
    Base *b = new Base(INT_B);
    Ptr *pb = new Ptr(b, true, false);
    Func *f = new Func(pb);
    Ptr *p = new Ptr(f, false, true);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_1", str(t));
    testOut("clone_1", str(clone(t)));
}

void testComplex_2() { // float (*f)[4][5][6];
    Base *b = new Base(FLOAT_B);
    Arr *a = new Arr(b, NULL); a->newDim(); a->newDim(NULL);
    Ptr *p = new Ptr(a);

    Type *t = p;
    if (t->grp() == PTR_G) testOut("complex_2", str(t));
    testOut("clone_2", str(clone(t)));
}

void testComplex_3() { // int *** (*(*)(char))[]
    Base *b = new Base(INT_B); // int
    Ptr *p = new Ptr(b); p->newPtr(); p->newPtr(); // int ***
    Arr *a = new Arr(p); // int*** []
    Ptr *pa = new Ptr(a); // int *** (*) []
    Func *f = new Func(pa); f->newParam(new Base(CHAR_B)); // int *** (*()(char))[]
    Ptr *pf = new Ptr(f); // int *** (*(*)(char))[]

    Type *t = pf;
    if (t->grp() == PTR_G) testOut("complex_3", str(t));
    testOut("clone_3", str(clone(t)));
    heir(t);
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
    if (t->grp() == ARR_G) testOut("complex_4", str(t));
    testOut("clone_4", str(clone(t)));
}

void testComplex_5() { // int *** (*(*)(char))()
    Base *b = new Base(INT_B); // int
    Ptr *p = new Ptr(b); p->newPtr(); p->newPtr(); // int ***
    Func *f = new Func(p); // int*** ()()
    Ptr *pf = new Ptr(f); // int *** (*) ()
    Func *ff = new Func(pf); ff->newParam(new Base(CHAR_B)); // int *** (*()(char)) ()
    Ptr *pff = new Ptr(ff); // int *** (*(*)(char))()

    Type *t = pff;
    if (t->grp() == PTR_G) testOut("complex_5", str(t));
    testOut("clone_5", str(clone(t)));
}

int main(){
	testBase();
	testPtr();
	testArr();
	testFunc();

    testComplex_1();
    testComplex_2();
    testComplex_3();
    testComplex_4();
    testComplex_5();

	return 0;	
}

#endif
