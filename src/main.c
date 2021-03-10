// AUM SHREEGANESHAAYA NAMAH|| // DIETY INVOCATION
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <parser.tab.h>
#include <gfcc_lexer.h>

// INITIALIZE ALL GLOBAL VARIABLES IN THIS FILE ONLY. DO NOT CHANGE
// THEIR NAMES. SINCE THEY ARE SHARE ACROSS MULTIPLE FILES.

int column = 1, token_column = 1, token_line = 1;
int colorize = 1; // [BOOLEAN ONLY] to colorize output (supported by modern terminals)
FILE *temp_out = NULL; // if this is NULL, use stdout
int tab_len = TAB_LEN;
int bad_char_seen = 0; // to notify parser
ull_t currNumNodes = 0; // invariant: currNumNodes > 0 for all existing nodes.
node_t *AstRoot = NULL;

int main (int argc , char *argv[]) {
	// ARGC TOO FEW
	if (argc < 2) {
		lex_err("Too few arguments. Use \"--help\" or \"-h\" for help.\n");
		return E_TOO_FEW_ARGS;
	}

	// HELP - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--help", "-h")) {	gfcc_lexer_help(); return 0; }


	// VERSION - DO NOT CHECK FURTHER OPTIONS
	if (isEqual(argv[1], "--version", "-v")) { gfcc_lexer_version(); return 0; }


	// maximum three more flags (-b, -c, -t) can be specified (apart from -o)
	// int brief = -1, t_flag = 0; // colorize is global param
	// for (int i = 0; i < 3; i++) {
	// 	int curr_pos = 1 + brief + colorize + (2 * t_flag);

	// 	brief |= isEqual(argv[curr_pos], "--brief", "-b");
	// 	colorize |= isEqual(argv[curr_pos], "--color", "-c");

	// 	if (isEqual(argv[curr_pos], "--tab-len", "-t")) {
	// 		t_flag = 1;
	// 		if ((2 + brief + colorize) >= argc) {
	// 			lex_err("Please specify desired tab length and also at least one input file. Use \"--help\" or \"-h\" for help.\n");
	// 			return E_TAB_LEN;
	// 		}
	// 		if ((tab_len = atoi(argv[2 + brief + colorize])) < 1) {
	// 			lex_err("Tab length must be a positive integer. Use \"--help\" or \"-h\" for help.\n");
	// 			return E_TAB_LEN;
	// 		}
	// 	}
	// }


	// CHECK FILE LIST AND ALSO SEARCH OPTION [--output|-o]
	// int start = 1 + brief + colorize + (2 * t_flag), o_flag_index = -1;
	int start = 1, o_flag_index = -1;
	for (int i = start; i < argc; i++) {
		if (isEqual(argv[i], "--output", "-o")) {
			if (o_flag_index < 0) o_flag_index = i;
			else {
				lex_err("Option [--output|-o] specified twice. Use \"--help\" or \"-h\" for help.\n");
				return E_O_FLAG_TWICE;
			}
			continue;
		}


		if (argv[i][0] == '-') {
			lex_err("Invalid option \"%s\". Use \"--help\" or \"-h\" for help.\n", argv[i]);
			return E_INV_OPTION;
		}
	}

	int total_files;
	if (o_flag_index < 0) total_files = argc - start; // -o was never specified. Output on STDOUT
	else if ((total_files = o_flag_index - start) != (argc - o_flag_index - 1)) { // check no. of input and output files are equal
		lex_err("Number of input and files must be equal. Use \"--help\" or \"-h\" for help.\n");
		return E_NUM_IO_UNEQUAL;
	}

	if (total_files < 1) {
		lex_err("Specify at least one file as input. See \"--help\" or \"-h\" for help.\n");
		return E_NO_FILES;
	}

	int file_failures = 0;
	for (int i = 0; i < total_files; i++) {
		// OPEN FILE	
		yyin = fopen(argv[start + i], "r");
		if (!yyin) {
			printf(i > 0 ? "\n" : "");
			lex_warn("File \"%s\" does not exist or problem reading it. Skipping it.\n", argv[start + i]);
			file_failures++;
			continue;
		}

		if ( o_flag_index >= 0 ) {

			temp_out = fopen(argv[o_flag_index + i + 1], "w");
			if(!temp_out){
			printf(i > 0 ? "\n" : "");
			lex_warn("Problem writing to file \"%s\". Skipping it.\n", argv[o_flag_index + i + 1]);
			file_failures++;
			continue;}

			fileName = argv[o_flag_index + i + 1];
		} 
		else 
		{
			int len = strlen(argv[start + i]);
			char out_file_name[len + 5]; strcpy(out_file_name, argv[start + i]);

			// check if ".c" extension or not.
			int _start = len + ((argv[start + i][len - 2] == '.' && argv[start + i][len - 1] == 'c') ? (-2) : 0);
			out_file_name[_start] = '.'; out_file_name[_start + 1] = 'd';
			out_file_name[_start + 2] = 'o'; out_file_name[_start + 3] = 't';
			out_file_name[_start + 4] = '\0';

			if ( !(temp_out = fopen(out_file_name, "w")) ) {
				printf(i > 0 ? "\n" : "");
				lex_warn("Problem writing to file \"%s\". Skipping it.\n", out_file_name);
				file_failures++;
				continue;
			}

			free(fileName);
			fileName = strdup(argv[start + i]);
		}

		// PostScript OK. Try to adjust for actual PDF (although not required).

		int parse_return = yyparse();

		// printf("yyparse() = %d\n", parse_return);
		
		if (!parse_return) AstToDot(temp_out, AstRoot);
		temp_out = NULL; // reset for next file
		token_line = token_column = 1;
		column = 1;

		// fprintf(temp_out, "}\n");
		// if (!temp_out) {
		// 	printf(i > 0 ? "\n" : "");
		// 	printf("Token Stream for file \"%s\":\n", argv[start + i]);
		// }

		// if (colorize && !temp_out) printf("%s%s", _C_BOLD_, _FORE_GREEN_);
		// if (brief) {
		// 	fprintf(temp_out ? temp_out : stdout, "%-18s %-30s %-10s\n", "TOKEN NAME", "LEXEME", "LOCATION");
		// 	fprintf(temp_out ? temp_out : stdout, "------------------ ------------------------------ ----------\n");
		// } else {
		// 	fprintf(temp_out ? temp_out : stdout, "%-8s %-18s %-30s %-8s %-8s\n", "TOKEN #", "TOKEN NAME", "LEXEME", "LINE #", "COLUMN #");
		// 	fprintf(temp_out ? temp_out : stdout, "-------- ------------------ ------------------------------ -------- --------\n");
		// }
		// if (colorize && !temp_out) printf(_C_NONE_);
		
		// column = token_line = token_column = 1;

		// int token, total_tokens = 0;
		// token_t *tok_str = NULL;
		// if (
		// 	fseek(temp_in, 0, SEEK_END) || !( tok_str = malloc(ftell(temp_in) * sizeof(token_t)) )
		// ) lex_warn("Could not get size of file \"%s\". Will skip parsing.\n", argv[start + i]);
		
		// fseek(temp_in, 0, SEEK_SET); // return to beginning of the file. Assume success for now - lift assumption later.

		// while ((token = yylex()) > 0) {
		// 	if (tok_str) {
		// 		tok_str[total_tokens].id = token;
		// 		tok_str[total_tokens].lexeme = malloc(sizeof(char) * (strlen(yytext) + 1));
		// 		strcpy(tok_str[total_tokens].lexeme, yytext);
		// 		tok_str[total_tokens].line = token_line;
		// 		tok_str[total_tokens].column = token_column;
		// 	}
			
		// 	char* token_name = getTokenName(token, yytext);
		// 	if (brief)	fprintf(temp_out ? temp_out : stdout, "%-18s %-30s %d:%d\n", token_name, yytext, token_line, token_column);
		// 	else		fprintf(temp_out ? temp_out : stdout, "%-8d %-18s %-30s %-8d %-8d\n", token, token_name, yytext, token_line, token_column);
		// 	total_tokens++;
		// }

		// if (colorize && !temp_out) printf("%s%s", _C_BOLD_, _FORE_GREEN_);
		// fprintf(temp_out ? temp_out : stdout, "*** TOTAL TOKENS = %d ***\n", total_tokens);
		// if (colorize && !temp_out) printf(_C_NONE_);

		// if (bad_char_seen) {
		// 	if (tok_str) lex_warn("Bad characters encountered. Skipping parsing...\n");
		// 	tok_str = NULL;
		// }

		// if (tok_str) {
		// 	token_t* tmp = realloc(tok_str, total_tokens * sizeof(token_t));
		// 	if (tmp) tok_str = tmp; // else not a very critical issue
		// }

		// // TRY USING THIS FOR PRINTING IN LEXICAL ANALYSIS TOO
		// fprintTokens(temp_out ? temp_out : stdout, tok_str, (unsigned long int) total_tokens, brief);
	}

	return file_failures;
}

