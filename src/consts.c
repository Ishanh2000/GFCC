#include <gfcc_lexer.h>

char* TOKEN_NAME_ARRAY[] = {
	"IDENTIFIER", "CONSTANT", "STRING_LITERAL", "SIZEOF", "FILE_OBJ", "PTR_OP", "INC_OP", "DEC_OP", "LEFT_OP", "RIGHT_OP",
	"LE_OP", "GE_OP", "EQ_OP", "NE_OP", "AND_OP", "OR_OP", "MUL_ASSIGN", "DIV_ASSIGN", "MOD_ASSIGN", "ADD_ASSIGN",
	"SUB_ASSIGN", "LEFT_ASSIGN", "RIGHT_ASSIGN", "AND_ASSIGN", "XOR_ASSIGN", "OR_ASSIGN", "TYPE_NAME", "TYPEDEF",
	"EXTERN", "STATIC", "AUTO", "REGISTER", "CHAR", "SHORT", "INT", "LONG", "SIGNED", "UNSIGNED", "FLOAT", "DOUBLE",
	"CONST", "VOLATILE", "VOID", "STRUCT", "UNION", "ENUM", "ELLIPSIS", "CASE", "DEFAULT", "IF", "ELSE", "SWITCH",
	"WHILE", "DO", "FOR", "GOTO", "CONTINUE", "BREAK", "RETURN",
};

char lexer_help[] = "\
Usage: <exec-name> [options] files... [--output|-o] output-files...\n\
\n\
Options:\n\
  --help	-h : Help. Must be first option. Other options are not checked.\n\
\n\
  --version	-v : Version and release date. Maybe author names/licenses. Must be first option. Other options not checked.\n\
\n\
  --output	-o : Names of output files in the same order as inputs are specified.\n\
\n\
Notes:\n\
  1) Specify an option only once. Otherwise they may be treated invalid.\n\
  2) Specify output files AFTER input files.\n\
  3) The number of output files must be EQUAL to the number of input files.\n\
  4) If erreneous options (and their values) are given, desired output may not be achieved.\n\
  5) All files won't be jeopardized due failure in opening a few files.\n\
  6) Bad (invalid) characters are reported, but lexical analysis is still carried on.\n\
  7) Pre-processor directives / macros treated as comments (basically everything beginning with #)\n\
";

