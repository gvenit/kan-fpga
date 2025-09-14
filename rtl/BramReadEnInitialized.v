
`resetall
`timescale 1ns / 1ps
`default_nettype none

module BramReadEnInitialized #(
  // Width of AXI stream Input interfaces in bits
  parameter ADDR_WIDTH = 8,
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 8,
  // Strobe Width of AXI stream Output interfaces in bits
  parameter STRB_WIDTH = (DATA_WIDTH/8),
  // Path to ROM Data
  parameter ROM_DATA_PATH = ""
) (
  input  wire                     clka,
  input  wire                     clkb,

  input  wire                     rdena,
  input  wire                     wrena,
  input  wire [STRB_WIDTH-1:0]    wrstrba,
  input  wire [ADDR_WIDTH-1:0]    addra,
  input  wire [DATA_WIDTH-1:0]    dina,
  output wire [DATA_WIDTH-1:0]    douta,
  output wire                     racka,
  
  input  wire                     rdenb,
  input  wire                     wrenb,
  input  wire [STRB_WIDTH-1:0]    wrstrbb,
  input  wire [ADDR_WIDTH-1:0]    addrb,
  input  wire [DATA_WIDTH-1:0]    dinb,
  output wire [DATA_WIDTH-1:0]    doutb,
  output wire                     rackb
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

  reg rdack_a;
  reg rdack_b;

  reg [DATA_WIDTH-1:0] rddata_a;
  reg [DATA_WIDTH-1:0] rddata_b;
  reg [DATA_WIDTH-1:0] ram [DEPTH-1:0];

  initial begin
    $readmemh( ROM_DATA_PATH, ram, 0, DEPTH-1);
  end

  /********************************
  Always blocks
  ********************************/

  always @ (posedge clka) begin
    if (rdena) begin
      rddata_a <= ram[addra];
    end else if (wrena) begin
      for (i = 0; i < STRB_WIDTH; i = i + 1) begin
        if (wrstrba[i])
          ram[addra][WORD_SIZE*i +: WORD_SIZE] <= dina[WORD_SIZE*i +: WORD_SIZE];
      end
    end
    rdack_a <= rdena;
  end

  always @ (posedge clkb) begin
    if (rdenb) begin
      rddata_b <= ram[addrb];
    end else if (wrenb) begin
      for (i = 0; i < STRB_WIDTH; i = i + 1) begin
        if (wrstrbb[i])
          ram[addrb][WORD_SIZE*i +: WORD_SIZE] <= dinb[WORD_SIZE*i +: WORD_SIZE];
      end
    end
    rdack_b <= rdenb;
  end
  
  /********************************
  Direct assignments
  ********************************/

  assign douta = rddata_a;
  assign doutb = rddata_b;

  assign racka = rdack_a;
  assign rackb = rdack_b;

endmodule

`resetall