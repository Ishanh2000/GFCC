int a = 1;
float b = 2.0;
int main();

int foo(){
	a++;
	if(a<10) main();
	return 1;
}

int main(){
	// int b = a;
	g5_printf("%d %f\n", a, b);
	foo();
	return 0;
}
