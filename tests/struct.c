struct pair {
    int x;
    struct {struct {int aa; char bb;} a; int b;} *y;
    short z;
    int p;
};
struct pair1 {
    int x;
    struct {struct {int aa; char bb;} a; int b;} *y;
    short z;
    int p;
};
int main() {
    struct pair a;
    struct pair1 b;
    b = a;
    return 0;
}