char* getTokenName(int tok_num, char* lexeme) {
	return (tok_num < IDENTIFIER || tok_num > RETURN) ? lexeme : TOKEN_NAME_ARRAY[tok_num - IDENTIFIER];
}

int check_type() {
	// PSEUDO-CODE: This is what it should check.
	// if (yytext == type_name) return (TYPE_NAME);
	// return (IDENTIFIER);

	return (IDENTIFIER); // it actually will only return IDENTIFIER
}

void comment() { // multi line comment (MLC)
	column += 2; /* since '/*' start was never counted */
	char c, c_next;

    mlc_loop:
	while ((c = lexInput()) != '*' && c != 0) { // normal characters in an MLC
		token_column = column;
		update_location(c);
	}

	if ((c_next = lexInput()) != '/' && c != 0) { // (Lookahead) '*' is not followed by '/'
		lexUnput(c_next);
		goto mlc_loop;
	}

	if (c != 0) { // End of an MLC (but not due to EOF)
		column++; // because we need to take ending '/' into account
		token_column = column;
		update_location(c);
	}
}

void count() {
	token_column = column;
	for (int i = 0; yytext[i] != '\0'; i++) update_location(yytext[i]);
	// ECHO;
}

void handle_bad_char() {
	bad_char_seen = 1;
	lex_err("Bad character (%s) seen at line %d, column %d.\n", yytext, token_line, token_column);
}

