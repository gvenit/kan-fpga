`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * ParallelizedLinearProcessingElement : Accepts and returns two AXI-Streams
 *   from neighbouring `ParallelizedLinearProcessingElement` modules. Input
 *   streams are up (i,j-1) and left (i-1,j) and output wire streams
 *   are down (i,j+1) and right (i+1,j). The module works as a
 *   node of a systolic array for the Matrix-Matrix Multiplication.
 * 
 * 
 * Array Positioning :
 *              i
 *       --------------->
 *   |  {0,0}  ...  {I-1,0}
 *  j|   ...          ...
 *   v {0,J-1} ... {I-1,J-1} 
 */

module ParallelizedLPEWrapper #(
  // Number of PEs in Processing Array i axis
  parameter PE_NUMBER_I = 4,
  // Number of PEs in Processing Array j axis
  parameter PE_NUMBER_J = 4,
  // Position of current PE in the i axis
  parameter PE_POSITION_I = 0,
  // Position of current PE in the j axis
  parameter PE_POSITION_J = 0,
  // Data Width of Input Data (L-AXIS)
  parameter OP0_WIDTH = 16,
  // Fractional Bits of Input Data (L-AXIS)
  parameter OP0_FRACTIONAL_BITS = 12,
  // Treat operand 0 as unsigned
  parameter IS_UNSIGNED_OP0 = 0,
  // Data Width of Input Weights (T-AXIS)
  parameter OP1_WIDTH = 16,
  // Fractional Bits of Input Weights (T-AXIS)
  parameter OP1_FRACTIONAL_BITS = 12,
  // Treat operand 1 as unsigned
  parameter IS_UNSIGNED_OP1 = 0,
  // Data Width of Output Data (D-AXIS)
  parameter PSUM_WIDTH = OP0_WIDTH + OP1_WIDTH
) (
  input  wire                         clk,
  input  wire                         rst,

  /*
   * AXI Stream Left Input
   */
  input  wire [OP0_WIDTH-1:0]         s_axis_l_tdata,
  input  wire                         s_axis_l_tvalid,
  output wire                         s_axis_l_tready,
  input  wire                         s_axis_l_tlast,

  /*
   * AXI Stream Right Output
   */
  output wire [OP0_WIDTH-1:0]         m_axis_r_tdata,
  output wire                         m_axis_r_tvalid,
  input  wire                         m_axis_r_tready,
  output wire                         m_axis_r_tlast,

  /*
   * AXI Stream Top Input
   */
  input  wire [OP1_WIDTH-1:0]         s_axis_t_tdata,
  input  wire                         s_axis_t_tvalid,
  output wire                         s_axis_t_tready,
  input  wire                         s_axis_t_tlast,

  /*
   * AXI Stream Bottom Output
   */
  output wire [OP1_WIDTH-1:0]         m_axis_b_tdata,
  output wire                         m_axis_b_tvalid,
  input  wire                         m_axis_b_tready,
  output wire                         m_axis_b_tlast,

  /*
   * AXI Stream Up Input
   */
  input  wire [PSUM_WIDTH-1:0]        s_axis_u_tdata,
  input  wire                         s_axis_u_tvalid,
  output wire                         s_axis_u_tready,
  input  wire                         s_axis_u_tlast,

  /*
   * AXI Stream Down Output
   */
  output wire [PSUM_WIDTH-1:0]        m_axis_d_tdata,
  output wire                         m_axis_d_tvalid,
  input  wire                         m_axis_d_tready,
  output wire                         m_axis_d_tlast,

  /*
   * Error Outputs
   */
  output wire err_unalligned_data
);
  ParallelizedLinearProcessingElement #(
    // Number of PEs in Processing Array i axis
    .PE_NUMBER_I(PE_NUMBER_I),
    // Number of PEs in Processing Array j axis
    .PE_NUMBER_J(PE_NUMBER_J),
    // Position of current PE in the i axis
    .PE_POSITION_I(PE_POSITION_I),
    // Position of current PE in the j axis
    .PE_POSITION_J(PE_POSITION_J),
    // Data Width of Input Data (L-AXIS)
    .OP0_WIDTH(OP0_WIDTH),
    // Fractional Bits of Input Data (L-AXIS)
    .OP0_FRACTIONAL_BITS(OP0_FRACTIONAL_BITS),
    // Treat operand 0 as unsigned
    .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
    // Data Width of Input Weights (T-AXIS)
    .OP1_WIDTH(OP1_WIDTH),
    // Fractional Bits of Input Weights (T-AXIS)
    .OP1_FRACTIONAL_BITS(OP1_FRACTIONAL_BITS),
    // Treat operand 1 as unsigned
    .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
    // Data Width of Output Data (D-AXIS)
    .PSUM_WIDTH(PSUM_WIDTH)
  ) parallelized_lpe_inst (
    .clk                    (clk),
    .rst                    (rst),
    .s_axis_u_tdata         (s_axis_u_tdata),
    .s_axis_u_tvalid        (s_axis_u_tvalid),
    .s_axis_u_tready        (s_axis_u_tready),
    .s_axis_u_tlast         (s_axis_u_tlast),
    .m_axis_d_tdata         (m_axis_d_tdata),
    .m_axis_d_tvalid        (m_axis_d_tvalid),
    .m_axis_d_tready        (m_axis_d_tready),
    .m_axis_d_tlast         (m_axis_d_tlast),
    .s_axis_l_tdata         (s_axis_l_tdata),
    .s_axis_l_tvalid        (s_axis_l_tvalid),
    .s_axis_l_tready        (s_axis_l_tready),
    .s_axis_l_tlast         (s_axis_l_tlast),
    .m_axis_r_tdata         (m_axis_r_tdata),
    .m_axis_r_tvalid        (m_axis_r_tvalid),
    .m_axis_r_tready        (m_axis_r_tready),
    .m_axis_r_tlast         (m_axis_r_tlast),
    .s_axis_t_tdata         (s_axis_t_tdata),
    .s_axis_t_tvalid        (s_axis_t_tvalid),
    .s_axis_t_tready        (s_axis_t_tready),
    .s_axis_t_tlast         (s_axis_t_tlast),
    .m_axis_b_tdata         (m_axis_b_tdata),
    .m_axis_b_tvalid        (m_axis_b_tvalid),
    .m_axis_b_tready        (m_axis_b_tready),
    .m_axis_b_tlast         (m_axis_b_tlast),
    .err_unalligned_data    (err_unalligned_data)
  );

endmodule

`resetall
