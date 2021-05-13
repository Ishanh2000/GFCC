# GFCC: Group Five's C Compiler

## About:
<!-- ![GFCC Logo](./logo_t.png) -->
<p align="center">
  <img src="./logo_t.png" width="400" margin="200">
</p>

CS335A (Compiler Design) Project, Semester 6, 2020-21-II (Jan - Apr 2021).
Official name of compiler will be "gfcc".

Source (S): C.

Implemetation (I): C++.

Target (T): MIPS (R2000, run on SPIM 8.0)

## Usage:
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
  ./bin/gfcc -h # help
  ./bin/gfcc -v # version
  
  # Creates {.tok.csv/.dot/.sym.csv/.3ac/.asm} files for all test case files
  ./bin/gfcc ./tests/*.c
  
  # specify output files
  ./bin/gfcc ./tests/*.c -o out_1.tok.csv out_1.dot out_1.sym.csv out_1.3ac out_1.asm ... out_N.tok.csv out_N.dot out_N.sym.csv out_N.3ac out_N.asm

  # change tab length
  ./bin/gfcc -t 6 ./tests/*.c -o out_1.tok.csv out_1.dot out_1.sym.csv out_1.3ac out_1.asm ... out_N.tok.csv out_N.dot out_N.sym.csv out_N.3ac out_N.asm

  # specify only required output files (one or more of {tok,ast,sym,3ac,asm})
  ./bin/gfcc -r=tok,asm,sym ./tests/*.c -o out_1.tok.csv out_1.sym.csv out_1.asm ... out_N.tok.csv out_N.sym.csv out_N.asm

  # specify libraries
  ./bin/gfcc -l=typo,math,std,string ./tests/*.c
```

All the flags will work even if output files are not specified Default output file names will be generated. Use help flag for more details.

### Documentation: https://www.overleaf.com/read/qjpzyjmycknt (may not be updated)

## Participants:
 - Debarsho Sannyasi (180218) - debarsho@iitk.ac.in
 - Ishanh Misra (180313) - imisra@iitk.ac.in
 - Prashant Kumar (180539) - praskr@iitk.ac.in
 - Priyanshu Agrarwal (180559) - priyanag@iitk.ac.in
 - Rwit Panda (180635) - rwit@iitk.ac.in

## Dependecies
 - flex v2.6.4
 - bison v3.0.4 or above
 - cmake v3.10.2 or above
 - gcc v7.5 or above
 - spim v8.0

## Misc
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
 
