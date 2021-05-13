struct st {int a; char b;};
int main() {
	struct st *aa, *bb, cc;
	// int **p, *q, a = 1, b = 100;
	// q = &b;
	// p = &q;
	// g5_printf("%d\n", **p);
	// **p = **p + a;
	// g5_printf("%d %d %d\n", a, **p, b);

	aa = &cc;
	bb = &cc;
	aa->a = 1;
	aa->b = 2;
	g5_printf("%d %d\n", aa->a, aa->b);
	return 0;
}