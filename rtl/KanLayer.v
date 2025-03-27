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
    Bram controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter BRAM_CTR_WIDTH = 32,
  parameter BRAM_CTR_WE = 4,
  parameter BRAM_CTR_ADDR = 11,

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
  parameter DATA_BANKS = 4,
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

  // Width of AXI stream Input Weight interface in bits
  parameter DATA_WIDTH_WEIGHT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_WEIGHT = 12,
  // Number of Independent AXI-Stream Weight Channels
  parameter WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS,

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
  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/

  input wire                       bram_data_ctr_rst,
  input wire                       bram_data_ctr_clk,
  input wire                       bram_data_ctr_en,
  input wire [BRAM_CTR_WE-1:0]     bram_data_ctr_we,
  input wire [BRAM_CTR_ADDR-1:0]   bram_data_ctr_addr,
  input wire [BRAM_CTR_WIDTH-1:0]  bram_data_ctr_wrdata,
  output wire [BRAM_CTR_WIDTH-1:0] bram_data_ctr_rddata,

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/

  input wire                       bram_grid_ctr_rst,
  input wire                       bram_grid_ctr_clk,
  input wire                       bram_grid_ctr_en,
  input wire [BRAM_CTR_WE-1:0]     bram_grid_ctr_we,
  input wire [BRAM_CTR_ADDR-1:0]   bram_grid_ctr_addr,
  input wire [BRAM_CTR_WIDTH-1:0]  bram_grid_ctr_wrdata,
  output wire [BRAM_CTR_WIDTH-1:0] bram_grid_ctr_rddata,

  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  input wire          s00_axi_aclk,
  input wire          s00_axi_aresetn,
  input wire [11:0]   s00_axi_awaddr,
  input wire [2:0]    s00_axi_awprot,
  input wire          s00_axi_awvalid,
  output wire         s00_axi_awready,
  input wire [31:0]   s00_axi_wdata,
  input wire [3:0]    s00_axi_wstrb,
  input wire          s00_axi_wvalid,
  output wire         s00_axi_wready,
  output wire [1:0]   s00_axi_bresp,
  output wire         s00_axi_bvalid,
  input wire          s00_axi_bready,
  input wire [11:0]   s00_axi_araddr,
  input wire [2:0]    s00_axi_arprot,
  input wire          s00_axi_arvalid,
  output wire         s00_axi_arready,
  output wire [31:0]  s00_axi_rdata,
  output wire [1:0]   s00_axi_rresp,
  output wire         s00_axi_rvalid,
  input wire          s00_axi_rready,

  /*------------------------------------------------------------------
      AXI-Lite Scale Register Slave interface
  ------------------------------------------------------------------*/

  input wire          s01_axi_aclk,
  input wire          s01_axi_aresetn,
  input wire [11:0]   s01_axi_awaddr,
  input wire [2:0]    s01_axi_awprot,
  input wire          s01_axi_awvalid,
  output wire         s01_axi_awready,
  input wire [31:0]   s01_axi_wdata,
  input wire [3:0]    s01_axi_wstrb,
  input wire          s01_axi_wvalid,
  output wire         s01_axi_wready,
  output wire [1:0]   s01_axi_bresp,
  output wire         s01_axi_bvalid,
  input wire          s01_axi_bready,
  input wire [11:0]   s01_axi_araddr,
  input wire [2:0]    s01_axi_arprot,
  input wire          s01_axi_arvalid,
  output wire         s01_axi_arready,
  output wire [31:0]  s01_axi_rdata,
  output wire [1:0]   s01_axi_rresp,
  output wire         s01_axi_rvalid,
  input wire          s01_axi_rready
  );

  /*************************************************************************************
   Local Paramters
  *************************************************************************************/

  localparam DATA_ITRL_DEPTH = DATA_BANKS * DATA_BANK_DEPTH; // simulated total data ram length
  localparam DATA_ITRL_ADDR = `LOG2(DATA_ITRL_DEPTH);        // number of input address bits of total data memory

  localparam GRID_ITRL_ADDR = `LOG2(GRID_DEPTH);  // number of input address bits of total grid memory

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
    
  // grid ram interface out of the translator into the internal brams

  wire                        itrl_bram_grid_ctr_en;
  wire [DATA_WE-1:0]          itrl_bram_grid_ctr_we;
  wire [DATA_ADDR-1:0]        itrl_bram_grid_ctr_addr;
  wire [DATA_WIDTH_DATA-1:0]  itrl_bram_grid_ctr_wrdata;
  wire [DATA_WIDTH_DATA-1:0]  itrl_bram_grid_ctr_rddata;

  // grid ram interface for use internally in the architecture

  wire                        bram_grid_en;
  wire [DATA_ADDR-1:0]        bram_grid_addr;
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
    .addr_i(bram_data_ctr_addr[DATA_ITRL_ADDR-1:0]),
    .wrdata_i(bram_data_ctr_wrdata),
    .rddata_i(bram_data_ctr_rddata),
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

  BramIntrfTranslator #(
    .IN_WIDTH(BRAM_CTR_WIDTH),
    .OUT_WIDTH(DATA_WIDTH_DATA),
    .BANKS(1),
    .OUT_DEPTH(GRID_DEPTH)
  ) grid_bram_interface_translator_inst (
    .en_i(bram_grid_ctr_en),
    .we_i(bram_grid_ctr_we),
    .addr_i(bram_grid_ctr_addr[GRID_ITRL_ADDR-1:0]),
    .wrdata_i(bram_grid_ctr_wrdata),
    .rddata_i(bram_grid_ctr_rddata),
    .en_o(itrl_bram_grid_ctr_en),
    .we_o(itrl_bram_grid_ctr_we),
    .addr_o(itrl_bram_grid_ctr_addr),
    .wrdata_o(itrl_bram_grid_ctr_wrdata),
    .rddata_o(itrl_bram_grid_ctr_rddata)
  );

  Bram #(
    .WIDTH(DATA_WIDTH_DATA),
    .DEPTH(GRID_DEPTH)
  ) grid_bram_inst (
    .clk(bram_grid_ctr_clk),
    .ena(itrl_bram_grid_ctr_en),
    .wea(itrl_bram_grid_ctr_we),
    .addra(itrl_bram_grid_ctr_addr),
    .dina(itrl_bram_grid_ctr_wrdata),
    .douta(itrl_bram_grid_ctr_rddata),
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
    .S_AXI_ACLK(s00_axi_aclk),
    .S_AXI_ARESETN(s00_axi_aresetn),
    .S_AXI_AWADDR(s00_axi_awaddr),
    .S_AXI_AWPROT(s00_axi_awprot),
    .S_AXI_AWVALID(s00_axi_awvalid),
    .S_AXI_AWREADY(s00_axi_awready),
    .S_AXI_WDATA(s00_axi_wdata),
    .S_AXI_WSTRB(s00_axi_wstrb),
    .S_AXI_WVALID(s00_axi_wvalid),
    .S_AXI_WREADY(s00_axi_wready),
    .S_AXI_BRESP(s00_axi_bresp),
    .S_AXI_BVALID(s00_axi_bvalid),
    .S_AXI_BREADY(s00_axi_bready),
    .S_AXI_ARADDR(s00_axi_araddr),
    .S_AXI_ARPROT(s00_axi_arprot),
    .S_AXI_ARVALID(s00_axi_arvalid),
    .S_AXI_ARREADY(s00_axi_arready),
    .S_AXI_RDATA(s00_axi_rdata),
    .S_AXI_RRESP(s00_axi_rresp),
    .S_AXI_RVALID(s00_axi_rvalid),
    .S_AXI_RREADY(s00_axi_rready)
	);

	AxiLiteScaleRegister  #(
		.C_S_AXI_DATA_WIDTH(32),
		.C_S_AXI_ADDR_WIDTH(4),
    .SCALE_WIDTH(DATA_WIDTH_SCALE)
  ) axi_lite_scale_register_inst (
    .scale_reg(scale_reg),
    .S_AXI_ACLK(s01_axi_aclk),
    .S_AXI_ARESETN(s01_axi_aresetn),
    .S_AXI_AWADDR(s01_axi_awaddr),
    .S_AXI_AWPROT(s01_axi_awprot),
    .S_AXI_AWVALID(s01_axi_awvalid),
    .S_AXI_AWREADY(s01_axi_awready),
    .S_AXI_WDATA(s01_axi_wdata),
    .S_AXI_WSTRB(s01_axi_wstrb),
    .S_AXI_WVALID(s01_axi_wvalid),
    .S_AXI_WREADY(s01_axi_wready),
    .S_AXI_BRESP(s01_axi_bresp),
    .S_AXI_BVALID(s01_axi_bvalid),
    .S_AXI_BREADY(s01_axi_bready),
    .S_AXI_ARADDR(s01_axi_araddr),
    .S_AXI_ARPROT(s01_axi_arprot),
    .S_AXI_ARVALID(s01_axi_arvalid),
    .S_AXI_ARREADY(s01_axi_arready),
    .S_AXI_RDATA(s01_axi_rdata),
    .S_AXI_RRESP(s01_axi_rresp),
    .S_AXI_RVALID(s01_axi_rvalid),
    .S_AXI_RREADY(s01_axi_rready)
	);

  MemoryUnit #(
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_CHANNELS(DATA_CHANNELS),
    .DATA_BANKS(DATA_BANKS),
    .DATA_BANK_DEPTH(DATA_BANK_DEPTH),
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

  AxisSplitter #(
    .OUTPUT_DATA_WIDTH(DATA_WIDTH_WEIGHT),
    .CHANNELS(WEIGHT_CHANNELS),
    .LAST_ENABLE(LAST_ENABLE),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .EXTRA_CYCLE(EXTRA_CYCLE)
  ) axis_splitter_weights_inst (
    .clk              ( ),
    .rst              ( ),
    .s_axis_tdata     ( ),
    .s_axis_tkeep     ( ),
    .s_axis_tvalid    ( ),
    .s_axis_tready    ( ),
    .s_axis_tlast     ( ),
    .s_axis_tid       ( ),
    .s_axis_tdest     ( ),
    .s_axis_tuser     ( ),
    .m_axis_tdata     (axis_weight_tdata),
    .m_axis_tkeep     ( ),
    .m_axis_tvalid    (axis_weight_tvalid),
    .m_axis_tready    (axis_weight_tready),
    .m_axis_tlast     (axis_weight_tlast),
    .m_axis_tid       (axis_weight_tid),
    .m_axis_tdest     (axis_weight_tdest),
    .m_axis_tuser     (axis_weight_tuser)
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
    .clk(s00_axi_aclk),
    .rst(~s00_axi_aresetn),
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
