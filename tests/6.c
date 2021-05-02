int main() {
	int a = 10, b = 0;
	switch(a+1+b-1) {
		case 1: {b = 10; break;}
		case 2: {b = 20; break;}
		default: b = 1;
	}
	return b;
}
