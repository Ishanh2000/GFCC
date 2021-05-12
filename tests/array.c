float foo(float a[][3]) {
	// int b[5] = a;
	return a[0][1];
}

int main() {
	float a[5] = {1, 2, 3, 4, 5};
	float b[5] = {1,2,3,4,5}, c[5] = {1,2,3,4,5};
	int d;
	float aa[2][3] = {{1, 2, 0.3}, {4,5,6}};
	// d = aa[1][1];
	g5_printf("%f\n", aa[0][0]);
	// a[2] = -1;
	// d = a[2];
	// a[1] = b[4];
	// a[2] = b[3] + c[4];
	// aa[0][1] = c[3] * b[1]; // 4 * 2 = 8
	d = foo(aa);
	g5_printf("asgasdg\n");
	g5_printf("%d %d\n", d, 1);

	return 0;
}
