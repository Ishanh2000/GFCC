int main() {
    int a, b;
    if(1){
        a = 1;
    }
    else {
        b = 1;
    }
    main();
    {
        int main(int);
        int r = main(12) + 90;
    }
    return 0;
}
