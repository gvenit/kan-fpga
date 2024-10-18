
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
  parameter FRACTIONAL_BITS_SCALE= 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_SCALED_DIFF = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_SCALED_DIFF = 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH_RSLT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = ((DATA_WIDTH_RSLT+7)/8),
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = 8,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = 8,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = 1,
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Unsigned Input
  parameter USE_UNSIGNED = 1,
  // Use Common Share Channel 
  parameter SHARE_SCALE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : CHANNELS
)
(
  input                             clk,
  input                             rst,

  /*
    * AXI Stream Data input
    */
  input  [CHANNELS*DATA_WIDTH_DATA-1:0] s_axis_data_tdata,
  input  [CHANNELS-1:0]                 s_axis_data_tvalid,
  output [CHANNELS-1:0]                 s_axis_data_tready,
  input  [CHANNELS-1:0]                 s_axis_data_tlast,
  input  [CHANNELS*ID_WIDTH-1:0]        s_axis_data_tid,
  input  [CHANNELS*DEST_WIDTH-1:0]      s_axis_data_tdest,
  input  [CHANNELS*USER_WIDTH-1:0]      s_axis_data_tuser,

  /*
    * AXI Stream Grid input
    */
  input  [CHANNELS*DATA_WIDTH_DATA-1:0] s_axis_grid_tdata,
  input  [CHANNELS-1:0]                 s_axis_grid_tvalid,
  output [CHANNELS-1:0]                 s_axis_grid_tready,
  input  [CHANNELS-1:0]                 s_axis_grid_tlast,
  input  [CHANNELS*ID_WIDTH-1:0]        s_axis_grid_tid,
  input  [CHANNELS*DEST_WIDTH-1:0]      s_axis_grid_tdest,
  input  [CHANNELS*USER_WIDTH-1:0]      s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]  s_axis_scale_tdata,
  input  [SCALE_CHANNELS-1:0]                   s_axis_scale_tvalid,
  output [SCALE_CHANNELS-1:0]                   s_axis_scale_tready,
  input  [SCALE_CHANNELS-1:0]                   s_axis_scale_tlast,
  input  [SCALE_CHANNELS*ID_WIDTH-1:0]          s_axis_scale_tid,
  input  [SCALE_CHANNELS*DEST_WIDTH-1:0]        s_axis_scale_tdest,
  input  [SCALE_CHANNELS*USER_WIDTH-1:0]        s_axis_scale_tuser,

  /*
    * AXI Stream output
    */
  output [CHANNELS*DATA_WIDTH_RSLT-1:0] m_axis_data_tdata,
  output [CHANNELS*KEEP_WIDTH-1:0]      m_axis_data_tkeep,
  output [CHANNELS-1:0]                 m_axis_data_tvalid,
  input  [CHANNELS-1:0]                 m_axis_data_tready,
  output [CHANNELS-1:0]                 m_axis_data_tlast,
  output [CHANNELS*ID_WIDTH-1:0]        m_axis_data_tid,
  output [CHANNELS*DEST_WIDTH-1:0]      m_axis_data_tdest,
  output [CHANNELS*USER_WIDTH-1:0]      m_axis_data_tuser
);


  // Internal Registers & Wires
  wire [CHANNELS*DATA_WIDTH_SCALE-1:0] s_axis_scale_tdata_int;
  wire [CHANNELS-1:0]                  s_axis_scale_tvalid_int;
  wire [CHANNELS-1:0]                  s_axis_scale_tready_int;
  wire [CHANNELS-1:0]                  s_axis_scale_tlast_int;
  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_scale_tid_int;
  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_scale_tdest_int;
  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_scale_tuser_int;
  
  wire [CHANNELS*DATA_WIDTH_SCALED_DIFF-1:0] scaled_diff_axis_data_tdata;
  wire [CHANNELS-1:0]                        scaled_diff_axis_data_tvalid;
  wire [CHANNELS-1:0]                        scaled_diff_axis_data_tready;
  wire [CHANNELS-1:0]                        scaled_diff_axis_data_tlast;
  wire [CHANNELS*ID_WIDTH-1:0]               scaled_diff_axis_data_tid;
  wire [CHANNELS*DEST_WIDTH-1:0]             scaled_diff_axis_data_tdest;
  wire [CHANNELS*USER_WIDTH-1:0]             scaled_diff_axis_data_tuser;

  genvar CHN;
  generate 

  if (SHARE_SCALE) begin

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
      // .s_axis_tkeep(s_axis_scale_tkeep),
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
  end
  else begin
    assign s_axis_scale_tdata_int = s_axis_scale_tdata;
    assign s_axis_scale_tvalid_int  = s_axis_scale_tvalid;
    assign s_axis_scale_tready_int  = s_axis_scale_tready;
    assign s_axis_scale_tlast_int = s_axis_scale_tlast;
    assign s_axis_scale_tid_int = s_axis_scale_tid;
    assign s_axis_scale_tdest_int = s_axis_scale_tdest;
    assign s_axis_scale_tuser_int = s_axis_scale_tuser;
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
  
    assign s_in_axis_grid_tdata_slice  = s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1 : CHN*DATA_WIDTH_DATA];
    // assign s_in_axis_grid_tkeep_slice  = s_axis_grid_tkeep[(CHN+1)*KEEP_WIDTH_DATA-1 : CHN*KEEP_WIDTH_DATA];
    assign s_in_axis_grid_tvalid_slice = s_axis_grid_tvalid[CHN];
    assign s_axis_grid_tready[CHN]     = s_in_axis_grid_tready_slice;
    assign s_in_axis_grid_tlast_slice  = s_axis_grid_tlast[CHN];
    assign s_in_axis_grid_tid_slice    = s_axis_grid_tid  [(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH];
    assign s_in_axis_grid_tdest_slice  = s_axis_grid_tdest[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH];
    assign s_in_axis_grid_tuser_slice  = s_axis_grid_tuser[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH];
  
    assign s_in_axis_scale_tdata_slice  = s_axis_scale_tdata_int[(CHN+1)*DATA_WIDTH_DATA-1 : CHN*DATA_WIDTH_DATA];
    // assign s_in_axis_scale_tkeep_slice  = s_axis_scale_tkeep_int[(CHN+1)*KEEP_WIDTH_DATA-1 : CHN*KEEP_WIDTH_DATA];
    assign s_in_axis_scale_tvalid_slice = s_axis_scale_tvalid_int[CHN];
    assign s_axis_scale_tready_int[CHN] = s_in_axis_scale_tready_slice;
    assign s_in_axis_scale_tlast_slice  = s_axis_scale_tlast_int[CHN];
    assign s_in_axis_scale_tid_slice    = s_axis_scale_tid_int  [(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH];
    assign s_in_axis_scale_tdest_slice  = s_axis_scale_tdest_int[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH];
    assign s_in_axis_scale_tuser_slice  = s_axis_scale_tuser_int[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH];

    axis_fifo #(
    // FIFO depth in words
    // KEEP_WIDTH words per cycle if KEEP_ENABLE set
    // Rounded up to nearest power of 2 cycles
    .DEPTH(8),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    .KEEP_ENABLE(0),
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
    // number of RAM pipeline registers
    .RAM_PIPELINE(1),
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    .OUTPUT_FIFO_ENABLE(0),
    // Frame FIFO mode - operate on frames instead of cycles
    // When set, m_axis_tvalid will not be deasserted within a frame
    // Requires LAST_ENABLE set
    .FRAME_FIFO(0),
    // tuser value for bad frame marker
    .USER_BAD_FRAME_VALUE(1'b1),
    // tuser mask for bad frame marker
    .USER_BAD_FRAME_MASK(1'b1),
    // Drop frames larger than FIFO
    // Requires FRAME_FIFO set
    .DROP_OVERSIZE_FRAME(0),
    // Drop frames marked bad
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_BAD_FRAME(0),
    // Drop incoming frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_WHEN_FULL(0),
    // Mark incoming frames as bad frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO to be clear
    .MARK_WHEN_FULL(0),
    // Enable pause request input
    .PAUSE_ENABLE(0),
    // Pause between frames
    .FRAME_PAUSE(0)
    )
    axis_fifo_data_inst(
    .clk(clk),
    .rst(rst),

    /*
     * AXI input
     */
    .s_axis_tdata(s_in_axis_data_tdata_slice),
    // .s_axis_tkeep(s_in_axis_data_tkeep_slice),
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
    .m_axis_tuser(s_fifo_axis_data_tuser_slice),

    /*
     * Pause
     */
    .pause_req(1'b0)
    );
    
    axis_fifo #(
    // FIFO depth in words
    // KEEP_WIDTH words per cycle if KEEP_ENABLE set
    // Rounded up to nearest power of 2 cycles
    .DEPTH(8),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    .KEEP_ENABLE(0),
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
    // number of RAM pipeline registers
    .RAM_PIPELINE(1),
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    .OUTPUT_FIFO_ENABLE(0),
    // Frame FIFO mode - operate on frames instead of cycles
    // When set, m_axis_tvalid will not be deasserted within a frame
    // Requires LAST_ENABLE set
    .FRAME_FIFO(0),
    // tuser value for bad frame marker
    .USER_BAD_FRAME_VALUE(1'b1),
    // tuser mask for bad frame marker
    .USER_BAD_FRAME_MASK(1'b1),
    // Drop frames larger than FIFO
    // Requires FRAME_FIFO set
    .DROP_OVERSIZE_FRAME(0),
    // Drop frames marked bad
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_BAD_FRAME(0),
    // Drop incoming frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_WHEN_FULL(0),
    // Mark incoming frames as bad frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO to be clear
    .MARK_WHEN_FULL(0),
    // Enable pause request input
    .PAUSE_ENABLE(0),
    // Pause between frames
    .FRAME_PAUSE(0)
    )
    axis_fifo_grid_inst(
    .clk(clk),
    .rst(rst),

    /*
     * AXI input
     */
    .s_axis_tdata(s_in_axis_grid_tdata_slice),
    // .s_axis_tkeep(s_in_axis_grid_tkeep_slice),
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
    .m_axis_tuser(s_fifo_axis_grid_tuser_slice),

    /*
     * Pause
     */
    .pause_req(1'b0)
    );
    
    axis_fifo #(
    // FIFO depth in words
    // KEEP_WIDTH words per cycle if KEEP_ENABLE set
    // Rounded up to nearest power of 2 cycles
    .DEPTH(8),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_SCALE),
    // Propagate tkeep signal
    // If disabled, tkeep assumed to be 1'b1
    .KEEP_ENABLE(0),
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
    // number of RAM pipeline registers
    .RAM_PIPELINE(1),
    // use output FIFO
    // When set, the RAM read enable and pipeline clock enables are removed
    .OUTPUT_FIFO_ENABLE(0),
    // Frame FIFO mode - operate on frames instead of cycles
    // When set, m_axis_tvalid will not be deasserted within a frame
    // Requires LAST_ENABLE set
    .FRAME_FIFO(0),
    // tuser value for bad frame marker
    .USER_BAD_FRAME_VALUE(1'b1),
    // tuser mask for bad frame marker
    .USER_BAD_FRAME_MASK(1'b1),
    // Drop frames larger than FIFO
    // Requires FRAME_FIFO set
    .DROP_OVERSIZE_FRAME(0),
    // Drop frames marked bad
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_BAD_FRAME(0),
    // Drop incoming frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO and DROP_OVERSIZE_FRAME set
    .DROP_WHEN_FULL(0),
    // Mark incoming frames as bad frames when full
    // When set, s_axis_tready is always asserted
    // Requires FRAME_FIFO to be clear
    .MARK_WHEN_FULL(0),
    // Enable pause request input
    .PAUSE_ENABLE(0),
    // Pause between frames
    .FRAME_PAUSE(0)
    )
    axis_fifo_scale_inst(
    .clk(clk),
    .rst(rst),

    /*
     * AXI input
     */
    .s_axis_tdata(s_in_axis_scale_tdata_slice),
    // .s_axis_tkeep(s_in_axis_scale_tkeep_slice),
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
    .m_axis_tuser(s_fifo_axis_scale_tuser_slice),

    /*
     * Pause
     */
    .pause_req(1'b0)
    );
    
    SubMultAbs
    #(
      .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
      .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
      .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
      .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
      .DATA_WIDTH_RSLT(DATA_WIDTH_SCALED_DIFF),
      .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_SCALED_DIFF),
      .KEEP_ENABLE(KEEP_ENABLE),
      .KEEP_WIDTH(KEEP_WIDTH),
      .ID_ENABLE(ID_ENABLE),
      .ID_WIDTH(ID_WIDTH),
      .DEST_ENABLE(DEST_ENABLE),
      .DEST_WIDTH(DEST_WIDTH),
      .USER_ENABLE(USER_ENABLE),
      .USER_WIDTH(USER_WIDTH)
    )
    SubMultAbs_inst
    (
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

  Sech2Lutram
  #(
    .DATA_WIDTH_DATA(DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_SCALED_DIFF),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE_DATA(0),
    .KEEP_WIDTH_DATA(1),
    .KEEP_ENABLE_RSLT(KEEP_ENABLE),
    .KEEP_WIDTH_RSLT(KEEP_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .CHANNELS(CHANNELS),
    .USE_UNSIGNED(USE_UNSIGNED)
  )
  Sech2Lutram_inst
  (
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
    .m_axis_0_tkeep(m_axis_data_tkeep),
    .m_axis_0_tlast(m_axis_data_tlast),
    .m_axis_0_tvalid(m_axis_data_tvalid),
    .m_axis_0_tready(m_axis_data_tready),
    .m_axis_0_tid(m_axis_data_tid),
    .m_axis_0_tdest(m_axis_data_tdest),
    .m_axis_0_tuser(m_axis_data_tuser)
  );

endmodule

`resetall
