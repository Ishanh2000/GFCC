#include <g5_typo.h>
#include <g5_std.h>
#include <g5_string.h>

struct g5_file_t {
  int fd;
};

struct file_t* g5_fopen(const char *fname, const char* mode) {
  int flags = 0x0;
  int _l = g5_strlen(mode);
  int i;
  struct g5_file_t* f;

  for (i = 0; i < _l; i++) {
    if (mode[i] == 'r') flags |= O_RDONLY;
    if (mode[i] == 'w') flags |= O_WRONLY;
  }
  f = g5_malloc(sizeof(struct g5_file_t));
  f->fd = g5_open(fname, flags, 0644);
}

int g5_fprintf(struct g5_file_t *f, const char* str) { // no support for variadic statements
  return g5_write(f->fd, str, g5_strlen(str));
}


int main() {
  
  char fName[100];
  struct g5_file_t* f;

  /************ WRITING TO A FILE ************/
  g5_printf("Enter a file name (max 100 characters): ");
	g5_scanf("%s", fName); // got the file name

  f = g5_fopen(fName, "rw");

  g5_fprintf(f, "Hello World\n");  
  
	return 0;
}