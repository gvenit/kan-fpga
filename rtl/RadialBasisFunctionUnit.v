`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  RadialBasisFunctionUnit : Accepts three input AXI-Stream frames and returns the
 *    result RBF(scale * (x-grid)), where RBF a function implemented as a ROM.
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */

module RadialBasisFunctionUnit #
(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scale
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Width of AXI stream Output Data interface in bits
  parameter SCALED_DIFF_WIDTH = 16,
  // Fractional bits of output data
  parameter SCALED_DIFF_FRACTIONAL_BITS = 12,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12,
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
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Use Common Share Channel 
  parameter SCALE_SHARE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SCALE_SHARE) ? 1 : CHANNELS,
  // Use Common Grid Channel 
  parameter GRID_SHARE = 1,
  // Grid Channels
  parameter GRID_CHANNELS = (GRID_SHARE)? 1 : CHANNELS,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt",
  // Use FIFO for inputs
  parameter FIFO_DEPTH = 0
)
(
  input  wire                                         clk,
  input  wire                                         rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]               s_axis_data_tdata,
  input  wire [CHANNELS-1:0]                          s_axis_data_tvalid,
  output wire [CHANNELS-1:0]                          s_axis_data_tready,
  input  wire [CHANNELS-1:0]                          s_axis_data_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]                 s_axis_data_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]               s_axis_data_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]               s_axis_data_tuser,

  /*
   * AXI Stream Grid input
   */
  input  wire [GRID_CHANNELS*DATA_WIDTH-1:0]          s_axis_grid_tdata,
  input  wire [GRID_CHANNELS-1:0]                     s_axis_grid_tvalid,
  output wire [GRID_CHANNELS-1:0]                     s_axis_grid_tready,
  input  wire [GRID_CHANNELS-1:0]                     s_axis_grid_tlast,
  input  wire [GRID_CHANNELS*ID_WIDTH-1:0]            s_axis_grid_tid,
  input  wire [GRID_CHANNELS*DEST_WIDTH-1:0]          s_axis_grid_tdest,
  input  wire [GRID_CHANNELS*USER_WIDTH-1:0]          s_axis_grid_tuser,

  /*
   * AXI Stream Scale input
   */
  input  wire [SCALE_CHANNELS*SCALE_WIDTH-1:0]        s_axis_scle_tdata,
  input  wire [SCALE_CHANNELS-1:0]                    s_axis_scle_tvalid,
  output wire [SCALE_CHANNELS-1:0]                    s_axis_scle_tready,
  input  wire [SCALE_CHANNELS-1:0]                    s_axis_scle_tlast,
  input  wire [SCALE_CHANNELS*ID_WIDTH-1:0]           s_axis_scle_tid,
  input  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]         s_axis_scle_tdest,
  input  wire [SCALE_CHANNELS*USER_WIDTH-1:0]         s_axis_scle_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*RSLT_WIDTH-1:0]               m_axis_data_tdata,
  output wire [CHANNELS-1:0]                          m_axis_data_tvalid,
  input  wire [CHANNELS-1:0]                          m_axis_data_tready,
  output wire [CHANNELS-1:0]                          m_axis_data_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]                 m_axis_data_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]               m_axis_data_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]               m_axis_data_tuser
);

  localparam LOCAL_SDIFF_WIDTH = DATA_WIDTH + SCALE_WIDTH;
  localparam LOCAL_SDIFF_FRACTIONAL_BITS = DATA_FRACTIONAL_BITS + SCALE_FRACTIONAL_BITS;

  // Internal Registers & Wires -- I/O for Grid Broadcaster
  wire [GRID_CHANNELS*DATA_WIDTH-1:0]         int_cst_grid_s_axis_tdata;
  wire [GRID_CHANNELS-1:0]                    int_cst_grid_s_axis_tvalid;
  wire [GRID_CHANNELS-1:0]                    int_cst_grid_s_axis_tready;
  wire [GRID_CHANNELS-1:0]                    int_cst_grid_s_axis_tlast;
  wire [GRID_CHANNELS*ID_WIDTH-1:0]           int_cst_grid_s_axis_tid;
  wire [GRID_CHANNELS*DEST_WIDTH-1:0]         int_cst_grid_s_axis_tdest;
  wire [GRID_CHANNELS*USER_WIDTH-1:0]         int_cst_grid_s_axis_tuser;
  
  wire [SCALE_CHANNELS*SCALE_WIDTH-1:0]       int_cst_scle_s_axis_tdata;
  wire [SCALE_CHANNELS-1:0]                   int_cst_scle_s_axis_tvalid;
  wire [SCALE_CHANNELS-1:0]                   int_cst_scle_s_axis_tready;
  wire [SCALE_CHANNELS-1:0]                   int_cst_scle_s_axis_tlast;
  wire [SCALE_CHANNELS*ID_WIDTH-1:0]          int_cst_scle_s_axis_tid;
  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]        int_cst_scle_s_axis_tdest;
  wire [SCALE_CHANNELS*USER_WIDTH-1:0]        int_cst_scle_s_axis_tuser;

  // Internal Registers & Wires -- I/O for Scale Broadcaster
  wire [CHANNELS*DATA_WIDTH-1:0]              int_cst_grid_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_cst_grid_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_cst_grid_m_axis_tready;
  wire [CHANNELS-1:0]                         int_cst_grid_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_cst_grid_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_cst_grid_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_cst_grid_m_axis_tuser;
  
  wire [CHANNELS*SCALE_WIDTH-1:0]             int_cst_scle_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_cst_scle_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_cst_scle_m_axis_tready;
  wire [CHANNELS-1:0]                         int_cst_scle_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_cst_scle_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_cst_scle_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_cst_scle_m_axis_tuser;
  
  // Internal Registers & Wires -- I/O for Data SRL-FIFOs
  wire [CHANNELS*DATA_WIDTH-1:0]              int_srl_data_s_axis_tdata,     int_srl_data_m_axis_tdata; 
  wire [CHANNELS-1:0]                         int_srl_data_s_axis_tvalid,    int_srl_data_m_axis_tvalid; 
  wire [CHANNELS-1:0]                         int_srl_data_s_axis_tready,    int_srl_data_m_axis_tready; 
  wire [CHANNELS-1:0]                         int_srl_data_s_axis_tlast,     int_srl_data_m_axis_tlast; 
  wire [CHANNELS*ID_WIDTH-1:0]                int_srl_data_s_axis_tid,       int_srl_data_m_axis_tid; 
  wire [CHANNELS*DEST_WIDTH-1:0]              int_srl_data_s_axis_tdest,     int_srl_data_m_axis_tdest; 
  wire [CHANNELS*USER_WIDTH-1:0]              int_srl_data_s_axis_tuser,     int_srl_data_m_axis_tuser; 

  // Internal Registers & Wires -- I/O for Grid SRL-FIFOs
  wire [CHANNELS*DATA_WIDTH-1:0]              int_srl_grid_s_axis_tdata,     int_srl_grid_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_srl_grid_s_axis_tvalid,    int_srl_grid_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_srl_grid_s_axis_tready,    int_srl_grid_m_axis_tready;
  wire [CHANNELS-1:0]                         int_srl_grid_s_axis_tlast,     int_srl_grid_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_srl_grid_s_axis_tid,       int_srl_grid_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_srl_grid_s_axis_tdest,     int_srl_grid_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_srl_grid_s_axis_tuser,     int_srl_grid_m_axis_tuser;

  // Internal Registers & Wires -- I/O for Scale SRL-FIFOs
  wire [CHANNELS*SCALE_WIDTH-1:0]             int_srl_scle_s_axis_tdata,     int_srl_scle_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_srl_scle_s_axis_tvalid,    int_srl_scle_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_srl_scle_s_axis_tready,    int_srl_scle_m_axis_tready;
  wire [CHANNELS-1:0]                         int_srl_scle_s_axis_tlast,     int_srl_scle_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_srl_scle_s_axis_tid,       int_srl_scle_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_srl_scle_s_axis_tdest,     int_srl_scle_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_srl_scle_s_axis_tuser,     int_srl_scle_m_axis_tuser;

  // Internal Registers & Wires -- I/O for SubMultAbs
  wire [CHANNELS*DATA_WIDTH-1:0]              int_sma_data_s_axis_tdata;
  wire [CHANNELS-1:0]                         int_sma_data_s_axis_tvalid;
  wire [CHANNELS-1:0]                         int_sma_data_s_axis_tready;
  wire [CHANNELS-1:0]                         int_sma_data_s_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_sma_data_s_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_sma_data_s_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_sma_data_s_axis_tuser;

  wire [CHANNELS*DATA_WIDTH-1:0]              int_sma_grid_s_axis_tdata;
  wire [CHANNELS-1:0]                         int_sma_grid_s_axis_tvalid;
  wire [CHANNELS-1:0]                         int_sma_grid_s_axis_tready;
  wire [CHANNELS-1:0]                         int_sma_grid_s_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_sma_grid_s_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_sma_grid_s_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_sma_grid_s_axis_tuser;

  wire [CHANNELS*SCALE_WIDTH-1:0]             int_sma_scle_s_axis_tdata;
  wire [CHANNELS-1:0]                         int_sma_scle_s_axis_tvalid;
  wire [CHANNELS-1:0]                         int_sma_scle_s_axis_tready;
  wire [CHANNELS-1:0]                         int_sma_scle_s_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_sma_scle_s_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_sma_scle_s_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_sma_scle_s_axis_tuser;

  wire [CHANNELS*LOCAL_SDIFF_WIDTH-1:0]       int_sma_sdff_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_sma_sdff_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_sma_sdff_m_axis_tready;
  wire [CHANNELS-1:0]                         int_sma_sdff_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_sma_sdff_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_sma_sdff_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_sma_sdff_m_axis_tuser;

  // Internal Registers & Wires -- I/O for Scaled Difference Clamper
  wire [CHANNELS*LOCAL_SDIFF_WIDTH-1:0]       int_clp_sdff_s_axis_tdata;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tvalid;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tready;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_clp_sdff_s_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_clp_sdff_s_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_clp_sdff_s_axis_tuser;
  
  wire [CHANNELS*SCALED_DIFF_WIDTH-1:0]       int_clp_sdff_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tready;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_clp_sdff_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_clp_sdff_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_clp_sdff_m_axis_tuser;

  // Internal Registers & Wires -- I/O for AxisROM
  wire [CHANNELS*SCALED_DIFF_WIDTH-1:0]       int_rom_sdff_s_axis_tdata;
  wire [CHANNELS-1:0]                         int_rom_sdff_s_axis_tvalid;
  wire [CHANNELS-1:0]                         int_rom_sdff_s_axis_tready;
  wire [CHANNELS-1:0]                         int_rom_sdff_s_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_rom_sdff_s_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_rom_sdff_s_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_rom_sdff_s_axis_tuser;
  
  wire [CHANNELS*RSLT_WIDTH-1:0]              int_rom_actf_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_rom_actf_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_rom_actf_m_axis_tready;
  wire [CHANNELS-1:0]                         int_rom_actf_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_rom_actf_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_rom_actf_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_rom_actf_m_axis_tuser;

 genvar CHN;
 generate if (GRID_SHARE && CHANNELS > 1) begin : grid_share_genblock
  // Grid Broadcast Block
  axis_broadcast #(
    .M_COUNT            (CHANNELS),
    .DATA_WIDTH         (DATA_WIDTH),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .LAST_ENABLE        (1),
    .ID_ENABLE          (ID_ENABLE),
    .ID_WIDTH           (ID_WIDTH),
    .DEST_ENABLE        (DEST_ENABLE),
    .DEST_WIDTH         (DEST_WIDTH),
    .USER_ENABLE        (USER_ENABLE),
    .USER_WIDTH         (USER_WIDTH)
  ) axis_cst_grid_inst (
    .clk                (clk),
    .rst                (rst),
    .s_axis_tdata       (int_cst_grid_s_axis_tdata),
    .s_axis_tkeep       (1'b1),
    .s_axis_tvalid      (int_cst_grid_s_axis_tvalid),
    .s_axis_tready      (int_cst_grid_s_axis_tready),
    .s_axis_tlast       (int_cst_grid_s_axis_tlast),
    .s_axis_tid         (int_cst_grid_s_axis_tid),
    .s_axis_tdest       (int_cst_grid_s_axis_tdest),
    .s_axis_tuser       (int_cst_grid_s_axis_tuser),
    .m_axis_tdata       (int_cst_grid_m_axis_tdata),
    .m_axis_tvalid      (int_cst_grid_m_axis_tvalid),
    .m_axis_tready      (int_cst_grid_m_axis_tready),
    .m_axis_tlast       (int_cst_grid_m_axis_tlast),
    .m_axis_tid         (int_cst_grid_m_axis_tid),
    .m_axis_tdest       (int_cst_grid_m_axis_tdest),
    .m_axis_tuser       (int_cst_grid_m_axis_tuser)
  );
 end else begin
  assign int_cst_grid_m_axis_tdata   = int_cst_grid_s_axis_tdata;
  assign int_cst_grid_m_axis_tvalid  = int_cst_grid_s_axis_tvalid;
  assign int_cst_grid_s_axis_tready  = int_cst_grid_m_axis_tready;
  assign int_cst_grid_m_axis_tlast   = int_cst_grid_s_axis_tlast;
  assign int_cst_grid_m_axis_tid     = int_cst_grid_s_axis_tid;
  assign int_cst_grid_m_axis_tdest   = int_cst_grid_s_axis_tdest;
  assign int_cst_grid_m_axis_tuser   = int_cst_grid_s_axis_tuser;
 end

 if (SCALE_SHARE && CHANNELS > 1) begin : scle_share_genblock
  // Scale Broadcast Block
  axis_broadcast #(
    .M_COUNT            (CHANNELS),
    .DATA_WIDTH         (SCALE_WIDTH),
    .KEEP_ENABLE        (0),
    .KEEP_WIDTH         (1),
    .LAST_ENABLE        (1),
    .ID_ENABLE          (ID_ENABLE),
    .ID_WIDTH           (ID_WIDTH),
    .DEST_ENABLE        (DEST_ENABLE),
    .DEST_WIDTH         (DEST_WIDTH),
    .USER_ENABLE        (USER_ENABLE),
    .USER_WIDTH         (USER_WIDTH)
  ) axis_cst_scle_inst (
    .clk                (clk),
    .rst                (rst),
    .s_axis_tdata       (int_cst_scle_s_axis_tdata),
    .s_axis_tkeep       (1'b1),
    .s_axis_tvalid      (int_cst_scle_s_axis_tvalid),
    .s_axis_tready      (int_cst_scle_s_axis_tready),
    .s_axis_tlast       (int_cst_scle_s_axis_tlast),
    .s_axis_tid         (int_cst_scle_s_axis_tid),
    .s_axis_tdest       (int_cst_scle_s_axis_tdest),
    .s_axis_tuser       (int_cst_scle_s_axis_tuser),
    .m_axis_tdata       (int_cst_scle_m_axis_tdata),
    .m_axis_tvalid      (int_cst_scle_m_axis_tvalid),
    .m_axis_tready      (int_cst_scle_m_axis_tready),
    .m_axis_tlast       (int_cst_scle_m_axis_tlast),
    .m_axis_tid         (int_cst_scle_m_axis_tid),
    .m_axis_tdest       (int_cst_scle_m_axis_tdest),
    .m_axis_tuser       (int_cst_scle_m_axis_tuser)
  );
 end else begin
  assign int_cst_scle_m_axis_tdata   = int_cst_scle_s_axis_tdata;
  assign int_cst_scle_m_axis_tvalid  = int_cst_scle_s_axis_tvalid;
  assign int_cst_scle_s_axis_tready  = int_cst_scle_m_axis_tready;
  assign int_cst_scle_m_axis_tlast   = int_cst_scle_s_axis_tlast;
  assign int_cst_scle_m_axis_tid     = int_cst_scle_s_axis_tid;
  assign int_cst_scle_m_axis_tdest   = int_cst_scle_s_axis_tdest;
  assign int_cst_scle_m_axis_tuser   = int_cst_scle_s_axis_tuser;
 end
    
 // SRL-FIFO Blocks
 if (FIFO_DEPTH) begin : srl_fifo_genblock
  for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1 ) begin : srl_fifo_chn_genblock
    // Data SRL-FIFO Block per channel
    axis_srl_fifo #(
      .DATA_WIDTH         (DATA_WIDTH),
      .KEEP_ENABLE        (0),
      .KEEP_WIDTH         (1),
      .LAST_ENABLE        (1),
      .ID_ENABLE          (ID_ENABLE),
      .ID_WIDTH           (ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .DEPTH              (FIFO_DEPTH)
    ) axis_srl_data_inst (
      .clk                (clk),
      .rst                (rst),
      .s_axis_tdata       (int_srl_data_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (int_srl_data_s_axis_tvalid [CHN]),
      .s_axis_tready      (int_srl_data_s_axis_tready [CHN]),
      .s_axis_tlast       (int_srl_data_s_axis_tlast  [CHN]),
      .s_axis_tid         (int_srl_data_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .s_axis_tdest       (int_srl_data_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .s_axis_tuser       (int_srl_data_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
      .m_axis_tdata       (int_srl_data_m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tvalid      (int_srl_data_m_axis_tvalid [CHN]),
      .m_axis_tready      (int_srl_data_m_axis_tready [CHN]),
      .m_axis_tlast       (int_srl_data_m_axis_tlast  [CHN]),
      .m_axis_tid         (int_srl_data_m_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .m_axis_tdest       (int_srl_data_m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (int_srl_data_m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH])
    );
      
    // Grid SRL-FIFO Block per channel
    axis_srl_fifo #(
      .DATA_WIDTH         (DATA_WIDTH),
      .KEEP_ENABLE        (0),
      .KEEP_WIDTH         (1),
      .LAST_ENABLE        (1),
      .ID_ENABLE          (ID_ENABLE),
      .ID_WIDTH           (ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .DEPTH              (FIFO_DEPTH)
    ) axis_srl_grid_inst (
      .clk                (clk),
      .rst                (rst),
      .s_axis_tdata       (int_srl_grid_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (int_srl_grid_s_axis_tvalid [CHN]),
      .s_axis_tready      (int_srl_grid_s_axis_tready [CHN]),
      .s_axis_tlast       (int_srl_grid_s_axis_tlast  [CHN]),
      .s_axis_tid         (int_srl_grid_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .s_axis_tdest       (int_srl_grid_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .s_axis_tuser       (int_srl_grid_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
      .m_axis_tdata       (int_srl_grid_m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tvalid      (int_srl_grid_m_axis_tvalid [CHN]),
      .m_axis_tready      (int_srl_grid_m_axis_tready [CHN]),
      .m_axis_tlast       (int_srl_grid_m_axis_tlast  [CHN]),
      .m_axis_tid         (int_srl_grid_m_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .m_axis_tdest       (int_srl_grid_m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (int_srl_grid_m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH])
    );
    
    // Scale SRL-FIFO Block per channel
    axis_srl_fifo #(
      .DATA_WIDTH         (SCALE_WIDTH),
      .KEEP_ENABLE        (0),
      .KEEP_WIDTH         (1),
      .LAST_ENABLE        (1),
      .ID_ENABLE          (ID_ENABLE),
      .ID_WIDTH           (ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .DEPTH              (FIFO_DEPTH)
    ) axis_srl_scle_inst (
      .clk                (clk),
      .rst                (rst),
      .s_axis_tdata       (int_srl_scle_s_axis_tdata  [CHN*SCALE_WIDTH +: SCALE_WIDTH]),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (int_srl_scle_s_axis_tvalid [CHN]),
      .s_axis_tready      (int_srl_scle_s_axis_tready [CHN]),
      .s_axis_tlast       (int_srl_scle_s_axis_tlast  [CHN]),
      .s_axis_tid         (int_srl_scle_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .s_axis_tdest       (int_srl_scle_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .s_axis_tuser       (int_srl_scle_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
      .m_axis_tdata       (int_srl_scle_m_axis_tdata  [CHN*SCALE_WIDTH +: SCALE_WIDTH]),
      .m_axis_tvalid      (int_srl_scle_m_axis_tvalid [CHN]),
      .m_axis_tready      (int_srl_scle_m_axis_tready [CHN]),
      .m_axis_tlast       (int_srl_scle_m_axis_tlast  [CHN]),
      .m_axis_tid         (int_srl_scle_m_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .m_axis_tdest       (int_srl_scle_m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (int_srl_scle_m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH])
    );
  end 
 end else begin : srl_fifo_skip_genblock
    assign int_srl_data_m_axis_tdata  = int_srl_data_s_axis_tdata;
    assign int_srl_data_m_axis_tvalid = int_srl_data_s_axis_tvalid;
    assign int_srl_data_s_axis_tready = int_srl_data_m_axis_tready;
    assign int_srl_data_m_axis_tlast  = int_srl_data_s_axis_tlast;
    assign int_srl_data_m_axis_tid    = int_srl_data_s_axis_tid;
    assign int_srl_data_m_axis_tdest  = int_srl_data_s_axis_tdest;
    assign int_srl_data_m_axis_tuser  = int_srl_data_s_axis_tuser;

    assign int_srl_grid_m_axis_tdata  = int_srl_grid_s_axis_tdata;
    assign int_srl_grid_m_axis_tvalid = int_srl_grid_s_axis_tvalid;
    assign int_srl_grid_s_axis_tready = int_srl_grid_m_axis_tready;
    assign int_srl_grid_m_axis_tlast  = int_srl_grid_s_axis_tlast;
    assign int_srl_grid_m_axis_tid    = int_srl_grid_s_axis_tid;
    assign int_srl_grid_m_axis_tdest  = int_srl_grid_s_axis_tdest;
    assign int_srl_grid_m_axis_tuser  = int_srl_grid_s_axis_tuser;
  
    assign int_srl_scle_m_axis_tdata  = int_srl_scle_s_axis_tdata;
    assign int_srl_scle_m_axis_tvalid = int_srl_scle_s_axis_tvalid;
    assign int_srl_scle_s_axis_tready = int_srl_scle_m_axis_tready;
    assign int_srl_scle_m_axis_tlast  = int_srl_scle_s_axis_tlast;
    assign int_srl_scle_m_axis_tid    = int_srl_scle_s_axis_tid;
    assign int_srl_scle_m_axis_tdest  = int_srl_scle_s_axis_tdest;
    assign int_srl_scle_m_axis_tuser  = int_srl_scle_s_axis_tuser;
  end

 // SubMultAbs Blocks
 for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1 ) begin : sub_mult_abs_chn_genblock
  // SubMultAbs Block per channel
  SubMultAbs #(
    .DATA_WIDTH             (DATA_WIDTH),
    .DATA_FRACTIONAL_BITS   (DATA_FRACTIONAL_BITS),
    .SCALE_WIDTH            (SCALE_WIDTH),
    .SCALE_FRACTIONAL_BITS  (SCALE_FRACTIONAL_BITS),
    .RSLT_WIDTH             (LOCAL_SDIFF_WIDTH),
    .RSLT_FRACTIONAL_BITS   (LOCAL_SDIFF_FRACTIONAL_BITS),
    .ID_ENABLE              (ID_ENABLE),
    .ID_WIDTH               (ID_WIDTH),
    .DEST_ENABLE            (DEST_ENABLE),
    .DEST_WIDTH             (DEST_WIDTH),
    .USER_ENABLE            (USER_ENABLE),
    .USER_WIDTH             (USER_WIDTH),
    .OUTPUT_BUFFER          (1)
  ) sma_inst (
    .clk                    (clk),
    .rst                    (rst),
    .s_axis_data_tdata      (int_sma_data_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
    .s_axis_data_tvalid     (int_sma_data_s_axis_tvalid [CHN]),
    .s_axis_data_tready     (int_sma_data_s_axis_tready [CHN]),
    .s_axis_data_tlast      (int_sma_data_s_axis_tlast  [CHN]),
    .s_axis_data_tid        (int_sma_data_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
    .s_axis_data_tdest      (int_sma_data_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .s_axis_data_tuser      (int_sma_data_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
    .s_axis_grid_tdata      (int_sma_grid_s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH]),
    .s_axis_grid_tvalid     (int_sma_grid_s_axis_tvalid [CHN]),
    .s_axis_grid_tready     (int_sma_grid_s_axis_tready [CHN]),
    .s_axis_grid_tlast      (int_sma_grid_s_axis_tlast  [CHN]),
    .s_axis_grid_tid        (int_sma_grid_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
    .s_axis_grid_tdest      (int_sma_grid_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .s_axis_grid_tuser      (int_sma_grid_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
    .s_axis_scle_tdata      (int_sma_scle_s_axis_tdata  [CHN*SCALE_WIDTH +: SCALE_WIDTH]),
    .s_axis_scle_tvalid     (int_sma_scle_s_axis_tvalid [CHN]),
    .s_axis_scle_tready     (int_sma_scle_s_axis_tready [CHN]),
    .s_axis_scle_tlast      (int_sma_scle_s_axis_tlast  [CHN]),
    .s_axis_scle_tid        (int_sma_scle_s_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
    .s_axis_scle_tdest      (int_sma_scle_s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .s_axis_scle_tuser      (int_sma_scle_s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH]),
    .m_axis_data_tdata      (int_sma_sdff_m_axis_tdata  [CHN*LOCAL_SDIFF_WIDTH +: LOCAL_SDIFF_WIDTH]),
    .m_axis_data_tvalid     (int_sma_sdff_m_axis_tvalid [CHN]),
    .m_axis_data_tready     (int_sma_sdff_m_axis_tready [CHN]),
    .m_axis_data_tlast      (int_sma_sdff_m_axis_tlast  [CHN]),
    .m_axis_data_tid        (int_sma_sdff_m_axis_tid    [CHN*  ID_WIDTH +:   ID_WIDTH]),
    .m_axis_data_tdest      (int_sma_sdff_m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .m_axis_data_tuser      (int_sma_sdff_m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH])
  );
 end
 endgenerate

  // Axis Clamp Block
  AxisClamp #(
    .DATA_WIDTH             (LOCAL_SDIFF_WIDTH),
    .DATA_FRACTIONAL_BITS   (LOCAL_SDIFF_FRACTIONAL_BITS),
    .RSLT_WIDTH             (SCALED_DIFF_WIDTH),
    .RSLT_FRACTIONAL_BITS   (SCALED_DIFF_FRACTIONAL_BITS),
    .CHANNELS               (CHANNELS),
    .LAST_ENABLE            (1),
    .ID_ENABLE              (ID_ENABLE),
    .ID_WIDTH               (ID_WIDTH),
    .DEST_ENABLE            (DEST_ENABLE),
    .DEST_WIDTH             (DEST_WIDTH),
    .USER_ENABLE            (USER_ENABLE),
    .USER_WIDTH             (USER_WIDTH),
    .UNSIGNED_DATA          (1),
    .UNSIGNED_RSLT          (1),
    .USE_INFINITY           (1),
    .REG_TYPE               (2)
  ) clamp_inst (
    .clk                    ({CHANNELS{clk}}),
    .rst                    ({CHANNELS{rst}}),
    .s_axis_tdata           (int_clp_sdff_s_axis_tdata),
    .s_axis_tvalid          (int_clp_sdff_s_axis_tvalid),
    .s_axis_tready          (int_clp_sdff_s_axis_tready),
    .s_axis_tlast           (int_clp_sdff_s_axis_tlast),
    .s_axis_tid             (int_clp_sdff_s_axis_tid),
    .s_axis_tdest           (int_clp_sdff_s_axis_tdest),
    .s_axis_tuser           (int_clp_sdff_s_axis_tuser),
    .m_axis_tdata           (int_clp_sdff_m_axis_tdata),
    .m_axis_tvalid          (int_clp_sdff_m_axis_tvalid),
    .m_axis_tready          (int_clp_sdff_m_axis_tready),
    .m_axis_tlast           (int_clp_sdff_m_axis_tlast),
    .m_axis_tid             (int_clp_sdff_m_axis_tid),
    .m_axis_tdest           (int_clp_sdff_m_axis_tdest),
    .m_axis_tuser           (int_clp_sdff_m_axis_tuser)
  );

  // Axis ROM Block
  AxisRom #(
    .ADDR_WIDTH             (SCALED_DIFF_WIDTH),
    .DATA_WIDTH             (RSLT_WIDTH),
    .LAST_ENABLE            (1),
    .ID_ENABLE              (ID_ENABLE),
    .ID_WIDTH               (ID_WIDTH),
    .DEST_ENABLE            (DEST_ENABLE),
    .DEST_WIDTH             (DEST_WIDTH),
    .USER_ENABLE            (USER_ENABLE),
    .USER_WIDTH             (USER_WIDTH),
    .CHANNELS               (CHANNELS),
    .ROM_DATA_PATH          (ROM_DATA_PATH)
  ) axis_rom_sdff_inst (
    .clk                    ({CHANNELS{clk}}),
    .rst                    ({CHANNELS{rst}}),
    .s_axis_tdata           (int_rom_sdff_s_axis_tdata),
    .s_axis_tvalid          (int_rom_sdff_s_axis_tvalid),
    .s_axis_tready          (int_rom_sdff_s_axis_tready),
    .s_axis_tlast           (int_rom_sdff_s_axis_tlast),
    .s_axis_tid             (int_rom_sdff_s_axis_tid),
    .s_axis_tdest           (int_rom_sdff_s_axis_tdest),
    .s_axis_tuser           (int_rom_sdff_s_axis_tuser),
    .m_axis_tdata           (int_rom_actf_m_axis_tdata),
    .m_axis_tvalid          (int_rom_actf_m_axis_tvalid),
    .m_axis_tready          (int_rom_actf_m_axis_tready),
    .m_axis_tlast           (int_rom_actf_m_axis_tlast),
    .m_axis_tid             (int_rom_actf_m_axis_tid),
    .m_axis_tdest           (int_rom_actf_m_axis_tdest),
    .m_axis_tuser           (int_rom_actf_m_axis_tuser)
  );

  // Connect input grid stream with grid Broadcaster
  assign int_cst_grid_s_axis_tdata  = s_axis_grid_tdata;
  assign int_cst_grid_s_axis_tvalid = s_axis_grid_tvalid;
  assign s_axis_grid_tready = int_cst_grid_s_axis_tready;
  assign int_cst_grid_s_axis_tlast  = s_axis_grid_tlast;
  assign int_cst_grid_s_axis_tid    = s_axis_grid_tid;
  assign int_cst_grid_s_axis_tdest  = s_axis_grid_tdest;
  assign int_cst_grid_s_axis_tuser  = s_axis_grid_tuser;

  // Connect input scale stream with scale Broadcaster
  assign int_cst_scle_s_axis_tdata  = s_axis_scle_tdata;
  assign int_cst_scle_s_axis_tvalid = s_axis_scle_tvalid;
  assign s_axis_scle_tready = int_cst_scle_s_axis_tready;
  assign int_cst_scle_s_axis_tlast  = s_axis_scle_tlast;
  assign int_cst_scle_s_axis_tid    = s_axis_scle_tid;
  assign int_cst_scle_s_axis_tdest  = s_axis_scle_tdest;
  assign int_cst_scle_s_axis_tuser  = s_axis_scle_tuser;

  // Connect data Broadcaster with input data stream
  assign int_srl_data_s_axis_tdata  = s_axis_data_tdata; 
  assign int_srl_data_s_axis_tvalid = s_axis_data_tvalid; 
  assign s_axis_data_tready = int_srl_data_s_axis_tready; 
  assign int_srl_data_s_axis_tlast  = s_axis_data_tlast; 
  assign int_srl_data_s_axis_tid    = s_axis_data_tid; 
  assign int_srl_data_s_axis_tdest  = s_axis_data_tdest; 
  assign int_srl_data_s_axis_tuser  = s_axis_data_tuser; 

  // Connect grid Broadcaster with grid SRL-FIFOs
  assign int_srl_grid_s_axis_tdata  = int_cst_grid_m_axis_tdata; 
  assign int_srl_grid_s_axis_tvalid = int_cst_grid_m_axis_tvalid; 
  assign int_cst_grid_m_axis_tready = int_srl_grid_s_axis_tready; 
  assign int_srl_grid_s_axis_tlast  = int_cst_grid_m_axis_tlast; 
  assign int_srl_grid_s_axis_tid    = int_cst_grid_m_axis_tid; 
  assign int_srl_grid_s_axis_tdest  = int_cst_grid_m_axis_tdest; 
  assign int_srl_grid_s_axis_tuser  = int_cst_grid_m_axis_tuser; 

  // Connect scale Broadcaster with scale SRL-FIFOs
  assign int_srl_scle_s_axis_tdata  = int_cst_scle_m_axis_tdata; 
  assign int_srl_scle_s_axis_tvalid = int_cst_scle_m_axis_tvalid; 
  assign int_cst_scle_m_axis_tready = int_srl_scle_s_axis_tready; 
  assign int_srl_scle_s_axis_tlast  = int_cst_scle_m_axis_tlast; 
  assign int_srl_scle_s_axis_tid    = int_cst_scle_m_axis_tid; 
  assign int_srl_scle_s_axis_tdest  = int_cst_scle_m_axis_tdest; 
  assign int_srl_scle_s_axis_tuser  = int_cst_scle_m_axis_tuser; 

  // Connect data SRL-FIFOs with SubMultAbs block
  assign int_sma_data_s_axis_tdata  = int_srl_data_m_axis_tdata; 
  assign int_sma_data_s_axis_tvalid = int_srl_data_m_axis_tvalid; 
  assign int_srl_data_m_axis_tready = int_sma_data_s_axis_tready; 
  assign int_sma_data_s_axis_tlast  = int_srl_data_m_axis_tlast; 
  assign int_sma_data_s_axis_tid    = int_srl_data_m_axis_tid; 
  assign int_sma_data_s_axis_tdest  = int_srl_data_m_axis_tdest; 
  assign int_sma_data_s_axis_tuser  = int_srl_data_m_axis_tuser; 

  // Connect grid SRL-FIFOs with SubMultAbs block
  assign int_sma_grid_s_axis_tdata  = int_srl_grid_m_axis_tdata; 
  assign int_sma_grid_s_axis_tvalid = int_srl_grid_m_axis_tvalid; 
  assign int_srl_grid_m_axis_tready = int_sma_grid_s_axis_tready; 
  assign int_sma_grid_s_axis_tlast  = int_srl_grid_m_axis_tlast; 
  assign int_sma_grid_s_axis_tid    = int_srl_grid_m_axis_tid; 
  assign int_sma_grid_s_axis_tdest  = int_srl_grid_m_axis_tdest; 
  assign int_sma_grid_s_axis_tuser  = int_srl_grid_m_axis_tuser; 

  // Connect scale SRL-FIFOs with SubMultAbs block
  assign int_sma_scle_s_axis_tdata  = int_srl_scle_m_axis_tdata; 
  assign int_sma_scle_s_axis_tvalid = int_srl_scle_m_axis_tvalid; 
  assign int_srl_scle_m_axis_tready = int_sma_scle_s_axis_tready; 
  assign int_sma_scle_s_axis_tlast  = int_srl_scle_m_axis_tlast; 
  assign int_sma_scle_s_axis_tid    = int_srl_scle_m_axis_tid; 
  assign int_sma_scle_s_axis_tdest  = int_srl_scle_m_axis_tdest; 
  assign int_sma_scle_s_axis_tuser  = int_srl_scle_m_axis_tuser; 

  // Connect SubMultAbs results with scaled difference Clamper
  assign int_clp_sdff_s_axis_tdata  = int_sma_sdff_m_axis_tdata; 
  assign int_clp_sdff_s_axis_tvalid = int_sma_sdff_m_axis_tvalid; 
  assign int_sma_sdff_m_axis_tready = int_clp_sdff_s_axis_tready; 
  assign int_clp_sdff_s_axis_tlast  = int_sma_sdff_m_axis_tlast; 
  assign int_clp_sdff_s_axis_tid    = int_sma_sdff_m_axis_tid; 
  assign int_clp_sdff_s_axis_tdest  = int_sma_sdff_m_axis_tdest; 
  assign int_clp_sdff_s_axis_tuser  = int_sma_sdff_m_axis_tuser; 

  // Connect Clamper result with AxisROM input
  assign int_rom_sdff_s_axis_tdata  = int_clp_sdff_m_axis_tdata;
  assign int_rom_sdff_s_axis_tvalid = int_clp_sdff_m_axis_tvalid;
  assign int_clp_sdff_m_axis_tready = int_rom_sdff_s_axis_tready;
  assign int_rom_sdff_s_axis_tlast  = int_clp_sdff_m_axis_tlast;
  assign int_rom_sdff_s_axis_tid    = int_clp_sdff_m_axis_tid;
  assign int_rom_sdff_s_axis_tdest  = int_clp_sdff_m_axis_tdest;
  assign int_rom_sdff_s_axis_tuser  = int_clp_sdff_m_axis_tuser;

  // Connect AxisROM input with output data stream
  assign m_axis_data_tdata  = int_rom_actf_m_axis_tdata;
  assign m_axis_data_tvalid = int_rom_actf_m_axis_tvalid;
  assign int_rom_actf_m_axis_tready = m_axis_data_tready;
  assign m_axis_data_tlast  = int_rom_actf_m_axis_tlast;
  assign m_axis_data_tid    = int_rom_actf_m_axis_tid;
  assign m_axis_data_tdest  = int_rom_actf_m_axis_tdest;
  assign m_axis_data_tuser  = int_rom_actf_m_axis_tuser;

endmodule

`resetall
