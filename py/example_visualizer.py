import subprocess
import graphviz
import sys

for arg in sys.argv[1:]:
    module_name = arg

    # Parse Verilog file using Yosys
    yosys_cmd = [
        "prep",
        f"read_verilog ../rtl/{module_name}.v",
        f"show -stretch -prefix ../dot/{module_name} -format dot", 
    ]
    subprocess.run(["yosys", "-q", "-p", "; ".join(yosys_cmd)])

    # Generate block diagram using Graphviz
    graphviz_cmd = ["dot", "-Tpng", f"../dot/{module_name}.dot", "-o", f"../graphs/{module_name}.png"]
    subprocess.run(graphviz_cmd)