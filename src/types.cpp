
// AUM SHREEGANESHAAYA NAMAH||

/************************ NOTE TO THE DEVELOPER ************************
 * SEE <proj_root>/src/include/types.h for description of various classes,
   members, methods, etc.
 * Search "TODO" for things to do.
 * Search "ASSUMPTIONS" for assumptions.
 * Execution using: g++ -std=c++11 [-DTEST_TYPES] types.cpp -Iinclude && ./a.out
************************************************************************/

#include <iostream>
#include <string>
#include <types.h>

#ifdef DEBUG_TYPES
const bool dbg = true;
#else
const bool dbg = false;
#endif

using namespace std;

bool expectSub = false;

_qual_t::_qual_t () { }

_qual_t::_qual_t (bool _c, bool _v) { isConst = _c; isVolatile = _v; }

/****************************************************/
/****************** class "arrBnd" ******************/
/****************************************************/

arrBnd::arrBnd() { } // do nothing = abstract declaration

arrBnd::arrBnd(node_t* _evalNode) : evalNode(_evalNode) { } // normal declaration

unsigned int arrBnd::eval() { // TODO: evaluate the bound
	return 1;
}

bool arrBnd::exists() {
	return (evalNode != NULL);
}

/**************************************************/
/****************** class "Type" ******************/
/**************************************************/

string Type::str() {
	return "Will convert to string later"; // TODO
}

bool Type::isArr() {
	return (arrBnds.size() > 0);
}

bool Type::isPtr() {
	return (ptrs.size() > 0);
}

bool Type::isFunc() {
	return (funcParams.size() > 0);
}

bool Type::newArrBnd(node_t* _evalNode) {
	arrBnd* ab = new arrBnd(_evalNode);
	if (!ab) return false;
	arrBnds.push_back(ab);
	return true;
}

bool Type::newArrBnd() {
	return newArrBnd(NULL);
}

void Type::newFuncParam(Type* t) {
	funcParams.push_back(t);
}

/*******************************************************/
/****************** class "type_expr" ******************/
/*******************************************************/

type_expr::type_expr() {}

bool type_expr::operator==(const type_expr & rtype) const{
	if(this->type != rtype.type) return false;

	if(rtype.basic_type) {
		return true;
	}
	// not basic type
	switch(this->type) {
		case POINTER_T: {
			return static_cast<const type_pointer*>(this) == \
						 static_cast<const type_pointer*>(&rtype);
			}
		case FUNCTION_T: {
			return static_cast<const type_function*>(this) == \
						 static_cast<const type_function*>(&rtype);
		}
		case ARRAY_T: {
			return static_cast<const type_array*>(this) == \
						 static_cast<const type_array*>(&rtype);
		}
		case STRUCT_T: {
			return static_cast<const type_struct*>(this) == \
						 static_cast<const type_struct*>(&rtype);
		}
		case ENUM_T: {
			return static_cast<const type_enum*>(this) == \
						 static_cast<const type_enum*>(&rtype);
		}
		case UNION_T: {
			return static_cast<const type_union*>(this) == \
						 static_cast<const type_union*>(&rtype);
		}
		// // default: {} TODO: throw error
	}
	return false;
}

type_expr type_expr::operator+(const type_expr & rtype) const {
	
	if(rtype.type == ERROR_T ||
		 this->type == ERROR_T)
	{
		// NOTE: add metadata in error if required
		return type_error();
	}

	// for basic types
	if(rtype.basic_type && this->basic_type && *this == rtype)
	{
		return *this;
	}
	// TODO: for pointers
	// TODO implicit typecasting - make cases

	// default
	return type_error();
}

type_expr type_expr::operator-(const type_expr & rtype) const {
	// ASSUMPTION: asssumed similar behaviour for now
	return *this + rtype;
}

type_expr type_expr::operator*(const type_expr & rtype) const {
	// ASSUMPTION: asssumed similar behaviour for now
	return *this + rtype;
}

type_expr type_expr::operator/(const type_expr & rtype) const {
	// ASSUMPTION: asssumed similar behaviour for now
	return *this + rtype;
}


type_void::type_void() {
	type = VOID_T;
	basic_type = true;
}

type_char::type_char() {
	type = CHAR_T;
	basic_type = true;
}	

type_int::type_int() {
	type = INT_T;
	basic_type = true;
}

type_long::type_long() {
	type = LONG_T;
	basic_type = true;
}

type_double::type_double() {
	type = DOUBLE_T;
	basic_type = true;
}

type_long_double::type_long_double() {
	type = LONG_DOUBLE_T;
	basic_type = true;
}

type_long_long::type_long_long() {
	type = LONG_LONG_T;
	basic_type = true;
}

type_short::type_short() {
	type = SHORT_T;
	basic_type = true;
}

type_float::type_float() {
	type = FLOAT_T;
	basic_type = true;
}

type_pointer::type_pointer(type_expr _type) {
	basic_type = false;
	type = POINTER_T;
	pointer_type = _type;
}

bool type_pointer::operator==(const type_pointer & rtype) const {
	return this->pointer_type == rtype.pointer_type;
}

type_function::type_function(const std::vector<type_expr>& _params,const type_expr _return_type)
{
	basic_type = false;
	type = FUNCTION_T;
	params = _params;
	return_type = _return_type;
}

bool type_function::operator==(const type_function & rtype) const {
	// can use == between vector<T> if T is EqualityComparable
	if(this->params == rtype.params &&
		 this->return_type == rtype.return_type)
	{
		return true;
	}
	return false;
}

// TODO: type_enum

