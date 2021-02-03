# GFCC: Group Five's C Compiler

### About:
CS335A (Compiler Design) Project, Semester 6, 2020-21-II (Jan - Apr 2021).
Official name of compiler will be "gfcc".

### Usage:
```bash
  # will generate lexer binary in bin/
  ./runme.sh  
```

### Participants:
 - Debarsho Sannyasi (180218) - debarsho@iitk.ac.in
 - Ishanh Misra (180313) - imisra@iitk.ac.in
 - Prashant Kumar (180539) - praskr@iitk.ac.in
 - Priyanshu Agrarwal (180559) - priyanag@iitk.ac.in
 - Rwit Panda (180635) - rwit@iitk.ac.in

### TODO:
 - Invite others to this repository privately.
 - [DONE] Make folders "bin", "inc", "obj", "shared_obj", "src", etc. and makefile. Change structure as required.
 - Start working on preprocessor.

### Dependecies
 - flex v2.6.4
 - cmake v3.18.5 or above
 - gcc v7.5 or above


 ### Misc
  To install cmake-3.18.5:
 ```bash
  # Source: https://askubuntu.com/a/865294/884513
  version=3.18
  build=5
  wget https://github.com/Kitware/CMake/releases/download/v$version.$build/cmake-$version.$build.tar.gz

  tar -xzvf cmake-$version.$build.tar.gz
  cd cmake-$version.$build/

  ./bootstrap
  make -j$(nproc) # no. of threads
  sudo make install

  # test
  cmake --version
  which cmake
 ```