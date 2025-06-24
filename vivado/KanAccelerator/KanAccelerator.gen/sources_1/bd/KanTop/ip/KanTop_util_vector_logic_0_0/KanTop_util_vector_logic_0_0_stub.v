// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
// Date        : Thu Jun 19 17:48:04 2025
// Host        : GV-LAPTOP-LOQ running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top KanTop_util_vector_logic_0_0 -prefix
//               KanTop_util_vector_logic_0_0_ KanTop_util_vector_logic_0_0_stub.v
// Design      : KanTop_util_vector_logic_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z007sclg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "util_vector_logic_v2_0_2_util_vector_logic,Vivado 2022.1" *)
module KanTop_util_vector_logic_0_0(Op1, Res)
/* synthesis syn_black_box black_box_pad_pin="Op1[1:0],Res[1:0]" */;
  input [1:0]Op1;
  output [1:0]Res;
endmodule
