// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
/***********************************************************************/
/************************ NOTE TO THE DEVELOPER ************************/
/***********************************************************************
 * This file is for stuff related to typography on the terminal. This
 * usually includes printing formatted errors, outputs, warnings, etc.
***********************************************************************/

#include <iostream>
#include <typo.h>

using namespace std;

#ifdef TEST_TYPO

int main() {
    msg() << "This " << "is " << "a " << "normal prompt!";
    msg(SUCC) << "This " << "is " << "a " << "success!";
    msg(WARN) << "This " << "is " << "a " << "warning!";
    msg(ERR) << "This " << "is " << "an " << "error!";
    string x = "string";
    const char y[] = "const char []";
    char z[] = "char []";
    msg(SUCC) << x << " OK";
    msg(SUCC) << y << " OK";
    msg(SUCC) << z << " OK";

    return 0;
}

#endif
