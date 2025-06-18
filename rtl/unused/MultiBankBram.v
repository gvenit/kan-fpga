`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

module MultiBankBram #(
  parameter BANKS = 4,
  parameter WIDTH = 16,
  parameter DEPTH = 256,
  parameter ADDR = `LOG2(DEPTH),
  parameter WE = WIDTH / 8
) (
  input  wire                       clka,
  input  wire                       clkb,

  input  wire [BANKS-1:0]           ena,    
  input  wire [BANKS*WE-1:0]        wea,    
  input  wire [BANKS*ADDR-1:0]      addra,  
  input  wire [BANKS*WIDTH-1:0]     dina,  
  output wire [BANKS*WIDTH-1:0]     douta,

  input  wire [BANKS-1:0]           enb,    
  input  wire [BANKS*ADDR-1:0]      addrb,  
  output wire [BANKS*WIDTH-1:0]     doutb,  
  output wire [BANKS-1:0]           validb
);

genvar i;

generate
  for (i = 0; i < BANKS; i = i + 1) begin : bram_genblock
    Bram #(
      .WIDTH    (WIDTH),
      .DEPTH    (DEPTH),
      .ADDR     (ADDR)
    ) bram_inst (
      .clka     (clka),
      .clkb     (clkb),
      .ena      (ena    [i]),
      .wea      (wea    [i*WE +: WE]),
      .addra    (addra  [i*ADDR +: ADDR]),
      .dina     (dina   [i*WIDTH +: WIDTH]),
      .douta    (douta  [i*WIDTH +: WIDTH]),
      .enb      (enb    [i]),
      .addrb    (addrb  [i*ADDR +: ADDR]),
      .doutb    (doutb  [i*WIDTH +: WIDTH]),
      .validb   (validb [i])
    );
  end
endgenerate

endmodule

`resetall