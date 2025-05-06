
`resetall
`timescale 1ns / 1ps
`default_nettype none

module ROM #(
  // Width of AXI stream Input interfaces in bits
  parameter ADDR_WIDTH = 8,
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 8,
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Path to ROM Data
  parameter ROM_DATA_PATH = ""
) (
  input  wire                           clk,
  input  wire [CHANNELS-1:0]            en,
  input  wire [CHANNELS*ADDR_WIDTH-1:0] addr,
  output wire [CHANNELS*DATA_WIDTH-1:0] data,
  output wire [CHANNELS-1:0]            ack
);

  // LUTRAM Configuration
  (* ROM_STYLE="BLOCK" *)
  reg [DATA_WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

  initial begin
    $readmemh( ROM_DATA_PATH, mem);
  end

genvar CHN;
generate
for (CHN = 0; CHN < CHANNELS; CHN = CHN+1) begin 

  wire [ADDR_WIDTH-1:0] addr_i = addr[CHN*ADDR_WIDTH +: ADDR_WIDTH];
  wire                  en_i   = en  [CHN];

  reg  [DATA_WIDTH-1:0] data_i = 0;
  reg                   ack_i  = 1'b0;

  assign data [CHN*DATA_WIDTH +: DATA_WIDTH] = data_i;
  assign ack  [CHN] = ack_i;

  always @(posedge clk ) begin
    ack_i <= en_i;
    if (en_i) 
      data_i <= mem[addr_i];
  end

end

endgenerate

endmodule

`resetall
