`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

(* use_dsp="yes" *)
module DSPELogic #(
  parameter OP0_SIZE = 8,
  parameter OP1_SIZE = 8,
  parameter ACC_SIZE = 8,
  parameter USE_OP2 = 0,
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

  reg  signed [OP0_SIZE-1:0]    op0_reg = 0;
  reg  signed [OP1_SIZE-1:0]    op1_reg = 0;
  reg  signed [ACC_SIZE-1:0]    op2_reg = 0;
  reg  signed [MLT_SIZE-1:0]    mlt_reg = 0;
  reg  signed [ACC_SIZE-1:0]    old_reg = 0;
  reg  signed [ACC_SIZE-1:0]    acc_reg = 0;

  reg  bypass_mlt_reg_0 = 1'b0;
  reg  bypass_add_reg_0 = 1'b0;
  reg  reset_acc_reg_0  = 1'b0;
  reg  bypass_mlt_reg_1 = 1'b0;
  reg  bypass_add_reg_1 = 1'b0;
  reg  reset_acc_reg_1  = 1'b0;

  reg  [EXTRA_SIGNAL_SIZE-1:0] extra_sig_reg_0;
  reg  [EXTRA_SIGNAL_SIZE-1:0] extra_sig_reg_1;

  wire ce_in     = ~bypass_mlt;
  wire ce_op2    =  bypass_mlt && ~bypass_add;
  wire ce_mlt    = ~bypass_mlt_reg_0;
  wire ce_acc    = ~bypass_add_reg_1;
  wire sload     =  reset_acc_reg_1;

  wire rst_in    =  rst;
  wire rst_op2   =  rst;
  wire rst_mlt   =  rst;
  wire rst_acc   =  bypass_add_reg_1 &&  reset_acc_reg_1;


  always @(sload or acc_reg) begin
    if (sload)
      old_reg <= 0;
    else
      old_reg <= acc_reg;
  end

  always @(posedge clk) begin
    if (rst) begin
      bypass_mlt_reg_0  <= 1'b1;   
      bypass_add_reg_0  <= 1'b1;   
      reset_acc_reg_0   <= 1'b1; 

      bypass_mlt_reg_1  <= 1'b1;   
      bypass_add_reg_1  <= 1'b1;   
      reset_acc_reg_1   <= 1'b1;

      extra_sig_reg_0   <= 0;
      extra_sig_reg_1   <= 0;
    end else begin
      bypass_mlt_reg_0  <= bypass_mlt;   
      bypass_add_reg_0  <= bypass_add;   
      reset_acc_reg_0   <= reset_acc; 

      bypass_mlt_reg_1  <= bypass_mlt_reg_0;   
      bypass_add_reg_1  <= bypass_add_reg_0;   
      reset_acc_reg_1   <= reset_acc_reg_0;

      extra_sig_reg_0   <= extra_sig_in;
      extra_sig_reg_1   <= extra_sig_reg_0;
    end

    // Multiplier Input
    if (rst) begin
      op0_reg     <= op0;
      op1_reg     <= op1;
    end else if (ce_in) begin
      op0_reg     <= op0;
      op1_reg     <= op1;
    end

    // Multiplier Output
    if (rst_mlt) begin
      mlt_reg <= 0;
    end else if (ce_mlt) begin
      mlt_reg <= op0_reg * op1_reg;
    end

    if (rst_acc) begin
      // Store accumulation result into a register
      acc_reg <= 0;
    end else if (ce_acc) begin
      // Store accumulation result into a register
      acc_reg <= old_reg + mlt_reg;
    end
  end 
 

 generate
  if (USE_OP2) begin : accumulate_genblock
    reg  [ACC_SIZE-1:0] old_psum = 0;
    reg  [ACC_SIZE-1:0] psum = 0;

    reg  psum_load = 1'b0;
      
    always @(psum_load or acc_reg or psum) begin
      if (psum_load)
        old_psum <= acc_reg;
      else
        old_psum <= psum;
    end

    always @(posedge clk) begin
      psum_load <= ce_acc && ~bypass_mlt_reg_1;

      // Register C
      if (rst_op2) begin
        op2_reg <= 0;
      end else if (ce_op2) begin
        op2_reg <= op2;
      end

      if (rst_acc) begin
        // Store accumulation result into a register
        psum <= 0;
      end else if (ce_acc) begin
        // Store accumulation result into a register
        psum <= old_psum + op2_reg;
      end else if (psum_load) begin
        psum <= old_psum;
      end
    end 

    // Output accumulation result
    assign acc = psum;
  end else begin : skip_accumulate_genblock
    // Output accumulation result
    assign acc = acc_reg;
  end
 endgenerate
 
  // Output accumulation result
  assign extra_sig_out = extra_sig_reg_1;
    
endmodule

`resetall
