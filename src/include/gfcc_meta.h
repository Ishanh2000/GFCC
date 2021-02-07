#ifndef __LEXER_META__
#define __LEXER_META__

#define GFCC_LEXER_VERSION "0.0.1"
#define VERSION_DATE "February 8, 2021"

char lexer_help[] = "\
Usage: <exec-name> [--help|-h] [--version|-v] files... [--output|-o] output-files...\n\
\n\
Options:\n\
  --help      -h : Help.\n\
  --version   -v : Version and release date. Maybe author names/licenses.\n\
  --output    -o : Names of output files in the same order as inputs are specified.\n\
\n\
NOTES:\n\
  1) Specify output files AFTER input files.\n\
  2) The number of output files must be EQUAL to the number of input files.\n\
";

/*  --all       -a : All information (including token type, token number, lexeme address, etc.).\n */

void gfcc_lexer_help();

void gfcc_lexer_version();

#endif
