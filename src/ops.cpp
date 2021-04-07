// AUM SHREEGANESHAAYA NAMAH||

#include <iostream>
#include <string>
#include <vector>
#include <unordered_map>

#include <types2.h>
#include <typo.h>

using namespace std;

class Type *bin(int opr, node_t* left, node_t* right) { // binary operations
    Type *tl = left->type, *tr = right->type; grp_t gl = tl->grp(), gr = tr->grp();
    // assume nothing goes NULL
    switch (opr) {
        case '+' : case '-' :

        case '*' : case '/' : case '%' :
            if (gl == BASE_G && gr == BASE_G) {
                switch (gl) {
                    case VOID_B : repErr(left->pos, "pure \"void\" type used in an expression", _FORE_RED_);
                }
                    
	            // VOID_B, CHAR_B, SHORT_B, INT_B, FLOAT_B, LONG_B, LONG_LONG_B, DOUBLE_B, LONG_DOUBLE_B
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
