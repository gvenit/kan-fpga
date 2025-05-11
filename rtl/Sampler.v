`resetall
`timescale 1ns/1ps
`default_nettype none

module Sampler (
  input  wire clk,
  input  wire signal,
  output reg  sampled_signal
);

  reg switch = 1'b0;

  wire [1:0] samples_in;
  reg  [1:0] samples_out = 2'b0;

  // Switch
  always @(posedge clk ) begin
    switch <= !switch;
  end

  // Demultiplexer
  assign samples_in[0] = signal &&  switch;
  assign samples_in[1] = signal && !switch;

  // Registers
  always @(posedge samples_in[0] or posedge switch) begin
    if (switch) begin
      samples_out[0] <= 1'b0;
    end else begin
      samples_out[0] <= 1'b1;
    end
  end
  always @(posedge samples_in[1] or negedge switch) begin
    if (!switch) begin
      samples_out[1] <= 1'b0;
    end else begin
      samples_out[1] <= 1'b1;
    end
  end

  always @(posedge clk ) begin
    sampled_signal <= |samples_out;
  end

endmodule

`resetall
