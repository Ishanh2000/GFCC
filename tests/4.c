int foo(int p, int q) {
	if (q == 1) return 10;
	return p + q + 10;
}
int main(int a) {
	int b=1;
	a = 1;
	b = a + foo(b, 1); // 1 + b + 10 + 10
	return 0;
}

int q  = 1-- -48
int p =b -- -44
.
.
.
foo -->fp <--- sp
t4
t3
b
a
.
.
.
main fp
