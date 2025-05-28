`resetall
`timescale 1ns/1ps
`default_nettype none

/*=============================================
    Wrapper module that contains:

    - Dual Port Axi-Lite RAM
    - Width Adapter on port B

    B_A_DATA_WIDTH specifies the actual
    data width of the internal RAM module.
    B_A_DATA_WIDTH external is the external
    adapted width so that it interfaces
    with other blocks in the block design
    because Vivado will not allow 
    data width smaller than 32 bits
==============================================*/

`include "header_utils.vh"

module AxilDpRamParameterizable #(
  parameter ADDR_WIDTH = 9,
  parameter A_DATA_WIDTH = 16,
  parameter A_STRB_WIDTH = (A_DATA_WIDTH/8),
  parameter B_DATA_WIDTH = 32,
  parameter B_STRB_WIDTH = (B_DATA_WIDTH/8),
  parameter PIPELINE_OUTPUT = 0
) (
  input  wire                             clka,
  input  wire                             rsta,
  input  wire                             clkb,
  input  wire                             rstb,

  /*-----------------------------------------
      Port A AXI-Lite : Internal port
  -----------------------------------------*/

  input  wire [ADDR_WIDTH-1:0]            s_axil_a_awaddr,
  input  wire [2:0]                       s_axil_a_awprot,
  input  wire                             s_axil_a_awvalid,
  output wire                             s_axil_a_awready,
  input  wire [A_DATA_WIDTH-1:0]          s_axil_a_wdata,
  input  wire [A_STRB_WIDTH-1:0]          s_axil_a_wstrb,
  input  wire                             s_axil_a_wvalid,
  output wire                             s_axil_a_wready,
  output wire [1:0]                       s_axil_a_bresp,
  output wire                             s_axil_a_bvalid,
  input  wire                             s_axil_a_bready,
  input  wire [ADDR_WIDTH-1:0]            s_axil_a_araddr,
  input  wire [2:0]                       s_axil_a_arprot,
  input  wire                             s_axil_a_arvalid,
  output wire                             s_axil_a_arready,
  output wire [A_DATA_WIDTH-1:0]          s_axil_a_rdata,
  output wire [1:0]                       s_axil_a_rresp,
  output wire                             s_axil_a_rvalid,
  input  wire                             s_axil_a_rready,

  /*-----------------------------------------
      Port B AXI-Lite : External port
  -----------------------------------------*/

  input  wire [ADDR_WIDTH-1:0]            s_axil_b_awaddr,
  input  wire [2:0]                       s_axil_b_awprot,
  input  wire                             s_axil_b_awvalid,
  output wire                             s_axil_b_awready,
  input  wire [B_DATA_WIDTH-1:0]          s_axil_b_wdata,
  input  wire [B_STRB_WIDTH-1:0]          s_axil_b_wstrb,
  input  wire                             s_axil_b_wvalid,
  output wire                             s_axil_b_wready,
  output wire [1:0]                       s_axil_b_bresp,
  output wire                             s_axil_b_bvalid,
  input  wire                             s_axil_b_bready,
  input  wire [ADDR_WIDTH-1:0]            s_axil_b_araddr,
  input  wire [2:0]                       s_axil_b_arprot,
  input  wire                             s_axil_b_arvalid,
  output wire                             s_axil_b_arready,
  output wire [B_DATA_WIDTH-1:0]          s_axil_b_rdata,
  output wire [1:0]                       s_axil_b_rresp,
  output wire                             s_axil_b_rvalid,
  input  wire                             s_axil_b_rready
);

  /********************************
  Internal Signals & localparams -- Port A
  ********************************/

  localparam A_VALID_ADDR_WIDTH = `MAX( ADDR_WIDTH - `RLOG2( A_STRB_WIDTH ), 1 );
  localparam A_WORD_WIDTH = A_STRB_WIDTH;
  localparam A_WORD_SIZE = A_DATA_WIDTH/A_WORD_WIDTH;

  reg read_eligible_a;
  reg write_eligible_a;

  reg mem_wr_en_a;
  reg mem_rd_en_a;

  reg  last_read_a_reg = 1'b0, last_read_a_next;
    
  reg  s_axil_a_awready_reg = 1'b0, s_axil_a_awready_next;
  reg  s_axil_a_wready_reg  = 1'b0, s_axil_a_wready_next;
  reg  s_axil_a_bvalid_reg  = 1'b0, s_axil_a_bvalid_next;
  reg  s_axil_a_arready_reg = 1'b0, s_axil_a_arready_next;
  reg  s_axil_a_rvalid_reg  = 1'b0, s_axil_a_rvalid_next;
  reg  s_axil_a_rvalid_pipe_reg = 1'b0;

  reg  [A_DATA_WIDTH-1:0] s_axil_a_rdata_next;
  wire [A_DATA_WIDTH-1:0] s_axil_a_rdata_reg;
  reg  [A_DATA_WIDTH-1:0] s_axil_a_rdata_pipe_reg = {A_DATA_WIDTH{1'b0}};
    
  wire [A_VALID_ADDR_WIDTH-1:0] s_axil_a_awaddr_valid = $unsigned(s_axil_a_awaddr >> (ADDR_WIDTH - A_VALID_ADDR_WIDTH));
  wire [A_VALID_ADDR_WIDTH-1:0] s_axil_a_araddr_valid = $unsigned(s_axil_a_araddr >> (ADDR_WIDTH - A_VALID_ADDR_WIDTH));

  wire [A_VALID_ADDR_WIDTH-1:0] addra;
  
  /********************************
  Direct Assignments
  ********************************/

  assign s_axil_a_awready = s_axil_a_awready_reg;
  assign s_axil_a_wready  = s_axil_a_wready_reg;
  assign s_axil_a_bresp   = 2'b00;
  assign s_axil_a_bvalid  = s_axil_a_bvalid_reg;
  assign s_axil_a_arready = s_axil_a_arready_reg;
  assign s_axil_a_rdata   = PIPELINE_OUTPUT ? s_axil_a_rdata_pipe_reg : s_axil_a_rdata_reg;
  assign s_axil_a_rresp   = 2'b00;
  assign s_axil_a_rvalid  = PIPELINE_OUTPUT ? s_axil_a_rvalid_pipe_reg : s_axil_a_rvalid_reg;

  assign addra = mem_rd_en_a ? s_axil_a_araddr_valid : s_axil_a_awaddr_valid;

  /********************************
  Always blocks -- Port A
  ********************************/

  always @* begin
    mem_wr_en_a = 1'b0;
    mem_rd_en_a = 1'b0;

    last_read_a_next = last_read_a_reg;

    s_axil_a_awready_next = 1'b0;
    s_axil_a_wready_next = 1'b0;
    s_axil_a_bvalid_next = s_axil_a_bvalid_reg && !s_axil_a_bready;

    s_axil_a_arready_next = 1'b0;
    s_axil_a_rvalid_next = s_axil_a_rvalid_reg && !(s_axil_a_rready || (PIPELINE_OUTPUT && !s_axil_a_rvalid_pipe_reg));

    write_eligible_a = s_axil_a_awvalid && s_axil_a_wvalid && (!s_axil_a_bvalid || s_axil_a_bready) && (!s_axil_a_awready && !s_axil_a_wready);
    read_eligible_a  = s_axil_a_arvalid && (!s_axil_a_rvalid || s_axil_a_rready || (PIPELINE_OUTPUT && !s_axil_a_rvalid_pipe_reg)) && (!s_axil_a_arready);

    if (write_eligible_a && (!read_eligible_a || last_read_a_reg)) begin
      last_read_a_next = 1'b0;

      s_axil_a_awready_next = 1'b1;
      s_axil_a_wready_next = 1'b1;
      s_axil_a_bvalid_next = 1'b1;

      mem_wr_en_a = 1'b1;
    end else if (read_eligible_a) begin
      last_read_a_next = 1'b1;

      s_axil_a_arready_next = 1'b1;
      s_axil_a_rvalid_next = 1'b1;

      mem_rd_en_a = 1'b1;
    end
  end

  always @(posedge clka) begin
    last_read_a_reg <= last_read_a_next;

    s_axil_a_awready_reg <= s_axil_a_awready_next;
    s_axil_a_wready_reg  <= s_axil_a_wready_next;
    s_axil_a_bvalid_reg  <= s_axil_a_bvalid_next;

    s_axil_a_arready_reg <= s_axil_a_arready_next;
    s_axil_a_rvalid_reg  <= s_axil_a_rvalid_next;

    if (!s_axil_a_rvalid_pipe_reg || s_axil_a_rready) begin
      s_axil_a_rdata_pipe_reg  <= s_axil_a_rdata_reg;
      s_axil_a_rvalid_pipe_reg <= s_axil_a_rvalid_reg;
    end

    if (rsta) begin
      last_read_a_reg <= 1'b0;

      s_axil_a_awready_reg <= 1'b0;
      s_axil_a_wready_reg  <= 1'b0;
      s_axil_a_bvalid_reg  <= 1'b0;

      s_axil_a_arready_reg <= 1'b0;
      s_axil_a_rvalid_reg  <= 1'b0;
      s_axil_a_rvalid_pipe_reg <= 1'b0;
    end
  end

  /********************************
  Internal Signals & localparams -- Port A
  ********************************/

  localparam B_VALID_ADDR_WIDTH = `MAX( ADDR_WIDTH - `RLOG2( B_STRB_WIDTH ), 1 );;
  localparam B_WORD_WIDTH = B_STRB_WIDTH;
  localparam B_WORD_SIZE = B_DATA_WIDTH/A_WORD_WIDTH;

  reg read_eligible_b;
  reg write_eligible_b;

  reg mem_wr_en_b;
  reg mem_rd_en_b;

  reg  last_read_b_reg = 1'b0, last_read_b_next;
  
  reg  [B_DATA_WIDTH-1:0] s_axil_b_rdata_next;
  wire [B_DATA_WIDTH-1:0] s_axil_b_rdata_reg;
  reg  [B_DATA_WIDTH-1:0] s_axil_b_rdata_pipe_reg = {A_DATA_WIDTH{1'b0}};

  wire [B_VALID_ADDR_WIDTH-1:0] s_axil_b_awaddr_valid = $unsigned(s_axil_b_awaddr >> (ADDR_WIDTH - B_VALID_ADDR_WIDTH));
  wire [B_VALID_ADDR_WIDTH-1:0] s_axil_b_araddr_valid = $unsigned(s_axil_b_araddr >> (ADDR_WIDTH - B_VALID_ADDR_WIDTH));

  reg  s_axil_b_awready_reg = 1'b0, s_axil_b_awready_next;
  reg  s_axil_b_wready_reg  = 1'b0, s_axil_b_wready_next;
  reg  s_axil_b_bvalid_reg  = 1'b0, s_axil_b_bvalid_next;
  reg  s_axil_b_arready_reg = 1'b0, s_axil_b_arready_next;
  reg  s_axil_b_rvalid_reg  = 1'b0, s_axil_b_rvalid_next;
  reg  s_axil_b_rvalid_pipe_reg = 1'b0;

  wire [B_VALID_ADDR_WIDTH-1:0] addrb;

  /********************************
  Direct Assignments
  ********************************/

  assign s_axil_b_awready = s_axil_b_awready_reg;
  assign s_axil_b_wready  = s_axil_b_wready_reg;
  assign s_axil_b_bresp   = 2'b00;
  assign s_axil_b_bvalid  = s_axil_b_bvalid_reg;
  assign s_axil_b_arready = s_axil_b_arready_reg;
  assign s_axil_b_rdata   = PIPELINE_OUTPUT ? s_axil_b_rdata_pipe_reg : s_axil_b_rdata_reg;
  assign s_axil_b_rresp   = 2'b00;
  assign s_axil_b_rvalid  = PIPELINE_OUTPUT ? s_axil_b_rvalid_pipe_reg : s_axil_b_rvalid_reg;

  assign addrb = mem_rd_en_b ? s_axil_b_araddr_valid : s_axil_b_awaddr_valid;

  /********************************
  Always blocks -- Port B
  ********************************/

  always @* begin
    mem_wr_en_b = 1'b0;
    mem_rd_en_b = 1'b0;

    last_read_b_next = last_read_b_reg;

    s_axil_b_awready_next = 1'b0;
    s_axil_b_wready_next  = 1'b0;
    s_axil_b_bvalid_next  = s_axil_b_bvalid_reg && !s_axil_b_bready;

    s_axil_b_arready_next = 1'b0;
    s_axil_b_rvalid_next  = s_axil_b_rvalid_reg && !(s_axil_b_rready || (PIPELINE_OUTPUT && !s_axil_b_rvalid_pipe_reg));

    write_eligible_b = s_axil_b_awvalid && s_axil_b_wvalid && (!s_axil_b_bvalid || s_axil_b_bready) && (!s_axil_b_awready && !s_axil_b_wready);
    read_eligible_b  = s_axil_b_arvalid && (!s_axil_b_rvalid || s_axil_b_rready || (PIPELINE_OUTPUT && !s_axil_b_rvalid_pipe_reg)) && (!s_axil_b_arready);

    if (write_eligible_b && (!read_eligible_b || last_read_b_reg)) begin
      last_read_b_next = 1'b0;

      s_axil_b_awready_next = 1'b1;
      s_axil_b_wready_next  = 1'b1;
      s_axil_b_bvalid_next  = 1'b1;

      mem_wr_en_b = 1'b1;
    end else if (read_eligible_b) begin
      last_read_b_next = 1'b1;

      s_axil_b_arready_next = 1'b1;
      s_axil_b_rvalid_next  = 1'b1;

      mem_rd_en_b = 1'b1;
    end
  end

  always @(posedge clkb) begin
    last_read_b_reg <= last_read_b_next;

    s_axil_b_awready_reg <= s_axil_b_awready_next;
    s_axil_b_wready_reg  <= s_axil_b_wready_next;
    s_axil_b_bvalid_reg  <= s_axil_b_bvalid_next;

    s_axil_b_arready_reg <= s_axil_b_arready_next;
    s_axil_b_rvalid_reg  <= s_axil_b_rvalid_next;

    if (!s_axil_b_rvalid_pipe_reg || s_axil_b_rready) begin
      s_axil_b_rdata_pipe_reg  <= s_axil_b_rdata_reg;
      s_axil_b_rvalid_pipe_reg <= s_axil_b_rvalid_reg;
    end

    if (rstb) begin
      last_read_b_reg <= 1'b0;

      s_axil_b_awready_reg <= 1'b0;
      s_axil_b_wready_reg  <= 1'b0;
      s_axil_b_bvalid_reg  <= 1'b0;

      s_axil_b_arready_reg <= 1'b0;
      s_axil_b_rvalid_reg  <= 1'b0;
      s_axil_b_rvalid_pipe_reg <= 1'b0;
    end
  end

  /********************************
  Internal Signals & localparams -- Global
  ********************************/

  localparam MAX_DATA_WIDTH = `MAX( A_DATA_WIDTH, B_DATA_WIDTH );
  localparam MIN_DATA_WIDTH = `MIN( A_DATA_WIDTH, B_DATA_WIDTH );

  localparam BANKS = MAX_DATA_WIDTH / MIN_DATA_WIDTH;

  localparam BANK_DATA_WIDTH = MIN_DATA_WIDTH;
  localparam BANK_STRB_WIDTH = BANK_DATA_WIDTH / 8;

  localparam BANK_VALID_ADDR_WIDTH = `MAX( `MAX( A_VALID_ADDR_WIDTH, B_VALID_ADDR_WIDTH ) - `RLOG2( BANKS ), 1);  

  wire [A_DATA_WIDTH-1:0]                   s_axil_a_rdata_reg_int;
  reg  [A_DATA_WIDTH-1:0]                   s_axil_a_rdata_reg_int_reg;

  wire [B_DATA_WIDTH-1:0]                   s_axil_b_rdata_reg_int;
  reg  [B_DATA_WIDTH-1:0]                   s_axil_b_rdata_reg_int_reg;
  
  reg                                       mem_rd_en_a_reg;
  reg                                       mem_rd_en_b_reg;

  wire [BANKS-1:0]                          bram_rdena;
  wire [BANKS-1:0]                          bram_wrena;
  wire [BANKS*BANK_STRB_WIDTH-1:0]          bram_wrstrba;
  wire [BANKS*BANK_VALID_ADDR_WIDTH-1:0]    bram_addra;
  wire [BANKS*BANK_DATA_WIDTH-1:0]          bram_dina;
  wire [BANKS*BANK_DATA_WIDTH-1:0]          bram_douta;
  wire [BANKS-1:0]                          bram_rdenb;
  wire [BANKS-1:0]                          bram_wrenb;
  wire [BANKS*BANK_STRB_WIDTH-1:0]          bram_wrstrbb;
  wire [BANKS*BANK_VALID_ADDR_WIDTH-1:0]    bram_addrb;
  wire [BANKS*BANK_DATA_WIDTH-1:0]          bram_dinb;
  wire [BANKS*BANK_DATA_WIDTH-1:0]          bram_doutb;

  /********************************
  Module instantiations
  ********************************/

  always @(posedge clka ) begin  // Hold Read data in case of handshake delays in read channel
    mem_rd_en_a_reg <= mem_rd_en_a;
    if (mem_rd_en_a_reg) 
      s_axil_a_rdata_reg_int_reg <= s_axil_a_rdata_reg_int;
  end
  assign s_axil_a_rdata_reg = (mem_rd_en_a_reg) ? s_axil_a_rdata_reg_int : s_axil_a_rdata_reg_int_reg;

  assign bram_rdena   = {BANKS{mem_rd_en_a}};

  BramIntrfTranslator # (
    .IN_WIDTH     (A_DATA_WIDTH),
    .OUT_WIDTH    (BANK_DATA_WIDTH),
    .BANKS        (BANKS),
    .OUT_DEPTH    (2**BANK_VALID_ADDR_WIDTH)
  ) bram_trl_A_inst (
    .clk          (clka),
    .en_i         (mem_rd_en_a || mem_wr_en_a),
    .we_i         (s_axil_a_wstrb),
    .addr_i       ($unsigned(addra)),
    .wrdata_i     (s_axil_a_wdata),
    .rddata_i     (s_axil_a_rdata_reg_int),
    .en_o         (bram_wrena),
    .we_o         (bram_wrstrba),
    .addr_o       (bram_addra),
    .wrdata_o     (bram_dina),
    .rddata_o     (bram_douta)
  );

  always @(posedge clkb ) begin  // Hold Read data in case of handshake delays in read channel
    mem_rd_en_b_reg <= mem_rd_en_b;
    if (mem_rd_en_b_reg) 
      s_axil_b_rdata_reg_int_reg <= s_axil_b_rdata_reg_int;
  end
  assign s_axil_b_rdata_reg = (mem_rd_en_b_reg) ? s_axil_b_rdata_reg_int : s_axil_b_rdata_reg_int_reg;

  assign bram_rdenb   = {BANKS{mem_rd_en_b}};

  BramIntrfTranslator # (
    .IN_WIDTH     (B_DATA_WIDTH),
    .OUT_WIDTH    (BANK_DATA_WIDTH),
    .BANKS        (BANKS),
    .OUT_DEPTH    (2**BANK_VALID_ADDR_WIDTH),
    .RD_LATENCY   (1)
  ) bram_trl_B_inst (
    .clk          (clkb),
    .en_i         (mem_wr_en_b),
    .we_i         (s_axil_b_wstrb),
    .addr_i       ($unsigned(addrb)),
    .wrdata_i     (s_axil_b_wdata),
    .rddata_i     (s_axil_b_rdata_reg_int),
    .en_o         (bram_wrenb),
    .we_o         (bram_wrstrbb),
    .addr_o       (bram_addrb),
    .wrdata_o     (bram_dinb),
    .rddata_o     (bram_doutb)
  );
  
  MultiBankBramReadEn #(
    .BANKS        (BANKS),
    .DATA_WIDTH   (BANK_DATA_WIDTH),
    .ADDR_WIDTH   (BANK_VALID_ADDR_WIDTH),
    .STRB_WIDTH   (BANK_STRB_WIDTH)
  ) internal_bram_inst (
    .clka        (clka),
    .clkb        (clkb),
    .rdena        (bram_rdena),
    .wrena        (bram_wrena),
    .wrstrba      (bram_wrstrba),
    .addra        (bram_addra),
    .dina         (bram_dina),
    .douta        (bram_douta),
    .rdenb        (bram_rdenb),
    .wrenb        (bram_wrenb),
    .wrstrbb      (bram_wrstrbb),
    .addrb        (bram_addrb),
    .dinb         (bram_dinb),
    .doutb        (bram_doutb)
  );

endmodule