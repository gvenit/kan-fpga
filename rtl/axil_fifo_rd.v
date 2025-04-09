`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Lite FIFO (read)
 */
module axil_fifo_rd #
(
  // Width of data bus in bits
  parameter DATA_WIDTH = 32,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of wstrb (width of data bus in words)
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  // Read data FIFO depth (cycles)
  parameter FIFO_DEPTH = 32,
  // Hold read address until space available in FIFO for data, if possible
  parameter FIFO_DELAY = 0
)
(
  input  wire                     clk,
  input  wire                     rst,

  /*
    * AXI-Lite slave interface
    */
  input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
  input  wire [2:0]               s_axil_arprot,
  input  wire                     s_axil_arvalid,
  output wire                     s_axil_arready,
  output wire [DATA_WIDTH-1:0]    s_axil_rdata,
  output wire [1:0]               s_axil_rresp,
  output wire                     s_axil_rvalid,
  input  wire                     s_axil_rready,

  /*
    * AXI-Lite master interface
    */
  output wire [ADDR_WIDTH-1:0]    m_axil_araddr,
  output wire [2:0]               m_axil_arprot,
  output wire                     m_axil_arvalid,
  input  wire                     m_axil_arready,
  input  wire [DATA_WIDTH-1:0]    m_axil_rdata,
  input  wire [1:0]               m_axil_rresp,
  input  wire                     m_axil_rvalid,
  output wire                     m_axil_rready
);
  /*
   * AXI4 FIFO (read)
   */
  axi_fifo_rd #
  (
    // Width of data bus in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Width of address bus in bits
    .ADDR_WIDTH(ADDR_WIDTH),
    // Width of wstrb (width of data bus in words)
    .STRB_WIDTH(STRB_WIDTH),
    // Width of ID signal
    .ID_WIDTH(1),
    // Propagate aruser signal
    .ARUSER_ENABLE(1'b0),
    // Width of aruser signal
    .ARUSER_WIDTH(1),
    // Propagate ruser signal
    .RUSER_ENABLE(1'b0),
    // Width of ruser signal
    .RUSER_WIDTH(1),
    // Read data FIFO depth (cycles)
    .FIFO_DEPTH(FIFO_DEPTH),
    // Hold read address until space available in FIFO for data, if possible
    .FIFO_DELAY(FIFO_DELAY)
  ) axi_fifo_rd_inst
  (
    .clk            (clk),
    .rst            (rst),
    .s_axi_arid     (1'b0),
    .s_axi_araddr   (s_axil_araddr),
    .s_axi_arlen    (8'b0),
    .s_axi_arsize   (3'b0),
    .s_axi_arburst  (2'b0),
    .s_axi_arlock   (1'b0),
    .s_axi_arcache  (4'b0),
    .s_axi_arprot   (s_axil_arprot),
    .s_axi_arqos    (4'b0),
    .s_axi_arregion (4'b0),
    .s_axi_aruser   (1'b0),
    .s_axi_arvalid  (s_axil_arvalid),
    .s_axi_arready  (s_axil_arready),
    // .s_axi_rid      (1'b0),
    .s_axi_rdata    (s_axil_rdata),
    .s_axi_rresp    (s_axil_rresp),
    // .s_axi_rlast    (1'b0),
    // .s_axi_ruser    (1'b0),
    .s_axi_rvalid   (s_axil_rvalid),
    .s_axi_rready   (s_axil_rready),
    // .m_axi_arid     (1'b0),
    .m_axi_araddr   (m_axil_araddr),
    // .m_axi_arlen    (1'b0),
    // .m_axi_arsize   (1'b0),
    // .m_axi_arburst  (1'b0),
    // .m_axi_arlock   (1'b0),
    // .m_axi_arcache  (1'b0),
    .m_axi_arprot   (m_axil_arprot),
    // .m_axi_arqos    (1'b0),
    // .m_axi_arregion (1'b0),
    // .m_axi_aruser   (1'b0),
    .m_axi_arvalid  (m_axil_arvalid),
    .m_axi_arready  (m_axil_arready),
    .m_axi_rid      (1'b0),
    .m_axi_rdata    (m_axil_rdata),
    .m_axi_rresp    (m_axil_rresp),
    .m_axi_rlast    (1'b0),
    .m_axi_ruser    (1'b0),
    .m_axi_rvalid   (m_axil_rvalid),
    .m_axi_rready   (m_axil_rready)
  );  
endmodule;

`resetall