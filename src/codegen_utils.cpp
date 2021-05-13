#include <vector>
#include <ircodes.h>
#include <codegen.h>
#include <symtab.h>
using namespace std;

string loadArrAddr(ofstream & f, deltaOpd & Opd, string pos) {
  /*
    * pos:  0 for dst (use $a0, $a3)
    *       1 for src1 (use $a1, $a3)
    *       2 for src2 (use $a2, $a3)
  */
  if(!Opd.Sym || Opd.Type == 0 ) {
    // cout << "string loadArrAddr: Called for non-array" << endl;
    return "";
  }

  string addrReg = "$a" + pos;          // store address here if non-constant offset or "->"
	string symReg = reg2str[Opd.Sym->reg];   // base address of the base symbol
	bool allConst = true;
	int constOffset = 0;
  f << "\t #### <Load address> ###" << endl;
  
  if (Opd.Type == 1) {
    vector<int> dimSize;
    Arr *a = (Arr *) Opd.Sym->type;
    for(auto dim: a->dims) {
      int * sizePtr = eval(dim);
      if(!sizePtr) {
        cout << "string loadArrAddr: eval(dim) failed for a dimension" << endl;
        dimSize.push_back(INT16_MAX);
      }
      else dimSize.push_back(*sizePtr);
    }
    
    /* for array part */
    if(dimSize.size() > Opd.ArrOff.size())
      cout << "string loadArrAddr: some problem in semantic analysis" << endl;
    
    int dimWidth = getSize(a->item);
    for(int i = dimSize.size()-1; i>=0; i--) {
      if(!Opd.ArrSymb[i]) {
        /* constant  operand*/
        constOffset += stoi(Opd.ArrOff[i]) * dimWidth;
      }
      else {
        /* variable offset */
        /* eg. lw $a3, -44($fp) */
        f << '\t' << "lw $a3, -" + to_string(Opd.ArrSymb[i]->offset) + "($fp)"
          << " # load " + Opd.ArrSymb[i]->name << endl;
        /* eg. mul $a3, $a3, dimWidth */
        if (dimWidth != 1)
          f << '\t' << "mul $a3, $a3, " + to_string(dimWidth)
            << " # multiply with dimWidth" << endl;
        
        if(allConst){
          allConst = false;
          // base + currOffset
          /* eg. addu $a0, $t0, $a3 */
          f << '\t' << "addu " + addrReg + ", " + symReg +", $a3"
            << " # offset calc" << endl;
        }
        else 
          // offsetTillNow + currOffset
          /* eg. addu $a0, $a0, $a3 */
          f << '\t' << "addu " + addrReg + ", " + addrReg + ", $a3" 
            << " # offset calc" << endl;
      }
      dimWidth *= dimSize[i];
    }
    /* eg. "10($t0)" */
    if(allConst) return to_string(constOffset) + "("+symReg+")";
    /* eg. "$a0" */
    else {
      if (constOffset)
      /* addu $a0, $a0, constOffset */
      f << '\t' << "addu " + addrReg + ", " + addrReg + ", " + to_string(constOffset) 
            << " # add const offset" << endl;
      return "("+addrReg+")";
    }
  }
  
  else if(Opd.Type == 2) { // struct: ".", "->"
		f << '\t' << "move "<< addrReg + ", " << symReg << endl;
		for(auto pfx: Opd.PfxOprs) {
			// cout << pfx.name << endl;
			if(pfx.type == ".") {
        if (pfx.symb->offset != 0)
         f << '\t' << "addu " + addrReg + ", " + addrReg + ", " << to_string(pfx.symb->offset) 
            << " # offset calc" << endl;
			}
			else if(pfx.type == ">") {
				f << '\t' << "lw " << addrReg << ", " << "("+addrReg+")" << endl;
        if (pfx.symb->offset != 0)
				  f << '\t' << "addu " + addrReg + ", " + addrReg + ", " << to_string(pfx.symb->offset) 
            << " # offset calc" << endl;
			}
      else if (pfx.type == "[]") {
        if(pfx.symb == NULL) {
          if (pfx.name != "0")
          f << '\t' << "addu " + addrReg + ", " + addrReg + ", " << pfx.name
            << " # offset calc" << endl;
        }
        else {
          f << '\t' << "lw $a3, -" + to_string(pfx.symb->offset) + "($fp)"
            << " # load " + pfx.symb->name << endl;
          f << '\t' << "mul $a3, $a3, " + pfx.name
            << " # width calc" << endl;
          f << '\t' << "addu " + addrReg + ", " + addrReg + ", $a3"
            << " # offset calc" << endl;
        }
      }
		}
		return "("+addrReg+")";
  }

  /* for pointer part */
  // TODO: pointer
  return "aa";
}



