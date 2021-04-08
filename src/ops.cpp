// AUM SHREEGANESHAAYA NAMAH||

#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>
#include <parser.tab.h>
#include <types2.h>
#include <typo.h>
#include <ops.h>

using namespace std;

// BASE_G, PTR_G, ARR_G, FUNC_G
std::unordered_map<base_t, int> priority =
    {{CHAR_B, 0}, {SHORT_B, 1}, {INT_B, 2}, {LONG_B, 3}, {LONG_LONG_B, 4}, {FLOAT_B, 5}, {DOUBLE_B, 6}, {LONG_DOUBLE_B, 7}};

class Type *bin(int opr, node_t *left, node_t *right)
{ // binary operations
    Type *tl = left->type, *tr = right->type;
    if (tl->isErr || tr->isErr)
        return (tl->isErr) ? tl : tr;

    grp_t gl = tl->grp(), gr = tr->grp();

    Base *bl = (Base *)tl, *br = (Base *)tr;
    Ptr *pl = (Ptr *)tl, *pr = (Ptr *)tr;
    Arr *al = (Arr *)tl, *ar = (Arr *)tr;
    Func *fl = (Func *)tl, *fr = (Func *)tr;
    // assume nothing goes NULL
    if (gl == BASE_G && gr == BASE_G) {
        if (bl->base == VOID_B || br->base == VOID_B)
        {
            repErr(left->pos, "pure \"void\" type used in an expression", _FORE_RED_);
            tl->isErr = true;
            return tl;
        }
    }

    switch (opr) {
    case '+': case '-':
        if (gl == ARR_G || gr == ARR_G) {
            if (gl == gr) {
                repErr(left->pos, "invalid arithmetic for array type", _FORE_RED_);
                tl->isErr = true;
                return tl;
            }
            if ((gl == BASE_G) && (priority[bl->base] <= priority[LONG_LONG_B])) { // int + arr
                ar = (Arr *) tr;
                if (ar->dims.size() > 1) { ar->dims.erase(ar->dims.begin()); return new Ptr(ar); }
                if (ar->dims.size() == 1) return new Ptr(ar->item);
            }
            if ((gr == BASE_G) && (priority[br->base] <= priority[LONG_LONG_B])) { // arr + int
                al = (Arr *) tl;
                if (al->dims.size() > 1) { al->dims.erase(al->dims.begin()); return new Ptr(al); }
                if (al->dims.size() == 1) return new Ptr(al->item);
            }
            repErr(left->pos, "invalid arithmetic for array type", _FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        if(gl == PTR_G || gr == PTR_G) {
            if(gl == gr) {
                repErr(left->pos,"Invalid Pointer arithmetic",_FORE_RED_);
                tl->isErr = true;
                return tl;    
            }
            if(gl == BASE_G) {
                if(priority[bl->base]<=priority[LONG_LONG_B]){
                    return tr;
                }
            }
            if(gr == BASE_G) {
                if(priority[br->base]<=priority[LONG_LONG_B]){
                    return tl;
                }
            }
            repErr(left->pos,"Invalid Pointer arithmetic",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
    case '*': case '/':
        if (gl == BASE_G && gr == BASE_G)
        {
            if (bl->base == br->base)
            {
                if (bl->sign == br->sign || (bl->sign != UNSIGNED_X && bl->sign != UNSIGNED_X))
                    return tl;
                repErr(left->pos, "Implicit typecasting from unsigned to signed", _FORE_MAGENTA_);
                return (bl->sign == UNSIGNED_X) ? tl : tr;
            }

            if (priority[bl->base] > priority[br->base])
            {
                if (br->sign == UNSIGNED_X)
                    bl->sign = UNSIGNED_X;
                return tl;
            }
            else
            {
                if (bl->sign == UNSIGNED_X)
                    br->sign = UNSIGNED_X;
                return tr;
            }
        }
        else if(gl == PTR_G || gr == PTR_G) {
            repErr(left->pos,"Invalid Pointer arithmetic",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        else if(gl == ARR_G || gr == ARR_G) {
            repErr(left->pos,"Invalid Pointer arithmetic",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        else if(gl == FUNC_G || gr == FUNC_G) {
            repErr(left->pos,"Operation not supported for function pointers",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        break;
				    
    case '%':
				if(gl == BASE_G && gr == BASE_G \
        && priority[bl->base]<=priority[LONG_LONG_B]
        && priority[br->base]<=priority[LONG_LONG_B]){
            return tl;
        }
        else {
            repErr(left->pos,"invalid operands to binary %",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        break;
		
		// ! 'a': >>, 'b': <<
    case '&': case '^': case '|': case 'a': case 'b': 
        if(gl == BASE_G && gr == BASE_G \
        && priority[bl->base]<=priority[LONG_LONG_B]
        && priority[br->base]<=priority[LONG_LONG_B]){
            return tl;
        }
        else {
            repErr(left->pos,"invalid operands to binary bitwise operator",_FORE_RED_);
            tl->isErr = true;
            return tl;
        }
        break;
    case '<': case '>':
        if(gl==BASE_G && gr == BASE_G){
            // ! return int type
            bl = new Base(INT_B);
            return bl;
        }
        if(gl==gr){
            // ! return int type
            bl = new Base(INT_B);
            return bl;
        }
        if(gl==BASE_G || gr == BASE_G){
            repErr(left->pos,"invalid operands to binary relational operator",_FORE_RED_);    
            bl->isErr = true;
            return tl;
        }
        repErr(left->pos,"comparison of distinct pointer types lacks a cast",_FORE_MAGENTA_);
        return tl;
    case AND_OP : case OR_OP :
        bl = new Base(INT_B);
        return bl;
    }    
}

#ifdef TEST_OPS

int main()
{
    // conduct tests.

    return 0;
}

#endif
