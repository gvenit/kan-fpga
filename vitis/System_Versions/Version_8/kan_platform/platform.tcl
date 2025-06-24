# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_8\kan_platform\platform.tcl
# 
# OR launch xsct and run below command.
# source D:\Yannos\FILES\PROGRAMS\FPGA\SoC\KAN\gvenit_design\kan-fpga\vitis\System_Versions\Version_8\kan_platform\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {kan_platform}\
-hw {C:\Users\giann\Downloads\axil_ram_bd_wrapper.xsa}\
-proc {ps7_cortexa9_0} -os {standalone} -out {D:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vitis/System_Versions/Version_8}

platform write
platform generate -domains 
platform active {kan_platform}
platform generate
platform config -updatehw {C:/Users/giann/Downloads/kan_pl.xsa}
platform generate -domains 
platform generate -domains 
