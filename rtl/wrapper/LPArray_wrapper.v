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

module LPArray_wrapper #(
    // Number of PEs in Processing Array i axis
    parameter PE_NUMBER_I = 4,
    // Number of PEs in Processing Array j axis
    parameter PE_NUMBER_J = 4,
    // Enable module to do internal resets
    parameter INTERNAL_RESET = 0,
    // Data Width of Input Data (L-AXIS)
    parameter DATA_WIDTH_OP0 = 16,
    // Fractional Bits of Input Data (L-AXIS)
    parameter FRACTIONAL_BITS_OP0 = 12,
    // Treat operand 0 as unsigned
    parameter IS_UNSIGNED_OP0 = 0,
    // Data Width of Input Weights (U-AXIS)
    parameter DATA_WIDTH_OP1 = 16,
    // Treat operand 1 as unsigned
    parameter IS_UNSIGNED_OP1 = 0,
    // Fractional Bits of Input Weights (U-AXIS)
    parameter FRACTIONAL_BITS_OP1 = 12,
    // Data Width of Output Data (D-AXIS)
    parameter DATA_WIDTH_RSLT = 16,
    // Fractional Bits of Output Data (D-AXIS)
    parameter FRACTIONAL_BITS_RSLT = 12,
    // Propagate tid signal
    parameter ID_ENABLE = 0,
    // tid signal width
    parameter ID_WIDTH = (ID_ENABLE) ? 8 : 1,
    // Propagate tdest signal
    parameter DEST_ENABLE = 0,
    // tdest signal width
    parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
    // Propagate tuser signal
    parameter USER_ENABLE = 0,
    // tuser signal width
    parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1 , 
    // Output Destination 
    parameter OUTPUT_DEST = 0,
    // Output Thread ID 
    parameter OUTPUT_ID = 1,
    // Resolve Up/Down Bit Width
    parameter DATA_WIDTH_U_D = (DATA_WIDTH_OP1 > DATA_WIDTH_RSLT) ? DATA_WIDTH_OP1 : DATA_WIDTH_RSLT,
    // Resolve Left/Right Bit Width
    parameter DATA_WIDTH_L_R = DATA_WIDTH_OP0
) (
  input  wire                                     clk,
  input  wire                                     rst,

  /*
   * AXI Stream Up input
   */
  input  wire [PE_NUMBER_I*DATA_WIDTH_U_D-1:0]    s_axis_up_tdata,
  input  wire [PE_NUMBER_I-1:0]                   s_axis_up_tvalid,
  output wire [PE_NUMBER_I-1:0]                   s_axis_up_tready,
  input  wire [PE_NUMBER_I-1:0]                   s_axis_up_tlast,
  input  wire [PE_NUMBER_I*ID_WIDTH-1:0]          s_axis_up_tid,
  input  wire [PE_NUMBER_I*DEST_WIDTH-1:0]        s_axis_up_tdest,
  input  wire [PE_NUMBER_I*USER_WIDTH-1:0]        s_axis_up_tuser,

  /*
   * AXI Stream Left input
   */
  input  wire [PE_NUMBER_J*DATA_WIDTH_L_R-1:0]    s_axis_left_tdata,
  input  wire [PE_NUMBER_J-1:0]                   s_axis_left_tvalid,
  output wire [PE_NUMBER_J-1:0]                   s_axis_left_tready,
  input  wire [PE_NUMBER_J-1:0]                   s_axis_left_tlast,
  input  wire [PE_NUMBER_J*ID_WIDTH-1:0]          s_axis_left_tid,
  input  wire [PE_NUMBER_J*DEST_WIDTH-1:0]        s_axis_left_tdest,
  input  wire [PE_NUMBER_J*USER_WIDTH-1:0]        s_axis_left_tuser,

  /*
   * AXI Stream Down Output
   */
  output wire [PE_NUMBER_I*DATA_WIDTH_U_D-1:0]    m_axis_down_tdata,
  output wire [PE_NUMBER_I-1:0]                   m_axis_down_tvalid,
  input  wire [PE_NUMBER_I-1:0]                   m_axis_down_tready,
  output wire [PE_NUMBER_I-1:0]                   m_axis_down_tlast,
  output wire [PE_NUMBER_I*ID_WIDTH-1:0]          m_axis_down_tid,
  output wire [PE_NUMBER_I*DEST_WIDTH-1:0]        m_axis_down_tdest,
  output wire [PE_NUMBER_I*USER_WIDTH-1:0]        m_axis_down_tuser,

  /*
   * Error Outputs
   */
  output wire err_unalligned_data,
  output wire err_user_flag
);

LinearProcessingArray #(
  .PE_NUMBER_I(PE_NUMBER_I),
  .PE_NUMBER_J(PE_NUMBER_J),
  .INTERNAL_RESET(INTERNAL_RESET),
  .DATA_WIDTH_OP0(DATA_WIDTH_OP0),
  .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
  .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
  .DATA_WIDTH_OP1(DATA_WIDTH_OP1),
  .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
  .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
  .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
  .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
  .ID_ENABLE(ID_ENABLE),
  .ID_WIDTH(ID_WIDTH),
  .DEST_ENABLE(DEST_ENABLE),
  .DEST_WIDTH(DEST_WIDTH),
  .USER_ENABLE(USER_ENABLE),
  .USER_WIDTH(USER_WIDTH),
  .OUTPUT_DEST(OUTPUT_DEST),
  .OUTPUT_ID(OUTPUT_ID),
  .DATA_WIDTH_U_D(DATA_WIDTH_U_D),
  .DATA_WIDTH_L_R(DATA_WIDTH_L_R)  
) wrapper (
  .clk(clk),
  .rst(rst),
  .s_axis_up_tdata(s_axis_up_tdata),
  .s_axis_up_tvalid(s_axis_up_tvalid),
  .s_axis_up_tready(s_axis_up_tready),
  .s_axis_up_tlast(s_axis_up_tlast),
  .s_axis_up_tid(s_axis_up_tid),
  .s_axis_up_tdest(s_axis_up_tdest),
  .s_axis_up_tuser(s_axis_up_tuser),
  .s_axis_left_tdata(s_axis_left_tdata),
  .s_axis_left_tvalid(s_axis_left_tvalid),
  .s_axis_left_tready(s_axis_left_tready),
  .s_axis_left_tlast(s_axis_left_tlast),
  .s_axis_left_tid(s_axis_left_tid),
  .s_axis_left_tdest(s_axis_left_tdest),
  .s_axis_left_tuser(s_axis_left_tuser),
  .m_axis_down_tdata(m_axis_down_tdata),
  .m_axis_down_tvalid(m_axis_down_tvalid),
  .m_axis_down_tready(m_axis_down_tready),
  .m_axis_down_tlast(m_axis_down_tlast),
  .m_axis_down_tid(m_axis_down_tid),
  .m_axis_down_tdest(m_axis_down_tdest),
  .m_axis_down_tuser(m_axis_down_tuser),
  .err_unalligned_data(err_unalligned_data),
  .err_user_flag(err_user_flag)
);

endmodule

`resetall
