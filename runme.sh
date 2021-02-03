#! /bin/bash

if [[ !(-d "build") ]]; then
  mkdir build;
fi

ROOT_DIR=$(pwd)
CMAKE="cmake"


cd build;
$CMAKE ..;
$CMAKE --build .
$CMAKE --install . --prefix $ROOT_DIR
