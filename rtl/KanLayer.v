`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * KanLayer: This acts as the top level hdl module
 *   of the KAN SoC design.
 *   The endgoal is that this particular module
 *   be drag-and-dropped in the Vivado Block Design.
 */

`include "utils.vh"
`include "IFOptionsInst.vh"

module KanLayer #(
  /*------------------------------------------------------------------
    Genreal parameters of the architecture
  ------------------------------------------------------------------*/
  
  `include "MCUGlobalFSMParameters.vh"
  `include "ControlRegisters.vh"

  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,

  /*------------------------------------------------------------------
    DMA parameters
  ------------------------------------------------------------------*/
  
  // Width of DMA streams
  parameter DATA_WIDTH_DMA = 64,
  // Propagate tkeep signal
  parameter KEEP_ENABLE_DMA = (DATA_WIDTH_DMA > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_DMA = (KEEP_ENABLE_DMA) ? ((DATA_WIDTH_DMA + 7) / 8) : 1,

  /*------------------------------------------------------------------
    Bram controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter BRAM_CTRL_WIDTH = 32,
  parameter BRAM_CTRL_WE = 4,
  parameter BRAM_CTRL_ADDR = 13,

  /*------------------------------------------------------------------
    DATA parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = 1,
  // Data FIFO Depth
  parameter FIFO_DEPTH_DATA = `MAX(DATA_CHANNELS + BATCH_SIZE, 8),

  // number of DATA bram banks
  parameter DATA_BANKS = DATA_CHANNELS,
  // number of elements on a single bram bank
  parameter DATA_BANK_DEPTH = 16,
  // number of address bits needed for each bank
  parameter DATA_ADDR = `LOG2(DATA_BANK_DEPTH),
  // number of DATA_WE bits needed for each bank
  parameter DATA_WE = DATA_WIDTH_DATA / 8,

  `ifdef DATA_IF_IS_AXIL
    // Data Strobe Width
    parameter STRB_WIDTH_DATA = DATA_WIDTH_DATA / 8,
    // Pipeline Output Data
    parameter PIPELINE_OUTPUT_DATA = 0,
  `endif 
  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Grid Data Width
  parameter DATA_WIDTH_GRID = DATA_WIDTH_DATA,
  // Use Common Grid Channel 
  parameter SHARE_GRID = `GRID_IS_SHARED, 
  // Input Grid Channels
  parameter GRID_CHANNELS_IN = (SHARE_GRID) ? 1 : DATA_CHANNELS,
  // Output Grid Channels
  parameter GRID_CHANNELS_OUT = (SHARE_GRID) ? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Grid FIFO Depth
  parameter FIFO_DEPTH_GRID = `MAX((SHARE_GRID) ? 1 : DATA_CHANNELS + BATCH_SIZE, 2),

  `ifdef GRID_IF_IS_AXIL
    // depth of the grid bram
    parameter GRID_DEPTH = 16,
    // Grid Address Width
    parameter GRID_ADDR = `LOG2(GRID_DEPTH),
    // Grid Strobe Width
    parameter STRB_WIDTH_GRID = DATA_WIDTH_GRID / 8,
    // Pipeline Output Grid
    parameter PIPELINE_OUTPUT_GRID = 0,
  `endif 

  `ifdef GRID_IF_IS_BRAM
    // number of GRID bram banks
    parameter GRID_BANKS = DATA_CHANNELS,
    // number of elements on a single bram bank
    parameter GRID_BANK_DEPTH = 16,
    // number of address bits needed for each bank
    parameter GRID_ADDR = `LOG2(GRID_BANK_DEPTH),
    // number of GRID_WE bits needed for each bank
    parameter GRID_WE = DATA_WIDTH_DATA / 8,
  `endif 
  /*------------------------------------------------------------------
    SCALE streams parameters
  ------------------------------------------------------------------*/

  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scle
  parameter FRACTIONAL_BITS_SCALE = 12,
  // Use Common Share Channel 
  parameter SHARE_SCALE = `SCALE_IS_SHARED,
  // Input Scale Channels
  parameter SCALE_CHANNELS_IN = (SHARE_SCALE) ? 1 : DATA_CHANNELS,
  // Output Scale Channels
  parameter SCALE_CHANNELS_OUT = (SHARE_SCALE) ? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Grid FIFO Depth
  parameter FIFO_DEPTH_SCALE = `MAX((SHARE_SCALE) ? 1 : DATA_CHANNELS + BATCH_SIZE,8),

  `ifdef SCALE_IF_IS_AXIL
    // depth of the grid bram
    parameter SCALE_DEPTH = 1,
    // Grid Address Width
    parameter SCALE_ADDR = `LOG2(SCALE_DEPTH),
    // Grid Strobe Width
    parameter STRB_WIDTH_SCALE = DATA_WIDTH_SCALE / 8,
    // Pipeline Output Grid
    parameter PIPELINE_OUTPUT_SCALE = 0,
  `endif 

  `ifdef SCALE_IF_IS_BRAM
    // number of SCALE bram banks
    parameter SCALE_BANKS = DATA_CHANNELS,
    // number of elements on a single bram bank
    parameter SCALE_BANK_DEPTH = GRID_DEPTH*DATA_BANK_DEPTH,
    // number of address bits needed for each bank
    parameter SCALE_ADDR = `LOG2(SCALE_BANK_DEPTH),
    // number of SCALE_WE bits needed for each bank
    parameter SCALE_WE = DATA_WIDTH_SCALE / 8,
  `endif 
  /*------------------------------------------------------------------
    RESULT / OUTPUT parameters
  ------------------------------------------------------------------*/

  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_RSLT = ((DATA_WIDTH_RSLT + 7) / 8),
  // FIFO Depth for results
  parameter FIFO_DEPTH_RSLT = 2 ** (`LOG2(BATCH_SIZE + RSLT_CHANNELS) + KEEP_WIDTH_DMA),

  /*------------------------------------------------------------------
    WEIGHT streams parameters
  ------------------------------------------------------------------*/

  // Width of input wght word
  parameter DATA_WIDTH_WEIGHT = 16,
  // Fractional bits of wght data
  parameter FRACTIONAL_BITS_WEIGHT = 12,
  // Number of Independent AXI-Stream Weight Channels
  parameter WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS,
  // Propagate tkeep signal
  parameter KEEP_ENABLE_WEIGHT = (DATA_WIDTH_WEIGHT > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_WEIGHT = (KEEP_ENABLE_WEIGHT) ? ((DATA_WIDTH_WEIGHT + 7) / 8) : 1,
  // FIFO Depth for weight parameters
  parameter FIFO_DEPTH_WEIGHT = 2 ** `LOG2(BATCH_SIZE + DATA_CHANNELS + RSLT_CHANNELS + KEEP_WIDTH_DMA),

  /*------------------------------------------------------------------
    SCALED_DIFF parameters
  ------------------------------------------------------------------*/

  // Width of Scaled Data in bits
  parameter DATA_WIDTH_SCALED_DIFF = 16,
  // Fractional bits of Scaled Data
  parameter FRACTIONAL_BITS_SCALED_DIFF = 12,

  /*------------------------------------------------------------------
    ACT parameters
  ------------------------------------------------------------------*/

  // Width of Activation Function Data in bits
  parameter DATA_WIDTH_ACT = 16,
  // Fractional bits of Activation Function Data
  parameter FRACTIONAL_BITS_ACT = 12,

  /*------------------------------------------------------------------
    Various AXI parameters
  ------------------------------------------------------------------*/

  // Propagate tid signal
  parameter WGHT_ID_ENABLE = 0,
  // tid signal width
  parameter WGHT_ID_WIDTH = (WGHT_ID_ENABLE) ? 8 : 1,

  // Propagate tid signal
  parameter RSLT_ID_ENABLE = 1,
  // tid signal width
  parameter RSLT_ID_WIDTH = (RSLT_ID_ENABLE) ? `LOG2(BATCH_SIZE) : 1,
  // tid value
  parameter ID_OUTPUT = 0,

  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // tdest value
  parameter DEST_OUTPUT = 0,

  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,
  // tuser value
  parameter USER_OUTPUT = 0,

  // Propagate tlast signal
  parameter LAST_ENABLE = 1,

  // Add Buffer on Output Streams
  parameter EXTRA_CYCLE = 0,

  /*------------------------------------------------------------------
    Miscalleneous parameters
  ------------------------------------------------------------------*/
  `define SYSTEM_SIZES_H
  `include "Peripherals.vh"
  `undef SYSTEM_SIZES_H

  /*------------------------------------------------------------------
    Input / Output file constants
  ------------------------------------------------------------------*/

  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.12_16.16.txt"
) (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_ctrl, ASSOCIATED_RESET fsm_rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire         fsm_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fsm_rst RST" *)
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire         fsm_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET core_rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire         core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output wire         core_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dma_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_wght m_axis_rslt, ASSOCIATED_RESET dma_rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire         dma_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 dma_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire         dma_rst,

  /*------------------------------------------------------------------
      Generated Interrupts & Resets
  ------------------------------------------------------------------*/
  output wire         operation_busy,
  output wire         operation_complete,
  output wire         operation_error,
  output wire         locked,
  output wire         pl2ps_intr,

  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/
 `ifdef DATA_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_data_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_data, ASSOCIATED_RESET s_axil_data_areset, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire                         s_axil_data_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_data_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                         s_axil_data_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWADDR" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axil_data_aclk,READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [DATA_ADDR-1:0]         s_axil_data_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWPROT" *)
  input  wire [2:0]                   s_axil_data_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWVALID" *)
  input  wire                         s_axil_data_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWREADY" *)
  output wire                         s_axil_data_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WDATA" *)
  input  wire [DATA_WIDTH_DATA-1:0]   s_axil_data_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WSTRB" *)
  input  wire [STRB_WIDTH_DATA-1:0]   s_axil_data_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WVALID" *)
  input  wire                         s_axil_data_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WREADY" *)
  output wire                         s_axil_data_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BRESP" *)
  output wire [1:0]                   s_axil_data_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BVALID" *)
  output wire                         s_axil_data_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BREADY" *)
  input  wire                         s_axil_data_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARADDR" *)
  input  wire [DATA_ADDR-1:0]         s_axil_data_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARPROT" *)
  input  wire [2:0]                   s_axil_data_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARVALID" *)
  input  wire                         s_axil_data_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARREADY" *)
  output wire                         s_axil_data_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RDATA" *)
  output wire [DATA_WIDTH_DATA-1:0]   s_axil_data_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RRESP" *)
  output wire [1:0]                   s_axil_data_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RVALID" *)
  output wire                         s_axil_data_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RREADY" *)
  input  wire                         s_axil_data_rready,
 `endif 

  // Uncomment the following to set interface specific parameter on the bus interface.
  // (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC <value>,MEM_WIDTH <value>,MEM_SIZE <value>,READ_WRITE_MODE <value>" *)

 `ifdef DATA_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data CLK" *)
  input  wire                       bram_ctrl_data_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data RST" *)
  input  wire                       bram_ctrl_data_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data EN" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                       bram_ctrl_data_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data WE" *)
  input  wire [BRAM_CTRL_WE-1:0]    bram_ctrl_data_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]  bram_ctrl_data_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_data_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_data_dout,
 `endif 

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/
 `ifdef GRID_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_grid_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_grid, ASSOCIATED_RESET s_axil_grid_areset, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire                         s_axil_grid_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_grid_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                         s_axil_grid_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWADDR" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axil_grid_aclk,READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [GRID_ADDR-1:0]         s_axil_grid_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWPROT" *)
  input  wire [2:0]                   s_axil_grid_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWVALID" *)
  input  wire                         s_axil_grid_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWREADY" *)
  output wire                         s_axil_grid_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WDATA" *)
  input  wire [DATA_WIDTH_GRID-1:0]   s_axil_grid_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
  input  wire [STRB_WIDTH_GRID-1:0]   s_axil_grid_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WVALID" *)
  input  wire                         s_axil_grid_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WREADY" *)
  output wire                         s_axil_grid_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BRESP" *)
  output wire [1:0]                   s_axil_grid_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BVALID" *)
  output wire                         s_axil_grid_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BREADY" *)
  input  wire                         s_axil_grid_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARADDR" *)
  input  wire [GRID_ADDR-1:0]         s_axil_grid_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARPROT" *)
  input  wire [2:0]                   s_axil_grid_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARVALID" *)
  input  wire                         s_axil_grid_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARREADY" *)
  output wire                         s_axil_grid_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RDATA" *)
  output wire [DATA_WIDTH_GRID-1:0]   s_axil_grid_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
  output wire [1:0]                   s_axil_grid_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
  output wire                         s_axil_grid_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
  input  wire                         s_axil_grid_rready,
 `endif 

 `ifdef GRID_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid CLK" *)
  input  wire                       bram_ctrl_grid_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid RST" *)
  input  wire                       bram_ctrl_grid_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                       bram_ctrl_grid_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid WE" *)
  input  wire [BRAM_CTRL_WE-1:0]    bram_ctrl_grid_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]  bram_ctrl_grid_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_grid_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_grid_dout,
 `endif

  /*------------------------------------------------------------------
      BRAM Scale Control interface
  ------------------------------------------------------------------*/

 `ifdef SCALE_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_scle_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_scle, ASSOCIATED_RESET s_axil_scle_areset, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire                         s_axil_scle_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_scle_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                         s_axil_scle_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWADDR" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axil_scle_aclk,READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [SCALE_ADDR-1:0]         s_axil_scle_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWPROT" *)
  input  wire [2:0]                   s_axil_scle_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWVALID" *)
  input  wire                         s_axil_scle_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWREADY" *)
  output wire                         s_axil_scle_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WDATA" *)
  input  wire [DATA_WIDTH_SCALE-1:0]   s_axil_scle_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
  input  wire [STRB_WIDTH_SCALE-1:0]   s_axil_scle_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WVALID" *)
  input  wire                         s_axil_scle_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WREADY" *)
  output wire                         s_axil_scle_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BRESP" *)
  output wire [1:0]                   s_axil_scle_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BVALID" *)
  output wire                         s_axil_scle_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BREADY" *)
  input  wire                         s_axil_scle_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARADDR" *)
  input  wire [SCALE_ADDR-1:0]         s_axil_scle_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARPROT" *)
  input  wire [2:0]                   s_axil_scle_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARVALID" *)
  input  wire                         s_axil_scle_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARREADY" *)
  output wire                         s_axil_scle_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RDATA" *)
  output wire [DATA_WIDTH_SCALE-1:0]   s_axil_scle_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
  output wire [1:0]                   s_axil_scle_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
  output wire                         s_axil_scle_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
  input  wire                         s_axil_scle_rready,
 `endif 

 `ifdef  SCALE_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle CLK" *)
  input  wire                       bram_ctrl_scle_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle RST" *)
  input  wire                       bram_ctrl_scle_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                       bram_ctrl_scle_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle WE" *)
  input  wire [BRAM_CTRL_WE-1:0]    bram_ctrl_scle_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]  bram_ctrl_scle_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_scle_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0] bram_ctrl_scle_dout,
 `endif
  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWADDR" *)
  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN fsm_clk,READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE,DATA_WIDTH 32" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWPROT" *)
  input  wire [2:0]             s_axil_ctrl_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWVALID" *)
  input  wire                   s_axil_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWREADY" *)
  output wire                   s_axil_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WDATA" *)
  input  wire [31:0]            s_axil_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WSTRB" *)
  input  wire [3:0]             s_axil_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WVALID" *)
  input  wire                   s_axil_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WREADY" *)
  output wire                   s_axil_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BRESP" *)
  output wire [1:0]             s_axil_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BVALID" *)
  output wire                   s_axil_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BREADY" *)
  input  wire                   s_axil_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARADDR" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARPROT" *)
  input  wire [2:0]             s_axil_ctrl_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARVALID" *)
  input  wire                   s_axil_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARREADY" *)
  output wire                   s_axil_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RDATA" *)
  output wire [31:0]            s_axil_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RRESP" *)
  output wire [1:0]             s_axil_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RVALID" *)
  output wire                   s_axil_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RREADY" *)
  input  wire                   s_axil_ctrl_rready,

  /*------------------------------------------------------------------
      AXI-Stream Weight Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN dma_clk,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  input  wire [DATA_WIDTH_DMA-1:0]  s_axis_wght_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TKEEP" *)
  input  wire [KEEP_WIDTH_DMA-1:0]  s_axis_wght_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TVALID" *)
  input  wire                       s_axis_wght_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TREADY" *)
  output wire                       s_axis_wght_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TLAST" *)
  input  wire                       s_axis_wght_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TID" *)
  input  wire [WGHT_ID_WIDTH-1:0]   s_axis_wght_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
  input  wire [DEST_WIDTH-1:0]      s_axis_wght_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
  input  wire [USER_WIDTH-1:0]      s_axis_wght_tuser,

  /*------------------------------------------------------------------
      AXI-Stream Results / Output Master interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN dma_clk,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  output  wire [DATA_WIDTH_DMA-1:0] m_axis_rslt_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TKEEP" *)
  output  wire [KEEP_WIDTH_DMA-1:0] m_axis_rslt_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TVALID" *)
  output  wire                      m_axis_rslt_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TREADY" *)
  input wire                        m_axis_rslt_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TLAST" *)
  output  wire                      m_axis_rslt_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TID" *)
  output  wire [RSLT_ID_WIDTH-1:0]  m_axis_rslt_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
  output  wire [DEST_WIDTH-1:0]     m_axis_rslt_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
  output  wire [USER_WIDTH-1:0]     m_axis_rslt_tuser
);
  /*************************************************************************************
   Local Paramters
  *************************************************************************************/
 `ifdef DATA_IF_IS_BRAM
  localparam IN_WORD_DATA = BRAM_CTRL_WIDTH / DATA_WIDTH_DATA;

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory
 `endif

 `ifdef GRID_IF_IS_BRAM
  localparam IN_WORD_GRID = BRAM_CTRL_WIDTH / DATA_WIDTH_GRID;

  localparam GRID_ITRL_DEPTH = GRID_BANKS * GRID_BANK_DEPTH; // simulated total data ram length
  localparam GRID_ITRL_ADDR = `LOG2(GRID_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_DEPTH = GRID_ITRL_DEPTH;

  localparam GRID_EXTRL_DEPTH = GRID_DEPTH / IN_WORD_GRID;  // grid depth as seen from external ram control interface
  localparam GRID_EXTRL_ADDR = `LOG2(GRID_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  // localparam GRID_ADDR = `LOG2(GRID_DEPTH);  // number of input address bits of total grid memory
  localparam GRID_PHYS_DEPTH = GRID_DEPTH / IN_WORD_GRID;  // effective - physical depth of grid ram
  localparam GRID_PHYS_ADDR = `LOG2(GRID_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram
 `endif

 `ifdef SCALE_IF_IS_BRAM
  localparam IN_WORD_SCALE = BRAM_CTRL_WIDTH / DATA_WIDTH_SCALE;

  localparam SCALE_ITRL_DEPTH = SCALE_BANKS * SCALE_BANK_DEPTH; // simulated total data ram length
  localparam SCALE_ITRL_ADDR = `LOG2(SCALE_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam SCALE_DEPTH = SCALE_ITRL_DEPTH;

  localparam SCALE_EXTRL_DEPTH = SCALE_DEPTH / IN_WORD_SCALE;  // grid depth as seen from external ram control interface
  localparam SCALE_EXTRL_ADDR = `LOG2(SCALE_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  // localparam SCALE_ADDR = `LOG2(SCALE_DEPTH);  // number of input address bits of total grid memory
  localparam SCALE_PHYS_DEPTH = SCALE_DEPTH / IN_WORD_SCALE;  // effective - physical depth of grid ram
  localparam SCALE_PHYS_ADDR = `LOG2(SCALE_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram
 `endif
  // localparam DATA_WIDTH_GRID = DATA_WIDTH_DATA;

  localparam PCKT_SIZE_WIDTH = DATA_ADDR + GRID_ADDR -1;

  /*************************************************************************************
   Check Configuration
  *************************************************************************************/
  initial begin
    if (DATA_WIDTH_DATA != DATA_WIDTH_GRID) begin
      $error("Missmatch between widths of grid and data.");
      $finish;
    end
    if (DATA_WIDTH_DMA % 32 != 0) begin
      $error("Data width for DMA master & slave interfaces must be multiples of 32.");
      $finish;
    end
    if ( (`LOG2(DATA_CHANNELS)) ** 2 != DATA_CHANNELS) begin
      $error("Data channels is expected to be a power of 2.");
      $finish;
    end
    if (FIFO_DEPTH_DATA < 2) begin
      $error("FIFO depth for Data must be greater than 1.");
      $finish;
    end
    if (FIFO_DEPTH_GRID < 2) begin
      $error("FIFO depth for Grid must be greater than 1.");
      $finish;
    end
    if (FIFO_DEPTH_SCALE < 2) begin
      $error("FIFO depth for Scale must be greater than 1.");
      $finish;
    end
    if (FIFO_DEPTH_WEIGHT < 2) begin
      $error("FIFO depth for Weights must be greater than 1.");
      $finish;
    end
    if (FIFO_DEPTH_RSLT < 2) begin
      $error("FIFO depth for Results must be greater than 1.");
      $finish;
    end
  end

  /*************************************************************************************
   Internal Signals
  *************************************************************************************/

  wire err_unalligned_data;   // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later

  // wire core_rst; // Interrupt outputs. WARNING: Might be grouped into AXI-Lite MM interfaces later
  wire                            operation_start;
  wire [DATA_ADDR:0]              data_size;
  wire [GRID_ADDR:0]              grid_size;
  wire [SCALE_ADDR:0]             scle_size;
  wire [PCKT_SIZE_WIDTH-1:0]      pckt_size;
  wire [RSLT_CHANNELS-1:0]        use_channels;
  wire [BATCH_SIZE-1:0]           use_batch;
  wire                            internal_operation_error;
  wire [NUM_PERIPHERALS-1:0]      peripheral_operation_busy;
  wire [NUM_PERIPHERALS-1:0]      peripheral_operation_complete;
  wire [NUM_PERIPHERALS-1:0]      peripheral_operation_error;
  wire [NUM_PERIPHERALS-1:0]      peripheral_transmission;
  wire                            rslt_tlast;

  /*************************************************************************************
   Module instantiations with their local signals
  *************************************************************************************/

 `ifdef DATA_IF_IS_AXIL

  initial begin
    if (DATA_CHANNELS != 1) begin
      $error("Configuration error : Data AXI-Lite interface can only be used when DATA_CHANNELS == 1.");
      $finish;
    end
  end

  /**********************************************
    AXI-Lite Data register

    The axi-lite signals are immediatly
    connected to the axi-lite
    external slave interface
    without internal signals.

    Naming conventions
    - int_ : internal signal
    - _axil_ : axi-lite
  *********************************************/

  // Port A
  wire                        int_ram_data_a_axil_aclk;
  wire                        int_ram_data_a_axil_arst;
  // Keep Write channels of Port A
  wire [DATA_ADDR-1:0]        int_ram_data_a_axil_awaddr;
  wire [2:0]                  int_ram_data_a_axil_awprot;
  wire                        int_ram_data_a_axil_awvalid;
  wire                        int_ram_data_a_axil_awready;
  wire [DATA_WIDTH_DATA-1:0]  int_ram_data_a_axil_wdata;
  wire [1-1:0]                int_ram_data_a_axil_wstrb;
  wire                        int_ram_data_a_axil_wvalid;
  wire                        int_ram_data_a_axil_wready;
  wire [1:0]                  int_ram_data_a_axil_bresp;
  wire                        int_ram_data_a_axil_bvalid;
  wire                        int_ram_data_a_axil_bready;
  // Keep Read channels of Port A
  wire [DATA_ADDR-1:0]        int_ram_data_a_axil_araddr;
  wire [2:0]                  int_ram_data_a_axil_arprot;
  wire                        int_ram_data_a_axil_arvalid;
  wire                        int_ram_data_a_axil_arready;
  wire [DATA_WIDTH_DATA-1:0]  int_ram_data_a_axil_rdata;
  wire [1:0]                  int_ram_data_a_axil_rresp;
  wire                        int_ram_data_a_axil_rvalid;
  wire                        int_ram_data_a_axil_rready;

  // Port B
  wire                        int_ram_data_b_axil_aclk;
  wire                        int_ram_data_b_axil_arst;
  // Drop Write channels of Port B
  wire [DATA_ADDR-1:0]        int_ram_data_b_axil_awaddr = {DATA_ADDR{1'b0}};
  wire [2:0]                  int_ram_data_b_axil_awprot = {2'b00};
  wire                        int_ram_data_b_axil_awvalid = 1'b0;
  wire                        int_ram_data_b_axil_awready;
  wire [DATA_WIDTH_DATA-1:0]  int_ram_data_b_axil_wdata = {DATA_ADDR{1'b0}};
  wire [1-1:0]                int_ram_data_b_axil_wstrb = 1'b0;
  wire                        int_ram_data_b_axil_wvalid = 1'b0;
  wire                        int_ram_data_b_axil_wready = 1'b0;
  wire [1:0]                  int_ram_data_b_axil_bresp;
  wire                        int_ram_data_b_axil_bvalid;
  wire                        int_ram_data_b_axil_bready = 1'b0;
  // Keep Read channels of Port B
  wire [DATA_ADDR-1:0]        int_ram_data_b_axil_araddr;
  wire [2:0]                  int_ram_data_b_axil_arprot;
  wire                        int_ram_data_b_axil_arvalid;
  wire                        int_ram_data_b_axil_arready;
  wire [DATA_WIDTH_DATA-1:0]  int_ram_data_b_axil_rdata;
  wire [1:0]                  int_ram_data_b_axil_rresp;
  wire                        int_ram_data_b_axil_rvalid;
  wire                        int_ram_data_b_axil_rready;

  axil_dp_ram # (
    .DATA_WIDTH         (DATA_WIDTH_DATA),
    .ADDR_WIDTH         (DATA_ADDR),
    .STRB_WIDTH         (1),
    .PIPELINE_OUTPUT    (PIPELINE_OUTPUT_DATA)
  ) data_axil_ram (
    .a_clk              (int_ram_data_a_axil_aclk),
    .a_rst              (int_ram_data_a_axil_arst),
    .b_clk              (int_ram_data_b_axil_aclk),
    .b_rst              (int_ram_data_b_axil_arst),
    .s_axil_a_awaddr    (int_ram_data_a_axil_awaddr),
    .s_axil_a_awprot    (int_ram_data_a_axil_awprot),
    .s_axil_a_awvalid   (int_ram_data_a_axil_awvalid),
    .s_axil_a_awready   (int_ram_data_a_axil_awready),
    .s_axil_a_wdata     (int_ram_data_a_axil_wdata),
    .s_axil_a_wstrb     (int_ram_data_a_axil_wstrb),
    .s_axil_a_wvalid    (int_ram_data_a_axil_wvalid),
    .s_axil_a_wready    (int_ram_data_a_axil_wready),
    .s_axil_a_bresp     (int_ram_data_a_axil_bresp),
    .s_axil_a_bvalid    (int_ram_data_a_axil_bvalid),
    .s_axil_a_bready    (int_ram_data_a_axil_bready),
    .s_axil_a_araddr    (int_ram_data_a_axil_araddr),
    .s_axil_a_arprot    (int_ram_data_a_axil_arprot),
    .s_axil_a_arvalid   (int_ram_data_a_axil_arvalid),
    .s_axil_a_arready   (int_ram_data_a_axil_arready),
    .s_axil_a_rdata     (int_ram_data_a_axil_rdata),
    .s_axil_a_rresp     (int_ram_data_a_axil_rresp),
    .s_axil_a_rvalid    (int_ram_data_a_axil_rvalid),
    .s_axil_a_rready    (int_ram_data_a_axil_rready),
    .s_axil_b_awaddr    (int_ram_data_b_axil_awaddr),
    .s_axil_b_awprot    (int_ram_data_b_axil_awprot),
    .s_axil_b_awvalid   (int_ram_data_b_axil_awvalid),
    .s_axil_b_awready   (int_ram_data_b_axil_awready),
    .s_axil_b_wdata     (int_ram_data_b_axil_wdata),
    .s_axil_b_wstrb     (int_ram_data_b_axil_wstrb),
    .s_axil_b_wvalid    (int_ram_data_b_axil_wvalid),
    .s_axil_b_wready    (int_ram_data_b_axil_wready),
    .s_axil_b_bresp     (int_ram_data_b_axil_bresp),
    .s_axil_b_bvalid    (int_ram_data_b_axil_bvalid),
    .s_axil_b_bready    (int_ram_data_b_axil_bready),
    .s_axil_b_araddr    (int_ram_data_b_axil_araddr),
    .s_axil_b_arprot    (int_ram_data_b_axil_arprot),
    .s_axil_b_arvalid   (int_ram_data_b_axil_arvalid),
    .s_axil_b_arready   (int_ram_data_b_axil_arready),
    .s_axil_b_rdata     (int_ram_data_b_axil_rdata),
    .s_axil_b_rresp     (int_ram_data_b_axil_rresp),
    .s_axil_b_rvalid    (int_ram_data_b_axil_rvalid),
    .s_axil_b_rready    (int_ram_data_b_axil_rready)
  );

  // Connect Port A to S_AXIL_DATA interface
  assign int_ram_data_a_axil_aclk       = s_axil_data_aclk;
  assign int_ram_data_a_axil_arst       = s_axil_data_areset;
  assign int_ram_data_a_axil_awaddr     = s_axil_data_awaddr;
  assign int_ram_data_a_axil_awprot     = s_axil_data_awprot;
  assign int_ram_data_a_axil_awvalid    = s_axil_data_awvalid;
  assign s_axil_data_awready            = int_ram_data_a_axil_awready;
  assign int_ram_data_a_axil_wdata      = s_axil_data_wdata;
  assign int_ram_data_a_axil_wstrb      = s_axil_data_wstrb;
  assign int_ram_data_a_axil_wvalid     = s_axil_data_wvalid;
  assign s_axil_data_wready             = int_ram_data_a_axil_wready;
  assign s_axil_data_bresp              = int_ram_data_a_axil_bresp;
  assign s_axil_data_bvalid             = int_ram_data_a_axil_bvalid;
  assign int_ram_data_a_axil_bready     = s_axil_data_bready;
  assign int_ram_data_a_axil_araddr     = s_axil_data_araddr;
  assign int_ram_data_a_axil_arprot     = s_axil_data_arprot;
  assign int_ram_data_a_axil_arvalid    = s_axil_data_arvalid;
  assign s_axil_data_arready            = int_ram_data_a_axil_arready;
  assign s_axil_data_rdata              = int_ram_data_a_axil_rdata;
  assign s_axil_data_rresp              = int_ram_data_a_axil_rresp;
  assign s_axil_data_rvalid             = int_ram_data_a_axil_rvalid;
  assign int_ram_data_a_axil_rready     = s_axil_data_rready;
 `endif

 `ifdef DATA_IF_IS_BRAM
    /**********************************************
      Interface Translator between BRAM Controller
      and Data BRAM

      Naming conventions
      - int_ : internal signal
      - _ctrl_ : indicates a translator module
      - _i : input / slave interface
      - _o : output / master interface
    *********************************************/
    wire                                    int_bram_ctrl_data_en_i;
    wire [BRAM_CTRL_WE-1:0]                 int_bram_ctrl_data_we_i;
    wire [DATA_ITRL_ADDR-1:0]               int_bram_ctrl_data_addr_i;
    wire [BRAM_CTRL_WIDTH-1:0]              int_bram_ctrl_data_wrdata_i;
    wire [BRAM_CTRL_WIDTH-1:0]              int_bram_ctrl_data_rddata_i;
    
    wire [DATA_BANKS-1:0]                   int_bram_ctrl_data_en_o;
    wire [(DATA_BANKS*DATA_WE)-1:0]         int_bram_ctrl_data_we_o;
    wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_bram_ctrl_data_addr_o;
    wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_bram_ctrl_data_wrdata_o;
    wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_bram_ctrl_data_rddata_o;

    BramIntrfTranslator # (
      .IN_WIDTH  (BRAM_CTRL_WIDTH),
      .OUT_WIDTH (DATA_WIDTH_DATA),
      .BANKS     (DATA_BANKS),
      .OUT_DEPTH (DATA_BANK_DEPTH),
      .OUT_ADDR  (DATA_ADDR)
    ) data_bram_interface_translator_inst (
      .en_i      (int_bram_ctrl_data_en_i),
      .we_i      (int_bram_ctrl_data_we_i),
      .addr_i    (int_bram_ctrl_data_addr_i),
      .wrdata_i  (int_bram_ctrl_data_wrdata_i),
      .rddata_i  (int_bram_ctrl_data_rddata_i),
      .en_o      (int_bram_ctrl_data_en_o),
      .we_o      (int_bram_ctrl_data_we_o),
      .addr_o    (int_bram_ctrl_data_addr_o),
      .wrdata_o  (int_bram_ctrl_data_wrdata_o),
      .rddata_o  (int_bram_ctrl_data_rddata_o)
    );

    /**********************************************
      Data Multi-Bank Dual-Port BRAM

      Naming conventions
      - int_ : internal signal
      - _a : port a (control port)
      - _b : port b (internal use)
    *********************************************/
    wire                                    int_ram_data_bram_clk_a;
    wire [DATA_BANKS-1:0]                   int_ram_data_bram_en_a;
    wire [(DATA_BANKS*DATA_WE)-1:0]         int_ram_data_bram_we_a;
    wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_ram_data_bram_addr_a;
    wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_data_bram_wrdata_a;
    wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_data_bram_rddata_a;

    wire [DATA_BANKS-1:0]                   int_ram_data_bram_en_b;
    wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_ram_data_bram_addr_b;
    wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_data_bram_rddata_b;
    wire [DATA_BANKS-1:0]                   int_ram_data_bram_rdack_b;

    MultiBankBram #(
      .BANKS  (DATA_BANKS),
      .WIDTH  (DATA_WIDTH_DATA),
      .DEPTH  (DATA_BANK_DEPTH),
      .ADDR   (DATA_ADDR)
    ) data_multi_bank_bram_inst (
      .clk    (int_ram_data_bram_clk_a),
      .ena    (int_ram_data_bram_en_a),
      .wea    (int_ram_data_bram_we_a),
      .addra  (int_ram_data_bram_addr_a),
      .dina   (int_ram_data_bram_wrdata_a),
      .douta  (int_ram_data_bram_rddata_a),
      .enb    (int_ram_data_bram_en_b),
      .addrb  (int_ram_data_bram_addr_b),
      .doutb  (int_ram_data_bram_rddata_b),
      .validb (int_ram_data_bram_rdack_b)
    );
  
 `endif

 `ifdef GRID_IF_IS_AXIL
 
  initial begin
    if (~SHARE_GRID) begin
      $error("Configuration error : SHARE_GRID can only be used with AXI-Lite interface.");
      $finish;
    end
  end

  /**********************************************
    AXI-Lite Grid register

    The axi-lite signals are immediatly
    connected to the axi-lite
    external slave interface
    without internal signals.

    Naming conventions
    - int_ : internal signal
    - _axil_ : axi-lite
  *********************************************/

  // Port A
  wire                        int_ram_grid_a_axil_aclk;
  wire                        int_ram_grid_a_axil_arst;
  // Keep Write channels of Port A
  wire [GRID_ADDR-1:0]        int_ram_grid_a_axil_awaddr;
  wire [2:0]                  int_ram_grid_a_axil_awprot;
  wire                        int_ram_grid_a_axil_awvalid;
  wire                        int_ram_grid_a_axil_awready;
  wire [DATA_WIDTH_GRID-1:0]  int_ram_grid_a_axil_wdata;
  wire [1-1:0]                int_ram_grid_a_axil_wstrb;
  wire                        int_ram_grid_a_axil_wvalid;
  wire                        int_ram_grid_a_axil_wready;
  wire [1:0]                  int_ram_grid_a_axil_bresp;
  wire                        int_ram_grid_a_axil_bvalid;
  wire                        int_ram_grid_a_axil_bready;
  // Keep Read channels of Port A
  wire [GRID_ADDR-1:0]        int_ram_grid_a_axil_araddr;
  wire [2:0]                  int_ram_grid_a_axil_arprot;
  wire                        int_ram_grid_a_axil_arvalid;
  wire                        int_ram_grid_a_axil_arready;
  wire [DATA_WIDTH_GRID-1:0]  int_ram_grid_a_axil_rdata;
  wire [1:0]                  int_ram_grid_a_axil_rresp;
  wire                        int_ram_grid_a_axil_rvalid;
  wire                        int_ram_grid_a_axil_rready;

  // Port B
  wire                        int_ram_grid_b_axil_aclk;
  wire                        int_ram_grid_b_axil_arst;
  // Drop Write channels of Port B
  wire [GRID_ADDR-1:0]        int_ram_grid_b_axil_awaddr = {GRID_ADDR{1'b0}};
  wire [2:0]                  int_ram_grid_b_axil_awprot = {2'b00};
  wire                        int_ram_grid_b_axil_awvalid = 1'b0;
  wire                        int_ram_grid_b_axil_awready;
  wire [DATA_WIDTH_GRID-1:0]  int_ram_grid_b_axil_wdata = {GRID_ADDR{1'b0}};
  wire [1-1:0]                int_ram_grid_b_axil_wstrb = 1'b0;
  wire                        int_ram_grid_b_axil_wvalid = 1'b0;
  wire                        int_ram_grid_b_axil_wready = 1'b0;
  wire [1:0]                  int_ram_grid_b_axil_bresp;
  wire                        int_ram_grid_b_axil_bvalid;
  wire                        int_ram_grid_b_axil_bready = 1'b0;
  // Keep Read channels of Port B
  wire [GRID_ADDR-1:0]        int_ram_grid_b_axil_araddr;
  wire [2:0]                  int_ram_grid_b_axil_arprot;
  wire                        int_ram_grid_b_axil_arvalid;
  wire                        int_ram_grid_b_axil_arready;
  wire [DATA_WIDTH_GRID-1:0]  int_ram_grid_b_axil_rdata;
  wire [1:0]                  int_ram_grid_b_axil_rresp;
  wire                        int_ram_grid_b_axil_rvalid;
  wire                        int_ram_grid_b_axil_rready;

  axil_dp_ram # (
    .DATA_WIDTH         (DATA_WIDTH_GRID),
    .ADDR_WIDTH         (GRID_ADDR),
    .STRB_WIDTH         (1),
    .PIPELINE_OUTPUT    (PIPELINE_OUTPUT_GRID)
  ) grid_axil_ram (
    .a_clk              (int_ram_grid_a_axil_aclk),
    .a_rst              (int_ram_grid_a_axil_arst),
    .b_clk              (int_ram_grid_b_axil_aclk),
    .b_rst              (int_ram_grid_b_axil_arst),
    .s_axil_a_awaddr    (int_ram_grid_a_axil_awaddr),
    .s_axil_a_awprot    (int_ram_grid_a_axil_awprot),
    .s_axil_a_awvalid   (int_ram_grid_a_axil_awvalid),
    .s_axil_a_awready   (int_ram_grid_a_axil_awready),
    .s_axil_a_wdata     (int_ram_grid_a_axil_wdata),
    .s_axil_a_wstrb     (int_ram_grid_a_axil_wstrb),
    .s_axil_a_wvalid    (int_ram_grid_a_axil_wvalid),
    .s_axil_a_wready    (int_ram_grid_a_axil_wready),
    .s_axil_a_bresp     (int_ram_grid_a_axil_bresp),
    .s_axil_a_bvalid    (int_ram_grid_a_axil_bvalid),
    .s_axil_a_bready    (int_ram_grid_a_axil_bready),
    .s_axil_a_araddr    (int_ram_grid_a_axil_araddr),
    .s_axil_a_arprot    (int_ram_grid_a_axil_arprot),
    .s_axil_a_arvalid   (int_ram_grid_a_axil_arvalid),
    .s_axil_a_arready   (int_ram_grid_a_axil_arready),
    .s_axil_a_rdata     (int_ram_grid_a_axil_rdata),
    .s_axil_a_rresp     (int_ram_grid_a_axil_rresp),
    .s_axil_a_rvalid    (int_ram_grid_a_axil_rvalid),
    .s_axil_a_rready    (int_ram_grid_a_axil_rready),
    .s_axil_b_awaddr    (int_ram_grid_b_axil_awaddr),
    .s_axil_b_awprot    (int_ram_grid_b_axil_awprot),
    .s_axil_b_awvalid   (int_ram_grid_b_axil_awvalid),
    .s_axil_b_awready   (int_ram_grid_b_axil_awready),
    .s_axil_b_wdata     (int_ram_grid_b_axil_wdata),
    .s_axil_b_wstrb     (int_ram_grid_b_axil_wstrb),
    .s_axil_b_wvalid    (int_ram_grid_b_axil_wvalid),
    .s_axil_b_wready    (int_ram_grid_b_axil_wready),
    .s_axil_b_bresp     (int_ram_grid_b_axil_bresp),
    .s_axil_b_bvalid    (int_ram_grid_b_axil_bvalid),
    .s_axil_b_bready    (int_ram_grid_b_axil_bready),
    .s_axil_b_araddr    (int_ram_grid_b_axil_araddr),
    .s_axil_b_arprot    (int_ram_grid_b_axil_arprot),
    .s_axil_b_arvalid   (int_ram_grid_b_axil_arvalid),
    .s_axil_b_arready   (int_ram_grid_b_axil_arready),
    .s_axil_b_rdata     (int_ram_grid_b_axil_rdata),
    .s_axil_b_rresp     (int_ram_grid_b_axil_rresp),
    .s_axil_b_rvalid    (int_ram_grid_b_axil_rvalid),
    .s_axil_b_rready    (int_ram_grid_b_axil_rready)
  );

  // Connect Port A to S_AXIL_GRID interface
  assign int_ram_grid_a_axil_aclk     = s_axil_grid_aclk;
  assign int_ram_grid_a_axil_arst     = fsm_rst;
  assign int_ram_grid_a_axil_awaddr   = s_axil_grid_awaddr;
  assign int_ram_grid_a_axil_awprot   = s_axil_grid_awprot;
  assign int_ram_grid_a_axil_awvalid  = s_axil_grid_awvalid;
  assign s_axil_grid_awready          = int_ram_grid_a_axil_awready;
  assign int_ram_grid_a_axil_wdata    = s_axil_grid_wdata;
  assign int_ram_grid_a_axil_wstrb    = s_axil_grid_wstrb;
  assign int_ram_grid_a_axil_wvalid   = s_axil_grid_wvalid;
  assign s_axil_grid_wready           = int_ram_grid_a_axil_wready;
  assign s_axil_grid_bresp            = int_ram_grid_a_axil_bresp;
  assign s_axil_grid_bvalid           = int_ram_grid_a_axil_bvalid;
  assign int_ram_grid_a_axil_bready   = s_axil_grid_bready;
  assign int_ram_grid_a_axil_araddr   = s_axil_grid_araddr;
  assign int_ram_grid_a_axil_arprot   = s_axil_grid_arprot;
  assign int_ram_grid_a_axil_arvalid  = s_axil_grid_arvalid;
  assign s_axil_grid_arready          = int_ram_grid_a_axil_arready;
  assign s_axil_grid_rdata            = int_ram_grid_a_axil_rdata;
  assign s_axil_grid_rresp            = int_ram_grid_a_axil_rresp;
  assign s_axil_grid_rvalid           = int_ram_grid_a_axil_rvalid;
  assign int_ram_grid_a_axil_rready   = s_axil_grid_rready;

 `endif

 `ifdef GRID_IF_IS_BRAM
    /**********************************************
      Interface Translator between BRAM Controller
      and Grid BRAM

      Naming conventions
      - int_ : internal signal
      - _ctrl_ : indicates a translator module
      - _i : input / slave interface
      - _o : output / master interface
    *********************************************/
    wire                                    int_bram_ctrl_grid_en_i;
    wire [BRAM_CTRL_WE-1:0]                 int_bram_ctrl_grid_we_i;
    wire [GRID_ITRL_ADDR-1:0]               int_bram_ctrl_grid_addr_i;
    wire [BRAM_CTRL_WIDTH-1:0]              int_bram_ctrl_grid_wrdata_i;
    wire [BRAM_CTRL_WIDTH-1:0]              int_bram_ctrl_grid_rddata_i;
    
    wire [GRID_BANKS-1:0]                   int_bram_ctrl_grid_en_o;
    wire [(GRID_BANKS*DATA_WE)-1:0]         int_bram_ctrl_grid_we_o;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_bram_ctrl_grid_addr_o;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_bram_ctrl_grid_wrdata_o;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_bram_ctrl_grid_rddata_o;

    BramIntrfTranslator # (
      .IN_WIDTH  (BRAM_CTRL_WIDTH),
      .OUT_WIDTH (DATA_WIDTH_GRID),
      .BANKS     (GRID_BANKS),
      .OUT_DEPTH (GRID_BANK_DEPTH),
      .OUT_ADDR  (GRID_ADDR)
    ) grid_bram_interface_translator_inst (
      .en_i      (int_bram_ctrl_grid_en_i),
      .we_i      (int_bram_ctrl_grid_we_i),
      .addr_i    (int_bram_ctrl_grid_addr_i),
      .wrdata_i  (int_bram_ctrl_grid_wrdata_i),
      .rddata_i  (int_bram_ctrl_grid_rddata_i),
      .en_o      (int_bram_ctrl_grid_en_o),
      .we_o      (int_bram_ctrl_grid_we_o),
      .addr_o    (int_bram_ctrl_grid_addr_o),
      .wrdata_o  (int_bram_ctrl_grid_wrdata_o),
      .rddata_o  (int_bram_ctrl_grid_rddata_o)
    );

    /**********************************************
      Grid Multi-Bank Dual-Port BRAM

      Naming conventions
      - int_ : internal signal
      - _a : port a (control port)
      - _b : port b (internal use)
    *********************************************/
    wire                                    int_ram_grid_bram_clk_a;
    wire [GRID_BANKS-1:0]                   int_ram_grid_bram_en_a;
    wire [(GRID_BANKS*DATA_WE)-1:0]         int_ram_grid_bram_we_a;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_ram_grid_bram_addr_a;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_grid_bram_wrdata_a;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_grid_bram_rddata_a;

    wire [GRID_BANKS-1:0]                   int_ram_grid_bram_en_b;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_ram_grid_bram_addr_b;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_ram_grid_bram_rddata_b;
    wire [GRID_BANKS-1:0]                   int_ram_grid_bram_rdack_b;

    MultiBankBram #(
      .BANKS  (GRID_BANKS),
      .WIDTH  (DATA_WIDTH_GRID),
      .DEPTH  (GRID_BANK_DEPTH),
      .ADDR   (GRID_ADDR)
    ) grid_multi_bank_bram_inst (
      .clk    (int_ram_grid_bram_clk_a),
      .ena    (int_ram_grid_bram_en_a),
      .wea    (int_ram_grid_bram_we_a),
      .addra  (int_ram_grid_bram_addr_a),
      .dina   (int_ram_grid_bram_wrdata_a),
      .douta  (int_ram_grid_bram_rddata_a),
      .enb    (int_ram_grid_bram_en_b),
      .addrb  (int_ram_grid_bram_addr_b),
      .doutb  (int_ram_grid_bram_rddata_b),
      .validb (int_ram_grid_bram_rdack_b)
    );
  
 `endif

 `ifdef SCALE_IF_IS_AXIL
  
  if (~SHARE_SCALE) begin
    initial begin
      $display("Configuration error : SHARE_SCALE can only be used with AXI-Lite interface.");
      $finish;
    end
  end

  /**********************************************
    AXI-Lite Scale register

    The axi-lite signals are immediatly
    connected to the axi-lite
    external slave interface
    without internal signals.

    Naming conventions
    - int_ : internal signal
    - _axil_ : axi-lite
  *********************************************/

  // Port A
  wire                        int_ram_scle_a_axil_aclk;
  wire                        int_ram_scle_a_axil_arst;
  // Keep Write channels of Port A
  wire [SCALE_ADDR-1:0]       int_ram_scle_a_axil_awaddr;
  wire [2:0]                  int_ram_scle_a_axil_awprot;
  wire                        int_ram_scle_a_axil_awvalid;
  wire                        int_ram_scle_a_axil_awready;
  wire [DATA_WIDTH_SCALE-1:0] int_ram_scle_a_axil_wdata;
  wire [1-1:0]                int_ram_scle_a_axil_wstrb;
  wire                        int_ram_scle_a_axil_wvalid;
  wire                        int_ram_scle_a_axil_wready;
  wire [1:0]                  int_ram_scle_a_axil_bresp;
  wire                        int_ram_scle_a_axil_bvalid;
  wire                        int_ram_scle_a_axil_bready;
  // Keep Read channels of Port A
  wire [SCALE_ADDR-1:0]       int_ram_scle_a_axil_araddr;
  wire [2:0]                  int_ram_scle_a_axil_arprot;
  wire                        int_ram_scle_a_axil_arvalid;
  wire                        int_ram_scle_a_axil_arready;
  wire [DATA_WIDTH_SCALE-1:0] int_ram_scle_a_axil_rdata;
  wire [1:0]                  int_ram_scle_a_axil_rresp;
  wire                        int_ram_scle_a_axil_rvalid;
  wire                        int_ram_scle_a_axil_rready;

  // Port B
  wire                        int_ram_scle_b_axil_aclk;
  wire                        int_ram_scle_b_axil_arst;
  // Drop Write channels of Port B
  wire [SCALE_ADDR-1:0]       int_ram_scle_b_axil_awaddr = {SCALE_ADDR{1'b0}};
  wire [2:0]                  int_ram_scle_b_axil_awprot = {2'b00};
  wire                        int_ram_scle_b_axil_awvalid = 1'b0;
  wire                        int_ram_scle_b_axil_awready;
  wire [DATA_WIDTH_SCALE-1:0] int_ram_scle_b_axil_wdata = {SCALE_ADDR{1'b0}};
  wire [1-1:0]                int_ram_scle_b_axil_wstrb = 1'b0;
  wire                        int_ram_scle_b_axil_wvalid = 1'b0;
  wire                        int_ram_scle_b_axil_wready = 1'b0;
  wire [1:0]                  int_ram_scle_b_axil_bresp;
  wire                        int_ram_scle_b_axil_bvalid;
  wire                        int_ram_scle_b_axil_bready = 1'b0;
  // Keep Read channels of Port B
  wire [SCALE_ADDR-1:0]       int_ram_scle_b_axil_araddr;
  wire [2:0]                  int_ram_scle_b_axil_arprot;
  wire                        int_ram_scle_b_axil_arvalid;
  wire                        int_ram_scle_b_axil_arready;
  wire [DATA_WIDTH_SCALE-1:0] int_ram_scle_b_axil_rdata;
  wire [1:0]                  int_ram_scle_b_axil_rresp;
  wire                        int_ram_scle_b_axil_rvalid;
  wire                        int_ram_scle_b_axil_rready;

  axil_dp_ram # (
    .DATA_WIDTH         (DATA_WIDTH_SCALE),
    .ADDR_WIDTH         (SCALE_ADDR),
    .STRB_WIDTH         (1),
    .PIPELINE_OUTPUT    (PIPELINE_OUTPUT_SCALE)
  ) scle_axil_ram (
    .a_clk              (int_ram_scle_a_axil_aclk),
    .a_rst              (int_ram_scle_a_axil_arst),
    .b_clk              (int_ram_scle_b_axil_aclk),
    .b_rst              (int_ram_scle_b_axil_arst),
    .s_axil_a_awaddr    (int_ram_scle_a_axil_awaddr),
    .s_axil_a_awprot    (int_ram_scle_a_axil_awprot),
    .s_axil_a_awvalid   (int_ram_scle_a_axil_awvalid),
    .s_axil_a_awready   (int_ram_scle_a_axil_awready),
    .s_axil_a_wdata     (int_ram_scle_a_axil_wdata),
    .s_axil_a_wstrb     (int_ram_scle_a_axil_wstrb),
    .s_axil_a_wvalid    (int_ram_scle_a_axil_wvalid),
    .s_axil_a_wready    (int_ram_scle_a_axil_wready),
    .s_axil_a_bresp     (int_ram_scle_a_axil_bresp),
    .s_axil_a_bvalid    (int_ram_scle_a_axil_bvalid),
    .s_axil_a_bready    (int_ram_scle_a_axil_bready),
    .s_axil_a_araddr    (int_ram_scle_a_axil_araddr),
    .s_axil_a_arprot    (int_ram_scle_a_axil_arprot),
    .s_axil_a_arvalid   (int_ram_scle_a_axil_arvalid),
    .s_axil_a_arready   (int_ram_scle_a_axil_arready),
    .s_axil_a_rdata     (int_ram_scle_a_axil_rdata),
    .s_axil_a_rresp     (int_ram_scle_a_axil_rresp),
    .s_axil_a_rvalid    (int_ram_scle_a_axil_rvalid),
    .s_axil_a_rready    (int_ram_scle_a_axil_rready),
    .s_axil_b_awaddr    (int_ram_scle_b_axil_awaddr),
    .s_axil_b_awprot    (int_ram_scle_b_axil_awprot),
    .s_axil_b_awvalid   (int_ram_scle_b_axil_awvalid),
    .s_axil_b_awready   (int_ram_scle_b_axil_awready),
    .s_axil_b_wdata     (int_ram_scle_b_axil_wdata),
    .s_axil_b_wstrb     (int_ram_scle_b_axil_wstrb),
    .s_axil_b_wvalid    (int_ram_scle_b_axil_wvalid),
    .s_axil_b_wready    (int_ram_scle_b_axil_wready),
    .s_axil_b_bresp     (int_ram_scle_b_axil_bresp),
    .s_axil_b_bvalid    (int_ram_scle_b_axil_bvalid),
    .s_axil_b_bready    (int_ram_scle_b_axil_bready),
    .s_axil_b_araddr    (int_ram_scle_b_axil_araddr),
    .s_axil_b_arprot    (int_ram_scle_b_axil_arprot),
    .s_axil_b_arvalid   (int_ram_scle_b_axil_arvalid),
    .s_axil_b_arready   (int_ram_scle_b_axil_arready),
    .s_axil_b_rdata     (int_ram_scle_b_axil_rdata),
    .s_axil_b_rresp     (int_ram_scle_b_axil_rresp),
    .s_axil_b_rvalid    (int_ram_scle_b_axil_rvalid),
    .s_axil_b_rready    (int_ram_scle_b_axil_rready)
  );

  // Connect Port A to S_AXIL_SCALE interface
  assign int_ram_scle_a_axil_aclk       = s_axil_scle_aclk;
  assign int_ram_scle_a_axil_arst       = s_axil_scle_areset;
  assign int_ram_scle_a_axil_awaddr     = s_axil_scle_awaddr;
  assign int_ram_scle_a_axil_awprot     = s_axil_scle_awprot;
  assign int_ram_scle_a_axil_awvalid    = s_axil_scle_awvalid;
  assign s_axil_scle_awready            = int_ram_scle_a_axil_awready;
  assign int_ram_scle_a_axil_wdata      = s_axil_scle_wdata;
  assign int_ram_scle_a_axil_wstrb      = s_axil_scle_wstrb;
  assign int_ram_scle_a_axil_wvalid     = s_axil_scle_wvalid;
  assign s_axil_scle_wready             = int_ram_scle_a_axil_wready;
  assign s_axil_scle_bresp              = int_ram_scle_a_axil_bresp;
  assign s_axil_scle_bvalid             = int_ram_scle_a_axil_bvalid;
  assign int_ram_scle_a_axil_bready     = s_axil_scle_bready;
  assign int_ram_scle_a_axil_araddr     = s_axil_scle_araddr;
  assign int_ram_scle_a_axil_arprot     = s_axil_scle_arprot;
  assign int_ram_scle_a_axil_arvalid    = s_axil_scle_arvalid;
  assign s_axil_scle_arready            = int_ram_scle_a_axil_arready;
  assign s_axil_scle_rdata              = int_ram_scle_a_axil_rdata;
  assign s_axil_scle_rresp              = int_ram_scle_a_axil_rresp;
  assign s_axil_scle_rvalid             = int_ram_scle_a_axil_rvalid;
  assign int_ram_scle_a_axil_rready     = s_axil_scle_rready;

 `endif

 `ifdef SCALE_IF_IS_BRAM
    /**********************************************
      Interface Translator between BRAM Controller
      and Grid BRAM

      Naming conventions
      - int_ : internal signal
      - _ctrl_ : indicates a translator module
      - _i : input / slave interface
      - _o : output / master interface
    *********************************************/
    wire                                      int_bram_ctrl_scle_en_i;
    wire [BRAM_CTRL_WE-1:0]                   int_bram_ctrl_scle_we_i;
    wire [SCALE_ITRL_ADDR-1:0]                int_bram_ctrl_scle_addr_i;
    wire [BRAM_CTRL_WIDTH-1:0]                int_bram_ctrl_scle_wrdata_i;
    wire [BRAM_CTRL_WIDTH-1:0]                int_bram_ctrl_scle_rddata_i;
    
    wire [SCALE_BANKS-1:0]                    int_bram_ctrl_scle_en_o;
    wire [(SCALE_BANKS*SCALE_WE)-1:0]         int_bram_ctrl_scle_we_o;
    wire [(SCALE_BANKS*SCALE_ADDR)-1:0]       int_bram_ctrl_scle_addr_o;
    wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0] int_bram_ctrl_scle_wrdata_o;
    wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0] int_bram_ctrl_scle_rddata_o;

    BramIntrfTranslator # (
      .IN_WIDTH   (BRAM_CTRL_WIDTH),
      .OUT_WIDTH  (DATA_WIDTH_SCALE),
      .BANKS      (SCALE_BANKS),
      .OUT_DEPTH  (SCALE_BANK_DEPTH),
      .OUT_ADDR   (SCALE_ADDR)
    ) scle_bram_interface_translator_inst (
      .en_i       (int_bram_ctrl_scle_en_i),
      .we_i       (int_bram_ctrl_scle_we_i),
      .addr_i     (int_bram_ctrl_scle_addr_i),
      .wrdata_i   (int_bram_ctrl_scle_wrdata_i),
      .rddata_i   (int_bram_ctrl_scle_rddata_i),
      .en_o       (int_bram_ctrl_scle_en_o),
      .we_o       (int_bram_ctrl_scle_we_o),
      .addr_o     (int_bram_ctrl_scle_addr_o),
      .wrdata_o   (int_bram_ctrl_scle_wrdata_o),
      .rddata_o   (int_bram_ctrl_scle_rddata_o)
    );

    /**********************************************
      Grid Multi-Bank Dual-Port BRAM

      Naming conventions
      - int_ : internal signal
      - _a : port a (control port)
      - _b : port b (internal use)
    *********************************************/
    wire                                      int_ram_scle_bram_clk_a;
    wire [SCALE_BANKS-1:0]                    int_ram_scle_bram_en_a;
    wire [(SCALE_BANKS*SCALE_WE)-1:0]         int_ram_scle_bram_we_a;
    wire [(SCALE_BANKS*SCALE_ADDR)-1:0]       int_ram_scle_bram_addr_a;
    wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0] int_ram_scle_bram_wrdata_a;
    wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0] int_ram_scle_bram_rddata_a;

    wire [SCALE_BANKS-1:0]                    int_ram_scle_bram_en_b;
    wire [(SCALE_BANKS*SCALE_ADDR)-1:0]       int_ram_scle_bram_addr_b;
    wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0] int_ram_scle_bram_rddata_b;
    wire [SCALE_BANKS-1:0]                    int_ram_scle_bram_rdack_b;

    MultiBankBram #(
      .BANKS  (SCALE_BANKS),
      .WIDTH  (DATA_WIDTH_SCALE),
      .DEPTH  (DATA_BANK_DEPTH),
      .ADDR   (SCALE_ADDR)
    ) scle_multi_bank_bram_inst (
      .clk    (int_ram_scle_bram_clk_a),
      .ena    (int_ram_scle_bram_en_a),
      .wea    (int_ram_scle_bram_we_a),
      .addra  (int_ram_scle_bram_addr_a),
      .dina   (int_ram_scle_bram_wrdata_a),
      .douta  (int_ram_scle_bram_rddata_a),
      .enb    (int_ram_scle_bram_en_b),
      .addrb  (int_ram_scle_bram_addr_b),
      .doutb  (int_ram_scle_bram_rddata_b),
      .validb (int_ram_scle_bram_rdack_b)
    );
  
  // bram control interface to the scle bram port a
  assign int_ram_scle_bram_clk_a    = bram_ctrl_scle_clk;
  assign int_ram_scle_bram_en_a     = bram_ctrl_scle_en;
  assign int_ram_scle_bram_we_a     = bram_ctrl_scle_we;
  assign int_ram_scle_bram_addr_a   = bram_ctrl_scle_addr[2 +: SCALE_EXTRL_ADDR];
  assign int_ram_scle_bram_wrdata_a = bram_ctrl_scle_din;
  assign bram_ctrl_scle_dout    = int_ram_scle_bram_rddata_a;
 `endif

  /**********************************************
    Memory Controller

    For now this is a dummy module

    Naming conventions
    - int_ : internal signal
    - mcu : indicates signal that connects
      directly to the MCU
    - _m_axis_ : master axi stream interface
  *********************************************/
  wire mcu_operation_busy;
  wire mcu_operation_complete;
  wire mcu_operation_error;
  wire mcu_transmission = 1'b0;       // Still debating if it should be used or not

 `ifdef DATA_IF_IS_AXIL
  wire [DATA_ADDR-1:0]                              int_mcu_data_m_axil_araddr;
  wire [2:0]                                        int_mcu_data_m_axil_arprot;
  wire                                              int_mcu_data_m_axil_arvalid;
  wire                                              int_mcu_data_m_axil_arready;
  wire [DATA_WIDTH_DATA-1:0]                        int_mcu_data_m_axil_rdata;
  wire [1:0]                                        int_mcu_data_m_axil_rresp;
  wire                                              int_mcu_data_m_axil_rvalid;
  wire                                              int_mcu_data_m_axil_rready;
 `endif

 `ifdef DATA_IF_IS_BRAM
  wire [GRID_BANKS-1:0]                             int_mcu_data_bram_clk;
  wire [DATA_BANKS-1:0]                             int_mcu_data_bram_en;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]                 int_mcu_data_bram_addr;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0]           int_mcu_data_bram_rddata;
  wire [DATA_BANKS-1:0]                             int_mcu_data_bram_rdack;
 `endif

 `ifdef GRID_IF_IS_AXIL
  wire [GRID_ADDR-1:0]                              int_mcu_grid_m_axil_araddr;
  wire [2:0]                                        int_mcu_grid_m_axil_arprot;
  wire                                              int_mcu_grid_m_axil_arvalid;
  wire                                              int_mcu_grid_m_axil_arready;
  wire [DATA_WIDTH_GRID-1:0]                        int_mcu_grid_m_axil_rdata;
  wire [1:0]                                        int_mcu_grid_m_axil_rresp;
  wire                                              int_mcu_grid_m_axil_rvalid;
  wire                                              int_mcu_grid_m_axil_rready;
 `endif
 
 `ifdef GRID_IF_IS_BRAM
  wire [GRID_BANKS-1:0]                             int_mcu_grid_bram_clk;
  wire [GRID_BANKS-1:0]                             int_mcu_grid_bram_en;
  wire [(GRID_BANKS*GRID_ADDR)-1:0]                 int_mcu_grid_bram_addr;
  wire [(GRID_BANKS*DATA_WIDTH_GRID)-1:0]           int_mcu_grid_bram_rddata;
  wire [GRID_BANKS-1:0]                             int_mcu_grid_bram_rdack;
 `endif

 `ifdef SCALE_IF_IS_AXIL
  wire [SCALE_ADDR-1:0]                             int_mcu_scle_m_axil_araddr;
  wire [2:0]                                        int_mcu_scle_m_axil_arprot;
  wire                                              int_mcu_scle_m_axil_arvalid;
  wire                                              int_mcu_scle_m_axil_arready;
  wire [DATA_WIDTH_SCALE-1:0]                       int_mcu_scle_m_axil_rdata;
  wire [1:0]                                        int_mcu_scle_m_axil_rresp;
  wire                                              int_mcu_scle_m_axil_rvalid;
  wire                                              int_mcu_scle_m_axil_rready;
 `endif
 
 `ifdef SCALE_IF_IS_BRAM
  wire [SCALE_BANKS-1:0]                            int_mcu_scle_bram_clk;
  wire [SCALE_BANKS-1:0]                            int_mcu_scle_bram_en;
  wire [(SCALE_BANKS*SCALE_ADDR)-1:0]               int_mcu_scle_bram_addr;
  wire [(SCALE_BANKS*DATA_WIDTH_SCALE)-1:0]         int_mcu_scle_bram_rddata;
  wire [SCALE_BANKS-1:0]                            int_mcu_scle_bram_rdack;
 `endif

  wire                                              int_mcu_data_m_axis_aclk;
  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]          int_mcu_data_m_axis_tdata;
  wire [DATA_CHANNELS-1:0]                          int_mcu_data_m_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                          int_mcu_data_m_axis_tready;
  wire [DATA_CHANNELS-1:0]                          int_mcu_data_m_axis_tlast;

  wire                                              int_mcu_grid_m_axis_aclk;
  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]          int_mcu_grid_m_axis_tdata;
  wire [DATA_CHANNELS-1:0]                          int_mcu_grid_m_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                          int_mcu_grid_m_axis_tready;
  wire [DATA_CHANNELS-1:0]                          int_mcu_grid_m_axis_tlast;

  wire                                              int_mcu_scle_m_axis_aclk;
  wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]    int_mcu_scle_m_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_mcu_scle_m_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_mcu_scle_m_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_mcu_scle_m_axis_tlast;

  MemoryControlUnit #(
    `include "MCUGlobalFSMParametersInst.vh"
   `ifdef BRAM_ACK_SIG_OPTION
    .BRAM_ACK_SIG               (1),
   `endif
    .BATCH_SIZE                 (BATCH_SIZE),
    .DATA_WIDTH_DATA            (DATA_WIDTH_DATA),
    .DATA_WIDTH_SCALE           (DATA_WIDTH_SCALE),
    .ID_ENABLE                  (0),
    .ID_WIDTH                   (1),
    .DEST_ENABLE                (0),
    .DEST_WIDTH                 (1),
    .USER_ENABLE                (0),
    .USER_WIDTH                 (1),
    .DATA_CHANNELS              (DATA_CHANNELS),
    .SHARE_SCALE                (SHARE_SCALE),
    .SHARE_GRID                 (SHARE_GRID),
    .ADDR_WIDTH_DATA            (DATA_ADDR),
    .ADDR_WIDTH_GRID            (GRID_ADDR),
    .ADDR_WIDTH_SCALE           (SCALE_ADDR),
    .FIFO_DEPTH_DATA            (FIFO_DEPTH_DATA),
    .FIFO_DEPTH_GRID            (FIFO_DEPTH_GRID),
    .FIFO_DEPTH_SCALE           (FIFO_DEPTH_SCALE)
  ) mcu_inst (
    .fsm_clk                    (fsm_clk),
    .rst                        (fsm_rst),
    .operation_start            (operation_start),
    .data_size                  (data_size),
    .grid_size                  (grid_size),
    .scle_size                  (scle_size),
    .operation_busy             (mcu_operation_busy),
    .operation_complete         (mcu_operation_complete),
    .operation_error            (mcu_operation_error),
   `ifdef DATA_IF_IS_BRAM
    .data_bram_clk              (int_mcu_data_bram_clk),
    .data_bram_en               (int_mcu_data_bram_en),
    .data_bram_addr             (int_mcu_data_bram_addr),
    .data_bram_rddata           (int_mcu_data_bram_rddata),
    .data_bram_rdack            (int_mcu_data_bram_rdack),
   `endif
   `ifdef DATA_IF_IS_AXIL
    .m_axil_data_araddr         (int_mcu_data_m_axil_araddr),
    .m_axil_data_arprot         (int_mcu_data_m_axil_arprot),
    .m_axil_data_arvalid        (int_mcu_data_m_axil_arvalid),
    .m_axil_data_arready        (int_mcu_data_m_axil_arready),
    .m_axil_data_rdata          (int_mcu_data_m_axil_rdata),
    .m_axil_data_rresp          (int_mcu_data_m_axil_rresp),
    .m_axil_data_rvalid         (int_mcu_data_m_axil_rvalid),
    .m_axil_data_rready         (int_mcu_data_m_axil_rready),
   `endif
    .m_axis_data_aclk           (int_mcu_data_m_axis_aclk),
    .m_axis_data_tdata          (int_mcu_data_m_axis_tdata),
    .m_axis_data_tvalid         (int_mcu_data_m_axis_tvalid),
    .m_axis_data_tready         (int_mcu_data_m_axis_tready),
    .m_axis_data_tlast          (int_mcu_data_m_axis_tlast),
   `ifdef GRID_IF_IS_BRAM
    .grid_bram_clk              (int_mcu_grid_bram_clk),
    .grid_bram_en               (int_mcu_grid_bram_en),
    .grid_bram_addr             (int_mcu_grid_bram_addr),
    .grid_bram_rddata           (int_mcu_grid_bram_rddata),
    .grid_bram_rdack            (int_mcu_grid_bram_rdack),
   `endif
   `ifdef GRID_IF_IS_AXIL
    .m_axil_grid_araddr         (int_mcu_grid_m_axil_araddr),
    .m_axil_grid_arprot         (int_mcu_grid_m_axil_arprot),
    .m_axil_grid_arvalid        (int_mcu_grid_m_axil_arvalid),
    .m_axil_grid_arready        (int_mcu_grid_m_axil_arready),
    .m_axil_grid_rdata          (int_mcu_grid_m_axil_rdata),
    .m_axil_grid_rresp          (int_mcu_grid_m_axil_rresp),
    .m_axil_grid_rvalid         (int_mcu_grid_m_axil_rvalid),
    .m_axil_grid_rready         (int_mcu_grid_m_axil_rready),
   `endif
    .m_axis_grid_aclk           (int_mcu_grid_m_axis_aclk),
    .m_axis_grid_tdata          (int_mcu_grid_m_axis_tdata),
    .m_axis_grid_tvalid         (int_mcu_grid_m_axis_tvalid),
    .m_axis_grid_tready         (int_mcu_grid_m_axis_tready),
    .m_axis_grid_tlast          (int_mcu_grid_m_axis_tlast),
   `ifdef SCALE_IF_IS_BRAM
    .scle_bram_clk              (int_mcu_scle_bram_clk),
    .scle_bram_en               (int_mcu_scle_bram_en),
    .scle_bram_addr             (int_mcu_scle_bram_addr),
    .scle_bram_rddata           (int_mcu_scle_bram_rddata),
    .scle_bram_rdack            (int_mcu_scle_bram_rdack),
   `endif
   `ifdef SCALE_IF_IS_AXIL
    .m_axil_scle_araddr         (int_mcu_scle_m_axil_araddr),
    .m_axil_scle_arprot         (int_mcu_scle_m_axil_arprot),
    .m_axil_scle_arvalid        (int_mcu_scle_m_axil_arvalid),
    .m_axil_scle_arready        (int_mcu_scle_m_axil_arready),
    .m_axil_scle_rdata          (int_mcu_scle_m_axil_rdata),
    .m_axil_scle_rresp          (int_mcu_scle_m_axil_rresp),
    .m_axil_scle_rvalid         (int_mcu_scle_m_axil_rvalid),
    .m_axil_scle_rready         (int_mcu_scle_m_axil_rready),
   `endif
    .m_axis_scle_aclk           (int_mcu_scle_m_axis_aclk),
    .m_axis_scle_tdata          (int_mcu_scle_m_axis_tdata),
    .m_axis_scle_tvalid         (int_mcu_scle_m_axis_tvalid),
    .m_axis_scle_tready         (int_mcu_scle_m_axis_tready),
    .m_axis_scle_tlast          (int_mcu_scle_m_axis_tlast)
  );

  /**********************************************
    Slave AXI Async FIFO
    between the MCU
    and the DPU data stream

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire                                          int_adp_data_s_axis_aclk;
  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_adp_data_s_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_s_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_s_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_s_axis_tlast;

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_adp_data_m_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_m_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_m_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_data_m_axis_tlast;

  axis_async_fifo #(
    .DEPTH          (FIFO_DEPTH_DATA),
    .DATA_WIDTH     (DATA_WIDTH_DATA),
    .KEEP_ENABLE    (0),
    .KEEP_WIDTH     (1),
    .ID_ENABLE      (0),
    .ID_WIDTH       (1),
    .DEST_ENABLE    (0),
    .DEST_WIDTH     (1),
    .USER_ENABLE    (0),
    .USER_WIDTH     (1)
  ) axis_adp_data_inst (
    .s_clk          (int_adp_data_s_axis_aclk),
    .s_rst          (1'b0),
    .s_axis_tdata   (int_adp_data_s_axis_tdata),
    .s_axis_tkeep   (1'b1),
    .s_axis_tvalid  (int_adp_data_s_axis_tvalid),
    .s_axis_tready  (int_adp_data_s_axis_tready),
    .s_axis_tlast   (int_adp_data_s_axis_tlast),
    .s_axis_tid     (1'b0),
    .s_axis_tdest   (1'b0),
    .s_axis_tuser   (1'b0),
    .m_clk          (core_clk),
    .m_rst          (core_rst),
    .m_axis_tdata   (int_adp_data_m_axis_tdata),
    .m_axis_tvalid  (int_adp_data_m_axis_tvalid),
    .m_axis_tready  (int_adp_data_m_axis_tready),
    .m_axis_tlast   (int_adp_data_m_axis_tlast),
    .s_pause_req    (1'b0),
    .m_pause_req    (1'b0)
  );

  /**********************************************
    Slave AXI Async FIFO
    between the MCU
    and the DPU data stream

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire                                          int_adp_grid_s_axis_aclk;
  wire [DATA_CHANNELS*DATA_WIDTH_GRID-1:0]      int_adp_grid_s_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_s_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_s_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_s_axis_tlast;

  wire [DATA_CHANNELS*DATA_WIDTH_GRID-1:0]      int_adp_grid_m_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_m_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_m_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_grid_m_axis_tlast;

  axis_async_fifo #(
    .DEPTH          (FIFO_DEPTH_GRID),
    .DATA_WIDTH     (DATA_WIDTH_GRID),
    .KEEP_ENABLE    (0),
    .KEEP_WIDTH     (1),
    .ID_ENABLE      (0),
    .ID_WIDTH       (1),
    .DEST_ENABLE    (0),
    .DEST_WIDTH     (1),
    .USER_ENABLE    (0),
    .USER_WIDTH     (1)
  ) axis_adp_grid_inst (
    .s_clk          (int_adp_grid_s_axis_aclk),
    .s_rst          (1'b0),
    .s_axis_tdata   (int_adp_grid_s_axis_tdata),
    .s_axis_tkeep   (1'b1),
    .s_axis_tvalid  (int_adp_grid_s_axis_tvalid),
    .s_axis_tready  (int_adp_grid_s_axis_tready),
    .s_axis_tlast   (int_adp_grid_s_axis_tlast),
    .s_axis_tid     (1'b0),
    .s_axis_tdest   (1'b0),
    .s_axis_tuser   (1'b0),
    .m_clk          (core_clk),
    .m_rst          (core_rst),
    .m_axis_tdata   (int_adp_grid_m_axis_tdata),
    .m_axis_tvalid  (int_adp_grid_m_axis_tvalid),
    .m_axis_tready  (int_adp_grid_m_axis_tready),
    .m_axis_tlast   (int_adp_grid_m_axis_tlast),
    .s_pause_req    (1'b0),
    .m_pause_req    (1'b0)
  );

  /**********************************************
    Slave AXI Async FIFO
    between the MCU
    and the DPU data stream

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire                                          int_adp_scle_s_axis_aclk;
  wire [DATA_CHANNELS*DATA_WIDTH_SCALE-1:0]     int_adp_scle_s_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_s_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_s_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_s_axis_tlast;

  wire [DATA_CHANNELS*DATA_WIDTH_SCALE-1:0]     int_adp_scle_m_axis_tdata;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_m_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_m_axis_tready;
  wire [DATA_CHANNELS-1:0]                      int_adp_scle_m_axis_tlast;

  axis_async_fifo #(
    .DEPTH          (FIFO_DEPTH_SCALE),
    .DATA_WIDTH     (DATA_WIDTH_SCALE),
    .KEEP_ENABLE    (0),
    .KEEP_WIDTH     (1),
    .ID_ENABLE      (0),
    .ID_WIDTH       (1),
    .DEST_ENABLE    (0),
    .DEST_WIDTH     (1),
    .USER_ENABLE    (0),
    .USER_WIDTH     (1)
  ) axis_adp_scle_inst (
    .s_clk          (int_adp_scle_s_axis_aclk),
    .s_rst          (1'b0),
    .s_axis_tdata   (int_adp_scle_s_axis_tdata),
    .s_axis_tkeep   (1'b1),
    .s_axis_tvalid  (int_adp_scle_s_axis_tvalid),
    .s_axis_tready  (int_adp_scle_s_axis_tready),
    .s_axis_tlast   (int_adp_scle_s_axis_tlast),
    .s_axis_tid     (1'b0),
    .s_axis_tdest   (1'b0),
    .s_axis_tuser   (1'b0),
    .m_clk          (core_clk),
    .m_rst          (core_rst),
    .m_axis_tdata   (int_adp_scle_m_axis_tdata),
    .m_axis_tvalid  (int_adp_scle_m_axis_tvalid),
    .m_axis_tready  (int_adp_scle_m_axis_tready),
    .m_axis_tlast   (int_adp_scle_m_axis_tlast),
    .s_pause_req    (1'b0),
    .m_pause_req    (1'b0)
  );

  /**********************************************
    Slave AXI Adapter
    between the DMA Master
    and the Weight Streams Splitter 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire                                          int_adp_wght_s_axis_aclk;
  wire [DATA_WIDTH_DMA-1:0]                     int_adp_wght_s_axis_tdata;
  wire [KEEP_WIDTH_DMA-1:0]                     int_adp_wght_s_axis_tkeep;
  wire                                          int_adp_wght_s_axis_tvalid;
  wire                                          int_adp_wght_s_axis_tready;
  wire                                          int_adp_wght_s_axis_tlast;

  wire                                          int_adp_wght_m_axis_aclk;
  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0]  int_adp_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0]  int_adp_wght_m_axis_tkeep;
  wire                                          int_adp_wght_m_axis_tvalid;
  wire                                          int_adp_wght_m_axis_tready;
  wire                                          int_adp_wght_m_axis_tlast;

  axis_async_fifo_adapter #(
    .DEPTH          (FIFO_DEPTH_WEIGHT),
    .S_DATA_WIDTH   (DATA_WIDTH_DMA),
    .M_DATA_WIDTH   (WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT),
    .ID_ENABLE      (WGHT_ID_ENABLE),
    .ID_WIDTH       (WGHT_ID_WIDTH),
    .DEST_ENABLE    (0),
    .DEST_WIDTH     (1),
    .USER_ENABLE    (0),
    .USER_WIDTH     (1)
  ) axis_adp_wght_inst (
    .s_clk          (dma_clk),
    .s_rst          (dma_rst),
    .s_axis_tdata   (int_adp_wght_s_axis_tdata),
    .s_axis_tkeep   (int_adp_wght_s_axis_tkeep),
    .s_axis_tvalid  (int_adp_wght_s_axis_tvalid),
    .s_axis_tready  (int_adp_wght_s_axis_tready),
    .s_axis_tlast   (int_adp_wght_s_axis_tlast),
    .s_axis_tid     (1'b0),
    .s_axis_tdest   (1'b0),
    .s_axis_tuser   (1'b0),
    .m_clk          (core_clk),
    .m_rst          (core_rst),
    .m_axis_tdata   (int_adp_wght_m_axis_tdata),
    .m_axis_tkeep   (int_adp_wght_m_axis_tkeep),
    .m_axis_tvalid  (int_adp_wght_m_axis_tvalid),
    .m_axis_tready  (int_adp_wght_m_axis_tready),
    .m_axis_tlast   (int_adp_wght_m_axis_tlast),
    .s_pause_req    (1'b0),
    .m_pause_req    (1'b0)
  );

  /**********************************************
    Weight streams AXI-Stream Splitter
    betweem the slave AXIS adapter
    and the AXIS Packet Splitter 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_spl_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] int_spl_wght_s_axis_tkeep;
  wire                                         int_spl_wght_s_axis_tvalid;
  wire                                         int_spl_wght_s_axis_tready;
  wire                                         int_spl_wght_s_axis_tlast;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_spl_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   int_spl_wght_m_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   int_spl_wght_m_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                   int_spl_wght_m_axis_tlast;

  AxisSplitter #(
    .OUTPUT_DATA_WIDTH  (DATA_WIDTH_WEIGHT),
    .CHANNELS           (WEIGHT_CHANNELS),
    .INPUT_KEEP_ENABLE  (KEEP_ENABLE_DMA),
    .INPUT_KEEP_WIDTH   (WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT),
    .OUTPUT_KEEP_ENABLE (0),
    .OUTPUT_KEEP_WIDTH  (1),
    .LAST_ENABLE        (1),
    .ID_ENABLE          (WGHT_ID_ENABLE),
    .ID_WIDTH           (WGHT_ID_WIDTH),
    .DEST_ENABLE        (0),
    .DEST_WIDTH         (1),
    .USER_ENABLE        (0),
    .USER_WIDTH         (1),
    .EXTRA_CYCLE        (EXTRA_CYCLE)
  ) axis_spl_wghts_inst (
    .clk                (core_clk),
    .rst                (core_rst),
    .s_axis_tdata       (int_spl_wght_s_axis_tdata),
    .s_axis_tkeep       (int_spl_wght_s_axis_tkeep),
    .s_axis_tvalid      (int_spl_wght_s_axis_tvalid),
    .s_axis_tready      (int_spl_wght_s_axis_tready),
    .s_axis_tlast       (int_spl_wght_s_axis_tlast),
    .m_axis_tdata       (int_spl_wght_m_axis_tdata),
    .m_axis_tvalid      (int_spl_wght_m_axis_tvalid),
    .m_axis_tready      (int_spl_wght_m_axis_tready),
    .m_axis_tlast       (int_spl_wght_m_axis_tlast)
  );

  /**********************************************
    Weight streams AXI-Stream Packet Splitter
    betweem the slave AXIS Splitter
    and the Data Processor 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/
  wire                                         aps_operation_busy;
  wire                                         aps_operation_complete;
  wire                                         aps_operation_error;
  wire                                         aps_external_error = 1'b0;  // To-Do
  wire [WEIGHT_CHANNELS-1:0]                   aps_transmission;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_aps_wght_s_axis_tdata , int_aps_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tvalid, int_aps_wght_m_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tready, int_aps_wght_m_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tlast , int_aps_wght_m_axis_tlast;
  wire [WEIGHT_CHANNELS*WGHT_ID_WIDTH-1:0]     int_aps_wght_s_axis_tid   , int_aps_wght_m_axis_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]        int_aps_wght_s_axis_tdest , int_aps_wght_m_axis_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]        int_aps_wght_s_axis_tuser , int_aps_wght_m_axis_tuser;

  ExtendedAxisPacketSplitter #(
    .CHANNELS           (WEIGHT_CHANNELS),
    .DATA_WIDTH         (DATA_WIDTH_WEIGHT),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .ID_ENABLE          (WGHT_ID_ENABLE),
    .ID_WIDTH           (WGHT_ID_WIDTH),
    .DEST_ENABLE        (0),
    .DEST_WIDTH         (1),
    .USER_ENABLE        (0),
    .USER_WIDTH         (1),
    .PCKT_WIDTH         (PCKT_SIZE_WIDTH),
    .RAISE_NON_DIVISIBLE(1)
  ) axis_aps_wghts_inst (
    .clk                (core_clk),
    .rst                (core_rst),
    .operation_start    (operation_start),
    .pckt_size          (pckt_size),
    .external_error     (aps_external_error),
    .operation_busy     (aps_operation_busy),
    .operation_complete (aps_operation_complete),
    .operation_error    (aps_operation_error),
    .transmission       (aps_transmission),
    .s_axis_tdata       (int_aps_wght_s_axis_tdata),
    .s_axis_tkeep       ({WEIGHT_CHANNELS{1'b1}}),
    .s_axis_tvalid      (int_aps_wght_s_axis_tvalid),  
    .s_axis_tready      (int_aps_wght_s_axis_tready),
    .s_axis_tlast       (int_aps_wght_s_axis_tlast),
    .s_axis_tid         (1'b0),
    .s_axis_tdest       (1'b0),
    .s_axis_tuser       (1'b0),
    .m_axis_tdata       (int_aps_wght_m_axis_tdata),
    .m_axis_tvalid      (int_aps_wght_m_axis_tvalid),
    .m_axis_tready      (int_aps_wght_m_axis_tready),
    .m_axis_tlast       (int_aps_wght_m_axis_tlast)
  );

  /**********************************************
    Result Buffers between the Data Processor 
    and the master AXI-Stream Joiner

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/
  
  wire [BATCH_SIZE*RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_buf_rslt_s_axis_tdata;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_s_axis_tvalid;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_s_axis_tready;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_s_axis_tlast;

  wire [BATCH_SIZE*RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_buf_rslt_m_axis_tdata;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_m_axis_tvalid;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_m_axis_tready;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_buf_rslt_m_axis_tlast;

  genvar BATCH, CHN;
  generate
    for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin
      for (CHN = 0; CHN < RSLT_CHANNELS; CHN = CHN + 1) begin
        localparam BTM_POS = BATCH * RSLT_CHANNELS + CHN;

        axis_register #(
          .DATA_WIDTH     (DATA_WIDTH_RSLT),
          .KEEP_ENABLE    (0),
          .KEEP_WIDTH     (1),
          .LAST_ENABLE    (1),
          .ID_ENABLE      (0),
          .ID_WIDTH       (1),
          .DEST_ENABLE    (0),
          .DEST_WIDTH     (1),
          .USER_ENABLE    (0),
          .USER_WIDTH     (1),
          .REG_TYPE       (1)
        ) axis_register_up_inst (
          .clk            (core_clk),
          .rst            (core_rst),
          .s_axis_tdata   (int_buf_rslt_s_axis_tdata  [BTM_POS*DATA_WIDTH_RSLT +: DATA_WIDTH_RSLT]),
          .s_axis_tkeep   (1'b1), 
          .s_axis_tvalid  (int_buf_rslt_s_axis_tvalid [BTM_POS]),
          .s_axis_tready  (int_buf_rslt_s_axis_tready [BTM_POS]),
          .s_axis_tlast   (int_buf_rslt_s_axis_tlast  [BTM_POS]),
          .s_axis_tid     (1'b0),
          .s_axis_tdest   (1'b0),
          .s_axis_tuser   (1'b0),
          .m_axis_tdata   (int_buf_rslt_m_axis_tdata  [BTM_POS*DATA_WIDTH_RSLT +: DATA_WIDTH_RSLT]),
          .m_axis_tvalid  (int_buf_rslt_m_axis_tvalid [BTM_POS]),
          .m_axis_tready  (int_buf_rslt_m_axis_tready [BTM_POS]),
          .m_axis_tlast   (int_buf_rslt_m_axis_tlast  [BTM_POS])
        );
      end
    end
  endgenerate

  /**********************************************
    Result streams AXI-Stream Joiner between
    the Data Processor and the master AXI adp 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/
  wire jnr_operation_busy;
  wire jnr_operation_complete;
  wire jnr_operation_error;
  wire jnr_transmission;
  wire jnr_interrupt = 1'b0;      // To-Do

  wire [BATCH_SIZE*RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_jnr_rslt_s_axis_tdata;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_jnr_rslt_s_axis_tvalid;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_jnr_rslt_s_axis_tready;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]                  int_jnr_rslt_s_axis_tlast;

  wire [DATA_WIDTH_RSLT-1:0]                           int_jnr_rslt_m_axis_tdata;
  wire                                                 int_jnr_rslt_m_axis_tvalid;
  wire                                                 int_jnr_rslt_m_axis_tready;
  wire                                                 int_jnr_rslt_m_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]                             int_jnr_rslt_m_axis_tid;

  BatchedAxisPacketJoiner #(
    .CHANNELS           (RSLT_CHANNELS),
    .BATCH_SIZE         (BATCH_SIZE),
    .DATA_WIDTH         (DATA_WIDTH_RSLT),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .ID_ENABLE          (0),
    .S_ID_WIDTH         (1),
    .M_ID_WIDTH         (RSLT_ID_WIDTH),
    .DEST_ENABLE        (0),
    .DEST_WIDTH         (1),
    .USER_ENABLE        (0),
    .USER_WIDTH         (1)
  ) wrapper (
    .clk                (core_clk),
    .rst                (core_rst),
    .operation_start    (operation_start),
    .use_channels       (use_channels),
    .use_batch          (use_batch),
    .interrupt          (jnr_interrupt),
    .operation_busy     (jnr_operation_busy),
    .operation_complete (jnr_operation_complete),
    .operation_error    (jnr_operation_error),
    .transmission       (jnr_transmission),       // Active high if bus transmitted data in the current cycle
    .s_axis_tdata       (int_jnr_rslt_s_axis_tdata),
    .s_axis_tkeep       (1'b1),
    .s_axis_tvalid      (int_jnr_rslt_s_axis_tvalid),  
    .s_axis_tready      (int_jnr_rslt_s_axis_tready),
    .s_axis_tlast       (int_jnr_rslt_s_axis_tlast),
    .s_axis_tid         ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .s_axis_tdest       ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .s_axis_tuser       ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .m_axis_tdata       (int_jnr_rslt_m_axis_tdata),
    .m_axis_tvalid      (int_jnr_rslt_m_axis_tvalid),
    .m_axis_tready      (int_jnr_rslt_m_axis_tready),
    .m_axis_tlast       (int_jnr_rslt_m_axis_tlast),
    .m_axis_tid         (int_jnr_rslt_m_axis_tid)
  );

  /**********************************************
    Master AXI adp between
    the Result Streams Joiner
    and the DMA slave

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [DATA_WIDTH_RSLT-1:0]  int_adp_rslt_s_axis_tdata;
  wire                        int_adp_rslt_s_axis_tvalid;
  wire                        int_adp_rslt_s_axis_tready;
  wire                        int_adp_rslt_s_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]    int_adp_rslt_s_axis_tid;

  wire [DATA_WIDTH_DMA-1:0]   int_adp_rslt_m_axis_tdata;
  wire [KEEP_WIDTH_DMA-1:0]   int_adp_rslt_m_axis_tkeep;
  wire                        int_adp_rslt_m_axis_tvalid;
  wire                        int_adp_rslt_m_axis_tready;
  wire                        int_adp_rslt_m_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]    int_adp_rslt_m_axis_tid;

  axis_async_fifo_adapter #(
    .DEPTH          (FIFO_DEPTH_RSLT),
    .S_DATA_WIDTH   (DATA_WIDTH_RSLT),
    .S_KEEP_ENABLE  (0),
    .S_KEEP_WIDTH   (1),
    .M_DATA_WIDTH   (DATA_WIDTH_DMA),
    .M_KEEP_ENABLE  (KEEP_ENABLE_DMA),
    .M_KEEP_WIDTH   (KEEP_WIDTH_DMA),
    .ID_ENABLE      (RSLT_ID_ENABLE),
    .ID_WIDTH       (RSLT_ID_WIDTH),
    .DEST_ENABLE    (0),
    .DEST_WIDTH     (1),
    .USER_ENABLE    (0),
    .USER_WIDTH     (1)
  ) axis_adp_rslt_inst (
    .s_clk          (core_clk),
    .s_rst          (core_rst),
    .s_axis_tdata   (int_adp_rslt_s_axis_tdata),
    .s_axis_tkeep   (1'b1),
    .s_axis_tvalid  (int_adp_rslt_s_axis_tvalid),
    .s_axis_tready  (int_adp_rslt_s_axis_tready),
    .s_axis_tlast   (int_adp_rslt_s_axis_tlast),
    .s_axis_tid     (int_adp_rslt_s_axis_tid),
    .s_axis_tdest   (1'b0),
    .s_axis_tuser   (1'b0),
    .m_clk          (dma_clk),
    .m_rst          (dma_rst),
    .m_axis_tdata   (int_adp_rslt_m_axis_tdata),
    .m_axis_tkeep   (int_adp_rslt_m_axis_tkeep),
    .m_axis_tvalid  (int_adp_rslt_m_axis_tvalid),
    .m_axis_tready  (int_adp_rslt_m_axis_tready),
    .m_axis_tlast   (int_adp_rslt_m_axis_tlast),
    .m_axis_tid     (int_adp_rslt_m_axis_tid)
  );

  /**********************************************
    KAN parallelized datastream
    systolic array processor

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : slave interface
    - _m_ : master interface
  *********************************************/

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]        int_dpu_data_s_axis_tdata;
  wire [DATA_CHANNELS-1:0]                        int_dpu_data_s_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                        int_dpu_data_s_axis_tready;
  wire [DATA_CHANNELS-1:0]                        int_dpu_data_s_axis_tlast;

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]        int_dpu_grid_s_axis_tdata;
  wire [DATA_CHANNELS-1:0]                        int_dpu_grid_s_axis_tvalid;
  wire [DATA_CHANNELS-1:0]                        int_dpu_grid_s_axis_tready;
  wire [DATA_CHANNELS-1:0]                        int_dpu_grid_s_axis_tlast;
                                                                  
  wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]  int_dpu_scle_s_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tlast;
                                                                  
  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0]    int_dpu_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tlast;

  wire [RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]        int_dpu_rslt_m_axis_tdata;
  wire [RSLT_CHANNELS-1:0]                        int_dpu_rslt_m_axis_tvalid;
  wire [RSLT_CHANNELS-1:0]                        int_dpu_rslt_m_axis_tready;
  wire [RSLT_CHANNELS-1:0]                        int_dpu_rslt_m_axis_tlast;

  ParallelizedDataProcessor #(
    .BATCH_SIZE                   (BATCH_SIZE),
    .DATA_WIDTH_DATA              (DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA         (FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_SCALE             (DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE        (FRACTIONAL_BITS_SCALE),
    .DATA_WIDTH_WEIGHT            (DATA_WIDTH_WEIGHT),
    .FRACTIONAL_BITS_WEIGHT       (FRACTIONAL_BITS_WEIGHT),
    .DATA_WIDTH_SCALED_DIFF       (DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_SCALED_DIFF  (FRACTIONAL_BITS_SCALED_DIFF),
    .DATA_WIDTH_ACT               (DATA_WIDTH_ACT),
    .FRACTIONAL_BITS_ACT          (FRACTIONAL_BITS_ACT),
    .DATA_WIDTH_RSLT              (DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT         (FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE                  (0),
    .ID_ENABLE                    (0),
    .DEST_ENABLE                  (0),
    .USER_ENABLE                  (0),
    .DATA_CHANNELS                (DATA_CHANNELS),
    .RSLT_CHANNELS                (RSLT_CHANNELS),
    .SHARE_SCALE                  (SHARE_SCALE),
    .ROM_DATA_PATH                (ROM_DATA_PATH),
    .OUTPUT_DEST                  (0),
    .OUTPUT_ID                    (0)
  ) data_processor_inst (
    .clk                          (core_clk),
    .rst                          (~fsm_rst),
    .s_axis_data_tdata            (int_dpu_data_s_axis_tdata),
    .s_axis_data_tvalid           (int_dpu_data_s_axis_tvalid),
    .s_axis_data_tready           (int_dpu_data_s_axis_tready),
    .s_axis_data_tlast            (int_dpu_data_s_axis_tlast),
    .s_axis_data_tid              (1'b0),
    .s_axis_data_tdest            (1'b0),
    .s_axis_data_tuser            (1'b0),
    .s_axis_grid_tdata            (int_dpu_grid_s_axis_tdata),
    .s_axis_grid_tvalid           (int_dpu_grid_s_axis_tvalid),
    .s_axis_grid_tready           (int_dpu_grid_s_axis_tready),
    .s_axis_grid_tlast            (int_dpu_grid_s_axis_tlast),
    .s_axis_grid_tid              (1'b0),
    .s_axis_grid_tdest            (1'b0),
    .s_axis_grid_tuser            (1'b0),
    .s_axis_scle_tdata            (int_dpu_scle_s_axis_tdata),
    .s_axis_scle_tvalid           (int_dpu_scle_s_axis_tvalid),
    .s_axis_scle_tready           (int_dpu_scle_s_axis_tready),
    .s_axis_scle_tlast            (int_dpu_scle_s_axis_tlast),
    .s_axis_scle_tid              (1'b0),
    .s_axis_scle_tdest            (1'b0),
    .s_axis_scle_tuser            (1'b0),
    .s_axis_wght_tdata            (int_dpu_wght_s_axis_tdata),
    .s_axis_wght_tvalid           (int_dpu_wght_s_axis_tvalid),
    .s_axis_wght_tready           (int_dpu_wght_s_axis_tready),
    .s_axis_wght_tlast            (int_dpu_wght_s_axis_tlast),
    .s_axis_wght_tid              (1'b0),
    .s_axis_wght_tdest            (1'b0),
    .s_axis_wght_tuser            (1'b0),
    .m_axis_data_tdata            (int_dpu_rslt_m_axis_tdata),
    .m_axis_data_tvalid           (int_dpu_rslt_m_axis_tvalid),
    .m_axis_data_tready           (int_dpu_rslt_m_axis_tready),
    .m_axis_data_tlast            (int_dpu_rslt_m_axis_tlast),
    .err_unalligned_data          (err_unalligned_data),
    .core_rst                     (core_rst)
  );

  /**********************************************
    AXI-Lite Control Registers
    of the whole Core
  **********************************************/

  CentralControlUnit #(
    `include "SystemSizesInst.vh"
    .DATA_CHANNELS                  (DATA_CHANNELS),
    .RSLT_CHANNELS                  (RSLT_CHANNELS),
    .ADDR_WIDTH_DATA                (DATA_ADDR),
    .ADDR_WIDTH_GRID                (GRID_ADDR),
    .ADDR_WIDTH_SCALE               (SCALE_ADDR),
    .PCKT_SIZE_WIDTH                (PCKT_SIZE_WIDTH)
  ) ccu (
    .fsm_clk                        (fsm_clk),
    .rst                            (fsm_rst),
    .operation_start                (operation_start),
    .data_size                      (data_size),
    .grid_size                      (grid_size),
    .scle_size                      (scle_size),
    .pckt_size                      (pckt_size),
    .use_channels                   (use_channels),
    .use_batch                      (use_batch),
    .peripheral_operation_busy      (peripheral_operation_busy),
    .peripheral_operation_complete  (peripheral_operation_complete),
    .peripheral_operation_error     (peripheral_operation_error),
    .peripheral_transmission        (peripheral_transmission),
    .rslt_tlast                     (rslt_tlast),
    .operation_busy                 (operation_busy),
    .operation_complete             (operation_complete),
    .operation_error                (operation_error),
    .internal_operation_error       (internal_operation_error),
    .locked                         (locked),
    .pl2ps_intr                     (pl2ps_intr),
    .s_axil_awaddr                  (s_axil_ctrl_awaddr),
    .s_axil_awprot                  (s_axil_ctrl_awprot),
    .s_axil_awvalid                 (s_axil_ctrl_awvalid),
    .s_axil_awready                 (s_axil_ctrl_awready),
    .s_axil_wdata                   (s_axil_ctrl_wdata),
    .s_axil_wstrb                   (s_axil_ctrl_wstrb),
    .s_axil_wvalid                  (s_axil_ctrl_wvalid),
    .s_axil_wready                  (s_axil_ctrl_wready),
    .s_axil_bresp                   (s_axil_ctrl_bresp),
    .s_axil_bvalid                  (s_axil_ctrl_bvalid),
    .s_axil_bready                  (s_axil_ctrl_bready),
    .s_axil_araddr                  (s_axil_ctrl_araddr),
    .s_axil_arprot                  (s_axil_ctrl_arprot),
    .s_axil_arvalid                 (s_axil_ctrl_arvalid),
    .s_axil_arready                 (s_axil_ctrl_arready),
    .s_axil_rdata                   (s_axil_ctrl_rdata),
    .s_axil_rresp                   (s_axil_ctrl_rresp),
    .s_axil_rvalid                  (s_axil_ctrl_rvalid),
    .s_axil_rready                  (s_axil_ctrl_rready)
  );

  /*************************************************************************************
   Internal Sinals Connections and Direct Assignments
  *************************************************************************************/

 `ifdef DATA_IF_IS_AXIL
  assign int_ram_data_b_axil_aclk     = s_axil_data_aclk;
  assign int_ram_data_b_axil_arst     = s_axil_data_areset;
  assign int_ram_data_b_axil_araddr   = int_mcu_data_m_axil_araddr;
  assign int_ram_data_b_axil_arprot   = int_mcu_data_m_axil_arprot;
  assign int_ram_data_b_axil_arvalid  = int_mcu_data_m_axil_arvalid;
  assign int_mcu_data_m_axil_arready  = int_ram_data_b_axil_arready;
  assign int_mcu_data_m_axil_rdata    = int_ram_data_b_axil_rdata;
  assign int_mcu_data_m_axil_rresp    = int_ram_data_b_axil_rresp;
  assign int_mcu_data_m_axil_rvalid   = int_ram_data_b_axil_rvalid;
  assign int_ram_data_b_axil_rready   = int_mcu_data_m_axil_rready;
 `endif

 `ifdef DATA_IF_IS_BRAM
  // bram control interface to the data bram translator
  assign int_bram_ctrl_data_en_i      = bram_ctrl_data_en;
  assign int_bram_ctrl_data_we_i      = bram_ctrl_data_we;
  assign int_bram_ctrl_data_addr_i    = bram_ctrl_data_addr[2 +: DATA_ITRL_ADDR];
  assign int_bram_ctrl_data_wrdata_i  = bram_ctrl_data_din;
  assign bram_ctrl_data_dout          = int_bram_ctrl_data_rddata_i;

  // data bram translator to data bram port a
  assign int_ram_data_bram_clk_a      = bram_ctrl_data_clk;
  assign int_ram_data_bram_en_a       = int_bram_ctrl_data_en_o;
  assign int_ram_data_bram_we_a       = int_bram_ctrl_data_we_o;
  assign int_ram_data_bram_addr_a     = int_bram_ctrl_data_addr_o;
  assign int_ram_data_bram_wrdata_a   = int_bram_ctrl_data_wrdata_o;
  assign int_bram_ctrl_data_rddata_o  = int_ram_data_bram_rddata_a;

  // data bram port b to memory control unit
  assign int_mcu_data_bram_clk        = int_ram_data_bram_clk_a;
  assign int_ram_data_bram_en_b       = int_mcu_data_bram_en;
  assign int_ram_data_bram_addr_b     = int_mcu_data_bram_addr;
  assign int_mcu_data_bram_rddata     = int_ram_data_bram_rddata_b;
  assign int_mcu_data_bram_rdack      = int_ram_data_bram_rdack_b;
 `endif
 
 `ifdef GRID_IF_IS_AXIL
  assign int_ram_grid_b_axil_aclk     = s_axil_grid_aclk;
  assign int_ram_grid_b_axil_arst     = s_axil_grid_areset;
  assign int_ram_grid_b_axil_araddr   = int_mcu_grid_m_axil_araddr;
  assign int_ram_grid_b_axil_arprot   = int_mcu_grid_m_axil_arprot;
  assign int_ram_grid_b_axil_arvalid  = int_mcu_grid_m_axil_arvalid;
  assign int_mcu_grid_m_axil_arready  = int_ram_grid_b_axil_arready;
  assign int_mcu_grid_m_axil_rdata    = int_ram_grid_b_axil_rdata;
  assign int_mcu_grid_m_axil_rresp    = int_ram_grid_b_axil_rresp;
  assign int_mcu_grid_m_axil_rvalid   = int_ram_grid_b_axil_rvalid;
  assign int_ram_grid_b_axil_rready   = int_mcu_grid_m_axil_rready;
 `endif

 `ifdef GRID_IF_IS_BRAM
  // bram control interface to the grid bram port a
  assign int_ram_grid_bram_clk_a      = bram_ctrl_grid_clk;
  assign int_ram_grid_bram_en_a       = bram_ctrl_grid_en;
  assign int_ram_grid_bram_we_a       = bram_ctrl_grid_we;
  assign int_ram_grid_bram_addr_a     = bram_ctrl_grid_addr[2 +: GRID_EXTRL_ADDR];
  assign int_ram_grid_bram_wrdata_a   = bram_ctrl_grid_din;
  assign bram_ctrl_grid_dout          = int_ram_grid_bram_rddata_a;

  // grid bram port b to memory control unit
  assign int_mcu_grid_bram_clk        = int_ram_grid_bram_clk_a;
  assign int_ram_grid_bram_en_b       = int_mcu_grid_bram_en;
  assign int_ram_grid_bram_addr_b     = int_mcu_grid_bram_addr;
  assign int_mcu_grid_bram_rddata     = int_ram_grid_bram_rddata_b;
  assign int_mcu_grid_bram_rdack      = int_ram_grid_bram_rdack_b;
 `endif

 `ifdef SCALE_IF_IS_AXIL
  assign int_ram_scle_b_axil_aclk     = s_axil_scle_aclk;
  assign int_ram_scle_b_axil_arst     = s_axil_scle_areset;
  assign int_ram_scle_b_axil_araddr   = int_mcu_scle_m_axil_araddr;
  assign int_ram_scle_b_axil_arprot   = int_mcu_scle_m_axil_arprot;
  assign int_ram_scle_b_axil_arvalid  = int_mcu_scle_m_axil_arvalid;
  assign int_mcu_scle_m_axil_arready  = int_ram_scle_b_axil_arready;
  assign int_mcu_scle_m_axil_rdata    = int_ram_scle_b_axil_rdata;
  assign int_mcu_scle_m_axil_rresp    = int_ram_scle_b_axil_rresp;
  assign int_mcu_scle_m_axil_rvalid   = int_ram_scle_b_axil_rvalid;
  assign int_ram_scle_b_axil_rready   = int_mcu_scle_m_axil_rready;
 `endif

 `ifdef SCALE_IF_IS_BRAM

  // bram control interface to the scle bram port a
  assign int_ram_scle_bram_clk_a      = bram_ctrl_scle_clk;
  assign int_ram_scle_bram_en_a       = bram_ctrl_scle_en;
  assign int_ram_scle_bram_we_a       = bram_ctrl_scle_we;
  assign int_ram_scle_bram_addr_a     = bram_ctrl_scle_addr[2 +: SCALE_EXTRL_ADDR];
  assign int_ram_scle_bram_wrdata_a   = bram_ctrl_scle_din;
  assign bram_ctrl_scle_dout          = int_ram_scle_bram_rddata_a;

  // scle bram port b to memory control unit
  assign int_mcu_scle_bram_clk        = int_ram_scle_bram_clk_a;
  assign int_ram_scle_bram_en_b       = int_mcu_scle_bram_en;
  assign int_ram_scle_bram_addr_b     = int_mcu_scle_bram_addr;
  assign int_mcu_scle_bram_rddata     = int_ram_scle_bram_rddata_b;
  assign int_mcu_scle_bram_rdack      = int_ram_scle_bram_rdack_b;
 `endif

  // connect dma slave to slave axi adp

  assign int_adp_wght_s_axis_tdata  = s_axis_wght_tdata;
  assign int_adp_wght_s_axis_tkeep  = s_axis_wght_tkeep;
  assign int_adp_wght_s_axis_tvalid = s_axis_wght_tvalid;
  assign s_axis_wght_tready         = int_adp_wght_s_axis_tready;
  assign int_adp_wght_s_axis_tlast  = s_axis_wght_tlast;

  // connect slave axi adp to axi spl of the wght streams

  assign int_spl_wght_s_axis_tdata   = int_adp_wght_m_axis_tdata;
  assign int_spl_wght_s_axis_tkeep   = int_adp_wght_m_axis_tkeep;
  assign int_spl_wght_s_axis_tvalid  = int_adp_wght_m_axis_tvalid;
  assign int_adp_wght_m_axis_tready  = int_spl_wght_s_axis_tready;
  assign int_spl_wght_s_axis_tlast   = int_adp_wght_m_axis_tlast;

  // connect slave axi spl to axi aps of the wght streams

  assign int_aps_wght_s_axis_tdata   = int_spl_wght_m_axis_tdata;
  assign int_aps_wght_s_axis_tvalid  = int_spl_wght_m_axis_tvalid;
  assign int_spl_wght_m_axis_tready  = int_aps_wght_s_axis_tready;
  assign int_aps_wght_s_axis_tlast   = int_spl_wght_m_axis_tlast;

  // Connect the data axis from mcu to async fifo

  assign int_adp_data_s_axis_aclk    = int_mcu_data_m_axis_aclk;
  assign int_adp_data_s_axis_tdata   = int_mcu_data_m_axis_tdata;
  assign int_adp_data_s_axis_tvalid  = int_mcu_data_m_axis_tvalid;
  assign int_mcu_data_m_axis_tready  = int_adp_data_s_axis_tready;
  assign int_adp_data_s_axis_tlast   = int_mcu_data_m_axis_tlast;

  // Connect the data axis from async fifo to data processor

  assign int_dpu_data_s_axis_tdata   = int_adp_data_m_axis_tdata;
  assign int_dpu_data_s_axis_tvalid  = int_adp_data_m_axis_tvalid;
  assign int_adp_data_m_axis_tready  = int_dpu_data_s_axis_tready;
  assign int_dpu_data_s_axis_tlast   = int_adp_data_m_axis_tlast;

  // Connect the grid axis from mcu to async fifo

  assign int_adp_grid_s_axis_aclk    = int_mcu_grid_m_axis_aclk;
  assign int_adp_grid_s_axis_tdata   = int_mcu_grid_m_axis_tdata;
  assign int_adp_grid_s_axis_tvalid  = int_mcu_grid_m_axis_tvalid;
  assign int_mcu_grid_m_axis_tready  = int_adp_grid_s_axis_tready;
  assign int_adp_grid_s_axis_tlast   = int_mcu_grid_m_axis_tlast;

  // Connect the grid axis from async fifo to data processor

  assign int_dpu_grid_s_axis_tdata   = int_adp_grid_m_axis_tdata;
  assign int_dpu_grid_s_axis_tvalid  = int_adp_grid_m_axis_tvalid;
  assign int_adp_grid_m_axis_tready  = int_dpu_grid_s_axis_tready;
  assign int_dpu_grid_s_axis_tlast   = int_adp_grid_m_axis_tlast;

  // Connect the scle axis from mcu to async fifo

  assign int_adp_scle_s_axis_aclk    = int_mcu_scle_m_axis_aclk;
  assign int_adp_scle_s_axis_tdata   = int_mcu_scle_m_axis_tdata;
  assign int_adp_scle_s_axis_tvalid  = int_mcu_scle_m_axis_tvalid;
  assign int_mcu_scle_m_axis_tready  = int_adp_scle_s_axis_tready;
  assign int_adp_scle_s_axis_tlast   = int_mcu_scle_m_axis_tlast;

  // Connect the scle axis from async fifo to data processor

  assign int_dpu_scle_s_axis_tdata   = int_adp_scle_m_axis_tdata;
  assign int_dpu_scle_s_axis_tvalid  = int_adp_scle_m_axis_tvalid;
  assign int_adp_scle_m_axis_tready  = int_dpu_scle_s_axis_tready;
  assign int_dpu_scle_s_axis_tlast   = int_adp_scle_m_axis_tlast;

  // connect axi spl wght streams to data processor

  assign int_dpu_wght_s_axis_tdata   = int_aps_wght_m_axis_tdata;
  assign int_dpu_wght_s_axis_tvalid  = int_aps_wght_m_axis_tvalid;
  assign int_aps_wght_m_axis_tready  = int_dpu_wght_s_axis_tready;
  assign int_dpu_wght_s_axis_tlast   = int_aps_wght_m_axis_tlast;

  // connect the rslt streams from data procesor to axi jnr

  assign int_buf_rslt_s_axis_tdata    = int_dpu_rslt_m_axis_tdata;
  assign int_buf_rslt_s_axis_tvalid   = int_dpu_rslt_m_axis_tvalid;
  assign int_dpu_rslt_m_axis_tready   = int_buf_rslt_s_axis_tready;
  assign int_buf_rslt_s_axis_tlast    = int_dpu_rslt_m_axis_tlast;

  assign int_jnr_rslt_s_axis_tdata    = int_buf_rslt_m_axis_tdata;
  assign int_jnr_rslt_s_axis_tvalid   = int_buf_rslt_m_axis_tvalid;
  assign int_buf_rslt_m_axis_tready   = int_jnr_rslt_s_axis_tready;
  assign int_jnr_rslt_s_axis_tlast    = int_buf_rslt_m_axis_tlast;

  // connect axi jnr of result streams to axi master adp

  assign int_adp_rslt_s_axis_tdata   = int_jnr_rslt_m_axis_tdata;
  assign int_adp_rslt_s_axis_tvalid  = int_jnr_rslt_m_axis_tvalid;
  assign int_jnr_rslt_m_axis_tready  = int_adp_rslt_s_axis_tready;
  assign int_adp_rslt_s_axis_tlast   = int_jnr_rslt_m_axis_tlast;
  assign int_adp_rslt_s_axis_tid     = int_jnr_rslt_m_axis_tid;

  // connect axi master adp to external master axi interface

  assign m_axis_rslt_tdata            = int_adp_rslt_m_axis_tdata;
  assign m_axis_rslt_tkeep            = int_adp_rslt_m_axis_tkeep;
  assign m_axis_rslt_tvalid           = int_adp_rslt_m_axis_tvalid;
  assign int_adp_rslt_m_axis_tready   = m_axis_rslt_tready;
  assign m_axis_rslt_tlast            = int_adp_rslt_m_axis_tlast;
  assign m_axis_rslt_tid              = (RSLT_ID_ENABLE) ? {int_adp_rslt_m_axis_tid, ID_OUTPUT[RSLT_ID_WIDTH-`LOG2(BATCH_SIZE):0]} : ID_OUTPUT;
  assign m_axis_rslt_tdest            = (DEST_ENABLE) ? DEST_OUTPUT : 0;
  assign m_axis_rslt_tuser            = (USER_ENABLE) ? USER_OUTPUT : 0;

  // connect internal control signals !!!

  assign peripheral_operation_busy     [PERIPHERAL_MCU] = mcu_operation_busy;
  assign peripheral_operation_complete [PERIPHERAL_MCU] = mcu_operation_complete;
  assign peripheral_operation_error    [PERIPHERAL_MCU] = mcu_operation_error;
  assign peripheral_transmission       [PERIPHERAL_MCU] = mcu_transmission;

  assign peripheral_operation_busy     [PERIPHERAL_APS] = aps_operation_busy;
  assign peripheral_operation_complete [PERIPHERAL_APS] = aps_operation_complete;
  assign peripheral_operation_error    [PERIPHERAL_APS] = aps_operation_error;
  assign peripheral_transmission       [PERIPHERAL_APS] = aps_transmission;

  assign peripheral_operation_busy     [PERIPHERAL_JNR] = jnr_operation_busy;
  assign peripheral_operation_complete [PERIPHERAL_JNR] = jnr_operation_complete;
  assign peripheral_operation_error    [PERIPHERAL_JNR] = jnr_operation_error;
  assign peripheral_transmission       [PERIPHERAL_JNR] = jnr_transmission;
endmodule

`resetall
