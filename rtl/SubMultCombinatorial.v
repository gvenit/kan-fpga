`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  SubMult : Accepts three input AXI-Stream frames and returns
 *    the result (x-grid)*scale.
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */
 
(* use_dsp="yes" *)
module SubMultCombinatorial #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scale
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12
) (
  input  wire [DATA_WIDTH-1:0]    A,
  input  wire [DATA_WIDTH-1:0]    B,
  input  wire [SCALE_WIDTH-1:0]   C,
  output wire [RSLT_WIDTH-1:0]    R
);
  localparam OP_SIZE  = (RSLT_WIDTH > DATA_WIDTH + SCALE_WIDTH) ? RSLT_WIDTH : DATA_WIDTH + SCALE_WIDTH;
  localparam RSLT_LSB = DATA_FRACTIONAL_BITS + SCALE_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS;
  localparam RSLT_MSB = RSLT_LSB + RSLT_WIDTH - 1;

  wire signed [DATA_WIDTH-1:0]              A_in = $signed(A);
  wire signed [DATA_WIDTH-1:0]              B_in = $signed(B);
  wire signed [SCALE_WIDTH-1:0]             C_in = $signed(C);
  wire signed [DATA_WIDTH+SCALE_WIDTH-1:0]  R_in;

  assign R_in = $signed(A_in-B_in) * C_in;

  assign R = R_in[RSLT_MSB:RSLT_LSB];

endmodule
`resetall
