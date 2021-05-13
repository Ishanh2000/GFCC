int main() {
	int *p, a = 1, b = 100;
	p = &b;
	g5_printf("%d\n", p[0]);
	a = p[0] + a;
	g5_printf("%d %d %d\n", a, p[0], b);
	return 0;
}
