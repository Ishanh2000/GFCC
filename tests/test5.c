#include <stdio.h>

struct employee
{
	int id;
	char name[100];
	float salary;
	double HIno;
	int lvl;
};

int main()
{
	struct employee E[10];
	for(int i=0;;i++)
	{
		scanf("%d %s %f %ld %d",&E[i].id,E[i].name,&E[i].salary,&E[i].HIno,&E[i].lvl);
		if( i == 9 ) break;
	}
	for(int i=0;i<10;i++)
	{
		if( i == 5 ) continue;
		switch(E[i].lvl)
		{
			case 0 : printf("CEO\n"); break;
			case 1 : printf("Manager\n"); break;
			case 2 : printf("Entry level employee\n"); break;
			default : printf("Wrong lvl input...\n");
		}
	}
	return 0;
}