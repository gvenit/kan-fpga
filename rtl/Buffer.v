
`resetall
`timescale 1ns/1ps
`default_nettype none

module Buffer #(
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Width of AXI stream Input interface in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
  // Propagate tlast signal
  parameter LAST_ENABLE = 1,
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
  // Register type
  // 0 to bypass, 1 for simple buffer, 2 for skid buffer
  parameter REG_TYPE = 2
) (
  input  wire                                 clk,
  input  wire                                 rst,
  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]       s_axis_tdata,
  input  wire [CHANNELS*KEEP_WIDTH-1:0]       s_axis_tkeep,
  input  wire [CHANNELS-1:0]                  s_axis_tvalid,
  output wire [CHANNELS-1:0]                  s_axis_tready,
  input  wire [CHANNELS-1:0]                  s_axis_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*DATA_WIDTH-1:0]       m_axis_tdata,
  output wire [CHANNELS*KEEP_WIDTH-1:0]       m_axis_tkeep,
  output wire [CHANNELS-1:0]                  m_axis_tvalid,
  input  wire [CHANNELS-1:0]                  m_axis_tready,
  output wire [CHANNELS-1:0]                  m_axis_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]         m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]       m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]       m_axis_tuser
);

generate
  genvar CHN;
  for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1) begin
    axis_register #(
      .DATA_WIDTH     (DATA_WIDTH),
      .KEEP_ENABLE    (KEEP_ENABLE),
      .KEEP_WIDTH     (KEEP_WIDTH),
      .LAST_ENABLE    (LAST_ENABLE),
      .ID_ENABLE      (ID_ENABLE),
      .ID_WIDTH       (ID_WIDTH),
      .DEST_ENABLE    (DEST_ENABLE),
      .DEST_WIDTH     (DEST_WIDTH),
      .USER_ENABLE    (USER_ENABLE),
      .USER_WIDTH     (USER_WIDTH),
      .REG_TYPE       (REG_TYPE)
    ) reg_i_inst (
      .clk            (clk),
      .rst            (rst),
      .s_axis_tdata   (s_axis_tdata     [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .s_axis_tkeep   (s_axis_tkeep     [CHN*KEEP_WIDTH +: KEEP_WIDTH]),
      .s_axis_tvalid  (s_axis_tvalid    [CHN]),
      .s_axis_tready  (s_axis_tready    [CHN]),
      .s_axis_tlast   (s_axis_tlast     [CHN]),
      .s_axis_tid     (s_axis_tid       [CHN*ID_WIDTH   +: ID_WIDTH]),
      .s_axis_tdest   (s_axis_tdest     [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .s_axis_tuser   (s_axis_tuser     [CHN*USER_WIDTH +: USER_WIDTH]),
      .m_axis_tdata   (m_axis_tdata     [CHN*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tkeep   (m_axis_tkeep     [CHN*KEEP_WIDTH +: KEEP_WIDTH]),
      .m_axis_tvalid  (m_axis_tvalid    [CHN]),
      .m_axis_tready  (m_axis_tready    [CHN]),
      .m_axis_tlast   (m_axis_tlast     [CHN]),
      .m_axis_tid     (m_axis_tid       [CHN*ID_WIDTH   +: ID_WIDTH]),
      .m_axis_tdest   (m_axis_tdest     [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser   (m_axis_tuser     [CHN*USER_WIDTH +: USER_WIDTH])
    );
  end
endgenerate

endmodule

`resetall
