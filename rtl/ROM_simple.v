
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
