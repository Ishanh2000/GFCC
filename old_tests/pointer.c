struct st {int a; char b;};
int main() {
	struct st *aa, *bb, cc;
	int **p, *q, a = 1, b = 10, d;
	q = &b;
	p = &q;
	d = p[0][0];
	g5_printf("%d\n", d);
	p[0][0] = p[0][0] + a;
	g5_printf("%d %d %d\n", a, p[0][0], b);

	aa = &cc;
	bb = &cc;
	aa->a = 1;
	aa->b = 2;
	g5_printf("%d %d\n", aa->a, aa->b);
	return 0;
}
