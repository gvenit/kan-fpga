`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

(* use_dsp="yes" *)
module DSPELogic #(
  parameter OP0_SIZE = 8,
  parameter OP1_SIZE = 8,
  parameter ACC_SIZE = OP0_SIZE + OP1_SIZE,
  parameter PIPELINE_LEVEL = 2,
  parameter EXTRA_SIGNAL_SIZE = 1
) (
  input  wire                         clk,
  input  wire                         rst,

  // Flow Controll Signals      
  input  wire                         bypass_mlt,
  input  wire                         bypass_add,
  input  wire                         reset_acc,

  // Data Signals     
  input  wire [OP0_SIZE-1:0]          op0,
  input  wire [OP1_SIZE-1:0]          op1,
  input  wire [ACC_SIZE-1:0]          op2,
  output wire [ACC_SIZE-1:0]          acc,

  // Extra Signals
  input  wire [EXTRA_SIGNAL_SIZE-1:0] extra_sig_in,
  output wire [EXTRA_SIGNAL_SIZE-1:0] extra_sig_out
);

  localparam MLT_SIZE = `MAX( OP0_SIZE+OP1_SIZE, ACC_SIZE);

  reg signed [OP0_SIZE-1:0]   op0_reg = {OP0_SIZE{1'b0}};
  reg signed [OP1_SIZE-1:0]   op1_reg = {OP1_SIZE{1'b0}};
  reg signed [ACC_SIZE-1:0]   op2_reg = {ACC_SIZE{1'b0}};
  reg signed [MLT_SIZE-1:0]   mlt_reg = {MLT_SIZE{1'b0}}, mux_reg;
  reg signed [ACC_SIZE-1:0]   acc_reg = {ACC_SIZE{1'b0}}, old_acc;

  reg                    bypass_mlt_reg = 1'b0;
  reg  [1:0]             bypass_add_reg = 2'b0;
  reg  [1:0]             reset_acc_reg  = 2'b0;

  reg  [EXTRA_SIGNAL_SIZE-1:0] extra_sig_reg [0:1];

 generate
  initial begin
    extra_sig_reg [0] = {EXTRA_SIGNAL_SIZE{1'b0}};
    extra_sig_reg [1] = {EXTRA_SIGNAL_SIZE{1'b0}};
  end

  if (PIPELINE_LEVEL > 1) begin : full_pipeline_genblock
    always @(bypass_add_reg or mlt_reg) begin
      if (bypass_add_reg)
        mux_reg <= 0;
      else
        mux_reg <= mlt_reg;
    end

    always @(reset_acc_reg[1] or acc_reg) begin
      if (reset_acc_reg[1])
        old_acc <= 0;
      else
        old_acc <= acc_reg;
    end

    always @(posedge clk) begin
      if (rst) begin
        op0_reg <= {OP0_SIZE{1'b0}};
        op1_reg <= {OP1_SIZE{1'b0}};
        op2_reg <= {ACC_SIZE{1'b0}};
        mlt_reg <= {MLT_SIZE{1'b0}};
        acc_reg <= {ACC_SIZE{1'b0}};

        bypass_mlt_reg <= 1'b0;
        bypass_add_reg <= 1'b0;
        reset_acc_reg  <= 2'b0;

        extra_sig_reg [0] = {EXTRA_SIGNAL_SIZE{1'b0}};
        extra_sig_reg [1] = {EXTRA_SIGNAL_SIZE{1'b0}};

      end else begin
        // Stage Input
        op0_reg  <= op0;
        op1_reg  <= op1;
        op2_reg  <= op2;
        extra_sig_reg [0] <= extra_sig_in;

        bypass_mlt_reg    <= bypass_mlt;
        bypass_add_reg    <= bypass_add;
        reset_acc_reg [0] <= reset_acc;

        // Stage Multiplier
        mlt_reg  <= (bypass_mlt_reg) ? op2_reg : op0_reg * op1_reg;
        extra_sig_reg [1] <= extra_sig_reg [0];

        reset_acc_reg [1] <= reset_acc_reg[0];

        // Stage Accumulator
        acc_reg <= old_acc + mux_reg;
      end
    end

    // Output accumulation result
    assign acc = acc_reg;

  end else if (PIPELINE_LEVEL > 0) begin : half_pipeline_genblock
    always @(bypass_add or mlt_reg) begin
      if (bypass_add)
        mux_reg <= 0;
      else
        mux_reg <= mlt_reg;
    end

    always @(reset_acc_reg[0] or acc_reg) begin
      if (reset_acc_reg[0])
        old_acc <= 0;
      else
        old_acc <= acc_reg;
    end

    always @(posedge clk) begin
      if (rst) begin
        mlt_reg <= {MLT_SIZE{1'b0}};
        acc_reg <= {ACC_SIZE{1'b0}};

        reset_acc_reg  <= 2'b0;

        extra_sig_reg [0] = {EXTRA_SIGNAL_SIZE{1'b0}};
        extra_sig_reg [1] = {EXTRA_SIGNAL_SIZE{1'b0}};

      end else begin
        // Stage Multiplier
        mlt_reg  <= (bypass_mlt) ? op2 : op0 * op1;
        extra_sig_reg [1] <= extra_sig_in;

        reset_acc_reg [0] <= reset_acc;

        // Stage Accumulator
        acc_reg <= old_acc + mux_reg;
      end
    end

  end else begin
    always @(extra_sig_in) begin
      extra_sig_reg [1] <= extra_sig_in;
    end

    always @(bypass_mlt, op0, op1, op2) begin
      if (bypass_mlt)
        mlt_reg  <= op2;
      else
        mlt_reg  <= op0 * op1;
    end

    always @(bypass_add or mlt_reg) begin
      if (bypass_add)
        mux_reg <= 0;
      else
        mux_reg <= mlt_reg;
    end

    always @(reset_acc or acc_reg) begin
      if (reset_acc)
        old_acc <= 0;
      else
        old_acc <= acc_reg;
    end

    always @(posedge clk) begin
      if (rst) begin
        acc_reg <= {ACC_SIZE{1'b0}};
      end else begin
        // Stage Accumulator
        acc_reg <= old_acc + mux_reg;
      end
    end
  end
		
 endgenerate

 assign acc = acc_reg;
 assign extra_sig_out = extra_sig_reg [1];
    
endmodule