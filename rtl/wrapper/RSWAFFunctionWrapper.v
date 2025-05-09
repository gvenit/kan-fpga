`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  RSWAFFunction : Accepts three input AXI-Stream frames and returns the
 *    result sech^2(scale * (x-grid))
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */

module RSWAFFunctionWrapper #
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

  RSWAFFunction #(
    // Width of AXI stream Input Data & Grid interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Fractional bits of input data & grid
    .DATA_FRACTIONAL_BITS(DATA_FRACTIONAL_BITS),
    // Width of AXI stream Scale interface in bits
    .SCALE_WIDTH(SCALE_WIDTH),
    // Fractional bits of input scale
    .SCALE_FRACTIONAL_BITS(SCALE_FRACTIONAL_BITS),
    // Width of AXI stream Output Data interface in bits
    .SCALED_DIFF_WIDTH(SCALED_DIFF_WIDTH),
    // Fractional bits of output data
    .SCALED_DIFF_FRACTIONAL_BITS(SCALED_DIFF_FRACTIONAL_BITS),
    // Width of AXI stream Output Data interface in bits
    .RSLT_WIDTH(RSLT_WIDTH),
    // Fractional bits of output data
    .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
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
    // Number of Independent AXI-Stream Channels
    .CHANNELS(CHANNELS),
    // Use Common Share Channel 
    .SCALE_SHARE(SCALE_SHARE),
    // Scale Channels
    .SCALE_CHANNELS(SCALE_CHANNELS),
    // Use Common Grid Channel 
    .GRID_SHARE(GRID_SHARE),
    // Grid Channels
    .GRID_CHANNELS(GRID_CHANNELS),
    // Path to ROM Data
    .ROM_DATA_PATH(ROM_DATA_PATH),
    // Use FIFO for inputs
    .FIFO_DEPTH(FIFO_DEPTH)
  ) act_func_inst (
    .clk                  (clk),
    .rst                  (rst),
    .s_axis_data_tdata    (s_axis_data_tdata),
    .s_axis_data_tvalid   (s_axis_data_tvalid),
    .s_axis_data_tready   (s_axis_data_tready),
    .s_axis_data_tlast    (s_axis_data_tlast),
    .s_axis_data_tid      (s_axis_data_tid),
    .s_axis_data_tdest    (s_axis_data_tdest),
    .s_axis_data_tuser    (s_axis_data_tuser),
    .s_axis_grid_tdata    (s_axis_grid_tdata),
    .s_axis_grid_tvalid   (s_axis_grid_tvalid),
    .s_axis_grid_tready   (s_axis_grid_tready),
    .s_axis_grid_tlast    (s_axis_grid_tlast),
    .s_axis_grid_tid      (s_axis_grid_tid),
    .s_axis_grid_tdest    (s_axis_grid_tdest),
    .s_axis_grid_tuser    (s_axis_grid_tuser),
    .s_axis_scle_tdata    (s_axis_scle_tdata),
    .s_axis_scle_tvalid   (s_axis_scle_tvalid),
    .s_axis_scle_tready   (s_axis_scle_tready),
    .s_axis_scle_tlast    (s_axis_scle_tlast),
    .s_axis_scle_tid      (s_axis_scle_tid),
    .s_axis_scle_tdest    (s_axis_scle_tdest),
    .s_axis_scle_tuser    (s_axis_scle_tuser),
    .m_axis_data_tdata    (m_axis_data_tdata),
    .m_axis_data_tvalid   (m_axis_data_tvalid),
    .m_axis_data_tready   (m_axis_data_tready),
    .m_axis_data_tlast    (m_axis_data_tlast),
    .m_axis_data_tid      (m_axis_data_tid),
    .m_axis_data_tdest    (m_axis_data_tdest),
    .m_axis_data_tuser    (m_axis_data_tuser)
  );
endmodule

`resetall
