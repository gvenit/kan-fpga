import os
import sys

def bin_to_c_header(bin_file_path, header_file_path, array_name="data_array"):
    with open(bin_file_path, "rb") as bin_file:
        byte_data = bin_file.read()
        values = list(byte_data)

    header_guard = os.path.basename(header_file_path).replace(".", "_").upper()

    with open(header_file_path, "w") as header_file:
        header_file.write(f"#ifndef {header_guard}\n")
        header_file.write(f"#define {header_guard}\n\n")

        header_file.write(f"#define {array_name.upper()}_LEN {len(values)}\n")
        header_file.write(f"unsigned char {array_name}[{len(values)}] = {{\n")

        for i, val in enumerate(values):
            if i != len(values) - 1:
                header_file.write(f"    {val},\n")
            else:
                header_file.write(f"    {val}\n")

        header_file.write("};\n\n")
        header_file.write(f"#endif // {header_guard}\n")

    print(f"Header file '{header_file_path}' generated with {len(values)} values.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py input.bin output.h")
    else:
        bin_to_c_header(sys.argv[1], sys.argv[2])
