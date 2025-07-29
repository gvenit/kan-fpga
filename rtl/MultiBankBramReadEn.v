`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

module MultiBankBramReadEn #(
  parameter BANKS = 4,
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 32,
  parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
  input  wire [BANKS-1:0]               clka,
  input  wire [BANKS-1:0]               clkb,

  input  wire [BANKS-1:0]               rdena,
  input  wire [BANKS-1:0]               wrena,
  input  wire [BANKS*STRB_WIDTH-1:0]    wrstrba,
  input  wire [BANKS*ADDR_WIDTH-1:0]    addra,
  input  wire [BANKS*DATA_WIDTH-1:0]    dina,
  output wire [BANKS*DATA_WIDTH-1:0]    douta,
  output wire [BANKS-1:0]               dacka,
  
  input  wire [BANKS-1:0]               rdenb,
  input  wire [BANKS-1:0]               wrenb,
  input  wire [BANKS*STRB_WIDTH-1:0]    wrstrbb,
  input  wire [BANKS*ADDR_WIDTH-1:0]    addrb,
  input  wire [BANKS*DATA_WIDTH-1:0]    dinb,
  output wire [BANKS*DATA_WIDTH-1:0]    doutb,
  output wire [BANKS-1:0]               dackb
);

genvar i;

generate
  for (i = 0; i < BANKS; i = i + 1) begin : bram_read_en_genblock
    BramReadEn #(
      .ADDR_WIDTH (ADDR_WIDTH),
      .DATA_WIDTH (DATA_WIDTH),
      .STRB_WIDTH (STRB_WIDTH)
    ) bram_inst   (
      .clka       (clka     [i]),
      .clkb       (clkb     [i]),
      .rdena      (rdena    [i]),
      .wrena      (wrena    [i]),
      .wrstrba    (wrstrba  [i*STRB_WIDTH +: STRB_WIDTH]),
      .addra      (addra    [i*ADDR_WIDTH +: ADDR_WIDTH]),
      .dina       (dina     [i*DATA_WIDTH +: DATA_WIDTH]),
      .douta      (douta    [i*DATA_WIDTH +: DATA_WIDTH]),
      .dacka      (dacka    [i]),
      .rdenb      (rdenb    [i]),
      .wrenb      (wrenb    [i]),
      .wrstrbb    (wrstrbb  [i*STRB_WIDTH +: STRB_WIDTH]),
      .addrb      (addrb    [i*ADDR_WIDTH +: ADDR_WIDTH]),
      .dinb       (dinb     [i*DATA_WIDTH +: DATA_WIDTH]),
      .doutb      (doutb    [i*DATA_WIDTH +: DATA_WIDTH]),
      .dackb      (dackb    [i])
    );
  end
endgenerate

endmodule

`resetall