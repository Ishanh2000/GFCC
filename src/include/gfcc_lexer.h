// AUM SHREEGANESHAAYA NAMAH|| // DIETY INVOCATION
#include <gfcc_meta.h>

#ifndef __GFCC_LEXER__
#define __GFCC_LEXER__

// TAB LENGTH
#define TAB_LEN 8

// ERROR CODES
#define E_TOO_FEW_ARGS (-1)
#define E_INV_OPTION (-2)
#define E_O_FLAG_TWICE (-3)
#define E_NUM_IO_UNEQUAL (-4)
#define E_NO_FILES (-5)


void count(); // count characters for every token encountered

void comment(); // [DO NOT CHANGE NAME] for multi-line comment (MLC)

int check_type();

int isEqual(char*, char*, char*); // check if first is equal to second ot third

#endif
