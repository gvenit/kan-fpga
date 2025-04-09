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
  
  parameter BATCH_SIZE = 1,

  /*------------------------------------------------------------------
    DMA parameters
  ------------------------------------------------------------------*/
  
  // Width of DMA streams
  parameter DATA_WIDTH_DMA = 64,
  // Propagate tkeep signal
  parameter KEEP_ENABLE_DMA = (DATA_WIDTH_DMA>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_DMA = ((DATA_WIDTH_DMA+7)/8),

  /*------------------------------------------------------------------
    Bram controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter BRAM_CTR_WIDTH = 32,
  parameter BRAM_CTR_WE = 4,
  parameter BRAM_CTR_ADDR = 13,

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

  /*------------------------------------------------------------------
    SCALE streams parameters
  ------------------------------------------------------------------*/

  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scale
  parameter FRACTIONAL_BITS_SCALE= 12,
  // Use Common Share Channel 
  parameter SHARE_SCALE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS * BATCH_SIZE,

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
  parameter KEEP_WIDTH_RSLT = ((DATA_WIDTH_RSLT+7)/8),

  /*------------------------------------------------------------------
    WEIGHT streams parameters
  ------------------------------------------------------------------*/

  // Width of input weight word
  parameter DATA_WIDTH_WEIGHT = 16,
  // Fractional bits of weight data
  parameter FRACTIONAL_BITS_WEIGHT = 12,
  // Number of Independent AXI-Stream Weight Channels
  parameter WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS,
  // Propagate tkeep signal
  parameter KEEP_ENABLE_WEIGHT = (DATA_WIDTH_WEIGHT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_WEIGHT = ((DATA_WIDTH_WEIGHT+7)/8),

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

  input  wire         clk,
  input  wire         aresetn,

  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/

  // Uncomment the following to set interface specific parameter on the bus interface.
  // (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC <value>,MEM_WIDTH <value>,MEM_SIZE <value>,READ_WRITE_MODE <value>" *)

  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr CLK" *)
  input  wire                      bram_data_ctr_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr RST" *)
  input  wire                      bram_data_ctr_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                      bram_data_ctr_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr WE" *)
  input  wire [BRAM_CTR_WE-1:0]    bram_data_ctr_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr ADDR" *)
  input  wire [BRAM_CTR_ADDR-1:0]  bram_data_ctr_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr DIN" *)
  input  wire [BRAM_CTR_WIDTH-1:0] bram_data_ctr_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_data_ctr DOUT" *)
  output wire [BRAM_CTR_WIDTH-1:0] bram_data_ctr_dout,

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr CLK" *)
  input  wire                      bram_grid_ctr_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr RST" *)
  input  wire                      bram_grid_ctr_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                      bram_grid_ctr_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr WE" *)
  input  wire [BRAM_CTR_WE-1:0]    bram_grid_ctr_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr ADDR" *)
  input  wire [BRAM_CTR_ADDR-1:0]  bram_grid_ctr_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr DIN" *)
  input  wire [BRAM_CTR_WIDTH-1:0] bram_grid_ctr_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_grid_ctr DOUT" *)
  output wire [BRAM_CTR_WIDTH-1:0] bram_grid_ctr_dout,

  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  input  wire [11:0]  s_axi_ctr_awaddr,
  input  wire [2:0]   s_axi_ctr_awprot,
  input  wire         s_axi_ctr_awvalid,
  output wire         s_axi_ctr_awready,
  input  wire [31:0]  s_axi_ctr_wdata,
  input  wire [3:0]   s_axi_ctr_wstrb,
  input  wire         s_axi_ctr_wvalid,
  output wire         s_axi_ctr_wready,
  output wire [1:0]   s_axi_ctr_bresp,
  output wire         s_axi_ctr_bvalid,
  input  wire         s_axi_ctr_bready,
  input  wire [11:0]  s_axi_ctr_araddr,
  input  wire [2:0]   s_axi_ctr_arprot,
  input  wire         s_axi_ctr_arvalid,
  output wire         s_axi_ctr_arready,
  output wire [31:0]  s_axi_ctr_rdata,
  output wire [1:0]   s_axi_ctr_rresp,
  output wire         s_axi_ctr_rvalid,
  input  wire         s_axi_ctr_rready,

  /*------------------------------------------------------------------
      AXI-Lite Scale Register Slave interface
  ------------------------------------------------------------------*/

  input  wire [11:0]  s_axi_scale_awaddr,
  input  wire [2:0]   s_axi_scale_awprot,
  input  wire         s_axi_scale_awvalid,
  output wire         s_axi_scale_awready,
  input  wire [31:0]  s_axi_scale_wdata,
  input  wire [3:0]   s_axi_scale_wstrb,
  input  wire         s_axi_scale_wvalid,
  output wire         s_axi_scale_wready,
  output wire [1:0]   s_axi_scale_bresp,
  output wire         s_axi_scale_bvalid,
  input  wire         s_axi_scale_bready,
  input  wire [11:0]  s_axi_scale_araddr,
  input  wire [2:0]   s_axi_scale_arprot,
  input  wire         s_axi_scale_arvalid,
  output wire         s_axi_scale_arready,
  output wire [31:0]  s_axi_scale_rdata,
  output wire [1:0]   s_axi_scale_rresp,
  output wire         s_axi_scale_rvalid,
  input  wire         s_axi_scale_rready,

  /*------------------------------------------------------------------
      AXI-Stream Weight Slave interface
  ------------------------------------------------------------------*/
  
  input  wire [DATA_WIDTH_DMA-1:0]  s_axis_weight_tdata,
  input  wire [KEEP_WIDTH_DMA-1:0]  s_axis_weight_tkeep,
  input  wire                       s_axis_weight_tvalid,  
  output wire                       s_axis_weight_tready,
  input  wire                       s_axis_weight_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_weight_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_weight_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_weight_tuser,

  /*------------------------------------------------------------------
      AXI-Stream Results / Output Master interface
  ------------------------------------------------------------------*/

  output  wire [DATA_WIDTH_DMA-1:0] m_axis_rslt_tdata,
  output  wire [KEEP_WIDTH_DMA-1:0] m_axis_rslt_tkeep,
  output  wire                      m_axis_rslt_tvalid,  
  input wire                        m_axis_rslt_tready,
  output  wire                      m_axis_rslt_tlast,
  output  wire [ID_WIDTH-1:0]       m_axis_rslt_tid,
  output  wire [DEST_WIDTH-1:0]     m_axis_rslt_tdest,
  output  wire [USER_WIDTH-1:0]     m_axis_rslt_tuser

  );

  /*************************************************************************************
   Local Paramters
  *************************************************************************************/

  localparam IN_WORD_DATA = BRAM_CTR_WIDTH / DATA_WIDTH_DATA;

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_EXTRL_DEPTH = GRID_DEPTH / IN_WORD_DATA;  // grid depth as seen from external ram control interface
  localparam GRID_EXTRL_ADDR = `LOG2(GRID_EXTRL_DEPTH);     // number of bits needed for the addressing of the grid ram from the external ram controlm interface

  localparam GRID_ADDR = `LOG2(GRID_DEPTH);  // number of input address bits of total grid memory
  localparam GRID_PHYS_DEPTH = GRID_DEPTH / IN_WORD_DATA;  // effective - physical depth of grid ram
  localparam GRID_PHYS_ADDR = `LOG2(GRID_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram

  /*************************************************************************************
   Internal Signals
  *************************************************************************************/

  // control flags that connecy to axi-lite mm interface

  wire pl_flag_0, pl_flag_1;  // single bit flags for output from the PL and input to the PS
  wire ps_flag_0, ps_flag_1;  // single bit flags for input to the PS and output from the PS

  wire err_unalligned_data;   // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later
  wire err_user_flag;         // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later

  wire core_rst; // Interrupt outputs. WARNING: Might be grouped into AXI-Lite MM interfaces later

  /*************************************************************************************
   Module instantiations with their local signals
  *************************************************************************************/

  /**********************************************
    Interface Translator between BRAM Controller
    and Data BRAM

    Naming conventions
    - int_ : internal signal
    - _ctr_ : indicates a translator module
    - _i : input / slave interface
    - _o : output / master interface
  *********************************************/

  wire                                    int_data_bram_ctr_en_i;
  wire [BRAM_CTR_WE-1:0]                  int_data_bram_ctr_we_i;
  wire [DATA_ITRL_ADDR-1:0]               int_data_bram_ctr_addr_i;
  wire [BRAM_CTR_WIDTH-1:0]               int_data_bram_ctr_wrdata_i;
  wire [BRAM_CTR_WIDTH-1:0]               int_data_bram_ctr_rddata_i;
  
  wire [DATA_BANKS-1:0]                   int_data_bram_ctr_en_o;
  wire [(DATA_BANKS*DATA_WE)-1:0]         int_data_bram_ctr_we_o;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_data_bram_ctr_addr_o;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_ctr_wrdata_o;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_data_bram_ctr_rddata_o;

  BramIntrfTranslator #(
    .IN_WIDTH(BRAM_CTR_WIDTH),
    .OUT_WIDTH(DATA_WIDTH_DATA),
    .BANKS(DATA_BANKS),
    .OUT_DEPTH(DATA_BANK_DEPTH)
  ) data_bram_interface_translator_inst (
    .en_i(int_data_bram_ctr_en_i),
    .we_i(int_data_bram_ctr_we_i),
    .addr_i(int_data_bram_ctr_addr_i),
    .wrdata_i(int_data_bram_ctr_wrdata_i),
    .rddata_i(int_data_bram_ctr_rddata_i),
    .en_o(int_data_bram_ctr_en_o),
    .we_o(int_data_bram_ctr_we_o),
    .addr_o(int_data_bram_ctr_addr_o),
    .wrdata_o(int_data_bram_ctr_wrdata_o),
    .rddata_o(int_data_bram_ctr_rddata_o)
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
    .clk(int_data_bram_clk_a),
    .ena(int_data_bram_en_a),
    .wea(int_data_bram_we_a),
    .addra(int_data_bram_addr_a),
    .dina(int_data_bram_wrdata_a),
    .douta(int_data_bram_rddata_a),
    .enb(int_data_bram_en_b),
    .addrb(int_data_bram_addr_b),
    .doutb(int_data_bram_rddata_b),
    .validb(int_data_bram_rdstrobe_b)
  );

  /**********************************************
    Grid BRAM

    Naming conventions
    - int_ : internal signal
    - _a : port a (control port)
    - _b : port b (internal use)
  *********************************************/

  wire                                    int_grid_bram_clk_a;
  wire                                    int_grid_bram_en_a;
  wire [BRAM_CTR_WE-1:0]                  int_grid_bram_we_a;
  wire [GRID_EXTRL_ADDR-1:0]              int_grid_bram_addr_a;
  wire [BRAM_CTR_WIDTH-1:0]               int_grid_bram_wrdata_a;
  wire [BRAM_CTR_WIDTH-1:0]               int_grid_bram_rddata_a;

  wire [DATA_BANKS-1:0]                   int_grid_bram_en_b;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       int_grid_bram_addr_b;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] int_grid_bram_rddata_b;
  wire [DATA_BANKS-1:0]                   int_grid_bram_rdstrobe_b;

  MultiWidthDualPortBram #(
    .PORT_B_WIDTH(DATA_WIDTH_DATA),
    .PORT_B_DEPTH(GRID_DEPTH),
    .PORT_A_WIDTH(BRAM_CTR_WIDTH)
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

  wire [DATA_WIDTH_SCALE-1:0] int_axil_scale_reg;

	AxiLiteScaleRegister  #(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(4),
    .SCALE_WIDTH(DATA_WIDTH_SCALE)
  ) axi_lite_scale_register_inst (
    .scale_reg(int_axil_scale_reg),
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(aresetn),
    .S_AXI_AWADDR(s_axi_scale_awaddr),
    .S_AXI_AWPROT(s_axi_scale_awprot),
    .S_AXI_AWVALID(s_axi_scale_awvalid),
    .S_AXI_AWREADY(s_axi_scale_awready),
    .S_AXI_WDATA(s_axi_scale_wdata),
    .S_AXI_WSTRB(s_axi_scale_wstrb),
    .S_AXI_WVALID(s_axi_scale_wvalid),
    .S_AXI_WREADY(s_axi_scale_wready),
    .S_AXI_BRESP(s_axi_scale_bresp),
    .S_AXI_BVALID(s_axi_scale_bvalid),
    .S_AXI_BREADY(s_axi_scale_bready),
    .S_AXI_ARADDR(s_axi_scale_araddr),
    .S_AXI_ARPROT(s_axi_scale_arprot),
    .S_AXI_ARVALID(s_axi_scale_arvalid),
    .S_AXI_ARREADY(s_axi_scale_arready),
    .S_AXI_RDATA(s_axi_scale_rdata),
    .S_AXI_RRESP(s_axi_scale_rresp),
    .S_AXI_RVALID(s_axi_scale_rvalid),
    .S_AXI_RREADY(s_axi_scale_rready)
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

  wire [DATA_WIDTH_SCALE-1:0] int_axil_scale_mcu;

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
                                                                  
  wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]    int_m_axis_scale_mcu_tdata;
  wire [SCALE_CHANNELS-1:0]                     int_m_axis_scale_mcu_tvalid;
  wire [SCALE_CHANNELS-1:0]                     int_m_axis_scale_mcu_tready;
  wire [SCALE_CHANNELS-1:0]                     int_m_axis_scale_mcu_tlast;
  wire [SCALE_CHANNELS*ID_WIDTH-1:0]            int_m_axis_scale_mcu_tid; 
  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]          int_m_axis_scale_mcu_tdest;
  wire [SCALE_CHANNELS*USER_WIDTH-1:0]          int_m_axis_scale_mcu_tuser;
                                                                  

  MemoryUnit #(
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_CHANNELS(DATA_CHANNELS),
    .DATA_BANKS(DATA_BANKS),
    .DATA_BANK_DEPTH(DATA_BANK_DEPTH),
    .GRID_DEPTH(GRID_DEPTH),
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    .SHARE_SCALE(SHARE_SCALE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) memory_controler_unit_inst (
    .mb_bram_data_en(int_data_mcu_en),
    .mb_bram_data_addr(int_data_mcu_addr),
    .mb_bram_data_rddata(int_data_mcu_rddata),
    .mb_bram_data_rdstrobe(int_data_mcu_rdstrobe),
    .bram_grid_en(int_grid_mcu_en),
    .bram_grid_addr(int_grid_mcu_addr),
    .bram_grid_rddata(int_grid_mcu_rddata),
    .bram_grid_rdstrobe(int_grid_mcu_rdstrobe),
    .scale_reg(int_axil_scale_mcu),
    .axis_data_tdata(int_m_axis_data_mcu_tdata),
    .axis_data_tvalid(int_m_axis_data_mcu_tvalid),
    .axis_data_tready(int_m_axis_data_mcu_tready),
    .axis_data_tlast(int_m_axis_data_mcu_tlast),
    .axis_data_tid(int_m_axis_data_mcu_tid),
    .axis_data_tdest(int_m_axis_data_mcu_tdest),
    .axis_data_tuser(int_m_axis_data_mcu_tuser),
    .axis_grid_tdata(int_m_axis_grid_mcu_tdata),
    .axis_grid_tvalid(int_m_axis_grid_mcu_tvalid),
    .axis_grid_tready(int_m_axis_grid_mcu_tready),
    .axis_grid_tlast(int_m_axis_grid_mcu_tlast),
    .axis_grid_tid(int_m_axis_grid_mcu_tid),  
    .axis_grid_tdest(int_m_axis_grid_mcu_tdest),
    .axis_grid_tuser(int_m_axis_grid_mcu_tuser),
    .axis_scale_tdata(int_m_axis_scale_mcu_tdata),
    .axis_scale_tvalid(int_m_axis_scale_mcu_tvalid),
    .axis_scale_tready(int_m_axis_scale_mcu_tready),
    .axis_scale_tlast(int_m_axis_scale_mcu_tlast),
    .axis_scale_tid(int_m_axis_scale_mcu_tid), 
    .axis_scale_tdest(int_m_axis_scale_mcu_tdest),
    .axis_scale_tuser(int_m_axis_scale_mcu_tuser)
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

  wire [DATA_WIDTH_DMA-1:0]   int_s_axis_weight_adapter_tdata;
  wire [KEEP_WIDTH_DMA-1:0]   int_s_axis_weight_adapter_tkeep;
  wire                        int_s_axis_weight_adapter_tvalid;
  wire                        int_s_axis_weight_adapter_tready;
  wire                        int_s_axis_weight_adapter_tlast;
  wire [ID_WIDTH-1:0]         int_s_axis_weight_adapter_tid;
  wire [DEST_WIDTH-1:0]       int_s_axis_weight_adapter_tdest;
  wire [USER_WIDTH-1:0]       int_s_axis_weight_adapter_tuser;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_m_axis_weight_adapter_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] int_m_axis_weight_adapter_tkeep;
  wire                                         int_m_axis_weight_adapter_tvalid;
  wire                                         int_m_axis_weight_adapter_tready;
  wire                                         int_m_axis_weight_adapter_tlast;
  wire [ID_WIDTH-1:0]                          int_m_axis_weight_adapter_tid;
  wire [DEST_WIDTH-1:0]                        int_m_axis_weight_adapter_tdest;
  wire [USER_WIDTH-1:0]                        int_m_axis_weight_adapter_tuser;

  axis_adapter #(
    .S_DATA_WIDTH(DATA_WIDTH_DMA),
    .M_DATA_WIDTH(WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),    // !!! Mismatch between this module and Axi Adapter values
    .USER_WIDTH(USER_WIDTH)
  ) axis_adapter_weight_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(int_s_axis_weight_adapter_tdata),
    .s_axis_tkeep(int_s_axis_weight_adapter_tkeep),
    .s_axis_tvalid(int_s_axis_weight_adapter_tvalid),
    .s_axis_tready(int_s_axis_weight_adapter_tready),
    .s_axis_tlast(int_s_axis_weight_adapter_tlast),
    .s_axis_tid(int_s_axis_weight_adapter_tid),
    .s_axis_tdest(int_s_axis_weight_adapter_tdest),
    .s_axis_tuser(int_s_axis_weight_adapter_tuser),
    .m_axis_tdata(int_m_axis_weight_adapter_tdata),
    .m_axis_tkeep(int_m_axis_weight_adapter_tkeep),
    .m_axis_tvalid(int_m_axis_weight_adapter_tvalid),
    .m_axis_tready(int_m_axis_weight_adapter_tready),
    .m_axis_tlast(int_m_axis_weight_adapter_tlast),
    .m_axis_tid(int_m_axis_weight_adapter_tid),
    .m_axis_tdest(int_m_axis_weight_adapter_tdest),
    .m_axis_tuser(int_m_axis_weight_adapter_tuser)
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

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_s_axis_weight_splitter_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] int_s_axis_weight_splitter_tkeep;
  wire                                         int_s_axis_weight_splitter_tvalid;
  wire                                         int_s_axis_weight_splitter_tready;
  wire                                         int_s_axis_weight_splitter_tlast;
  wire [ID_WIDTH-1:0]                          int_s_axis_weight_splitter_tid;
  wire [DEST_WIDTH-1:0]                        int_s_axis_weight_splitter_tdest;
  wire [USER_WIDTH-1:0]                        int_s_axis_weight_splitter_tuser;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] int_m_axis_weight_splitter_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_weight_splitter_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_weight_splitter_tready;
  wire [WEIGHT_CHANNELS-1:0]                   int_m_axis_weight_splitter_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]          int_m_axis_weight_splitter_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]        int_m_axis_weight_splitter_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]        int_m_axis_weight_splitter_tuser;

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
  ) axis_splitter_weights_inst (
    .clk              (clk),
    .rst              (~aresetn),
    .s_axis_tdata     (int_s_axis_weight_splitter_tdata),
    .s_axis_tkeep     (int_s_axis_weight_splitter_tkeep),
    .s_axis_tvalid    (int_s_axis_weight_splitter_tvalid),
    .s_axis_tready    (int_s_axis_weight_splitter_tready),
    .s_axis_tlast     (int_s_axis_weight_splitter_tlast),
    .s_axis_tid       (int_s_axis_weight_splitter_tid),
    .s_axis_tdest     (int_s_axis_weight_splitter_tdest),
    .s_axis_tuser     (int_s_axis_weight_splitter_tuser),
    .m_axis_tdata     (int_m_axis_weight_splitter_tdata),
    .m_axis_tvalid    (int_m_axis_weight_splitter_tvalid),
    .m_axis_tready    (int_m_axis_weight_splitter_tready),
    .m_axis_tlast     (int_m_axis_weight_splitter_tlast),
    .m_axis_tid       (int_m_axis_weight_splitter_tid),
    .m_axis_tdest     (int_m_axis_weight_splitter_tdest),
    .m_axis_tuser     (int_m_axis_weight_splitter_tuser)
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
                                                                  
  wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]    int_s_axis_scale_dp_tdata;
  wire [SCALE_CHANNELS-1:0]                     int_s_axis_scale_dp_tvalid;
  wire [SCALE_CHANNELS-1:0]                     int_s_axis_scale_dp_tready;
  wire [SCALE_CHANNELS-1:0]                     int_s_axis_scale_dp_tlast;
  wire [SCALE_CHANNELS*ID_WIDTH-1:0]            int_s_axis_scale_dp_tid; 
  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]          int_s_axis_scale_dp_tdest;
  wire [SCALE_CHANNELS*USER_WIDTH-1:0]          int_s_axis_scale_dp_tuser;
                                                                  
  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0]  int_s_axis_weight_dp_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_weight_dp_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_weight_dp_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_s_axis_weight_dp_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           int_s_axis_weight_dp_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         int_s_axis_weight_dp_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         int_s_axis_weight_dp_tuser;

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
    .s_axis_scale_tdata   (int_s_axis_scale_dp_tdata),
    .s_axis_scale_tvalid  (int_s_axis_scale_dp_tvalid),
    .s_axis_scale_tready  (int_s_axis_scale_dp_tready),
    .s_axis_scale_tlast   (int_s_axis_scale_dp_tlast),
    .s_axis_scale_tid     (int_s_axis_scale_dp_tid),
    .s_axis_scale_tdest   (int_s_axis_scale_dp_tdest),
    .s_axis_scale_tuser   (int_s_axis_scale_dp_tuser),
    .s_axis_weight_tdata  (int_s_axis_weight_dp_tdata),
    .s_axis_weight_tvalid (int_s_axis_weight_dp_tvalid),
    .s_axis_weight_tready (int_s_axis_weight_dp_tready),
    .s_axis_weight_tlast  (int_s_axis_weight_dp_tlast),
    .s_axis_weight_tid    (int_s_axis_weight_dp_tid),
    .s_axis_weight_tdest  (int_s_axis_weight_dp_tdest),
    .s_axis_weight_tuser  (int_s_axis_weight_dp_tuser),
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
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(aresetn),
    .S_AXI_AWADDR(s_axi_ctr_awaddr),
    .S_AXI_AWPROT(s_axi_ctr_awprot),
    .S_AXI_AWVALID(s_axi_ctr_awvalid),
    .S_AXI_AWREADY(s_axi_ctr_awready),
    .S_AXI_WDATA(s_axi_ctr_wdata),
    .S_AXI_WSTRB(s_axi_ctr_wstrb),
    .S_AXI_WVALID(s_axi_ctr_wvalid),
    .S_AXI_WREADY(s_axi_ctr_wready),
    .S_AXI_BRESP(s_axi_ctr_bresp),
    .S_AXI_BVALID(s_axi_ctr_bvalid),
    .S_AXI_BREADY(s_axi_ctr_bready),
    .S_AXI_ARADDR(s_axi_ctr_araddr),
    .S_AXI_ARPROT(s_axi_ctr_arprot),
    .S_AXI_ARVALID(s_axi_ctr_arvalid),
    .S_AXI_ARREADY(s_axi_ctr_arready),
    .S_AXI_RDATA(s_axi_ctr_rdata),
    .S_AXI_RRESP(s_axi_ctr_rresp),
    .S_AXI_RVALID(s_axi_ctr_rvalid),
    .S_AXI_RREADY(s_axi_ctr_rready)
	);

  /*************************************************************************************
   Internal Sinals Connections and Direct Assignments
  *************************************************************************************/

  // bram control interface to the data bram translator

  assign int_data_bram_ctr_en_i = bram_data_ctr_en;
  assign int_data_bram_ctr_we_i = bram_data_ctr_we;
  assign int_data_bram_ctr_addr_i = bram_data_ctr_addr[2 +: DATA_ITRL_ADDR];
  assign int_data_bram_ctr_wrdata_i = bram_data_ctr_din;
  assign bram_data_ctr_dout = int_data_bram_ctr_rddata_i;

  // data bram translator to data bram port a

  assign int_data_bram_clk_a = bram_data_ctr_clk;
  assign int_data_bram_en_a = int_data_bram_ctr_en_o;
  assign int_data_bram_we_a = int_data_bram_ctr_we_o;
  assign int_data_bram_addr_a = int_data_bram_ctr_addr_o;
  assign int_data_bram_wrdata_a = int_data_bram_ctr_wrdata_o;
  assign int_data_bram_ctr_rddata_o = int_data_bram_rddata_a;

  // bram control interface to the grid bram port a

  assign int_grid_bram_clk_a = bram_grid_ctr_clk;
  assign int_grid_bram_en_a = bram_grid_ctr_en;
  assign int_grid_bram_we_a = bram_grid_ctr_we;
  assign int_grid_bram_addr_a = bram_grid_ctr_addr[2 +: GRID_EXTRL_ADDR];
  assign int_grid_bram_wrdata_a = bram_grid_ctr_din;
  assign bram_grid_ctr_dout = int_grid_bram_rddata_a;

  // data bram port b to memory control unit

  assign int_data_bram_en_b = int_data_mcu_en;
  assign int_data_bram_addr_b = int_data_mcu_addr;
  assign int_data_mcu_rddata = int_data_bram_rddata_b;
  assign int_data_mcu_rdstrobe = int_data_bram_rdstrobe_b;

  // connect dma slave to slave axi adapter

  assign int_s_axis_weight_adapter_tdata = s_axis_weight_tdata;
  assign int_s_axis_weight_adapter_tkeep = s_axis_weight_tkeep;
  assign int_s_axis_weight_adapter_tvalid = s_axis_weight_tvalid;
  assign s_axis_weight_tready = int_s_axis_weight_adapter_tready;
  assign int_s_axis_weight_adapter_tlast = s_axis_weight_tlast;
  assign int_s_axis_weight_adapter_tid = s_axis_weight_tid;
  assign int_s_axis_weight_adapter_tdest = s_axis_weight_tdest;
  assign int_s_axis_weight_adapter_tuser = s_axis_weight_tuser;

  // connect slave axi adapter to axi splitter of the weight streams

  assign int_s_axis_weight_splitter_tdata = int_m_axis_weight_adapter_tdata;
  assign int_s_axis_weight_splitter_tkeep = int_m_axis_weight_adapter_tkeep;
  assign int_s_axis_weight_splitter_tvalid = int_m_axis_weight_adapter_tvalid;
  assign int_m_axis_weight_adapter_tready = int_s_axis_weight_splitter_tready;
  assign int_s_axis_weight_splitter_tlast = int_m_axis_weight_adapter_tlast;
  assign int_s_axis_weight_splitter_tid = int_m_axis_weight_adapter_tid;
  assign int_s_axis_weight_splitter_tdest = int_m_axis_weight_adapter_tdest;
  assign int_s_axis_weight_splitter_tuser = int_m_axis_weight_adapter_tuser;

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

  // Connect the scale axis from mcu to data processor

  assign int_s_axis_scale_dp_tdata = int_m_axis_scale_mcu_tdata;
  assign int_s_axis_scale_dp_tvalid = int_m_axis_scale_mcu_tvalid;
  assign int_m_axis_scale_mcu_tready = int_s_axis_scale_dp_tready;
  assign int_s_axis_scale_dp_tlast = int_m_axis_scale_mcu_tlast;
  assign int_s_axis_scale_dp_tid = int_m_axis_scale_mcu_tid; 
  assign int_s_axis_scale_dp_tdest = int_m_axis_scale_mcu_tdest;
  assign int_s_axis_scale_dp_tuser = int_m_axis_scale_mcu_tuser;
                                                                  
  // connect axi splitter weight streams to data processor

  assign int_s_axis_weight_dp_tdata = int_m_axis_weight_splitter_tdata;
  assign int_s_axis_weight_dp_tvalid = int_m_axis_weight_splitter_tvalid;
  assign int_m_axis_weight_splitter_tready = int_s_axis_weight_dp_tready;
  assign int_s_axis_weight_dp_tlast = int_m_axis_weight_splitter_tlast;
  assign int_s_axis_weight_dp_tid = int_m_axis_weight_splitter_tid;
  assign int_s_axis_weight_dp_tdest = int_m_axis_weight_splitter_tdest;
  assign int_s_axis_weight_dp_tuser = int_m_axis_weight_splitter_tuser;

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
