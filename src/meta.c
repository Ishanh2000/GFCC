#include <stdio.h>
#include <gfcc_meta.h>

void gfcc_lexer_version() {
	printf("GFCC Lexer Version: v%s (%s)\n", GFCC_LEXER_VERSION, VERSION_DATE);
}

void gfcc_lexer_help() {
	printf("%s", lexer_help);
}
