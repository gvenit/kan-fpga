# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_0\KAN_SoC\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_0\KAN_SoC\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {KAN_SoC}\
-hw {D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vivado\vivado_22.2\KAN_SoC\KAN_SoC.hardware_exports\KAN_SoC.xsa}\
-out {D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/System_Versions/Version_0}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {KAN_SoC}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform active {KAN_SoC}
platform active {KAN_SoC}
platform active {KAN_SoC}
platform active {KAN_SoC}
platform config -updatehw {C:/Users/giann/Downloads/kan-2x2x1-80MHz-160MHz.xsa}
platform generate
platform active {KAN_SoC}
platform generate -domains 
platform clean
platform generate
platform clean
platform generate
platform active {KAN_SoC}
platform generate -domains 
platform generate -domains 
platform generate -domains 
platform active {KAN_SoC}
platform generate -domains 
platform clean
platform config -updatehw {C:/Users/giann/Downloads/kan-2x2x1-80MHz-160MHz.xsa}
platform generate
platform generate
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
platform generate
platform clean
platform generate
