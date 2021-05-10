// AUM SHREEGANESHAAYA NAMAH|| (DIETY INVOCATION)
#include <cstring>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>

#include <parser.tab.h>
#include <gfcc_lexer.h>
#include <symtab.h>
#include <typo.h>
#include <ircodes.h>
#include <codegen.h>

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
vector<unsigned int> offsets = { 0 }; // line i starts at offsets[i-1], line 1 starts at offsets[0] = 0
vector<struct _token_t> tokDump;
ifstream in_file;

// CLA: <exec-name> [some options] in_1 in_2 ... in_N
// CLA: <exec-name> [some options] in_1 in_2 ... in_N -o[=tok,ast,sym,3ac,asm] { dot_i csv_i 3ac_i asm_i } x N

int main (int argc , char *argv[]) {
	// ARGC TOO FEW
	if (argc < 2) {
		msg(ERR) << "Too few arguments. Use [--help|-h] flag for more help.";
		return E_TOO_FEW_ARGS;
	}

	// HELP - DO NOT CHECK FURTHER OPTIONS
	if (matches(argv[1], "--help", "-h")) {	gfcc_lexer_help(); return 0; }


	// VERSION - DO NOT CHECK FURTHER OPTIONS
	if (matches(argv[1], "--version", "-v")) { gfcc_lexer_version(); return 0; }

	msg(SUCC) << "This toy compiler uses tab length = 4. Use [-t <tab_len>] option for changing it. Use \"--help\" or \"-h\" for more help.";

	int start = 1;
	int o_flag_index = -1, num_t_flag = 0, num_r_flag = 0, num_l_flag = 0;
	int out_reqs = 0x1f, out_to_in = 5; // output file requirements (default all) [out_to_in = # output files per input file]
	int lib_reqs = 0x0; // library requirements (default none)

	// CHECK CLA LIST SEARCHING FOR VARIOUS OPTIONS
	for (int i = start; i < argc; i++) {
		if (matches(argv[i], "--output", "-o")) {
			if (o_flag_index < 0) { o_flag_index = i; continue; }
			msg(ERR) << "Option [--output|-o] specified twice. Use [--help|-h] flag for more help.";
			return E_O_FLAG_TWICE;
		}

		if (matches(argv[i], "--tab-len", "-t")) {
			num_t_flag++;
			if ( ((i+2) > argc) || ((tab_len = atoi(argv[i+1])) < 1) ) {
				msg(ERR) << "Please specify a positive integer after [--tab-len|-t] option. Use [--help|-h] flag for more help.";
				return E_TAB_LEN;
			}
			continue;
		}

		string s(argv[i]);
		
		if (s.substr(0, 10) == "--require=" || s.substr(0, 3) == "-r=") { // now get specifications for output
			num_r_flag++; s = s.substr((s[2] == '=') ? 3 : 10); out_reqs = out_to_in = 0;
			int _comma;
			while (1) {
				string s_ele = ""; bool brk = false; _comma = s.find_first_of(",");
				if (_comma < 0) { s_ele = s; brk = true; }
				else { s_ele = s.substr(0, _comma);	s = s.substr(_comma + 1);	}

				     if (s_ele == "tok") { out_reqs |= OUT_TOK; out_to_in++; }
				else if (s_ele == "ast") { out_reqs |= OUT_AST; out_to_in++; }
				else if (s_ele == "sym") { out_reqs |= OUT_SYM; out_to_in++; }
				else if (s_ele == "3ac") { out_reqs |= OUT_3AC; out_to_in++; }
				else if (s_ele == "asm") { out_reqs |= OUT_ASM; out_to_in++; }
				else if (s_ele != "") {
					msg(WARN) << "Ignoring \"" << s_ele << "\" specified in \"" << argv[i] << "\" flag. Use [--help|-h] flag for more help.";
				}
				
				if (brk) break;
			}
			continue;
		}
		
		if (s.substr(0, 6) == "--lib=" || s.substr(0, 3) == "-l=") { // now get specifications for output
			num_l_flag++; s = s.substr((s[2] == '=') ? 3 : 6); lib_reqs = 0;
			int _comma;
			while (1) {
				string s_ele = ""; bool brk = false; _comma = s.find_first_of(",");
				if (_comma < 0) { s_ele = s; brk = true; }
				else { s_ele = s.substr(0, _comma);	s = s.substr(_comma + 1);	}

				if (s_ele == "math") { lib_reqs |= LIB_MATH; }
				else if (s_ele == "typo") { lib_reqs |= LIB_TYPO; }
				else if (s_ele ==  "std") { lib_reqs |= LIB_STD ; }
				else if (s_ele != "") {
					msg(WARN) << "Ignoring \"" << s_ele << "\" specified in \"" << argv[i] << "\" flag. Use [--help|-h] flag for more help.";
				}
				
				if (brk) break;
			}
			continue;
		}

		if (argv[i][0] == '-') {
			if (matches(argv[i], "--require", "-r")) {
				msg(ERR) << "Please specify one/more of {tok,ast,sym,3ac,asm} after \"=\" after [--require|-r] flag. Example: \"-r=tok,asm\". Use [--help|-h] flag for more help.";
				return E_NO_OUT_REQS;
			}
			if (matches(argv[i], "--lib", "-l")) {
				msg(ERR) << "Please specify one/more of {math,typo,std} after \"=\" after [--lib|-l] flag. Example: \"-l=math,typo\". Use [--help|-h] flag for more help.";
				return E_NO_LIB_REQS;
			}
			msg(ERR) << "Invalid option \"" << argv[i] << "\". Use [--help|-h] flag for more help.";
			return E_INV_OPTION;
		}
	}

	if (!out_to_in) {
		msg(ERR) << "Please specify one/more of {tok,ast,sym,3ac,asm} after \"=\" in [--require|-r] flag. Example: \"-l=tok,asm\". Use [--help|-h] flag for more help.";
		return E_NO_OUT_REQS;
	}

	if (num_l_flag && !lib_reqs) {
		msg(ERR) << "Please specify one/more of {math,typo,std} after \"=\" in [--lib|-l] flag. Example: \"-l=math,typo\". Use [--help|-h] flag for more help.";
		return E_NO_OUT_REQS;
	}

	if (num_t_flag) std::cout << _C_BOLD_ << _FORE_YELLOW_ << "Tab length set to " << tab_len << ".\n" << _C_NONE_;
	if (lib_reqs & LIB_MATH) std::cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC maths library." << endl << _C_NONE_;
	if (lib_reqs & LIB_TYPO) std::cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC typography library." << endl << _C_NONE_;
	if (lib_reqs & LIB_STD ) std::cout << _C_BOLD_ << _FORE_YELLOW_ << "Using GFCC standard library." << endl << _C_NONE_;

	start += (2*num_t_flag) + num_r_flag + num_l_flag;

	int total_in_files;
	if (o_flag_index < 0) total_in_files = argc - start; // -o was never specified. Output on STDOUT
	else if (out_to_in * (total_in_files = o_flag_index - start) != (argc - o_flag_index - 1)) {
		// check if required number of output files are provided.
		msg(ERR) << "Specify output files for each given input file in the priority {tok > ast > sym > 3ac > asm}. Use [--help|-h] flag for more help.";
		return E_NUM_IO_UNEQUAL;
	}

	if (total_in_files < 1) {
		msg(ERR) << "Specify at least one file as input. Use [--help|-h] flag for more help.";
		return E_NO_FILES;
	}

	int file_failures = 0;

	for (int i = 0; i < total_in_files; i++) {
		int _in = start + i; // CLA index of input file

		if (! (yyin = fopen(argv[_in], "r")) ) { // TRY TO OPEN FILE
			if (i > 0) std::cout << endl;
			msg(WARN) << "File \"" << argv[_in] << "\" does not exist or problem reading it. Skipping it.";
			file_failures++;
			continue;
		}

		// doing this to seek independently of 'yyin' when printing errors.
		in_file.open(argv[_in]); // TODO: must gracefully handle errors

		ofstream tok_out, ast_out, sym_out, a3c_out, asm_out;

		if ( o_flag_index >= 0 ) {
			// CLA index of dot and csv output files, if provided "-o"
			int _out = o_flag_index + 1 + (out_to_in * i);
			int _tok, _ast, _sym, _3ac, _asm;
			// TODO: must gracefully handle errors (also increment file_failures)
			if (out_reqs & OUT_TOK) tok_out.open(argv[_out++]);
			if (out_reqs & OUT_AST) ast_out.open(argv[_out++]);
			if (out_reqs & OUT_SYM) sym_out.open(argv[_out++]);
			if (out_reqs & OUT_3AC) a3c_out.open(argv[_out++]);
			if (out_reqs & OUT_ASM) asm_out.open(argv[_out++]);
			
			// if (! (ast_out = fopen(argv[_ast], "w")) ) {
			// 	if (i > 0) cout << endl;
			// 	msg(WARN) << "Problem writing to file \"" << argv[_ast] << "\". Skipping writing to it.";
			// 	file_failures++;
			// 	continue;
			// }

		} else {
			string copyName(argv[_in]);
			int d = copyName.find_first_of('.');
			if (d > -1) copyName.erase(d);

			// Change extension if you want.
			// TODO: must gracefully handle errors (also increment file_failures)
			if (out_reqs & OUT_TOK) tok_out.open(copyName + ".tok.csv");
			if (out_reqs & OUT_AST) ast_out.open(copyName + ".dot");
			if (out_reqs & OUT_SYM) sym_out.open(copyName + ".sym.csv");
			if (out_reqs & OUT_3AC) a3c_out.open(copyName + ".3ac");
			if (out_reqs & OUT_ASM) asm_out.open(copyName + ".asm");

			// if ( !(temp_out = fopen(out_file_name, "w")) ) {
			// 	if (i > 0) cout << endl;
			// 	msg(WARN) << "Problem writing to file \"" << out_file_name << "\". Skipping it.";
			// 	file_failures++;
			// 	continue;
			// }
		}

		fileName = argv[_in];

		libDumpSym(lib_reqs);

		int parse_return = yyparse(); std::cout << "yyparse() = " << parse_return << endl;
		
		if (!parse_return) {
			if (out_reqs & OUT_TOK) { //  do not dump library tokens
				tok_out << "# File Name: " << argv[_in] << endl << endl;
				dumpTok(tok_out, tokDump);
			}
			
			if (out_reqs & OUT_AST) { // AST to DOT conversion - do not output library ASTs
				ast_out << "// File Name: " << argv[_in] << endl << endl;
				ast_out << "digraph {" << endl;
				if (!AstRoot) ast_out << "\t0 [label=\"" << fileName << " (nothing useful)\",shape=none];" << endl;
				else AstToDot(ast_out, AstRoot);
				ast_out << "}" << endl;
			}
			
			if (out_reqs & OUT_SYM) { // Symbol table to CSV conversion - dump library symbols too
				sym_out << "# File Name: " << argv[_in] << endl << endl;
				sym_out << csvHeaders << endl << endl; /// CSV HEADERS
				SymRoot->dump(sym_out);
			}

			if (out_reqs & OUT_3AC) { // 3AC code dump - do not dump library 3AC
				a3c_out << "# File Name: " << argv[_in] << endl << endl;
				// revisit3AC(IRDump);
				dumpStr(a3c_out, StrDump);
				dumpIR(a3c_out, IRDump);
			}

			if (out_reqs & OUT_ASM) { // ASM code dump - dump library ASM code
				if (semanticErr) msg(WARN) << "Semantic error: NOT proceeding with code generation.";
				else {
					asm_out << "# File Name: " << argv[_in] << endl << endl;
					libDumpASM(asm_out, lib_reqs);
					asm_out << "## SOURCE FILE (" << argv[_in] << ")" << endl << endl;
					dumpASM(asm_out, IRDump);
				}
			}
		}
		
		// PREPARE FOR NEXT FILE (ITERATION)
		tok_out.close(); ast_out.close(); sym_out.close(); a3c_out.close(); asm_out.close();
	  resetLexer();
		resetTypes();
	  resetSymtab();
	  resetIRCodes();
		resetCodegen();
	}

	return file_failures;
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
	repErr(gpos, "bad character seen (not in C alphabet)", _FORE_RED_);
	// msg(ERR) << "Bad character (" << yytext << ") seen at " << string(fileName) << ":" << gpos.line << ":" << gpos.column << endl;
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

void dumpTok(std::ofstream &f, std::vector<struct _token_t> &arr) { // to dump tokens (like Milestone 1)
	f << "*** TOTAL TOKENS = " << arr.size() << " ***" << endl << endl;
	f << "TOKEN TYPE ID, TOKEN TYPE NAME, LEXEME, LINE, COLUMN" << endl << endl;
	for (auto _token : arr) {
		int tok = _token.tok;
		f << setw( 8) << tok << ", ";
		f << setw(18) << ((tok < IDENTIFIER || tok > RETURN) ? _token.lexeme : TOKEN_NAME_ARRAY[tok - IDENTIFIER]) << ", ";
		f << setw(30) << _token.lexeme << ", ";
		f << setw( 8) << _token.pos.line << ", ";
		f << setw( 8) << _token.pos.column << endl;
	}
	f << endl;
}

/* yywrap() { return 1; } */

void resetLexer() {
	bad_char_seen = 0;
	column = 1; gpos = { 1, 1 };
	offsets.clear(); offsets.push_back(0); // line 1 starts at offsets[0] = 0
	fclose(yyin);
	temp_out = NULL;
	fileName = NULL;
	currNumNodes = 0;
	in_file.close();
	tokDump.clear();
	purgeAST(AstRoot); // frees the current AST
}
