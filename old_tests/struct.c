struct sub {struct {int aa; float bb[10];} a; int b;};
struct pair {
    int x;
    struct sub *y;
    float z[10];
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
    a.z[1] = 1;
    g5_printf("%f\n", a.z[1]);
    a.y->a.bb[5] = 111;
    b.y->a.bb[5] = 10;
    g5_printf("Before: %f %f\n", a.y->a.bb[5], b.y->a.bb[5]);
    b = a;
    g5_printf("After: %f %f\n", a.y->a.bb[5], b.y->a.bb[5]);
    return 0;
}
