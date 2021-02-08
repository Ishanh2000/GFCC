#ifndef __LEXER_META__
#define __LEXER_META__

#define GFCC_LEXER_VERSION "0.0.1" // try using CMake for this stuff
#define VERSION_DATE "February 8, 2021"

char lexer_help[] = "\
Usage: <exec-name> [options] files... [--output|-o] output-files...\n\
\n\
Options:\n\
  --help	-h : Help. Must be first option. Other options are not checked.\n\
\n\
  --version	-v : Version and release date. Maybe author names/licenses. Must be first option. Other options not checked.\n\
\n\
  --brief	-b : Keep output brief. Default: disabled. Must specify before files.\n\
\n\
  --color	-c : Colorize output (does not work if writing to a file). Default: disabled. Must specify before files.\n\
\n\
  --output	-o : Names of output files in the same order as inputs are specified.\n\
\n\
  --tab-len <tab-len> | -t <tab-len> : Specify tab length. Default = 8. Must be a positive integer.\n\
\n\
Notes:\n\
  1) Specify an option only once. Otherwise they may be treated invalid.\n\
  2) Specify output files AFTER input files.\n\
  3) The number of output files must be EQUAL to the number of input files.\n\
  4) If erreneous options (and their values) are given, desired output may not be achieved.\n\
  5) All files won't be jeopardized due failure in opening a few files.\n\
";

void gfcc_lexer_help();

void gfcc_lexer_version();

#endif
