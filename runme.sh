#! /bin/bash

if [[ !(-d "build") ]]; then
  mkdir build;
fi

if [[ !(-d "src/generated") ]]; then
  mkdir -p src/generated;
fi


ROOT_DIR=$(pwd)
CMAKE="cmake"


cd build;
$CMAKE ..;
$CMAKE --build .
$CMAKE --install . --prefix $ROOT_DIR
