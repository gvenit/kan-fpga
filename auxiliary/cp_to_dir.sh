#!/bin/sh

PARAMS=""  # to store positional arguments

dryrun=0
verbose=0
purge=0
update=""

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
    echo "      cp_to_dir.sh [-h] [-d] [-v] <target-top-dir>" 
    echo
    echo DESCRIPTION
    echo "      Copy project to the specified Top Directory. If the project already exists in the target directory, the script updates the project files and folders."
    echo "      Only one of \`--purge\` and \`--update\` flags can be set. If both are present, the first flag is overwritten."
    echo
    echo Parameters
    echo "      -h                     Prints out help"
    echo "      -d, --dryrun           Dry run of the script"
    echo "      -v, --verbose          Prints the to be executed commands"
    echo "      -p, --purge            Purges any copies of the project on the target directory before copying"
    echo "      -u, --update           Update existing files only when newer versions exist"   
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
        # -b|--my-flag-with-argument) 
        #   if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        #     MY_FLAG_ARG=$2; shift 2
        #   else
        #     echo "Error: Argument for $1 is missing" >&2; exit 1
        #   fi ;;
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
usb_path=$(realpath "$1/$(basename $pc_path)")  # path/to/usb/top/directory/kan-fpga

# echo $(realpath "$(dirname $0)")
# echo $pc_path
# echo $usb_path

if [ "$1" = "" ];then
    echo Please provide a value for positional argument [1] \(path to target top directory\)
    exit 1;
elif [ ! -d $1 ]; then
    echo The provided USB Top Directory does not exist. Please provide a valid path to the USB device.
    echo -- Provided path : \"$1\"
    exit 1;
fi

if [ ! -d $usb_path ]; then
    temp=$PWD
    print_exec cd $(dirname $usb_path)
    print_exec mkdir $(basename $usb_path);
    print_exec cd $temp
elif [ $purge -ge 1 ]; then
    print_verbose A copy of the project found in the target directory is to be deleted.
    print_exec rm -r "$usb_path/*"
fi

if [ -d $pc_path ]; then
    for subpath in $pc_path/*; do
        subdir=$(basename $subpath)

        case $subdir in
            *"env"*)
                print_exec mkdir -p "$usb_path/$subdir"
                print_exec "pip freeze > \"$usb_path/$subdir/requirements.txt\""
                ;;
            *)
                print_exec cp -r -L $update $subpath "$usb_path/";
                ;;
        esac
    done;
fi