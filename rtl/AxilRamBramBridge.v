`resetall
`timescale 1ns/1ps
`default_nettype none

/*=============================================
    Wrapper module that contains:

    - Dual Port Axi-Lite RAM
    - Width Adapter on port B

    B_AXIL_DATA_WIDTH specifies the actual
    data width of the internal RAM module.
    B_AXIL_DATA_WIDTH external is the external
    adapted width so that it interfaces
    with other blocks in the block design
    because Vivado will not allow 
    data width smaller than 32 bits
==============================================*/

`include "header_utils.vh"

module AxilRamBramBridge #(
  parameter AXIL_ADDR_WIDTH = 2,
  parameter AXIL_DATA_WIDTH = 32,
  parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
  parameter BRAM_DATA_WIDTH = 8,
  parameter BRAM_STRB_WIDTH = (BRAM_DATA_WIDTH/8),
  parameter BRAM_PORTS = 1,
  parameter PIPELINE_OUTPUT = 0
) (
  input  wire                                   clka,
  input  wire                                   rsta,

  /*-----------------------------------------
      Port A AXI-Lite : Internal port
  -----------------------------------------*/

  input  wire [AXIL_ADDR_WIDTH-1:0]             s_axil_awaddr,
  input  wire [2:0]                             s_axil_awprot,
  input  wire                                   s_axil_awvalid,
  output wire                                   s_axil_awready,
  input  wire [AXIL_DATA_WIDTH-1:0]             s_axil_wdata,
  input  wire [AXIL_STRB_WIDTH-1:0]             s_axil_wstrb,
  input  wire                                   s_axil_wvalid,
  output wire                                   s_axil_wready,
  output wire [1:0]                             s_axil_bresp,
  output wire                                   s_axil_bvalid,
  input  wire                                   s_axil_bready,
  input  wire [AXIL_ADDR_WIDTH-1:0]             s_axil_araddr,
  input  wire [2:0]                             s_axil_arprot,
  input  wire                                   s_axil_arvalid,
  output wire                                   s_axil_arready,
  output wire [AXIL_DATA_WIDTH-1:0]             s_axil_rdata,
  output wire [1:0]                             s_axil_rresp,
  output wire                                   s_axil_rvalid,
  input  wire                                   s_axil_rready,

  /*-----------------------------------------
      Port B BRam : External port
  -----------------------------------------*/

  input  wire [BRAM_PORTS-1:0]                  clkb,
  input  wire [BRAM_PORTS-1:0]                  rstb,
  input  wire [BRAM_PORTS-1:0]                  rden,
  input  wire [BRAM_PORTS-1:0]                  wren,
  input  wire [BRAM_PORTS*BRAM_STRB_WIDTH-1:0]  wrstrb,
  input  wire [BRAM_PORTS*BRAM_ADDR_WIDTH-1:0]  addr,
  input  wire [BRAM_PORTS*BRAM_DATA_WIDTH-1:0]  din,
  output wire [BRAM_PORTS*BRAM_DATA_WIDTH-1:0]  dout,
  output wire [BRAM_PORTS-1:0]                  dack

);

  /********************************
  Internal Signals & localparams -- Port A
  ********************************/

  localparam AXIL_VALID_ADDR_WIDTH = `MAX( AXIL_ADDR_WIDTH - `RLOG2( AXIL_STRB_WIDTH ), 1 );
  localparam AXIL_WORD_WIDTH = AXIL_STRB_WIDTH;
  localparam AXIL_WORD_SIZE = AXIL_DATA_WIDTH/AXIL_WORD_WIDTH;

  localparam BRAM_ADDR_WIDTH = `MAX( AXIL_ADDR_WIDTH - `RLOG2( BRAM_STRB_WIDTH ) - `RLOG2( BRAM_PORTS ), 1 );

  reg read_eligible_a;
  reg write_eligible_a;

  reg mem_wr_en;
  reg mem_rd_en;

  reg  last_read_a_reg = 1'b0, last_read_a_next;
    
  reg  s_axil_awready_reg = 1'b0, s_axil_awready_next;
  reg  s_axil_wready_reg  = 1'b0, s_axil_wready_next;
  reg  s_axil_bvalid_reg  = 1'b0, s_axil_bvalid_next;
  reg  s_axil_arready_reg = 1'b0, s_axil_arready_next;
  reg  s_axil_rvalid_reg  = 1'b0, s_axil_rvalid_next;
  reg  s_axil_rvalid_pipe_reg = 1'b0;

  reg  [AXIL_DATA_WIDTH-1:0] s_axil_rdata_next;
  wire [AXIL_DATA_WIDTH-1:0] s_axil_rdata_reg;
  reg  [AXIL_DATA_WIDTH-1:0] s_axil_rdata_pipe_reg = {AXIL_DATA_WIDTH{1'b0}};
    
  wire [AXIL_VALID_ADDR_WIDTH-1:0] s_axil_awaddr_valid = $unsigned(s_axil_awaddr >> (AXIL_ADDR_WIDTH - AXIL_VALID_ADDR_WIDTH));
  wire [AXIL_VALID_ADDR_WIDTH-1:0] s_axil_araddr_valid = $unsigned(s_axil_araddr >> (AXIL_ADDR_WIDTH - AXIL_VALID_ADDR_WIDTH));

  wire [AXIL_VALID_ADDR_WIDTH-1:0] addra;
  
  /********************************
  Direct Assignments
  ********************************/

  assign s_axil_awready = s_axil_awready_reg;
  assign s_axil_wready  = s_axil_wready_reg;
  assign s_axil_bresp   = 2'b00;
  assign s_axil_bvalid  = s_axil_bvalid_reg;
  assign s_axil_arready = s_axil_arready_reg;
  assign s_axil_rdata   = PIPELINE_OUTPUT ? s_axil_rdata_pipe_reg : s_axil_rdata_reg;
  assign s_axil_rresp   = 2'b00;
  assign s_axil_rvalid  = PIPELINE_OUTPUT ? s_axil_rvalid_pipe_reg : s_axil_rvalid_reg;

  assign addra = mem_rd_en ? s_axil_araddr_valid : s_axil_awaddr_valid;

  /********************************
  Always blocks -- Port A
  ********************************/

  always @* begin
    mem_wr_en = 1'b0;
    mem_rd_en = 1'b0;

    last_read_a_next = last_read_a_reg;

    s_axil_awready_next = 1'b0;
    s_axil_wready_next = 1'b0;
    s_axil_bvalid_next = s_axil_bvalid_reg && !s_axil_bready;

    s_axil_arready_next = 1'b0;
    s_axil_rvalid_next = s_axil_rvalid_reg && !(s_axil_rready || (PIPELINE_OUTPUT && !s_axil_rvalid_pipe_reg));

    write_eligible_a = s_axil_awvalid && s_axil_wvalid && (!s_axil_bvalid || s_axil_bready) && (!s_axil_awready && !s_axil_wready);
    read_eligible_a  = s_axil_arvalid && (!s_axil_rvalid || s_axil_rready || (PIPELINE_OUTPUT && !s_axil_rvalid_pipe_reg)) && (!s_axil_arready);

    if (write_eligible_a && (!read_eligible_a || last_read_a_reg)) begin
      last_read_a_next = 1'b0;

      s_axil_awready_next = 1'b1;
      s_axil_wready_next = 1'b1;
      s_axil_bvalid_next = 1'b1;

      mem_wr_en = 1'b1;
    end else if (read_eligible_a) begin
      last_read_a_next = 1'b1;

      s_axil_arready_next = 1'b1;
      s_axil_rvalid_next = 1'b1;

      mem_rd_en = 1'b1;
    end
  end

  always @(posedge clka) begin
    last_read_a_reg <= last_read_a_next;

    s_axil_awready_reg <= s_axil_awready_next;
    s_axil_wready_reg  <= s_axil_wready_next;
    s_axil_bvalid_reg  <= s_axil_bvalid_next;

    s_axil_arready_reg <= s_axil_arready_next;
    s_axil_rvalid_reg  <= s_axil_rvalid_next;

    if (!s_axil_rvalid_pipe_reg || s_axil_rready) begin
      s_axil_rdata_pipe_reg  <= s_axil_rdata_reg;
      s_axil_rvalid_pipe_reg <= s_axil_rvalid_reg;
    end

    if (rsta) begin
      last_read_a_reg <= 1'b0;

      s_axil_awready_reg <= 1'b0;
      s_axil_wready_reg  <= 1'b0;
      s_axil_bvalid_reg  <= 1'b0;

      s_axil_arready_reg <= 1'b0;
      s_axil_rvalid_reg  <= 1'b0;
      s_axil_rvalid_pipe_reg <= 1'b0;
    end
  end

  /********************************
  Internal Signals & localparams -- Global
  ********************************/
  wire [AXIL_DATA_WIDTH-1:0]    s_axil_rdata_reg_int;
  reg  [AXIL_DATA_WIDTH-1:0]    s_axil_rdata_reg_int_reg;
  reg                           mem_rd_en_reg;

  /********************************
  Module instantiations
  ********************************/

  always @(posedge clka ) begin  // Hold Read data in case of handshake delays in read channel
    mem_rd_en_reg <= mem_rd_en;
    if (mem_rd_en_reg) 
      s_axil_rdata_reg_int_reg <= s_axil_rdata_reg_int;
  end
  assign s_axil_rdata_reg = (mem_rd_en_reg) ? s_axil_rdata_reg_int : s_axil_rdata_reg_int_reg;

  MultiPortBramReadEn #(
    .ADDR_WIDTH_A   (AXIL_VALID_ADDR_WIDTH),
    .DATA_WIDTH_A   (AXIL_DATA_WIDTH),
    .STRB_WIDTH_A   (AXIL_STRB_WIDTH),
    .NUM_PORTS_A    (1),
    .ADDR_WIDTH_B   (BRAM_ADDR_WIDTH),
    .DATA_WIDTH_B   (BRAM_DATA_WIDTH),
    .STRB_WIDTH_B   (BRAM_STRB_WIDTH),
    .NUM_PORTS_B    (BRAM_PORTS)
  ) bram_inst (
    .clka     (clka),
    .clkb     (clkb),
    .rdena    (mem_rd_en),
    .wrena    (mem_wr_en),
    .wrstrba  (s_axil_wstrb),
    .addra    ($unsigned(addra)),
    .dina     (s_axil_wdata),
    .douta    (s_axil_rdata_reg_int),
    // .dacka    (dacka),   // Not needed for AXI-Lite
    .rdenb    (rden),
    .wrenb    (wren),
    .wrstrbb  (wrstrb),
    .addrb    (addr),
    .dinb     (din),
    .doutb    (dout),
    .dackb    (dack)
  );
endmodule

`resetall
