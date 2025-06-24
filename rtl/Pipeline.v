`resetall
`timescale 1ns/1ps
`default_nettype none

module Pipeline #(
  parameter DATA_WIDTH = 8,
  parameter LEVEL = 2
) (
  input  wire clk,
  input  wire rst,

  input  wire [DATA_WIDTH-1:0] din,
  output wire [DATA_WIDTH-1:0] dout
);

  reg [DATA_WIDTH-1:0] pipe [0:LEVEL-1];

  integer stage;
  always @(posedge clk ) begin
    if (rst) begin
      for (stage = 0; stage < LEVEL; stage = stage + 1) begin
        pipe[stage] = 0;
      end
    end else begin
      pipe[0] = din;
      for (stage = 1; stage < LEVEL; stage = stage + 1) begin
        pipe[stage] = pipe[stage - 1];
      end
    end
  end

  assign dout = pipe[LEVEL - 1];

endmodule

`resetall
