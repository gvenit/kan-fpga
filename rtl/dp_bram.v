`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * dp_bram : A Duap Port Block RAM
 * 
 */
module dp_bram #(
    // Width of data bus in bits
    parameter DATA_WIDTH = 32,
    // Width of address bus in bits
    parameter ADDR_WIDTH = 16,
    // Width of wstrb (width of data bus in words)
    parameter STRB_WIDTH = (DATA_WIDTH/8)
) (
    input wire                  aclk,
    input wire [STRB_WIDTH-1:0] awr_en,
    input wire [ADDR_WIDTH-1:0] aaddr,
    input wire [DATA_WIDTH-1:0] adata_in,
    output reg [DATA_WIDTH-1:0] adata_out,

    input wire                  bclk,
    input wire [ADDR_WIDTH-1:0] baddr,
    output reg [DATA_WIDTH-1:0] bdata_out
);
  localparam WORD_WIDTH = STRB_WIDTH;
  localparam WORD_SIZE = DATA_WIDTH/WORD_WIDTH;

  // (* RAM_STYLE="BLOCK" *)
  reg [31:0] mem [0:1023];

  integer word_i;

  always @(posedge aclk) begin
    for (word_i=0; word_i < STRB_WIDTH; word_i=word_i+1) begin
      if (awr_en[word_i]) begin
          mem[aaddr][WORD_SIZE*word_i +: WORD_SIZE] <= adata_in[WORD_SIZE*word_i +: WORD_SIZE];
      end
    end
    adata_out <= mem[aaddr];
  end
  
  always @(posedge bclk) begin
    bdata_out <= mem[baddr];
  end
endmodule

`resetall
