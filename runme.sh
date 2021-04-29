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
    $CMAKE --build . -j$(nproc)
    make DESTDIR=$ROOT_DIR install
    # For cmake v3.15+
    # $CMAKE --install . --prefix $ROOT_DIR
}

function clean {
    if [[ $1 = "tests" ]] && [[ -d "tests" ]]; then
        echo "Cleaning tests..."
        rm -f tests/*.{csv,dot,ps,s,3ac}
        return
    fi

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

function dpdf {
    dot -Tpdf tests/$1.dot -o tests/$1.pdf && xdg-open tests/$1.pdf
}

function dps {
    dot -Tps tests/$1.dot -o tests/$1.ps && xdg-open tests/$1.ps
}

#  main

# *please run in root directory only
ROOT_DIR=$(pwd)
CMAKE="cmake"

cmd="$(tr [A-Z] [a-z] <<< $1)"

case $cmd in

    build | rebuild)
        $cmd
        ;;

    clean)
        $cmd $2
        ;;

    pdf | ps)
        d$1 $2
        ;;

    *)
        echo "Usage: $0 [build|clean|rebuild|ps <test#>|pdf <test#>]"
        ;;
esac
