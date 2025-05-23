`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

(* use_dsp="yes" *)
module DSPELogic #(
  parameter OP0_SIZE = 8,
  parameter OP1_SIZE = 8,
  parameter ACC_SIZE = 8,
  parameter PIPELINE_LEVEL = 0,
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

  reg  [OP0_SIZE-1:0]    op0_reg = {OP0_SIZE{1'b0}};
  reg  [OP1_SIZE-1:0]    op1_reg = {OP1_SIZE{1'b0}};
  reg  [ACC_SIZE-1:0]    op2_reg = {ACC_SIZE{1'b0}};
  reg  [MLT_SIZE-1:0]    mlt_reg = {MLT_SIZE{1'b0}};
  reg  [ACC_SIZE-1:0]    acc_reg = {ACC_SIZE{1'b0}};

  reg                    bypass_mlt_reg = 1'b0;
  reg  [1:0]             bypass_add_reg = 2'b0;
  reg  [1:0]             reset_acc_reg  = 2'b0;

  reg  [EXTRA_SIGNAL_SIZE-1:0] extra_sig_reg_0;
  reg  [EXTRA_SIGNAL_SIZE-1:0] extra_sig_reg_1;

 generate
  initial begin
    extra_sig_reg_0  = {EXTRA_SIGNAL_SIZE{1'b0}};
    extra_sig_reg_1  = {EXTRA_SIGNAL_SIZE{1'b0}};
  end

  always @(posedge clk ) begin
    if (rst) begin
      if (PIPELINE_LEVEL > 1) begin : stage_in_rst_genblock
        op0_reg <= {OP0_SIZE{1'b0}};
        op1_reg <= {OP1_SIZE{1'b0}};
        op2_reg <= {ACC_SIZE{1'b0}};

        bypass_mlt_reg     <= 1'b0;
        bypass_add_reg [0] <= 1'b0;
        reset_acc_reg  [0] <= 1'b0;

        extra_sig_reg_0  <= {EXTRA_SIGNAL_SIZE{1'b0}};
      end

      if (PIPELINE_LEVEL > 0) begin : stage_mlt_rst_genblock
        mlt_reg <= {MLT_SIZE{1'b0}};

        extra_sig_reg_1  <= {EXTRA_SIGNAL_SIZE{1'b0}};
      end

      // Stage Acc Reset
      acc_reg  <= {ACC_SIZE{1'b0}};


    end else begin
      if (PIPELINE_LEVEL > 1) begin : stage_in_genblock
        op0_reg <= op0;
        op1_reg <= op1;
        op2_reg <= op2;

        bypass_mlt_reg     <= bypass_mlt;
        bypass_add_reg [0] <= bypass_add;
        reset_acc_reg  [0] <= reset_acc;

        extra_sig_reg_0   <= extra_sig_in;
      end

      if (PIPELINE_LEVEL > 0) begin : stage_mlt_genblock
        if (bypass_mlt_reg) begin
          mlt_reg <= op2_reg;
        end else begin
          mlt_reg <= $signed(op0_reg) * $signed(op1_reg);
        end
        bypass_add_reg [1] <= bypass_add_reg [0];
        reset_acc_reg  [1] <= reset_acc_reg  [0];

        extra_sig_reg_1  <= extra_sig_reg_0 ;
      end
      
      if (bypass_add_reg[1] && reset_acc_reg[1]) begin
        acc_reg <= {ACC_SIZE{1'b0}};
      end else if (reset_acc_reg[1]) begin
        acc_reg <= $signed(mlt_reg);
      end else if (bypass_add_reg[1]) begin
        acc_reg <= acc_reg;
      end else begin
        acc_reg <= $signed(acc_reg) + $signed(mlt_reg);
      end
    end
  end

  if (PIPELINE_LEVEL < 2) begin : do_not_stage_inputs_genblock
    always @(*) begin
      op0_reg <= op0;
      op1_reg <= op1;
      op2_reg <= op2;

      bypass_mlt_reg     <= bypass_mlt;
      bypass_add_reg [0] <= bypass_add;
      reset_acc_reg  [0] <= reset_acc;
    
      extra_sig_reg_0  <= extra_sig_in;
    end
  end
    
  if (PIPELINE_LEVEL < 1) begin : do_not_stage_mlt_genblock
    always @(*) begin
      if (bypass_mlt_reg) begin
        mlt_reg <= op2_reg;
      end else begin
        mlt_reg  <= $signed(op0_reg) * $signed(op1_reg);
      end
      bypass_add_reg [1] <= bypass_add_reg [0];
      reset_acc_reg  [1] <= reset_acc_reg  [0];

      extra_sig_reg_1  <= extra_sig_reg_0 ;
    end
  end

 endgenerate

 assign acc = acc_reg;
 assign extra_sig_out = extra_sig_reg_1 ;
    
endmodule