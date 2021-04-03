// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
#include <cstring>
#include <iostream>
#include <fstream>

#include <parser.tab.h>
#include <gfcc_lexer.h>
#include <symtab.h>
#include <typo.h>

using namespace std;

// INITIALIZE ALL GLOBAL VARIABLES IN THIS FILE ONLY. DO NOT CHANGE
// THEIR NAMES. SINCE THEY ARE SHARE ACROSS MULTIPLE FILES.

int column = 1; // internally used by parser - DO NOT TOUCH!!!
loc_t gpos = { 1, 1 }; // global position in current file

FILE *temp_out = NULL; // if this is NULL, use stdout
int tab_len = TAB_LEN;
int bad_char_seen = 0; // to notify parser
ull_t currNumNodes = 0; // invariant: currNumNodes > 0 for all existing nodes.
node_t* AstRoot = NULL;
char * fileName = NULL;
symRoot *SymRoot = NULL;
vector<unsigned int> offsets; // line i starts at offsets[i-1]
ifstream in_file;

// CLA: <exec-name> [some options] in_1 in_2 ... in_N
// CLA: <exec-name> [some options] in_1 in_2 ... in_N -o dot_1 csv_1 dot_2 csv_2 ... dot_n csv_n

int main (int argc , char *argv[]) {
	// ARGC TOO FEW
	if (argc < 2) {
		msg(ERR) << "Too few arguments. Use \"--help\" or \"-h\" for help.";
		return E_TOO_FEW_ARGS;
	}

	// HELP - DO NOT CHECK FURTHER OPTIONS
	if (matches(argv[1], "--help", "-h")) {	gfcc_lexer_help(); return 0; }


	// VERSION - DO NOT CHECK FURTHER OPTIONS
	if (matches(argv[1], "--version", "-v")) { gfcc_lexer_version(); return 0; }


	// CHECK FILE LIST AND ALSO SEARCH OPTION [--output|-o]
	int start = 1, o_flag_index = -1;
	for (int i = start; i < argc; i++) {
		if (matches(argv[i], "--output", "-o")) {
			if (o_flag_index < 0) o_flag_index = i;
			else {
				msg(ERR) << "Option [--output|-o] specified twice. Use \"--help\" or \"-h\" for help.";
				return E_O_FLAG_TWICE;
			}
			continue;
		}


		if (argv[i][0] == '-') {
			msg(ERR) << "Invalid option \"" << argv[i] << "\". Use \"--help\" or \"-h\" for help.\n";
			return E_INV_OPTION;
		}
	}

	int total_in_files;
	if (o_flag_index < 0) total_in_files = argc - start; // -o was never specified. Output on STDOUT
	else if (2 * (total_in_files = o_flag_index - start) != (argc - o_flag_index - 1)) {
		// check no. of input and output files are equal
		msg(ERR) << "Specify output files for each given input file. Use \"--help\" or \"-h\" for help.";
		return E_NUM_IO_UNEQUAL;
	}

	if (total_in_files < 1) {
		msg(ERR) << "Specify at least one file as input. See \"--help\" or \"-h\" for help.";
		return E_NO_FILES;
	}

	int file_failures = 0;

	for (int i = 0; i < total_in_files; i++) {
		int _in = start + i; // CLA index of input file

		if (! (yyin = fopen(argv[_in], "r")) ) { // TRY TO OPEN FILE
			if (i > 0) cout << endl;
			msg(WARN) << "File \"" << argv[_in] << "\" does not exist or problem reading it. Skipping it.";
			file_failures++;
			continue;
		}

		// doing this to seek independently of 'yyin' when printing errors.
		in_file.open(argv[_in]); // TODO: must gracefully handle errors

		ofstream dot_out, csv_out;

		if ( o_flag_index >= 0 ) {
			int _dot = o_flag_index + 1 + (2 * i), _csv = _dot + 1; // CLA index of dot and csv output files, if provided "-o"
			
			dot_out.open(argv[_dot]); // TODO: must gracefully handle errors
			csv_out.open(argv[_csv]); // TODO: must gracefully handle errors

			// if (! (dot_out = fopen(argv[_dot], "w")) ) {
			// 	if (i > 0) cout << endl;
			// 	msg(WARN) << "Problem writing to file \"" << argv[_dot] << "\". Skipping writing to it.";
			// 	file_failures++;
			// 	continue;
			// }

		} else {
			string dotName(argv[_in]), csvName(argv[_in]); // manipulate these copies to create .dot/.csv extensions
			int d = dotName.find_last_of('.');
			if (d >= 0) { dotName.erase(d); csvName.erase(d); }
			dotName.append(".dot"); csvName.append(".csv");

			dot_out.open(dotName); // TODO: must gracefully handle errors
			csv_out.open(csvName); // TODO: must gracefully handle errors

			// if ( !(temp_out = fopen(out_file_name, "w")) ) {
			// 	if (i > 0) cout << endl;
			// 	msg(WARN) << "Problem writing to file \"" << out_file_name << "\". Skipping it.";
			// 	file_failures++;
			// 	continue;
			// }
		}

		fileName = argv[_in];

		// PostScript OK. Try to adjust for actual PDF (although not required).

		SymRoot = new symRoot();

		offsets.push_back(0); // line 1 starts at offsets[0] = 0

		int parse_return = yyparse(); cout << "yyparse() = " << parse_return << endl;
		
		if (!parse_return) {
			// AST to DOT conversion
			dot_out << "digraph {" << endl;
			if (!AstRoot) dot_out << "\t0 [label=\"" << fileName << " (nothing useful)\",shape=none];" << endl;
			else AstToDot(dot_out, AstRoot);
			dot_out << "}" << endl;

			// Symbol table to CSV conversion
			csv_out << "# File Name:, " << argv[_in] << endl << endl;
			csv_out << csvHeaders << endl << endl; /// CSV HEADERS
			SymRoot->dump(csv_out);
		}

		// PREPARE FOR NEXT FILE (ITERATION)
		in_file.close(); dot_out.close(); csv_out.close();
		purgeAST(AstRoot); // frees the current AST
		delete SymRoot; // frees the current symbol tables
		column = 1; gpos = { 1, 1 }; offsets.clear();
		temp_out = NULL; // reset for next file
	}

	return file_failures;
}

