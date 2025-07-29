`resetall
`timescale 1ns/1ps
`default_nettype none

module Sampler (
  input  wire signal_clk,
  input  wire sampler_clk,
  input  wire signal,
  output reg  sampled_signal
);

  reg captured_signal_pos  = 1'b0;
  reg captured_signal_neg  = 1'b0;
  reg captured_signal_pos_sampled = 1'b0;

  reg switch = 1'b0;

  // Output Driver
  always @(posedge sampler_clk ) begin
    sampled_signal <= captured_signal_neg || captured_signal_pos_sampled;
  end

  always @(posedge signal_clk ) begin
    if (switch)
      captured_signal_neg <= 1'b0;
    else 
      captured_signal_neg <= captured_signal_neg || signal;
  end

  always @(posedge signal_clk ) begin
    if (~switch)
      captured_signal_pos <= 1'b0;
    else 
      captured_signal_pos <= captured_signal_pos || signal;
  end

  always @(posedge sampler_clk ) begin
    captured_signal_pos_sampled <= captured_signal_pos;
  end

  always @(posedge sampler_clk ) begin
    switch <= ~switch;
  end

endmodule

`resetall
