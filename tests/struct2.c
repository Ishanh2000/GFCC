int main() {
	int k = 1;
	int a[3][4][2];
	a[1][k][1] = 1;
	g5_printf("%d\n", a[1][k][1]);
	a[1][k][1] = a[1][k][1] + 5;
	g5_printf("%d\n", a[1][k][1]);
	// int a[2][3];
	// a[1][2] = 1;
	// g5_printf("%d\n", a[k][2]);
	// a[1][2] += 1;
	// g5_printf("%d\n", a[k][2]);

  return 0;
}
