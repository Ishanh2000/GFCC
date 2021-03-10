#include <stdio.h>

char func(int,float*);
int main()
{
	int ii;
	for(ii=0;ii<10;ii++)
	{
		float e = 109.09;
		float *r = &e;
		if( func(8,r) == 'a' )
		{
			switch(ii)
			{
				case 2 : goto good;
				default : printf("Hi\n");
			}
		}
		else
		{
			const int g = 100;
			g++;
			while(g)
			{
				printf("do");
				g--;
			}
		}
		good : ;
	}
	return 0;
}

char func(int a, float *f)
{
	return a + *f;
}
