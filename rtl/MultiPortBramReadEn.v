`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

module MultiPortBramReadEn #(
  parameter DATA_WIDTH_A = 16,
  parameter STRB_WIDTH_A = DATA_WIDTH_A / 8,
  parameter ADDR_WIDTH_A = 8,
  parameter NUM_PORTS_A = 1,
  parameter DATA_WIDTH_B = 16,
  parameter STRB_WIDTH_B = DATA_WIDTH_B / 8,
  parameter ADDR_WIDTH_B = 8,
  parameter NUM_PORTS_B = 1
) (
  input  wire [NUM_PORTS_A-1:0]                 clka,
  input  wire [NUM_PORTS_B-1:0]                 clkb,

  input  wire [NUM_PORTS_A-1:0]                 rdena,
  input  wire [NUM_PORTS_A-1:0]                 wrena,
  input  wire [NUM_PORTS_A*STRB_WIDTH_A-1:0]    wrstrba,
  input  wire [NUM_PORTS_A*ADDR_WIDTH_A-1:0]    addra,
  input  wire [NUM_PORTS_A*DATA_WIDTH_A-1:0]    dina,
  output wire [NUM_PORTS_A*DATA_WIDTH_A-1:0]    douta,
  output wire [NUM_PORTS_A-1:0]                 dacka,
  
  input  wire [NUM_PORTS_B-1:0]                 rdenb,
  input  wire [NUM_PORTS_B-1:0]                 wrenb,
  input  wire [NUM_PORTS_B*STRB_WIDTH_B-1:0]    wrstrbb,
  input  wire [NUM_PORTS_B*ADDR_WIDTH_B-1:0]    addrb,
  input  wire [NUM_PORTS_B*DATA_WIDTH_B-1:0]    dinb,
  output wire [NUM_PORTS_B*DATA_WIDTH_B-1:0]    doutb,
  output wire [NUM_PORTS_B-1:0]                 dackb
);
  localparam TOTAL_DATA_WIDTH = `MIN( DATA_WIDTH_A, DATA_WIDTH_B );
  localparam TOTAL_STRB_WIDTH = TOTAL_DATA_WIDTH / 8;

  localparam MIN_BANKS = `MAX( (DATA_WIDTH_A+TOTAL_DATA_WIDTH-1) / TOTAL_DATA_WIDTH, (DATA_WIDTH_B+TOTAL_DATA_WIDTH-1) / TOTAL_DATA_WIDTH );
  localparam TOTAL_BANKS = `MAX( MIN_BANKS, `MAX( NUM_PORTS_A, NUM_PORTS_B ) );

  localparam TOTAL_DEPTH = `MIN( (2 ** ADDR_WIDTH_A) * NUM_PORTS_A * DATA_WIDTH_A, (2 ** ADDR_WIDTH_B) * NUM_PORTS_B * DATA_WIDTH_B )  / TOTAL_DATA_WIDTH;
  localparam DEPTH_PER_BANK = (TOTAL_DEPTH + TOTAL_BANKS-1) / TOTAL_BANKS;

  localparam TOTAL_ADDR_WIDTH = `LOG2( DEPTH_PER_BANK );

  localparam BANKS_PER_NUM_PORT_A = (TOTAL_BANKS+NUM_PORTS_A-1) / NUM_PORTS_A;
  localparam BANKS_PER_NUM_PORT_B = (TOTAL_BANKS+NUM_PORTS_B-1) / NUM_PORTS_B;

  // initial begin
  //   $display("DATA_WIDTH_A %4d",DATA_WIDTH_A);
  //   $display("STRB_WIDTH_A %4d",STRB_WIDTH_A);
  //   $display("ADDR_WIDTH_A %4d",ADDR_WIDTH_A);
  //   $display("NUM_PORTS_A  %4d",NUM_PORTS_A);
  //   $display("DATA_WIDTH_B %4d",DATA_WIDTH_B);
  //   $display("STRB_WIDTH_B %4d",STRB_WIDTH_B);
  //   $display("ADDR_WIDTH_B %4d",ADDR_WIDTH_B);
  //   $display("NUM_PORTS_B  %4d",NUM_PORTS_B);

  //   $display("TOTAL_DATA_WIDTH     %4d",TOTAL_DATA_WIDTH);
  //   $display("TOTAL_STRB_WIDTH     %4d",TOTAL_STRB_WIDTH);
  //   $display("MIN_BANKS            %4d",MIN_BANKS);
  //   $display("TOTAL_BANKS          %4d",TOTAL_BANKS);
  //   $display("TOTAL_DEPTH          %4d",TOTAL_DEPTH);
  //   $display("DEPTH_PER_BANK       %4d",DEPTH_PER_BANK);
  //   $display("TOTAL_ADDR_WIDTH     %4d",TOTAL_ADDR_WIDTH);
  //   $display("BANKS_PER_NUM_PORT_A %4d",BANKS_PER_NUM_PORT_A);
  //   $display("BANKS_PER_NUM_PORT_B %4d",BANKS_PER_NUM_PORT_B);
  //   $finish;
  // end

  wire [TOTAL_BANKS-1:0]                     int_clka;
  wire [TOTAL_BANKS-1:0]                     int_rdena;
  wire [TOTAL_BANKS-1:0]                     int_wrena;
  wire [TOTAL_BANKS*TOTAL_STRB_WIDTH-1:0]    int_wrstrba;
  wire [TOTAL_BANKS*TOTAL_ADDR_WIDTH-1:0]    int_addra;
  wire [TOTAL_BANKS*TOTAL_DATA_WIDTH-1:0]    int_dina;
  wire [TOTAL_BANKS*TOTAL_DATA_WIDTH-1:0]    int_douta;
  wire [TOTAL_BANKS-1:0]                     int_dacka;

  wire [TOTAL_BANKS-1:0]                     int_clkb;
  wire [TOTAL_BANKS-1:0]                     int_rdenb;
  wire [TOTAL_BANKS-1:0]                     int_wrenb;
  wire [TOTAL_BANKS*TOTAL_STRB_WIDTH-1:0]    int_wrstrbb;
  wire [TOTAL_BANKS*TOTAL_ADDR_WIDTH-1:0]    int_addrb;
  wire [TOTAL_BANKS*TOTAL_DATA_WIDTH-1:0]    int_dinb;
  wire [TOTAL_BANKS*TOTAL_DATA_WIDTH-1:0]    int_doutb;
  wire [TOTAL_BANKS-1:0]                     int_dackb;

  MultiBankBramReadEn #(
    .BANKS      (TOTAL_BANKS), 
    .DATA_WIDTH (TOTAL_DATA_WIDTH), 
    .STRB_WIDTH (TOTAL_STRB_WIDTH), 
    .ADDR_WIDTH (TOTAL_ADDR_WIDTH) 
  ) bram_inst   (
    .clka       (int_clka),
    .clkb       (int_clkb),
    .rdena      (int_rdena),
    .wrena      (int_wrena),
    .wrstrba    (int_wrstrba),
    .addra      (int_addra),
    .dina       (int_dina),
    .douta      (int_douta),
    .dacka      (int_dacka),
    .rdenb      (int_rdenb),
    .wrenb      (int_wrenb),
    .wrstrbb    (int_wrstrbb),
    .addrb      (int_addrb),
    .dinb       (int_dinb),
    .doutb      (int_doutb),
    .dackb      (int_dackb)
  );

genvar i;

generate
  for (i = 0; i < NUM_PORTS_A; i = i + 1) begin : port_a_translator_genblock
    BramIntrfTranslatorReadEn #(
      .DATA_WIDTH_IN  (DATA_WIDTH_A),
      .DATA_WIDTH_OUT (TOTAL_DATA_WIDTH),
      .BANKS          (BANKS_PER_NUM_PORT_A),
      .DEPTH_PER_BANK (DEPTH_PER_BANK),
      .RD_LATENCY     (1)
    ) translator_inst (
      .clk            (clka         [i]),
      .rden_i         (rdena        [i]),
      .wren_i         (wrena        [i]),
      .wrstrb_i       (wrstrba      [i*STRB_WIDTH_A +: STRB_WIDTH_A]),
      .addr_i         (addra        [i*ADDR_WIDTH_A +: ADDR_WIDTH_A]),
      .din_i          (dina         [i*DATA_WIDTH_A +: DATA_WIDTH_A]),
      .dout_i         (douta        [i*DATA_WIDTH_A +: DATA_WIDTH_A]),
      .dack_i         (dacka        [i]),
      .rden_o         (int_rdena    [i*BANKS_PER_NUM_PORT_A +: BANKS_PER_NUM_PORT_A]),
      .wren_o         (int_wrena    [i*BANKS_PER_NUM_PORT_A +: BANKS_PER_NUM_PORT_A]),
      .wrstrb_o       (int_wrstrba  [i*BANKS_PER_NUM_PORT_A*TOTAL_STRB_WIDTH +: BANKS_PER_NUM_PORT_A*TOTAL_STRB_WIDTH]),
      .addr_o         (int_addra    [i*BANKS_PER_NUM_PORT_A*TOTAL_ADDR_WIDTH +: BANKS_PER_NUM_PORT_A*TOTAL_ADDR_WIDTH]),
      .din_o          (int_dina     [i*BANKS_PER_NUM_PORT_A*TOTAL_DATA_WIDTH +: BANKS_PER_NUM_PORT_A*TOTAL_DATA_WIDTH]),
      .dout_o         (int_douta    [i*BANKS_PER_NUM_PORT_A*TOTAL_DATA_WIDTH +: BANKS_PER_NUM_PORT_A*TOTAL_DATA_WIDTH]),
      .dack_o         (int_dacka    [i*BANKS_PER_NUM_PORT_A +: BANKS_PER_NUM_PORT_A])
    );
    assign int_clka[i*BANKS_PER_NUM_PORT_A +: BANKS_PER_NUM_PORT_A] = {BANKS_PER_NUM_PORT_A{clka}};
  end

  for (i = 0; i < NUM_PORTS_B; i = i + 1) begin : port_b_translator_genblock
    BramIntrfTranslatorReadEn #(
      .DATA_WIDTH_IN  (DATA_WIDTH_B),
      .DATA_WIDTH_OUT (TOTAL_DATA_WIDTH),
      .BANKS          (BANKS_PER_NUM_PORT_B),
      .DEPTH_PER_BANK (DEPTH_PER_BANK),
      .RD_LATENCY     (1)
    ) translator_inst (
      .clk            (clkb         [i]),
      .rden_i         (rdenb        [i]),
      .wren_i         (wrenb        [i]),
      .wrstrb_i       (wrstrbb      [i*STRB_WIDTH_B +: STRB_WIDTH_B]),
      .addr_i         (addrb        [i*ADDR_WIDTH_B +: ADDR_WIDTH_B]),
      .din_i          (dinb         [i*DATA_WIDTH_B +: DATA_WIDTH_B]),
      .dout_i         (doutb        [i*DATA_WIDTH_B +: DATA_WIDTH_B]),
      .dack_i         (dackb        [i]),
      .rden_o         (int_rdenb    [i*BANKS_PER_NUM_PORT_B +: BANKS_PER_NUM_PORT_B]),
      .wren_o         (int_wrenb    [i*BANKS_PER_NUM_PORT_B +: BANKS_PER_NUM_PORT_B]),
      .wrstrb_o       (int_wrstrbb  [i*BANKS_PER_NUM_PORT_B*TOTAL_STRB_WIDTH +: BANKS_PER_NUM_PORT_B*TOTAL_STRB_WIDTH]),
      .addr_o         (int_addrb    [i*BANKS_PER_NUM_PORT_B*TOTAL_ADDR_WIDTH +: BANKS_PER_NUM_PORT_B*TOTAL_ADDR_WIDTH]),
      .din_o          (int_dinb     [i*BANKS_PER_NUM_PORT_B*TOTAL_DATA_WIDTH +: BANKS_PER_NUM_PORT_B*TOTAL_DATA_WIDTH]),
      .dout_o         (int_doutb    [i*BANKS_PER_NUM_PORT_B*TOTAL_DATA_WIDTH +: BANKS_PER_NUM_PORT_B*TOTAL_DATA_WIDTH]),
      .dack_o         (int_dackb    [i*BANKS_PER_NUM_PORT_B +: BANKS_PER_NUM_PORT_B])
    );
    assign int_clkb[i*BANKS_PER_NUM_PORT_B +: BANKS_PER_NUM_PORT_B] = {BANKS_PER_NUM_PORT_B{clkb}};
  end
endgenerate

endmodule

`resetall