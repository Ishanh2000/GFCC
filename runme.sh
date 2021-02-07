#! /bin/bash

if [[ !(-d "build") ]]; then
  mkdir build
fi

if [[ !(-d "src/generated") ]]; then
  mkdir -p src/generated
fi


ROOT_DIR=$(pwd)
CMAKE="cmake"


cd build
$CMAKE .. -DCMAKE_INSTALL_PREFIX=""
$CMAKE --build .
make DESTDIR=$ROOT_DIR install
# For cmake v3.15+
# $CMAKE --install . --prefix $ROOT_DIR
