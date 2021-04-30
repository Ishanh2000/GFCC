# GFCC: Group Five's C Compiler

### About:
CS335A (Compiler Design) Project, Semester 6, 2020-21-II (Jan - Apr 2021).
Official name of compiler will be "gfcc".

Source (S): C.

Implemetation (I): C++.

Target (T): MIPS (might change, if backend can be better implemented on another target).

### Usage:
Building Project:
```bash
  ./runme.sh build     # will generate parser binary in bin/
  ./runme.sh rebuild   # equivalent to "./runme.sh clean && ./runme.sh build"
```
Cleaning Project;
```bash
  ./runme.sh clean         # Will clean all the generated code-related files
  ./runme.sh clean tests   # Will clean all the generated test files (.dot/.ps/.csv/.3ac/.asm)
```
Running parser:
```bash
  ./bin/gfcc ./tests/*.c # Creates {.dot/.csv/.3ac/.asm} files for all test case files
  ./bin/gfcc -h # help
  ./bin/gfcc -v # version
  ./bin/gfcc ./tests/*.c -o out_1.dot out_1.csv out_1.3ac out_1.asm ... out_N.dot out_N.csv out_N.3ac out_N.asm
  ./bin/gfcc ./tests/*.c -t 78 -o out_1.dot out_1.csv out_1.3ac out_1.asm ... out_N.dot out_N.csv out_N.3ac out_N.asm
```

Use help flag for more details.

#### Documentation: https://www.overleaf.com/read/qjpzyjmycknt (may not be updated)

### Participants:
 - Debarsho Sannyasi (180218) - debarsho@iitk.ac.in
 - Ishanh Misra (180313) - imisra@iitk.ac.in
 - Prashant Kumar (180539) - praskr@iitk.ac.in
 - Priyanshu Agrarwal (180559) - priyanag@iitk.ac.in
 - Rwit Panda (180635) - rwit@iitk.ac.in

### Dependecies
 - flex v2.6.4
 - bison v3.0.4 or above
 - cmake v3.10.2 or above
 - gcc v7.5 or above


 ### Misc
  To install cmake-3.18.5 which is used in development (NOTE: Also tested on cmake-3.10.2):
 ```bash
  # Source: https://askubuntu.com/a/865294/884513
  version=3.18
  build=5
  mkdir ~/temp
  cd ~/temp
  wget https://github.com/Kitware/CMake/releases/download/v$version.$build/cmake-$version.$build.tar.gz

  tar -xzvf cmake-$version.$build.tar.gz
  cd cmake-$version.$build/

  ./bootstrap
  make -j$(nproc) # build with multithreading
  sudo make install

  # test
  cmake --version
  which cmake

  # to uninstall cmake
  cd ~/temp
  sudo make uninstall
  rm -r ~/temp
 ```
 
