struct {
    int x;
    char ***(*(*f)[])();
} f;
union {
    int x;
    char ***(*(*f)[])();
} g;
int main() {
    struct _loc_t { int x; int y; };
    typedef struct _loc_t loc_t;
    loc_t k;

    struct _loc_t k;
}
