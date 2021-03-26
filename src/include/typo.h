// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************/
/***********************************************************************
 * This file is for stuff related to typography on the terminal. This
 * usually includes printing formatted errors, outputs, warnings, etc.
***********************************************************************/

#include <iostream>
#include <sstream>
#include <gfcc_colors.h>

#ifndef __GFCC_TYPO__
#define __GFCC_TYPO__

#define SUCC 1
#define WARN 2
#define ERR 3

class msg : public std::stringstream {
	int gfcc_type = 0;
	public:
		msg() { }

		msg(int _type) : gfcc_type(_type) { }

		~msg() {
			switch (gfcc_type) {
				case SUCC: std::cout << _C_BOLD_ << _FORE_GREEN_ << this->str() << _C_NONE_ << std::endl; break; // can use prefix "SUCCESS: "
				case WARN: std::cout << _C_BOLD_ << _FORE_YELLOW_ << "WARNING: " << this->str() << _C_NONE_ << std::endl; break;
				case ERR : std::cout << _C_BOLD_ << _FORE_RED_ << "ERROR: " << this->str() << _C_NONE_ << std::endl; break;
				default  : std::cout << this->str() << std::endl;
			}
		}
};

#endif
