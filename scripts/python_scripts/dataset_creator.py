import os
import argparse

###################################
# Functions
###################################

def create_sourcefile (
        dataset, 
        file_path,
        array_name="data_array"
    ):
    '''
    Args:
        dataset (list) : a list of the datasets to become a header file array
        file_path (path) : the path with the name of the header file to be created
        array_name (str) : the name of the C array that will contain the data
    '''
    # with open(bin_file_path, "rb") as bin_file:
    #     byte_data = bin_file.read()
    #     values = list(byte_data)

    header_inc = os.path.basename(file_path).replace(".c", ".h")
    section = os.path.splitext(os.path.basename(header_inc))[0]

    with open(file_path, "w") as source_file:
        source_file.write(f"#include \"{header_inc}\"\n\n")
        source_file.write(f"__attribute__((section(\".{section}\"), aligned(4), used))\n")

        source_file.write(f"data_t {array_name}[] = {{\n")

        for i, val in enumerate(dataset):
            if i != len(dataset) - 1:
                source_file.write(f"    {val},\n")
            else:
                source_file.write(f"    {val}\n")

        source_file.write("};\n\n")

    print(f"Source file '{file_path}' generated with {len(dataset)} values.")

def create_headerfile (
        dataset, 
        file_path,
        array_name="data_array"
    ):
    '''
    Args:
        dataset (list) : a list of the datasets to become a header file array
        file_path (path) : the path with the name of the header file to be created
        array_name (str) : the name of the C array that will contain the data
    '''
    # with open(bin_file_path, "rb") as bin_file:
    #     byte_data = bin_file.read()
    #     values = list(byte_data)

    header_guard = os.path.basename(file_path).replace(".", "_").upper()
    header_guard = "_" + header_guard + "_"

    with open(file_path, "w") as header_file:
        header_file.write(f"#ifndef {header_guard}\n")
        header_file.write(f"#define {header_guard}\n\n")

        header_file.write(f"#define {array_name.upper()}_LEN {len(dataset)}\n")
        header_file.write(f"unsigned char {array_name}[{len(dataset)}] = {{\n")

        for i, val in enumerate(dataset):
            if i != len(dataset) - 1:
                header_file.write(f"    {val},\n")
            else:
                header_file.write(f"    {val}\n")

        header_file.write("};\n\n")
        header_file.write("#endif")

    print(f"Header file '{file_path}' generated with {len(dataset)} values.")

def bin_to_c_file (
        bin_file_path,
        file_path,
        array_name="data_array"
    ):
    '''
    **Warning** : it reads raw files and interprets each byte as a single data
    
    Args:
        bin_file_path (path) : path to a .bin a .raw dataset
        file_path (path) : the path with the name of the header file to be created
        array_name (str) : the name of the C array that will contain the data
    '''
    with open(bin_file_path, "rb") as bin_file:
        byte_data = bin_file.read()
        values = list(byte_data)

    create_sourcefile(values, file_path, array_name)

def enumlist_to_c_file (
        size,
        file_path,
        array_name="data_array"
    ):
    '''
    Args:
        size (int) : teh size of the dataset list
        file_path (path) : the path with the name of the header file to be created
        array_name (str) : the name of the C array that will contain the data
    '''
    values = list(range(size))

    create_sourcefile(values, file_path, array_name)

def constlist_to_c_file (
        constant,
        size,
        file_path,
        array_name="data_array"
    ):
    '''
    Args:
        constant (int) : the constant value of each element
        size (int) : teh size of the dataset list
        file_path (path) : the path with the name of the header file to be created
        array_name (str) : the name of the C array that will contain the data
    '''
    values = [constant] * size

    create_sourcefile(values, file_path, array_name)


###################################
# Parser config
###################################

parser = argparse.ArgumentParser(prog='dataset_crator', description='Create C file with a dataste as an array from interger datasets')

parser.add_argument(
    'filename',
    help='the name of the created file'
)
parser.add_argument(
    'arrayname',
    help='the name of the C array that will store the dataset in the C file'
)

parser.add_argument(
    '--outdir', '-o',
    action='store',
    help='Specify output dir for generated file. Else it is just the root of this script'
)
parser.add_argument(
    '--raw', '-r',
    action='store',
    help='input as datasets a .raw or .bin file. Otherwise the dataset will be a list of ascending values'
)
parser.add_argument(
    '--size', '-s',
    action='store',
    help='the size of the dataset that will be a list of ascending values (used only if --raw not specified)'
)
parser.add_argument(
    '--constant', '-c',
    action='store',
    help='the size of the dataset that will be a list of constant values (used only if --raw not specified and if --size not specified)'
)

###################################
# Main function
###################################

if __name__ == "__main__":

    args = parser.parse_args()

    if args.raw is None:
        if args.size is None:
            parser.error('You have to specify --size when you do not specify --raw')
    else:
        if args.size is not None or args.constant is not None:
            parser.error('If using --raw do not use --size or --constant')

    filename = args.filename
    arrayname = args.arrayname

    if args.outdir:
        filedir = args.outdir
        if not os.path.exists(filedir):
            os.makedirs(filedir)
        filepath = os.path.join(filedir, filename)
    else:
        filepath = filename

    
    if args.raw:
        rawpath = args.raw
        bin_to_c_file(rawpath, filepath, arrayname)
    else:
        size = int(args.size)
        if args.constant:
            constant = int(args.constant)
            constlist_to_c_file(constant, size, filepath, arrayname)
        else:
            enumlist_to_c_file(size, filepath, arrayname)