void parseStruct(string & q, deltaOpd & Opd) {
	vector <string> tokens = {".", ">", "["};
	int currPos = Find_first_of(q, tokens);
	if(currPos >= 0) {
		Opd.Type = 2;
		cout <<"Struct parse " << q << endl;
		string tmp = q.substr(0, currPos);
		if(q[currPos] == '>')tmp.pop_back();
		cout << "Base: " + tmp << endl;
		/* search in sym table */
		sym* st_sym = SymRoot->gLookup(tmp);
		Type* st_type;
		if(st_sym)
			st_type = st_sym->type;
		else {
			cout << "can't find " + tmp + " in symtab" << endl;
			return;
		}

		/* push first symbol */
		pfxOpr p;
		p.name = tmp;
		p.symb = st_sym;
		p.type = "---";
		// Opd.PfxOprs.push_back(p);

    vector<int> dimSize;
    int counter = 0, dimCount = 0, dimWidth = 1;
    int nxtPos = Find_first_of(q, tokens, currPos+1);
		while(currPos >= 0){
			pfxOpr p;
      p.type = q[currPos]; // ".", ">", "["

      if(p.type == ">" || p.type == ".") { // ".", "->"
        p.name = q.substr(currPos+1, nxtPos-currPos-1);
        if(q[nxtPos] == '>') p.name.pop_back();
        
        if(p.type == ">") { // pointer to struct
          if(!isPtr(st_type)) cout << "-> for non-pointer" << endl;
          st_type = ((Ptr *) st_type)->pt;
        }
        if(!isStruct(st_type)) cout << p.name + " is not an struct" << endl;
			  st_sym = findStructChild(st_type, p.name);
			  st_type = st_sym->type;
        p.symb = st_sym;
      }

      else if(p.type == "[") { // "[]" -- either array or pointer

        p.type = "[]";
        int brkClosePos = q.find_first_of("]", currPos+1);
        if(brkClosePos == -1) cout << "parseStruct:: Error: can't find ']'" << endl;
        p.name = q.substr(currPos+1, brkClosePos-currPos-1);
        p.symb = SymRoot->gLookup(p.name); // NULL if constant
        nxtPos = Find_first_of(q, tokens, brkClosePos+1);

        if(dimCount == 0) { // start of array or pointer
          if(!isArr(st_type) && !isPtr(st_type)) cout << "-> for invalid type" << endl;
          
          if(isArr(st_type)) {
            Arr* a = (Arr *) st_type;
            st_type =  a->item;
            dimSize = getDimSize(a);
            cout << "#########" << endl;
            dimWidth = getWidth(dimSize);
            dimCount = dimSize.size();
            counter = 1;
          }
          
          else {
            // element width == dimWidth
            dimWidth = 1;
            counter = 0;
            st_type = ptrChildType(st_type);
          }
        }
        
        int dimOffs = getSize(st_type) * dimWidth; // dimWidth * elSize
        if(!p.symb) { // constant offset
          p.name = to_string(stoi(p.name) * dimOffs);
        }
        else p.name = to_string(dimOffs);

        if(counter == dimCount){ // end multidim array;
          counter = 0;
          dimCount = 0;
        }
        else { // carry on multi-dim array
          // get width of nxt dimension
          dimWidth /= dimSize[counter];
          counter++;
        }
      }

			Opd.PfxOprs.push_back(p);
			cout << p.type + "  " + p.name + " " << counter << endl; //!
			currPos = nxtPos;
			nxtPos = Find_first_of(q, tokens, currPos + 1);
		}
		// if(currPos != q.size()) {
		// 	pfxOpr p;
		// 	p.type = q[currPos]; // ".", ">"
		// 	p.name = q.substr(currPos+1);
		// 	if(q[nxtPos] == '>') p.name.pop_back();

		// 	if(p.type == ">") { // pointer to struct
		// 		if(!isPtr(st_type)) cout << "-> for non-pointer" << endl;
		// 		st_type = ((Ptr *) st_type)->pt;
		// 	}
    //   else if(p.type == "[") {
    //     p.type = "[]";
    //     int brkClosePos = q.find_first_of("]", currPos+1);
    //     if(brkClosePos == -1) cout << "parseStruct:: Error: can't find ']'" << endl;
    //     nxtPos = brkClosePos;
    //   }
		// 	if(!isStruct(st_type)) cout << p.name + " is not an struct" << endl;
		// 	st_sym = findStructChild(st_type, p.name);
		// 	st_type = st_sym->type;
		// 	p.symb = st_sym;
		// 	Opd.PfxOprs.push_back(p);
		// 	cout << p.type + "  " + p.name << endl; //!
		// }
		q = tmp;
		Opd.FinalType = st_type;
	}
}


