
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
#include <cstdio>

#ifdef DEBUG_SYM
const bool dbg = true;
#else
const bool dbg = false;
#endif


type_expr::type_expr() {}

bool type_expr::operator==(const type_expr & rtype) const{
	if(dbg) printf("abstract comparision called\n");
	if(dbg) printf("types == %d and %d\n", this->type, rtype.type);
	if(this->type != rtype.type) return false;
	if(rtype.basic_type) {
		return true;
	}
	switch(this->type) {
		case POINTER: {
			return static_cast<const type_pointer*>(this) == \
						 static_cast<const type_pointer*>(&rtype);
			}
		case FUNCTION: {
			return static_cast<const type_function*>(this) == \
						 static_cast<const type_function*>(&rtype);
		}
	}
}

type_expr type_expr::operator+(const type_expr & rtype) const {
	
	if(rtype.type == ERROR ||
		 this->type == ERROR)
	{
		// NOTE: add metadata in error if required
		return type_error();
	}

	// for basic types
	if(rtype.basic_type &&
		 this->basic_type &&
		 *this == rtype)
	{
		return *this;
	}
	// TODO: for pointers
	// TODO implicit typecasting - make cases

	// default
	return type_error();
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
	type = VOID;
	basic_type = true;
}

type_int::type_int() {
	type = INT;
	basic_type = true;
}

type_float::type_float() {
	type = FLOAT;
	basic_type = true;
}


type_pointer::type_pointer(type_expr _type) {
	basic_type = false;
	type = POINTER;
	pointer_type = _type;
	if(dbg) printf("pointer_type- %d\n", _type.type);
}

bool type_pointer::operator==(const type_pointer & rtype) const {
	if(dbg) printf("Pointer 2 Pointer comparision called\n");
	printf("pointer_type: %d -- %d\n", this->pointer_type.type, rtype.pointer_type.type);
	return this->pointer_type == rtype.pointer_type;
}

type_function::type_function(const std::vector<type_expr>& _params,
														 const type_expr _return_type)
{
	basic_type = false;
	type = FUNCTION;
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

type_error::type_error(){
			type = ERROR;
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
	cout<< "p_in:t "<< (p_int == p_int)<<"\texpected: "<<1<<endl;
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
