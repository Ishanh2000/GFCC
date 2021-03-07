int main() {
    const int a, b;
    const int (a), (b);
    const int a[a+b-c], b[45];
    const int p[], q[];
    const int p(a, c), q(), r(int, char, ...);

    const volatile int a, b;
    const volatile int *a, * const * const * const volatile const *x;
    int x[] = { 1, 2, 3, {11, {11, 23, 90,}, 23, 90,} };

  my_label:
    switch(1) {
        case 0: "STMT";
        case 1: "STMT";
        default: "STMT";
    }

    enum {a, c = 89+22*7/5%0-2, b};
    enum _t_{a, c = 89+22*7/5%0-2, b};
    enum _t_;

    int a = 67, b, *p = NULL;
    void const volatile int typedef auto char int *a= NULL;
    { } { x = 90; } { int x; } { int x; int y; x = 90; } // blocks
    ; main + 90; // empty and expression stmt

    if (candoit()) {
        do_smthng();
    }
    if (candoit()) {
        do_smthng();
    } else cannotdoit();
    switch(1) {
        case 0: "STMT";
        case 1: "STMT";
        default: "STMT";
    }
    while (abd) { ABCD; "Helo"; 9+8; ; }
    do { } while (abd);
    for (i = 9; l = 89;) printf();
    for (i = 9; l = 89; d++) { ABCD; "Helo"; 9+8; }
}