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

  // Internal Registers & Wires
  wire [CHANNELS*DATA_WIDTH-1:0]              s_axis_grid_tdata_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tvalid_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tready_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tlast_int;
  wire [CHANNELS*ID_WIDTH-1:0]                s_axis_grid_tid_int;
  wire [CHANNELS*DEST_WIDTH-1:0]              s_axis_grid_tdest_int;
  wire [CHANNELS*USER_WIDTH-1:0]              s_axis_grid_tuser_int;
  
  wire [CHANNELS*SCALE_WIDTH-1:0]             s_axis_scle_tdata_int;
  wire [CHANNELS-1:0]                         s_axis_scle_tvalid_int;
  wire [CHANNELS-1:0]                         s_axis_scle_tready_int;
  wire [CHANNELS-1:0]                         s_axis_scle_tlast_int;
  wire [CHANNELS*ID_WIDTH-1:0]                s_axis_scle_tid_int;
  wire [CHANNELS*DEST_WIDTH-1:0]              s_axis_scle_tdest_int;
  wire [CHANNELS*USER_WIDTH-1:0]              s_axis_scle_tuser_int;
  
  wire [CHANNELS*LOCAL_SDIFF_WIDTH-1:0]       int_clp_sdff_s_axis_tdata , int_sma_sdff_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tvalid, int_sma_sdff_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tready, int_sma_sdff_m_axis_tready;
  wire [CHANNELS-1:0]                         int_clp_sdff_s_axis_tlast , int_sma_sdff_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_clp_sdff_s_axis_tid   , int_sma_sdff_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_clp_sdff_s_axis_tdest , int_sma_sdff_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_clp_sdff_s_axis_tuser , int_sma_sdff_m_axis_tuser;
  
  wire [CHANNELS*SCALED_DIFF_WIDTH-1:0]       int_clp_sdff_m_axis_tdata;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tvalid;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tready;
  wire [CHANNELS-1:0]                         int_clp_sdff_m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                int_clp_sdff_m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              int_clp_sdff_m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              int_clp_sdff_m_axis_tuser;

  genvar CHN;
  generate 

  if (GRID_SHARE && CHANNELS > 1) begin : grid_share_genblock
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
    ) axis_broadcast_inst (
      .clk                (clk),
      .rst                (rst),
      .s_axis_tdata       (s_axis_grid_tdata),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (s_axis_grid_tvalid),
      .s_axis_tready      (s_axis_grid_tready),
      .s_axis_tlast       (s_axis_grid_tlast),
      .s_axis_tid         (s_axis_grid_tid),
      .s_axis_tdest       (s_axis_grid_tdest),
      .s_axis_tuser       (s_axis_grid_tuser),
      .m_axis_tdata       (s_axis_grid_tdata_int),
      .m_axis_tvalid      (s_axis_grid_tvalid_int),
      .m_axis_tready      (s_axis_grid_tready_int),
      .m_axis_tlast       (s_axis_grid_tlast_int),
      .m_axis_tid         (s_axis_grid_tid_int),
      .m_axis_tdest       (s_axis_grid_tdest_int),
      .m_axis_tuser       (s_axis_grid_tuser_int)
    );
  end else begin
    assign s_axis_grid_tdata_int   = s_axis_grid_tdata;
    assign s_axis_grid_tvalid_int  = s_axis_grid_tvalid;
    assign s_axis_grid_tready      = s_axis_grid_tready_int;
    assign s_axis_grid_tlast_int   = s_axis_grid_tlast;
    assign s_axis_grid_tid_int     = s_axis_grid_tid;
    assign s_axis_grid_tdest_int   = s_axis_grid_tdest;
    assign s_axis_grid_tuser_int   = s_axis_grid_tuser;
  end

  if (SCALE_SHARE && CHANNELS > 1) begin : scle_share_genblock
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
    ) axis_broadcast_inst (
      .clk                (clk),
      .rst                (rst),
      .s_axis_tdata       (s_axis_scle_tdata),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (s_axis_scle_tvalid),
      .s_axis_tready      (s_axis_scle_tready),
      .s_axis_tlast       (s_axis_scle_tlast),
      .s_axis_tid         (s_axis_scle_tid),
      .s_axis_tdest       (s_axis_scle_tdest),
      .s_axis_tuser       (s_axis_scle_tuser),
      .m_axis_tdata       (s_axis_scle_tdata_int),
      .m_axis_tvalid      (s_axis_scle_tvalid_int),
      .m_axis_tready      (s_axis_scle_tready_int),
      .m_axis_tlast       (s_axis_scle_tlast_int),
      .m_axis_tid         (s_axis_scle_tid_int),
      .m_axis_tdest       (s_axis_scle_tdest_int),
      .m_axis_tuser       (s_axis_scle_tuser_int)
    );
  end else begin
    assign s_axis_scle_tdata_int   = s_axis_scle_tdata;
    assign s_axis_scle_tvalid_int  = s_axis_scle_tvalid;
    assign s_axis_scle_tready      = s_axis_scle_tready_int;
    assign s_axis_scle_tlast_int   = s_axis_scle_tlast;
    assign s_axis_scle_tid_int     = s_axis_scle_tid;
    assign s_axis_scle_tdest_int   = s_axis_scle_tdest;
    assign s_axis_scle_tuser_int   = s_axis_scle_tuser;
  end
    
  for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1 ) begin : sub_mult_abs_chn_genblock
    // Internal Registers & Wires
    // Data wires
    wire [DATA_WIDTH-1:0]         int_srl_data_s_axis_tdata_slice,     int_srl_data_m_axis_tdata_slice; 
    wire                          int_srl_data_s_axis_tvalid_slice,    int_srl_data_m_axis_tvalid_slice; 
    wire                          int_srl_data_s_axis_tready_slice,    int_srl_data_m_axis_tready_slice; 
    wire                          int_srl_data_s_axis_tlast_slice,     int_srl_data_m_axis_tlast_slice; 
    wire [ID_WIDTH-1:0]           int_srl_data_s_axis_tid_slice,       int_srl_data_m_axis_tid_slice; 
    wire [DEST_WIDTH-1:0]         int_srl_data_s_axis_tdest_slice,     int_srl_data_m_axis_tdest_slice; 
    wire [USER_WIDTH-1:0]         int_srl_data_s_axis_tuser_slice,     int_srl_data_m_axis_tuser_slice; 

    // Grid Wires
    wire [DATA_WIDTH-1:0]         int_srl_grid_s_axis_tdata_slice,     int_srl_grid_m_axis_tdata_slice;
    wire                          int_srl_grid_s_axis_tvalid_slice,    int_srl_grid_m_axis_tvalid_slice;
    wire                          int_srl_grid_s_axis_tready_slice,    int_srl_grid_m_axis_tready_slice;
    wire                          int_srl_grid_s_axis_tlast_slice,     int_srl_grid_m_axis_tlast_slice;
    wire [ID_WIDTH-1:0]           int_srl_grid_s_axis_tid_slice,       int_srl_grid_m_axis_tid_slice;
    wire [DEST_WIDTH-1:0]         int_srl_grid_s_axis_tdest_slice,     int_srl_grid_m_axis_tdest_slice;
    wire [USER_WIDTH-1:0]         int_srl_grid_s_axis_tuser_slice,     int_srl_grid_m_axis_tuser_slice;

    // Scale Wires
    wire [SCALE_WIDTH-1:0]        int_srl_scle_s_axis_tdata_slice,     int_srl_scle_m_axis_tdata_slice;
    wire                          int_srl_scle_s_axis_tvalid_slice,    int_srl_scle_m_axis_tvalid_slice;
    wire                          int_srl_scle_s_axis_tready_slice,    int_srl_scle_m_axis_tready_slice;
    wire                          int_srl_scle_s_axis_tlast_slice,     int_srl_scle_m_axis_tlast_slice;
    wire [ID_WIDTH-1:0]           int_srl_scle_s_axis_tid_slice,       int_srl_scle_m_axis_tid_slice;
    wire [DEST_WIDTH-1:0]         int_srl_scle_s_axis_tdest_slice,     int_srl_scle_m_axis_tdest_slice;
    wire [USER_WIDTH-1:0]         int_srl_scle_s_axis_tuser_slice,     int_srl_scle_m_axis_tuser_slice;
  
    wire [LOCAL_SDIFF_WIDTH-1:0]  int_sma_sdff_m_axis_tdata_slice;
    wire                          int_sma_sdff_m_axis_tvalid_slice;
    wire                          int_sma_sdff_m_axis_tready_slice;
    wire                          int_sma_sdff_m_axis_tlast_slice;
    wire [ID_WIDTH-1:0]           int_sma_sdff_m_axis_tid_slice;
    wire [DEST_WIDTH-1:0]         int_sma_sdff_m_axis_tdest_slice;
    wire [USER_WIDTH-1:0]         int_sma_sdff_m_axis_tuser_slice;
    
    assign int_srl_data_s_axis_tdata_slice    = s_axis_data_tdata[(CHN+1)*DATA_WIDTH -1: CHN*DATA_WIDTH];
    assign int_srl_data_s_axis_tvalid_slice   = s_axis_data_tvalid[CHN];
    assign s_axis_data_tready[CHN]            = int_srl_data_s_axis_tready_slice;
    assign int_srl_data_s_axis_tlast_slice    = s_axis_data_tlast[CHN];
    assign int_srl_data_s_axis_tid_slice      = s_axis_data_tid  [(CHN+1)*ID_WIDTH   -1: CHN*ID_WIDTH];
    assign int_srl_data_s_axis_tdest_slice    = s_axis_data_tdest[(CHN+1)*DEST_WIDTH -1: CHN*DEST_WIDTH];
    assign int_srl_data_s_axis_tuser_slice    = s_axis_data_tuser[(CHN+1)*USER_WIDTH -1: CHN*USER_WIDTH];

    assign int_srl_grid_s_axis_tdata_slice    = s_axis_grid_tdata_int[CHN*DATA_WIDTH +: DATA_WIDTH];
    assign int_srl_grid_s_axis_tvalid_slice   = s_axis_grid_tvalid_int[CHN];
    assign s_axis_grid_tready_int[CHN]        = int_srl_grid_s_axis_tready_slice;
    assign int_srl_grid_s_axis_tlast_slice    = s_axis_grid_tlast_int[CHN];
    assign int_srl_grid_s_axis_tid_slice      = s_axis_grid_tid_int  [CHN*ID_WIDTH +: ID_WIDTH];
    assign int_srl_grid_s_axis_tdest_slice    = s_axis_grid_tdest_int[CHN*DEST_WIDTH +: DEST_WIDTH];
    assign int_srl_grid_s_axis_tuser_slice    = s_axis_grid_tuser_int[CHN*USER_WIDTH +: USER_WIDTH];
  
    assign int_srl_scle_s_axis_tdata_slice    = s_axis_scle_tdata_int[CHN*DATA_WIDTH +: DATA_WIDTH];
    assign int_srl_scle_s_axis_tvalid_slice   = s_axis_scle_tvalid_int[CHN];
    assign s_axis_scle_tready_int[CHN]        = int_srl_scle_s_axis_tready_slice;
    assign int_srl_scle_s_axis_tlast_slice    = s_axis_scle_tlast_int[CHN];
    assign int_srl_scle_s_axis_tid_slice      = s_axis_scle_tid_int  [CHN*ID_WIDTH +: ID_WIDTH];
    assign int_srl_scle_s_axis_tdest_slice    = s_axis_scle_tdest_int[CHN*DEST_WIDTH +: DEST_WIDTH];
    assign int_srl_scle_s_axis_tuser_slice    = s_axis_scle_tuser_int[CHN*USER_WIDTH +: USER_WIDTH];

    if (FIFO_DEPTH) begin : input_fifo_genblock
      
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
      ) axis_fifo_data_inst (
        .clk                (clk),
        .rst                (rst),
        .s_axis_tdata       (int_srl_data_s_axis_tdata_slice),
        .s_axis_tkeep       (1'b1),
        .s_axis_tvalid      (int_srl_data_s_axis_tvalid_slice),
        .s_axis_tready      (int_srl_data_s_axis_tready_slice),
        .s_axis_tlast       (int_srl_data_s_axis_tlast_slice),
        .s_axis_tid         (int_srl_data_s_axis_tid_slice),
        .s_axis_tdest       (int_srl_data_s_axis_tdest_slice),
        .s_axis_tuser       (int_srl_data_s_axis_tuser_slice),
        .m_axis_tdata       (int_srl_data_m_axis_tdata_slice),
        .m_axis_tvalid      (int_srl_data_m_axis_tvalid_slice),
        .m_axis_tready      (int_srl_data_m_axis_tready_slice),
        .m_axis_tlast       (int_srl_data_m_axis_tlast_slice),
        .m_axis_tid         (int_srl_data_m_axis_tid_slice),
        .m_axis_tdest       (int_srl_data_m_axis_tdest_slice),
        .m_axis_tuser       (int_srl_data_m_axis_tuser_slice)
      );
      
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
      ) axis_fifo_grid_inst (
        .clk                (clk),
        .rst                (rst),
        .s_axis_tdata       (int_srl_grid_s_axis_tdata_slice),
        .s_axis_tkeep       (1'b1),
        .s_axis_tvalid      (int_srl_grid_s_axis_tvalid_slice),
        .s_axis_tready      (int_srl_grid_s_axis_tready_slice),
        .s_axis_tlast       (int_srl_grid_s_axis_tlast_slice),
        .s_axis_tid         (int_srl_grid_s_axis_tid_slice),
        .s_axis_tdest       (int_srl_grid_s_axis_tdest_slice),
        .s_axis_tuser       (int_srl_grid_s_axis_tuser_slice),
        .m_axis_tdata       (int_srl_grid_m_axis_tdata_slice),
        .m_axis_tvalid      (int_srl_grid_m_axis_tvalid_slice),
        .m_axis_tready      (int_srl_grid_m_axis_tready_slice),
        .m_axis_tlast       (int_srl_grid_m_axis_tlast_slice),
        .m_axis_tid         (int_srl_grid_m_axis_tid_slice),
        .m_axis_tdest       (int_srl_grid_m_axis_tdest_slice),
        .m_axis_tuser       (int_srl_grid_m_axis_tuser_slice)
      );
      
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
      ) axis_fifo_scle_inst (
        .clk                (clk),
        .rst                (rst),
        .s_axis_tdata       (int_srl_scle_s_axis_tdata_slice),
        .s_axis_tkeep       (1'b1),
        .s_axis_tvalid      (int_srl_scle_s_axis_tvalid_slice),
        .s_axis_tready      (int_srl_scle_s_axis_tready_slice),
        .s_axis_tlast       (int_srl_scle_s_axis_tlast_slice),
        .s_axis_tid         (int_srl_scle_s_axis_tid_slice),
        .s_axis_tdest       (int_srl_scle_s_axis_tdest_slice),
        .s_axis_tuser       (int_srl_scle_s_axis_tuser_slice),
        .m_axis_tdata       (int_srl_scle_m_axis_tdata_slice),
        .m_axis_tvalid      (int_srl_scle_m_axis_tvalid_slice),
        .m_axis_tready      (int_srl_scle_m_axis_tready_slice),
        .m_axis_tlast       (int_srl_scle_m_axis_tlast_slice),
        .m_axis_tid         (int_srl_scle_m_axis_tid_slice),
        .m_axis_tdest       (int_srl_scle_m_axis_tdest_slice),
        .m_axis_tuser       (int_srl_scle_m_axis_tuser_slice)
      );
    end else begin : input_skip_fifo_genblock

      assign int_srl_data_m_axis_tdata_slice    = int_srl_data_s_axis_tdata_slice;
      assign int_srl_data_m_axis_tvalid_slice   = int_srl_data_s_axis_tvalid_slice;
      assign int_srl_data_s_axis_tready_slice   = int_srl_data_m_axis_tready_slice;
      assign int_srl_data_m_axis_tlast_slice    = int_srl_data_s_axis_tlast_slice;
      assign int_srl_data_m_axis_tid_slice      = int_srl_data_s_axis_tid_slice;
      assign int_srl_data_m_axis_tdest_slice    = int_srl_data_s_axis_tdest_slice;
      assign int_srl_data_m_axis_tuser_slice    = int_srl_data_s_axis_tuser_slice;

      assign int_srl_grid_m_axis_tdata_slice    = int_srl_grid_s_axis_tdata_slice;
      assign int_srl_grid_m_axis_tvalid_slice   = int_srl_grid_s_axis_tvalid_slice;
      assign int_srl_grid_s_axis_tready_slice   = int_srl_grid_m_axis_tready_slice;
      assign int_srl_grid_m_axis_tlast_slice    = int_srl_grid_s_axis_tlast_slice;
      assign int_srl_grid_m_axis_tid_slice      = int_srl_grid_s_axis_tid_slice;
      assign int_srl_grid_m_axis_tdest_slice    = int_srl_grid_s_axis_tdest_slice;
      assign int_srl_grid_m_axis_tuser_slice    = int_srl_grid_s_axis_tuser_slice;
    
      assign int_srl_scle_m_axis_tdata_slice    = int_srl_scle_s_axis_tdata_slice;
      assign int_srl_scle_m_axis_tvalid_slice   = int_srl_scle_s_axis_tvalid_slice;
      assign int_srl_scle_s_axis_tready_slice   = int_srl_scle_m_axis_tready_slice;
      assign int_srl_scle_m_axis_tlast_slice    = int_srl_scle_s_axis_tlast_slice;
      assign int_srl_scle_m_axis_tid_slice      = int_srl_scle_s_axis_tid_slice;
      assign int_srl_scle_m_axis_tdest_slice    = int_srl_scle_s_axis_tdest_slice;
      assign int_srl_scle_m_axis_tuser_slice    = int_srl_scle_s_axis_tuser_slice;
    end

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
    ) SubMultAbs_inst (
      .clk                    (clk),
      .rst                    (rst),
      .s_axis_data_tdata      (int_srl_data_m_axis_tdata_slice),
      .s_axis_data_tvalid     (int_srl_data_m_axis_tvalid_slice),
      .s_axis_data_tready     (int_srl_data_m_axis_tready_slice),
      .s_axis_data_tlast      (int_srl_data_m_axis_tlast_slice),
      .s_axis_data_tid        (int_srl_data_m_axis_tid_slice),
      .s_axis_data_tdest      (int_srl_data_m_axis_tdest_slice),
      .s_axis_data_tuser      (int_srl_data_m_axis_tuser_slice),
      .s_axis_grid_tdata      (int_srl_grid_m_axis_tdata_slice),
      .s_axis_grid_tvalid     (int_srl_grid_m_axis_tvalid_slice),
      .s_axis_grid_tready     (int_srl_grid_m_axis_tready_slice),
      .s_axis_grid_tlast      (int_srl_grid_m_axis_tlast_slice),
      .s_axis_grid_tid        (int_srl_grid_m_axis_tid_slice),
      .s_axis_grid_tdest      (int_srl_grid_m_axis_tdest_slice),
      .s_axis_grid_tuser      (int_srl_grid_m_axis_tuser_slice),
      .s_axis_scle_tdata      (int_srl_scle_m_axis_tdata_slice),
      .s_axis_scle_tvalid     (int_srl_scle_m_axis_tvalid_slice),
      .s_axis_scle_tready     (int_srl_scle_m_axis_tready_slice),
      .s_axis_scle_tlast      (int_srl_scle_m_axis_tlast_slice),
      .s_axis_scle_tid        (int_srl_scle_m_axis_tid_slice),
      .s_axis_scle_tdest      (int_srl_scle_m_axis_tdest_slice),
      .s_axis_scle_tuser      (int_srl_scle_m_axis_tuser_slice),
      .m_axis_data_tdata      (int_sma_sdff_m_axis_tdata_slice),
      .m_axis_data_tvalid     (int_sma_sdff_m_axis_tvalid_slice),
      .m_axis_data_tready     (int_sma_sdff_m_axis_tready_slice),
      .m_axis_data_tlast      (int_sma_sdff_m_axis_tlast_slice),
      .m_axis_data_tid        (int_sma_sdff_m_axis_tid_slice),
      .m_axis_data_tdest      (int_sma_sdff_m_axis_tdest_slice),
      .m_axis_data_tuser      (int_sma_sdff_m_axis_tuser_slice)
    );

    assign int_sma_sdff_m_axis_tdata [CHN*LOCAL_SDIFF_WIDTH +: LOCAL_SDIFF_WIDTH] = int_sma_sdff_m_axis_tdata_slice;
    assign int_sma_sdff_m_axis_tlast [CHN]                                        = int_sma_sdff_m_axis_tlast_slice;
    assign int_sma_sdff_m_axis_tvalid[CHN]                                        = int_sma_sdff_m_axis_tvalid_slice;
    assign int_sma_sdff_m_axis_tready_slice                                       = int_sma_sdff_m_axis_tready[CHN];
    assign int_sma_sdff_m_axis_tid   [CHN*ID_WIDTH +: ID_WIDTH]                   = int_sma_sdff_m_axis_tid_slice;
    assign int_sma_sdff_m_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH]               = int_sma_sdff_m_axis_tdest_slice;
    assign int_sma_sdff_m_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH]               = int_sma_sdff_m_axis_tuser_slice;
    
  end
  endgenerate

  AxisClamp #(
    .DATA_WIDTH             (LOCAL_SDIFF_WIDTH),
    .RSLT_WIDTH             (SCALED_DIFF_WIDTH),
    .DATA_FRACTIONAL_BITS   (LOCAL_SDIFF_FRACTIONAL_BITS),
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
    .s_axis_tlast           (int_clp_sdff_s_axis_tlast),
    .s_axis_tvalid          (int_clp_sdff_s_axis_tvalid),
    .s_axis_tready          (int_clp_sdff_s_axis_tready),
    .s_axis_tid             (int_clp_sdff_s_axis_tid),
    .s_axis_tdest           (int_clp_sdff_s_axis_tdest),
    .s_axis_tuser           (int_clp_sdff_s_axis_tuser),
    .m_axis_tdata           (int_clp_sdff_m_axis_tdata),
    .m_axis_tlast           (int_clp_sdff_m_axis_tlast),
    .m_axis_tvalid          (int_clp_sdff_m_axis_tvalid),
    .m_axis_tready          (int_clp_sdff_m_axis_tready),
    .m_axis_tid             (int_clp_sdff_m_axis_tid),
    .m_axis_tdest           (int_clp_sdff_m_axis_tdest),
    .m_axis_tuser           (int_clp_sdff_m_axis_tuser)
  );

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
  ) Sech2Lutram_inst (
    .clk                    ({CHANNELS{clk}}),
    .rst                    ({CHANNELS{rst}}),
    .s_axis_tdata           (int_clp_sdff_m_axis_tdata),
    .s_axis_tlast           (int_clp_sdff_m_axis_tlast),
    .s_axis_tvalid          (int_clp_sdff_m_axis_tvalid),
    .s_axis_tready          (int_clp_sdff_m_axis_tready),
    .s_axis_tid             (int_clp_sdff_m_axis_tid),
    .s_axis_tdest           (int_clp_sdff_m_axis_tdest),
    .s_axis_tuser           (int_clp_sdff_m_axis_tuser),
    .m_axis_tdata           (m_axis_data_tdata),
    .m_axis_tlast           (m_axis_data_tlast),
    .m_axis_tvalid          (m_axis_data_tvalid),
    .m_axis_tready          (m_axis_data_tready),
    .m_axis_tid             (m_axis_data_tid),
    .m_axis_tdest           (m_axis_data_tdest),
    .m_axis_tuser           (m_axis_data_tuser)
  );

  assign int_clp_sdff_s_axis_tdata  = int_sma_sdff_m_axis_tdata; 
  assign int_clp_sdff_s_axis_tlast  = int_sma_sdff_m_axis_tlast; 
  assign int_clp_sdff_s_axis_tvalid = int_sma_sdff_m_axis_tvalid; 
  assign int_sma_sdff_m_axis_tready = int_clp_sdff_s_axis_tready; 
  assign int_clp_sdff_s_axis_tid    = int_sma_sdff_m_axis_tid; 
  assign int_clp_sdff_s_axis_tdest  = int_sma_sdff_m_axis_tdest; 
  assign int_clp_sdff_s_axis_tuser  = int_sma_sdff_m_axis_tuser; 

endmodule

`resetall
