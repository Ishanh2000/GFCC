struct ss{
	int a[5];
	int b;
};

int main() {
	struct ss a[5];
	int i, j;
	for(i = 0; i<5; i++) {
		for(j = 0; j<5; j++) {
			a[i].a[j] = i+j;
		}
		a[i].b = i;
	}

	for(i = 0; i<5; i++) {
		for(j = 0; j<5; j++) {
			g5_printf("%d ", a[i].a[j]);
		}
		g5_printf("\n");
	}
	return 0;
}
