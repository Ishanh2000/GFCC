#include <stdio.h>
#include <stdlib.h>
#include <math.h >      /* For square root function sqrt() */

#define MEM_PRIMES 100  /* Count of number of primes in memory */

/* Function prototypes */
int test_prime(unsigned long N);
void put_primes(void);
int check(unsigned long buffer[], int count, unsigned long N);

/* Global variables */
char myfile[] = "C:\\myfile.bin";                   /* Physical file name    */
FILE *pfile = NULL;                                 /* File pointer          */
unsigned long primes[MEM_PRIMES] = { 2UL,3UL,5UL }; /* Array to store primes */ 
int index = 3;                     /* Index of free location in array primes */
int nrec = 0;                                      /* Number of file records */

void main()
{
  unsigned long trial = 5UL; /* Prime candidate */
  long num_primes = 3L;      /* Prime count     */
  long total = 0L;           /* Total required  */
  int i = 0;                 /* Loop counter    */

  printf("How many primes would you like?  ");
  scanf("%d", &total);      /* Total is how many we need to find */
  total = total<4 ? 4:total;       /* Make sure it is at least 4 */

  /* Prime finding and storing loop */
  while(num_primes < total) /* Loop until we get total required  */
  {
    trial += 2;             /* Next value for checking           */

    if(test_prime(trial))   /* Check if trial is prime           */
    {                       /* Positive value means prime        */
       primes[index++] = trial;  /* so store it                  */
      num_primes++;         /* Increment total number of primes  */

      if(index == MEM_PRIMES) /* Check if array is full          */
      {
        /* File opened OK?   */
        if((pfile = fopen(myfile, "ab")) == NULL)  
        { /* No, so explain and end the program */
          printf("\nUnable to open %s to append\n", myfile);
          abort();
        }
        /* Write the array    */
        fwrite(primes, sizeof(long), MEM_PRIMES, pfile);  

        fclose(pfile);                     /* Close the file */
        index = 0;        /* Reset count of primes in memory */                    
        nrec++;          /* Increment file record count      */                      
      }
    }
  }

  if(total>MEM_PRIMES)   /* If we wrote some to file         */
    put_primes();        /* Display the contents of the file */
  if(index)              /* Display any left in memory       */
    for(i = 0; i<index ; i++)
    {
      if(i%5 == 0)
        printf("\n");              /* Newline after five     */
      printf("%12lu", primes[i]);  /* Output a prime         */
    }

  if(total>MEM_PRIMES)             /* Did we need a file? */
    if(remove(myfile))             /* then delete it.     */
      printf("\nFailed to delete %s\n", myfile); /* Delete failed */
    else
      printf("\nFile %s deleted.\n",myfile);     /* Delete OK     */
}

/************
 * Function to test if a number, N, is prime using primes in       *
 * memory and on file                                              *
 * First parameter N ?value to be tested                          *
 * Return value - a positive value for a prime, zero otherwise     *
 ************/
int test_prime(unsigned long N)
{
   unsigned long buffer[MEM_PRIMES]; /* local buffer for primes from the file */
   
   int i = 0;                        /* Loop counter */                      
   int k = 0;

   if(nrec > 0)         /* Have we written records? */
   {
     if((pfile = fopen(myfile, "rb")) == NULL)  /* Then open the file */
     {
       printf("\nUnable to open %s to read\n", myfile);
       abort();
     }

     for(i = 0; i < nrec ; i++)
     { /* Check against primes in the file first */
       /* Read primes */
       fread(buffer, sizeof(long), MEM_PRIMES, pfile); 
       if((k = check(buffer, MEM_PRIMES, N)) >= 0)   /* Prime or not? */
       {
         fclose(pfile);                     /* Yes, so close the file */
         return k;                          /* 1 for prime, 0 for not */
       }
     }
     fclose(pfile);                         /* Close the file         */
   }

   return check(primes, index, N);  /* Check against primes in memory */
}

/************
 * Function to check whether an integer, N, is divisble by any     *
 * of the elements in the array pbuffer up to the square root of N.*
 * First parameter buffer ?an array of primes                     *
 * second parameter count ?number of elements in pbuffer          *
 * Third parameter N ?the value to be checked                     *
 * Return value - 1 if N is prime, zero if N is not a prime,       *
 *               -1 for more checks                                *
 ************/
int check(unsigned long buffer[], int count, unsigned long N)
{
   int i = 0;                                 /* Loop counter */
   /* Upper limit */
   unsigned long root_N = (unsigned long)(1.0 + sqrt((double)N)); 

   for(i = 0 ; i<count ; i++)
   {
     if(N % buffer[i] == 0UL ) /* Exact division?              */
       return 0;               /* Then not a prime             */

     if(buffer[i] > root_N)    /* Divisor exceeds square root? */
       return 1;               /* Then must be a prime         */
   }
   return  1;                  /* More checks necessary...     */
}

/* Function to output primes from the file */
void put_primes(void)
{
   unsigned long buffer[MEM_PRIMES]; /* Buffer for a block of primes */
   int i = 0;                        /* Loop counter                 */
   int j = 0;                        /* Loop counter                 */
 
   if((pfile = fopen( myfile, "rb"))==NULL) /* Open the file         */
   {
     printf("\nUnable to open %s to read primes for output\n", myfile);
     abort();
   }

   for (i = 0 ; i< nrec ; i++)
   {
     /* Read a block of primes   */
     fread(buffer, sizeof(long), MEM_PRIMES, pfile);  

     for(j = 0 ; j<MEM_PRIMES ; j++)  /* Display the primes */
     {
       if(j%5 == 0)                   /* Five to a line     */
         printf("\n");
       printf("%12lu", buffer[j]);    /* Output a prime     */
     }
   }
   fclose(pfile);                     /* Close the file     */
}