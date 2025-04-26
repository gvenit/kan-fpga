`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  BAPJWrapper: Wrapper for BatchedAxisPacketJoiner 
 *    Accepts multiple input AXI-Stream Packets 
 *    and outputs a multiple Axi-Stream Packets in a single channel. 
 *    The output packet is a concatenation of the input packets. 
 *    The module awaits data from the specified channels, starting 
 *    from the first channel.
 */
`include "headers/utils.vh"

module BAPJWrapper #(
  // Number of Channels
  parameter CHANNELS = 2,
  // Number of Channels
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Data interfaces in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter S_ID_WIDTH = (ID_ENABLE) ? 8 : 1,
  // tid signal width output
  parameter M_ID_WIDTH = ((ID_ENABLE) ? S_ID_WIDTH : 0) + `LOG2(BATCH_SIZE),
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1
) (
  input  wire                                         clk,
  input  wire                                         rst,

  /*
   * Control signals
   */
  input  wire                                         operation_start,
  input  wire [CHANNELS-1:0]                          use_channels,
  input  wire [BATCH_SIZE-1:0]                        use_batch,
  
  /*
   * Input Interrupt signals
   */
  input  wire                                         interrupt,
  
  /*
   * Output Interrupt signals
   */
  output wire                                         operation_busy,
  output wire                                         operation_complete,
  output wire                                         operation_error,
  output wire                                         transmission,       // Active high if bus transmitted data in the current cycle

  /*
   * AXI Stream Data input
   */
  input  wire [BATCH_SIZE*CHANNELS*DATA_WIDTH-1:0]    s_axis_tdata,
  input  wire [BATCH_SIZE*CHANNELS*KEEP_WIDTH-1:0]    s_axis_tkeep,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tvalid,  
  output wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tready,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tlast,
  input  wire [BATCH_SIZE*CHANNELS*S_ID_WIDTH-1:0]    s_axis_tid,
  input  wire [BATCH_SIZE*CHANNELS*DEST_WIDTH-1:0]    s_axis_tdest,
  input  wire [BATCH_SIZE*CHANNELS*USER_WIDTH-1:0]    s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [DATA_WIDTH-1:0]                        m_axis_tdata,
  output wire [KEEP_WIDTH-1:0]                        m_axis_tkeep,
  output wire                                         m_axis_tvalid,
  input  wire                                         m_axis_tready,
  output wire                                         m_axis_tlast,
  output wire [M_ID_WIDTH-1:0]                        m_axis_tid,
  output wire [DEST_WIDTH-1:0]                        m_axis_tdest,
  output wire [USER_WIDTH-1:0]                        m_axis_tuser
);

BatchedAxisPacketJoiner #(
  .CHANNELS(CHANNELS),
  .BATCH_SIZE(BATCH_SIZE),
  .DATA_WIDTH(DATA_WIDTH),
  .KEEP_ENABLE(KEEP_ENABLE),
  .KEEP_WIDTH(KEEP_WIDTH),
  .ID_ENABLE(ID_ENABLE),
  .S_ID_WIDTH(S_ID_WIDTH),
  .M_ID_WIDTH(M_ID_WIDTH),
  .DEST_ENABLE(DEST_ENABLE),
  .DEST_WIDTH(DEST_WIDTH),
  .USER_ENABLE(USER_ENABLE),
  .USER_WIDTH(USER_WIDTH)
) wrapper (
  .clk                (clk),
  .rst                (rst),
  .operation_start    (operation_start),
  .use_channels       (use_channels),
  .use_batch          (use_batch),
  .interrupt          (interrupt),
  .operation_busy     (operation_busy),
  .operation_complete (operation_complete),
  .operation_error    (operation_error),
  .transmission       (transmission),       // Active high if bus transmitted data in the current cycle
  .s_axis_tdata       (s_axis_tdata),
  .s_axis_tkeep       (s_axis_tkeep),
  .s_axis_tvalid      (s_axis_tvalid),  
  .s_axis_tready      (s_axis_tready),
  .s_axis_tlast       (s_axis_tlast),
  .s_axis_tid         (s_axis_tid),
  .s_axis_tdest       (s_axis_tdest),
  .s_axis_tuser       (s_axis_tuser),
  .m_axis_tdata       (m_axis_tdata),
  .m_axis_tkeep       (m_axis_tkeep),
  .m_axis_tvalid      (m_axis_tvalid),
  .m_axis_tready      (m_axis_tready),
  .m_axis_tlast       (m_axis_tlast),
  .m_axis_tid         (m_axis_tid),
  .m_axis_tdest       (m_axis_tdest),
  .m_axis_tuser       (m_axis_tuser)
);

endmodule

`resetall