void memCopy(std::ofstream &f, reg_t src, reg_t dst, int size) {
  if(size < 1) return;

  string srcReg = reg2str[src], dstReg = reg2str[dst], freeReg = "$a3";
  string loadInstr[] = {"lw", "ls", "lb"};
  string storeInstr[] = {"sw", "ss", "lb"};
  
  f << '\t' << "### <memcopy> size = " + to_string(size)
    << " from " + reg2str[src] + " to " + reg2str[dst] + " ###"<< endl;
  int chnkSize = 4, instr = 0, remSize = size;
  while(remSize > 0) {
    if(remSize < chnkSize) {
      chnkSize /= 2;
      instr++;
      continue;
    }

    /* eg. lw $a3, 20($a0) */
    f << '\t' << loadInstr[instr] + " " + freeReg + ", "
      << to_string(size-remSize) + "("  << srcReg + ")" << endl;
    /* eg. sw $a3, 20($a1) */
    f << '\t' << storeInstr[instr] + " " + freeReg + ", "
      << to_string(size-remSize) + "("  << dstReg + ")" << endl;
    remSize -= chnkSize;
  }
}


sym* findStructChild(Type* st_type, string chName) {
	Base * b = (Base *) st_type;
	for (auto ch: b->subDef->syms) {
		if(ch->name == chName) return ch;
	}
	return NULL;
}

Type* ptrChildType(Type * t) {
  if(!isPtr(t)) return NULL;
  Ptr* p = (Ptr *) clone(t);
  if(p->ptrs.size()==1) return p->pt;
  else {
    p->ptrs.pop_back();
    return p;
  }
}

vector<int> getDimSize(Arr* a) {
  vector<int> dimSize;
  for(auto dim: a->dims) {
    int * sizePtr = eval(dim);
    if(!sizePtr) {
      dimSize.push_back(INT16_MAX);
    }
    else dimSize.push_back(*sizePtr);
  }
  return dimSize;
}

int getWidth(vector<int> dimSize) {
  int width = 1;
  for(int i = 1; i < dimSize.size(); i++) {
    width *= dimSize[i];
  }
  cout << "width " << width << endl;
  return width;
}

size_t Find_first_of(string s, vector<string> tokens, size_t pos) {
	size_t nxtPos = -1;
	for(auto tok: tokens) {
		nxtPos = min(nxtPos, s.find_first_of(tok, pos));
	}
	return nxtPos;
}
