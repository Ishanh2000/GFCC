#! /bin/bash

function build {
    echo "Building and installing..."
    
    if [[ !(-d "build") ]]; then
    mkdir build
    fi

    if [[ !(-d "src/generated") ]]; then
    mkdir -p src/generated
    fi

    if [[ !(-d "src/include/generated") ]]; then
    mkdir -p src/include/generated
    fi

    cd build
    $CMAKE .. -DCMAKE_INSTALL_PREFIX=""
    $CMAKE --build .
    make DESTDIR=$ROOT_DIR install
    # For cmake v3.15+
    # $CMAKE --install . --prefix $ROOT_DIR
}

function clean {
    echo "Cleaning..."
    
    if [[ -d "build" ]]; then
        rm -r build
    fi

    if [[ -d "src/generated" ]]; then
        rm -r src/generated
    fi

    if [[ -d "src/include/generated" ]]; then
        rm -r src/include/generated
    fi
}

function rebuild {
    clean
    build
}

#  main

# *please run in root directory only
ROOT_DIR=$(pwd)
CMAKE="cmake"

cmd="$(tr [A-Z] [a-z] <<< $1)"

case $cmd in

    build | clean | rebuild)
        $cmd
        ;;

    *)
        echo "Usage: $0 [build|clean|rebuild]"
        ;;
esac
