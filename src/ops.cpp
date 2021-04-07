// AUM SHREEGANESHAAYA NAMAH||

#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>

#include <types2.h>
#include <typo.h>

using namespace std;

// BASE_G, PTR_G, ARR_G, FUNC_G

// bool naam(base_t bl, )

// func()

class Type *bin(int opr, node_t* left, node_t* right) { // binary operations
    
    Type *tl = left->type, *tr = right->type;
    if (tl->isErr || tr->isErr) return (tl->isErr) ? tl : tr;

    grp_t gl = tl->grp(), gr = tr->grp();

    Base *bl = (Base *)tl, *br = (Base *)tr;
    Ptr *pl = (Ptr *)tl, *pr = (Ptr *)tr;
    Arr *al = (Arr *)tl, *ar = (Arr *)tr;
    Func *fl = (Func *)tl, *fr = (Func *)tr;
    // assume nothing goes NULL
    switch (opr) {
        case '+' : case '-' :


        case '*' : case '/' : case '%' : // 
            if (gl == BASE_G && gr == BASE_G) {
                if (bl->base == VOID_B || br->base == VOID_B) { repErr(left->pos, "pure \"void\" type used in an expression", _FORE_RED_); tl->isErr = true; return tl; }
                if (bl->base == INT_B && br->base == FLOAT_B) { bl->base = FLOAT_B; return tl; }
                if (bl->base == FLOAT_B && br->base == INT_B) { bl->base = FLOAT_B; return tl; }

    
	            // CHAR_B, SHORT_B, INT_B, FLOAT_B, LONG_B, LONG_LONG_B, DOUBLE_B, LONG_DOUBLE_B
            }

            break;
    }
    
}

#ifdef TEST_OPS

int main() {
    // conduct tests.

    return 0;
}

#endif
