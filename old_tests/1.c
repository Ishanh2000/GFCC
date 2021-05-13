// int main() {
    
//     return 0;
// }

int main() {
    int a = 10;
    int b = (2*4) + ((2+3) + ((1 + 2)+ (2-(a + a)) * 10));
    goto idt;
    b = (2*4) + ((2+3) + ((1 + 2)+ (2-(a + a)) * 10));
    // int b = (2*4) + ((2+3) + ((1 + 2)+ (2-(a + a)) * 10));
    idt: a = 1;
    b = (2*4) + ((2+3) + ((1 + 2)+ (2-(a + a)) * 10));
    // {
    //     int b = 10;
    //     int a = 1;
    //     a = a+b;
    //     return 0;
    // }
    goto idt;
    return 0;
}
// @ x{
//   int b = 10;
//   int a = 1;
//   a = a+b;
//   return 0;
// }

// int a, b ,c;

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