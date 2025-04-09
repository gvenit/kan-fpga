
`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  RSWAFFunction : Accepts three input AXI-Stream frames and returns the
 *    result sech^2(scale * (x-grid))
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */

module RSWAFFunction #
(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scale
  parameter FRACTIONAL_BITS_SCALE = 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_SCALED_DIFF = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_SCALED_DIFF = 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
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
  parameter SHARE_SCALE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SHARE_SCALE) ? 1 : CHANNELS,
  // Use Common Grid Channel 
  parameter SHARE_GRID = 1,
  // Grid Channels
  parameter GRID_CHANNELS = (SHARE_GRID)? 1 : CHANNELS,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.12_16.16.txt"
)
(
  input  wire                            clk,
  input  wire                            rst,

  /*
    * AXI Stream Data input
    */
  input  wire [CHANNELS*DATA_WIDTH_DATA-1:0]          s_axis_data_tdata,
  input  wire [CHANNELS-1:0]                          s_axis_data_tvalid,
  output wire [CHANNELS-1:0]                          s_axis_data_tready,
  input  wire [CHANNELS-1:0]                          s_axis_data_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]                 s_axis_data_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]               s_axis_data_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]               s_axis_data_tuser,

  /*
    * AXI Stream Grid input
    */
  input  wire [GRID_CHANNELS*DATA_WIDTH_DATA-1:0]     s_axis_grid_tdata,
  input  wire [GRID_CHANNELS-1:0]                     s_axis_grid_tvalid,
  output wire [GRID_CHANNELS-1:0]                     s_axis_grid_tready,
  input  wire [GRID_CHANNELS-1:0]                     s_axis_grid_tlast,
  input  wire [GRID_CHANNELS*ID_WIDTH-1:0]            s_axis_grid_tid,
  input  wire [GRID_CHANNELS*DEST_WIDTH-1:0]          s_axis_grid_tdest,
  input  wire [GRID_CHANNELS*USER_WIDTH-1:0]          s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]   s_axis_scale_tdata,
  input  wire [SCALE_CHANNELS-1:0]                    s_axis_scale_tvalid,
  output wire [SCALE_CHANNELS-1:0]                    s_axis_scale_tready,
  input  wire [SCALE_CHANNELS-1:0]                    s_axis_scale_tlast,
  input  wire [SCALE_CHANNELS*ID_WIDTH-1:0]           s_axis_scale_tid,
  input  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]         s_axis_scale_tdest,
  input  wire [SCALE_CHANNELS*USER_WIDTH-1:0]         s_axis_scale_tuser,

  /*
    * AXI Stream output
    */
  output wire [CHANNELS*DATA_WIDTH_RSLT-1:0]          m_axis_data_tdata,
  // output wire [CHANNELS*KEEP_WIDTH-1:0]               m_axis_data_tkeep,
  output wire [CHANNELS-1:0]                          m_axis_data_tvalid,
  input  wire [CHANNELS-1:0]                          m_axis_data_tready,
  output wire [CHANNELS-1:0]                          m_axis_data_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]                 m_axis_data_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]               m_axis_data_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]               m_axis_data_tuser
);

  // Internal Registers & Wires
  wire [CHANNELS*DATA_WIDTH_GRID-1:0]         s_axis_grid_tdata_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tvalid_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tready_int;
  wire [CHANNELS-1:0]                         s_axis_grid_tlast_int;
  wire [CHANNELS*ID_WIDTH-1:0]                s_axis_grid_tid_int;
  wire [CHANNELS*DEST_WIDTH-1:0]              s_axis_grid_tdest_int;
  wire [CHANNELS*USER_WIDTH-1:0]              s_axis_grid_tuser_int;
  
  wire [CHANNELS*DATA_WIDTH_SCALE-1:0]        s_axis_scale_tdata_int;
  wire [CHANNELS-1:0]                         s_axis_scale_tvalid_int;
  wire [CHANNELS-1:0]                         s_axis_scale_tready_int;
  wire [CHANNELS-1:0]                         s_axis_scale_tlast_int;
  wire [CHANNELS*ID_WIDTH-1:0]                s_axis_scale_tid_int;
  wire [CHANNELS*DEST_WIDTH-1:0]              s_axis_scale_tdest_int;
  wire [CHANNELS*USER_WIDTH-1:0]              s_axis_scale_tuser_int;
  
  wire [CHANNELS*DATA_WIDTH_SCALED_DIFF-1:0]  scaled_diff_axis_data_tdata;
  wire [CHANNELS-1:0]                         scaled_diff_axis_data_tvalid;
  wire [CHANNELS-1:0]                         scaled_diff_axis_data_tready;
  wire [CHANNELS-1:0]                         scaled_diff_axis_data_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]                scaled_diff_axis_data_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]              scaled_diff_axis_data_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]              scaled_diff_axis_data_tuser;

  genvar CHN;
  generate 

  if (SHARE_GRID && CHANNELS > 1) begin
    axis_broadcast #(
      .M_COUNT(CHANNELS),
      .DATA_WIDTH(DATA_WIDTH_GRID),
      .KEEP_ENABLE(0),
      .KEEP_WIDTH(1),
      .LAST_ENABLE(1),
      .ID_ENABLE(ID_ENABLE),
      .ID_WIDTH(ID_WIDTH),
      .DEST_ENABLE(DEST_ENABLE),
      .DEST_WIDTH(DEST_WIDTH),
      .USER_ENABLE(USER_ENABLE),
      .USER_WIDTH(USER_WIDTH)
    )
    axis_broadcast_inst (
      .clk(clk),
      .rst(rst),
      // AXI input
      .s_axis_tdata(s_axis_grid_tdata),
      .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_axis_grid_tvalid),
      .s_axis_tready(s_axis_grid_tready),
      .s_axis_tlast(s_axis_grid_tlast),
      .s_axis_tid(s_axis_grid_tid),
      .s_axis_tdest(s_axis_grid_tdest),
      .s_axis_tuser(s_axis_grid_tuser),
      // AXI outputs
      .m_axis_tdata(s_axis_grid_tdata_int),
      // .m_axis_tkeep(s_axis_grid_tkeep_int),
      .m_axis_tvalid(s_axis_grid_tvalid_int),
      .m_axis_tready(s_axis_grid_tready_int),
      .m_axis_tlast(s_axis_grid_tlast_int),
      .m_axis_tid(s_axis_grid_tid_int),
      .m_axis_tdest(s_axis_grid_tdest_int),
      .m_axis_tuser(s_axis_grid_tuser_int)
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

  if (SHARE_SCALE && CHANNELS > 1) begin
    axis_broadcast #(
      .M_COUNT(CHANNELS),
      .DATA_WIDTH(DATA_WIDTH_SCALE),
      .KEEP_ENABLE(0),
      .KEEP_WIDTH(1),
      .LAST_ENABLE(1),
      .ID_ENABLE(ID_ENABLE),
      .ID_WIDTH(ID_WIDTH),
      .DEST_ENABLE(DEST_ENABLE),
      .DEST_WIDTH(DEST_WIDTH),
      .USER_ENABLE(USER_ENABLE),
      .USER_WIDTH(USER_WIDTH)
    )
    axis_broadcast_inst (
      .clk(clk),
      .rst(rst),
      // AXI input
      .s_axis_tdata(s_axis_scale_tdata),
      .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_axis_scale_tvalid),
      .s_axis_tready(s_axis_scale_tready),
      .s_axis_tlast(s_axis_scale_tlast),
      .s_axis_tid(s_axis_scale_tid),
      .s_axis_tdest(s_axis_scale_tdest),
      .s_axis_tuser(s_axis_scale_tuser),
      // AXI outputs
      .m_axis_tdata(s_axis_scale_tdata_int),
      // .m_axis_tkeep(s_axis_scale_tkeep_int),
      .m_axis_tvalid(s_axis_scale_tvalid_int),
      .m_axis_tready(s_axis_scale_tready_int),
      .m_axis_tlast(s_axis_scale_tlast_int),
      .m_axis_tid(s_axis_scale_tid_int),
      .m_axis_tdest(s_axis_scale_tdest_int),
      .m_axis_tuser(s_axis_scale_tuser_int)
    );
  end else begin
    assign s_axis_scale_tdata_int   = s_axis_scale_tdata;
    assign s_axis_scale_tvalid_int  = s_axis_scale_tvalid;
    assign s_axis_scale_tready      = s_axis_scale_tready_int;
    assign s_axis_scale_tlast_int   = s_axis_scale_tlast;
    assign s_axis_scale_tid_int     = s_axis_scale_tid;
    assign s_axis_scale_tdest_int   = s_axis_scale_tdest;
    assign s_axis_scale_tuser_int   = s_axis_scale_tuser;
  end
    
  for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1 ) begin
    // Internal Registers & Wires
    // Data wires
    wire [DATA_WIDTH_DATA-1:0]  s_in_axis_data_tdata_slice, s_fifo_axis_data_tdata_slice; 
    // wire [KEEP_WIDTH-1:0]       s_in_axis_data_tkeep_slice, s_fifo_axis_data_tkeep_slice; 
    wire                        s_in_axis_data_tvalid_slice, s_fifo_axis_data_tvalid_slice; 
    wire                        s_in_axis_data_tready_slice, s_fifo_axis_data_tready_slice; 
    wire                        s_in_axis_data_tlast_slice, s_fifo_axis_data_tlast_slice; 
    wire [ID_WIDTH-1:0]         s_in_axis_data_tid_slice, s_fifo_axis_data_tid_slice; 
    wire [DEST_WIDTH-1:0]       s_in_axis_data_tdest_slice, s_fifo_axis_data_tdest_slice; 
    wire [USER_WIDTH-1:0]       s_in_axis_data_tuser_slice, s_fifo_axis_data_tuser_slice; 

    // Grid Wires
    wire [DATA_WIDTH_DATA-1:0]  s_in_axis_grid_tdata_slice, s_fifo_axis_grid_tdata_slice;
    // wire [KEEP_WIDTH-1:0]       s_in_axis_grid_tkeep_slice, s_fifo_axis_grid_tkeep_slice;
    wire                        s_in_axis_grid_tvalid_slice, s_fifo_axis_grid_tvalid_slice;
    wire                        s_in_axis_grid_tready_slice, s_fifo_axis_grid_tready_slice;
    wire                        s_in_axis_grid_tlast_slice, s_fifo_axis_grid_tlast_slice;
    wire [ID_WIDTH-1:0]         s_in_axis_grid_tid_slice, s_fifo_axis_grid_tid_slice;
    wire [DEST_WIDTH-1:0]       s_in_axis_grid_tdest_slice, s_fifo_axis_grid_tdest_slice;
    wire [USER_WIDTH-1:0]       s_in_axis_grid_tuser_slice, s_fifo_axis_grid_tuser_slice;

    // Scale Wires
    wire [DATA_WIDTH_SCALE-1:0] s_in_axis_scale_tdata_slice, s_fifo_axis_scale_tdata_slice;
    // wire [KEEP_WIDTH-1:0]       s_in_axis_scale_tkeep_slice, s_fifo_axis_scale_tkeep_slice;
    wire                        s_in_axis_scale_tvalid_slice, s_fifo_axis_scale_tvalid_slice;
    wire                        s_in_axis_scale_tready_slice, s_fifo_axis_scale_tready_slice;
    wire                        s_in_axis_scale_tlast_slice, s_fifo_axis_scale_tlast_slice;
    wire [ID_WIDTH-1:0]         s_in_axis_scale_tid_slice, s_fifo_axis_scale_tid_slice;
    wire [DEST_WIDTH-1:0]       s_in_axis_scale_tdest_slice, s_fifo_axis_scale_tdest_slice;
    wire [USER_WIDTH-1:0]       s_in_axis_scale_tuser_slice, s_fifo_axis_scale_tuser_slice;
  
    wire [DATA_WIDTH_RSLT-1:0]  scaled_diff_axis_data_tdata_slice;
    // wire [KEEP_WIDTH-1:0]       scaled_diff_axis_data_tkeep_slice;
    wire                        scaled_diff_axis_data_tvalid_slice;
    wire                        scaled_diff_axis_data_tready_slice;
    wire                        scaled_diff_axis_data_tlast_slice;
    wire [ID_WIDTH-1:0]         scaled_diff_axis_data_tid_slice;
    wire [DEST_WIDTH-1:0]       scaled_diff_axis_data_tdest_slice;
    wire [USER_WIDTH-1:0]       scaled_diff_axis_data_tuser_slice;
    
    assign s_in_axis_data_tdata_slice  = s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA -1: CHN*DATA_WIDTH_DATA];
    // assign s_in_axis_data_tkeep_slice  = s_axis_data_tkeep[(CHN+1)*KEEP_WIDTH_DATA-1 : CHN*KEEP_WIDTH_DATA];
    assign s_in_axis_data_tvalid_slice = s_axis_data_tvalid[CHN];
    assign s_axis_data_tready[CHN]     = s_in_axis_data_tready_slice;
    assign s_in_axis_data_tlast_slice  = s_axis_data_tlast[CHN];
    assign s_in_axis_data_tid_slice    = s_axis_data_tid  [(CHN+1)*ID_WIDTH   -1: CHN*ID_WIDTH];
    assign s_in_axis_data_tdest_slice  = s_axis_data_tdest[(CHN+1)*DEST_WIDTH -1: CHN*DEST_WIDTH];
    assign s_in_axis_data_tuser_slice  = s_axis_data_tuser[(CHN+1)*USER_WIDTH -1: CHN*USER_WIDTH];
  
    assign s_in_axis_grid_tdata_slice  = s_axis_grid_tdata_int[(CHN+1)*DATA_WIDTH_DATA-1 : CHN*DATA_WIDTH_DATA];
    // assign s_in_axis_grid_tkeep_slice  = s_axis_grid_tkeep_int[(CHN+1)*KEEP_WIDTH_DATA-1 : CHN*KEEP_WIDTH_DATA];
    assign s_in_axis_grid_tvalid_slice = s_axis_grid_tvalid_int[CHN];
    assign s_axis_grid_tready_int[CHN] = s_in_axis_grid_tready_slice;
    assign s_in_axis_grid_tlast_slice  = s_axis_grid_tlast_int[CHN];
    assign s_in_axis_grid_tid_slice    = s_axis_grid_tid_int  [(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH];
    assign s_in_axis_grid_tdest_slice  = s_axis_grid_tdest_int[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH];
    assign s_in_axis_grid_tuser_slice  = s_axis_grid_tuser_int[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH];
  
    assign s_in_axis_scale_tdata_slice  = s_axis_scale_tdata_int[(CHN+1)*DATA_WIDTH_DATA-1 : CHN*DATA_WIDTH_DATA];
    // assign s_in_axis_scale_tkeep_slice  = s_axis_scale_tkeep_int[(CHN+1)*KEEP_WIDTH_DATA-1 : CHN*KEEP_WIDTH_DATA];
    assign s_in_axis_scale_tvalid_slice = s_axis_scale_tvalid_int[CHN];
    assign s_axis_scale_tready_int[CHN] = s_in_axis_scale_tready_slice;
    assign s_in_axis_scale_tlast_slice  = s_axis_scale_tlast_int[CHN];
    assign s_in_axis_scale_tid_slice    = s_axis_scale_tid_int  [(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH];
    assign s_in_axis_scale_tdest_slice  = s_axis_scale_tdest_int[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH];
    assign s_in_axis_scale_tuser_slice  = s_axis_scale_tuser_int[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH];

    axis_srl_fifo #(
      // Width of AXI stream interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_DATA),
      // Propagate tkeep signal
      .KEEP_ENABLE(0),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(1),
      // Propagate tlast signal
      .LAST_ENABLE(1),
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
      // FIFO depth in cycles
      .DEPTH(8)
    ) axis_fifo_data_inst (
      .clk(clk),
      .rst(rst),

      /*
      * AXI input
      */
      .s_axis_tdata(s_in_axis_data_tdata_slice),
      .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_in_axis_data_tvalid_slice),
      .s_axis_tready(s_in_axis_data_tready_slice),
      .s_axis_tlast(s_in_axis_data_tlast_slice),
      .s_axis_tid(s_in_axis_data_tid_slice),
      .s_axis_tdest(s_in_axis_data_tdest_slice),
      .s_axis_tuser(s_in_axis_data_tuser_slice),

      /*
      * AXI output
      */
      .m_axis_tdata(s_fifo_axis_data_tdata_slice),
      // .m_axis_tkeep(s_fifo_axis_data_tkeep_slice),
      .m_axis_tvalid(s_fifo_axis_data_tvalid_slice),
      .m_axis_tready(s_fifo_axis_data_tready_slice),
      .m_axis_tlast(s_fifo_axis_data_tlast_slice),
      .m_axis_tid(s_fifo_axis_data_tid_slice),
      .m_axis_tdest(s_fifo_axis_data_tdest_slice),
      .m_axis_tuser(s_fifo_axis_data_tuser_slice)
    );
    
    axis_srl_fifo #(
      // Width of AXI stream interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_DATA),
      // Propagate tkeep signal
      .KEEP_ENABLE(0),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(1),
      // Propagate tlast signal
      .LAST_ENABLE(1),
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
      // FIFO depth in cycles
      .DEPTH(8)
    ) axis_fifo_grid_inst (
      .clk(clk),
      .rst(rst),

      /*
      * AXI input
      */
      .s_axis_tdata(s_in_axis_grid_tdata_slice),
      .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_in_axis_grid_tvalid_slice),
      .s_axis_tready(s_in_axis_grid_tready_slice),
      .s_axis_tlast(s_in_axis_grid_tlast_slice),
      .s_axis_tid(s_in_axis_grid_tid_slice),
      .s_axis_tdest(s_in_axis_grid_tdest_slice),
      .s_axis_tuser(s_in_axis_grid_tuser_slice),

      /*
      * AXI output
      */
      .m_axis_tdata(s_fifo_axis_grid_tdata_slice),
      // .m_axis_tkeep(s_fifo_axis_grid_tkeep_slice),
      .m_axis_tvalid(s_fifo_axis_grid_tvalid_slice),
      .m_axis_tready(s_fifo_axis_grid_tready_slice),
      .m_axis_tlast(s_fifo_axis_grid_tlast_slice),
      .m_axis_tid(s_fifo_axis_grid_tid_slice),
      .m_axis_tdest(s_fifo_axis_grid_tdest_slice),
      .m_axis_tuser(s_fifo_axis_grid_tuser_slice)
    );
    
    
    axis_srl_fifo #(
      // Width of AXI stream interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_DATA),
      // Propagate tkeep signal
      .KEEP_ENABLE(0),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(1),
      // Propagate tlast signal
      .LAST_ENABLE(1),
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
      // FIFO depth in cycles
      .DEPTH(8)
    ) axis_fifo_scale_inst (
      .clk(clk),
      .rst(rst),

      /*
      * AXI input
      */
      .s_axis_tdata(s_in_axis_scale_tdata_slice),
      .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_in_axis_scale_tvalid_slice),
      .s_axis_tready(s_in_axis_scale_tready_slice),
      .s_axis_tlast(s_in_axis_scale_tlast_slice),
      .s_axis_tid(s_in_axis_scale_tid_slice),
      .s_axis_tdest(s_in_axis_scale_tdest_slice),
      .s_axis_tuser(s_in_axis_scale_tuser_slice),

      /*
      * AXI output
      */
      .m_axis_tdata(s_fifo_axis_scale_tdata_slice),
      // .m_axis_tkeep(s_fifo_axis_scale_tkeep_slice),
      .m_axis_tvalid(s_fifo_axis_scale_tvalid_slice),
      .m_axis_tready(s_fifo_axis_scale_tready_slice),
      .m_axis_tlast(s_fifo_axis_scale_tlast_slice),
      .m_axis_tid(s_fifo_axis_scale_tid_slice),
      .m_axis_tdest(s_fifo_axis_scale_tdest_slice),
      .m_axis_tuser(s_fifo_axis_scale_tuser_slice)
    );
    
    SubMultAbs #(
      .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
      .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
      .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
      .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
      .DATA_WIDTH_RSLT(DATA_WIDTH_SCALED_DIFF),
      .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_SCALED_DIFF),
      .ID_ENABLE(ID_ENABLE),
      .ID_WIDTH(ID_WIDTH),
      .DEST_ENABLE(DEST_ENABLE),
      .DEST_WIDTH(DEST_WIDTH),
      .USER_ENABLE(USER_ENABLE),
      .USER_WIDTH(USER_WIDTH)
    ) SubMultAbs_inst (
      .clk(clk),
      .rst(rst),
      .s_axis_data_tdata(s_fifo_axis_data_tdata_slice),
      .s_axis_data_tvalid(s_fifo_axis_data_tvalid_slice),
      .s_axis_data_tready(s_fifo_axis_data_tready_slice),
      .s_axis_data_tlast(s_fifo_axis_data_tlast_slice),
      .s_axis_data_tid(s_fifo_axis_data_tid_slice),
      .s_axis_data_tdest(s_fifo_axis_data_tdest_slice),
      .s_axis_data_tuser(s_fifo_axis_data_tuser_slice),
      .s_axis_grid_tdata(s_fifo_axis_grid_tdata_slice),
      .s_axis_grid_tvalid(s_fifo_axis_grid_tvalid_slice),
      .s_axis_grid_tready(s_fifo_axis_grid_tready_slice),
      .s_axis_grid_tlast(s_fifo_axis_grid_tlast_slice),
      .s_axis_grid_tid(s_fifo_axis_grid_tid_slice),
      .s_axis_grid_tdest(s_fifo_axis_grid_tdest_slice),
      .s_axis_grid_tuser(s_fifo_axis_grid_tuser_slice),
      .s_axis_scale_tdata(s_fifo_axis_scale_tdata_slice),
      .s_axis_scale_tvalid(s_fifo_axis_scale_tvalid_slice),
      .s_axis_scale_tready(s_fifo_axis_scale_tready_slice),
      .s_axis_scale_tlast(s_fifo_axis_scale_tlast_slice),
      .s_axis_scale_tid(s_fifo_axis_scale_tid_slice),
      .s_axis_scale_tdest(s_fifo_axis_scale_tdest_slice),
      .s_axis_scale_tuser(s_fifo_axis_scale_tuser_slice),
      .m_axis_data_tdata(scaled_diff_axis_data_tdata_slice),
      .m_axis_data_tvalid(scaled_diff_axis_data_tvalid_slice),
      .m_axis_data_tready(scaled_diff_axis_data_tready_slice),
      .m_axis_data_tlast(scaled_diff_axis_data_tlast_slice),
      .m_axis_data_tid(scaled_diff_axis_data_tid_slice),
      .m_axis_data_tdest(scaled_diff_axis_data_tdest_slice),
      .m_axis_data_tuser(scaled_diff_axis_data_tuser_slice)
    );

    assign scaled_diff_axis_data_tdata [(CHN+1)*DATA_WIDTH_SCALED_DIFF-1 : CHN*DATA_WIDTH_SCALED_DIFF]  = scaled_diff_axis_data_tdata_slice;
    assign scaled_diff_axis_data_tlast [CHN] = scaled_diff_axis_data_tlast_slice;
    assign scaled_diff_axis_data_tvalid[CHN] = scaled_diff_axis_data_tvalid_slice;
    assign scaled_diff_axis_data_tready_slice= scaled_diff_axis_data_tready[CHN];
    assign scaled_diff_axis_data_tid   [(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH]      = scaled_diff_axis_data_tid_slice;
    assign scaled_diff_axis_data_tdest [(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH]  = scaled_diff_axis_data_tdest_slice;
    assign scaled_diff_axis_data_tuser [(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH]  = scaled_diff_axis_data_tuser_slice;
    
  end

  endgenerate

  Sech2Lutram #(
    .DATA_WIDTH_DATA(DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_SCALED_DIFF),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE_DATA(0),
    .KEEP_WIDTH_DATA(1),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .CHANNELS(CHANNELS),
    .ROM_DATA_PATH(ROM_DATA_PATH)
  ) Sech2Lutram_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(scaled_diff_axis_data_tdata),
    .s_axis_0_tlast(scaled_diff_axis_data_tlast),
    .s_axis_0_tvalid(scaled_diff_axis_data_tvalid),
    .s_axis_0_tready(scaled_diff_axis_data_tready),
    .s_axis_0_tid(scaled_diff_axis_data_tid),
    .s_axis_0_tdest(scaled_diff_axis_data_tdest),
    .s_axis_0_tuser(scaled_diff_axis_data_tuser),
    .m_axis_0_tdata(m_axis_data_tdata),
    // .m_axis_0_tkeep(m_axis_data_tkeep),
    .m_axis_0_tlast(m_axis_data_tlast),
    .m_axis_0_tvalid(m_axis_data_tvalid),
    .m_axis_0_tready(m_axis_data_tready),
    .m_axis_0_tid(m_axis_data_tid),
    .m_axis_0_tdest(m_axis_data_tdest),
    .m_axis_0_tuser(m_axis_data_tuser)
  );

endmodule

`resetall
