// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
// Date        : Sun May 18 22:15:41 2025
// Host        : yannos running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Yannos/FILES/PROGRAMS/FPGA/SoC/KAN/gvenit_design/kan-fpga/vivado/vivado_22.2/KAN_SoC/KAN_SoC.gen/sources_1/bd/design_1/ip/design_1_KanLayerInst_0_0/design_1_KanLayerInst_0_0_stub.v
// Design      : design_1_KanLayerInst_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z007sclg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "KanLayerInst,Vivado 2022.2" *)
module design_1_KanLayerInst_0_0(fsm_clk, fsm_rst, core_clk, core_rst, dma_clk, 
  dma_rst, operation_busy, operation_complete, operation_error, locked, pl2ps_intr, 
  bram00_ctrl_data_clk, bram00_ctrl_data_rst, bram00_ctrl_data_en, bram00_ctrl_data_we, 
  bram00_ctrl_data_addr, bram00_ctrl_data_din, bram00_ctrl_data_dout, s_axil_grid_aclk, 
  s_axil_grid_areset, s_axil_grid_awaddr, s_axil_grid_awprot, s_axil_grid_awvalid, 
  s_axil_grid_awready, s_axil_grid_wdata, s_axil_grid_wstrb, s_axil_grid_wvalid, 
  s_axil_grid_wready, s_axil_grid_bresp, s_axil_grid_bvalid, s_axil_grid_bready, 
  s_axil_grid_araddr, s_axil_grid_arprot, s_axil_grid_arvalid, s_axil_grid_arready, 
  s_axil_grid_rdata, s_axil_grid_rresp, s_axil_grid_rvalid, s_axil_grid_rready, 
  s_axil_scle_aclk, s_axil_scle_areset, s_axil_scle_awaddr, s_axil_scle_awprot, 
  s_axil_scle_awvalid, s_axil_scle_awready, s_axil_scle_wdata, s_axil_scle_wstrb, 
  s_axil_scle_wvalid, s_axil_scle_wready, s_axil_scle_bresp, s_axil_scle_bvalid, 
  s_axil_scle_bready, s_axil_scle_araddr, s_axil_scle_arprot, s_axil_scle_arvalid, 
  s_axil_scle_arready, s_axil_scle_rdata, s_axil_scle_rresp, s_axil_scle_rvalid, 
  s_axil_scle_rready, s_axil_ctrl_awaddr, s_axil_ctrl_awprot, s_axil_ctrl_awvalid, 
  s_axil_ctrl_awready, s_axil_ctrl_wdata, s_axil_ctrl_wstrb, s_axil_ctrl_wvalid, 
  s_axil_ctrl_wready, s_axil_ctrl_bresp, s_axil_ctrl_bvalid, s_axil_ctrl_bready, 
  s_axil_ctrl_araddr, s_axil_ctrl_arprot, s_axil_ctrl_arvalid, s_axil_ctrl_arready, 
  s_axil_ctrl_rdata, s_axil_ctrl_rresp, s_axil_ctrl_rvalid, s_axil_ctrl_rready, 
  s_axis_wght_tdata, s_axis_wght_tkeep, s_axis_wght_tvalid, s_axis_wght_tready, 
  s_axis_wght_tlast, s_axis_wght_tid, s_axis_wght_tdest, s_axis_wght_tuser, 
  m_axis_rslt_tdata, m_axis_rslt_tkeep, m_axis_rslt_tvalid, m_axis_rslt_tready, 
  m_axis_rslt_tlast, m_axis_rslt_tid, m_axis_rslt_tdest, m_axis_rslt_tuser)
