#include <gfcc_lexer.h>

const char* TOKEN_NAME_ARRAY[] = {
	"IDENTIFIER", "CONSTANT", "STRING_LITERAL", "SIZEOF", "FILE_OBJ", "PTR_OP", "INC_OP", "DEC_OP", "LEFT_OP", "RIGHT_OP",
	"LE_OP", "GE_OP", "EQ_OP", "NE_OP", "AND_OP", "OR_OP", "MUL_ASSIGN", "DIV_ASSIGN", "MOD_ASSIGN", "ADD_ASSIGN",
	"SUB_ASSIGN", "LEFT_ASSIGN", "RIGHT_ASSIGN", "AND_ASSIGN", "XOR_ASSIGN", "OR_ASSIGN", "TYPE_NAME", "TYPEDEF",
	"EXTERN", "STATIC", "AUTO", "REGISTER", "CHAR", "SHORT", "INT", "LONG", "SIGNED", "UNSIGNED", "FLOAT", "DOUBLE",
	"CONST", "VOLATILE", "VOID", "STRUCT", "UNION", "ENUM", "ELLIPSIS", "CASE", "DEFAULT", "IF", "ELSE", "SWITCH",
	"WHILE", "DO", "FOR", "GOTO", "CONTINUE", "BREAK", "RETURN",
};


#ifdef COMPLETE
const char type_spec_attr[] = "style=filled,fillcolor=yellow,shape=diamond";
const char strg_class_attr[] = "style=filled,fillcolor=yellow,shape=diamond";
const char type_qual_attr[] = "style=filled,fillcolor=yellow,shape=diamond";
#else
const char *type_spec_attr = NULL;
const char *strg_class_attr = NULL;
const char *type_qual_attr = NULL;
#endif

const char jump_attr[] = "style=filled,fillcolor=orange";
const char iter_attr[] = "style=filled,fillcolor=lightblue";
const char select_attr[] = "style=filled,fillcolor=yellow";
const char sizeof_attr[] = "style=filled,fillcolor=yellow";
const char empty_attr[] = "style=filled,fillcolor=gray"; // empty statment ';' / empty block '{}'
const char file_name_attr[] = "shape=box";
const char func_call_attr[] = "shape=box";
const char label_attr[] = "style=filled,fillcolor=magenta"; // labeled statemets like "abc : func();", "case 34 : func();", "default : func()".

char lexer_help[] = "\
\033[1;34mUSAGE:\033[0m <exec-name> [options] files... [--output|-o] output-files...\n\
\n\
\033[1;34mEXAMPLES:\033[0m\n\
  \033[32m./bin/gfcc\033[0m \033[33m-h\033[0m # help\n\
  \033[32m./bin/gfcc\033[0m \033[33m-v\033[0m # version\n\
\n\
  \033[90m# Creates {.tok.csv/.dot/.sym.csv/.3ac/.asm} files for all test case files\033[0m\n\
  \033[32m./bin/gfcc\033[0m ./tests/*.c\n\
\n\
  \033[90m# specify output files\033[0m\n\
  \033[32m./bin/gfcc\033[0m ./tests/*.c \033[33m-o\033[0m out_1.tok.csv out_1.dot out_1.sym.csv out_1.3ac out_1.asm ... out_N.tok.csv out_N.dot out_N.sym.csv out_N.3ac out_N.asm\n\
\n\
  \033[90m# change tab length\033[0m\n\
  \033[32m./bin/gfcc\033[0m \033[33m-t 6\033[0m ./tests/*.c \033[33m-o\033[0m out_1.tok.csv out_1.dot out_1.sym.csv out_1.3ac out_1.asm ... out_N.tok.csv out_N.dot out_N.sym.csv out_N.3ac out_N.asm\n\
\n\
  \033[90m# specify required output files only\033[0m\n\
  \033[32m./bin/gfcc\033[0m \033[33m-r=tok,asm,sym\033[0m ./tests/*.c \033[33m-o\033[0m out_1.tok.csv out_1.sym.csv out_1.asm ... out_N.tok.csv out_N.sym.csv out_N.asm\n\
\n\
  \033[90m# specify libraries\033[0m\n\
  \033[32m./bin/gfcc\033[0m \033[33m-l=typo,math,std,string\033[0m ./tests/*.c\n\
\n\
\033[1;34mOPTIONS:\033[0m\n\
  \033[32m-h|--help   \033[0m : Help. Must be first option. Other options are not checked.\n\
\n\
  \033[32m-v|--version\033[0m : Version and release date. Maybe author names/licenses. Must be first option. Other options not checked.\n\
\n\
  \033[32m-o|--output \033[0m : Names of output files in the same order as inputs are specified.\n\
\n\
  \033[32m-l|--lib    \033[0m : {math,typo,std,string} Comma separated libraries (must spceify on command line, not input file).\n\
                 \"typo\" and \"std\" are related to usual \"stdio.h\" and \"stdlib.h\" libraries respectively.\n\
\n\
  \033[32m-r|--require\033[0m : {tok,ast,sym,3ac,asm} Comma separated specifications for only required output files.\n\
  Output files, if specified must follow the precedence order {tok ast sym 3ac asm} for each input file.\n\
\n\
\033[1;34mNOTES:\033[0m\n\
  1) Try specifying an option only once. Otherwise they *may* be treated invalid.\n\
  2) Specify output files AFTER input files.\n\
  3) The number of output files must correctly correspond to the number of input files.\n\
  4) If erreneous options (and their values) are given, desired output may not be achieved.\n\
  5) All files won't be jeopardized due to failure in opening a few files.\n\
  6) \e[1;33m[IMPORTANT]\e[0m This compiler uses default tab length = 4. So, the location of errors and warnings *may* differ\n\
     from the location shown on your editor. Use [-t <tab_len>] option for changing the tab length.\n\
  7) \e[1;33m[IMPORTANT]\e[0m This compiler is not exhaustive. We have tried supporting almost all operations, but highly complex inputs\n\
     (or even incorrect programs sometimes) may result in segmentation fault, unexpected errors or garbage outputs.\n\
";
