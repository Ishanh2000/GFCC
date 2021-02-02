#! /bin/bash

if [[ !(-d "build") ]]; then
  mkdir build;
fi

ROOT_DIR=$(pwd)

cd build;
cmake ..;
cmake --build .
cmake --install . --prefix $ROOT_DIR
# cd $ROOT_DIR
# rm -r build
