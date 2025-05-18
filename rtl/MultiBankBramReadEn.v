`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

module MultiBankBramReadEn #(
  parameter BANKS = 4,
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 16,
  parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
  input  wire                           clk,

  input  wire [BANKS-1:0]               rdena,
  input  wire [BANKS-1:0]               wrena,
  input  wire [BANKS*STRB_WIDTH-1:0]    wrstrba,
  input  wire [BANKS*ADDR_WIDTH-1:0]    addra,
  input  wire [BANKS*DATA_WIDTH-1:0]    dina,
  output wire [BANKS*DATA_WIDTH-1:0]    douta,
  
  input  wire [BANKS-1:0]               rdenb,
  input  wire [BANKS-1:0]               wrenb,
  input  wire [BANKS*STRB_WIDTH-1:0]    wrstrbb,
  input  wire [BANKS*ADDR_WIDTH-1:0]    addrb,
  input  wire [BANKS*DATA_WIDTH-1:0]    dinb,
  output wire [BANKS*DATA_WIDTH-1:0]    doutb
);

genvar i;

generate
  for (i = 0; i < BANKS; i = i + 1) begin
    BramReadEn #(
      .DATA_WIDTH (DATA_WIDTH),
      .ADDR_WIDTH (ADDR_WIDTH),
      .STRB_WIDTH (STRB_WIDTH)
    ) bram_inst   (
      .clk        (clk),
      .rdena      (rdena    [i]),
      .wrena      (wrena    [i]),
      .wrstrba    (wrstrba  [i*STRB_WIDTH +: STRB_WIDTH]),
      .addra      (addra    [i*ADDR_WIDTH +: ADDR_WIDTH]),
      .dina       (dina     [i*DATA_WIDTH +: DATA_WIDTH]),
      .douta      (douta    [i*DATA_WIDTH +: DATA_WIDTH]),
      .rdenb      (rdenb    [i]),
      .wrenb      (wrenb    [i]),
      .wrstrbb    (wrstrbb  [i*STRB_WIDTH +: STRB_WIDTH]),
      .addrb      (addrb    [i*ADDR_WIDTH +: ADDR_WIDTH]),
      .dinb       (dinb     [i*DATA_WIDTH +: DATA_WIDTH]),
      .doutb      (doutb    [i*DATA_WIDTH +: DATA_WIDTH])
    );
  end
endgenerate

endmodule

`resetall