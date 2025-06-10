# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_4\smaller_name\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_4\smaller_name\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {smaller_name}\
-hw {D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\Hardware_Files\smaller_name.xsa}\
-out {D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/System_Versions/Version_4}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {smaller_name}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
