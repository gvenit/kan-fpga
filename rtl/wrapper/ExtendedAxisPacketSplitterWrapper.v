`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  ExtendedAxisPacketSplitterWrapper : Wrapper for ExtendedAxisPacketSplitter
 */

module ExtendedAxisPacketSplitterWrapper # (
  // Number of AXI-Stream channels to control
  parameter CHANNELS = 1,
  // Width of AXI stream Data interfaces in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
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
  // Width of Packet Size
  parameter PCKT_WIDTH = 32,
  // Allow locking module in its current state
  parameter ALLOW_LOCKS = 1,
  // Raise error flag if input packet non divisible
  parameter RAISE_NON_DIVISIBLE = 1
) (
  input  wire                             clk,
  input  wire                             rst,
  
  /*  
   * Control signals  
   */ 
  input  wire                             operation_start,
  input  wire [PCKT_WIDTH-1:0]            pckt_size,
    
  /*  
   * Input Interrupt signals  
   */ 
  input  wire                             external_error,
    
  /*  
   * Output Interrupt signals 
   */ 
  output wire                             operation_busy,
  output wire                             operation_complete,
  output wire                             operation_error,
  
  /*  
   * AXI Stream Data input  
   */ 
  input  wire [CHANNELS*DATA_WIDTH-1:0]   s_axis_tdata,
  input  wire [CHANNELS*KEEP_WIDTH-1:0]   s_axis_tkeep,
  input  wire [CHANNELS-1:0]              s_axis_tvalid,  
  output wire [CHANNELS-1:0]              s_axis_tready,
  input  wire [CHANNELS-1:0]              s_axis_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]     s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]   s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]   s_axis_tuser,
  
  /*  
   * AXI Stream output  
   */ 
  output wire [CHANNELS*DATA_WIDTH-1:0]   m_axis_tdata,
  output wire [CHANNELS*KEEP_WIDTH-1:0]   m_axis_tkeep,
  output wire [CHANNELS-1:0]              m_axis_tvalid,
  input  wire [CHANNELS-1:0]              m_axis_tready,
  output wire [CHANNELS-1:0]              m_axis_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]     m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]   m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]   m_axis_tuser
);

  ExtendedAxisPacketSplitter #(
    // Number of AXI-Stream channels to control
    .CHANNELS(CHANNELS),
    // Width of AXI stream Data interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
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
    // Width of Packet Size
    .PCKT_WIDTH(PCKT_WIDTH),
    // Allow locking module in its current state
    .ALLOW_LOCKS(ALLOW_LOCKS),
    // Raise error flag if input packet non divisible
    .RAISE_NON_DIVISIBLE(RAISE_NON_DIVISIBLE)
  ) wrapper (
    .clk                  (clk),
    .rst                  (rst),
    .operation_start      (operation_start),
    .pckt_size            (pckt_size),
    .external_error       (external_error),
    .operation_busy       (operation_busy),
    .operation_complete   (operation_complete),
    .operation_error      (operation_error),
    .s_axis_tdata         (s_axis_tdata),
    .s_axis_tkeep         (s_axis_tkeep),
    .s_axis_tvalid        (s_axis_tvalid),  
    .s_axis_tready        (s_axis_tready),
    .s_axis_tlast         (s_axis_tlast),
    .s_axis_tid           (s_axis_tid),
    .s_axis_tdest         (s_axis_tdest),
    .s_axis_tuser         (s_axis_tuser),
    .m_axis_tdata         (m_axis_tdata),
    .m_axis_tkeep         (m_axis_tkeep),
    .m_axis_tvalid        (m_axis_tvalid),
    .m_axis_tready        (m_axis_tready),
    .m_axis_tlast         (m_axis_tlast),
    .m_axis_tid           (m_axis_tid),
    .m_axis_tdest         (m_axis_tdest),
    .m_axis_tuser         (m_axis_tuser)
  );

endmodule

`resetall
