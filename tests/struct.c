struct sub {struct {int aa; char bb;} a; int b;};
struct pair {
    int x;
    struct sub *y;
    short z;
    int p;
};



int main() {
    struct pair a;
    struct pair b;
    struct sub a_sub;
    struct sub b_sub;
    int arr[100];
    a.y = &a_sub;
    b.y = &b_sub;
    b.y->a.aa = 0;
    g5_printf("%d\n", b.y->a.aa);
    a.y->a.aa = 1;
    b.y->a = a.y->a;
    // b.y.a = a.y.a;
    g5_printf("%d\n", b.y->a.aa);
    // a.y->a.aa = a.y->a.aa + b->y->a.aa;
    // b->y->a.aa = a.y->a.aa;
    // b = a;
    return 0;
}