/* synthesis syn_black_box black_box_pad_pin="fsm_clk,fsm_rst,core_clk,core_rst,dma_clk,dma_rst,operation_busy,operation_complete,operation_error,locked,pl2ps_intr,bram00_ctrl_data_clk,bram00_ctrl_data_rst,bram00_ctrl_data_en,bram00_ctrl_data_we[3:0],bram00_ctrl_data_addr[12:0],bram00_ctrl_data_din[31:0],bram00_ctrl_data_dout[31:0],s_axil_grid_aclk,s_axil_grid_areset,s_axil_grid_awaddr[4:0],s_axil_grid_awprot[2:0],s_axil_grid_awvalid,s_axil_grid_awready,s_axil_grid_wdata[31:0],s_axil_grid_wstrb[3:0],s_axil_grid_wvalid,s_axil_grid_wready,s_axil_grid_bresp[1:0],s_axil_grid_bvalid,s_axil_grid_bready,s_axil_grid_araddr[4:0],s_axil_grid_arprot[2:0],s_axil_grid_arvalid,s_axil_grid_arready,s_axil_grid_rdata[31:0],s_axil_grid_rresp[1:0],s_axil_grid_rvalid,s_axil_grid_rready,s_axil_scle_aclk,s_axil_scle_areset,s_axil_scle_awaddr[4:0],s_axil_scle_awprot[2:0],s_axil_scle_awvalid,s_axil_scle_awready,s_axil_scle_wdata[31:0],s_axil_scle_wstrb[3:0],s_axil_scle_wvalid,s_axil_scle_wready,s_axil_scle_bresp[1:0],s_axil_scle_bvalid,s_axil_scle_bready,s_axil_scle_araddr[4:0],s_axil_scle_arprot[2:0],s_axil_scle_arvalid,s_axil_scle_arready,s_axil_scle_rdata[31:0],s_axil_scle_rresp[1:0],s_axil_scle_rvalid,s_axil_scle_rready,s_axil_ctrl_awaddr[12:0],s_axil_ctrl_awprot[2:0],s_axil_ctrl_awvalid,s_axil_ctrl_awready,s_axil_ctrl_wdata[31:0],s_axil_ctrl_wstrb[3:0],s_axil_ctrl_wvalid,s_axil_ctrl_wready,s_axil_ctrl_bresp[1:0],s_axil_ctrl_bvalid,s_axil_ctrl_bready,s_axil_ctrl_araddr[12:0],s_axil_ctrl_arprot[2:0],s_axil_ctrl_arvalid,s_axil_ctrl_arready,s_axil_ctrl_rdata[31:0],s_axil_ctrl_rresp[1:0],s_axil_ctrl_rvalid,s_axil_ctrl_rready,s_axis_wght_tdata[63:0],s_axis_wght_tkeep[7:0],s_axis_wght_tvalid,s_axis_wght_tready,s_axis_wght_tlast,s_axis_wght_tid[0:0],s_axis_wght_tdest[0:0],s_axis_wght_tuser[0:0],m_axis_rslt_tdata[63:0],m_axis_rslt_tkeep[7:0],m_axis_rslt_tvalid,m_axis_rslt_tready,m_axis_rslt_tlast,m_axis_rslt_tid[0:0],m_axis_rslt_tdest[0:0],m_axis_rslt_tuser[0:0]" */;
  input fsm_clk;
  input fsm_rst;
  input core_clk;
  output core_rst;
  input dma_clk;
  input dma_rst;
  output operation_busy;
  output operation_complete;
  output operation_error;
  output locked;
  output pl2ps_intr;
  input bram00_ctrl_data_clk;
  input bram00_ctrl_data_rst;
  input bram00_ctrl_data_en;
  input [3:0]bram00_ctrl_data_we;
  input [12:0]bram00_ctrl_data_addr;
  input [31:0]bram00_ctrl_data_din;
  output [31:0]bram00_ctrl_data_dout;
  input s_axil_grid_aclk;
  input s_axil_grid_areset;
  input [4:0]s_axil_grid_awaddr;
  input [2:0]s_axil_grid_awprot;
  input s_axil_grid_awvalid;
  output s_axil_grid_awready;
  input [31:0]s_axil_grid_wdata;
  input [3:0]s_axil_grid_wstrb;
  input s_axil_grid_wvalid;
  output s_axil_grid_wready;
  output [1:0]s_axil_grid_bresp;
  output s_axil_grid_bvalid;
  input s_axil_grid_bready;
  input [4:0]s_axil_grid_araddr;
  input [2:0]s_axil_grid_arprot;
  input s_axil_grid_arvalid;
  output s_axil_grid_arready;
  output [31:0]s_axil_grid_rdata;
  output [1:0]s_axil_grid_rresp;
  output s_axil_grid_rvalid;
  input s_axil_grid_rready;
  input s_axil_scle_aclk;
  input s_axil_scle_areset;
  input [4:0]s_axil_scle_awaddr;
  input [2:0]s_axil_scle_awprot;
  input s_axil_scle_awvalid;
  output s_axil_scle_awready;
  input [31:0]s_axil_scle_wdata;
  input [3:0]s_axil_scle_wstrb;
  input s_axil_scle_wvalid;
  output s_axil_scle_wready;
  output [1:0]s_axil_scle_bresp;
  output s_axil_scle_bvalid;
  input s_axil_scle_bready;
  input [4:0]s_axil_scle_araddr;
  input [2:0]s_axil_scle_arprot;
  input s_axil_scle_arvalid;
  output s_axil_scle_arready;
  output [31:0]s_axil_scle_rdata;
  output [1:0]s_axil_scle_rresp;
  output s_axil_scle_rvalid;
  input s_axil_scle_rready;
  input [12:0]s_axil_ctrl_awaddr;
  input [2:0]s_axil_ctrl_awprot;
  input s_axil_ctrl_awvalid;
  output s_axil_ctrl_awready;
  input [31:0]s_axil_ctrl_wdata;
  input [3:0]s_axil_ctrl_wstrb;
  input s_axil_ctrl_wvalid;
  output s_axil_ctrl_wready;
  output [1:0]s_axil_ctrl_bresp;
  output s_axil_ctrl_bvalid;
  input s_axil_ctrl_bready;
  input [12:0]s_axil_ctrl_araddr;
  input [2:0]s_axil_ctrl_arprot;
  input s_axil_ctrl_arvalid;
  output s_axil_ctrl_arready;
  output [31:0]s_axil_ctrl_rdata;
  output [1:0]s_axil_ctrl_rresp;
  output s_axil_ctrl_rvalid;
  input s_axil_ctrl_rready;
  input [63:0]s_axis_wght_tdata;
  input [7:0]s_axis_wght_tkeep;
  input s_axis_wght_tvalid;
  output s_axis_wght_tready;
  input s_axis_wght_tlast;
  input [0:0]s_axis_wght_tid;
  input [0:0]s_axis_wght_tdest;
  input [0:0]s_axis_wght_tuser;
  output [63:0]m_axis_rslt_tdata;
  output [7:0]m_axis_rslt_tkeep;
  output m_axis_rslt_tvalid;
  input m_axis_rslt_tready;
  output m_axis_rslt_tlast;
  output [0:0]m_axis_rslt_tid;
  output [0:0]m_axis_rslt_tdest;
  output [0:0]m_axis_rslt_tuser;
endmodule
