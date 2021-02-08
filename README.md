# GFCC: Group Five's C Compiler

### About:
CS335A (Compiler Design) Project, Semester 6, 2020-21-II (Jan - Apr 2021).
Official name of compiler will be "gfcc".

Source (S): C.
Implemetation (I): C (maybe C++ later on, if required, especially in case of object orientation).
Target (T): ??

### Usage:
Building Project:
```bash
  # will generate lexer binary in bin/
  ./runme.sh  
```

Running lexer:
```bash
  ./bin/lexer ./tests/*.c # test cases
  ./bin/lexer -h # help
  ./bin/lexer -v # version
  ./bin/lexer ./tests/*.c -o out1.txt out2.txt out3.txt out4.txt out5.txt
  ./bin/lexer -c ./tests/*.c	# colorized output (only on terminal)
  ./bin/lexer -b ./tests/*.c	# brevity/conciseness
  ./bin/lexer -t 9 ./tests/*.c	# change tab length (default = 8)
```

Note: All files will not be jeopardized due to failure in opening a few files.
Use "-h" flag for more knowing options. Bad characters are reported, but
lexical analysis is carried on. Pre-processor directives / macros ignored.

Use help flag for more details.

### Participants:
 - Debarsho Sannyasi (180218) - debarsho@iitk.ac.in
 - Ishanh Misra (180313) - imisra@iitk.ac.in
 - Prashant Kumar (180539) - praskr@iitk.ac.in
 - Priyanshu Agrarwal (180559) - priyanag@iitk.ac.in
 - Rwit Panda (180635) - rwit@iitk.ac.in

### TODO:
 - Decide Target Language.
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
 
