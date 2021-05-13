#include <g5_typo.h>
#include <g5_std.h>
struct aa {
	int a;
	char b;
	int c[10];
};

int main() {
	int a = 10,b = 3;
	float x = 1.0, y = 2.0;
	x != y;
	// a = -(-(-x));
	g5_printf("%d\n", !(a == b));
	return 0;
}
