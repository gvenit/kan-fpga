/*
 * KanLayer: This acts as the top level hdl module
 *   of the KAN SoC design.
 *   The endgoal is that this particular module
 *   be drag-and-dropped in the Vivado Block Design.
 */

`include "utils.vh"

module KanLayer #(
  /*------------------------------------------------------------------
    Genreal parameters of the architecture
  ------------------------------------------------------------------*/
  
  `include "rtl/IFOptionsInst.vh"
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

  parameter BRAM_ctrl_WIDTH = 32,
  parameter BRAM_ctrl_WE = 4,
  parameter BRAM_ctrl_ADDR = 13,

  /*------------------------------------------------------------------
    DATA parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = 1,

  // number of DATA bram banks
  parameter DATA_BANKS = DATA_CHANNELS,
  // number of elements on a single bram bank
  parameter DATA_BANK_DEPTH = 16,
  // number of address bits needed for each bank
  parameter DATA_ADDR = `LOG2(DATA_BANK_DEPTH),
  // number of DATA_WE bits needed for each bank
  parameter DATA_WE = DATA_WIDTH_DATA / 8,

  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // depth of the grid bram
  parameter GRID_DEPTH = 16,
  // Use Common Grid Channel 
  parameter SHARE_GRID = `GRID_IS_SHARED, 
  // Input Grid Channels
  parameter GRID_CHANNELS_IN = (SHARE_GRID) ? 1 : DATA_CHANNELS,
  // Output Grid Channels
  parameter GRID_CHANNELS_OUT = (SHARE_GRID) ? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Pipeline Output Grid
  parameter PIPELINE_OUTPUT_GRID = 0,

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
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = (ID_ENABLE) ? 8 : 1,

  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,

  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,

  // Propagate tlast signal
  parameter LAST_ENABLE = 1,

  // Add Buffer on Output Streams
  parameter EXTRA_CYCLE = 0,

  /*------------------------------------------------------------------
    Input / Output file constants
  ------------------------------------------------------------------*/

  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.12_16.16.txt",

  /*------------------------------------------------------------------
    Miscalleneous parameters
  ------------------------------------------------------------------*/

  // Output Destination 
  parameter OUTPUT_DEST = 0,
  // Output Thread ID 
  parameter OUTPUT_ID = 1
) (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF fsm_clk, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire         fsm_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
  // (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire         aresetn,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF core_clk, ASSOCIATED_RESET core_rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire         core_clk,

  /*------------------------------------------------------------------
      Generated Interrupts & Resets
  ------------------------------------------------------------------*/
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output wire         core_rst,
  output wire         busy,
  output wire         error,

  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/

  // Uncomment the following to set interface specific parameter on the bus interface.
  // (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC <value>,MEM_WIDTH <value>,MEM_SIZE <value>,READ_WRITE_MODE <value>" *)

  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr CLK" *)
  input  wire                      bram_data_ctrl_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr RST" *)
  input  wire                      bram_data_ctrl_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                      bram_data_ctrl_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr WE" *)
  input  wire [BRAM_ctrl_WE-1:0]    bram_data_ctrl_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr ADDR" *)
  input  wire [BRAM_ctrl_ADDR-1:0]  bram_data_ctrl_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr DIN" *)
  input  wire [BRAM_ctrl_WIDTH-1:0] bram_data_ctrl_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr DOUT" *)
  output wire [BRAM_ctrl_WIDTH-1:0] bram_data_ctrl_dout,

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/
  `ifdef GRID_IF_IS_AXIL
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_grid_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_grid_aclk, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire                   s_axil_grid_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWADDR" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axil_grid_aclk,READ_WRITE_MODE READ_WRITE,ADDR_WIDTH GRID_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH DATA_WIDTH_GRID" *)
    input  wire [ADDR_WIDTH-1:0]  s_axil_grid_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWPROT" *)
    input  wire [2:0]             s_axil_grid_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWVALID" *)
    input  wire                   s_axil_grid_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWREADY" *)
    output wire                   s_axil_grid_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WDATA" *)
    input  wire [DATA_WIDTH-1:0]  s_axil_grid_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
    input  wire [STRB_WIDTH-1:0]  s_axil_grid_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WVALID" *)
    input  wire                   s_axil_grid_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WREADY" *)
    output wire                   s_axil_grid_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BRESP" *)
    output wire [1:0]             s_axil_grid_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BVALID" *)
    output wire                   s_axil_grid_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BREADY" *)
    input  wire                   s_axil_grid_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARADDR" *)
    input  wire [ADDR_WIDTH-1:0]  s_axil_grid_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARPROT" *)
    input  wire [2:0]             s_axil_grid_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARVALID" *)
    input  wire                   s_axil_grid_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARREADY" *)
    output wire                   s_axil_grid_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RDATA" *)
    output wire [DATA_WIDTH-1:0]  s_axil_grid_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
    output wire [1:0]             s_axil_grid_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
    output wire                   s_axil_grid_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
    input  wire                   s_axil_grid_rready,

  `elif GRID_IF_IS_BRAM
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr CLK" *)
    input  wire                      bram_grid_ctrl_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr RST" *)
    input  wire                      bram_grid_ctrl_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr EN" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
    input  wire                      bram_grid_ctrl_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr WE" *)
    input  wire [BRAM_ctrl_WE-1:0]    bram_grid_ctrl_we,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr ADDR" *)
    input  wire [BRAM_ctrl_ADDR-1:0]  bram_grid_ctrl_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr DIN" *)
    input  wire [BRAM_ctrl_WIDTH-1:0] bram_grid_ctrl_din,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr DOUT" *)
    output wire [BRAM_ctrl_WIDTH-1:0] bram_grid_ctrl_dout,
  `endif

  /*------------------------------------------------------------------
      BRAM Scale Control interface
  ------------------------------------------------------------------*/

  `ifdef SCALE_IF_IS_AXIL
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_scle_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_scle_aclk, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
    input  wire                   s_axil_scle_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWADDR" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axil_scle_aclk,READ_WRITE_MODE READ_WRITE,ADDR_WIDTH GRID_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH DATA_WIDTH_GRID" *)
    input  wire [ADDR_WIDTH-1:0]  s_axil_scle_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWPROT" *)
    input  wire [2:0]             s_axil_scle_awprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWVALID" *)
    input  wire                   s_axil_scle_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWREADY" *)
    output wire                   s_axil_scle_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WDATA" *)
    input  wire [DATA_WIDTH-1:0]  s_axil_scle_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
    input  wire [STRB_WIDTH-1:0]  s_axil_scle_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WVALID" *)
    input  wire                   s_axil_scle_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WREADY" *)
    output wire                   s_axil_scle_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BRESP" *)
    output wire [1:0]             s_axil_scle_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BVALID" *)
    output wire                   s_axil_scle_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BREADY" *)
    input  wire                   s_axil_scle_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARADDR" *)
    input  wire [ADDR_WIDTH-1:0]  s_axil_scle_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARPROT" *)
    input  wire [2:0]             s_axil_scle_arprot,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARVALID" *)
    input  wire                   s_axil_scle_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARREADY" *)
    output wire                   s_axil_scle_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RDATA" *)
    output wire [DATA_WIDTH-1:0]  s_axil_scle_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
    output wire [1:0]             s_axil_scle_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
    output wire                   s_axil_scle_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
    input  wire                   s_axil_scle_rready,

  `elif SCALE_IF_IS_BRAM
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr CLK" *)
    input  wire                      bram_scle_ctrl_clk,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr RST" *)
    input  wire                      bram_scle_ctrl_rst,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr EN" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
    input  wire                      bram_scle_ctrl_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr WE" *)
    input  wire [BRAM_ctrl_WE-1:0]    bram_scle_ctrl_we,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr ADDR" *)
    input  wire [BRAM_ctrl_ADDR-1:0]  bram_scle_ctrl_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr DIN" *)
    input  wire [BRAM_ctrl_WIDTH-1:0] bram_scle_ctrl_din,
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_scle_ctr DOUT" *)
    output wire [BRAM_ctrl_WIDTH-1:0] bram_scle_ctrl_dout,
  `endif
  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWADDR" *)
  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN fsm_clk,READ_WRITE_MODE READ_WRITE,ADDR_WIDTH GRID_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH DATA_WIDTH_GRID" *)
  input  wire [11:0]            s_axil_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWPROT" *)
  input  wire [2:0]             s_axil_ctrl_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWVALID" *)
  input  wire                   s_axil_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWREADY" *)
  output wire                   s_axil_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WDATA" *)
  input  wire [31:0]            s_axil_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WSTRB" *)
  input  wire [3:0]             s_axil_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WVALID" *)
  input  wire                   s_axil_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WREADY" *)
  output wire                   s_axil_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BRESP" *)
  output wire [1:0]             s_axil_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BVALID" *)
  output wire                   s_axil_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BREADY" *)
  input  wire                   s_axil_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARADDR" *)
  input  wire [11:0]            s_axil_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARPROT" *)
  input  wire [2:0]             s_axil_ctrl_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARVALID" *)
  input  wire                   s_axil_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARREADY" *)
  output wire                   s_axil_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RDATA" *)
  output wire [31:0]            s_axil_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RRESP" *)
  output wire [1:0]             s_axil_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RVALID" *)
  output wire                   s_axil_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RREADY" *)
  input  wire                   s_axil_ctrl_rready,

  /*------------------------------------------------------------------
      AXI-Stream Weight Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axis_wght_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_wght_aclk, ASSOCIATED_RESET aresetn, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire                       s_axis_wght_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN s_axis_wght_aclk,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
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
  input  wire [ID_WIDTH-1:0]        s_axis_wght_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
  input  wire [DEST_WIDTH-1:0]      s_axis_wght_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
  input  wire [USER_WIDTH-1:0]      s_axis_wght_tuser,

  /*------------------------------------------------------------------
      AXI-Stream Results / Output Master interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 m_axis_rslt_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF m_axis_rslt_aclk, ASSOCIATED_RESET core_rst, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0" *)
  input  wire                       m_axis_rslt_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
    (* X_INTERFACE_PARAMETER = "CLK_DOMAIN m_axis_rslt_aclk,HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
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
  output  wire [ID_WIDTH-1:0]       m_axis_rslt_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
  output  wire [DEST_WIDTH-1:0]     m_axis_rslt_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
  output  wire [USER_WIDTH-1:0]     m_axis_rslt_tuser
);

  /*************************************************************************************
   Local Paramters
  *************************************************************************************/

  localparam IN_WORD_DATA = BRAM_ctrl_WIDTH / DATA_WIDTH_DATA;

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_EXTRL_DEPTH = GRID_DEPTH / IN_WORD_DATA;  // grid depth as seen from external ram control interface
  localparam GRID_EXTRL_ADDR = `LOG2(GRID_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  localparam GRID_ADDR = `LOG2(GRID_DEPTH);  // number of input address bits of total grid memory
  localparam GRID_PHYS_DEPTH = GRID_DEPTH / IN_WORD_DATA;  // effective - physical depth of grid ram
  localparam GRID_PHYS_ADDR = `LOG2(GRID_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram

  localparam DATA_WIDTH_GRID = DATA_WIDTH_DATA;

  /*************************************************************************************
   Internal Signals
  *************************************************************************************/

  // control flags that connecy to axi-lite mm interface

  wire pl_flag_0, pl_flag_1;  // single bit flags for output from the PL and input to the PS
  wire ps_flag_0, ps_flag_1;  // single bit flags for input to the PS and output from the PS

  wire err_unalligned_data;   // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later
  wire err_user_flag;         // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later

  // wire core_rst; // Interrupt outputs. WARNING: Might be grouped into AXI-Lite MM interfaces later

  /*************************************************************************************
   Module instantiations with their local signals
  *************************************************************************************/

  /**********************************************
    Interface Translator between BRAM Controller
    and Data BRAM

    Naming conventions
    - int_ : internal signal
    - _ctrl_ : indicates a translator module
    - _i : input / slave interface
    - _o : output / master interface
  *********************************************/

  wire                                    int_data_bram_ctrl_en_i;
  wire [BRAM_ctrl_WE-1:0]                  int_data_bram_ctrl_we_i;
  wire [DATA_ITRL_ADDR-1:0]               int_data_bram_ctrl_addr_i;
  wire [BRAM_ctrl_WIDTH-1:0]               int_data_bram_ctrl_wrdata_i;
  wire [BRAM_ctrl_WIDTH-1:0]               int_data_bram_ctrl_rddata_i;
  
  wire [DATA_BANKS-1:0]                   int_data_bram_ctrl_en_o;
  wire [(DATA_BANKS*DATA_WE)-1:0]         int_data_bram_ctrl_we_o;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_data_bram_ctrl_addr_o;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_ctrl_wrdata_o;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_ctrl_rddata_o;

  BramIntrfTranslator #(
    .IN_WIDTH  (BRAM_ctrl_WIDTH),
    .OUT_WIDTH (DATA_WIDTH_DATA),
    .BANKS     (DATA_BANKS),
    .OUT_DEPTH (DATA_BANK_DEPTH)
  ) data_bram_interface_translator_inst (
    .en_i      (int_data_bram_ctrl_en_i),
    .we_i      (int_data_bram_ctrl_we_i),
    .addr_i    (int_data_bram_ctrl_addr_i),
    .wrdata_i  (int_data_bram_ctrl_wrdata_i),
    .rddata_i  (int_data_bram_ctrl_rddata_i),
    .en_o      (int_data_bram_ctrl_en_o),
    .we_o      (int_data_bram_ctrl_we_o),
    .addr_o    (int_data_bram_ctrl_addr_o),
    .wrdata_o  (int_data_bram_ctrl_wrdata_o),
    .rddata_o  (int_data_bram_ctrl_rddata_o)
  );

  /**********************************************
    Data Multi-Bank Dual-Port BRAM

    Naming conventions
    - int_ : internal signal
    - _a : port a (control port)
    - _b : port b (internal use)
  *********************************************/

  wire                                    int_data_bram_clk_a;
  wire [DATA_BANKS-1:0]                   int_data_bram_en_a;
  wire [(DATA_BANKS*DATA_WE)-1:0]         int_data_bram_we_a;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_data_bram_addr_a;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_wrdata_a;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_rddata_a;

  wire [DATA_BANKS-1:0]                   int_data_bram_en_b;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_data_bram_addr_b;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_rddata_b;
  wire [DATA_BANKS-1:0]                   int_data_bram_rdstrobe_b;

  MultiBankBram #(
    .BANKS(DATA_BANKS),
    .WIDTH(DATA_WIDTH_DATA),
    .DEPTH(DATA_BANK_DEPTH)
  ) data_multi_bank_bram_inst (
    .clk    (int_data_bram_clk_a),
    .ena    (int_data_bram_en_a),
    .wea    (int_data_bram_we_a),
    .addra  (int_data_bram_addr_a),
    .dina   (int_data_bram_wrdata_a),
    .douta  (int_data_bram_rddata_a),
    .enb    (int_data_bram_en_b),
    .addrb  (int_data_bram_addr_b),
    .doutb  (int_data_bram_rddata_b),
    .validb (int_data_bram_rdstrobe_b)
  );

 generate
  if (SHARE_GRID) begin
    // Port A
    wire                        int_grid_ram_a_clk;
    wire                        int_grid_ram_a_rst;
    // Keep Write channels of Port A
    wire [ADDR_WIDTH_GRID-1:0]  int_grid_ram_a_s_axil_awaddr;
    wire [2:0]                  int_grid_ram_a_s_axil_awprot;
    wire                        int_grid_ram_a_s_axil_awvalid;
    wire                        int_grid_ram_a_s_axil_awready;
    wire [DATA_WIDTH_GRID-1:0]  int_grid_ram_a_s_axil_wdata;
    wire [1-1:0]                int_grid_ram_a_s_axil_wstrb;
    wire                        int_grid_ram_a_s_axil_wvalid;
    wire                        int_grid_ram_a_s_axil_wready;
    wire [1:0]                  int_grid_ram_a_s_axil_bresp;
    wire                        int_grid_ram_a_s_axil_bvalid;
    wire                        int_grid_ram_a_s_axil_bready;
    // Keep Read channels of Port A
    wire [ADDR_WIDTH_GRID-1:0]  int_grid_ram_a_s_axil_araddr;
    wire [2:0]                  int_grid_ram_a_s_axil_arprot;
    wire                        int_grid_ram_a_s_axil_arvalid;
    wire                        int_grid_ram_a_s_axil_arready;
    wire [DATA_WIDTH_GRID-1:0]  int_grid_ram_a_s_axil_rdata;
    wire [1:0]                  int_grid_ram_a_s_axil_rresp;
    wire                        int_grid_ram_a_s_axil_rvalid;
    wire                        int_grid_ram_a_s_axil_rready;

    // Port B
    wire                        int_grid_ram_b_clk;
    wire                        int_grid_ram_b_rst;
    // Drop Write channels of Port B
    wire [ADDR_WIDTH_GRID-1:0]  int_grid_ram_b_s_axil_awaddr = {ADDR_WIDTH_GRID{1'b0}};
    wire [2:0]                  int_grid_ram_b_s_axil_awprot = {2'b00};
    wire                        int_grid_ram_b_s_axil_awvalid = 1'b0;
    wire                        int_grid_ram_b_s_axil_awready;
    wire [DATA_WIDTH_GRID-1:0]  int_grid_ram_b_s_axil_wdata = {ADDR_WIDTH_GRID{1'b0}};
    wire [1-1:0]                int_grid_ram_b_s_axil_wstrb = 1'b0;
    wire                        int_grid_ram_b_s_axil_wvalid = 1'b0;
    wire                        int_grid_ram_b_s_axil_wready = 1'b0;
    wire [1:0]                  int_grid_ram_b_s_axil_bresp;
    wire                        int_grid_ram_b_s_axil_bvalid;
    wire                        int_grid_ram_b_s_axil_bready = 1'b0;
    // Keep Read channels of Port B
    wire [ADDR_WIDTH_GRID-1:0]  int_grid_ram_b_s_axil_araddr;
    wire [2:0]                  int_grid_ram_b_s_axil_arprot;
    wire                        int_grid_ram_b_s_axil_arvalid;
    wire                        int_grid_ram_b_s_axil_arready;
    wire [DATA_WIDTH_GRID-1:0]  int_grid_ram_b_s_axil_rdata;
    wire [1:0]                  int_grid_ram_b_s_axil_rresp;
    wire                        int_grid_ram_b_s_axil_rvalid;
    wire                        int_grid_ram_b_s_axil_rready;

    axil_dp_ram # (
        // Width of data bus in bits
        .DATA_WIDTH(DATA_WIDTH_GRID)
        // Width of address bus in bits
        .ADDR_WIDTH(ADDR_WIDTH_GRID),
        // Width of wstrb (width of data bus in words)
        .STRB_WIDTH(1),
        // Extra pipeline register on output
        .PIPELINE_OUTPUT(PIPELINE_OUTPUT_GRID)
    ) grid_axil_ram (
        .a_clk              (int_grid_ram_a_clk),
        .a_rst              (int_grid_ram_a_rst),
        .b_clk              (int_grid_ram_b_clk),
        .b_rst              (int_grid_ram_b_rst),
        .s_axil_a_awaddr    (int_grid_ram_a_s_axil_awaddr),
        .s_axil_a_awprot    (int_grid_ram_a_s_axil_awprot),
        .s_axil_a_awvalid   (int_grid_ram_a_s_axil_awvalid),
        .s_axil_a_awready   (int_grid_ram_a_s_axil_awready),
        .s_axil_a_wdata     (int_grid_ram_a_s_axil_wdata),
        .s_axil_a_wstrb     (int_grid_ram_a_s_axil_wstrb),
        .s_axil_a_wvalid    (int_grid_ram_a_s_axil_wvalid),
        .s_axil_a_wready    (int_grid_ram_a_s_axil_wready),
        .s_axil_a_bresp     (int_grid_ram_a_s_axil_bresp),
        .s_axil_a_bvalid    (int_grid_ram_a_s_axil_bvalid),
        .s_axil_a_bready    (int_grid_ram_a_s_axil_bready),
        .s_axil_a_araddr    (int_grid_ram_a_s_axil_araddr),
        .s_axil_a_arprot    (int_grid_ram_a_s_axil_arprot),
        .s_axil_a_arvalid   (int_grid_ram_a_s_axil_arvalid),
        .s_axil_a_arready   (int_grid_ram_a_s_axil_arready),
        .s_axil_a_rdata     (int_grid_ram_a_s_axil_rdata),
        .s_axil_a_rresp     (int_grid_ram_a_s_axil_rresp),
        .s_axil_a_rvalid    (int_grid_ram_a_s_axil_rvalid),
        .s_axil_a_rready    (int_grid_ram_a_s_axil_rready),
        .s_axil_b_awaddr    (int_grid_ram_b_s_axil_awaddr),
        .s_axil_b_awprot    (int_grid_ram_b_s_axil_awprot),
        .s_axil_b_awvalid   (int_grid_ram_b_s_axil_awvalid),
        .s_axil_b_awready   (int_grid_ram_b_s_axil_awready),
        .s_axil_b_wdata     (int_grid_ram_b_s_axil_wdata),
        .s_axil_b_wstrb     (int_grid_ram_b_s_axil_wstrb),
        .s_axil_b_wvalid    (int_grid_ram_b_s_axil_wvalid),
        .s_axil_b_wready    (int_grid_ram_b_s_axil_wready),
        .s_axil_b_bresp     (int_grid_ram_b_s_axil_bresp),
        .s_axil_b_bvalid    (int_grid_ram_b_s_axil_bvalid),
        .s_axil_b_bready    (int_grid_ram_b_s_axil_bready),
        .s_axil_b_araddr    (int_grid_ram_b_s_axil_araddr),
        .s_axil_b_arprot    (int_grid_ram_b_s_axil_arprot),
        .s_axil_b_arvalid   (int_grid_ram_b_s_axil_arvalid),
        .s_axil_b_arready   (int_grid_ram_b_s_axil_arready),
        .s_axil_b_rdata     (int_grid_ram_b_s_axil_rdata),
        .s_axil_b_rresp     (int_grid_ram_b_s_axil_rresp),
        .s_axil_b_rvalid    (int_grid_ram_b_s_axil_rvalid),
        .s_axil_b_rready    (int_grid_ram_b_s_axil_rready)
    );

    // Connect Port A to S_AXIL_GRID interface
    assign int_grid_ram_a_clk             = s_axil_grid_aclk;
    assign int_grid_ram_a_rst             = aresetn;
    assign int_grid_ram_a_s_axil_awaddr   = s_axil_grid_awaddr;
    assign int_grid_ram_a_s_axil_awprot   = s_axil_grid_awprot;
    assign int_grid_ram_a_s_axil_awvalid  = s_axil_grid_awvalid;
    assign s_axil_grid_awready            = int_grid_ram_a_s_axil_awready;
    assign int_grid_ram_a_s_axil_wdata    = s_axil_grid_wdata;
    assign int_grid_ram_a_s_axil_wstrb    = s_axil_grid_wstrb;
    assign int_grid_ram_a_s_axil_wvalid   = s_axil_grid_wvalid;
    assign s_axil_grid_wready             = int_grid_ram_a_s_axil_wready;
    assign s_axil_grid_bresp              = int_grid_ram_a_s_axil_bresp;
    assign s_axil_grid_bvalid             = int_grid_ram_a_s_axil_bvalid;
    assign int_grid_ram_a_s_axil_bready   = s_axil_grid_bready;
    assign int_grid_ram_a_s_axil_araddr   = s_axil_grid_araddr;
    assign int_grid_ram_a_s_axil_arprot   = s_axil_grid_arprot;
    assign int_grid_ram_a_s_axil_arvalid  = s_axil_grid_arvalid;
    assign s_axil_grid_arready            = int_grid_ram_a_s_axil_arready;
    assign s_axil_grid_rdata              = int_grid_ram_a_s_axil_rdata;
    assign s_axil_grid_rresp              = int_grid_ram_a_s_axil_rresp;
    assign s_axil_grid_rvalid             = int_grid_ram_a_s_axil_rvalid;
    assign int_grid_ram_a_s_axil_rready   = s_axil_grid_rready;

  end else begin
    `define GRID_IF_IS_BRAM
    /**********************************************
      Interface Translator between BRAM Controller
      and Data BRAM

      Naming conventions
      - int_ : internal signal
      - _ctrl_ : indicates a translator module
      - _i : input / slave interface
      - _o : output / master interface
    *********************************************/
    wire                                    int_grid_bram_ctrl_en_i;
    wire [BRAM_ctrl_WE-1:0]                  int_grid_bram_ctrl_we_i;
    wire [DATA_ITRL_ADDR-1:0]               int_grid_bram_ctrl_addr_i;
    wire [BRAM_ctrl_WIDTH-1:0]               int_grid_bram_ctrl_wrdata_i;
    wire [BRAM_ctrl_WIDTH-1:0]               int_grid_bram_ctrl_rddata_i;
    
    wire [GRID_BANKS-1:0]                   int_grid_bram_ctrl_en_o;
    wire [(GRID_BANKS*DATA_WE)-1:0]         int_grid_bram_ctrl_we_o;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_grid_bram_ctrl_addr_o;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_ctrl_wrdata_o;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_ctrl_rddata_o;

    BramIntrfTranslator #(
      .IN_WIDTH  (BRAM_ctrl_WIDTH),
      .OUT_WIDTH (DATA_WIDTH_DATA),
      .BANKS     (DATA_BANKS),
      .OUT_DEPTH (DATA_BANK_DEPTH)
    ) data_bram_interface_translator_inst (
      .en_i     (int_grid_bram_ctrl_en_i),
      .we_i     (int_grid_bram_ctrl_we_i),
      .addr_i   (int_grid_bram_ctrl_addr_i),
      .wrdata_i (int_grid_bram_ctrl_wrdata_i),
      .rddata_i (int_grid_bram_ctrl_rddata_i),
      .en_o     (int_grid_bram_ctrl_en_o),
      .we_o     (int_grid_bram_ctrl_we_o),
      .addr_o   (int_grid_bram_ctrl_addr_o),
      .wrdata_o (int_grid_bram_ctrl_wrdata_o),
      .rddata_o (int_grid_bram_ctrl_rddata_o)
    );

    /**********************************************
      Grid Multi-Bank Dual-Port BRAM

      Naming conventions
      - int_ : internal signal
      - _a : port a (control port)
      - _b : port b (internal use)
    *********************************************/
    wire                                    int_grid_bram_clk_a;
    wire [GRID_BANKS-1:0]                   int_grid_bram_en_a;
    wire [(GRID_BANKS*DATA_WE)-1:0]         int_grid_bram_we_a;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_grid_bram_addr_a;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_wrdata_a;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_rddata_a;

    wire [GRID_BANKS-1:0]                   int_grid_bram_en_b;
    wire [(GRID_BANKS*DATA_ADDR)-1:0]       int_grid_bram_addr_b;
    wire [(GRID_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_rddata_b;
    wire [GRID_BANKS-1:0]                   int_grid_bram_rdstrobe_b;

    MultiBankBram #(
      .BANKS  (GRID_BANKS),
      .WIDTH  (DATA_WIDTH_GRID),
      .DEPTH  (DATA_BANK_DEPTH)
    ) grid_multi_bank_bram_inst (
      .clk    (int_grid_bram_clk_a),
      .ena    (int_grid_bram_en_a),
      .wea    (int_grid_bram_we_a),
      .addra  (int_grid_bram_addr_a),
      .dina   (int_grid_bram_wrdata_a),
      .douta  (int_grid_bram_rddata_a),
      .enb    (int_grid_bram_en_b),
      .addrb  (int_grid_bram_addr_b),
      .doutb  (int_grid_bram_rddata_b),
      .validb (int_grid_bram_rdstrobe_b)
    );
  end
  
  // bram control interface to the grid bram port a

  assign int_grid_bram_clk_a    = bram_grid_ctrl_clk;
  assign int_grid_bram_en_a     = bram_grid_ctrl_en;
  assign int_grid_bram_we_a     = bram_grid_ctrl_we;
  assign int_grid_bram_addr_a   = bram_grid_ctrl_addr[2 +: GRID_EXTRL_ADDR];
  assign int_grid_bram_wrdata_a = bram_grid_ctrl_din;
  assign bram_grid_ctrl_dout     = int_grid_bram_rddata_a;

 endgenerate
  /**********************************************
    Grid BRAM

    Naming conventions
    - int_ : internal signal
    - _a : port a (control port)
    - _b : port b (internal use)
  *********************************************/

  wire                                    int_grid_bram_clk_a;
  wire                                    int_grid_bram_en_a;
  wire [BRAM_ctrl_WE-1:0]                  int_grid_bram_we_a;
  wire [GRID_EXTRL_ADDR-1:0]              int_grid_bram_addr_a;
  wire [BRAM_ctrl_WIDTH-1:0]               int_grid_bram_wrdata_a;
  wire [BRAM_ctrl_WIDTH-1:0]               int_grid_bram_rddata_a;

  wire [DATA_BANKS-1:0]                   int_grid_bram_en_b;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_grid_bram_addr_b;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_rddata_b;
  wire [DATA_BANKS-1:0]                   int_grid_bram_rdstrobe_b;

  MultiWidthDualPortBram #(
    .PORT_B_WIDTH(DATA_WIDTH_DATA),
    .PORT_B_DEPTH(GRID_DEPTH),
    .PORT_A_WIDTH(BRAM_ctrl_WIDTH)
  ) grid_bram_inst (
    .clk(int_grid_bram_clk_a),
    .ena(int_grid_bram_en_a),
    .wea(int_grid_bram_we_a),
    .addra(int_grid_bram_addr_a),
    .dina(int_grid_bram_wrdata_a),
    .douta(int_grid_bram_rddata_a),
    .enb(int_grid_bram_en_b),
    .addrb(int_grid_bram_addr_b),
    .doutb(int_grid_bram_rddata_b),
    .validb(int_grid_bram_rdstrobe_b)
  );

  /**********************************************
    AXI-Lite Scale register

    The axi-lite signals are immediatly\
    connected to the axi-lite
    external slave interface
    without internal signals.

    Naming conventions
    - int_ : internal signal
    - _axil_ : axi-lite
  *********************************************/

  wire [DATA_WIDTH_SCALE-1:0] int_axil_scle_reg;

	AxiLiteScaleRegister  #(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(4),
    .SCALE_WIDTH(DATA_WIDTH_SCALE)
  ) axi_lite_scle_register_inst (
    .scle_reg(int_axil_scle_reg),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(aresetn),
    .S_AXI_AWADDR(s_axil_scle_awaddr),
    .S_AXI_AWPROT(s_axil_scle_awprot),
    .S_AXI_AWVALID(s_axil_scle_awvalid),
    .S_AXI_AWREADY(s_axil_scle_awready),
    .S_AXI_WDATA(s_axil_scle_wdata),
    .S_AXI_WSTRB(s_axil_scle_wstrb),
    .S_AXI_WVALID(s_axil_scle_wvalid),
    .S_AXI_WREADY(s_axil_scle_wready),
    .S_AXI_BRESP(s_axil_scle_bresp),
    .S_AXI_BVALID(s_axil_scle_bvalid),
    .S_AXI_BREADY(s_axil_scle_bready),
    .S_AXI_ARADDR(s_axil_scle_araddr),
    .S_AXI_ARPROT(s_axil_scle_arprot),
    .S_AXI_ARVALID(s_axil_scle_arvalid),
    .S_AXI_ARREADY(s_axil_scle_arready),
    .S_AXI_RDATA(s_axil_scle_rdata),
    .S_AXI_RRESP(s_axil_scle_rresp),
    .S_AXI_RVALID(s_axil_scle_rvalid),
    .S_AXI_RREADY(s_axil_scle_rready)
	);

  /**********************************************
    Memory Controller

    For now this is a dummy module

    Naming conventions
    - int_ : internal signal
    - mcu : indicates signal that connects
      directly to the MCU
    - _m_axis_ : master axi stream interface
  *********************************************/

  wire [DATA_BANKS-1:0]                   int_data_mcu_en;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_data_mcu_addr;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_mcu_rddata;
  wire [DATA_BANKS-1:0]                   int_data_mcu_rdstrobe;

  wire [DATA_BANKS-1:0]                   int_grid_mcu_en;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_grid_mcu_addr;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_mcu_rddata;
  wire [DATA_BANKS-1:0]                   int_grid_mcu_rdstrobe;

  wire [DATA_WIDTH_SCALE-1:0] int_axil_scle_mcu;

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_m_axis_data_mcu_tdata;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_data_mcu_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_data_mcu_tready;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_data_mcu_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             int_m_axis_data_mcu_tid;
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           int_m_axis_data_mcu_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           int_m_axis_data_mcu_tuser;

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_m_axis_grid_mcu_tdata;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_grid_mcu_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_grid_mcu_tready;
  wire [DATA_CHANNELS-1:0]                      int_m_axis_grid_mcu_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             int_m_axis_grid_mcu_tid;  
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           int_m_axis_grid_mcu_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           int_m_axis_grid_mcu_tuser;
                                                                  
  wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]    int_m_axis_scle_mcu_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_m_axis_scle_mcu_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_m_axis_scle_mcu_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_m_axis_scle_mcu_tlast;
  wire [SCALE_CHANNELS_OUT*ID_WIDTH-1:0]            int_m_axis_scle_mcu_tid; 
  wire [SCALE_CHANNELS_OUT*DEST_WIDTH-1:0]          int_m_axis_scle_mcu_tdest;
  wire [SCALE_CHANNELS_OUT*USER_WIDTH-1:0]          int_m_axis_scle_mcu_tuser;

  MemoryControlUnit #(
    `include "rtl/MCUGlobalFSMParametersInst.vh"
    // BRAM control has valid signal
    .BRAM_ACK_SIG(1),
    // Number of batches per run
    .BATCH_SIZE(BATCH_SIZE),
    // Width of AXI stream Input Data & Grid interfaces in bits
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    // Width of AXI stream Scale interface in bits
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    // Propagate tid signal
    .ID_ENABLE(ID_ENABLE),
    // tid signal width
    .ID_WIDTH(ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(USER_ENABLE),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Number of Independent AXI-Stream Data Channels per Batch
    .DATA_CHANNELS(DATA_CHANNELS),
    // Use Common Share Channel 
    .SHARE_SCALE(SHARE_SCALE),
    // Use Common Grid Channel 
    .SHARE_GRID(SHARE_GRID),
    // Data Width of address bus in bits
    .ADDR_WIDTH_DATA(ADDR_WIDTH_DATA),
    // Grid Width of address bus in bits
    .ADDR_WIDTH_GRID(ADDR_WIDTH_GRID),
    // Scale Width of address bus in bits
    .ADDR_WIDTH_SCALE(ADDR_WIDTH_SCALE),
    // Data FIFO size per stream
    .FIFO_DEPTH_DATA(FIFO_DEPTH_DATA),
    // Grid FIFO size per stream
    .FIFO_DEPTH_GRID(FIFO_DEPTH_GRID),
    // Scale FIFO size per stream
    .FIFO_DEPTH_SCALE(FIFO_DEPTH_SCALE)
  ) mcu_inst (
    .fsm_clk              (fsm_clk),
    .rst                  (rst),
    .operation_start      (operation_start),
    .data_size            (data_size),
    .grid_size            (grid_size),
    .scle_size            (scle_size),
    .operation_busy       (operation_busy),
    .operation_complete   (operation_complete),
    .operation_error      (operation_error),
    .data_bram_clk        (data_bram_clk),
    .data_bram_en         (data_bram_en),
    .data_bram_addr       (data_bram_addr),
    .data_bram_rddata     (data_bram_rddata),
    .data_bram_rdack      (data_bram_rdack),
    .m_axis_data_aclk     (int_m_axis_data_mcu_aclk),
    .m_axis_data_tdata    (int_m_axis_data_mcu_tdata),
    .m_axis_data_tvalid   (int_m_axis_data_mcu_tvalid),
    .m_axis_data_tready   (int_m_axis_data_mcu_tready),
    .m_axis_data_tlast    (int_m_axis_data_mcu_tlast),
    .m_axis_data_tid      (int_m_axis_data_mcu_tid),
    .m_axis_data_tdest    (int_m_axis_data_mcu_tdest),
    .m_axis_data_tuser    (int_m_axis_data_mcu_tuser),
    .grid_bram_clk        (grid_bram_clk),
    .grid_bram_en         (grid_bram_en),
    .grid_bram_addr       (grid_bram_addr),
    .grid_bram_rddata     (grid_bram_rddata),
    .grid_bram_rdack      (grid_bram_rdack),
    .m_axis_grid_aclk     (int_m_axis_grid_mcu_aclk),
    .m_axis_grid_tdata    (int_m_axis_grid_mcu_tdata),
    .m_axis_grid_tvalid   (int_m_axis_grid_mcu_tvalid),
    .m_axis_grid_tready   (int_m_axis_grid_mcu_tready),
    .m_axis_grid_tlast    (int_m_axis_grid_mcu_tlast),
    .m_axis_grid_tid      (int_m_axis_grid_mcu_tid),
    .m_axis_grid_tdest    (int_m_axis_grid_mcu_tdest),
    .m_axis_grid_tuser    (int_m_axis_grid_mcu_tuser),
    .scle_bram_clk        (scle_bram_clk),
    .scle_bram_en         (scle_bram_en),
    .scle_bram_addr       (scle_bram_addr),
    .scle_bram_rddata     (scle_bram_rddata),
    .scle_bram_rdack      (scle_bram_rdack),
    .m_axis_scle_aclk     (int_m_axis_scle_mcu_aclk),
    .m_axis_scle_tdata    (int_m_axis_scle_mcu_tdata),
    .m_axis_scle_tvalid   (int_m_axis_scle_mcu_tvalid),
    .m_axis_scle_tready   (int_m_axis_scle_mcu_tready),
    .m_axis_scle_tlast    (int_m_axis_scle_mcu_tlast),
    .m_axis_scle_tid      (int_m_axis_scle_mcu_tid),
    .m_axis_scle_tdest    (int_m_axis_scle_mcu_tdest),
    .m_axis_scle_tuser    (int_m_axis_scle_mcu_tuser)
  );

  /**********************************************
    Slave AXI adapter
    between the DMA Master
    and the Weight Streams Splitter 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [DATA_WIDTH_DMA-1:0]   int_s_axis_wght_adapter_tdata;
  wire [KEEP_WIDTH_DMA-1:0]   int_s_axis_wght_adapter_tkeep;
  wire                        int_s_axis_wght_adapter_tvalid;
  wire                        int_s_axis_wght_adapter_tready;
  wire                        int_s_axis_wght_adapter_tlast;
  wire [ID_WIDTH-1:0]         int_s_axis_wght_adapter_tid;
  wire [DEST_WIDTH-1:0]       int_s_axis_wght_adapter_tdest;
  wire [USER_WIDTH-1:0]       int_s_axis_wght_adapter_tuser;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_m_axis_wght_adapter_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] int_m_axis_wght_adapter_tkeep;
  wire                                         int_m_axis_wght_adapter_tvalid;
  wire                                         int_m_axis_wght_adapter_tready;
  wire                                         int_m_axis_wght_adapter_tlast;
  wire [ID_WIDTH-1:0]                          int_m_axis_wght_adapter_tid;
  wire [DEST_WIDTH-1:0]                        int_m_axis_wght_adapter_tdest;
  wire [USER_WIDTH-1:0]                        int_m_axis_wght_adapter_tuser;

  axis_adapter #(
    .S_DATA_WIDTH(DATA_WIDTH_DMA),
    .M_DATA_WIDTH(WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),    // !!! Mismatch between this module and Axi Adapter values
    .USER_WIDTH(USER_WIDTH)
  ) axis_adapter_wght_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(int_s_axis_wght_adapter_tdata),
    .s_axis_tkeep(int_s_axis_wght_adapter_tkeep),
    .s_axis_tvalid(int_s_axis_wght_adapter_tvalid),
    .s_axis_tready(int_s_axis_wght_adapter_tready),
    .s_axis_tlast(int_s_axis_wght_adapter_tlast),
    .s_axis_tid(int_s_axis_wght_adapter_tid),
    .s_axis_tdest(int_s_axis_wght_adapter_tdest),
    .s_axis_tuser(int_s_axis_wght_adapter_tuser),
    .m_axis_tdata(int_m_axis_wght_adapter_tdata),
    .m_axis_tkeep(int_m_axis_wght_adapter_tkeep),
    .m_axis_tvalid(int_m_axis_wght_adapter_tvalid),
    .m_axis_tready(int_m_axis_wght_adapter_tready),
    .m_axis_tlast(int_m_axis_wght_adapter_tlast),
    .m_axis_tid(int_m_axis_wght_adapter_tid),
    .m_axis_tdest(int_m_axis_wght_adapter_tdest),
    .m_axis_tuser(int_m_axis_wght_adapter_tuser)
  );

  /**********************************************
    Weight streams AXI splitter
    betweem the slave AXI adapter
    and the Data Processor 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_s_axis_wght_splitter_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] int_s_axis_wght_splitter_tkeep;
  wire                                         int_s_axis_wght_splitter_tvalid;
  wire                                         int_s_axis_wght_splitter_tready;
  wire                                         int_s_axis_wght_splitter_tlast;
  wire [ID_WIDTH-1:0]                          int_s_axis_wght_splitter_tid;
  wire [DEST_WIDTH-1:0]                        int_s_axis_wght_splitter_tdest;
  wire [USER_WIDTH-1:0]                        int_s_axis_wght_splitter_tuser;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_m_axis_wght_splitter_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_wght_splitter_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_wght_splitter_tready;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_wght_splitter_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]          int_m_axis_wght_splitter_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]        int_m_axis_wght_splitter_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]        int_m_axis_wght_splitter_tuser;

  AxisSplitter #(
    .OUTPUT_DATA_WIDTH(DATA_WIDTH_WEIGHT),
    .CHANNELS(WEIGHT_CHANNELS),
    .INPUT_KEEP_ENABLE(KEEP_ENABLE_DMA),
    .INPUT_KEEP_WIDTH(WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT),
    .OUTPUT_KEEP_ENABLE(0),
    .OUTPUT_KEEP_WIDTH(1),
    .LAST_ENABLE(LAST_ENABLE),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .EXTRA_CYCLE(EXTRA_CYCLE)
  ) axis_splitter_wghts_inst (
    .clk              (clk),
    .rst              (~aresetn),
    .s_axis_tdata     (int_s_axis_wght_splitter_tdata),
    .s_axis_tkeep     (int_s_axis_wght_splitter_tkeep),
    .s_axis_tvalid    (int_s_axis_wght_splitter_tvalid),
    .s_axis_tready    (int_s_axis_wght_splitter_tready),
    .s_axis_tlast     (int_s_axis_wght_splitter_tlast),
    .s_axis_tid       (int_s_axis_wght_splitter_tid),
    .s_axis_tdest     (int_s_axis_wght_splitter_tdest),
    .s_axis_tuser     (int_s_axis_wght_splitter_tuser),
    .m_axis_tdata     (int_m_axis_wght_splitter_tdata),
    .m_axis_tvalid    (int_m_axis_wght_splitter_tvalid),
    .m_axis_tready    (int_m_axis_wght_splitter_tready),
    .m_axis_tlast     (int_m_axis_wght_splitter_tlast),
    .m_axis_tid       (int_m_axis_wght_splitter_tid),
    .m_axis_tdest     (int_m_axis_wght_splitter_tdest),
    .m_axis_tuser     (int_m_axis_wght_splitter_tuser)
  );

  /**********************************************
    Result streams AXI Joiner between
    the Data Processor and the master AXI adapter 

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_s_axis_rslt_joiner_tdata;
  wire [RSLT_CHANNELS-1:0]                  int_s_axis_rslt_joiner_tvalid;
  wire [RSLT_CHANNELS-1:0]                  int_s_axis_rslt_joiner_tready;
  wire [RSLT_CHANNELS-1:0]                  int_s_axis_rslt_joiner_tlast;
  wire [RSLT_CHANNELS*ID_WIDTH-1:0]         int_s_axis_rslt_joiner_tid;
  wire [RSLT_CHANNELS*DEST_WIDTH-1:0]       int_s_axis_rslt_joiner_tdest;
  wire [RSLT_CHANNELS*USER_WIDTH-1:0]       int_s_axis_rslt_joiner_tuser;

  wire [RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_m_axis_rslt_joiner_tdata;
  wire [RSLT_CHANNELS*KEEP_WIDTH_RSLT-1:0]  int_m_axis_rslt_joiner_tkeep;
  wire                                      int_m_axis_rslt_joiner_tvalid;
  wire                                      int_m_axis_rslt_joiner_tready;
  wire                                      int_m_axis_rslt_joiner_tlast;
  wire [ID_WIDTH-1:0]                       int_m_axis_rslt_joiner_tid;
  wire [DEST_WIDTH-1:0]                     int_m_axis_rslt_joiner_tdest;
  wire [USER_WIDTH-1:0]                     int_m_axis_rslt_joiner_tuser;

  /* ADD JOINER MODULE */

  /**********************************************
    Master AXI adapter between
    the Result Streams Joiner
    and the DMA slave

    Naming conventions
    - int_ : internal signal
    - _axis_ : axi stream
    - _s_ : input / slave interface
    - _m_ : otuput / master interface
  *********************************************/

  wire [RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]  int_s_axis_rslt_adapter_tdata;
  wire [RSLT_CHANNELS*KEEP_WIDTH_RSLT-1:0]  int_s_axis_rslt_adapter_tkeep;
  wire                                      int_s_axis_rslt_adapter_tvalid;
  wire                                      int_s_axis_rslt_adapter_tready;
  wire                                      int_s_axis_rslt_adapter_tlast;
  wire [ID_WIDTH-1:0]                       int_s_axis_rslt_adapter_tid;
  wire [DEST_WIDTH-1:0]                     int_s_axis_rslt_adapter_tdest;
  wire [USER_WIDTH-1:0]                     int_s_axis_rslt_adapter_tuser;

  wire [DATA_WIDTH_DMA-1:0]   int_m_axis_rslt_adapter_tdata;
  wire [KEEP_WIDTH_DMA-1:0]   int_m_axis_rslt_adapter_tkeep;
  wire                        int_m_axis_rslt_adapter_tvalid;
  wire                        int_m_axis_rslt_adapter_tready;
  wire                        int_m_axis_rslt_adapter_tlast;
  wire [ID_WIDTH-1:0]         int_m_axis_rslt_adapter_tid;
  wire [DEST_WIDTH-1:0]       int_m_axis_rslt_adapter_tdest;
  wire [USER_WIDTH-1:0]       int_m_axis_rslt_adapter_tuser;


  axis_adapter #(
    .S_DATA_WIDTH(RSLT_CHANNELS*DATA_WIDTH_RSLT),
    .M_DATA_WIDTH(DATA_WIDTH_DMA),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),    // !!! Mismatch between this module and Axi Adapter values
    .USER_WIDTH(USER_WIDTH)
  ) axis_adapter_rslt_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(int_s_axis_rslt_adapter_tdata),
    .s_axis_tkeep(int_s_axis_rslt_adapter_tkeep),
    .s_axis_tvalid(int_s_axis_rslt_adapter_tvalid),
    .s_axis_tready(int_s_axis_rslt_adapter_tready),
    .s_axis_tlast(int_s_axis_rslt_adapter_tlast),
    .s_axis_tid(int_s_axis_rslt_adapter_tid),
    .s_axis_tdest(int_s_axis_rslt_adapter_tdest),
    .s_axis_tuser(int_s_axis_rslt_adapter_tuser),
    .m_axis_tdata(int_m_axis_rslt_adapter_tdata),
    .m_axis_tkeep(int_m_axis_rslt_adapter_tkeep),
    .m_axis_tvalid(int_m_axis_rslt_adapter_tvalid),
    .m_axis_tready(int_m_axis_rslt_adapter_tready),
    .m_axis_tlast(int_m_axis_rslt_adapter_tlast),
    .m_axis_tid(int_m_axis_rslt_adapter_tid),
    .m_axis_tdest(int_m_axis_rslt_adapter_tdest),
    .m_axis_tuser(int_m_axis_rslt_adapter_tuser)
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

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_s_axis_data_dp_tdata;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_data_dp_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_data_dp_tready;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_data_dp_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             int_s_axis_data_dp_tid;
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           int_s_axis_data_dp_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           int_s_axis_data_dp_tuser;

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      int_s_axis_grid_dp_tdata;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_grid_dp_tvalid;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_grid_dp_tready;
  wire [DATA_CHANNELS-1:0]                      int_s_axis_grid_dp_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             int_s_axis_grid_dp_tid;  
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           int_s_axis_grid_dp_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           int_s_axis_grid_dp_tuser;
                                                                  
  wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]    int_s_axis_scle_dp_tdata;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_s_axis_scle_dp_tvalid;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_s_axis_scle_dp_tready;
  wire [SCALE_CHANNELS_OUT-1:0]                     int_s_axis_scle_dp_tlast;
  wire [SCALE_CHANNELS_OUT*ID_WIDTH-1:0]            int_s_axis_scle_dp_tid; 
  wire [SCALE_CHANNELS_OUT*DEST_WIDTH-1:0]          int_s_axis_scle_dp_tdest;
  wire [SCALE_CHANNELS_OUT*USER_WIDTH-1:0]          int_s_axis_scle_dp_tuser;
                                                                  
  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0]  int_s_axis_wght_dp_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_wght_dp_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_wght_dp_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_wght_dp_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           int_s_axis_wght_dp_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         int_s_axis_wght_dp_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         int_s_axis_wght_dp_tuser;

  wire [RSLT_CHANNELS*DATA_WIDTH_RSLT-1:0]      int_m_axis_rslt_dp_tdata;
  wire [RSLT_CHANNELS-1:0]                      int_m_axis_rslt_dp_tvalid;
  wire [RSLT_CHANNELS-1:0]                      int_m_axis_rslt_dp_tready;
  wire [RSLT_CHANNELS-1:0]                      int_m_axis_rslt_dp_tlast;
  wire [RSLT_CHANNELS*ID_WIDTH-1:0]             int_m_axis_rslt_dp_tid;
  wire [RSLT_CHANNELS*DEST_WIDTH-1:0]           int_m_axis_rslt_dp_tdest;
  wire [RSLT_CHANNELS*USER_WIDTH-1:0]           int_m_axis_rslt_dp_tuser;

  ParallelizedDataProcessor #(
    .BATCH_SIZE(BATCH_SIZE),
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    .DATA_WIDTH_WEIGHT(DATA_WIDTH_WEIGHT),
    .FRACTIONAL_BITS_WEIGHT(FRACTIONAL_BITS_WEIGHT),
    .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
    .DATA_WIDTH_ACT(DATA_WIDTH_ACT),
    .FRACTIONAL_BITS_ACT(FRACTIONAL_BITS_ACT),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .ID_ENABLE(ID_ENABLE),
    .DEST_ENABLE(DEST_ENABLE),
    .USER_ENABLE(USER_ENABLE),
    .DATA_CHANNELS(DATA_CHANNELS),
    .RSLT_CHANNELS(RSLT_CHANNELS),
    .SHARE_SCALE(SHARE_SCALE),
    .ROM_DATA_PATH(ROM_DATA_PATH),
    .OUTPUT_DEST(OUTPUT_DEST),
    .OUTPUT_ID(OUTPUT_ID)
  ) data_processor_inst (
    .clk                  (clk),
    .rst                  (~aresetn),
    .s_axis_data_tdata    (int_s_axis_data_dp_tdata),
    .s_axis_data_tvalid   (int_s_axis_data_dp_tvalid),
    .s_axis_data_tready   (int_s_axis_data_dp_tready),
    .s_axis_data_tlast    (int_s_axis_data_dp_tlast),
    .s_axis_data_tid      (int_s_axis_data_dp_tid),
    .s_axis_data_tdest    (int_s_axis_data_dp_tdest),
    .s_axis_data_tuser    (int_s_axis_data_dp_tuser),
    .s_axis_grid_tdata    (int_s_axis_grid_dp_tdata),
    .s_axis_grid_tvalid   (int_s_axis_grid_dp_tvalid),
    .s_axis_grid_tready   (int_s_axis_grid_dp_tready),
    .s_axis_grid_tlast    (int_s_axis_grid_dp_tlast),
    .s_axis_grid_tid      (int_s_axis_grid_dp_tid),
    .s_axis_grid_tdest    (int_s_axis_grid_dp_tdest),
    .s_axis_grid_tuser    (int_s_axis_grid_dp_tuser),
    .s_axis_scle_tdata   (int_s_axis_scle_dp_tdata),
    .s_axis_scle_tvalid  (int_s_axis_scle_dp_tvalid),
    .s_axis_scle_tready  (int_s_axis_scle_dp_tready),
    .s_axis_scle_tlast   (int_s_axis_scle_dp_tlast),
    .s_axis_scle_tid     (int_s_axis_scle_dp_tid),
    .s_axis_scle_tdest   (int_s_axis_scle_dp_tdest),
    .s_axis_scle_tuser   (int_s_axis_scle_dp_tuser),
    .s_axis_wght_tdata  (int_s_axis_wght_dp_tdata),
    .s_axis_wght_tvalid (int_s_axis_wght_dp_tvalid),
    .s_axis_wght_tready (int_s_axis_wght_dp_tready),
    .s_axis_wght_tlast  (int_s_axis_wght_dp_tlast),
    .s_axis_wght_tid    (int_s_axis_wght_dp_tid),
    .s_axis_wght_tdest  (int_s_axis_wght_dp_tdest),
    .s_axis_wght_tuser  (int_s_axis_wght_dp_tuser),
    .m_axis_data_tdata    (int_m_axis_rslt_dp_tdata),
    .m_axis_data_tkeep    (int_m_axis_rslt_dp_tkeep),
    .m_axis_data_tvalid   (int_m_axis_rslt_dp_tvalid),
    .m_axis_data_tready   (int_m_axis_rslt_dp_tready),
    .m_axis_data_tlast    (int_m_axis_rslt_dp_tlast),
    .m_axis_data_tid      (int_m_axis_rslt_dp_tid),
    .m_axis_data_tdest    (int_m_axis_rslt_dp_tdest),
    .m_axis_data_tuser    (int_m_axis_rslt_dp_tuser),
    .err_unalligned_data  (err_unalligned_data),
    .core_rst             (core_rst)
  );

  /**********************************************
    AXI-Lite Control Registers
    of the whole Core
  **********************************************/

	AxiLiteControlRegisters #(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(4)
  ) axi_lite_control_registers_inst (
    .pl_flag_0(pl_flag_0),
    .pl_flag_1(pl_flag_1),
    .ps_flag_0(ps_flag_0),
    .ps_flag_1(ps_flag_1),
    .S_AXI_ACLK(fsm_clk),
    .S_AXI_ARESETN(aresetn),
    .S_AXI_AWADDR(s_axil_ctrl_awaddr),
    .S_AXI_AWPROT(s_axil_ctrl_awprot),
    .S_AXI_AWVALID(s_axil_ctrl_awvalid),
    .S_AXI_AWREADY(s_axil_ctrl_awready),
    .S_AXI_WDATA(s_axil_ctrl_wdata),
    .S_AXI_WSTRB(s_axil_ctrl_wstrb),
    .S_AXI_WVALID(s_axil_ctrl_wvalid),
    .S_AXI_WREADY(s_axil_ctrl_wready),
    .S_AXI_BRESP(s_axil_ctrl_bresp),
    .S_AXI_BVALID(s_axil_ctrl_bvalid),
    .S_AXI_BREADY(s_axil_ctrl_bready),
    .S_AXI_ARADDR(s_axil_ctrl_araddr),
    .S_AXI_ARPROT(s_axil_ctrl_arprot),
    .S_AXI_ARVALID(s_axil_ctrl_arvalid),
    .S_AXI_ARREADY(s_axil_ctrl_arready),
    .S_AXI_RDATA(s_axil_ctrl_rdata),
    .S_AXI_RRESP(s_axil_ctrl_rresp),
    .S_AXI_RVALID(s_axil_ctrl_rvalid),
    .S_AXI_RREADY(s_axil_ctrl_rready)
	);

  /*************************************************************************************
   Internal Sinals Connections and Direct Assignments
  *************************************************************************************/

  // bram control interface to the data bram translator

  assign int_data_bram_ctrl_en_i = bram_data_ctrl_en;
  assign int_data_bram_ctrl_we_i = bram_data_ctrl_we;
  assign int_data_bram_ctrl_addr_i = bram_data_ctrl_addr[2 +: DATA_ITRL_ADDR];
  assign int_data_bram_ctrl_wrdata_i = bram_data_ctrl_din;
  assign bram_data_ctrl_dout = int_data_bram_ctrl_rddata_i;

  // data bram translator to data bram port a

  assign int_data_bram_clk_a = bram_data_ctrl_clk;
  assign int_data_bram_en_a = int_data_bram_ctrl_en_o;
  assign int_data_bram_we_a = int_data_bram_ctrl_we_o;
  assign int_data_bram_addr_a = int_data_bram_ctrl_addr_o;
  assign int_data_bram_wrdata_a = int_data_bram_ctrl_wrdata_o;
  assign int_data_bram_ctrl_rddata_o = int_data_bram_rddata_a;

  // data bram port b to memory control unit

  assign int_data_bram_en_b = int_data_mcu_en;
  assign int_data_bram_addr_b = int_data_mcu_addr;
  assign int_data_mcu_rddata = int_data_bram_rddata_b;
  assign int_data_mcu_rdstrobe = int_data_bram_rdstrobe_b;

  // connect dma slave to slave axi adapter

  assign int_s_axis_wght_adapter_tdata = s_axis_wght_tdata;
  assign int_s_axis_wght_adapter_tkeep = s_axis_wght_tkeep;
  assign int_s_axis_wght_adapter_tvalid = s_axis_wght_tvalid;
  assign s_axis_wght_tready = int_s_axis_wght_adapter_tready;
  assign int_s_axis_wght_adapter_tlast = s_axis_wght_tlast;
  assign int_s_axis_wght_adapter_tid = s_axis_wght_tid;
  assign int_s_axis_wght_adapter_tdest = s_axis_wght_tdest;
  assign int_s_axis_wght_adapter_tuser = s_axis_wght_tuser;

  // connect slave axi adapter to axi splitter of the wght streams

  assign int_s_axis_wght_splitter_tdata = int_m_axis_wght_adapter_tdata;
  assign int_s_axis_wght_splitter_tkeep = int_m_axis_wght_adapter_tkeep;
  assign int_s_axis_wght_splitter_tvalid = int_m_axis_wght_adapter_tvalid;
  assign int_m_axis_wght_adapter_tready = int_s_axis_wght_splitter_tready;
  assign int_s_axis_wght_splitter_tlast = int_m_axis_wght_adapter_tlast;
  assign int_s_axis_wght_splitter_tid = int_m_axis_wght_adapter_tid;
  assign int_s_axis_wght_splitter_tdest = int_m_axis_wght_adapter_tdest;
  assign int_s_axis_wght_splitter_tuser = int_m_axis_wght_adapter_tuser;

  // Connect the data axis from mcu to data processor

  assign int_s_axis_data_dp_tdata = int_m_axis_data_mcu_tdata;
  assign int_s_axis_data_dp_tvalid = int_m_axis_data_mcu_tvalid;
  assign int_m_axis_data_mcu_tready = int_s_axis_data_dp_tready;
  assign int_s_axis_data_dp_tlast = int_m_axis_data_mcu_tlast;
  assign int_s_axis_data_dp_tid = int_m_axis_data_mcu_tid;
  assign int_s_axis_data_dp_tdest = int_m_axis_data_mcu_tdest;
  assign int_s_axis_data_dp_tuser = int_m_axis_data_mcu_tuser;

  // Connect the grid axis from mcu to data processor

  assign int_s_axis_grid_dp_tdata = int_m_axis_grid_mcu_tdata;
  assign int_s_axis_grid_dp_tvalid = int_m_axis_grid_mcu_tvalid;
  assign int_m_axis_grid_mcu_tready = int_s_axis_grid_dp_tready;
  assign int_s_axis_grid_dp_tlast = int_m_axis_grid_mcu_tlast;
  assign int_s_axis_grid_dp_tid  = int_m_axis_grid_mcu_tid;
  assign int_s_axis_grid_dp_tdest = int_m_axis_grid_mcu_tdest;
  assign int_s_axis_grid_dp_tuser = int_m_axis_grid_mcu_tuser;

  // Connect the scle axis from mcu to data processor

  assign int_s_axis_scle_dp_tdata = int_m_axis_scle_mcu_tdata;
  assign int_s_axis_scle_dp_tvalid = int_m_axis_scle_mcu_tvalid;
  assign int_m_axis_scle_mcu_tready = int_s_axis_scle_dp_tready;
  assign int_s_axis_scle_dp_tlast = int_m_axis_scle_mcu_tlast;
  assign int_s_axis_scle_dp_tid = int_m_axis_scle_mcu_tid; 
  assign int_s_axis_scle_dp_tdest = int_m_axis_scle_mcu_tdest;
  assign int_s_axis_scle_dp_tuser = int_m_axis_scle_mcu_tuser;
                                                                  
  // connect axi splitter wght streams to data processor

  assign int_s_axis_wght_dp_tdata = int_m_axis_wght_splitter_tdata;
  assign int_s_axis_wght_dp_tvalid = int_m_axis_wght_splitter_tvalid;
  assign int_m_axis_wght_splitter_tready = int_s_axis_wght_dp_tready;
  assign int_s_axis_wght_dp_tlast = int_m_axis_wght_splitter_tlast;
  assign int_s_axis_wght_dp_tid = int_m_axis_wght_splitter_tid;
  assign int_s_axis_wght_dp_tdest = int_m_axis_wght_splitter_tdest;
  assign int_s_axis_wght_dp_tuser = int_m_axis_wght_splitter_tuser;

  // connect the rslt streams from data procesor to axi joiner

  assign int_s_axis_rslt_joiner_tdata = int_m_axis_rslt_dp_tdata;
  assign int_s_axis_rslt_joiner_tvalid = int_m_axis_rslt_dp_tvalid;
  assign int_m_axis_rslt_dp_tready = int_s_axis_rslt_joiner_tready;
  assign int_s_axis_rslt_joiner_tlast = int_m_axis_rslt_dp_tlast;
  assign int_s_axis_rslt_joiner_tid = int_m_axis_rslt_dp_tid;
  assign int_s_axis_rslt_joiner_tdest = int_m_axis_rslt_dp_tdest;
  assign int_s_axis_rslt_joiner_tuser = int_m_axis_rslt_dp_tuser;

  // connect axi joiner of result streams to axi master adapter

  assign int_s_axis_rslt_adapter_tdata = int_m_axis_rslt_joiner_tdata;
  assign int_s_axis_rslt_adapter_tkeep = int_m_axis_rslt_joiner_tkeep;
  assign int_s_axis_rslt_adapter_tvalid = int_m_axis_rslt_joiner_tvalid;
  assign int_m_axis_rslt_joiner_tready = int_s_axis_rslt_adapter_tready;
  assign int_s_axis_rslt_adapter_tlast = int_m_axis_rslt_joiner_tlast;
  assign int_s_axis_rslt_adapter_tid = int_m_axis_rslt_joiner_tid;
  assign int_s_axis_rslt_adapter_tdest = int_m_axis_rslt_joiner_tdest;
  assign int_s_axis_rslt_adapter_tuser = int_m_axis_rslt_joiner_tuser;

  // connect axi master adapter to external master axi interface

  assign m_axis_rslt_tdata = int_m_axis_rslt_adapter_tdata;
  assign m_axis_rslt_tkeep = int_m_axis_rslt_adapter_tkeep;
  assign m_axis_rslt_tvalid = int_m_axis_rslt_adapter_tvalid;
  assign int_m_axis_rslt_adapter_tready = m_axis_rslt_tready;
  assign m_axis_rslt_tlast = int_m_axis_rslt_adapter_tlast;
  assign m_axis_rslt_tid = int_m_axis_rslt_adapter_tid;
  assign m_axis_rslt_tdest = int_m_axis_rslt_adapter_tdest;
  assign m_axis_rslt_tuser = int_m_axis_rslt_adapter_tuser;

  // connect internal control signals !!!

endmodule
