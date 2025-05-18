`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * KanLayer: This acts as the top level hdl module
 *   of the KAN SoC design.
 *   The endgoal is that this particular module
 *   be drag-and-dropped in the Vivado Block Design.
 */

`include "header_utils.vh"
`include "header_IFOptions.vh"

module KanLayer #(
  /*------------------------------------------------------------------
    Genreal parameters of the architecture
  ------------------------------------------------------------------*/
  
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,

  /*------------------------------------------------------------------
    DMA parameters
  ------------------------------------------------------------------*/
  
  // Width of DMA streams
  parameter DMA_WIDTH = 64,
  // Propagate tkeep signal
  parameter DMA_KEEP_ENABLE = (DMA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter DMA_KEEP_WIDTH = (DMA_KEEP_ENABLE) ? ((DMA_WIDTH + 7) / 8) : 1,

  /*------------------------------------------------------------------
    AXI_Lite controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter AXIL_WIDTH = 32,
  parameter AXIL_STRB_WIDTH = (AXIL_WIDTH / 8),

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
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = 1,
  // Total memory size allocated for Data in words
  parameter DATA_DEPTH = 1024,

 `ifdef DATA_IF_IS_AXIL
  // Grid Address Width
  parameter DATA_ADDR = `LOG2(DATA_DEPTH),
  // Grid Strobe Width
  parameter DATA_STRB_WIDTH = DATA_WIDTH / 8,
 `endif

  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Grid Data Width
  parameter GRID_WIDTH = DATA_WIDTH,
  // Use Common Grid Channel 
  parameter GRID_SHARE = `GRID_IS_SHARED, 
  // Total memory size allocated for Grid in words
  parameter GRID_DEPTH = 16,

 `ifdef GRID_IF_IS_AXIL
  // Grid Address Width
  parameter GRID_ADDR = `LOG2(GRID_DEPTH),
  // Grid Strobe Width
  parameter GRID_STRB_WIDTH = GRID_WIDTH / 8,
 `endif

  /*------------------------------------------------------------------
    SCALE streams parameters
  ------------------------------------------------------------------*/

  // Use Common Share Channel 
  parameter SCALE_SHARE = `SCALE_IS_SHARED,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scle
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Total memory size allocated for Data in words
  parameter SCALE_DEPTH = (SCALE_SHARE) ? 1 : GRID_DEPTH*DATA_DEPTH,

 `ifdef SCALE_IF_IS_AXIL
  // Grid Address Width
  parameter SCALE_ADDR = `MAX(`LOG2(SCALE_DEPTH), 1),
  // Grid Strobe Width
  parameter SCALE_STRB_WIDTH = SCALE_WIDTH / 8,
 `endif

  /*------------------------------------------------------------------
    RESULT / OUTPUT parameters
  ------------------------------------------------------------------*/

  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12,
  // tkeep signal width (words per cycle)
  parameter RSLT_KEEP_WIDTH = ((RSLT_WIDTH + 7) / 8),
  // FIFO Depth for results
  parameter RSLT_FIFO_DEPTH = `MAX( 2 ** `LOG2(`LOG2(BATCH_SIZE + RSLT_CHANNELS) + DMA_KEEP_WIDTH), 8),

  /*------------------------------------------------------------------
    WEIGHT streams parameters
  ------------------------------------------------------------------*/

  // Width of input wght word
  parameter WEIGHT_WIDTH = 16,
  // Fractional bits of wght data
  parameter WEIGHT_FRACTIONAL_BITS = 12,
  // Propagate tkeep signal
  parameter WEIGHT_KEEP_ENABLE = (WEIGHT_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter WEIGHT_KEEP_WIDTH = (WEIGHT_KEEP_ENABLE) ? ((WEIGHT_WIDTH + 7) / 8) : 1,
  // FIFO Depth for WEIGHT parameters
  parameter WEIGHT_FIFO_DEPTH = 2 ** `LOG2(BATCH_SIZE + DATA_CHANNELS + RSLT_CHANNELS + DMA_KEEP_WIDTH),

  /*------------------------------------------------------------------
    SCALED_DIFF parameters
  ------------------------------------------------------------------*/

  // Width of Scaled Data in bits
  parameter SCALED_DIFF_WIDTH = 16,
  // Fractional bits of Scaled Data
  parameter SCALED_DIFF_FRACTIONAL_BITS = 13,

  /*------------------------------------------------------------------
    ACT parameters
  ------------------------------------------------------------------*/

  // Width of Activation Function Data in bits
  parameter ACT_WIDTH = 16,
  // Fractional bits of Activation Function Data
  parameter ACT_FRACTIONAL_BITS = 16,

  /*------------------------------------------------------------------
    Various AXI parameters
  ------------------------------------------------------------------*/

  // Propagate tid signal
  parameter WEIGHT_ID_ENABLE = 0,
  // tid signal width
  parameter WEIGHT_ID_WIDTH = (WEIGHT_ID_ENABLE) ? 8 : 1,

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

  /*------------------------------------------------------------------
    Miscalleneous parameters
  ------------------------------------------------------------------*/

  // Add Buffer on Output Streams
  parameter EXTRA_CYCLE = 0,
  // Central Control Address Width
  parameter CTRL_ADDR = 6, // 13 

  /*------------------------------------------------------------------
    Input / Output file constants
  ------------------------------------------------------------------*/

  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt"
) (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_ctrl, ASSOCIATED_RESET fsm_rst" *)
  input  wire                                       fsm_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fsm_rst RST" *)
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       fsm_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET core_rst" *)
  input  wire                                       core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output wire                                       core_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dma_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_wght:m_axis_rslt, ASSOCIATED_RESET dma_rst" *)
  input  wire                                       dma_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 dma_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       dma_rst,

  /*------------------------------------------------------------------
      Generated Interrupts & Resets
  ------------------------------------------------------------------*/
  output wire                                       operation_busy,
  output wire                                       operation_complete,
  output wire                                       operation_error,
  output wire                                       locked,
  output wire                                       pl2ps_intr,

  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/
 `ifdef DATA_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_data_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_data, ASSOCIATED_RESET s_axil_data_areset" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_data_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [BATCH_SIZE*DATA_ADDR-1:0]            s_axil_data_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWPROT" *)
  input  wire [BATCH_SIZE*3-1:0]                    s_axil_data_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWVALID" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data AWREADY" *)
  output wire [BATCH_SIZE-1:0]                      s_axil_data_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WDATA" *)
  input  wire [BATCH_SIZE*AXIL_WIDTH-1:0]           s_axil_data_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WSTRB" *)
  input  wire [BATCH_SIZE*AXIL_STRB_WIDTH-1:0]      s_axil_data_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WVALID" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WREADY" *)
  output wire [BATCH_SIZE-1:0]                      s_axil_data_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BRESP" *)
  output wire [BATCH_SIZE*2-1:0]                    s_axil_data_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BVALID" *)
  output wire [BATCH_SIZE-1:0]                      s_axil_data_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data BREADY" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARADDR" *)
  input  wire [BATCH_SIZE*DATA_ADDR-1:0]            s_axil_data_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARPROT" *)
  input  wire [BATCH_SIZE*3-1:0]                    s_axil_data_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARVALID" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data ARREADY" *)
  output wire [BATCH_SIZE-1:0]                      s_axil_data_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RDATA" *)
  output wire [BATCH_SIZE*AXIL_WIDTH-1:0]           s_axil_data_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RRESP" *)
  output wire [BATCH_SIZE*2-1:0]                    s_axil_data_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RVALID" *)
  output wire [BATCH_SIZE-1:0]                      s_axil_data_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RREADY" *)
  input  wire [BATCH_SIZE-1:0]                      s_axil_data_rready,

  // Uncomment the following to set interface specific parameter on the bus interface.
  // (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC <value>,MEM_WIDTH <value>,MEM_SIZE <value>,READ_WRITE_MODE <value>" *)

 `elsif DATA_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data CLK" *)
  input  wire [BATCH_SIZE-1:0]                      bram_ctrl_data_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data RST" *)
  input  wire [BATCH_SIZE-1:0]                      bram_ctrl_data_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data EN" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire [BATCH_SIZE-1:0]                      bram_ctrl_data_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data WE" *)
  input  wire [BATCH_SIZE*BRAM_CTRL_WE-1:0]         bram_ctrl_data_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data ADDR" *)
  input  wire [BATCH_SIZE*BRAM_CTRL_ADDR-1:0]       bram_ctrl_data_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data DIN" *)
  input  wire [BATCH_SIZE*BRAM_CTRL_WIDTH-1:0]      bram_ctrl_data_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_data DOUT" *)
  output wire [BATCH_SIZE*BRAM_CTRL_WIDTH-1:0]      bram_ctrl_data_dout,
 `endif 

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/
 `ifdef GRID_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_grid_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_grid, ASSOCIATED_RESET s_axil_grid_areset" *)
  input  wire                                       s_axil_grid_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_grid_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       s_axil_grid_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [GRID_ADDR-1:0]                       s_axil_grid_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWPROT" *)
  input  wire [2:0]                                 s_axil_grid_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWVALID" *)
  input  wire                                       s_axil_grid_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWREADY" *)
  output wire                                       s_axil_grid_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WDATA" *)
  input  wire [AXIL_WIDTH-1:0]                      s_axil_grid_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
  input  wire [AXIL_STRB_WIDTH-1:0]                 s_axil_grid_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WVALID" *)
  input  wire                                       s_axil_grid_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WREADY" *)
  output wire                                       s_axil_grid_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BRESP" *)
  output wire [1:0]                                 s_axil_grid_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BVALID" *)
  output wire                                       s_axil_grid_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BREADY" *)
  input  wire                                       s_axil_grid_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARADDR" *)
  input  wire [GRID_ADDR-1:0]                       s_axil_grid_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARPROT" *)
  input  wire [2:0]                                 s_axil_grid_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARVALID" *)
  input  wire                                       s_axil_grid_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARREADY" *)
  output wire                                       s_axil_grid_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RDATA" *)
  output wire [AXIL_WIDTH-1:0]                      s_axil_grid_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
  output wire [1:0]                                 s_axil_grid_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
  output wire                                       s_axil_grid_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
  input  wire                                       s_axil_grid_rready,

 `elsif GRID_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid CLK" *)
  input  wire                                       bram_ctrl_grid_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid RST" *)
  input  wire                                       bram_ctrl_grid_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                                       bram_ctrl_grid_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid WE" *)
  input  wire [BRAM_CTRL_WE-1:0]                    bram_ctrl_grid_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]                  bram_ctrl_grid_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_grid_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_grid_dout,
 `endif

    /*------------------------------------------------------------------
        BRAM Scale Control interface
    ------------------------------------------------------------------*/

 `ifdef SCALE_IF_IS_AXIL
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_scle_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_scle, ASSOCIATED_RESET s_axil_scle_areset" *)
  input  wire                                       s_axil_scle_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_scle_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       s_axil_scle_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [SCALE_ADDR-1:0]                      s_axil_scle_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWPROT" *)
  input  wire [2:0]                                 s_axil_scle_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWVALID" *)
  input  wire                                       s_axil_scle_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWREADY" *)
  output wire                                       s_axil_scle_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WDATA" *)
  input  wire [AXIL_WIDTH-1:0]                      s_axil_scle_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
  input  wire [AXIL_STRB_WIDTH-1:0]                 s_axil_scle_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WVALID" *)
  input  wire                                       s_axil_scle_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WREADY" *)
  output wire                                       s_axil_scle_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BRESP" *)
  output wire [1:0]                                 s_axil_scle_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BVALID" *)
  output wire                                       s_axil_scle_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BREADY" *)
  input  wire                                       s_axil_scle_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARADDR" *)
  input  wire [SCALE_ADDR-1:0]                      s_axil_scle_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARPROT" *)
  input  wire [2:0]                                 s_axil_scle_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARVALID" *)
  input  wire                                       s_axil_scle_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARREADY" *)
  output wire                                       s_axil_scle_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RDATA" *)
  output wire [AXIL_WIDTH-1:0]                      s_axil_scle_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
  output wire [1:0]                                 s_axil_scle_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
  output wire                                       s_axil_scle_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
  input  wire                                       s_axil_scle_rready,

 `elsif  SCALE_IF_IS_BRAM
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle CLK" *)
  input  wire                                       bram_ctrl_scle_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle RST" *)
  input  wire                                       bram_ctrl_scle_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                                       bram_ctrl_scle_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle WE" *)
  input  wire [BRAM_CTRL_WE-1:0]                    bram_ctrl_scle_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]                  bram_ctrl_scle_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_scle_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_scle_dout,
 `endif
 
  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWADDR" *)
  (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE,DATA_WIDTH 32" *)
  input  wire [CTRL_ADDR-1:0]                       s_axil_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWPROT" *)
  input  wire [2:0]                                 s_axil_ctrl_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWVALID" *)
  input  wire                                       s_axil_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWREADY" *)
  output wire                                       s_axil_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WDATA" *)
  input  wire [31:0]                                s_axil_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WSTRB" *)
  input  wire [3:0]                                 s_axil_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WVALID" *)
  input  wire                                       s_axil_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WREADY" *)
  output wire                                       s_axil_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BRESP" *)
  output wire [1:0]                                 s_axil_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BVALID" *)
  output wire                                       s_axil_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BREADY" *)
  input  wire                                       s_axil_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARADDR" *)
  input  wire [CTRL_ADDR-1:0]                       s_axil_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARPROT" *)
  input  wire [2:0]                                 s_axil_ctrl_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARVALID" *)
  input  wire                                       s_axil_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARREADY" *)
  output wire                                       s_axil_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RDATA" *)
  output wire [31:0]                                s_axil_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RRESP" *)
  output wire [1:0]                                 s_axil_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RVALID" *)
  output wire                                       s_axil_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RREADY" *)
  input  wire                                       s_axil_ctrl_rready,

  /*------------------------------------------------------------------
      AXI-Stream Weight Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
    (* X_INTERFACE_PARAMETER = "HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  input  wire [DMA_WIDTH-1:0]                       s_axis_wght_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TKEEP" *)
  input  wire [DMA_KEEP_WIDTH-1:0]                  s_axis_wght_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TVALID" *)
  input  wire                                       s_axis_wght_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TREADY" *)
  output wire                                       s_axis_wght_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TLAST" *)
  input  wire                                       s_axis_wght_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TID" *)
  input  wire [WEIGHT_ID_WIDTH-1:0]                 s_axis_wght_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
  input  wire [DEST_WIDTH-1:0]                      s_axis_wght_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
  input  wire [USER_WIDTH-1:0]                      s_axis_wght_tuser,

    /*------------------------------------------------------------------
        AXI-Stream Results / Output Master interface
    ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
    (* X_INTERFACE_PARAMETER = "HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  output wire [DMA_WIDTH-1:0]                       m_axis_rslt_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TKEEP" *)
  output wire [DMA_KEEP_WIDTH-1:0]                  m_axis_rslt_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TVALID" *)
  output wire                                       m_axis_rslt_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TREADY" *)
  input  wire                                       m_axis_rslt_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TLAST" *)
  output wire                                       m_axis_rslt_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TID" *)
  output wire [RSLT_ID_WIDTH-1:0]                   m_axis_rslt_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
  output wire [DEST_WIDTH-1:0]                      m_axis_rslt_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
  output wire [USER_WIDTH-1:0]                      m_axis_rslt_tuser
);

  /*************************************************************************************
   Local Parameters
  *************************************************************************************/
  /*------------------------------------------------------------------
    DATA parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Data FIFO Depth
  localparam DATA_FIFO_DEPTH = `MAX(DATA_CHANNELS + BATCH_SIZE, 4);

 `ifdef DATA_IF_IS_AXIL
  // number of DATA bram banks
  localparam DATA_BANKS = (DATA_CHANNELS == 1);
  // number of elements on a single bram bank
  localparam DATA_BANK_DEPTH = DATA_DEPTH;
  // Pipeline Output DATA
  localparam DATA_PIPELINE_OUTPUT = 0;
 `elsif DATA_IF_IS_BRAM
  // number of DATA bram banks
  localparam DATA_BANKS = DATA_CHANNELS;
  // number of elements on a single bram bank
  localparam DATA_BANK_DEPTH = DATA_DEPTH / DATA_BANKS;
  // number of address bits needed for each bank
  localparam DATA_ADDR = `LOG2(DATA_BANK_DEPTH);
  // number of DATA_WE bits needed for each bank
  localparam DATA_WE = DATA_WIDTH / 8;
 `endif 

  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Input Grid Channels
  localparam GRID_CHANNELS_IN = (GRID_SHARE) ? 1 : DATA_CHANNELS;
  // Output Grid Channels
  localparam GRID_CHANNELS_OUT = (GRID_SHARE) ? 1 : DATA_CHANNELS*BATCH_SIZE;
  // Grid FIFO Depth
  localparam GRID_FIFO_DEPTH = `MAX((GRID_SHARE) ? 1 : DATA_CHANNELS + BATCH_SIZE, 2);

 `ifdef GRID_IF_IS_AXIL
  // number of GRID bram banks
  localparam GRID_BANKS = GRID_SHARE;
  // number of elements on a single bram bank
  localparam GRID_BANK_DEPTH = GRID_DEPTH;
  // Pipeline Output Grid
  localparam GRID_PIPELINE_OUTPUT = 0;
 `elsif GRID_IF_IS_BRAM
  // number of GRID bram banks
  localparam GRID_BANKS = (GRID_SHARE) ? 1 : DATA_CHANNELS;
  // number of elements on a single bram bank
  localparam GRID_BANK_DEPTH = GRID_DEPTH / GRID_BANKS;
  // number of address bits needed for each bank
  // localparam GRID_ADDR = `LOG2(GRID_BANK_DEPTH);
  // number of GRID_WE bits needed for each bank
  localparam GRID_WE = GRID_WIDTH / 8;
 `endif 

  /*------------------------------------------------------------------
    SCALE streams parameters
  ------------------------------------------------------------------*/

  // Input Scale Channels
  localparam SCALE_CHANNELS_IN = (SCALE_SHARE) ? 1 : DATA_CHANNELS;
  // Output Scale Channels
  localparam SCALE_CHANNELS_OUT = (SCALE_SHARE) ? 1 : DATA_CHANNELS*BATCH_SIZE;
  // Grid FIFO Depth
  localparam SCALE_FIFO_DEPTH = `MAX((SCALE_SHARE) ? 1 : DATA_CHANNELS + BATCH_SIZE,2);

 `ifdef SCALE_IF_IS_AXIL
  // number of SCALE bram banks
  localparam SCALE_BANKS = SCALE_SHARE;
  // number of elements on a single bram bank
  localparam SCALE_BANK_DEPTH = SCALE_DEPTH;
  // Pipeline Output Grid
  localparam SCALE_PIPELINE_OUTPUT = 0;
 `elsif SCALE_IF_IS_BRAM
  // number of SCALE bram banks
  localparam SCALE_BANKS = (SCALE_SHARE) ? 1 : DATA_CHANNELS;
  // number of elements on a single bram bank
  localparam SCALE_BANK_DEPTH = SCALE_DEPTH / SCALE_BANKS;
  // number of address bits needed for each bank
  // localparam SCALE_ADDR = `MAX(`LOG2(SCALE_BANK_DEPTH),2);
  // number of SCALE_WE bits needed for each bank
  localparam SCALE_WE = SCALE_WIDTH / 8;
 `endif 

  /*************************************************************************************
   More Local Parameters
  *************************************************************************************/

 `ifdef DATA_IF_IS_BRAM
  localparam IN_WORD_DATA = BRAM_CTRL_WIDTH / DATA_WIDTH;

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory

 `endif

 `ifdef GRID_IF_IS_BRAM
  localparam IN_WORD_GRID = BRAM_CTRL_WIDTH / GRID_WIDTH;

  localparam GRID_ITRL_DEPTH = GRID_BANKS * GRID_BANK_DEPTH; // simulated total data ram length
  localparam GRID_ITRL_ADDR = `LOG2(GRID_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_DEPTH_RESOLVED = GRID_ITRL_DEPTH;

  localparam GRID_EXTRL_DEPTH = GRID_DEPTH_RESOLVED / IN_WORD_GRID;  // grid depth as seen from external ram control interface
  localparam GRID_EXTRL_ADDR = `LOG2(GRID_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  localparam GRID_ADDR = `LOG2(GRID_DEPTH_RESOLVED);  // number of input address bits of total grid memory
  localparam GRID_PHYS_DEPTH = GRID_DEPTH_RESOLVED / IN_WORD_GRID;  // effective - physical depth of grid ram
  localparam GRID_PHYS_ADDR = `LOG2(GRID_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram
 `endif

 `ifdef SCALE_IF_IS_BRAM
  localparam IN_WORD_SCALE = BRAM_CTRL_WIDTH / SCALE_WIDTH;

  localparam SCALE_ITRL_DEPTH = SCALE_BANKS * SCALE_BANK_DEPTH; // simulated total data ram length
  localparam SCALE_ITRL_ADDR = `LOG2(SCALE_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam SCALE_DEPTH_RESOLVED = SCALE_ITRL_DEPTH;

  localparam SCALE_EXTRL_DEPTH = SCALE_DEPTH_RESOLVED / IN_WORD_SCALE;  // grid depth as seen from external ram control interface
  localparam SCALE_EXTRL_ADDR = `LOG2(SCALE_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  localparam SCALE_ADDR = `LOG2(SCALE_DEPTH_RESOLVED);  // number of input address bits of total grid memory
  localparam SCALE_PHYS_DEPTH = SCALE_DEPTH_RESOLVED / IN_WORD_SCALE;  // effective - physical depth of grid ram
  localparam SCALE_PHYS_ADDR = `LOG2(SCALE_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram
 `endif
  // localparam DATA_WIDTH_GRID = DATA_WIDTH_DATA;

  localparam PCKT_SIZE_WIDTH = DATA_ADDR + GRID_ADDR -1;

  // Number of Independent AXI-Stream Weight Channels
  localparam WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS;

  localparam DATA_CHANNELS_OUT = BATCH_SIZE*DATA_CHANNELS;
  localparam RSLT_CHANNELS_OUT = BATCH_SIZE*RSLT_CHANNELS;

 `include "header_PeripheralsLocal.vh"

  genvar BATCH, CHN;

  /*************************************************************************************
   Check Configuration
  *************************************************************************************/
  initial begin
    if (DATA_WIDTH != GRID_WIDTH) begin
      $error("Missmatch between widths of grid and data.");
      $finish;
    end
    if (DMA_WIDTH % 32 != 0) begin
      $error("Data width for DMA master & slave interfaces must be multiples of 32.");
      $finish;
    end
    if ( 2 ** ($clog2(DATA_CHANNELS)) != DATA_CHANNELS) begin
      $error("Data channels is expected to be a power of 2.");
      $finish;
    end
    if (DATA_FIFO_DEPTH < 2) begin
      $error("FIFO depth for Data must be greater than 1.");
      $finish;
    end
    if (GRID_FIFO_DEPTH < 2) begin
      $error("FIFO depth for Grid must be greater than 1.");
      $finish;
    end
    if (SCALE_FIFO_DEPTH < 2) begin
      $error("FIFO depth for Scale must be greater than 1.");
      $finish;
    end
    if (WEIGHT_FIFO_DEPTH < 2) begin
      $error("FIFO depth for Weights must be greater than 1.");
      $finish;
    end
    if (RSLT_FIFO_DEPTH < 2) begin
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
  wire                        int_ram_data_s_axil_aclk    [0:BATCH_SIZE-1];
  wire                        int_ram_data_s_axil_arst    [0:BATCH_SIZE-1];

  // Port A : destined for internal use
  // Keep Write channels of Port A
  wire [DATA_ADDR-1:0]        int_ram_data_a_axil_awaddr  [0:BATCH_SIZE-1];
  wire [2:0]                  int_ram_data_a_axil_awprot  [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_awvalid [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_awready [0:BATCH_SIZE-1];
  wire [DATA_WIDTH-1:0]       int_ram_data_a_axil_wdata   [0:BATCH_SIZE-1];
  wire [DATA_STRB_WIDTH-1:0]  int_ram_data_a_axil_wstrb   [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_wvalid  [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_wready  [0:BATCH_SIZE-1];
  wire [1:0]                  int_ram_data_a_axil_bresp   [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_bvalid  [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_bready  [0:BATCH_SIZE-1];
  // Keep Read channels of Port A
  wire [DATA_ADDR-1:0]        int_ram_data_a_axil_araddr  [0:BATCH_SIZE-1];
  wire [2:0]                  int_ram_data_a_axil_arprot  [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_arvalid [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_arready [0:BATCH_SIZE-1];
  wire [DATA_WIDTH-1:0]       int_ram_data_a_axil_rdata   [0:BATCH_SIZE-1];
  wire [1:0]                  int_ram_data_a_axil_rresp   [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_rvalid  [0:BATCH_SIZE-1];
  wire                        int_ram_data_a_axil_rready  [0:BATCH_SIZE-1];

  // Port B : destined for external interfacing
  // Drop Write channels of Port B
  wire [DATA_ADDR-1:0]        int_ram_data_b_axil_awaddr = {DATA_ADDR{1'b0}};
  wire [2:0]                  int_ram_data_b_axil_awprot = {2'b00};
  wire                        int_ram_data_b_axil_awvalid = 1'b0;
  wire                        int_ram_data_b_axil_awready [0:BATCH_SIZE-1];
  wire [AXIL_WIDTH-1:0]       int_ram_data_b_axil_wdata = {AXIL_WIDTH{1'b0}};
  wire [1-1:0]                int_ram_data_b_axil_wstrb = 1'b0;
  wire                        int_ram_data_b_axil_wvalid = 1'b0;
  wire                        int_ram_data_b_axil_wready = 1'b0;
  wire [1:0]                  int_ram_data_b_axil_bresp   [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_bvalid  [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_bready = 1'b0;
  // Keep Read channels of Port B
  wire [DATA_ADDR-1:0]        int_ram_data_b_axil_araddr  [0:BATCH_SIZE-1];
  wire [2:0]                  int_ram_data_b_axil_arprot  [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_arvalid [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_arready [0:BATCH_SIZE-1];
  wire [AXIL_WIDTH-1:0]       int_ram_data_b_axil_rdata   [0:BATCH_SIZE-1];
  wire [1:0]                  int_ram_data_b_axil_rresp   [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_rvalid  [0:BATCH_SIZE-1];
  wire                        int_ram_data_b_axil_rready  [0:BATCH_SIZE-1];

  generate
  for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin: axil_ram_data_genblock
    AxilDpRamPortbAdapter # (
      .ADDR_WIDTH(DATA_ADDR),
      .DATA_WIDTH(DATA_WIDTH),
      .DATA_WIDTH_EXT(AXIL_WIDTH),
      .PIPELINE_OUTPUT(DATA_PIPELINE_OUTPUT)
    ) axil_ram_data_inst (
      .clk                (int_ram_data_s_axil_aclk       [BATCH]),
      .rst                (int_ram_data_s_axil_arst       [BATCH]),
      .s_axil_a_awaddr    (int_ram_data_a_axil_awaddr     [BATCH]),
      .s_axil_a_awprot    (int_ram_data_a_axil_awprot     [BATCH]),
      .s_axil_a_awvalid   (int_ram_data_a_axil_awvalid    [BATCH]),
      .s_axil_a_awready   (int_ram_data_a_axil_awready    [BATCH]),
      .s_axil_a_wdata     (int_ram_data_a_axil_wdata      [BATCH]),
      .s_axil_a_wstrb     (int_ram_data_a_axil_wstrb      [BATCH]),
      .s_axil_a_wvalid    (int_ram_data_a_axil_wvalid     [BATCH]),
      .s_axil_a_wready    (int_ram_data_a_axil_wready     [BATCH]),
      .s_axil_a_bresp     (int_ram_data_a_axil_bresp      [BATCH]),
      .s_axil_a_bvalid    (int_ram_data_a_axil_bvalid     [BATCH]),
      .s_axil_a_bready    (int_ram_data_a_axil_bready     [BATCH]),
      .s_axil_a_araddr    (int_ram_data_a_axil_araddr     [BATCH]),
      .s_axil_a_arprot    (int_ram_data_a_axil_arprot     [BATCH]),
      .s_axil_a_arvalid   (int_ram_data_a_axil_arvalid    [BATCH]),
      .s_axil_a_arready   (int_ram_data_a_axil_arready    [BATCH]),
      .s_axil_a_rdata     (int_ram_data_a_axil_rdata      [BATCH]),
      .s_axil_a_rresp     (int_ram_data_a_axil_rresp      [BATCH]),
      .s_axil_a_rvalid    (int_ram_data_a_axil_rvalid     [BATCH]),
      .s_axil_a_rready    (int_ram_data_a_axil_rready     [BATCH]),
      .s_axil_b_awaddr    (int_ram_data_b_axil_awaddr),
      .s_axil_b_awprot    (int_ram_data_b_axil_awprot),
      .s_axil_b_awvalid   (int_ram_data_b_axil_awvalid),
      .s_axil_b_awready   (int_ram_data_b_axil_awready    [BATCH]),
      .s_axil_b_wdata     (int_ram_data_b_axil_wdata),
      .s_axil_b_wstrb     (int_ram_data_b_axil_wstrb),
      .s_axil_b_wvalid    (int_ram_data_b_axil_wvalid),
      .s_axil_b_wready    (int_ram_data_b_axil_wready),
      .s_axil_b_bresp     (int_ram_data_b_axil_bresp      [BATCH]),
      .s_axil_b_bvalid    (int_ram_data_b_axil_bvalid     [BATCH]),
      .s_axil_b_bready    (int_ram_data_b_axil_bready),
      .s_axil_b_araddr    (int_ram_data_b_axil_araddr     [BATCH]),
      .s_axil_b_arprot    (int_ram_data_b_axil_arprot     [BATCH]),
      .s_axil_b_arvalid   (int_ram_data_b_axil_arvalid    [BATCH]),
      .s_axil_b_arready   (int_ram_data_b_axil_arready    [BATCH]),
      .s_axil_b_rdata     (int_ram_data_b_axil_rdata      [BATCH]),
      .s_axil_b_rresp     (int_ram_data_b_axil_rresp      [BATCH]),
      .s_axil_b_rvalid    (int_ram_data_b_axil_rvalid     [BATCH]),
      .s_axil_b_rready    (int_ram_data_b_axil_rready     [BATCH])
    );
  end
  endgenerate
    
 `elsif DATA_IF_IS_BRAM
  /**********************************************
    Interface Translator between BRAM Controller
    and Data BRAM

    Naming conventions
    - int_ : internal signal
    - _trl_ : indicates a translator module
    - _i : input / slave interface
    - _o : output / master interface
  *********************************************/
  wire                                    int_trl_data_bram_en_i [0:BATCH_SIZE-1];
  wire [BRAM_CTRL_WE-1:0]                 int_trl_data_bram_we_i [0:BATCH_SIZE-1];
  wire [DATA_ITRL_ADDR-1:0]               int_trl_data_bram_addr_i [0:BATCH_SIZE-1];
  wire [BRAM_CTRL_WIDTH-1:0]              int_trl_data_bram_wrdata_i [0:BATCH_SIZE-1];
  wire [BRAM_CTRL_WIDTH-1:0]              int_trl_data_bram_rddata_i [0:BATCH_SIZE-1];
  
  wire [DATA_BANKS-1:0]                   int_trl_data_bram_en_o [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WE)-1:0]         int_trl_data_bram_we_o [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_trl_data_bram_addr_o [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WIDTH)-1:0]      int_trl_data_bram_wrdata_o [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WIDTH)-1:0]      int_trl_data_bram_rddata_o [0:BATCH_SIZE-1];

  generate
  for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin: bram_trl_data_genblock
    BramIntrfTranslator # (
      .IN_WIDTH  (BRAM_CTRL_WIDTH),
      .OUT_WIDTH (DATA_WIDTH),
      .BANKS     (DATA_BANKS),
      .OUT_DEPTH (DATA_BANK_DEPTH)
    ) bram_trl_data_inst (
      .en_i      (int_trl_data_bram_en_i[BATCH]),
      .we_i      (int_trl_data_bram_we_i[BATCH]),
      .addr_i    (int_trl_data_bram_addr_i[BATCH]),
      .wrdata_i  (int_trl_data_bram_wrdata_i[BATCH]),
      .rddata_i  (int_trl_data_bram_rddata_i[BATCH]),
      .en_o      (int_trl_data_bram_en_o[BATCH]),
      .we_o      (int_trl_data_bram_we_o[BATCH]),
      .addr_o    (int_trl_data_bram_addr_o[BATCH]),
      .wrdata_o  (int_trl_data_bram_wrdata_o[BATCH]),
      .rddata_o  (int_trl_data_bram_rddata_o[BATCH])
    );
  end
  endgenerate

  /**********************************************
    Data Multi-Bank Dual-Port BRAM

    Naming conventions
    - int_ : internal signal
    - _a : port a (control port)
    - _b : port b (internal use)
  *********************************************/
  wire                                    int_ram_data_bram_clk_a [0:BATCH_SIZE-1];
  wire [DATA_BANKS-1:0]                   int_ram_data_bram_en_a [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WE)-1:0]         int_ram_data_bram_we_a [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_ram_data_bram_addr_a [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WIDTH)-1:0]      int_ram_data_bram_wrdata_a [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WIDTH)-1:0]      int_ram_data_bram_rddata_a [0:BATCH_SIZE-1];

  wire [DATA_BANKS-1:0]                   int_ram_data_bram_en_b [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_ram_data_bram_addr_b [0:BATCH_SIZE-1];
  wire [(DATA_BANKS*DATA_WIDTH)-1:0]      int_ram_data_bram_rddata_b [0:BATCH_SIZE-1];
  wire [DATA_BANKS-1:0]                   int_ram_data_bram_rdack_b [0:BATCH_SIZE-1];

  generate
  for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin: bram_ram_data_genblock
    MultiBankBram #(
      .BANKS  (DATA_BANKS),
      .WIDTH  (DATA_WIDTH),
      .DEPTH  (DATA_BANK_DEPTH),
      .ADDR   (DATA_ADDR)
    ) bram_ram_data_inst (
      .clk    (int_ram_data_bram_clk_a [BATCH]),
      .ena    (int_ram_data_bram_en_a [BATCH]),
      .wea    (int_ram_data_bram_we_a [BATCH]),
      .addra  (int_ram_data_bram_addr_a [BATCH]),
      .dina   (int_ram_data_bram_wrdata_a [BATCH]),
      .douta  (int_ram_data_bram_rddata_a [BATCH]),
      .enb    (int_ram_data_bram_en_b [BATCH]),
      .addrb  (int_ram_data_bram_addr_b [BATCH]),
      .doutb  (int_ram_data_bram_rddata_b [BATCH]),
      .validb (int_ram_data_bram_rdack_b [BATCH])
    );
  end
  endgenerate
 `endif

 `ifdef GRID_IF_IS_AXIL
 
  initial begin
    if (!GRID_SHARE) begin
      $error("Configuration error : GRID_SHARE can only be used with AXI-Lite interface.");
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
  wire                        int_ram_grid_s_axil_aclk;
  wire                        int_ram_grid_s_axil_arst;

  // Port A : destined for internal use
  // Keep Write channels of Port A
  wire [GRID_ADDR-1:0]        int_ram_grid_a_axil_awaddr;
  wire [2:0]                  int_ram_grid_a_axil_awprot;
  wire                        int_ram_grid_a_axil_awvalid;
  wire                        int_ram_grid_a_axil_awready;
  wire [GRID_WIDTH-1:0]       int_ram_grid_a_axil_wdata;
  wire [GRID_STRB_WIDTH-1:0]  int_ram_grid_a_axil_wstrb;
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
  wire [GRID_WIDTH-1:0]       int_ram_grid_a_axil_rdata;
  wire [1:0]                  int_ram_grid_a_axil_rresp;
  wire                        int_ram_grid_a_axil_rvalid;
  wire                        int_ram_grid_a_axil_rready;

  // Port B : destined for external interfacing
  // Drop Write channels of Port B
  wire [GRID_ADDR-1:0]        int_ram_grid_b_axil_awaddr = {GRID_ADDR{1'b0}};
  wire [2:0]                  int_ram_grid_b_axil_awprot = {2'b00};
  wire                        int_ram_grid_b_axil_awvalid = 1'b0;
  wire                        int_ram_grid_b_axil_awready;
  wire [AXIL_WIDTH-1:0]       int_ram_grid_b_axil_wdata = {AXIL_WIDTH{1'b0}};
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
  wire [AXIL_WIDTH-1:0]       int_ram_grid_b_axil_rdata;
  wire [1:0]                  int_ram_grid_b_axil_rresp;
  wire                        int_ram_grid_b_axil_rvalid;
  wire                        int_ram_grid_b_axil_rready;

  AxilDpRamPortbAdapter # (
    .ADDR_WIDTH(GRID_ADDR),
    .DATA_WIDTH(GRID_WIDTH),
    .DATA_WIDTH_EXT(AXIL_WIDTH),
    .PIPELINE_OUTPUT(GRID_PIPELINE_OUTPUT)
  ) axil_ram_grid_inst (
    .clk                (int_ram_grid_s_axil_aclk),
    .rst                (int_ram_grid_s_axil_arst),
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

 `elsif GRID_IF_IS_BRAM
  /**********************************************
    Interface Translator between BRAM Controller
    and Grid BRAM

    Naming conventions
    - int_ : internal signal
    - _trl_ : indicates a translator module
    - _i : input / slave interface
    - _o : output / master interface
  *********************************************/
  wire                                    int_trl_grid_bram_en_i;
  wire [BRAM_CTRL_WE-1:0]                 int_trl_grid_bram_we_i;
  wire [GRID_ITRL_ADDR-1:0]               int_trl_grid_bram_addr_i;
  wire [BRAM_CTRL_WIDTH-1:0]              int_trl_grid_bram_wrdata_i;
  wire [BRAM_CTRL_WIDTH-1:0]              int_trl_grid_bram_rddata_i;
  
  wire [GRID_BANKS-1:0]                   int_trl_grid_bram_en_o;
  wire [(GRID_BANKS*GRID_WE)-1:0]         int_trl_grid_bram_we_o;
  wire [(GRID_BANKS*GRID_ADDR)-1:0]       int_trl_grid_bram_addr_o;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]      int_trl_grid_bram_wrdata_o;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]      int_trl_grid_bram_rddata_o;

  BramIntrfTranslator # (
    .IN_WIDTH     (BRAM_CTRL_WIDTH),
    .OUT_WIDTH    (GRID_WIDTH),
    .BANKS        (GRID_BANKS),
    .OUT_DEPTH    (GRID_BANK_DEPTH)
  ) bram_trl_grid_inst (
    .en_i         (int_trl_grid_bram_en_i),
    .we_i         (int_trl_grid_bram_we_i),
    .addr_i       (int_trl_grid_bram_addr_i),
    .wrdata_i     (int_trl_grid_bram_wrdata_i),
    .rddata_i     (int_trl_grid_bram_rddata_i),
    .en_o         (int_trl_grid_bram_en_o),
    .we_o         (int_trl_grid_bram_we_o),
    .addr_o       (int_trl_grid_bram_addr_o),
    .wrdata_o     (int_trl_grid_bram_wrdata_o),
    .rddata_o     (int_trl_grid_bram_rddata_o)
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
  wire [(GRID_BANKS*GRID_WE)-1:0]         int_ram_grid_bram_we_a;
  wire [(GRID_BANKS*GRID_ADDR)-1:0]       int_ram_grid_bram_addr_a;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]      int_ram_grid_bram_wrdata_a;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]      int_ram_grid_bram_rddata_a;

  wire [GRID_BANKS-1:0]                   int_ram_grid_bram_en_b;
  wire [(GRID_BANKS*GRID_ADDR)-1:0]       int_ram_grid_bram_addr_b;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]      int_ram_grid_bram_rddata_b;
  wire [GRID_BANKS-1:0]                   int_ram_grid_bram_rdack_b;

  MultiBankBram #(
    .BANKS  (GRID_BANKS),
    .WIDTH  (GRID_WIDTH),
    .DEPTH  (GRID_BANK_DEPTH),
    .ADDR   (GRID_ADDR)
  ) bram_ram_data_inst (
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
  
  initial begin
    if (!SCALE_SHARE) begin
      $display("Configuration error : SCALE_SHARE can only be used with AXI-Lite interface.");
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
  wire                        int_ram_scle_s_axil_aclk;
  wire                        int_ram_scle_s_axil_arst;

  // Port A : destined for internal use
  // Keep Write channels of Port A
  wire [SCALE_ADDR-1:0]       int_ram_scle_a_axil_awaddr;
  wire [2:0]                  int_ram_scle_a_axil_awprot;
  wire                        int_ram_scle_a_axil_awvalid;
  wire                        int_ram_scle_a_axil_awready;
  wire [SCALE_WIDTH-1:0]      int_ram_scle_a_axil_wdata;
  wire [SCALE_STRB_WIDTH:0]   int_ram_scle_a_axil_wstrb;
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
  wire [SCALE_WIDTH-1:0]      int_ram_scle_a_axil_rdata;
  wire [1:0]                  int_ram_scle_a_axil_rresp;
  wire                        int_ram_scle_a_axil_rvalid;
  wire                        int_ram_scle_a_axil_rready;

  // Port B : destined for external interfacing
  // Drop Write channels of Port B
  wire [SCALE_ADDR-1:0]       int_ram_scle_b_axil_awaddr = {SCALE_ADDR{1'b0}};
  wire [2:0]                  int_ram_scle_b_axil_awprot = {2'b00};
  wire                        int_ram_scle_b_axil_awvalid = 1'b0;
  wire                        int_ram_scle_b_axil_awready;
  wire [AXIL_WIDTH-1:0]       int_ram_scle_b_axil_wdata = {AXIL_WIDTH{1'b0}};
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
  wire [AXIL_WIDTH-1:0]       int_ram_scle_b_axil_rdata;
  wire [1:0]                  int_ram_scle_b_axil_rresp;
  wire                        int_ram_scle_b_axil_rvalid;
  wire                        int_ram_scle_b_axil_rready;

  AxilDpRamPortbAdapter # (
    .ADDR_WIDTH(SCALE_ADDR),
    .DATA_WIDTH(SCALE_WIDTH),
    .DATA_WIDTH_EXT(AXIL_WIDTH),
    .PIPELINE_OUTPUT(SCALE_PIPELINE_OUTPUT)
  ) axil_ram_scle_inst (
    .clk                (int_ram_scle_s_axil_aclk),
    .rst                (int_ram_scle_s_axil_arst),
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

 `elsif SCALE_IF_IS_BRAM
    /**********************************************
      Interface Translator between BRAM Controller
      and Scale BRAM

      Naming conventions
      - int_ : internal signal
      - _trl_ : indicates a translator module
      - _i : input / slave interface
      - _o : output / master interface
    *********************************************/
    wire                                      int_trl_scle_bram_en_i;
    wire [BRAM_CTRL_WE-1:0]                   int_trl_scle_bram_we_i;
    wire [SCALE_ITRL_ADDR-1:0]                int_trl_scle_bram_addr_i;
    wire [BRAM_CTRL_WIDTH-1:0]                int_trl_scle_bram_wrdata_i;
    wire [BRAM_CTRL_WIDTH-1:0]                int_trl_scle_bram_rddata_i;
    
    wire [SCALE_BANKS-1:0]                    int_trl_scle_bram_en_o;
    wire [(SCALE_BANKS*SCALE_WE)-1:0]         int_trl_scle_bram_we_o;
    wire [(SCALE_BANKS*SCALE_ADDR)-1:0]       int_trl_scle_bram_addr_o;
    wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]      int_trl_scle_bram_wrdata_o;
    wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]      int_trl_scle_bram_rddata_o;

    BramIntrfTranslator # (
      .IN_WIDTH   (BRAM_CTRL_WIDTH),
      .OUT_WIDTH  (SCALE_WIDTH),
      .BANKS      (SCALE_BANKS),
      .OUT_DEPTH  (SCALE_BANK_DEPTH)
    ) bram_trl_scle_inst (
      .en_i       (int_trl_scle_bram_en_i),
      .we_i       (int_trl_scle_bram_we_i),
      .addr_i     (int_trl_scle_bram_addr_i),
      .wrdata_i   (int_trl_scle_bram_wrdata_i),
      .rddata_i   (int_trl_scle_bram_rddata_i),
      .en_o       (int_trl_scle_bram_en_o),
      .we_o       (int_trl_scle_bram_we_o),
      .addr_o     (int_trl_scle_bram_addr_o),
      .wrdata_o   (int_trl_scle_bram_wrdata_o),
      .rddata_o   (int_trl_scle_bram_rddata_o)
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
    wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]      int_ram_scle_bram_wrdata_a;
    wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]      int_ram_scle_bram_rddata_a;

    wire [SCALE_BANKS-1:0]                    int_ram_scle_bram_en_b;
    wire [(SCALE_BANKS*SCALE_ADDR)-1:0]       int_ram_scle_bram_addr_b;
    wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]      int_ram_scle_bram_rddata_b;
    wire [SCALE_BANKS-1:0]                    int_ram_scle_bram_rdack_b;

    MultiBankBram #(
      .BANKS  (SCALE_BANKS),
      .WIDTH  (SCALE_WIDTH),
      .DEPTH  (DATA_BANK_DEPTH),
      .ADDR   (SCALE_ADDR)
    ) bram_ram_scle_inst (
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
  assign bram_ctrl_scle_dout        = int_ram_scle_bram_rddata_a;
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
  wire [BATCH_SIZE-1:0]                           int_mcu_data_m_axil_aclk;
  wire [BATCH_SIZE*DATA_ADDR-1:0]                 int_mcu_data_m_axil_araddr;
  wire [BATCH_SIZE*3-1:0]                         int_mcu_data_m_axil_arprot;
  wire [BATCH_SIZE-1:0]                           int_mcu_data_m_axil_arvalid;
  wire [BATCH_SIZE-1:0]                           int_mcu_data_m_axil_arready;
  wire [BATCH_SIZE*DATA_WIDTH-1:0]                int_mcu_data_m_axil_rdata;
  wire [BATCH_SIZE*2-1:0]                         int_mcu_data_m_axil_rresp;
  wire [BATCH_SIZE-1:0]                           int_mcu_data_m_axil_rvalid;
  wire [BATCH_SIZE-1:0]                           int_mcu_data_m_axil_rready;

 `elsif DATA_IF_IS_BRAM
  wire [BATCH_SIZE*DATA_BANKS-1:0]                int_mcu_data_bram_clk;
  wire [BATCH_SIZE*DATA_BANKS-1:0]                int_mcu_data_bram_en;
  wire [BATCH_SIZE*(DATA_BANKS*DATA_ADDR)-1:0]    int_mcu_data_bram_addr;
  wire [BATCH_SIZE*(DATA_BANKS*DATA_WIDTH)-1:0]   int_mcu_data_bram_rddata;
  wire [BATCH_SIZE*DATA_BANKS-1:0]                int_mcu_data_bram_rdack;

 `endif

 `ifdef GRID_IF_IS_AXIL
  wire                                            int_mcu_grid_m_axil_aclk;
  wire [GRID_ADDR-1:0]                            int_mcu_grid_m_axil_araddr;
  wire [2:0]                                      int_mcu_grid_m_axil_arprot;
  wire                                            int_mcu_grid_m_axil_arvalid;
  wire                                            int_mcu_grid_m_axil_arready;
  wire [GRID_WIDTH-1:0]                           int_mcu_grid_m_axil_rdata;
  wire [1:0]                                      int_mcu_grid_m_axil_rresp;
  wire                                            int_mcu_grid_m_axil_rvalid;
  wire                                            int_mcu_grid_m_axil_rready;

 `elsif GRID_IF_IS_BRAM
  wire [GRID_BANKS-1:0]                           int_mcu_grid_bram_clk;
  wire [GRID_BANKS-1:0]                           int_mcu_grid_bram_en;
  wire [(GRID_BANKS*GRID_ADDR)-1:0]               int_mcu_grid_bram_addr;
  wire [(GRID_BANKS*GRID_WIDTH)-1:0]              int_mcu_grid_bram_rddata;
  wire [GRID_BANKS-1:0]                           int_mcu_grid_bram_rdack;

 `endif

 `ifdef SCALE_IF_IS_AXIL
  wire                                            int_mcu_scle_m_axil_aclk;
  wire [SCALE_ADDR-1:0]                           int_mcu_scle_m_axil_araddr;
  wire [2:0]                                      int_mcu_scle_m_axil_arprot;
  wire                                            int_mcu_scle_m_axil_arvalid;
  wire                                            int_mcu_scle_m_axil_arready;
  wire [SCALE_WIDTH-1:0]                          int_mcu_scle_m_axil_rdata;
  wire [1:0]                                      int_mcu_scle_m_axil_rresp;
  wire                                            int_mcu_scle_m_axil_rvalid;
  wire                                            int_mcu_scle_m_axil_rready;
 `elsif SCALE_IF_IS_BRAM
  wire [SCALE_BANKS-1:0]                          int_mcu_scle_bram_clk;
  wire [SCALE_BANKS-1:0]                          int_mcu_scle_bram_en;
  wire [(SCALE_BANKS*SCALE_ADDR)-1:0]             int_mcu_scle_bram_addr;
  wire [(SCALE_BANKS*SCALE_WIDTH)-1:0]            int_mcu_scle_bram_rddata;
  wire [SCALE_BANKS-1:0]                          int_mcu_scle_bram_rdack;
 `endif

  wire [DATA_CHANNELS_OUT-1:0]                    int_mcu_data_m_axis_aclk;
  wire [DATA_CHANNELS_OUT*DATA_WIDTH-1:0]         int_mcu_data_m_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                    int_mcu_data_m_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                    int_mcu_data_m_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                    int_mcu_data_m_axis_tlast;

  wire [GRID_CHANNELS_OUT-1:0]                    int_mcu_grid_m_axis_aclk;
  wire [GRID_CHANNELS_OUT*GRID_WIDTH-1:0]         int_mcu_grid_m_axis_tdata;
  wire [GRID_CHANNELS_OUT-1:0]                    int_mcu_grid_m_axis_tvalid;
  wire [GRID_CHANNELS_OUT-1:0]                    int_mcu_grid_m_axis_tready;
  wire [GRID_CHANNELS_OUT-1:0]                    int_mcu_grid_m_axis_tlast;

  wire [SCALE_CHANNELS_OUT-1:0]                   int_mcu_scle_m_axis_aclk;
  wire [SCALE_CHANNELS_OUT*SCALE_WIDTH-1:0]       int_mcu_scle_m_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_mcu_scle_m_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_mcu_scle_m_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_mcu_scle_m_axis_tlast;

  MemoryControlUnit #(
    // `include "header_MCUGlobalFSMParametersInst.vh"
   `ifdef BRAM_ACK_SIG_OPTION
    .BRAM_ACK_SIG               (1),
   `endif
    .BATCH_SIZE                 (BATCH_SIZE),
    .DATA_WIDTH                 (DATA_WIDTH),
    .GRID_WIDTH                 (GRID_WIDTH),
    .SCALE_WIDTH                (SCALE_WIDTH),
    .ID_ENABLE                  (0),
    .ID_WIDTH                   (1),
    .DEST_ENABLE                (0),
    .DEST_WIDTH                 (1),
    .USER_ENABLE                (0),
    .USER_WIDTH                 (1),
    .DATA_CHANNELS              (DATA_CHANNELS),
    .SCALE_SHARE                (SCALE_SHARE),
    .SCALE_CHANNELS_IN          (SCALE_CHANNELS_IN),
    .SCALE_CHANNELS_OUT         (SCALE_CHANNELS_OUT),
    .GRID_SHARE                 (GRID_SHARE),
    .GRID_CHANNELS_IN           (GRID_CHANNELS_IN),
    .GRID_CHANNELS_OUT          (GRID_CHANNELS_OUT),
    .DATA_ADDR                  (DATA_ADDR),
    .GRID_ADDR                  (GRID_ADDR),
    .SCALE_ADDR                 (SCALE_ADDR),
    .DATA_FIFO_DEPTH            (DATA_FIFO_DEPTH),
    .GRID_FIFO_DEPTH            (GRID_FIFO_DEPTH),
    .SCALE_FIFO_DEPTH           (SCALE_FIFO_DEPTH)
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
   `ifdef DATA_IF_IS_AXIL
    .m_axil_data_aclk           (int_mcu_data_m_axil_aclk),
    .m_axil_data_araddr         (int_mcu_data_m_axil_araddr),
    .m_axil_data_arprot         (int_mcu_data_m_axil_arprot),
    .m_axil_data_arvalid        (int_mcu_data_m_axil_arvalid),
    .m_axil_data_arready        (int_mcu_data_m_axil_arready),
    .m_axil_data_rdata          (int_mcu_data_m_axil_rdata),
    .m_axil_data_rresp          (int_mcu_data_m_axil_rresp),
    .m_axil_data_rvalid         (int_mcu_data_m_axil_rvalid),
    .m_axil_data_rready         (int_mcu_data_m_axil_rready),
   `elsif DATA_IF_IS_BRAM
    .data_bram_clk              (int_mcu_data_bram_clk),
    .data_bram_en               (int_mcu_data_bram_en),
    .data_bram_addr             (int_mcu_data_bram_addr),
    .data_bram_rddata           (int_mcu_data_bram_rddata),
    .data_bram_rdack            (int_mcu_data_bram_rdack),
   `endif
    .m_axis_data_aclk           (int_mcu_data_m_axis_aclk),
    .m_axis_data_tdata          (int_mcu_data_m_axis_tdata),
    .m_axis_data_tvalid         (int_mcu_data_m_axis_tvalid),
    .m_axis_data_tready         (int_mcu_data_m_axis_tready),
    .m_axis_data_tlast          (int_mcu_data_m_axis_tlast),
   `ifdef GRID_IF_IS_AXIL
    .m_axil_grid_aclk           (int_mcu_grid_m_axil_aclk),
    .m_axil_grid_araddr         (int_mcu_grid_m_axil_araddr),
    .m_axil_grid_arprot         (int_mcu_grid_m_axil_arprot),
    .m_axil_grid_arvalid        (int_mcu_grid_m_axil_arvalid),
    .m_axil_grid_arready        (int_mcu_grid_m_axil_arready),
    .m_axil_grid_rdata          (int_mcu_grid_m_axil_rdata),
    .m_axil_grid_rresp          (int_mcu_grid_m_axil_rresp),
    .m_axil_grid_rvalid         (int_mcu_grid_m_axil_rvalid),
    .m_axil_grid_rready         (int_mcu_grid_m_axil_rready),
   `elsif GRID_IF_IS_BRAM
    .grid_bram_clk              (int_mcu_grid_bram_clk),
    .grid_bram_en               (int_mcu_grid_bram_en),
    .grid_bram_addr             (int_mcu_grid_bram_addr),
    .grid_bram_rddata           (int_mcu_grid_bram_rddata),
    .grid_bram_rdack            (int_mcu_grid_bram_rdack),
   `endif
    .m_axis_grid_aclk           (int_mcu_grid_m_axis_aclk),
    .m_axis_grid_tdata          (int_mcu_grid_m_axis_tdata),
    .m_axis_grid_tvalid         (int_mcu_grid_m_axis_tvalid),
    .m_axis_grid_tready         (int_mcu_grid_m_axis_tready),
    .m_axis_grid_tlast          (int_mcu_grid_m_axis_tlast),
   `ifdef SCALE_IF_IS_AXIL
    .m_axil_scle_aclk           (int_mcu_scle_m_axil_aclk),
    .m_axil_scle_araddr         (int_mcu_scle_m_axil_araddr),
    .m_axil_scle_arprot         (int_mcu_scle_m_axil_arprot),
    .m_axil_scle_arvalid        (int_mcu_scle_m_axil_arvalid),
    .m_axil_scle_arready        (int_mcu_scle_m_axil_arready),
    .m_axil_scle_rdata          (int_mcu_scle_m_axil_rdata),
    .m_axil_scle_rresp          (int_mcu_scle_m_axil_rresp),
    .m_axil_scle_rvalid         (int_mcu_scle_m_axil_rvalid),
    .m_axil_scle_rready         (int_mcu_scle_m_axil_rready),
   `elsif SCALE_IF_IS_BRAM
    .scle_bram_clk              (int_mcu_scle_bram_clk),
    .scle_bram_en               (int_mcu_scle_bram_en),
    .scle_bram_addr             (int_mcu_scle_bram_addr),
    .scle_bram_rddata           (int_mcu_scle_bram_rddata),
    .scle_bram_rdack            (int_mcu_scle_bram_rdack),
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

  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_s_axis_aclk;
  wire [DATA_CHANNELS_OUT*DATA_WIDTH-1:0]           int_adp_data_s_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_s_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_s_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_s_axis_tlast;

  wire [DATA_CHANNELS_OUT*DATA_WIDTH-1:0]           int_adp_data_m_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_m_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_m_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                      int_adp_data_m_axis_tlast;

 generate
  for (CHN=0; CHN < DATA_CHANNELS_OUT; CHN = CHN + 1) begin : axis_adp_data_genblock
    axis_async_fifo #(
      .DEPTH          (DATA_FIFO_DEPTH),
      .DATA_WIDTH     (DATA_WIDTH),
      .KEEP_ENABLE    (0),
      .KEEP_WIDTH     (1),
      .ID_ENABLE      (0),
      .ID_WIDTH       (1),
      .DEST_ENABLE    (0),
      .DEST_WIDTH     (1),
      .USER_ENABLE    (0),
      .USER_WIDTH     (1)
    ) axis_adp_data_inst (
      .s_clk          (int_adp_data_s_axis_aclk   [CHN]),
      .s_rst          (1'b0),
      .s_axis_tdata   (int_adp_data_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep   (1'b1),
      .s_axis_tvalid  (int_adp_data_s_axis_tvalid [CHN]),
      .s_axis_tready  (int_adp_data_s_axis_tready [CHN]),
      .s_axis_tlast   (int_adp_data_s_axis_tlast  [CHN]),
      .s_axis_tid     (1'b0),
      .s_axis_tdest   (1'b0),
      .s_axis_tuser   (1'b0),
      .m_clk          (core_clk),
      .m_rst          (core_rst),
      .m_axis_tdata   (int_adp_data_m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tvalid  (int_adp_data_m_axis_tvalid [CHN]),
      .m_axis_tready  (int_adp_data_m_axis_tready [CHN]),
      .m_axis_tlast   (int_adp_data_m_axis_tlast  [CHN]),
      .s_pause_req    (1'b0),
      .m_pause_req    (1'b0)
    );
  end 
 endgenerate

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

  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_s_axis_aclk;
  wire [GRID_CHANNELS_OUT*GRID_WIDTH-1:0]       int_adp_grid_s_axis_tdata;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_s_axis_tvalid;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_s_axis_tready;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_s_axis_tlast;

  wire [GRID_CHANNELS_OUT*GRID_WIDTH-1:0]       int_adp_grid_m_axis_tdata;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_m_axis_tvalid;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_m_axis_tready;
  wire [GRID_CHANNELS_OUT-1:0]                  int_adp_grid_m_axis_tlast;

 generate
  for (CHN=0; CHN < GRID_CHANNELS_OUT; CHN = CHN + 1) begin: axis_adp_grid_genblock
    axis_async_fifo #(
      .DEPTH          (GRID_FIFO_DEPTH),
      .DATA_WIDTH     (GRID_WIDTH),
      .KEEP_ENABLE    (0),
      .KEEP_WIDTH     (1),
      .ID_ENABLE      (0),
      .ID_WIDTH       (1),
      .DEST_ENABLE    (0),
      .DEST_WIDTH     (1),
      .USER_ENABLE    (0),
      .USER_WIDTH     (1)
    ) axis_adp_grid_inst (
      .s_clk          (int_adp_grid_s_axis_aclk   [CHN]),
      .s_rst          (1'b0),
      .s_axis_tdata   (int_adp_grid_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep   (1'b1),
      .s_axis_tvalid  (int_adp_grid_s_axis_tvalid [CHN]),
      .s_axis_tready  (int_adp_grid_s_axis_tready [CHN]),
      .s_axis_tlast   (int_adp_grid_s_axis_tlast  [CHN]),
      .s_axis_tid     (1'b0),
      .s_axis_tdest   (1'b0),
      .s_axis_tuser   (1'b0),
      .m_clk          (core_clk),
      .m_rst          (core_rst),
      .m_axis_tdata   (int_adp_grid_m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tvalid  (int_adp_grid_m_axis_tvalid [CHN]),
      .m_axis_tready  (int_adp_grid_m_axis_tready [CHN]),
      .m_axis_tlast   (int_adp_grid_m_axis_tlast  [CHN]),
      .s_pause_req    (1'b0),
      .m_pause_req    (1'b0)
    );
  end 
 endgenerate

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

  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_s_axis_aclk;
  wire [SCALE_CHANNELS_OUT*SCALE_WIDTH-1:0]     int_adp_scle_s_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_s_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_s_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_s_axis_tlast;

  wire [SCALE_CHANNELS_OUT*SCALE_WIDTH-1:0]     int_adp_scle_m_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_m_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_m_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                 int_adp_scle_m_axis_tlast;

 generate
  for (CHN=0; CHN < SCALE_CHANNELS_OUT; CHN = CHN + 1) begin: axis_adp_scle_genblock
    axis_async_fifo #(
      .DEPTH          (SCALE_FIFO_DEPTH),
      .DATA_WIDTH     (SCALE_WIDTH),
      .KEEP_ENABLE    (0),
      .KEEP_WIDTH     (1),
      .ID_ENABLE      (0),
      .ID_WIDTH       (1),
      .DEST_ENABLE    (0),
      .DEST_WIDTH     (1),
      .USER_ENABLE    (0),
      .USER_WIDTH     (1)
    ) axis_adp_scle_inst (
      .s_clk          (int_adp_scle_s_axis_aclk   [CHN]),
      .s_rst          (1'b0),
      .s_axis_tdata   (int_adp_scle_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep   (1'b1),
      .s_axis_tvalid  (int_adp_scle_s_axis_tvalid [CHN]),
      .s_axis_tready  (int_adp_scle_s_axis_tready [CHN]),
      .s_axis_tlast   (int_adp_scle_s_axis_tlast  [CHN]),
      .s_axis_tid     (1'b0),
      .s_axis_tdest   (1'b0),
      .s_axis_tuser   (1'b0),
      .m_clk          (core_clk),
      .m_rst          (core_rst),
      .m_axis_tdata   (int_adp_scle_m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tvalid  (int_adp_scle_m_axis_tvalid [CHN]),
      .m_axis_tready  (int_adp_scle_m_axis_tready [CHN]),
      .m_axis_tlast   (int_adp_scle_m_axis_tlast  [CHN]),
      .s_pause_req    (1'b0),
      .m_pause_req    (1'b0)
    );
  end 
 endgenerate

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
  wire [DMA_WIDTH-1:0]                          int_adp_wght_s_axis_tdata;
  wire [DMA_KEEP_WIDTH-1:0]                     int_adp_wght_s_axis_tkeep;
  wire                                          int_adp_wght_s_axis_tvalid;
  wire                                          int_adp_wght_s_axis_tready;
  wire                                          int_adp_wght_s_axis_tlast;

  wire                                          int_adp_wght_m_axis_aclk;
  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_adp_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS*WEIGHT_KEEP_WIDTH-1:0]  int_adp_wght_m_axis_tkeep;
  wire                                          int_adp_wght_m_axis_tvalid;
  wire                                          int_adp_wght_m_axis_tready;
  wire                                          int_adp_wght_m_axis_tlast;

  axis_async_fifo_adapter #(
    .DEPTH          (WEIGHT_FIFO_DEPTH),
    .S_DATA_WIDTH   (DMA_WIDTH),
    .M_DATA_WIDTH   (WEIGHT_CHANNELS*WEIGHT_WIDTH),
    .ID_ENABLE      (WEIGHT_ID_ENABLE),
    .ID_WIDTH       (WEIGHT_ID_WIDTH),
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

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_spl_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS*WEIGHT_KEEP_WIDTH-1:0]  int_spl_wght_s_axis_tkeep;
  wire                                          int_spl_wght_s_axis_tvalid;
  wire                                          int_spl_wght_s_axis_tready;
  wire                                          int_spl_wght_s_axis_tlast;

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_spl_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_spl_wght_m_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_spl_wght_m_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_spl_wght_m_axis_tlast;

  AxisSplitter #(
    .OUTPUT_DATA_WIDTH  (WEIGHT_WIDTH),
    .CHANNELS           (WEIGHT_CHANNELS),
    .INPUT_KEEP_ENABLE  (DMA_KEEP_ENABLE),
    .INPUT_KEEP_WIDTH   (WEIGHT_CHANNELS*WEIGHT_KEEP_WIDTH),
    .OUTPUT_KEEP_ENABLE (0),
    .OUTPUT_KEEP_WIDTH  (1),
    .LAST_ENABLE        (1),
    .ID_ENABLE          (WEIGHT_ID_ENABLE),
    .ID_WIDTH           (WEIGHT_ID_WIDTH),
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
    .s_axis_tid         (1'b0),
    .s_axis_tdest       (1'b0),
    .s_axis_tuser       (1'b0),
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

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]      int_aps_wght_s_axis_tdata , int_aps_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tvalid, int_aps_wght_m_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tready, int_aps_wght_m_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                   int_aps_wght_s_axis_tlast , int_aps_wght_m_axis_tlast;
  wire [WEIGHT_CHANNELS*WEIGHT_ID_WIDTH-1:0]   int_aps_wght_s_axis_tid   , int_aps_wght_m_axis_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]        int_aps_wght_s_axis_tdest , int_aps_wght_m_axis_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]        int_aps_wght_s_axis_tuser , int_aps_wght_m_axis_tuser;

  ExtendedAxisPacketSplitter #(
    .CHANNELS           (WEIGHT_CHANNELS),
    .DATA_WIDTH         (WEIGHT_WIDTH),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .ID_ENABLE          (WEIGHT_ID_ENABLE),
    .ID_WIDTH           (WEIGHT_ID_WIDTH),
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
    .s_axis_tid         ({WEIGHT_CHANNELS*WEIGHT_ID_WIDTH{1'b0}}),
    .s_axis_tdest       ({WEIGHT_CHANNELS{1'b0}}),
    .s_axis_tuser       ({WEIGHT_CHANNELS{1'b0}}),
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
  
  wire [BATCH_SIZE*RSLT_CHANNELS*RSLT_WIDTH-1:0]  int_buf_rslt_s_axis_tdata;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_s_axis_tvalid;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_s_axis_tready;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_s_axis_tlast;

  wire [BATCH_SIZE*RSLT_CHANNELS*RSLT_WIDTH-1:0]  int_buf_rslt_m_axis_tdata;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_m_axis_tvalid;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_m_axis_tready;
  wire [BATCH_SIZE*RSLT_CHANNELS-1:0]             int_buf_rslt_m_axis_tlast;

  Buffer #(
    .CHANNELS         (BATCH_SIZE*RSLT_CHANNELS),
    .DATA_WIDTH       (RSLT_WIDTH),  
    .KEEP_ENABLE      (0),    
    .KEEP_WIDTH       (1),  
    .LAST_ENABLE      (1),    
    .ID_ENABLE        (0),  
    .ID_WIDTH         (1),
    .DEST_ENABLE      (0),    
    .DEST_WIDTH       (1),  
    .USER_ENABLE      (0),    
    .USER_WIDTH       (1),  
    .REG_TYPE         (1)
  ) buffer_inst (
    .clk              (core_clk),
    .rst              (core_rst),
    .s_axis_tdata     (int_buf_rslt_s_axis_tdata),
    .s_axis_tkeep     ({BATCH_SIZE*RSLT_CHANNELS{1'b1}}),
    .s_axis_tvalid    (int_buf_rslt_s_axis_tvalid),
    .s_axis_tready    (int_buf_rslt_s_axis_tready),
    .s_axis_tlast     (int_buf_rslt_s_axis_tlast),
    .s_axis_tid       ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .s_axis_tdest     ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .s_axis_tuser     ({BATCH_SIZE*RSLT_CHANNELS{1'b0}}),
    .m_axis_tdata     (int_buf_rslt_m_axis_tdata),
    .m_axis_tvalid    (int_buf_rslt_m_axis_tvalid),
    .m_axis_tready    (int_buf_rslt_m_axis_tready),
    .m_axis_tlast     (int_buf_rslt_m_axis_tlast)
  );

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

  wire [RSLT_CHANNELS_OUT*RSLT_WIDTH-1:0]  int_jnr_rslt_s_axis_tdata;
  wire [RSLT_CHANNELS_OUT-1:0]             int_jnr_rslt_s_axis_tvalid;
  wire [RSLT_CHANNELS_OUT-1:0]             int_jnr_rslt_s_axis_tready;
  wire [RSLT_CHANNELS_OUT-1:0]             int_jnr_rslt_s_axis_tlast;

  wire [RSLT_WIDTH-1:0]                    int_jnr_rslt_m_axis_tdata;
  wire                                     int_jnr_rslt_m_axis_tvalid;
  wire                                     int_jnr_rslt_m_axis_tready;
  wire                                     int_jnr_rslt_m_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]                 int_jnr_rslt_m_axis_tid;

  BatchedAxisPacketJoiner #(
    .CHANNELS           (RSLT_CHANNELS),
    .BATCH_SIZE         (BATCH_SIZE),
    .DATA_WIDTH         (RSLT_WIDTH),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .ID_ENABLE          (0),
    .S_ID_WIDTH         (1),
    .M_ID_WIDTH         (RSLT_ID_WIDTH),
    .DEST_ENABLE        (0),
    .DEST_WIDTH         (1),
    .USER_ENABLE        (0),
    .USER_WIDTH         (1)
  ) batched_axis_packet_joiner_inst (
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
    .s_axis_tkeep       ({BATCH_SIZE*RSLT_CHANNELS{1'b1}}),
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

  wire [RSLT_WIDTH-1:0]       int_adp_rslt_s_axis_tdata;
  wire                        int_adp_rslt_s_axis_tvalid;
  wire                        int_adp_rslt_s_axis_tready;
  wire                        int_adp_rslt_s_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]    int_adp_rslt_s_axis_tid;

  wire [DMA_WIDTH-1:0]        int_adp_rslt_m_axis_tdata;
  wire [DMA_KEEP_WIDTH-1:0]   int_adp_rslt_m_axis_tkeep;
  wire                        int_adp_rslt_m_axis_tvalid;
  wire                        int_adp_rslt_m_axis_tready;
  wire                        int_adp_rslt_m_axis_tlast;
  wire [RSLT_ID_WIDTH-1:0]    int_adp_rslt_m_axis_tid;

  axis_async_fifo_adapter #(
    .DEPTH          (RSLT_FIFO_DEPTH),
    .S_DATA_WIDTH   (RSLT_WIDTH),
    .S_KEEP_ENABLE  (1),
    .S_KEEP_WIDTH   (RSLT_KEEP_WIDTH),
    .M_DATA_WIDTH   (DMA_WIDTH),
    .M_KEEP_ENABLE  (DMA_KEEP_ENABLE),
    .M_KEEP_WIDTH   (DMA_KEEP_WIDTH),
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
    .s_axis_tkeep   ({RSLT_KEEP_WIDTH{1'b1}}),
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
    .m_axis_tid     (int_adp_rslt_m_axis_tid),
    .s_pause_req    (1'b0),
    .m_pause_req    (1'b0)
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

  wire [DATA_CHANNELS_OUT*DATA_WIDTH-1:0]         int_dpu_data_s_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                    int_dpu_data_s_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                    int_dpu_data_s_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                    int_dpu_data_s_axis_tlast;

  wire [GRID_CHANNELS_OUT*DATA_WIDTH-1:0]         int_dpu_grid_s_axis_tdata;
  wire [GRID_CHANNELS_OUT-1:0]                    int_dpu_grid_s_axis_tvalid;
  wire [GRID_CHANNELS_OUT-1:0]                    int_dpu_grid_s_axis_tready;
  wire [GRID_CHANNELS_OUT-1:0]                    int_dpu_grid_s_axis_tlast;

  wire [SCALE_CHANNELS_OUT*SCALE_WIDTH-1:0]       int_dpu_scle_s_axis_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                   int_dpu_scle_s_axis_tlast;

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]         int_dpu_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                      int_dpu_wght_s_axis_tlast;

  wire [RSLT_CHANNELS_OUT*RSLT_WIDTH-1:0]         int_dpu_rslt_m_axis_tdata;
  wire [RSLT_CHANNELS_OUT-1:0]                    int_dpu_rslt_m_axis_tvalid;
  wire [RSLT_CHANNELS_OUT-1:0]                    int_dpu_rslt_m_axis_tready;
  wire [RSLT_CHANNELS_OUT-1:0]                    int_dpu_rslt_m_axis_tlast;

  ParallelizedDataProcessor #(
    .BATCH_SIZE                   (BATCH_SIZE),
    .DATA_WIDTH                   (DATA_WIDTH),
    .DATA_FRACTIONAL_BITS         (DATA_FRACTIONAL_BITS),
    .SCALE_WIDTH                  (SCALE_WIDTH),
    .SCALE_FRACTIONAL_BITS        (SCALE_FRACTIONAL_BITS),
    .WEIGHT_WIDTH                 (WEIGHT_WIDTH),
    .WEIGHT_FRACTIONAL_BITS       (WEIGHT_FRACTIONAL_BITS),
    .SCALED_DIFF_WIDTH            (SCALED_DIFF_WIDTH),
    .SCALED_DIFF_FRACTIONAL_BITS  (SCALED_DIFF_FRACTIONAL_BITS),
    .ACT_WIDTH                    (ACT_WIDTH),
    .ACT_FRACTIONAL_BITS          (ACT_FRACTIONAL_BITS),
    .RSLT_WIDTH                   (RSLT_WIDTH),
    .RSLT_FRACTIONAL_BITS         (RSLT_FRACTIONAL_BITS),
    .KEEP_ENABLE                  (0),
    .KEEP_WIDTH                   (1),
    .ID_ENABLE                    (0),
    .ID_WIDTH                     (1),
    .DEST_ENABLE                  (0),
    .DEST_WIDTH                   (1),
    .USER_ENABLE                  (0),
    .USER_WIDTH                   (1),
    .DATA_CHANNELS                (DATA_CHANNELS),
    .RSLT_CHANNELS                (RSLT_CHANNELS),
    .SCALE_SHARE                  (SCALE_SHARE),
    .GRID_SHARE                   (GRID_SHARE),
    .ROM_DATA_PATH                (ROM_DATA_PATH),
    .OUTPUT_DEST                  (0),
    .OUTPUT_ID                    (0),
    .FIFO_DEPTH                   (0),
    .PIPELINE_LEVEL               (2)
  ) data_processor_inst (
    .clk                          (core_clk),
    .rst                          (~fsm_rst),
    .s_axis_data_tdata            (int_dpu_data_s_axis_tdata),
    .s_axis_data_tvalid           (int_dpu_data_s_axis_tvalid),
    .s_axis_data_tready           (int_dpu_data_s_axis_tready),
    .s_axis_data_tlast            (int_dpu_data_s_axis_tlast),
    .s_axis_data_tid              ({DATA_CHANNELS_OUT{1'b0}}),
    .s_axis_data_tdest            ({DATA_CHANNELS_OUT{1'b0}}),
    .s_axis_data_tuser            ({DATA_CHANNELS_OUT{1'b0}}),
    .s_axis_grid_tdata            (int_dpu_grid_s_axis_tdata),
    .s_axis_grid_tvalid           (int_dpu_grid_s_axis_tvalid),
    .s_axis_grid_tready           (int_dpu_grid_s_axis_tready),
    .s_axis_grid_tlast            (int_dpu_grid_s_axis_tlast),
    .s_axis_grid_tid              ({GRID_CHANNELS_OUT{1'b0}}),
    .s_axis_grid_tdest            ({GRID_CHANNELS_OUT{1'b0}}),
    .s_axis_grid_tuser            ({GRID_CHANNELS_OUT{1'b0}}),
    .s_axis_scle_tdata            (int_dpu_scle_s_axis_tdata),
    .s_axis_scle_tvalid           (int_dpu_scle_s_axis_tvalid),
    .s_axis_scle_tready           (int_dpu_scle_s_axis_tready),
    .s_axis_scle_tlast            (int_dpu_scle_s_axis_tlast),
    .s_axis_scle_tid              ({SCALE_CHANNELS_OUT{1'b0}}),
    .s_axis_scle_tdest            ({SCALE_CHANNELS_OUT{1'b0}}),
    .s_axis_scle_tuser            ({SCALE_CHANNELS_OUT{1'b0}}),
    .s_axis_wght_tdata            (int_dpu_wght_s_axis_tdata),
    .s_axis_wght_tvalid           (int_dpu_wght_s_axis_tvalid),
    .s_axis_wght_tready           (int_dpu_wght_s_axis_tready),
    .s_axis_wght_tlast            (int_dpu_wght_s_axis_tlast),
    .s_axis_wght_tid              ({WEIGHT_CHANNELS{1'b0}}),
    .s_axis_wght_tdest            ({WEIGHT_CHANNELS{1'b0}}),
    .s_axis_wght_tuser            ({WEIGHT_CHANNELS{1'b0}}),
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
    `include "header_SystemSizesInst.vh"
    .BATCH_SIZE                     (BATCH_SIZE),
    .DATA_CHANNELS                  (DATA_CHANNELS),
    .RSLT_CHANNELS                  (RSLT_CHANNELS),
    .DATA_ADDR                      (DATA_ADDR),
    .GRID_ADDR                      (GRID_ADDR),
    .SCALE_ADDR                     (SCALE_ADDR),
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
  generate
  for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin: axil_if_batch_genblock
    // Connect Port A of Axil Data Ram to Data MCU
    assign int_mcu_data_m_axil_aclk    [BATCH]                          = int_ram_data_s_axil_aclk    [BATCH];
    assign int_ram_data_a_axil_araddr  [BATCH]                          = int_mcu_data_m_axil_araddr  [BATCH*DATA_ADDR +: DATA_ADDR];
    assign int_ram_data_a_axil_arprot  [BATCH]                          = int_mcu_data_m_axil_arprot  [BATCH*3 +: 3];
    assign int_ram_data_a_axil_arvalid [BATCH]                          = int_mcu_data_m_axil_arvalid [BATCH];
    assign int_mcu_data_m_axil_arready [BATCH]                          = int_ram_data_a_axil_arready [BATCH];
    assign int_mcu_data_m_axil_rdata   [BATCH*DATA_WIDTH +: DATA_WIDTH] = int_ram_data_a_axil_rdata   [BATCH];
    assign int_mcu_data_m_axil_rresp   [BATCH*2 +: 2]                   = int_ram_data_a_axil_rresp   [BATCH];
    assign int_mcu_data_m_axil_rvalid  [BATCH]                          = int_ram_data_a_axil_rvalid  [BATCH];
    assign int_ram_data_a_axil_rready  [BATCH]                          = int_mcu_data_m_axil_rready  [BATCH];

    // Connect Port B of Axil Data Ram to S_AXIL_DATA interface
    assign int_ram_data_s_axil_aclk [BATCH]                   = s_axil_data_aclk [BATCH];
    assign int_ram_data_s_axil_arst [BATCH]                   = s_axil_data_areset [BATCH];
    assign int_ram_data_b_axil_awaddr [BATCH]                 = s_axil_data_awaddr [BATCH*DATA_ADDR +: DATA_ADDR];
    assign int_ram_data_b_axil_awprot [BATCH]                 = s_axil_data_awprot [BATCH*3 +: 3];
    assign int_ram_data_b_axil_awvalid [BATCH]                = s_axil_data_awvalid [BATCH];
    assign s_axil_data_awready [BATCH]                        = int_ram_data_b_axil_awready [BATCH];
    assign int_ram_data_b_axil_wdata [BATCH]                  = s_axil_data_wdata [BATCH*AXIL_WIDTH +: AXIL_WIDTH];
    assign int_ram_data_b_axil_wstrb [BATCH]                  = s_axil_data_wstrb [BATCH*DATA_STRB_WIDTH +: DATA_STRB_WIDTH];
    assign int_ram_data_b_axil_wvalid [BATCH]                 = s_axil_data_wvalid [BATCH];
    assign s_axil_data_wready [BATCH]                         = int_ram_data_b_axil_wready [BATCH];
    assign s_axil_data_bresp [BATCH*2 +: 2]                   = int_ram_data_b_axil_bresp [BATCH];
    assign s_axil_data_bvalid [BATCH]                         = int_ram_data_b_axil_bvalid [BATCH];
    assign int_ram_data_b_axil_bready [BATCH]                 = s_axil_data_bready [BATCH];
    assign int_ram_data_b_axil_araddr [BATCH]                 = s_axil_data_araddr [BATCH*DATA_ADDR +: DATA_ADDR];
    assign int_ram_data_b_axil_arprot [BATCH]                 = s_axil_data_arprot [BATCH*3 +: 3];
    assign int_ram_data_b_axil_arvalid [BATCH]                = s_axil_data_arvalid [BATCH];
    assign s_axil_data_arready [BATCH]                        = int_ram_data_b_axil_arready [BATCH];
    assign s_axil_data_rdata [BATCH*AXIL_WIDTH +: AXIL_WIDTH] = int_ram_data_b_axil_rdata [BATCH];
    assign s_axil_data_rresp [BATCH]                          = int_ram_data_b_axil_rresp [BATCH];
    assign s_axil_data_rvalid [BATCH]                         = int_ram_data_b_axil_rvalid [BATCH];
    assign int_ram_data_b_axil_rready [BATCH]                 = s_axil_data_rready [BATCH];
  end
  endgenerate

 `elsif DATA_IF_IS_BRAM
  generate
  for (BATCH = 0; BATCH < BATCH_SIZE; BATCH = BATCH + 1) begin: bram_if_batch_genblock
    // bram control interface to the data bram translator
    assign int_trl_data_bram_en_i     [BATCH]                                     = bram_ctrl_data_en [BATCH];
    assign int_trl_data_bram_we_i     [BATCH]                                     = bram_ctrl_data_we [BATCH];
    assign int_trl_data_bram_addr_i   [BATCH]                                     = bram_ctrl_data_addr [BATCH*BRAM_CTRL_ADDR +2 +: DATA_ITRL_ADDR];
    assign int_trl_data_bram_wrdata_i [BATCH]                                     = bram_ctrl_data_din [BATCH*BRAM_CTRL_WIDTH +: BRAM_CTRL_WIDTH];
    assign bram_ctrl_data_dout        [BATCH*BRAM_CTRL_WIDTH +: BRAM_CTRL_WIDTH]  = int_trl_data_bram_rddata_i [BATCH];

    // data bram translator to data bram port a
    assign int_ram_data_bram_clk_a    [BATCH] = bram_ctrl_data_clk [BATCH];
    assign int_ram_data_bram_en_a     [BATCH] = int_trl_data_bram_en_o [BATCH];
    assign int_ram_data_bram_we_a     [BATCH] = int_trl_data_bram_we_o [BATCH];
    assign int_ram_data_bram_addr_a   [BATCH] = int_trl_data_bram_addr_o [BATCH];
    assign int_ram_data_bram_wrdata_a [BATCH] = int_trl_data_bram_wrdata_o [BATCH];
    assign int_trl_data_bram_rddata_o [BATCH] = int_ram_data_bram_rddata_a [BATCH];

    // data bram port b to memory control unit
    assign int_mcu_data_bram_clk      [BATCH]                           = int_ram_data_bram_clk_a [BATCH];
    assign int_ram_data_bram_en_b     [BATCH]                           = int_mcu_data_bram_en [BATCH];
    assign int_ram_data_bram_addr_b   [BATCH]                           = int_mcu_data_bram_addr [BATCH*DATA_ADDR +: DATA_ADDR];
    assign int_mcu_data_bram_rddata   [BATCH*DATA_WIDTH +: DATA_WIDTH]  = int_ram_data_bram_rddata_b [BATCH];
    assign int_mcu_data_bram_rdack    [BATCH]                           = int_ram_data_bram_rdack_b [BATCH];
  end
  endgenerate
 `endif
 
 `ifdef GRID_IF_IS_AXIL
  // Connect Port A of Axil Grid Ram to Grid MCU
  assign int_mcu_grid_m_axil_aclk    = int_ram_grid_s_axil_aclk;
  assign int_ram_grid_a_axil_araddr  = int_mcu_grid_m_axil_araddr;
  assign int_ram_grid_a_axil_arprot  = int_mcu_grid_m_axil_arprot;
  assign int_ram_grid_a_axil_arvalid = int_mcu_grid_m_axil_arvalid;
  assign int_mcu_grid_m_axil_arready = int_ram_grid_a_axil_arready;
  assign int_mcu_grid_m_axil_rdata   = int_ram_grid_a_axil_rdata;
  assign int_mcu_grid_m_axil_rresp   = int_ram_grid_a_axil_rresp;
  assign int_mcu_grid_m_axil_rvalid  = int_ram_grid_a_axil_rvalid;
  assign int_ram_grid_a_axil_rready  = int_mcu_grid_m_axil_rready;

  // Connect Port B of Axil Grid Ram to S_AXIL_GRID interface
  assign int_ram_grid_s_axil_aclk     = s_axil_grid_aclk;
  assign int_ram_grid_s_axil_arst     = s_axil_grid_areset;
  assign int_ram_grid_b_axil_awaddr   = s_axil_grid_awaddr;
  assign int_ram_grid_b_axil_awprot   = s_axil_grid_awprot;
  assign int_ram_grid_b_axil_awvalid  = s_axil_grid_awvalid;
  assign s_axil_grid_awready          = int_ram_grid_b_axil_awready;
  assign int_ram_grid_b_axil_wdata    = s_axil_grid_wdata;
  assign int_ram_grid_b_axil_wstrb    = s_axil_grid_wstrb;
  assign int_ram_grid_b_axil_wvalid   = s_axil_grid_wvalid;
  assign s_axil_grid_wready           = int_ram_grid_b_axil_wready;
  assign s_axil_grid_bresp            = int_ram_grid_b_axil_bresp;
  assign s_axil_grid_bvalid           = int_ram_grid_b_axil_bvalid;
  assign int_ram_grid_b_axil_bready   = s_axil_grid_bready;
  assign int_ram_grid_b_axil_araddr   = s_axil_grid_araddr;
  assign int_ram_grid_b_axil_arprot   = s_axil_grid_arprot;
  assign int_ram_grid_b_axil_arvalid  = s_axil_grid_arvalid;
  assign s_axil_grid_arready          = int_ram_grid_b_axil_arready;
  assign s_axil_grid_rdata            = int_ram_grid_b_axil_rdata;
  assign s_axil_grid_rresp            = int_ram_grid_b_axil_rresp;
  assign s_axil_grid_rvalid           = int_ram_grid_b_axil_rvalid;
  assign int_ram_grid_b_axil_rready   = s_axil_grid_rready;

 `elsif GRID_IF_IS_BRAM
  // bram control interface to the data bram translator
  assign int_trl_grid_bram_en_i     = bram_ctrl_grid_en;
  assign int_trl_grid_bram_we_i     = bram_ctrl_grid_we;
  assign int_trl_grid_bram_addr_i   = bram_ctrl_grid_addr;
  assign int_trl_grid_bram_wrdata_i = bram_ctrl_grid_din;
  assign bram_ctrl_grid_dout        = int_trl_grid_bram_rddata_i;

  // bram control interface to the grid bram port a
  assign int_ram_grid_bram_clk_a     = bram_ctrl_grid_clk;
  assign int_ram_grid_bram_en_a      = int_trl_grid_bram_en_o;
  assign int_ram_grid_bram_we_a      = int_trl_grid_bram_we_o;
  assign int_ram_grid_bram_addr_a    = int_trl_grid_bram_addr_o;
  assign int_ram_grid_bram_wrdata_a  = int_trl_grid_bram_wrdata_o;
  assign int_trl_grid_bram_rddata_o  = int_ram_grid_bram_rddata_a;

  // grid bram port b to memory control unit
  assign int_mcu_grid_bram_clk       = int_ram_grid_bram_clk_a;
  assign int_ram_grid_bram_en_b      = int_mcu_grid_bram_en;
  assign int_ram_grid_bram_addr_b    = int_mcu_grid_bram_addr;
  assign int_mcu_grid_bram_rddata    = int_ram_grid_bram_rddata_b;
  assign int_mcu_grid_bram_rdack     = int_ram_grid_bram_rdack_b;
 `endif
 
 `ifdef SCALE_IF_IS_AXIL
  // Connect Port A of Axil Scale Ram to Scale MCU
  assign int_mcu_scle_m_axil_aclk    = int_ram_scle_s_axil_aclk;
  assign int_ram_scle_a_axil_araddr  = int_mcu_scle_m_axil_araddr;
  assign int_ram_scle_a_axil_arprot  = int_mcu_scle_m_axil_arprot;
  assign int_ram_scle_a_axil_arvalid = int_mcu_scle_m_axil_arvalid;
  assign int_mcu_scle_m_axil_arready = int_ram_scle_a_axil_arready;
  assign int_mcu_scle_m_axil_rdata   = int_ram_scle_a_axil_rdata;
  assign int_mcu_scle_m_axil_rresp   = int_ram_scle_a_axil_rresp;
  assign int_mcu_scle_m_axil_rvalid  = int_ram_scle_a_axil_rvalid;
  assign int_ram_scle_a_axil_rready  = int_mcu_scle_m_axil_rready;

  // Connect Port B of Axil Scale Ram to S_AXIL_SCALE interface
  assign int_ram_scle_s_axil_aclk       = s_axil_scle_aclk;
  assign int_ram_scle_s_axil_arst       = s_axil_scle_areset;
  assign int_ram_scle_b_axil_awaddr     = s_axil_scle_awaddr;
  assign int_ram_scle_b_axil_awprot     = s_axil_scle_awprot;
  assign int_ram_scle_b_axil_awvalid    = s_axil_scle_awvalid;
  assign s_axil_scle_awready            = int_ram_scle_b_axil_awready;
  assign int_ram_scle_b_axil_wdata      = s_axil_scle_wdata;
  assign int_ram_scle_b_axil_wstrb      = s_axil_scle_wstrb;
  assign int_ram_scle_b_axil_wvalid     = s_axil_scle_wvalid;
  assign s_axil_scle_wready             = int_ram_scle_b_axil_wready;
  assign s_axil_scle_bresp              = int_ram_scle_b_axil_bresp;
  assign s_axil_scle_bvalid             = int_ram_scle_b_axil_bvalid;
  assign int_ram_scle_b_axil_bready     = s_axil_scle_bready;
  assign int_ram_scle_b_axil_araddr     = s_axil_scle_araddr;
  assign int_ram_scle_b_axil_arprot     = s_axil_scle_arprot;
  assign int_ram_scle_b_axil_arvalid    = s_axil_scle_arvalid;
  assign s_axil_scle_arready            = int_ram_scle_b_axil_arready;
  assign s_axil_scle_rdata              = int_ram_scle_b_axil_rdata;
  assign s_axil_scle_rresp              = int_ram_scle_b_axil_rresp;
  assign s_axil_scle_rvalid             = int_ram_scle_b_axil_rvalid;
  assign int_ram_scle_b_axil_rready     = s_axil_scle_rready;

 `elsif SCALE_IF_IS_BRAM
  // bram control interface to the data bram translator
  assign int_trl_scle_bram_en_i     = bram_ctrl_scle_en;
  assign int_trl_scle_bram_we_i     = bram_ctrl_scle_we;
  assign int_trl_scle_bram_addr_i   = bram_ctrl_scle_addr;
  assign int_trl_scle_bram_wrdata_i = bram_ctrl_scle_din;
  assign bram_ctrl_scle_dout        = int_trl_scle_bram_rddata_i;

  // bram control interface to the grid bram port a
  assign int_ram_scle_bram_clk_a     = bram_ctrl_scle_clk;
  assign int_ram_scle_bram_en_a      = int_trl_scle_bram_en_o;
  assign int_ram_scle_bram_we_a      = int_trl_scle_bram_we_o;
  assign int_ram_scle_bram_addr_a    = int_trl_scle_bram_addr_o;
  assign int_ram_scle_bram_wrdata_a  = int_trl_scle_bram_wrdata_o;
  assign int_trl_scle_bram_rddata_o  = int_ram_scle_bram_rddata_a;

  // grid bram port b to memory control unit
  assign int_mcu_scle_bram_clk       = int_ram_scle_bram_clk_a;
  assign int_ram_scle_bram_en_b      = int_mcu_scle_bram_en;
  assign int_ram_scle_bram_addr_b    = int_mcu_scle_bram_addr;
  assign int_mcu_scle_bram_rddata    = int_ram_scle_bram_rddata_b;
  assign int_mcu_scle_bram_rdack     = int_ram_scle_bram_rdack_b;
 `endif

  // connect dma slave to slave axi adp

  assign int_adp_wght_s_axis_tdata   = s_axis_wght_tdata;
  assign int_adp_wght_s_axis_tkeep   = s_axis_wght_tkeep;
  assign int_adp_wght_s_axis_tvalid  = s_axis_wght_tvalid;
  assign s_axis_wght_tready          = int_adp_wght_s_axis_tready;
  assign int_adp_wght_s_axis_tlast   = s_axis_wght_tlast;

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

  assign int_buf_rslt_s_axis_tdata   = int_dpu_rslt_m_axis_tdata;
  assign int_buf_rslt_s_axis_tvalid  = int_dpu_rslt_m_axis_tvalid;
  assign int_dpu_rslt_m_axis_tready  = int_buf_rslt_s_axis_tready;
  assign int_buf_rslt_s_axis_tlast   = int_dpu_rslt_m_axis_tlast;

  assign int_jnr_rslt_s_axis_tdata   = int_buf_rslt_m_axis_tdata;
  assign int_jnr_rslt_s_axis_tvalid  = int_buf_rslt_m_axis_tvalid;
  assign int_buf_rslt_m_axis_tready  = int_jnr_rslt_s_axis_tready;
  assign int_jnr_rslt_s_axis_tlast   = int_buf_rslt_m_axis_tlast;

  // connect axi jnr of result streams to axi master adp

  assign int_adp_rslt_s_axis_tdata   = int_jnr_rslt_m_axis_tdata;
  assign int_adp_rslt_s_axis_tvalid  = int_jnr_rslt_m_axis_tvalid;
  assign int_jnr_rslt_m_axis_tready  = int_adp_rslt_s_axis_tready;
  assign int_adp_rslt_s_axis_tlast   = int_jnr_rslt_m_axis_tlast;
  assign int_adp_rslt_s_axis_tid     = int_jnr_rslt_m_axis_tid;

  // connect axi master adp to external master axi interface

  assign m_axis_rslt_tdata           = int_adp_rslt_m_axis_tdata;
  assign m_axis_rslt_tkeep           = int_adp_rslt_m_axis_tkeep;
  assign m_axis_rslt_tvalid          = int_adp_rslt_m_axis_tvalid;
  assign int_adp_rslt_m_axis_tready  = m_axis_rslt_tready;
  assign m_axis_rslt_tlast           = int_adp_rslt_m_axis_tlast;
  assign m_axis_rslt_tid             = (RSLT_ID_ENABLE) ? {int_adp_rslt_m_axis_tid, ID_OUTPUT[RSLT_ID_WIDTH-`LOG2(BATCH_SIZE):0]} : ID_OUTPUT;
  assign m_axis_rslt_tdest           = (DEST_ENABLE) ? DEST_OUTPUT : 0;
  assign m_axis_rslt_tuser           = (USER_ENABLE) ? USER_OUTPUT : 0;

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
