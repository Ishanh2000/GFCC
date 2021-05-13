#include <g5_typo.h>
#include <g5_std.h>
#include <g5_string.h>

int main() {
  char fName[100];
  int fd;
  int readAmount;
  char buf[200];

  /************ READING FROM A FILE ************/

	g5_printf("\033[1;35mPlease enter a file name (max 100 characters): \033[0;33m");
	g5_scanf("%s", fName); // got the file name

  // Use O_RDONLY
  fd = g5_open(fName, 0, 0644); // rw-r--r-- permissions
	g5_printf("File Descriptor for file \"%s\": %d\n", fName, fd);
  
  if (fd > 0) {
    g5_printf("File opened successfully!\n");
  
    g5_printf("\033[1;35mPlease how many character to read (max 200 characters): \033[0;33m");
    g5_scanf("%d", &readAmount);
    
    g5_printf("g5_read(...) = %d, buf = \"%s\"\n", g5_read(fd, buf, readAmount), buf);


  } else g5_printf("Error opening file!\n");

  g5_printf("g5_close(fd) = %d\n", g5_close(fd));

  g5_printf("\n");

  /************ WRITING TO A FILE ************/

  g5_printf("\033[1;35mPlease enter a file name (max 100 characters): \033[0;33m");
	g5_scanf("%s", fName); // got the file name

  // Use O_WRONLY
  fd = g5_open("abc", 1, 0666); // rw-rw-rw- permissions
	g5_printf("File Descriptor for file \"%s\": %d\n", fName, fd);
  
  if (fd > 0) {
    int writeAmount;
    g5_printf("File opened successfully!\n");
  
    g5_printf("\033[1;35mPlease specify what to write (max 200 characters) : \033[0;33m");
    g5_scanf("%s", buf);

    writeAmount = g5_strlen(buf);
    g5_printf("g5_write(...) = %d\n", g5_write(fd, buf, writeAmount));

  } else g5_printf("Error opening file!\n");

  g5_printf("g5_close(fd) = %d\n", g5_close(fd));

	return 0;
}