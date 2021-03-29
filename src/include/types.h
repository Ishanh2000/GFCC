#ifndef __GFCC_TYPES__
#define __GFCC_TYPES__
#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>

#include <gfcc_lexer.h>

// List types
enum type_t {
	CHAR_T, INT_T, LONG_T, DOUBLE_T, LONG_LONG_T, LONG_DOUBLE_T, SHORT_T, FLOAT_T,
	VOID_T, ERROR_T, ARRAY_T, POINTER_T, FUNCTION_T, STRUCT_T, ENUM_T, UNION_T
};

// basic types (increasing size)
enum base_type_t {
	NONE_B, ERROR_B, // primitive useless types
	VOID_B, CHAR_B, SHORT_B, INT_B, FLOAT_B, LONG_B, LONG_LONG_B, DOUBLE_B, LONG_DOUBLE_B, // primitive useful types
	ENUM_B, STRUCT_B, UNION_B, // compound types // TODO: think about ENUM_B, UNION_B, STRUCT_B
};
	

enum sign_t { NONE_X, SIGNED_X, UNSIGNED_X };

// Tolerance to other types specifiers
// VOID_B : NONE,
// CHAR_B : NONE
// SHORT_B: INT -> SHORT
// INT_B: SHORT -> SHORT, LONG -> LONG, LONG_LONG -> LONG_LONG
// FLOAT_B : NONE
// LONG_B : INT -> LONG, LONG -> LONG_LONG, DOUBLE -> LONG_DOUBLE
// LONG_LONG_B: INT -> LONG_LONG
// DOUBLE_B : LONG -> LONG_DOUBLE
// LONG_DOUBLE_B: NONE



// storage class specifiers
enum strg_t { NONE_S, AUTO_S, EXTERN_S, REGISTER_S, STATIC_S, TYPEDEF_S };

typedef struct _qual_t { // type for "type qualifiers" - not humongous (2 bytes only)
	bool isConst = false; // default: variables NOT constant
	bool isVolatile = false; // default: variables NOT volatile
	_qual_t();
	_qual_t(bool, bool);
} qual_t;

class arrBnd {
	struct _node_t* evalNode = NULL; // NULL iff abstract declaration

	public:
		arrBnd(); // abstract declaration
		arrBnd(struct _node_t*); // normal declaration
		unsigned int eval(); // evaluate the bound
		bool exists(); // false iff abstract
};

class Type { public :
	base_type_t base = NONE_B; // default: set to INT_T upon checking "declaration"
	sign_t sign = NONE_X; // default: set to SIGNED_S upon checking "declaration". To be ignored if incompatible type
	qual_t qual; // defualt: !constant, !volatile
	strg_t strg = NONE_S; // default: set to AUTO_S upon checking "declaration";

	// manage "pointers" (const | volatile) - same order as given in input file
	std::vector<qual_t> ptrs; // Could use separate arrays for "const" and "volatile" too.

	void* enumDef; // will decide type later
	void* unionDef; // will decide type later
	void* structDef; // will decide type later

	std::vector<arrBnd*> arrBnds; // array bounds
	
	// function / function pointer
	bool isFunc = false;
	std::vector<Type*> funcParams; // size() > 0 iff [type related to a function and non-void arguments]
	
	std::string str(); // converts class info (type info) to a string - errors/warnings, etc.
	bool isArr(); // tells if type is an array.

	// insert new array bound
	bool newArrBnd(); // abst decl
	bool newArrBnd(struct _node_t*); // normal decl

	// TODO: make a copy constructor - to be used in expression evaluation (starting from "primary_expression")
};

// will work on this later
// class Constant : public Type { public : // (const) int / long / double / long double
	
	// char bits[64]; // bit map structure of incoming constants - later, if time permits
	// int int_val;
	// long long_val;
	// double db_val;
	// long double ldb_val;

	// Constant(); // int = 0 - DO NOT USE!!!
	// Constant(int);

// }

// Base class --> this is exclusively what we will use
class type_expr {
  public:
		type_t type;
		bool basic_type;
		bool is_const;
		type_expr();
    bool operator==(const type_expr &) const;
    type_expr operator+(const type_expr &) const;
		type_expr operator-(const type_expr &) const;
    type_expr operator*(const type_expr &) const;
    type_expr operator/(const type_expr &) const;
};

class type_void: public type_expr {
	public:
		type_void();
};

class type_char: public type_expr{
	public:
		type_char();

};

class type_int: public type_expr {
	public:
		type_int();
};

class type_long: public type_expr {
	public:
		type_long();
};

class type_double: public type_expr {
	public:
		type_double();
};


class type_long_long: public type_expr {
	public:
		type_long_long();
};


class type_long_double: public type_expr {
	public:
		type_long_double();
};



class type_short: public type_expr {
	public:
		type_short();
};

class type_float: public type_expr {
	public:
		type_float();
};

class type_pointer: public type_expr {
	public:
		type_expr pointer_type;
		type_pointer(type_expr _type);
    // compare 2 "pointers"
		bool operator==(const type_pointer &) const;
};

class type_function: public type_expr {
  public:
    std::vector<type_expr> params;
    type_expr return_type;
    type_function(const std::vector<type_expr>& _params, const type_expr _return_type);
    bool operator==(const type_function &) const;
};


class type_struct: public type_expr {
  public:
    std::vector<type_expr> members;
		std::string name;
    type_struct(const std::string &, const std::vector<type_expr>&);
    bool operator==(const type_struct &) const;
};

class type_enum: public type_expr {
  public:
		// TODO:
    // std::unordered_map <std::string, int> members;
		// std::vector<int> int2mem;
		// std::vector<std::string> mem2int;
    type_enum(const std::string &);
    bool operator==(const type_enum &) const;
};

class type_union: public type_expr {
  public:
    std::vector<type_expr> members;
		std::string name;
    type_union(const std::string &, const std::vector<type_expr>&);
    bool operator==(const type_union &) const;
};

class type_array: public type_expr {
	public:
		type_expr base_type;
		int num_dim;
		std::vector<int> dim_sizes;
		//TODO: This is just for a[10]. Not for b[10][10] etc..
		// Can use num for checking out of bound array accesses. Or give warnings
		type_array(const type_expr base_type, int n, std::vector<int> dim_sizes);
		bool operator==(const type_array &) const;
};

/** 
 * TODO: typerror should contain error details(string?),
 * [underlying types?], etc.
**/
class type_error: public type_expr {
	public:
		type_error();
};
#endif
