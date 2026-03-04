/*
  MIT License

  Copyright (c) 2025 Georgios Venitourakis

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

module ROM_simple #(
  // Width of AXI stream Input interfaces in bits
  parameter ADDR_WIDTH = 8,
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 8,
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "",
  // Use synchronous reads
  parameter IS_SYNC = 1
) (
  input  wire [CHANNELS-1:0]            clk,
  input  wire [CHANNELS-1:0]            en,
  input  wire [CHANNELS*ADDR_WIDTH-1:0] addr,
  output wire [CHANNELS*DATA_WIDTH-1:0] data,
  output wire [CHANNELS-1:0]            ack
);

 genvar CHN;
 generate
 for (CHN = 0; CHN < CHANNELS; CHN = CHN+2) begin : ROM_if_genblock

  wire                  clka  = clk [CHN];
  wire [ADDR_WIDTH-1:0] addra = addr[CHN*ADDR_WIDTH +: ADDR_WIDTH];
  wire                  rdena = en  [CHN];

  wire [DATA_WIDTH-1:0] douta;
  wire                  racka;

  assign data [CHN*DATA_WIDTH +: DATA_WIDTH] = douta;
  assign ack  [CHN] = racka;

  wire                  clkb;
  wire [ADDR_WIDTH-1:0] addrb;
  wire                  rdenb;
  wire [DATA_WIDTH-1:0] doutb;
  wire                  rackb;
  
  if (CHN+1 < CHANNELS) begin
    assign clkb  = clk [(CHN+1)];
    assign addrb = addr[(CHN+1)*ADDR_WIDTH +: ADDR_WIDTH];
    assign rdenb = en  [(CHN+1)];
    assign data [(CHN+1)*DATA_WIDTH +: DATA_WIDTH] = doutb;
    assign ack  [(CHN+1)] = rackb;
  end

  BramReadEnInitialized #( 
    .ADDR_WIDTH     (ADDR_WIDTH),
    .DATA_WIDTH     (DATA_WIDTH),
    .STRB_WIDTH     (1),
    .ROM_DATA_PATH  (ROM_DATA_PATH)
  ) dp_rom_inst ( 
    .clka     (clka),
    .clkb     (clkb),
    .rdena    (rdena),
    .wrena    (1'b0),
    .wrstrba  (1'b0),
    .addra    (addra),
    .dina     ({DATA_WIDTH{1'b0}}),
    .douta    (douta),
    .racka    (racka),
    .rdenb    (rdenb),
    .wrenb    (1'b0),
    .wrstrbb  (1'b0),
    .addrb    (addrb),
    .dinb     ({DATA_WIDTH{1'b0}}),
    .doutb    (doutb),
    .rackb    (rackb)
  );

 end
 endgenerate

endmodule

`resetall
