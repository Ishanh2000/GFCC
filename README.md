# GFCC: Group Five's C Compiler

### About:
CS335A (Compiler Design) Project, Semester 6, 2020-21-II (Jan - Apr 2021).
Official name of compiler will be "gfcc".

Source (S): C.

Implemetation (I): C (maybe C++ later on, if required, especially in case of object orientation).

Target (T): MIPS (might change, if backend can be better implemented on another target).

### Usage:
Building Project:
```bash
  # will generate parser binary in bin/
  ./runme.sh build
```
Cleaning Project;
```bash
  # Will clean all the generated files
  ./runme.sh clean
```
Clean and Build;
```bash
  # Will clean all the generated files and rebuild binary
  ./runme.sh rebuild
```
Running parser:
```bash
  ./bin/lexer ./tests/*.c # Creates dot file for all test case files
  ./bin/lexer -h # help
  ./bin/lexer -v # version
  ./bin/lexer ./tests/*.c -o out1.dot out2.dot out3.dot out4.dot out5.dot
```

Use help flag for more details.

#### Documentation: https://www.overleaf.com/read/qjpzyjmycknt

### Participants:
 - Debarsho Sannyasi (180218) - debarsho@iitk.ac.in
 - Ishanh Misra (180313) - imisra@iitk.ac.in
 - Prashant Kumar (180539) - praskr@iitk.ac.in
 - Priyanshu Agrarwal (180559) - priyanag@iitk.ac.in
 - Rwit Panda (180635) - rwit@iitk.ac.in

### TODO:
 - Try updating repositry to CPP, if required in future.

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
 
