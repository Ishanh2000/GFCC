int a = 1;
int main();

int foo(){
	a++;
	if(a<10) main();
	return 1;
}

int main(){
	// int b = a;
	g5_printf("%p\n", main);
	foo();
	return 0;
}
