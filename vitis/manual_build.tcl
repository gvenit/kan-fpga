xsct

platform create -name KAN_Platform -hw "D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/Hardware_Files/kan-layer-bubble-cycles-80-160-PSclocks.xsa" -out "D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/KAN_Platform"

platform active KAN_Platform

domain list

domain create -name standalone_ps7_cortexa9_0 -os standalone -proc ps7_cortexa9_0
