`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  SubMultAbs : Accepts three input AXI-Stream frames and returns
 *    the result abs((x-grid)*scale).
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */

module SubMultAbs #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scale
  parameter FRACTIONAL_BITS_SCALE= 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH_RSLT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH_RSLT+7)/8) : 1,
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
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1
) (
  input  wire                            clk,
  input  wire                            rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_WIDTH_DATA-1:0] s_axis_data_tdata,
  input  wire                       s_axis_data_tvalid,
  output wire                       s_axis_data_tready,
  input  wire                       s_axis_data_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_data_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_data_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_data_tuser,

  /*
    * AXI Stream Grid input
    */
  input  wire [DATA_WIDTH_DATA-1:0] s_axis_grid_tdata,
  input  wire                       s_axis_grid_tvalid,
  output wire                       s_axis_grid_tready,
  input  wire                       s_axis_grid_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_grid_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_grid_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [DATA_WIDTH_SCALE-1:0]  s_axis_scale_tdata,
  input  wire                         s_axis_scale_tvalid,
  output wire                         s_axis_scale_tready,
  input  wire                         s_axis_scale_tlast,
  input  wire [ID_WIDTH-1:0]          s_axis_scale_tid,
  input  wire [DEST_WIDTH-1:0]        s_axis_scale_tdest,
  input  wire [USER_WIDTH-1:0]        s_axis_scale_tuser,

  /*
    * AXI Stream output
    */
  output wire [DATA_WIDTH_RSLT-1:0] m_axis_data_tdata,
  output wire [KEEP_WIDTH-1:0]      m_axis_data_tkeep,
  output wire                       m_axis_data_tvalid,
  input  wire                       m_axis_data_tready,
  output wire                       m_axis_data_tlast,
  output wire [ID_WIDTH-1:0]        m_axis_data_tid,
  output wire [DEST_WIDTH-1:0]      m_axis_data_tdest,
  output wire [USER_WIDTH-1:0]      m_axis_data_tuser

  // // Error Signals
  // output                  err_unalligned_data,
  // output                  err_unalligned_scale
);
  `define abs(signal) ($signed(signal) < 0) ? -$signed(signal) : signal

  wire signed [DATA_WIDTH_RSLT:0] signed_rslt;

  assign m_axis_data_tdata = `abs(signed_rslt)[DATA_WIDTH_RSLT-1:0];

  SubMult
  #(
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT+1),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE(KEEP_ENABLE),
    .KEEP_WIDTH(KEEP_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH)
  )
  SubMult_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tid(s_axis_data_tid),
    .s_axis_data_tdest(s_axis_data_tdest),
    .s_axis_data_tuser(s_axis_data_tuser),
    .s_axis_grid_tdata(s_axis_grid_tdata),
    .s_axis_grid_tvalid(s_axis_grid_tvalid),
    .s_axis_grid_tready(s_axis_grid_tready),
    .s_axis_grid_tlast(s_axis_grid_tlast),
    .s_axis_grid_tid(s_axis_grid_tid),
    .s_axis_grid_tdest(s_axis_grid_tdest),
    .s_axis_grid_tuser(s_axis_grid_tuser),
    .s_axis_scale_tdata(s_axis_scale_tdata),
    .s_axis_scale_tvalid(s_axis_scale_tvalid),
    .s_axis_scale_tready(s_axis_scale_tready),
    .s_axis_scale_tlast(s_axis_scale_tlast),
    .s_axis_scale_tid(s_axis_scale_tid),
    .s_axis_scale_tdest(s_axis_scale_tdest),
    .s_axis_scale_tuser(s_axis_scale_tuser),
    .m_axis_data_tdata(signed_rslt),
    .m_axis_data_tkeep(m_axis_data_tkeep),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tid(m_axis_data_tid),
    .m_axis_data_tdest(m_axis_data_tdest),
    .m_axis_data_tuser(m_axis_data_tuser)
  );

endmodule

`resetall
