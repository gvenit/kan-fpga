`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * LinearProcessingUnit : Accepts N+M and returns N AXI-Streams. Input
 *   The module works as a systolic array for the Matrix-Matrix Multiplication.
 * 
 * Array Positioning :
 *              i
 *       --------------->
 *   |  {0,0}  ...  {I-1,0}
 *  j|   ...          ...
 *   v {0,J-1} ... {I-1,J-1} 
 */

module ParallelizedLPAWrapper #(
  // Number of PEs in Processing Array i axis -- Number of results per batch per run
  parameter PE_NUMBER_I = 1,
  // Number of PEs in Processing Array j axis -- Number of partial sums per result
  parameter PE_NUMBER_J = 1,
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,
  // Enable module to do internal resets
  parameter INTERNAL_RESET = 0,
  // Data Width of Input Data (L-AXIS)
  parameter OP0_WIDTH = 16,
  // Fractional Bits of Input Data (L-AXIS)
  parameter OP0_FRACTIONAL_BITS = 12,
  // Treat operand 0 as unsigned
  parameter IS_UNSIGNED_OP0 = 0,
  // Data Width of Input Weights (U-AXIS)
  parameter OP1_WIDTH = 16,
  // Fractional Bits of Input Weights (U-AXIS)
  parameter OP1_FRACTIONAL_BITS = 12,
  // Treat operand 1 as unsigned
  parameter IS_UNSIGNED_OP1 = 0,
  // Data Width of Output Data (D-AXIS)
  parameter RSLT_WIDTH = 16,
  // Fractional Bits of Output Data (D-AXIS)
  parameter RSLT_FRACTIONAL_BITS = 12,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = (ID_ENABLE) ? 8 : 1,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 :1,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1, 
  // Output User
  parameter OUTPUT_USER = 0,
  // Output Destination 
  parameter OUTPUT_DEST = 0,
  // Output Thread ID 
  parameter OUTPUT_ID = 1
) (
  input  wire                                                 clk,
  input  wire                                                 rst,

  /*
   * AXI Stream Top Input -- Weight Input
   */
  input  wire [PE_NUMBER_I*PE_NUMBER_J*OP1_WIDTH-1:0]    s_axis_t_tdata,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tvalid,
  output wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tready,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tlast,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*ID_WIDTH-1:0]          s_axis_t_tid,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*DEST_WIDTH-1:0]        s_axis_t_tdest,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*USER_WIDTH-1:0]        s_axis_t_tuser,

  /*
   * AXI Stream Left Input -- Data Input
   */
  input  wire [PE_NUMBER_J*BATCH_SIZE*OP0_WIDTH-1:0]    s_axis_l_tdata,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_l_tvalid,
  output wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_l_tready,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_l_tlast,
  input  wire [PE_NUMBER_J*BATCH_SIZE*ID_WIDTH-1:0]          s_axis_l_tid,
  input  wire [PE_NUMBER_J*BATCH_SIZE*DEST_WIDTH-1:0]        s_axis_l_tdest,
  input  wire [PE_NUMBER_J*BATCH_SIZE*USER_WIDTH-1:0]        s_axis_l_tuser,

  /*
   * AXI Stream Down Output -- Partial Sum Output
   */
  output wire [PE_NUMBER_I*BATCH_SIZE*RSLT_WIDTH-1:0]   m_axis_d_tdata,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_d_tvalid,
  input  wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_d_tready,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_d_tlast,
  output wire [PE_NUMBER_I*BATCH_SIZE*ID_WIDTH-1:0]          m_axis_d_tid,
  output wire [PE_NUMBER_I*BATCH_SIZE*DEST_WIDTH-1:0]        m_axis_d_tdest,
  output wire [PE_NUMBER_I*BATCH_SIZE*USER_WIDTH-1:0]        m_axis_d_tuser,

  /*
   * Error Outputs
   */
  output wire err_unalligned_data,

  /*
   * Interrupts
   */
  output wire core_rst
);

ParallelizedLinearProcessingArray #(
  .PE_NUMBER_I(PE_NUMBER_I),
  .PE_NUMBER_J(PE_NUMBER_J),
  .BATCH_SIZE(BATCH_SIZE),
  .INTERNAL_RESET(INTERNAL_RESET),
  .OP0_WIDTH(OP0_WIDTH),
  .OP0_FRACTIONAL_BITS(OP0_FRACTIONAL_BITS),
  .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
  .OP1_WIDTH(OP1_WIDTH),
  .OP1_FRACTIONAL_BITS(OP1_FRACTIONAL_BITS),
  .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
  .RSLT_WIDTH(RSLT_WIDTH),
  .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
  .ID_ENABLE(ID_ENABLE),
  .ID_WIDTH(ID_WIDTH),
  .DEST_ENABLE(DEST_ENABLE),
  .DEST_WIDTH(DEST_WIDTH),
  .USER_ENABLE(USER_ENABLE),
  .USER_WIDTH(USER_WIDTH), 
  .OUTPUT_USER(OUTPUT_USER),
  .OUTPUT_DEST(OUTPUT_DEST),
  .OUTPUT_ID(OUTPUT_ID)
) parallelized_lpa_inst (
  .clk(clk),
  .rst(rst),
  .s_axis_t_tdata(s_axis_t_tdata),
  .s_axis_t_tvalid(s_axis_t_tvalid),
  .s_axis_t_tready(s_axis_t_tready),
  .s_axis_t_tlast(s_axis_t_tlast),
  .s_axis_t_tid(s_axis_t_tid),
  .s_axis_t_tdest(s_axis_t_tdest),
  .s_axis_t_tuser(s_axis_t_tuser),
  .s_axis_l_tdata(s_axis_l_tdata),
  .s_axis_l_tvalid(s_axis_l_tvalid),
  .s_axis_l_tready(s_axis_l_tready),
  .s_axis_l_tlast(s_axis_l_tlast),
  .s_axis_l_tid(s_axis_l_tid),
  .s_axis_l_tdest(s_axis_l_tdest),
  .s_axis_l_tuser(s_axis_l_tuser),
  .m_axis_d_tdata(m_axis_d_tdata),
  .m_axis_d_tvalid(m_axis_d_tvalid),
  .m_axis_d_tready(m_axis_d_tready),
  .m_axis_d_tlast(m_axis_d_tlast),
  .m_axis_d_tid(m_axis_d_tid),
  .m_axis_d_tdest(m_axis_d_tdest),
  .m_axis_d_tuser(m_axis_d_tuser),
  .err_unalligned_data(err_unalligned_data),
  .core_rst(core_rst)
);

endmodule

`resetall