type_struct::type_struct(const std::string & _name, const std::vector<type_expr>& _members) {
	basic_type = false;
	type = STRUCT_T;
	name = _name;
	members = _members;
}

bool type_struct::operator==(const type_struct& rtype) const {
	return (this->name == rtype.name && this->members == rtype.members);
}

type_union::type_union(const std::string & _name, const std::vector<type_expr>& _members) {
	basic_type = false;
	type = UNION_T;
	name = _name;
	members = _members;
}

bool type_union::operator==(const type_union& rtype) const {
	return (this->name == rtype.name && this->members == rtype.members);
}

type_array::type_array(type_expr _type, int _num_dim, std::vector<int> _dim_sizes){
	basic_type = false;
	type = ARRAY_T;
	base_type = _type;
	num_dim = _num_dim;
	dim_sizes = _dim_sizes;

}

bool type_array::operator==(const type_array & rtype) const{
  return this->base_type == rtype.base_type;
}	


type_error::type_error(){
			type = ERROR_T;
			basic_type = false;
}

# ifdef TEST_TYPES
void sanity_checks() {
	type_expr b_int = type_int();
	type_expr b_float = type_float();
	type_expr p_int = type_pointer(b_int);
	type_expr p_float = type_pointer(b_float);
	using namespace std;

	cout<< "b_int: "<< (b_int == b_int)<<"\texpected: "<<1<<endl;
	cout<< "b_float: "<< (b_float == b_float)<<"\texpected: "<<1<<endl;
	cout<< "p_in:t "<< (p_int == p_int) <<"\texpected: "<<1<<endl;
	cout<< "b_int vs b_float: "<< (b_int == b_float) 
		<< " "<< (b_float==b_int)<<"\texpected: "<<"0 0"<<endl;
	cout<< "b_int vs p_int: "<< (b_int == p_int) 
		<< " "<< (p_int==b_int)<<"\texpected: "<<"0 0"<<endl;
	cout<< "b_int vs p_float: "<< (b_int == p_float) 
		<< " "<< (p_float==b_int)<<"\texpected: "<<"0 0"<<endl;

	cout<< "b_float vs p_int: "<< (b_float == p_int) 
		<< " "<< (p_int==b_float)<<"\texpected: "<<"0 0"<<endl;
	cout<< "b_float vs p_float: "<< (b_float == p_float) 
		<< " "<< (p_float==b_float)<<"\texpected: "<<"0 0"<<endl;

	cout<< "p_int vs p_float: "<< (p_int == p_float) 
		<< " "<< (p_float==p_int)<<"\texpected: "<<"0 0"<<endl;

	const type_expr p_p_int = type_pointer(p_int);
	const type_expr p_p_float = type_pointer(p_float);
	type_expr p_p_p_float = type_pointer(p_float);

	cout<< "p_p_int: "<< (p_p_int == p_p_int)<<"\texpected: "<<1<<endl;
	cout<< "p_p_float: "<< (p_p_float == p_p_float)<<"\texpected: "<<1<<endl;
	cout<< "p_p_p_float: "<< (p_p_p_float == p_p_p_float)<<"\texpected: "<<1<<endl;
	
	cout<< "p_p_float vs p_p_int: "<< (p_p_float == p_p_int) 
		<< " "<< (p_p_int==p_p_float)<<"\texpected: "<<"0 0"<<endl;
	cout<< "p_p_float vs p_p_p_float: "<< (p_p_float == p_p_p_float) 
		<< " "<< (p_p_p_float==p_p_float)<<"\texpected: "<<"0 0"<<endl;
	cout<< "p_p_int vs p_p_p_float: "<< (p_p_int == p_p_p_float) 
		<< " "<< (p_p_p_float==p_p_int)<<"\texpected: "<<"0 0"<<endl;

	type_expr f_int_to_p_int = type_function({b_float}, p_int);
	type_expr f_err_float_to_p_p_int = type_function({type_error(), b_float},p_p_int);
	cout<< "f_int_to_p_int: "<< (f_int_to_p_int == f_int_to_p_int)<<"\texpected: "<<1<<endl;
	cout<< "f_err_float_to_p_p_int: "<< (f_err_float_to_p_p_int == f_err_float_to_p_p_int)<<"\texpected: "<<1<<endl;

	cout<< "p_p_float vs f_err_float_to_p_p_int: "<< (p_p_float == f_err_float_to_p_p_int) 
		<< " "<< (f_err_float_to_p_p_int==p_p_float)<<"\texpected: "<<"0 0"<<endl;
	cout<< "p_p_float vs p_p_p_float: "<< (p_p_float == p_p_p_float) 
		<< " "<< (p_p_p_float==p_p_float)<<"\texpected: "<<"0 0"<<endl;
	cout<< "f_err_float_to_p_p_int vs f_int_to_p_int: "<< (f_err_float_to_p_p_int == f_int_to_p_int) 
		<< " "<< (f_int_to_p_int==f_err_float_to_p_p_int)<<"\texpected: "<<"0 0"<<endl;
}
void complex_tests() {
	type_expr b_int = type_int(),
	b_float = type_float(),
	p_int = type_pointer(type_int());
	using namespace std;
	// ! current  expected behaviours
	cout<< (b_int + b_int).type << "\n" // 0 (INT)
	<< (b_int * b_int).type << "\n"     // 0
	<< (b_float + b_float).type << "\n"		// 1 (FLOAT)
	<< (b_int + p_int).type << "\n"			// 3 (ERROR)
	<< (p_int + p_int).type << "\n";		// 3
}
int main(){
	// sanity_checks();
	complex_tests();
	return 0;	
}

#endif
