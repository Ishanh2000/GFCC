int fibo(int n) {
	if(n==1 || n==0) return n;
	return fibo(n-1) + fibo(n-2);
}

int main() {
	int a = fibo(25); //2584
	return 0;
}
