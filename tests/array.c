int foo(int a[][3]) {
	// int b[5] = a;
	return a[0][1];
}

int main() {
	int a[5] = {1,2,3,4,5}, b[5] = {1,2,3,4,5}, c[5] = {1,2,3,4,5}, d;
	// int d;
	int aa[2][3] = {{1,2,3}, {4,5,6}};
	// d = aa[1][1];
	// g5_printf("%d\n", aa[1][1]);
	// a[2] = -1;
	// d = a[2];
	// a[1] = b[4];
	// a[2] = b[3] + c[4];
	aa[0][1] = c[3] * b[1]; // 4 * 2 = 8
	g5_printf("%d\n", foo(aa));
	return 0;
}
