// (c) Copyright 1995-2025 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:module_ref:KanAcceleratorWrapper:1.0
// IP Revision: 1

(* X_CORE_INFO = "KanAcceleratorWrapper,Vivado 2022.1" *)
(* CHECK_LICENSE_TYPE = "mixed16_4x4x1_KanAccelerator_0,KanAcceleratorWrapper,{}" *)
(* CORE_GENERATION_INFO = "mixed16_4x4x1_KanAccelerator_0,KanAcceleratorWrapper,{x_ipProduct=Vivado 2022.1,x_ipVendor=xilinx.com,x_ipLibrary=module_ref,x_ipName=KanAcceleratorWrapper,x_ipVersion=1.0,x_ipCoreRevision=1,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,DMA_WIDTH=128,DMA_KEEP_ENABLE=true,DMA_KEEP_WIDTH=16,AXIL_WIDTH=32,AXIL_STRB_WIDTH=4,DATA_WIDTH=16,DATA_FRACTIONAL_BITS=11,DATA_CHANNELS=4,DATA_DEPTH=16384,DATA_STRB_WIDTH=4,DATA_ADDR=15,GRID_SHARE=1,GRID_DEPTH=1024,GRID_ADDR=10,SCALE_SHARE=1,SCALE_WIDTH=16,SCALE_FR\
ACTIONAL_BITS=14,SCALE_DEPTH=1024,RSLT_CHANNELS=4,RSLT_WIDTH=16,RSLT_FRACTIONAL_BITS=11,RSLT_KEEP_WIDTH=2,RSLT_FIFO_DEPTH=32,SCALE_STRB_WIDTH=2,SCALE_ADDR=10,WEIGHT_WIDTH=8,WEIGHT_FRACTIONAL_BITS=10,WEIGHT_KEEP_ENABLE=true,WEIGHT_KEEP_WIDTH=1,WEIGHT_FIFO_DEPTH=512,SCALED_DIFF_WIDTH=12,SCALED_DIFF_FRACTIONAL_BITS=9,ACT_WIDTH=16,ACT_FRACTIONAL_BITS=16,WEIGHT_LAST_ENABLE=0,WEIGHT_ID_ENABLE=0,WEIGHT_ID_WIDTH=1,RSLT_ID_ENABLE=1,RSLT_ID_WIDTH=1,ID_OUTPUT=0,DEST_ENABLE=0,DEST_WIDTH=1,DEST_OUTPUT=0,USER\
_ENABLE=0,USER_WIDTH=1,USER_OUTPUT=0,EXTRA_CYCLE=0,CTRL_ADDR=14,IS_ASYNCHRONOUS=1,ROM_DATA_PATH=../data/Sech2Lutram_n_12.9_16.16.txt}" *)
(* IP_DEFINITION_SOURCE = "module_ref" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module mixed16_4x4x1_KanAccelerator_0 (
  fsm_clk,
  fsm_rst,
  core_clk,
  core_rst,
  operation_busy,
  operation_complete,
  operation_error,
  locked,
  pl2ps_intr,
  s_axil_ctrl_awaddr,
  s_axil_ctrl_awprot,
  s_axil_ctrl_awvalid,
  s_axil_ctrl_awready,
  s_axil_ctrl_wdata,
  s_axil_ctrl_wstrb,
  s_axil_ctrl_wvalid,
  s_axil_ctrl_wready,
  s_axil_ctrl_bresp,
  s_axil_ctrl_bvalid,
  s_axil_ctrl_bready,
  s_axil_ctrl_araddr,
  s_axil_ctrl_arprot,
  s_axil_ctrl_arvalid,
  s_axil_ctrl_arready,
  s_axil_ctrl_rdata,
  s_axil_ctrl_rresp,
  s_axil_ctrl_rvalid,
  s_axil_ctrl_rready,
  s00_axil_data_aclk,
  s00_axil_data_areset,
  s00_axil_data_awaddr,
  s00_axil_data_awprot,
  s00_axil_data_awvalid,
  s00_axil_data_awready,
  s00_axil_data_wdata,
  s00_axil_data_wstrb,
  s00_axil_data_wvalid,
  s00_axil_data_wready,
  s00_axil_data_bresp,
  s00_axil_data_bvalid,
  s00_axil_data_bready,
  s00_axil_data_araddr,
  s00_axil_data_arprot,
  s00_axil_data_arvalid,
  s00_axil_data_arready,
  s00_axil_data_rdata,
  s00_axil_data_rresp,
  s00_axil_data_rvalid,
  s00_axil_data_rready,
  s_axil_grid_aclk,
  s_axil_grid_areset,
  s_axil_grid_awaddr,
  s_axil_grid_awprot,
  s_axil_grid_awvalid,
  s_axil_grid_awready,
  s_axil_grid_wdata,
  s_axil_grid_wstrb,
  s_axil_grid_wvalid,
  s_axil_grid_wready,
  s_axil_grid_bresp,
  s_axil_grid_bvalid,
  s_axil_grid_bready,
  s_axil_grid_araddr,
  s_axil_grid_arprot,
  s_axil_grid_arvalid,
  s_axil_grid_arready,
  s_axil_grid_rdata,
  s_axil_grid_rresp,
  s_axil_grid_rvalid,
  s_axil_grid_rready,
  s_axil_scle_aclk,
  s_axil_scle_areset,
  s_axil_scle_awaddr,
  s_axil_scle_awprot,
  s_axil_scle_awvalid,
  s_axil_scle_awready,
  s_axil_scle_wdata,
  s_axil_scle_wstrb,
  s_axil_scle_wvalid,
  s_axil_scle_wready,
  s_axil_scle_bresp,
  s_axil_scle_bvalid,
  s_axil_scle_bready,
  s_axil_scle_araddr,
  s_axil_scle_arprot,
  s_axil_scle_arvalid,
  s_axil_scle_arready,
  s_axil_scle_rdata,
  s_axil_scle_rresp,
  s_axil_scle_rvalid,
  s_axil_scle_rready,
  s_axis_wght_aclk,
  s_axis_wght_areset,
  s_axis_wght_tdata,
  s_axis_wght_tkeep,
  s_axis_wght_tvalid,
  s_axis_wght_tready,
  s_axis_wght_tlast,
  s_axis_wght_tid,
  s_axis_wght_tdest,
  s_axis_wght_tuser,
  m_axis_rslt_aclk,
  m_axis_rslt_areset,
  m_axis_rslt_tdata,
  m_axis_rslt_tkeep,
  m_axis_rslt_tvalid,
  m_axis_rslt_tready,
  m_axis_rslt_tlast,
  m_axis_rslt_tid,
  m_axis_rslt_tdest,
  m_axis_rslt_tuser
);

(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME fsm_clk, ASSOCIATED_RESET fsm_rst, ASSOCIATED_BUSIF s_axil_ctrl, FREQ_HZ 62500000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
input wire fsm_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME fsm_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fsm_rst RST" *)
input wire fsm_rst;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_clk, ASSOCIATED_RESET core_rst, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
input wire core_clk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME core_rst, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST" *)
output wire core_rst;
output wire operation_busy;
output wire operation_complete;
output wire operation_error;
output wire locked;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME pl2ps_intr, SENSITIVITY LEVEL_HIGH, PortWidth 1" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 pl2ps_intr INTERRUPT" *)
output wire pl2ps_intr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWADDR" *)
input wire [13 : 0] s_axil_ctrl_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWPROT" *)
input wire [2 : 0] s_axil_ctrl_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWVALID" *)
input wire s_axil_ctrl_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWREADY" *)
output wire s_axil_ctrl_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WDATA" *)
input wire [31 : 0] s_axil_ctrl_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WSTRB" *)
input wire [3 : 0] s_axil_ctrl_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WVALID" *)
input wire s_axil_ctrl_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WREADY" *)
output wire s_axil_ctrl_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BRESP" *)
output wire [1 : 0] s_axil_ctrl_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BVALID" *)
output wire s_axil_ctrl_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BREADY" *)
input wire s_axil_ctrl_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARADDR" *)
input wire [13 : 0] s_axil_ctrl_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARPROT" *)
input wire [2 : 0] s_axil_ctrl_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARVALID" *)
input wire s_axil_ctrl_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARREADY" *)
output wire s_axil_ctrl_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RDATA" *)
output wire [31 : 0] s_axil_ctrl_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RRESP" *)
output wire [1 : 0] s_axil_ctrl_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RVALID" *)
output wire s_axil_ctrl_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_ctrl, READ_WRITE_MODE READ_WRITE, PROTOCOL AXI4LITE, DATA_WIDTH 32, FREQ_HZ 62500000, ID_WIDTH 0, ADDR_WIDTH 14, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK0, NUM_READ_\
THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RREADY" *)
input wire s_axil_ctrl_rready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s00_axil_data_aclk, ASSOCIATED_BUSIF s00_axil_data, ASSOCIATED_RESET s00_axil_data_areset, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s00_axil_data_aclk CLK" *)
input wire s00_axil_data_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s00_axil_data_areset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s00_axil_data_areset RST" *)
input wire s00_axil_data_areset;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data AWADDR" *)
input wire [14 : 0] s00_axil_data_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data AWPROT" *)
input wire [2 : 0] s00_axil_data_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data AWVALID" *)
input wire s00_axil_data_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data AWREADY" *)
output wire s00_axil_data_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data WDATA" *)
input wire [31 : 0] s00_axil_data_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data WSTRB" *)
input wire [3 : 0] s00_axil_data_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data WVALID" *)
input wire s00_axil_data_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data WREADY" *)
output wire s00_axil_data_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data BRESP" *)
output wire [1 : 0] s00_axil_data_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data BVALID" *)
output wire s00_axil_data_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data BREADY" *)
input wire s00_axil_data_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data ARADDR" *)
input wire [14 : 0] s00_axil_data_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data ARPROT" *)
input wire [2 : 0] s00_axil_data_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data ARVALID" *)
input wire s00_axil_data_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data ARREADY" *)
output wire s00_axil_data_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data RDATA" *)
output wire [31 : 0] s00_axil_data_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data RRESP" *)
output wire [1 : 0] s00_axil_data_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data RVALID" *)
output wire s00_axil_data_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s00_axil_data, READ_WRITE_MODE READ_WRITE, PROTOCOL AXI4LITE, DATA_WIDTH 32, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 15, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, NUM_RE\
AD_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s00_axil_data RREADY" *)
input wire s00_axil_data_rready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_grid_aclk, ASSOCIATED_BUSIF s_axil_grid, ASSOCIATED_RESET s_axil_grid_areset, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_grid_aclk CLK" *)
input wire s_axil_grid_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_grid_areset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_grid_areset RST" *)
input wire s_axil_grid_areset;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWADDR" *)
input wire [9 : 0] s_axil_grid_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWPROT" *)
input wire [2 : 0] s_axil_grid_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWVALID" *)
input wire s_axil_grid_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWREADY" *)
output wire s_axil_grid_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WDATA" *)
input wire [31 : 0] s_axil_grid_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
input wire [3 : 0] s_axil_grid_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WVALID" *)
input wire s_axil_grid_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WREADY" *)
output wire s_axil_grid_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BRESP" *)
output wire [1 : 0] s_axil_grid_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BVALID" *)
output wire s_axil_grid_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BREADY" *)
input wire s_axil_grid_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARADDR" *)
input wire [9 : 0] s_axil_grid_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARPROT" *)
input wire [2 : 0] s_axil_grid_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARVALID" *)
input wire s_axil_grid_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARREADY" *)
output wire s_axil_grid_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RDATA" *)
output wire [31 : 0] s_axil_grid_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
output wire [1 : 0] s_axil_grid_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
output wire s_axil_grid_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_grid, READ_WRITE_MODE READ_WRITE, PROTOCOL AXI4LITE, DATA_WIDTH 32, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 10, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, NUM_READ\
_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
input wire s_axil_grid_rready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_scle_aclk, ASSOCIATED_BUSIF s_axil_scle, ASSOCIATED_RESET s_axil_scle_areset, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_scle_aclk CLK" *)
input wire s_axil_scle_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_scle_areset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_scle_areset RST" *)
input wire s_axil_scle_areset;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWADDR" *)
input wire [9 : 0] s_axil_scle_awaddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWPROT" *)
input wire [2 : 0] s_axil_scle_awprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWVALID" *)
input wire s_axil_scle_awvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWREADY" *)
output wire s_axil_scle_awready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WDATA" *)
input wire [31 : 0] s_axil_scle_wdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
input wire [3 : 0] s_axil_scle_wstrb;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WVALID" *)
input wire s_axil_scle_wvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WREADY" *)
output wire s_axil_scle_wready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BRESP" *)
output wire [1 : 0] s_axil_scle_bresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BVALID" *)
output wire s_axil_scle_bvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BREADY" *)
input wire s_axil_scle_bready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARADDR" *)
input wire [9 : 0] s_axil_scle_araddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARPROT" *)
input wire [2 : 0] s_axil_scle_arprot;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARVALID" *)
input wire s_axil_scle_arvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARREADY" *)
output wire s_axil_scle_arready;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RDATA" *)
output wire [31 : 0] s_axil_scle_rdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
output wire [1 : 0] s_axil_scle_rresp;
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
output wire s_axil_scle_rvalid;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axil_scle, READ_WRITE_MODE READ_WRITE, PROTOCOL AXI4LITE, DATA_WIDTH 32, FREQ_HZ 125000000, ID_WIDTH 0, ADDR_WIDTH 10, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, SUPPORTS_NARROW_BURST 0, NUM_READ_OUTSTANDING 1, NUM_WRITE_OUTSTANDING 1, MAX_BURST_LENGTH 1, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, NUM_READ\
_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
input wire s_axil_scle_rready;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_wght_aclk, ASSOCIATED_BUSIF s_axis_wght, ASSOCIATED_RESET s_axis_wght_areset, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axis_wght_aclk CLK" *)
input wire s_axis_wght_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_wght_areset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axis_wght_areset RST" *)
input wire s_axis_wght_areset;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
input wire [127 : 0] s_axis_wght_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TKEEP" *)
input wire [15 : 0] s_axis_wght_tkeep;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TVALID" *)
input wire s_axis_wght_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TREADY" *)
output wire s_axis_wght_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TLAST" *)
input wire s_axis_wght_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TID" *)
input wire [0 : 0] s_axis_wght_tid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
input wire [0 : 0] s_axis_wght_tdest;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axis_wght, HAS_TLAST WEIGHT_LAST_ENABLE, HAS_TSTRB 0, HAS_TREADY 1, TDATA_NUM_BYTES 16, TDEST_WIDTH 1, TID_WIDTH 1, TUSER_WIDTH 1, HAS_TKEEP 1, FREQ_HZ 125000000, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
input wire [0 : 0] s_axis_wght_tuser;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_rslt_aclk, ASSOCIATED_BUSIF m_axis_rslt, ASSOCIATED_RESET m_axis_rslt_areset, FREQ_HZ 125000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axis_rslt_aclk CLK" *)
input wire m_axis_rslt_aclk;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_rslt_areset, POLARITY ACTIVE_HIGH, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 m_axis_rslt_areset RST" *)
input wire m_axis_rslt_areset;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
output wire [127 : 0] m_axis_rslt_tdata;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TKEEP" *)
output wire [15 : 0] m_axis_rslt_tkeep;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TVALID" *)
output wire m_axis_rslt_tvalid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TREADY" *)
input wire m_axis_rslt_tready;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TLAST" *)
output wire m_axis_rslt_tlast;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TID" *)
output wire [0 : 0] m_axis_rslt_tid;
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
output wire [0 : 0] m_axis_rslt_tdest;
(* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME m_axis_rslt, HAS_TLAST 1, HAS_TSTRB 0, HAS_TREADY 1, TDATA_NUM_BYTES 16, TDEST_WIDTH 1, TID_WIDTH 1, TUSER_WIDTH 1, HAS_TKEEP 1, FREQ_HZ 125000000, PHASE 0.0, CLK_DOMAIN mixed16_4x4x1_processing_system7_1_FCLK_CLK1, LAYERED_METADATA undef, INSERT_VIP 0" *)
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
output wire [0 : 0] m_axis_rslt_tuser;

  KanAcceleratorWrapper #(
    .DMA_WIDTH(128),
    .DMA_KEEP_ENABLE(1'B1),
    .DMA_KEEP_WIDTH(16),
    .AXIL_WIDTH(32),
    .AXIL_STRB_WIDTH(4),
    .DATA_WIDTH(16),
    .DATA_FRACTIONAL_BITS(11),
    .DATA_CHANNELS(4),
    .DATA_DEPTH(16384),
    .DATA_STRB_WIDTH(4),
    .DATA_ADDR(15),
    .GRID_SHARE(1),
    .GRID_DEPTH(1024),
    .GRID_ADDR(10),
    .SCALE_SHARE(1),
    .SCALE_WIDTH(16),
    .SCALE_FRACTIONAL_BITS(14),
    .SCALE_DEPTH(1024),
    .RSLT_CHANNELS(4),
    .RSLT_WIDTH(16),
    .RSLT_FRACTIONAL_BITS(11),
    .RSLT_KEEP_WIDTH(2),
    .RSLT_FIFO_DEPTH(32),
    .SCALE_STRB_WIDTH(2),
    .SCALE_ADDR(10),
    .WEIGHT_WIDTH(8),
    .WEIGHT_FRACTIONAL_BITS(10),
    .WEIGHT_KEEP_ENABLE(1'B1),
    .WEIGHT_KEEP_WIDTH(1),
    .WEIGHT_FIFO_DEPTH(512),
    .SCALED_DIFF_WIDTH(12),
    .SCALED_DIFF_FRACTIONAL_BITS(9),
    .ACT_WIDTH(16),
    .ACT_FRACTIONAL_BITS(16),
    .WEIGHT_LAST_ENABLE(0),
    .WEIGHT_ID_ENABLE(0),
    .WEIGHT_ID_WIDTH(1),
    .RSLT_ID_ENABLE(1),
    .RSLT_ID_WIDTH(1),
    .ID_OUTPUT(0),
    .DEST_ENABLE(0),
    .DEST_WIDTH(1),
    .DEST_OUTPUT(0),
    .USER_ENABLE(0),
    .USER_WIDTH(1),
    .USER_OUTPUT(0),
    .EXTRA_CYCLE(0),
    .CTRL_ADDR(14),
    .IS_ASYNCHRONOUS(1),
    .ROM_DATA_PATH("../data/Sech2Lutram_n_12.9_16.16.txt")
  ) inst (
    .fsm_clk(fsm_clk),
    .fsm_rst(fsm_rst),
    .core_clk(core_clk),
    .core_rst(core_rst),
    .operation_busy(operation_busy),
    .operation_complete(operation_complete),
    .operation_error(operation_error),
    .locked(locked),
    .pl2ps_intr(pl2ps_intr),
    .s_axil_ctrl_awaddr(s_axil_ctrl_awaddr),
    .s_axil_ctrl_awprot(s_axil_ctrl_awprot),
    .s_axil_ctrl_awvalid(s_axil_ctrl_awvalid),
    .s_axil_ctrl_awready(s_axil_ctrl_awready),
    .s_axil_ctrl_wdata(s_axil_ctrl_wdata),
    .s_axil_ctrl_wstrb(s_axil_ctrl_wstrb),
    .s_axil_ctrl_wvalid(s_axil_ctrl_wvalid),
    .s_axil_ctrl_wready(s_axil_ctrl_wready),
    .s_axil_ctrl_bresp(s_axil_ctrl_bresp),
    .s_axil_ctrl_bvalid(s_axil_ctrl_bvalid),
    .s_axil_ctrl_bready(s_axil_ctrl_bready),
    .s_axil_ctrl_araddr(s_axil_ctrl_araddr),
    .s_axil_ctrl_arprot(s_axil_ctrl_arprot),
    .s_axil_ctrl_arvalid(s_axil_ctrl_arvalid),
    .s_axil_ctrl_arready(s_axil_ctrl_arready),
    .s_axil_ctrl_rdata(s_axil_ctrl_rdata),
    .s_axil_ctrl_rresp(s_axil_ctrl_rresp),
    .s_axil_ctrl_rvalid(s_axil_ctrl_rvalid),
    .s_axil_ctrl_rready(s_axil_ctrl_rready),
    .s00_axil_data_aclk(s00_axil_data_aclk),
    .s00_axil_data_areset(s00_axil_data_areset),
    .s00_axil_data_awaddr(s00_axil_data_awaddr),
    .s00_axil_data_awprot(s00_axil_data_awprot),
    .s00_axil_data_awvalid(s00_axil_data_awvalid),
    .s00_axil_data_awready(s00_axil_data_awready),
    .s00_axil_data_wdata(s00_axil_data_wdata),
    .s00_axil_data_wstrb(s00_axil_data_wstrb),
    .s00_axil_data_wvalid(s00_axil_data_wvalid),
    .s00_axil_data_wready(s00_axil_data_wready),
    .s00_axil_data_bresp(s00_axil_data_bresp),
    .s00_axil_data_bvalid(s00_axil_data_bvalid),
    .s00_axil_data_bready(s00_axil_data_bready),
    .s00_axil_data_araddr(s00_axil_data_araddr),
    .s00_axil_data_arprot(s00_axil_data_arprot),
    .s00_axil_data_arvalid(s00_axil_data_arvalid),
    .s00_axil_data_arready(s00_axil_data_arready),
    .s00_axil_data_rdata(s00_axil_data_rdata),
    .s00_axil_data_rresp(s00_axil_data_rresp),
    .s00_axil_data_rvalid(s00_axil_data_rvalid),
    .s00_axil_data_rready(s00_axil_data_rready),
    .s_axil_grid_aclk(s_axil_grid_aclk),
    .s_axil_grid_areset(s_axil_grid_areset),
    .s_axil_grid_awaddr(s_axil_grid_awaddr),
    .s_axil_grid_awprot(s_axil_grid_awprot),
    .s_axil_grid_awvalid(s_axil_grid_awvalid),
    .s_axil_grid_awready(s_axil_grid_awready),
    .s_axil_grid_wdata(s_axil_grid_wdata),
    .s_axil_grid_wstrb(s_axil_grid_wstrb),
    .s_axil_grid_wvalid(s_axil_grid_wvalid),
    .s_axil_grid_wready(s_axil_grid_wready),
    .s_axil_grid_bresp(s_axil_grid_bresp),
    .s_axil_grid_bvalid(s_axil_grid_bvalid),
    .s_axil_grid_bready(s_axil_grid_bready),
    .s_axil_grid_araddr(s_axil_grid_araddr),
    .s_axil_grid_arprot(s_axil_grid_arprot),
    .s_axil_grid_arvalid(s_axil_grid_arvalid),
    .s_axil_grid_arready(s_axil_grid_arready),
    .s_axil_grid_rdata(s_axil_grid_rdata),
    .s_axil_grid_rresp(s_axil_grid_rresp),
    .s_axil_grid_rvalid(s_axil_grid_rvalid),
    .s_axil_grid_rready(s_axil_grid_rready),
    .s_axil_scle_aclk(s_axil_scle_aclk),
    .s_axil_scle_areset(s_axil_scle_areset),
    .s_axil_scle_awaddr(s_axil_scle_awaddr),
    .s_axil_scle_awprot(s_axil_scle_awprot),
    .s_axil_scle_awvalid(s_axil_scle_awvalid),
    .s_axil_scle_awready(s_axil_scle_awready),
    .s_axil_scle_wdata(s_axil_scle_wdata),
    .s_axil_scle_wstrb(s_axil_scle_wstrb),
    .s_axil_scle_wvalid(s_axil_scle_wvalid),
    .s_axil_scle_wready(s_axil_scle_wready),
    .s_axil_scle_bresp(s_axil_scle_bresp),
    .s_axil_scle_bvalid(s_axil_scle_bvalid),
    .s_axil_scle_bready(s_axil_scle_bready),
    .s_axil_scle_araddr(s_axil_scle_araddr),
    .s_axil_scle_arprot(s_axil_scle_arprot),
    .s_axil_scle_arvalid(s_axil_scle_arvalid),
    .s_axil_scle_arready(s_axil_scle_arready),
    .s_axil_scle_rdata(s_axil_scle_rdata),
    .s_axil_scle_rresp(s_axil_scle_rresp),
    .s_axil_scle_rvalid(s_axil_scle_rvalid),
    .s_axil_scle_rready(s_axil_scle_rready),
    .s_axis_wght_aclk(s_axis_wght_aclk),
    .s_axis_wght_areset(s_axis_wght_areset),
    .s_axis_wght_tdata(s_axis_wght_tdata),
    .s_axis_wght_tkeep(s_axis_wght_tkeep),
    .s_axis_wght_tvalid(s_axis_wght_tvalid),
    .s_axis_wght_tready(s_axis_wght_tready),
    .s_axis_wght_tlast(s_axis_wght_tlast),
    .s_axis_wght_tid(s_axis_wght_tid),
    .s_axis_wght_tdest(s_axis_wght_tdest),
    .s_axis_wght_tuser(s_axis_wght_tuser),
    .m_axis_rslt_aclk(m_axis_rslt_aclk),
    .m_axis_rslt_areset(m_axis_rslt_areset),
    .m_axis_rslt_tdata(m_axis_rslt_tdata),
    .m_axis_rslt_tkeep(m_axis_rslt_tkeep),
    .m_axis_rslt_tvalid(m_axis_rslt_tvalid),
    .m_axis_rslt_tready(m_axis_rslt_tready),
    .m_axis_rslt_tlast(m_axis_rslt_tlast),
    .m_axis_rslt_tid(m_axis_rslt_tid),
    .m_axis_rslt_tdest(m_axis_rslt_tdest),
    .m_axis_rslt_tuser(m_axis_rslt_tuser)
  );
endmodule
