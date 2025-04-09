#!/bin/sh

PARAMS=""  # to store positional arguments

dryrun=0
verbose=0
purge=0

dry_run () {
    if [ $dryrun -lt 1 ]; then
        eval "$*";
    fi
}
print_verbose () {
    if [ $verbose -ge 1 ]; then
        echo "$*";
    fi;
}
print_exec () {
    print_verbose -- "$*";
    dry_run "$*";
}
usage () {
    echo NAME
    echo "      run_sim.sh [-h] [-d] [-v] <top_module> [:<top_modules>]" 
    echo
    echo DESCRIPTION
    echo "      Compiles and executes the simutalion for the proviced testbench."
    echo
    echo Parameters
    echo "      -h                     Prints out help"
    echo "      -d, --dryrun           Dry run of the script"
    echo "      -v, --verbose          Prints the to be executed commands"
    echo "      -p, --purge            Purges any existing output files before generating them"
}

while [ "$#" -gt 0 ] ; do
    case "$1" in
        -h|--help) 
            usage
            exit 0 ;;
        -d|--dry-run) 
            dryrun=1
            verbose=1
            shift ;;
        -v|--verbose) 
            verbose=1
            shift ;;
        -p|--purge) 
            purge=1
            update=""
            shift ;;
        -u|--update) 
            purge=0
            update="-u"
            shift ;;
        -*|--*=)  # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1 ;;
        *)  # preserve positional arguments
            PARAMS="$PARAMS $1"
            shift ;;
    esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

pc_path=$(dirname $(realpath "$(dirname $0)"))              # path/to/pc/top/directory/kan-fpga

print_exec cd $pc_path

while [ $1 ] ; do 
    module=$1

    if [ -e $(realpath -q "./rtl/$module.v") ]; then
        module="tb_$module"
    fi
    if [ -e $(realpath -q "./tb/$module.v") ]; then
        if [ $purge -ge 1 ]; then
            if [ -e $(realpath -q "./out/$module.out") ]; then
                print_exec rm "./out/$module.out"
            fi
            if [ -e $(realpath -q "./vcd/$module.vcd") ]; then
                print_exec rm -r "./vcd/$module.vcd"
            fi
        fi
        lib_path="./lib"

        LIB_RESOURCES="-y ./rtl -y ./rtl/wrapper"
        for lib_path_i in $lib_path/*/rtl; do
            LIB_RESOURCES="$LIB_RESOURCES -y $lib_path_i"
        done

        print_exec iverilog $LIB_RESOURCES -Wall -o "./out/$module.out" "./tb/$module.v"
        print_exec vvp $( [ verbose ] && echo -v ) -n "./out/$module.out"
        print_verbose -- Done
    else
        echo Module $module not found in testbench folder.
    fi
    shift;
done