const char* getTokenName(int tok_num, const char* lexeme) {
	return (tok_num < IDENTIFIER || tok_num > RETURN) ? lexeme : TOKEN_NAME_ARRAY[tok_num - IDENTIFIER];
}

void comment() { // multi line comment (MLC)
	column += 2; /* since '/*' start was never counted */
	char c, c_next;

    mlc_loop:
	while ((c = lexInput()) != '*' && c != 0) { // normal characters in an MLC
		gpos.column = column;
		update_location(c);
	}

	if ((c_next = lexInput()) != '/' && c != 0) { // (Lookahead) '*' is not followed by '/'
		lexUnput(c_next);
		goto mlc_loop;
	}

	if (c != 0) { // End of an MLC (but not due to EOF)
		column++; // because we need to take ending '/' into account
		gpos.column = column;
		update_location(c);
	}
}

void count() {
	gpos.column = column;
	for (int i = 0; yytext[i] != '\0'; i++) update_location(yytext[i]);
	// ECHO;
}

void handle_bad_char() {
	bad_char_seen = 1;
	msg(ERR) << "Bad character (" << yytext << ") seen at line " << gpos.line << ", column " << gpos.column << "." << endl;
}

bool matches(const char* option, string a) { // return 1 iff option matched a OR b
	return !(a.compare(option));
}

bool matches(const char* option, string a, string b) { // return 1 iff option matched a OR b
	return !( a.compare(option) && b.compare(option) );
}

void update_location (char c) {
	if (c == '\n') { column = 1; gpos.line++; offsets.push_back(offsets.back() + gpos.column); } // Inserting new offset here also.
	else if (c == '\t') column += tab_len - ((column - 1) % tab_len);
	else column++;
}

void fprintTokens(FILE *f, token_t* tok_str, unsigned long int size, int brief) {
	if (!(f && tok_str)) return;
	for (unsigned long int i = 0; i < size; i++) {
		int _id = tok_str[i].id, _line = tok_str[i].line, _column = tok_str[i].column;
		const char *_lexeme = tok_str[i].lexeme, *_name = getTokenName(_id, _lexeme);

		if (brief)	fprintf(f, "%-18s %-30s %d:%d\n", _name, _lexeme, _line, _column);
		else		fprintf(f, "%-8d %-18s %-30s %-8d %-8d\n", _id, _name, _lexeme, _line, _column);
	}
}

/* yywrap() { return 1; } */
