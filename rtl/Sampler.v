`resetall
`timescale 1ns/1ps
`default_nettype none

module Sampler (
  input  wire signal_clk,
  input  wire sampler_clk,
  input  wire signal,
  output reg  sampled_signal
);

  reg captured_signal = 1'b0;

  // Output Driver
  always @(posedge sampler_clk ) begin
    sampled_signal <= captured_signal;
  end

  always @(posedge sampler_clk ) begin
    captured_signal <= 1'b0;
  end

  always @(posedge signal_clk ) begin
    captured_signal <= captured_signal || signal;
  end

endmodule

`resetall
