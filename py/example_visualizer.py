import subprocess
import graphviz

# Parse Verilog file using Yosys
yosys_cmd = ["yosys", "-q", "-p", "read_verilog", "../rtl/AXISSplitter.v"]
subprocess.run(yosys_cmd)

# Extract necessary information (e.g., module hierarchy, connections)
# from Yosys output

# Create Graphviz graph definition file (DOT language)
dot_file = "../dot/block_diagram.dot"
with open(dot_file, "w") as f:
    f.write("digraph block_diagram {\n")
    # Add nodes and edges to the graph definition file
    f.write("}\n")

# Generate block diagram using Graphviz
graphviz_cmd = ["dot", "-Tpng", dot_file, "-o", "../graphs/AXISSplitter.png"]
subprocess.run(graphviz_cmd)