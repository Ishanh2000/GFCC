// float func(int a, char b);

struct _y { int x; int y; char z; } d; // 9 - 12

struct _x { int x; struct _y l; int y; char z; } p; // 18 - 12+20 = 32

union _f { char f0; int f1; float *f2; };

int main() {
    char str[][4] = {{'H', 'e', '\0', 'l'}, {'B','y', 'e' ,'\0'}};
    str[9][4] = 90;
    // char str[] = "H\"\\ello";
    // int gl[][4] = { {1, 2,}, {3}};
    // char c = '∞';
    // int a = 10;
    // a++;
    // {
    //     int p,q,r;
    // }
    // {
    //     int x,y,z;
    //     struct _x g;
    // }
    // switch (a+1) {
    //     case 2: a =1;
    //     case 3: a =1;
    // }
    // return a;
    return 0;
}

int a, b ,c;

// int main() {
    // int a = 2, b = 5;
    // switch(a+2)
    // {
    //     case b-4 : a = 3;
    //     case 2 : {a = 4; break;}
    //     case 4 : 
    //     {
    //         switch(b)
    //         {
    //             case 132 : {b = 5;}
    //             default : b = 7; 
    //         }
    //     }
    //     default : a = 10;
    // }
    // {
        // int a[6][5][3][2][11], b;

        // b = -9 + ++(a[3][3][2][1][1]);

        // b = (a-1)[2][3][+1][1][1] + +b;
        // int maina;
        // maina + 1;
        // sizeof(maina) + 1;
        // sizeof - maina + sizeof(main);
        // main();
        // {
        //     char f = 'm';
        //     func(6, f) + 56;
        //     {
        //         int f = 90;
        //         f += 9.0;
        //     }

        // }
    // }
    // typedef struct _nt { struct { int x; int y; } *x; int y; } nt;
    // nt* a;

    // a->x++;

    // if (!a->x) main();

    // *&*&*&*&*&*&*&*&a->x;
//     int a, i;
//     a = a + 9;

//     for (i = 0; i < 90; i++) {
//         int a = 90;
//         a++;
//     }
//     return 0;
// }

// int f(int a,int b)
// {
//     a = b;
//     return a;
// }
// int main()
// {
//     int a,b;
//     int c = f(a,b);
//     return 0;
// }