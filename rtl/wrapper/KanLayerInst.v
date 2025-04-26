`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"
`include "header_IFOptions.vh"

module KanLayerInst #(
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
    Bram controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter BRAM_CTRL_WIDTH = 32,
  parameter BRAM_CTRL_WE = 4,
  parameter BRAM_CTRL_ADDR = 12,

  /*------------------------------------------------------------------
    DATA parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = 4,
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

  // Use Common Grid Channel 
  parameter GRID_SHARE = 1, 
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
  parameter SCALE_SHARE = 1,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scle
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Total memory size allocated for Data in words
  parameter SCALE_DEPTH = 2,

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
  parameter RSLT_CHANNELS = 8,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12,
  // tkeep signal width (words per cycle)
  parameter RSLT_KEEP_WIDTH = ((RSLT_WIDTH + 7) / 8),
  // FIFO Depth for results
  parameter RSLT_FIFO_DEPTH = 16,

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
  parameter WEIGHT_FIFO_DEPTH = 2 ** `LOG2((DATA_CHANNELS + RSLT_CHANNELS) * DMA_KEEP_WIDTH),

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

  /*------------------------------------------------------------------
    Input / Output file constants
  ------------------------------------------------------------------*/

  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt"
) (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_ctrl, ASSOCIATED_RESET fsm_rst, FREQ_TOLERANCE_HZ 0" *)
  input  wire         fsm_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fsm_rst RST" *)
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire         fsm_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET core_rst, FREQ_TOLERANCE_HZ 0" *)
  input  wire         core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output wire         core_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dma_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_wght m_axis_rslt, ASSOCIATED_RESET dma_rst, FREQ_TOLERANCE_HZ 0" *)
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
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_data, ASSOCIATED_RESET s_axil_data_areset, FREQ_TOLERANCE_HZ 0" *)
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
  input  wire [DATA_WIDTH-1:0]        s_axil_data_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data WSTRB" *)
  input  wire [DATA_STRB_WIDTH-1:0]   s_axil_data_wstrb,
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
  output wire [DATA_WIDTH-1:0]        s_axil_data_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RRESP" *)
  output wire [1:0]                   s_axil_data_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RVALID" *)
  output wire                         s_axil_data_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_data RREADY" *)
  input  wire                         s_axil_data_rready,

  // Uncomment the following to set interface specific parameter on the bus interface.
  // (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC <value>,MEM_WIDTH <value>,MEM_SIZE <value>,READ_WRITE_MODE <value>" *)

 `elsif DATA_IF_IS_BRAM
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
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_grid, ASSOCIATED_RESET s_axil_grid_areset, FREQ_TOLERANCE_HZ 0" *)
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
  input  wire [GRID_WIDTH-1:0]   s_axil_grid_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
  input  wire [GRID_STRB_WIDTH-1:0]   s_axil_grid_wstrb,
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
  output wire [GRID_WIDTH-1:0]   s_axil_grid_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
  output wire [1:0]                   s_axil_grid_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
  output wire                         s_axil_grid_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
  input  wire                         s_axil_grid_rready,

 `elsif GRID_IF_IS_BRAM
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
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_scle, ASSOCIATED_RESET s_axil_scle_areset, FREQ_TOLERANCE_HZ 0" *)
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
  input  wire [SCALE_WIDTH-1:0]   s_axil_scle_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
  input  wire [SCALE_STRB_WIDTH-1:0]   s_axil_scle_wstrb,
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
  output wire [SCALE_WIDTH-1:0]   s_axil_scle_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
  output wire [1:0]                   s_axil_scle_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
  output wire                         s_axil_scle_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
  input  wire                         s_axil_scle_rready,

 `elsif  SCALE_IF_IS_BRAM
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
  input  wire [5:0]             s_axil_ctrl_awaddr,
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
  input  wire [5:0]             s_axil_ctrl_araddr,
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
      AXI-Stream WEIGHT Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN ,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  input  wire [DMA_WIDTH-1:0]       s_axis_wght_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TKEEP" *)
  input  wire [DMA_KEEP_WIDTH-1:0]  s_axis_wght_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TVALID" *)
  input  wire                       s_axis_wght_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TREADY" *)
  output wire                       s_axis_wght_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TLAST" *)
  input  wire                       s_axis_wght_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TID" *)
  input  wire [WEIGHT_ID_WIDTH-1:0]   s_axis_wght_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
  input  wire [DEST_WIDTH-1:0]      s_axis_wght_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
  input  wire [USER_WIDTH-1:0]      s_axis_wght_tuser,

  /*------------------------------------------------------------------
      AXI-Stream Results / Output Master interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN ,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  output wire [DMA_WIDTH-1:0]       m_axis_rslt_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TKEEP" *)
  output wire [DMA_KEEP_WIDTH-1:0]  m_axis_rslt_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TVALID" *)
  output wire                       m_axis_rslt_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TREADY" *)
  input  wire                       m_axis_rslt_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TLAST" *)
  output wire                       m_axis_rslt_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TID" *)
  output wire [RSLT_ID_WIDTH-1:0]   m_axis_rslt_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
  output wire [DEST_WIDTH-1:0]      m_axis_rslt_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
  output wire [USER_WIDTH-1:0]      m_axis_rslt_tuser
);

  // Grid Data Width
  localparam GRID_WIDTH = DATA_WIDTH;

  KanLayer #(
    .BATCH_SIZE                     (BATCH_SIZE),
    .DMA_WIDTH                      (DMA_WIDTH),
    .DMA_KEEP_ENABLE                (DMA_KEEP_ENABLE),
    .DMA_KEEP_WIDTH                 (DMA_KEEP_WIDTH),
    .BRAM_CTRL_WIDTH                (BRAM_CTRL_WIDTH),
    .BRAM_CTRL_WE                   (BRAM_CTRL_WE),
    .BRAM_CTRL_ADDR                 (BRAM_CTRL_ADDR),
    .DATA_WIDTH                     (DATA_WIDTH),
    .DATA_FRACTIONAL_BITS           (DATA_FRACTIONAL_BITS),
    .DATA_CHANNELS                  (DATA_CHANNELS),
    .DATA_DEPTH                     (DATA_DEPTH),
  `ifdef DATA_IF_IS_AXIL
    .DATA_ADDR                      (DATA_ADDR),
    .DATA_STRB_WIDTH                (DATA_STRB_WIDTH),
  `endif
    .GRID_SHARE                     (GRID_SHARE), 
    .GRID_DEPTH                     (GRID_DEPTH),
  `ifdef GRID_IF_IS_AXIL
    .GRID_ADDR                      (GRID_ADDR),
    .GRID_STRB_WIDTH                (GRID_STRB_WIDTH),
  `endif
    .SCALE_SHARE                    (SCALE_SHARE),
    .SCALE_WIDTH                    (SCALE_WIDTH),
    .SCALE_FRACTIONAL_BITS          (SCALE_FRACTIONAL_BITS),
    .SCALE_DEPTH                    (SCALE_DEPTH),
  `ifdef SCALE_IF_IS_AXIL
    .SCALE_ADDR                     (SCALE_ADDR),
    .SCALE_STRB_WIDTH               (SCALE_STRB_WIDTH),
  `endif
    .RSLT_CHANNELS                  (RSLT_CHANNELS),
    .RSLT_WIDTH                     (RSLT_WIDTH),
    .RSLT_FRACTIONAL_BITS           (RSLT_FRACTIONAL_BITS),
    .RSLT_KEEP_WIDTH                (RSLT_KEEP_WIDTH),
    .RSLT_FIFO_DEPTH                (RSLT_FIFO_DEPTH),
    .WEIGHT_WIDTH                   (WEIGHT_WIDTH),
    .WEIGHT_FRACTIONAL_BITS         (WEIGHT_FRACTIONAL_BITS),
    .WEIGHT_KEEP_ENABLE             (WEIGHT_KEEP_ENABLE),
    .WEIGHT_KEEP_WIDTH              (WEIGHT_KEEP_WIDTH),
    .WEIGHT_FIFO_DEPTH              (WEIGHT_FIFO_DEPTH),
    .SCALED_DIFF_WIDTH              (SCALED_DIFF_WIDTH),
    .SCALED_DIFF_FRACTIONAL_BITS    (SCALED_DIFF_FRACTIONAL_BITS),
    .ACT_WIDTH                      (ACT_WIDTH),
    .ACT_FRACTIONAL_BITS            (ACT_FRACTIONAL_BITS),
    .WEIGHT_ID_ENABLE               (WEIGHT_ID_ENABLE),
    .WEIGHT_ID_WIDTH                (WEIGHT_ID_WIDTH),
    .RSLT_ID_ENABLE                 (RSLT_ID_ENABLE),
    .RSLT_ID_WIDTH                  (RSLT_ID_WIDTH),
    .ID_OUTPUT                      (ID_OUTPUT),
    .DEST_ENABLE                    (DEST_ENABLE),
    .DEST_WIDTH                     (DEST_WIDTH),
    .DEST_OUTPUT                    (DEST_OUTPUT),
    .USER_ENABLE                    (USER_ENABLE),
    .USER_WIDTH                     (USER_WIDTH),
    .USER_OUTPUT                    (USER_OUTPUT),
    .EXTRA_CYCLE                    (EXTRA_CYCLE),
    .ROM_DATA_PATH                  (ROM_DATA_PATH)
  ) wrapper (
    .fsm_clk                    (fsm_clk),
    .fsm_rst                    (fsm_rst),

    .core_clk                   (core_clk),
    .core_rst                   (core_rst),

    .dma_clk                    (dma_clk),
    .dma_rst                    (dma_rst),

    /*------------------------------------------------------------------
        Generated Interrupts & Resets
    ------------------------------------------------------------------*/
    .operation_busy             (operation_busy),
    .operation_complete         (operation_complete),
    .operation_error            (operation_error),
    .locked                     (locked),
    .pl2ps_intr                 (pl2ps_intr),

    /*------------------------------------------------------------------
        BRAM Data Control interface
    ------------------------------------------------------------------*/
  `ifdef DATA_IF_IS_AXIL
    .s_axil_data_aclk           (s_axil_data_aclk),
    .s_axil_data_areset         (s_axil_data_areset),
    .s_axil_data_awaddr         (s_axil_data_awaddr),
    .s_axil_data_awprot         (s_axil_data_awprot),
    .s_axil_data_awvalid        (s_axil_data_awvalid),
    .s_axil_data_awready        (s_axil_data_awready),
    .s_axil_data_wdata          (s_axil_data_wdata),
    .s_axil_data_wstrb          (s_axil_data_wstrb),
    .s_axil_data_wvalid         (s_axil_data_wvalid),
    .s_axil_data_wready         (s_axil_data_wready),
    .s_axil_data_bresp          (s_axil_data_bresp),
    .s_axil_data_bvalid         (s_axil_data_bvalid),
    .s_axil_data_bready         (s_axil_data_bready),
    .s_axil_data_araddr         (s_axil_data_araddr),
    .s_axil_data_arprot         (s_axil_data_arprot),
    .s_axil_data_arvalid        (s_axil_data_arvalid),
    .s_axil_data_arready        (s_axil_data_arready),
    .s_axil_data_rdata          (s_axil_data_rdata),
    .s_axil_data_rresp          (s_axil_data_rresp),
    .s_axil_data_rvalid         (s_axil_data_rvalid),
    .s_axil_data_rready         (s_axil_data_rready),

  `elsif DATA_IF_IS_BRAM
    .bram_ctrl_data_clk         (bram_ctrl_data_clk),
    .bram_ctrl_data_rst         (bram_ctrl_data_rst),
    .bram_ctrl_data_en          (bram_ctrl_data_en),
    .bram_ctrl_data_we          (bram_ctrl_data_we),
    .bram_ctrl_data_addr        (bram_ctrl_data_addr),
    .bram_ctrl_data_din         (bram_ctrl_data_din),
    .bram_ctrl_data_dout        (bram_ctrl_data_dout),
  `endif 

    /*------------------------------------------------------------------
        BRAM Grid Control interface
    ------------------------------------------------------------------*/
  `ifdef GRID_IF_IS_AXIL
    .s_axil_grid_aclk                 (s_axil_grid_aclk),
    .s_axil_grid_areset               (s_axil_grid_areset),
    .s_axil_grid_awaddr               (s_axil_grid_awaddr),
    .s_axil_grid_awprot               (s_axil_grid_awprot),
    .s_axil_grid_awvalid              (s_axil_grid_awvalid),
    .s_axil_grid_awready              (s_axil_grid_awready),
    .s_axil_grid_wdata                (s_axil_grid_wdata),
    .s_axil_grid_wstrb                (s_axil_grid_wstrb),
    .s_axil_grid_wvalid               (s_axil_grid_wvalid),
    .s_axil_grid_wready               (s_axil_grid_wready),
    .s_axil_grid_bresp                (s_axil_grid_bresp),
    .s_axil_grid_bvalid               (s_axil_grid_bvalid),
    .s_axil_grid_bready               (s_axil_grid_bready),
    .s_axil_grid_araddr               (s_axil_grid_araddr),
    .s_axil_grid_arprot               (s_axil_grid_arprot),
    .s_axil_grid_arvalid              (s_axil_grid_arvalid),
    .s_axil_grid_arready              (s_axil_grid_arready),
    .s_axil_grid_rdata                (s_axil_grid_rdata),
    .s_axil_grid_rresp                (s_axil_grid_rresp),
    .s_axil_grid_rvalid               (s_axil_grid_rvalid),
    .s_axil_grid_rready               (s_axil_grid_rready),

  `elsif GRID_IF_IS_BRAM
    .bram_ctrl_grid_clk               (bram_ctrl_grid_clk),
    .bram_ctrl_grid_rst               (bram_ctrl_grid_rst),
    .bram_ctrl_grid_en                (bram_ctrl_grid_en),
    .bram_ctrl_grid_we                (bram_ctrl_grid_we),
    .bram_ctrl_grid_addr              (bram_ctrl_grid_addr),
    .bram_ctrl_grid_din               (bram_ctrl_grid_din),
    .bram_ctrl_grid_dout              (bram_ctrl_grid_dout),
  `endif

    /*------------------------------------------------------------------
        BRAM Scale Control interface
    ------------------------------------------------------------------*/

  `ifdef SCALE_IF_IS_AXIL
    .s_axil_scle_aclk                 (s_axil_scle_aclk),
    .s_axil_scle_areset               (s_axil_scle_areset),
    .s_axil_scle_awaddr               (s_axil_scle_awaddr),
    .s_axil_scle_awprot               (s_axil_scle_awprot),
    .s_axil_scle_awvalid              (s_axil_scle_awvalid),
    .s_axil_scle_awready              (s_axil_scle_awready),
    .s_axil_scle_wdata                (s_axil_scle_wdata),
    .s_axil_scle_wstrb                (s_axil_scle_wstrb),
    .s_axil_scle_wvalid               (s_axil_scle_wvalid),
    .s_axil_scle_wready               (s_axil_scle_wready),
    .s_axil_scle_bresp                (s_axil_scle_bresp),
    .s_axil_scle_bvalid               (s_axil_scle_bvalid),
    .s_axil_scle_bready               (s_axil_scle_bready),
    .s_axil_scle_araddr               (s_axil_scle_araddr),
    .s_axil_scle_arprot               (s_axil_scle_arprot),
    .s_axil_scle_arvalid              (s_axil_scle_arvalid),
    .s_axil_scle_arready              (s_axil_scle_arready),
    .s_axil_scle_rdata                (s_axil_scle_rdata),
    .s_axil_scle_rresp                (s_axil_scle_rresp),
    .s_axil_scle_rvalid               (s_axil_scle_rvalid),
    .s_axil_scle_rready               (s_axil_scle_rready),

  `elsif  SCALE_IF_IS_BRAM
    .bram_ctrl_scle_clk               (bram_ctrl_scle_clk),
    .bram_ctrl_scle_rst               (bram_ctrl_scle_rst),
    .bram_ctrl_scle_en                (bram_ctrl_scle_en),
    .bram_ctrl_scle_we                (bram_ctrl_scle_we),
    .bram_ctrl_scle_addr              (bram_ctrl_scle_addr),
    .bram_ctrl_scle_din               (bram_ctrl_scle_din),
    .bram_ctrl_scle_dout              (bram_ctrl_scle_dout),
  `endif
  
    /*------------------------------------------------------------------
        AXI-Lite Control Slave interface
    ------------------------------------------------------------------*/

    .s_axil_ctrl_awaddr                (s_axil_ctrl_awaddr),
    .s_axil_ctrl_awprot                (s_axil_ctrl_awprot),
    .s_axil_ctrl_awvalid               (s_axil_ctrl_awvalid),
    .s_axil_ctrl_awready               (s_axil_ctrl_awready),
    .s_axil_ctrl_wdata                 (s_axil_ctrl_wdata),
    .s_axil_ctrl_wstrb                 (s_axil_ctrl_wstrb),
    .s_axil_ctrl_wvalid                (s_axil_ctrl_wvalid),
    .s_axil_ctrl_wready                (s_axil_ctrl_wready),
    .s_axil_ctrl_bresp                 (s_axil_ctrl_bresp),
    .s_axil_ctrl_bvalid                (s_axil_ctrl_bvalid),
    .s_axil_ctrl_bready                (s_axil_ctrl_bready),
    .s_axil_ctrl_araddr                (s_axil_ctrl_araddr),
    .s_axil_ctrl_arprot                (s_axil_ctrl_arprot),
    .s_axil_ctrl_arvalid               (s_axil_ctrl_arvalid),
    .s_axil_ctrl_arready               (s_axil_ctrl_arready),
    .s_axil_ctrl_rdata                 (s_axil_ctrl_rdata),
    .s_axil_ctrl_rresp                 (s_axil_ctrl_rresp),
    .s_axil_ctrl_rvalid                (s_axil_ctrl_rvalid),
    .s_axil_ctrl_rready                (s_axil_ctrl_rready),

    /*------------------------------------------------------------------
        AXI-Stream WEIGHT Slave interface
    ------------------------------------------------------------------*/

    .s_axis_wght_tdata                  (s_axis_wght_tdata),
    .s_axis_wght_tkeep                  (s_axis_wght_tkeep),
    .s_axis_wght_tvalid                 (s_axis_wght_tvalid),  
    .s_axis_wght_tready                 (s_axis_wght_tready),
    .s_axis_wght_tlast                  (s_axis_wght_tlast),
    .s_axis_wght_tid                    (s_axis_wght_tid),
    .s_axis_wght_tdest                  (s_axis_wght_tdest),
    .s_axis_wght_tuser                  (s_axis_wght_tuser),

    /*------------------------------------------------------------------
        AXI-Stream Results / Output Master interface
    ------------------------------------------------------------------*/

    .m_axis_rslt_tdata                  (m_axis_rslt_tdata),
    .m_axis_rslt_tkeep                  (m_axis_rslt_tkeep),
    .m_axis_rslt_tvalid                 (m_axis_rslt_tvalid),  
    .m_axis_rslt_tready                 (m_axis_rslt_tready),
    .m_axis_rslt_tlast                  (m_axis_rslt_tlast),
    .m_axis_rslt_tid                    (m_axis_rslt_tid),
    .m_axis_rslt_tdest                  (m_axis_rslt_tdest),
    .m_axis_rslt_tuser                  (m_axis_rslt_tuser)
  );

endmodule

`resetall
