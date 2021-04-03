// AUM SHREEGANESHAAYA NAMAH||
#ifndef __GFCC_TYPES__
#define __GFCC_TYPES__

#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>

#include <gfcc_lexer.h>

// basic types (increasing size)
enum base_t {
	NONE_B,
	VOID_B, CHAR_B, SHORT_B, INT_B, FLOAT_B, LONG_B, LONG_LONG_B, DOUBLE_B, LONG_DOUBLE_B, // primitives
	ENUM_B, STRUCT_B, UNION_B, // compound types
	ELLIPSIS_B,
};

// sign types
enum sign_t { NONE_X, SIGNED_X, UNSIGNED_X };

// storage class specifiers
enum strg_t { NONE_S, AUTO_S, EXTERN_S, REGISTER_S, STATIC_S, TYPEDEF_S };

/* Tolerance to other types specifiers
 * VOID : NONE
 * CHAR : NONE
 * SHORT: INT -> SHORT
 * INT: SHORT -> SHORT, LONG -> LONG, LONG_LONG -> LONG_LONG
 * FLOAT : NONE
 * LONG : INT -> LONG, LONG -> LONG_LONG, DOUBLE -> LONG_DOUBLE
 * LONG_LONG: INT -> LONG_LONG
 * DOUBLE : LONG -> LONG_DOUBLE
 * LONG_DOUBLE: NONE
 */

// A type is made of 4 group: base, pointer, array, function
enum grp_t { NONE_G, BASE_G, PTR_G, ARR_G, FUNC_G };

typedef struct _qual_t { // type qualifiers
	bool isConst = false;
	bool isVoltl = false;
	_qual_t();
	_qual_t(bool, bool);
} qual_t;

class Type { public :
    bool isErr = false;
    strg_t strg = NONE_S;

    // late binding : use "virtual"
    virtual grp_t grp(); // NONE_G
    virtual std::string _str(); // convert type to string (for error reporting)
};

class Base : public Type { public :
    base_t base = NONE_B;
    sign_t sign = NONE_X;
    bool isConst = false;
    bool isVoltl = false;
    // void* enumDef; // deal later
	// void* unionDef; // deal later
	// void* structDef; // deal later

    Base ();
    Base (base_t);
    grp_t grp(); // BASE_G
    std::string _str();
};

class Ptr : public Type { public :
    std::vector<struct _qual_t> ptrs;
    class Type* pt = NULL; // pointee

    // constructors insert a pointer by default
    Ptr(class Type *);
    Ptr(class Type *, bool, bool);
    void newPtr();
    void newPtr(struct _qual_t);
    void newPtr(bool, bool);
    grp_t grp(); // PTR_G
    std::string _str();
};

class Arr : public Type { public : // int a[]
    std::vector<struct _node_t *> dims; // (bounds) NULL iff abstract declaration
    class Type* item = NULL;

    // constructors insert a dimension by default
    Arr(class Type *);
    Arr(class Type *, struct _node_t *);
    void newDim();
    void newDim(struct _node_t *);
    grp_t grp(); // ARR_G
    std::string _str();
    // unsigned int eval(int); // evaluate a bound
};

class Func : public Type { public :
    std::vector<class Type *> params; // [size() == 0] iff void
    class Type* retType = NULL;

    Func(class Type *);
    void newParam(class Type *);
    grp_t grp(); // FUNC_G
    std::string _str();
};

extern bool brackPut; // signifies whether brackets were put around a declarator earlier

std::string str(class Type *);

class Type *clone(class Type*);

#endif
