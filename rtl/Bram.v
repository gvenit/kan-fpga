`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * Bram : In this code a BRAM is infered by XST.
 *    The memory is byte addresible
 *    and to have similar behavior to the non-byte addressible
 *    you will have to write we = 4'b1111
 *
 *    This is a read-first BRAM
 *    which means there are registers on the ouput.
 *    This might have timing implications.
 */

`include "headers/utils.vh"

module Bram #(
  parameter WIDTH = 32,
  parameter DEPTH = 256,
  parameter ADDR = `LOG2(DEPTH),
  parameter WE = WIDTH / 8
) (
  input wire clk,

  /*-----------------------------------------
      Port A: read / wite
  -----------------------------------------*/

  input wire              ena,
  input wire [WE-1:0]     wea,
  input wire [ADDR-1:0]   addra,
  input wire [WIDTH-1:0]  dina,
  output wire [WIDTH-1:0] douta,

  /*-----------------------------------------
      Port B: read only
  -----------------------------------------*/

  input wire              enb,
  input wire [ADDR-1:0]   addrb,
  output wire [WIDTH-1:0] doutb,
  output wire             validb
);

  /********************************
    Internal Signals
  ********************************/

  integer i, j;

  reg [WIDTH-1:0] rddata_a;
  reg [WIDTH-1:0] rddata_b;

  reg rdstrobe_b;

  reg [WIDTH-1:0] ram [0:DEPTH-1];

  /********************************
    Always blocks
  ********************************/

  // port a access
  always @ (posedge clk) begin
    if (ena) begin
      for (i = 0; i < WE; i = i + 1) begin
        if (wea[i])
            ram[addra][8*i +: 8] <= dina[8*i +: 8];
      end
      rddata_a <= ram[addra];
    end
  end

  // port b access
  always @ (posedge clk) begin
    rdstrobe_b <= enb;
    if (enb) begin
      rddata_b <= ram[addrb];
    end
  end

  /********************************
    Direct assignments
  ********************************/

  assign douta = rddata_a;
  assign doutb = rddata_b;

  assign validb = rdstrobe_b;
endmodule

`resetall
