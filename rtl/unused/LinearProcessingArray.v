`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

/* 
 * LinearProcessingArray : Accepts N+M and returns N AXI-Streams. Input
 *   The module works as a systolic array for the Matrix-Matrix Multiplication.
 * 
 * Array Positioning :
 *              i
 *       --------------->
 *   |  {0,0}  ...  {I-1,0}
 *  j|   ...          ...
 *   v {0,J-1} ... {I-1,J-1} 
 */

module LinearProcessingArray #(
    // Number of PEs in Processing Array i axis
    parameter PE_NUMBER_I = 1,
    // Number of PEs in Processing Array j axis
    parameter PE_NUMBER_J = 1,
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
    // Output Destination 
    parameter OUTPUT_DEST = 0,
    // Output Thread ID 
    parameter OUTPUT_ID = 1
) (
  input  wire                            clk,
  input  wire                            rst,

  /*
   * AXI Stream Up input
   */
  input  wire [PE_NUMBER_I*OP1_WIDTH-1:0]    s_axis_up_tdata,
  input  wire [PE_NUMBER_I-1:0]                   s_axis_up_tvalid,
  output wire [PE_NUMBER_I-1:0]                   s_axis_up_tready,
  input  wire [PE_NUMBER_I-1:0]                   s_axis_up_tlast,
  input  wire [PE_NUMBER_I*ID_WIDTH-1:0]          s_axis_up_tid,
  input  wire [PE_NUMBER_I*DEST_WIDTH-1:0]        s_axis_up_tdest,
  input  wire [PE_NUMBER_I*USER_WIDTH-1:0]        s_axis_up_tuser,

  /*
   * AXI Stream Left input
   */
  input  wire [PE_NUMBER_J*OP0_WIDTH-1:0]    s_axis_left_tdata,
  input  wire [PE_NUMBER_J-1:0]                   s_axis_left_tvalid,
  output wire [PE_NUMBER_J-1:0]                   s_axis_left_tready,
  input  wire [PE_NUMBER_J-1:0]                   s_axis_left_tlast,
  input  wire [PE_NUMBER_J*ID_WIDTH-1:0]          s_axis_left_tid,
  input  wire [PE_NUMBER_J*DEST_WIDTH-1:0]        s_axis_left_tdest,
  input  wire [PE_NUMBER_J*USER_WIDTH-1:0]        s_axis_left_tuser,

  /*
   * AXI Stream Down Output
   */
  output wire [PE_NUMBER_I*RSLT_WIDTH-1:0]   m_axis_down_tdata,
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
  output wire err_user_flag,

  /*
   * Interrupts
   */
  output wire core_rst
);
  // Global Local Parameters
  localparam PE_WIDTH_J       = `LOG2(PE_NUMBER_J);
  localparam USER_WIDTH_INT   = 2 + PE_WIDTH_J + (USER_ENABLE ? USER_WIDTH : 0);
  // Operator 1 User Mask
  localparam OP1_USER_MASK_R  = 2'b01;
  // Result User Mask
  localparam RSLT_USER_MASK_R = 2'b10;
  // Operator 1 User Mask
  localparam OP1_USER_MASK    = {OP1_USER_MASK_R, {USER_WIDTH_INT-2{1'b0}}};
  // Result User Mask
  localparam RSLT_USER_MASK   = {RSLT_USER_MASK_R, {USER_WIDTH_INT-2{1'b0}}};
  // Resolve Up/Down Bit Width
  localparam U_D_WIDTH   = (OP1_WIDTH > RSLT_WIDTH) ? OP1_WIDTH : RSLT_WIDTH;

  // Internal AXI-Stream Signals
  wire [U_D_WIDTH-1:0]          int_axis_up_tdata      [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [USER_WIDTH_INT-1:0]          int_axis_up_tuser      [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_up_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_up_tready;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_up_tlast;

  wire [OP0_WIDTH-1:0]          int_axis_left_tdata    [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_left_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_left_tready;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_left_tlast;

  wire [U_D_WIDTH-1:0]          int_axis_down_tdata    [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [USER_WIDTH_INT-1:0]          int_axis_down_tuser    [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_down_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_down_tready;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_down_tlast;

  wire [OP0_WIDTH-1:0]          int_axis_right_tdata   [0:PE_NUMBER_I*PE_NUMBER_J-1];
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_right_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_right_tready;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_right_tlast;

  // Internal Error Signals
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] err_unalligned_data_int, err_user_flag_int;

  // Debugging Signals
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_left_handshake  = int_axis_left_tready  & int_axis_left_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_up_handshake    = int_axis_up_tready    & int_axis_up_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_right_handshake = int_axis_right_tready & int_axis_right_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J-1] int_axis_down_handshake  = int_axis_down_tready  & int_axis_down_tvalid;

  // Internal Reset
  reg  [3:0] rst_pipeline;
  wire rst_int;

  // Error Signal Reduction
  assign err_unalligned_data = |err_unalligned_data_int;
  assign err_user_flag = |err_user_flag_int;

  // Reset Management
  always @(posedge clk ) begin
    rst_pipeline[1] <= rst_pipeline[0];
    rst_pipeline[2] <= rst_pipeline[1];
    rst_pipeline[3] <= |rst_pipeline[2:0];
  end

  assign rst_int = rst_pipeline[3];
  assign core_rst = rst_int;

  // PE Coordinates
  genvar pe_pos_i, pe_pos_j;

  generate
    always @* begin
      if (INTERNAL_RESET)
        rst_pipeline[0] <= rst | err_unalligned_data | err_user_flag;
      else 
       rst_pipeline[0] <= rst;
    end

    for (pe_pos_j = 0; pe_pos_j < PE_NUMBER_J; pe_pos_j = pe_pos_j + 1) begin
      for (pe_pos_i = 0; pe_pos_i < PE_NUMBER_I; pe_pos_i = pe_pos_i + 1) begin
        localparam PE_POSITION_I = pe_pos_i;
        localparam PE_POSITION_J = pe_pos_j;
        localparam NODE   =  PE_POSITION_J    * PE_NUMBER_I +  PE_POSITION_I;
        localparam NODE_U = (PE_POSITION_J-1) * PE_NUMBER_I +  PE_POSITION_I;
        localparam NODE_L =  PE_POSITION_J    * PE_NUMBER_I + (PE_POSITION_I-1);
        localparam NODE_D = (PE_POSITION_J+1) * PE_NUMBER_I +  PE_POSITION_I;
        localparam NODE_R =  PE_POSITION_J    * PE_NUMBER_I + (PE_POSITION_I+1);

        LinearProcessingElement #(
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
          // Data Width of Input Weights (U-AXIS)
          .OP1_WIDTH(OP1_WIDTH),
          // Treat operand 1 as unsigned
          .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
          // Fractional Bits of Input Weights (U-AXIS)
          .OP1_FRACTIONAL_BITS(OP1_FRACTIONAL_BITS),
          // Data Width of Output Data (D-AXIS)
          .RSLT_WIDTH(RSLT_WIDTH),
          // Fractional Bits of Output Data (D-AXIS)
          .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
          // tuser signal width
          .USER_WIDTH(USER_WIDTH_INT)
        ) LPE_ij (
          .clk(clk),
          .rst(rst_int),
          .s_axis_up_tdata(int_axis_up_tdata[NODE]),
          .s_axis_up_tvalid(int_axis_up_tvalid[NODE]),
          .s_axis_up_tready(int_axis_up_tready[NODE]),
          .s_axis_up_tlast(int_axis_up_tlast[NODE]),
          .s_axis_up_tuser(int_axis_up_tuser[NODE]),
          .s_axis_left_tdata(int_axis_left_tdata[NODE]),
          .s_axis_left_tvalid(int_axis_left_tvalid[NODE]),
          .s_axis_left_tready(int_axis_left_tready[NODE]),
          .s_axis_left_tlast(int_axis_left_tlast[NODE]),
          .m_axis_down_tdata(int_axis_down_tdata[NODE]),
          .m_axis_down_tvalid(int_axis_down_tvalid[NODE]),
          .m_axis_down_tready(int_axis_down_tready[NODE]),
          .m_axis_down_tlast(int_axis_down_tlast[NODE]),
          .m_axis_down_tuser(int_axis_down_tuser[NODE]),
          .m_axis_right_tdata(int_axis_right_tdata[NODE]),
          .m_axis_right_tvalid(int_axis_right_tvalid[NODE]),
          .m_axis_right_tready(int_axis_right_tready[NODE]),
          .m_axis_right_tlast(int_axis_right_tlast[NODE]),
          .err_unalligned_data(err_unalligned_data_int[NODE]),
          .err_user_flag(err_user_flag_int[NODE])
        );

        if (PE_POSITION_I == 0) begin
          localparam LSB = PE_POSITION_J*OP0_WIDTH;
          localparam MSB = LSB + OP0_WIDTH -1;

          // Connect Input to Left Border
          assign int_axis_left_tdata  [NODE]          = s_axis_left_tdata    [MSB:LSB];
          assign int_axis_left_tvalid [NODE]          = s_axis_left_tvalid   [PE_POSITION_J];
          assign s_axis_left_tready   [PE_POSITION_J] = int_axis_left_tready [NODE];
          assign int_axis_left_tlast  [NODE]          = s_axis_left_tlast    [PE_POSITION_J];
          // assign int_axis_left_tid    [NODE]          = s_axis_left_tid      [(PE_POSITION_J+1)*ID_WIDTH-1:PE_POSITION_J*ID_WIDTH];
          // assign int_axis_left_tdest  [NODE]          = s_axis_left_tdest    [(PE_POSITION_J+1)*DEST_WIDTH-1:PE_POSITION_J*DEST_WIDTH];
        end else begin
          assign int_axis_left_tdata   [NODE]   = int_axis_right_tdata  [NODE_L];
          assign int_axis_left_tvalid  [NODE]   = int_axis_right_tvalid [NODE_L];
          assign int_axis_right_tready [NODE_L] = int_axis_left_tready  [NODE];
          assign int_axis_left_tlast   [NODE]   = int_axis_right_tlast  [NODE_L];
        end 

        if (PE_POSITION_I == PE_NUMBER_I-1) begin
          // Drop Output from Right Border
          assign int_axis_right_tready[NODE] = 1'b1;
        end 

        if (PE_POSITION_J == 0) begin
          localparam LSB = PE_POSITION_I*OP1_WIDTH;
          localparam MSB = LSB + OP1_WIDTH -1;

          // Connect Input to Up Border
          assign int_axis_up_tdata  [NODE]          = {{U_D_WIDTH-OP1_WIDTH{1'b0}}, s_axis_up_tdata [MSB:LSB]};
          assign int_axis_up_tvalid [NODE]          = s_axis_up_tvalid   [PE_POSITION_I];
          assign s_axis_up_tready   [PE_POSITION_I] = int_axis_up_tready [NODE];
          assign int_axis_up_tlast  [NODE]          = s_axis_up_tlast    [PE_POSITION_I];
          // assign int_axis_up_tid    [NODE]          = s_axis_up_tid      [(PE_POSITION_I+1)*ID_WIDTH-1:PE_POSITION_I*ID_WIDTH];
          // assign int_axis_up_tdest  [NODE]          = s_axis_up_tdest    [(PE_POSITION_I+1)*DEST_WIDTH-1:PE_POSITION_I*DEST_WIDTH];
          assign int_axis_up_tuser  [NODE]          = (USER_ENABLE) ? 
            {OP1_USER_MASK_R, {PE_WIDTH_J{1'b0}}, s_axis_up_tuser [(PE_POSITION_I+1)*USER_WIDTH-1:PE_POSITION_I*USER_WIDTH]} :
            OP1_USER_MASK;
        end else begin
          assign int_axis_up_tdata   [NODE]   = int_axis_down_tdata  [NODE_U];
          assign int_axis_up_tvalid  [NODE]   = int_axis_down_tvalid [NODE_U];
          assign int_axis_down_tready[NODE_U] = int_axis_up_tready   [NODE];
          assign int_axis_up_tlast   [NODE]   = int_axis_down_tlast  [NODE_U];
          assign int_axis_up_tuser   [NODE]   = int_axis_down_tuser  [NODE_U];
        end
        
          if (PE_POSITION_J == PE_NUMBER_J-1) begin
            localparam LSB = PE_POSITION_I*U_D_WIDTH;
            localparam MSB = LSB + RSLT_WIDTH -1;

            // Drop Output from Down Border if OP!_USER_MASK
            // wire [USER_WIDTH_INT-1:0] temp = int_axis_down_tuser[NODE];
            wire   op1_flag_match = |(int_axis_down_tuser[NODE] & OP1_USER_MASK);

            assign m_axis_down_tdata    [MSB:LSB]                                                 = int_axis_down_tdata  [NODE][RSLT_WIDTH-1];
            assign m_axis_down_tvalid   [PE_POSITION_I]                                           = int_axis_down_tvalid [NODE] & !op1_flag_match;
            assign int_axis_down_tready [NODE]                                                    = (int_axis_down_tvalid[NODE] &  op1_flag_match) ? 1'b1 : m_axis_down_tready [PE_POSITION_I];
            assign m_axis_down_tlast    [PE_POSITION_I]                                           = int_axis_down_tlast  [NODE];
            assign m_axis_down_tid      [(PE_POSITION_I+1)*ID_WIDTH-1:PE_POSITION_I*ID_WIDTH]     = (ID_ENABLE)   ? OUTPUT_ID : {ID_WIDTH{1'b0}};
            assign m_axis_down_tdest    [(PE_POSITION_I+1)*DEST_WIDTH-1:PE_POSITION_I*DEST_WIDTH] = (DEST_ENABLE) ? OUTPUT_DEST : {DEST_WIDTH{1'b0}};
            assign m_axis_down_tuser    [(PE_POSITION_I+1)*USER_WIDTH-1:PE_POSITION_I*USER_WIDTH] = (USER_ENABLE) ? int_axis_down_tuser  [NODE][USER_WIDTH-1:0] : {USER_WIDTH{1'b0}};
          end 
        end 
    end
  endgenerate

endmodule

`resetall
