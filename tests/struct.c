struct pair {
    int x;
    struct {struct {int aa; char bb;} a; int b;} y;
    short z;
    int p;
};

int main() {
    struct pair a;
    struct pair b;
    a.y.a.aa = 1;
    g5_printf("%d\n", a.y.a.aa);
    // a.y->a.aa = a.y->a.aa + b->y->a.aa;
    // b->y->a.aa = a.y->a.aa;
    // b = a;
    return 0;
}
