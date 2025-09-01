# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_15\kan_pl\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_15\kan_pl\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {kan_pl}\
-hw {D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\Hardware_Files\mixed16_4x4x1_wrapper.xsa}\
-out {D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/System_Versions/Version_15}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {kan_pl}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
platform clean
platform generate
platform generate -domains 
