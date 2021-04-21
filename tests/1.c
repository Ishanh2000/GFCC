



int main() {
    int a = 2, b = 5;
    switch(a+2)
    {
        case b-4 : a = 3;
        case 2 : {a = 4; break;}
        case 4 : 
        {
            switch(b)
            {
                case 132 : {b = 5;}
                default : b = 7; 
            }
        }
        default : a = 10;
    }
}

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