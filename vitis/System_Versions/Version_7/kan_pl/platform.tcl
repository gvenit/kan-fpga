# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_7\kan_pl\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_7\kan_pl\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {kan_pl}\
-hw {D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\Hardware_Files\slightly_bigger_small_design.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/System_Versions/Version_7}

platform write
platform generate -domains 
platform active {kan_pl}
platform generate
platform active {kan_pl}
platform generate -domains 
