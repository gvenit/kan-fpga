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
  parameter DATA_BANK_DEPTH = 256,
  // number of address bits needed for each bank
  parameter DATA_ADDR = `LOG2(DATA_BANK_DEPTH),
  // number of DATA_WE bits needed for each bank
  parameter DATA_WE = DATA_WIDTH_DATA / 8,

  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // depth of the grid bram
  parameter GRID_DEPTH = 256,

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
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS*BATCH_SIZE,

  /*------------------------------------------------------------------
    RESULT / OUTPUT parameters
  ------------------------------------------------------------------*/

  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,

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

  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = ((DATA_WIDTH_RSLT+7)/8),

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
  
  input  wire [DATA_WIDTH_DMA-1:0]   s_axis_weight_tdata,
  input  wire [KEEP_WIDTH_DMA-1:0]   s_axis_weight_tkeep,
  input  wire                               s_axis_weight_tvalid,  
  output wire                               s_axis_weight_tready,
  input  wire                               s_axis_weight_tlast,
  input  wire [ID_WIDTH-1:0]                s_axis_weight_tid,
  input  wire [DEST_WIDTH-1:0]              s_axis_weight_tdest,
  input  wire [USER_WIDTH-1:0]              s_axis_weight_tuser,

  /*------------------------------------------------------------------
      AXI-Stream Results / Output Master interface
  ------------------------------------------------------------------*/

  output  wire [DATA_WIDTH_DMA-1:0]  m_axis_result_tdata,
  output  wire [KEEP_WIDTH_DMA-1:0]  m_axis_result_tkeep,
  output  wire                              m_axis_result_tvalid,  
  input wire                                m_axis_result_tready,
  output  wire                              m_axis_result_tlast,
  output  wire [ID_WIDTH-1:0]               m_axis_result_tid,
  output  wire [DEST_WIDTH-1:0]             m_axis_result_tdest,
  output  wire [USER_WIDTH-1:0]             m_axis_result_tuser

  );

  /*************************************************************************************
   Local Paramters
  *************************************************************************************/

  localparam IN_WORD_DATA = BRAM_CTR_WIDTH / DATA_WIDTH_DATA;

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_ADDR = `LOG2(GRID_DEPTH);  // number of input address bits of total grid memory
  localparam GRID_PHYS_DEPTH = GRID_DEPTH / IN_WORD_DATA;  // effective - physical depth of grid ram
  localparam GRID_PHYS_ADDR = `LOG2(GRID_PHYS_DEPTH); // number of bits to represent actual addresses of grid ram

  /*************************************************************************************
   Internal Signals
  *************************************************************************************/

  // data ram packed interface out of the translator into the multi-bank brams

  wire [DATA_BANKS-1:0]                   mb_bram_data_ctr_en;
  wire [(DATA_BANKS*DATA_WE)-1:0]         mb_bram_data_ctr_we;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       mb_bram_data_ctr_addr;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] mb_bram_data_ctr_wrdata;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] mb_bram_data_ctr_rddata;

  // data ram packed interface for use internally in the architecture

  wire [DATA_BANKS-1:0]                   mb_bram_data_en;
  wire [(DATA_BANKS*DATA_ADDR)-1:0]       mb_bram_data_addr;
  wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0] mb_bram_data_rddata;
  wire [DATA_BANKS-1:0]                   mb_bram_data_rdstrobe;
    
  // grid ram interface for use internally in the architecture

  wire                        bram_grid_en;
  wire [GRID_ADDR-1:0]        bram_grid_addr;
  wire [DATA_WIDTH_DATA-1:0]  bram_grid_rddata;
  wire                        bram_grid_rdstrobe;
    
  // control flags that connecy to axi-lite mm interface

  wire pl_flag_0, pl_flag_1;  // single bit flags for output from the PL and input to the PS
  wire ps_flag_0, ps_flag_1;  // single bit flags for input to the PS and output from the PS

  wire err_unalligned_data;   // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later
  wire err_user_flag;         // Error output. WARNING: Might be grouped into AXI-Lite MM interfaces later

  wire core_rst; // Interrupt outputs. WARNING: Might be grouped into AXI-Lite MM interfaces later

  // scale register value

  wire [DATA_WIDTH_SCALE-1:0] scale_reg;  // !!!

  // DMA slave and wright streams

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] axis_wght_splitter_in_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT-1:0] axis_wght_splitter_in_tkeep;
  wire                                         axis_wght_splitter_in_tvalid;
  wire                                         axis_wght_splitter_in_tready;
  wire                                         axis_wght_splitter_in_tlast;
  wire [ID_WIDTH-1:0]                          axis_wght_splitter_in_tid;
  wire [DEST_WIDTH-1:0]                        axis_wght_splitter_in_tdest;
  wire [USER_WIDTH-1:0]                        axis_wght_splitter_in_tuser;

  wire [WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT-1:0] axis_wght_splitter_out_tdata;
  wire [WEIGHT_CHANNELS-1:0]                   axis_wght_splitter_out_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                   axis_wght_splitter_out_tready;
  wire [WEIGHT_CHANNELS-1:0]                   axis_wght_splitter_out_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]          axis_wght_splitter_out_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]        axis_wght_splitter_out_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]        axis_wght_splitter_out_tuser;

  // AXI Stream Data

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      axis_data_tdata;
  wire [DATA_CHANNELS-1:0]                      axis_data_tvalid;
  wire [DATA_CHANNELS-1:0]                      axis_data_tready;
  wire [DATA_CHANNELS-1:0]                      axis_data_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             axis_data_tid;
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           axis_data_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           axis_data_tuser;

  // AXI Stream Grid    

  wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      axis_grid_tdata;
  wire [DATA_CHANNELS-1:0]                      axis_grid_tvalid;
  wire [DATA_CHANNELS-1:0]                      axis_grid_tready;
  wire [DATA_CHANNELS-1:0]                      axis_grid_tlast;
  wire [DATA_CHANNELS*ID_WIDTH-1:0]             axis_grid_tid;  
  wire [DATA_CHANNELS*DEST_WIDTH-1:0]           axis_grid_tdest;
  wire [DATA_CHANNELS*USER_WIDTH-1:0]           axis_grid_tuser;
                                                                  
  // AXI Stream Scale

  wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]    axis_scale_tdata;
  wire [SCALE_CHANNELS-1:0]                     axis_scale_tvalid;
  wire [SCALE_CHANNELS-1:0]                     axis_scale_tready;
  wire [SCALE_CHANNELS-1:0]                     axis_scale_tlast;
  wire [SCALE_CHANNELS*ID_WIDTH-1:0]            axis_scale_tid; 
  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]          axis_scale_tdest;
  wire [SCALE_CHANNELS*USER_WIDTH-1:0]          axis_scale_tuser;
                                                                  
  // AXI Stream Weight

  wire [WEIGHT_CHANNELS*DATA_WIDTH_SCALE-1:0]   axis_weight_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    axis_weight_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    axis_weight_tready;
  wire [WEIGHT_CHANNELS-1:0]                    axis_weight_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           axis_weight_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         axis_weight_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         axis_weight_tuser;

  // AXI Stream output

  wire [WEIGHT_CHANNELS*DATA_WIDTH_RSLT-1:0]    axis_output_tdata;
  wire [WEIGHT_CHANNELS*KEEP_WIDTH-1:0]         axis_output_tkeep;
  wire [WEIGHT_CHANNELS-1:0]                    axis_output_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    axis_output_tready;
  wire [WEIGHT_CHANNELS-1:0]                    axis_output_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           axis_output_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         axis_output_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         axis_output_tuser;

  /*************************************************************************************
   Module instantiations
  *************************************************************************************/

  BramIntrfTranslator #(
    .IN_WIDTH(BRAM_CTR_WIDTH),
    .OUT_WIDTH(DATA_WIDTH_DATA),
    .BANKS(DATA_BANKS),
    .OUT_DEPTH(DATA_BANK_DEPTH)
  ) data_bram_interface_translator_inst (
    .en_i(bram_data_ctr_en),
    .we_i(bram_data_ctr_we),
    // .addr_i(bram_data_ctr_addr[DATA_ITRL_ADDR-1:0]),
    .addr_i(bram_data_ctr_addr[2 +: DATA_ITRL_ADDR]),
    .wrdata_i(bram_data_ctr_din),
    .rddata_i(bram_data_ctr_dout),
    .en_o(mb_bram_data_ctr_en),
    .we_o(mb_bram_data_ctr_we),
    .addr_o(mb_bram_data_ctr_addr),
    .wrdata_o(mb_bram_data_ctr_wrdata),
    .rddata_o(mb_bram_data_ctr_rddata)
  );

  MultiBankBram #(
    .BANKS(DATA_BANKS),
    .WIDTH(DATA_WIDTH_DATA),
    .DEPTH(DATA_BANK_DEPTH)
  ) data_multi_bank_bram_inst (
    .clk(bram_data_ctr_clk),
    .ena(mb_bram_data_ctr_en),
    .wea(mb_bram_data_ctr_we),
    .addra(mb_bram_data_ctr_addr),
    .dina(mb_bram_data_ctr_wrdata),
    .douta(mb_bram_data_ctr_rddata),
    .enb(mb_bram_data_en),
    .addrb(mb_bram_data_addr),
    .doutb(mb_bram_data_rddata),
    .validb(mb_bram_data_rdstrobe)
  );

  MultiWidthDualPortBram #(
    .PORT_B_WIDTH(DATA_WIDTH_DATA),
    .PORT_B_DEPTH(GRID_DEPTH),
    .PORT_A_WIDTH(BRAM_CTR_WIDTH)
  ) grid_bram_inst (
    .clk(bram_grid_ctr_clk),
    .ena(bram_grid_ctr_en),
    .wea(bram_grid_ctr_we),
    // .addra(bram_grid_ctr_addr[GRID_PHYS_ADDR-1:0]),
    .addra(bram_grid_ctr_addr[2 +: GRID_PHYS_ADDR]),
    .dina(bram_grid_ctr_din),
    .douta(bram_grid_ctr_dout),
    .enb(bram_grid_en),
    .addrb(bram_grid_addr),
    .doutb(bram_grid_rddata),
    .validb(bram_grid_rdstrobe)
  );

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

	AxiLiteScaleRegister  #(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(4),
    .SCALE_WIDTH(DATA_WIDTH_SCALE)
  ) axi_lite_scale_register_inst (
    .scale_reg(scale_reg),
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
    .mb_bram_data_en(mb_bram_data_en),
    .mb_bram_data_addr(mb_bram_data_addr),
    .mb_bram_data_rddata(mb_bram_data_rddata),
    .mb_bram_data_rdstrobe(mb_bram_data_rdstrobe),
    .bram_grid_en(bram_grid_en),
    .bram_grid_addr(bram_grid_addr),
    .bram_grid_rddata(bram_grid_rddata),
    .bram_grid_rdstrobe(bram_grid_rdstrobe),
    .scale_reg(scale_reg),
    .axis_data_tdata(axis_data_tdata),
    .axis_data_tvalid(axis_data_tvalid),
    .axis_data_tready(axis_data_tready),
    .axis_data_tlast(axis_data_tlast),
    .axis_data_tid(axis_data_tid),
    .axis_data_tdest(axis_data_tdest),
    .axis_data_tuser(axis_data_tuser),
    .axis_grid_tdata(axis_grid_tdata),
    .axis_grid_tvalid(axis_grid_tvalid),
    .axis_grid_tready(axis_grid_tready),
    .axis_grid_tlast(axis_grid_tlast),
    .axis_grid_tid(axis_grid_tid),  
    .axis_grid_tdest(axis_grid_tdest),
    .axis_grid_tuser(axis_grid_tuser),
    .axis_scale_tdata(axis_scale_tdata),
    .axis_scale_tvalid(axis_scale_tvalid),
    .axis_scale_tready(axis_scale_tready),
    .axis_scale_tlast(axis_scale_tlast),
    .axis_scale_tid(axis_scale_tid), 
    .axis_scale_tdest(axis_scale_tdest),
    .axis_scale_tuser(axis_scale_tuser)
  );

  axis_adapter #(
    .S_DATA_WIDTH(DATA_WIDTH_DMA),
    .S_KEEP_ENABLE(KEEP_ENABLE_DMA),
    .S_KEEP_WIDTH(KEEP_WIDTH_DMA),
    .M_DATA_WIDTH(WEIGHT_CHANNELS*DATA_WIDTH_WEIGHT),
    .M_KEEP_ENABLE(KEEP_ENABLE_DMA),
    .M_KEEP_WIDTH(WEIGHT_CHANNELS*KEEP_WIDTH_WEIGHT),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH)
  ) axis_adapter_weights_inst (
    .clk(clk),
    .rst(~aresetn),
    .s_axis_tdata(s_axis_weight_tdata),
    .s_axis_tkeep(s_axis_weight_tkeep),
    .s_axis_tvalid(s_axis_weight_tvalid),
    .s_axis_tready(s_axis_weight_tready),
    .s_axis_tlast(s_axis_weight_tlast),
    .s_axis_tid(s_axis_weight_tid),
    .s_axis_tdest(s_axis_weight_tdest),
    .s_axis_tuser(s_axis_weight_tuser),
    .m_axis_tdata(axis_wght_splitter_in_tdata),
    .m_axis_tkeep(axis_wght_splitter_in_tkeep),
    .m_axis_tvalid(axis_wght_splitter_in_tvalid),
    .m_axis_tready(axis_wght_splitter_in_tready),
    .m_axis_tlast(axis_wght_splitter_in_tlast),
    .m_axis_tid(axis_wght_splitter_in_tid),
    .m_axis_tdest(axis_wght_splitter_in_tdest),
    .m_axis_tuser(axis_wght_splitter_in_tuser)
  );

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
    .s_axis_tdata     (axis_wght_splitter_in_tdata),
    .s_axis_tkeep     (axis_wght_splitter_in_tkeep),
    .s_axis_tvalid    (axis_wght_splitter_in_tvalid),
    .s_axis_tready    (axis_wght_splitter_in_tready),
    .s_axis_tlast     (axis_wght_splitter_in_tlast),
    .s_axis_tid       (axis_wght_splitter_in_tid),
    .s_axis_tdest     (axis_wght_splitter_in_tdest),
    .s_axis_tuser     (axis_wght_splitter_in_tuser),
    .m_axis_tdata     (axis_wght_splitter_out_tdata),
    // .m_axis_tkeep     (axis_wght_splitter_out_tkeep),
    .m_axis_tvalid    (axis_wght_splitter_out_tvalid),
    .m_axis_tready    (axis_wght_splitter_out_tready),
    .m_axis_tlast     (axis_wght_splitter_out_tlast),
    .m_axis_tid       (axis_wght_splitter_out_tid),
    .m_axis_tdest     (axis_wght_splitter_out_tdest),
    .m_axis_tuser     (axis_wght_splitter_out_tuser)
  );

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
    .clk(clk),
    .rst(~aresetn),
    .s_axis_data_tdata(axis_data_tdata),
    .s_axis_data_tvalid(axis_data_tvalid),
    .s_axis_data_tready(axis_data_tready),
    .s_axis_data_tlast(axis_data_tlast),
    .s_axis_data_tid(axis_data_tid),
    .s_axis_data_tdest(axis_data_tdest),
    .s_axis_data_tuser(axis_data_tuser),
    .s_axis_grid_tdata(axis_grid_tdata),
    .s_axis_grid_tvalid(axis_grid_tvalid),
    .s_axis_grid_tready(axis_grid_tready),
    .s_axis_grid_tlast(axis_grid_tlast),
    .s_axis_grid_tid(axis_grid_tid),
    .s_axis_grid_tdest(axis_grid_tdest),
    .s_axis_grid_tuser(axis_grid_tuser),
    .s_axis_scale_tdata(axis_scale_tdata),
    .s_axis_scale_tvalid(axis_scale_tvalid),
    .s_axis_scale_tready(axis_scale_tready),
    .s_axis_scale_tlast(axis_scale_tlast),
    .s_axis_scale_tid(axis_scale_tid),
    .s_axis_scale_tdest(axis_scale_tdest),
    .s_axis_scale_tuser(axis_scale_tuser),
    .s_axis_weight_tdata(axis_weight_tdata),
    .s_axis_weight_tvalid(axis_weight_tvalid),
    .s_axis_weight_tready(axis_weight_tready),
    .s_axis_weight_tlast(axis_weight_tlast),
    .s_axis_weight_tid(axis_weight_tid),
    .s_axis_weight_tdest(axis_weight_tdest),
    .s_axis_weight_tuser(axis_weight_tuser),
    .m_axis_data_tdata(axis_output_tdata),
    .m_axis_data_tkeep(axis_output_tkeep),
    .m_axis_data_tvalid(axis_output_tvalid),
    .m_axis_data_tready(axis_output_tready),
    .m_axis_data_tlast(axis_output_tlast),
    .m_axis_data_tid(axis_output_tid),
    .m_axis_data_tdest(axis_output_tdest),
    .m_axis_data_tuser(axis_output_tuser),
    .err_unalligned_data(err_unalligned_data),
    .core_rst(core_rst)
  );

endmodule
