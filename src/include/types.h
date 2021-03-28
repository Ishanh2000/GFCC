#ifndef __GFCC_TYPES__
#define __GFCC_TYPES__
#include <iostream>
#include <string>
#include <vector>
// List types
enum type_t {CHAR, INT, FLOAT, VOID, ERROR, ARRAY, POINTER, FUNCTION};

// Base class --> this is exclusively what we will use
class type_expr {
  public:
		type_t type;
		bool basic_type;
		bool is_const;
		type_expr();
    bool operator==(const type_expr &) const;
    type_expr operator +(const type_expr &) const;
    type_expr operator *(const type_expr &) const;
    type_expr operator /(const type_expr &) const;
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


class type_array: public type_expr {
	public:
		type_expr base_type;
		int num;
		//TODO: This is just for a[10]. Not for b[10][10] etc..
		// Can use num for checking out of bound array accesses. Or give warnings
		type_array(const type_expr base_type, int n);
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