int isEqual(char* option, char* a, char* b) { // return 1 iff option matched a OR b
	if (!option || !(a || b)) return 0;
	if (!a) return !strcmp(option, b); // compare with b if a not given
	if (!b) return !strcmp(option, a);
	return !strcmp(option, a) || !strcmp(option, b);
}

void lex_err(const char* format, ...) {
	va_list args;
	va_start(args, format);
	if (colorize && !temp_out) printf(_FORE_RED_);
	fprintf(temp_out ? temp_out : stdout, "ERROR: ");
	vfprintf(temp_out ? temp_out : stdout, format, args);
	if (colorize && !temp_out) printf(_C_NONE_);
	va_end(args);
}

void lex_warn(const char* format, ...) {
	va_list args;
	va_start(args, format);
	if (colorize && !temp_out) printf(_FORE_YELLOW_);
	fprintf(temp_out ? temp_out : stdout, "WARNING: ");
	vfprintf(temp_out ? temp_out : stdout, format, args);
	if (colorize && !temp_out) printf(_C_NONE_);
	va_end(args);
}

void update_location (char c) {
	if (c == '\n') { column = 1; token_line++; }
	else if (c == '\t') column += tab_len - ((column - 1) % tab_len);
	else column++;
}

void fprintTokens(FILE *f, token_t* tok_str, unsigned long int size, int brief) {
	if (!(f && tok_str)) return;
	for (unsigned long int i = 0; i < size; i++) {
		int _id = tok_str[i].id, _line = tok_str[i].line, _column = tok_str[i].column;
		char *_lexeme = tok_str[i].lexeme, *_name = getTokenName(_id, _lexeme);

		if (brief)	fprintf(f, "%-18s %-30s %d:%d\n", _name, _lexeme, _line, _column);
		else		fprintf(f, "%-8d %-18s %-30s %-8d %-8d\n", _id, _name, _lexeme, _line, _column);
	}
}

/* yywrap() { return 1; } */
