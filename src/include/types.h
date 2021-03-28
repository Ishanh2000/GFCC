#ifndef __GFCC_TYPES__
#define __GFCC_TYPES__
#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>

// List types
enum type_t {CHAR, INT, LONG, DOUBLE, LONG_LONG, LONG_DOUBLE, SHORT, FLOAT, VOID, ERROR, ARRAY, POINTER, FUNCTION, STRUCT, ENUM, UNION};

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

class type_struct: public type_expr {
  public:
    std::vector<type_expr> members;
		std::string name;
    type_struct(const std::string &, const std::vector<type_expr>&);
    bool operator==(const type_struct &) const;
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
