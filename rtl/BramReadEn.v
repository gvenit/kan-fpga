`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
  In this code a BRAM is infered by XST.
  The main way to infer a BRAM is to make sure that both write and read are synchronous.
  This example uses parameters to generate the BRAM and
  it has a similar interface with the Block Memory Generator IP.

  This is a read-first BRAM
  which means there are registers on the ouput.
  This might have timing implications.
*/

module BramReadEn #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 16,
  parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
  input  wire                     clk,

  input  wire                     rdena,
  input  wire                     wrena,
  input  wire [STRB_WIDTH-1:0]    wrstrba,
  input  wire [ADDR_WIDTH-1:0]    addra,
  input  wire [DATA_WIDTH-1:0]    dina,
  output wire [DATA_WIDTH-1:0]    douta,
  
  input  wire                     rdenb,
  input  wire                     wrenb,
  input  wire [STRB_WIDTH-1:0]    wrstrbb,
  input  wire [ADDR_WIDTH-1:0]    addrb,
  input  wire [DATA_WIDTH-1:0]    dinb,
  output wire [DATA_WIDTH-1:0]    doutb
);

  /********************************
  Local Parameters
  ********************************/

  localparam DEPTH = 2**ADDR_WIDTH;
  localparam WORD_SIZE = DATA_WIDTH/STRB_WIDTH;

  /********************************
  Internal Signals
  ********************************/

  integer i, j;

  reg [DATA_WIDTH-1:0] rddata_a;
  reg [DATA_WIDTH-1:0] rddata_b;
  reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];

  /********************************
  Always blocks
  ********************************/

  always @ (posedge clk) begin
    if (rdena) begin
      rddata_a <= ram[addra];
    end else if (wrena) begin
      for (i = 0; i < STRB_WIDTH; i = i + 1) begin
        if (wrstrba[i])
          ram[addra][WORD_SIZE*i +: WORD_SIZE] <= dina[WORD_SIZE*i +: WORD_SIZE];
      end
    end
  end

  always @ (posedge clk) begin
    if (rdenb) begin
      rddata_b <= ram[addrb];
    end else if (wrenb) begin
      for (i = 0; i < STRB_WIDTH; i = i + 1) begin
        if (wrstrbb[i])
          ram[addrb][WORD_SIZE*i +: WORD_SIZE] <= dinb[WORD_SIZE*i +: WORD_SIZE];
      end
    end
  end

  /********************************
  Direct assignments
  ********************************/

  assign douta = rddata_a;
  assign doutb = rddata_b;

endmodule

`resetall
