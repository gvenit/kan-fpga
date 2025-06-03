`resetall
`timescale 1ns / 1ps
`default_nettype none

module ROMWrapper #(
  // Width of AXI stream Input interfaces in bits
  parameter ADDR_WIDTH = 8,
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 8,
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "",
  // Propagate tlast signal
  parameter LAST_ENABLE = 1,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = 8,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = 8,
  // Propagate tuser signal
  parameter USER_ENABLE = 1,
  // tuser signal width
  parameter USER_WIDTH = 1,
  // Register type
  // 0 to bypass, 1 for simple buffer, 2 for skid buffer
  parameter REG_TYPE = 2
) (
  input  wire                                 clk,
  input  wire                                 rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*ADDR_WIDTH-1:0]       s_axis_tdata,
  input  wire [CHANNELS-1:0]                  s_axis_tlast,
  input  wire [CHANNELS-1:0]                  s_axis_tvalid,
  output wire [CHANNELS-1:0]                  s_axis_tready,
  input  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*DATA_WIDTH-1:0]       m_axis_tdata,
  output wire [CHANNELS-1:0]                  m_axis_tlast,
  output wire [CHANNELS-1:0]                  m_axis_tvalid,
  input  wire [CHANNELS-1:0]                  m_axis_tready,
  output wire [CHANNELS*ID_WIDTH-1:0]         m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]       m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]       m_axis_tuser
);
  ROM #(
    .ADDR_WIDTH             (ADDR_WIDTH),
    .DATA_WIDTH             (DATA_WIDTH),
    .CHANNELS               (CHANNELS),
    .ROM_DATA_PATH          (ROM_DATA_PATH),
    .LAST_ENABLE            (LAST_ENABLE),
    .ID_ENABLE              (ID_ENABLE),
    .ID_WIDTH               (ID_WIDTH),
    .DEST_ENABLE            (DEST_ENABLE),
    .DEST_WIDTH             (DEST_WIDTH),
    .USER_ENABLE            (USER_ENABLE),
    .USER_WIDTH             (USER_WIDTH),
    .REG_TYPE               (REG_TYPE)
  ) wrapper (
    .clk                    (clk),
    .rst                    (rst),
    .s_axis_tdata           (s_axis_tdata),
    .s_axis_tlast           (s_axis_tlast),
    .s_axis_tvalid          (s_axis_tvalid),
    .s_axis_tready          (s_axis_tready),
    .s_axis_tid             (s_axis_tid),
    .s_axis_tdest           (s_axis_tdest),
    .s_axis_tuser           (s_axis_tuser),
    .m_axis_tdata           (m_axis_tdata),
    .m_axis_tlast           (m_axis_tlast),
    .m_axis_tvalid          (m_axis_tvalid),
    .m_axis_tready          (m_axis_tready),
    .m_axis_tid             (m_axis_tid),
    .m_axis_tdest           (m_axis_tdest),
    .m_axis_tuser           (m_axis_tuser)
  );
  
endmodule

`resetall
