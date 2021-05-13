// AUM SHREEGANESHAAYA NAMAH|| /* DIETY INVOCATION */

int g5_exit(int);
int g5_atoi(const char *);
void *g5_malloc(int); // requires global hidden data structure
void *g5_free(int); //  requires global hidden data structure (does nothing for now)
void *g5_calloc(int, int); // requires global hidden data structure
// void *g5_realloc(void *, int); // requires global hidden data structure
const int O_RDONLY;
const int O_WRONLY;
const int O_RDWR;
const int O_CREAT;
const int O_APPEND;
// Can create stdio-like procedures (fclose, fopen, fscanf, fprintf) from the following Unix-like syscalls
int g5_open(const char*, int, int); // returns file desciptor : Unix-like syscall (not stdio-like)
int g5_close(int); // return 0 on success, -1 on failure : Unix-like syscall (not stdio-like)
int g5_read(int, const char*, int); // return number of bytes read Unix-like syscall (not stdio-like)
int g5_write(int, const char*, int); // return number of bytes written Unix-like syscall (not stdio-like)

// TODO: time, random, realloc, etc.
// TODO: fopen, fread, fwrite, fclose, etc.
// TODO: open, read, write, close, etc.
