`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * LinearProcessingArray : Accepts N+M and returns N AXI-Streams. Input
 *   The module works as a systolic array for the Matrix-Matrix Multiplication.
 * 
 * Array Positioning :
 *                         i
 *                  --------------->
 *              |  {0,0}  ...  {I-1,0}
 *  X ---->    j|   ...          ...
 *              v {0,J-1} ... {I-1,J-1} 
 *                         |
 *                         |
 *                         v
 *                    Partial Sums
 */

module LinearProcessingArray #(
    // Number of PEs in Processing Array i axis -- Number of results per batch per run
    parameter PE_NUMBER_I = 1,
    // Number of PEs in Processing Array j axis -- Number of partial sums per result
    parameter PE_NUMBER_J = 1,
    // Number of PEs in Processing Array k axis -- Number of batches per run
    parameter BATCH_SIZE = 1,
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
    // Fractional Bits of Input Weights (U-AXIS)
    parameter FRACTIONAL_BITS_OP1 = 12,
    // Treat operand 1 as unsigned
    parameter IS_UNSIGNED_OP1 = 0,
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
    parameter DEST_WIDTH = (DEST_ENABLE) ? 8 :1,
    // Propagate tuser signal
    parameter USER_ENABLE = 1,
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
   * AXI Stream Top Input -- Weight Input
   */
  input  wire [PE_NUMBER_I*PE_NUMBER_J*DATA_WIDTH_OP1-1:0]    s_axis_top_tdata,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_top_tvalid,
  output wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_top_tready,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_top_tlast,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*ID_WIDTH-1:0]          s_axis_top_tid,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*DEST_WIDTH-1:0]        s_axis_top_tdest,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*USER_WIDTH-1:0]        s_axis_top_tuser,

  // /*
  //  * AXI Stream Bottom Output -- Weights are dropped
  //  */
  // output wire [PE_NUMBER_I*PE_NUMBER_J*DATA_WIDTH_RSLT-1:0]   m_axis_down_tdata,
  // output wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   m_axis_down_tvalid,
  // input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   m_axis_down_tready,
  // output wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   m_axis_down_tlast,
  // output wire [PE_NUMBER_I*PE_NUMBER_J*ID_WIDTH-1:0]          m_axis_down_tid,
  // output wire [PE_NUMBER_I*PE_NUMBER_J*DEST_WIDTH-1:0]        m_axis_down_tdest,
  // output wire [PE_NUMBER_I*PE_NUMBER_J*USER_WIDTH-1:0]        m_axis_down_tuser,

  /*
   * AXI Stream Left Input -- Data Input
   */
  input  wire [PE_NUMBER_J*BATCH_SIZE*DATA_WIDTH_OP0-1:0]    s_axis_left_tdata,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_left_tvalid,
  output wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_left_tready,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                   s_axis_left_tlast,
  input  wire [PE_NUMBER_J*BATCH_SIZE*ID_WIDTH-1:0]          s_axis_left_tid,
  input  wire [PE_NUMBER_J*BATCH_SIZE*DEST_WIDTH-1:0]        s_axis_left_tdest,
  input  wire [PE_NUMBER_J*BATCH_SIZE*USER_WIDTH-1:0]        s_axis_left_tuser,

  /*
   * AXI Stream Down Output -- Partial Sum Output
   */
  output wire [PE_NUMBER_I*BATCH_SIZE*DATA_WIDTH_RSLT-1:0]   m_axis_down_tdata,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_down_tvalid,
  input  wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_down_tready,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                   m_axis_down_tlast,
  output wire [PE_NUMBER_I*BATCH_SIZE*ID_WIDTH-1:0]          m_axis_down_tid,
  output wire [PE_NUMBER_I*BATCH_SIZE*DEST_WIDTH-1:0]        m_axis_down_tdest,
  output wire [PE_NUMBER_I*BATCH_SIZE*USER_WIDTH-1:0]        m_axis_down_tuser,

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
  localparam MLT_OP_SIZE     = DATA_WIDTH_OP0 + DATA_WIDTH_OP1 + IS_UNSIGNED_OP0 + IS_UNSIGNED_OP1;
  localparam DATA_WIDTH_PSUM = (DATA_WIDTH_RSLT > MLT_OP_SIZE) ? DATA_WIDTH_RSLT : MLT_OP_SIZE;
  localparam MAC_RSLT_LSB    = FRACTIONAL_BITS_OP0 + FRACTIONAL_BITS_OP1 - FRACTIONAL_BITS_RSLT;
  localparam MAC_RSLT_MSB    = MAC_RSLT_LSB + DATA_WIDTH_RSLT - 1;

  // Internal AXI-Stream Signals
  // Output Partial Sums (Up->Down)
  wire [DATA_WIDTH_PSUM-1:0]                                int_axis_ud_tdata    [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1];
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_ud_tvalid;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_ud_tready;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_ud_tlast;

  // Input Data (Left->Right)
  wire [DATA_WIDTH_OP0-1:0]                                 int_axis_lr_tdata    [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1];
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_lr_tvalid;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_lr_tready;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_lr_tlast;

  // Input Weights (Top->Bottom)
  wire [DATA_WIDTH_OP1-1:0]                                 int_axis_tb_tdata    [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1];
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_tb_tvalid;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_tb_tready;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_tb_tlast;


  // Internal Error Signals
  wire [0:PE_NUMBER_I*PE_NUMBER_J*BATCH_SIZE-1] err_unalligned_data_int, err_user_flag_int;

  // Debugging Signals
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_lr_handshake = int_axis_lr_tready & int_axis_lr_tvalid;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_ud_handshake = int_axis_ud_tready & int_axis_ud_tvalid;
  wire [0:(PE_NUMBER_I+1)*(PE_NUMBER_J+1)*(BATCH_SIZE+1)-1] int_axis_tb_handshake = int_axis_tb_tready & int_axis_tb_tvalid;

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
  genvar pe_pos_i, pe_pos_j, batch;

  generate
    always @* begin
      if (INTERNAL_RESET)
        rst_pipeline[0] <= rst | err_unalligned_data | err_user_flag;
      else 
       rst_pipeline[0] <= rst;
    end

    for (batch = 0; batch < BATCH_SIZE; batch = batch + 1) begin
      for (pe_pos_j = 0; pe_pos_j < PE_NUMBER_J; pe_pos_j = pe_pos_j + 1) begin
        for (pe_pos_i = 0; pe_pos_i < PE_NUMBER_I; pe_pos_i = pe_pos_i + 1) begin
          localparam PE_POSITION_I = pe_pos_i;
          localparam PE_POSITION_J = pe_pos_j;
          localparam UID    = (  batch    *  PE_NUMBER_J    +  PE_POSITION_J    ) *  PE_NUMBER_I    +  PE_POSITION_I;
          localparam NODE   = (  batch    * (PE_NUMBER_J+1) +  PE_POSITION_J    ) * (PE_NUMBER_I+1) +  PE_POSITION_I;
          localparam NODE_U = (  batch    * (PE_NUMBER_J+1) + (PE_POSITION_J-1) ) * (PE_NUMBER_I+1) +  PE_POSITION_I;
          localparam NODE_L = (  batch    * (PE_NUMBER_J+1) +  PE_POSITION_J    ) * (PE_NUMBER_I+1) + (PE_POSITION_I-1);
          localparam NODE_D = (  batch    * (PE_NUMBER_J+1) + (PE_POSITION_J+1) ) * (PE_NUMBER_I+1) +  PE_POSITION_I;
          localparam NODE_R = (  batch    * (PE_NUMBER_J+1) +  PE_POSITION_J    ) * (PE_NUMBER_I+1) + (PE_POSITION_I+1);
          localparam NODE_T = ( (batch-1) * (PE_NUMBER_J+1) +  PE_POSITION_J    ) * (PE_NUMBER_I+1) +  PE_POSITION_I;
          localparam NODE_B = ( (batch+1) * (PE_NUMBER_J+1) +  PE_POSITION_J    ) * (PE_NUMBER_I+1) +  PE_POSITION_I;

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
            .DATA_WIDTH_OP0(DATA_WIDTH_OP0),
            // Fractional Bits of Input Data (L-AXIS)
            .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
            // Treat operand 0 as unsigned
            .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
            // Data Width of Input Weights (U-AXIS)
            .DATA_WIDTH_OP1(DATA_WIDTH_OP1),
            // Treat operand 1 as unsigned
            .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
            // Fractional Bits of Input Weights (U-AXIS)
            .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
            // Data Width of Output Data (D-AXIS)
            .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
            // Fractional Bits of Output Data (D-AXIS)
            .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
            // tuser signal width
            .USER_WIDTH(USER_WIDTH_INT)
          ) LPE_ij (
            .clk(clk),
            .rst(rst_int),
            .s_axis_u_tdata(int_axis_ud_tdata[NODE]),
            .s_axis_u_tvalid(int_axis_ud_tvalid[NODE]),
            .s_axis_u_tready(int_axis_ud_tready[NODE]),
            .s_axis_u_tlast(int_axis_ud_tlast[NODE]),
            .m_axis_d_tdata(int_axis_ud_tdata[NODE_D]),
            .m_axis_d_tvalid(int_axis_ud_tvalid[NODE_D]),
            .m_axis_d_tready(int_axis_ud_tready[NODE_D]),
            .m_axis_d_tlast(int_axis_ud_tlast[NODE_D]),
            .s_axis_l_tdata(int_axis_lr_tdata[NODE]),
            .s_axis_l_tvalid(int_axis_lr_tvalid[NODE]),
            .s_axis_l_tready(int_axis_lr_tready[NODE]),
            .s_axis_l_tlast(int_axis_lr_tlast[NODE]),
            .m_axis_r_tdata(int_axis_lr_tdata[NODE_R]),
            .m_axis_r_tvalid(int_axis_lr_tvalid[NODE_R]),
            .m_axis_r_tready(int_axis_lr_tready[NODE_R]),
            .m_axis_r_tlast(int_axis_lr_tlast[NODE_R]),
            .s_axis_t_tdata(int_axis_tb_tdata[NODE]),
            .s_axis_t_tvalid(int_axis_tb_tvalid[NODE]),
            .s_axis_t_tready(int_axis_tb_tready[NODE]),
            .s_axis_t_tlast(int_axis_tb_tlast[NODE]),
            .m_axis_b_tdata(int_axis_tb_tdata[NODE_B]),
            .m_axis_b_tvalid(int_axis_tb_tvalid[NODE_B]),
            .m_axis_b_tready(int_axis_tb_tready[NODE_B]),
            .m_axis_b_tlast(int_axis_tb_tlast[NODE_B]),
            .err_unalligned_data(err_unalligned_data_int[UID]),
            .err_user_flag(err_user_flag_int[UID])
          );

          if (PE_POSITION_I == 0) begin
            localparam LSB = (batch * PE_NUMBER_J + PE_POSITION_J)*DATA_WIDTH_OP0;
            localparam MSB = LSB + DATA_WIDTH_OP0 -1;

            // Connect Input to Left Border
            assign int_axis_lr_tdata   [NODE]          = s_axis_left_tdata  [MSB:LSB];
            assign int_axis_lr_tvalid  [NODE]          = s_axis_left_tvalid [PE_POSITION_J];
            assign s_axis_left_tready  [PE_POSITION_J] = int_axis_lr_tready [NODE];
            assign int_axis_lr_tlast   [NODE]          = s_axis_left_tlast  [PE_POSITION_J];
            // assign int_axis_lr_tid    [NODE]          = s_axis_left_tid      [(PE_POSITION_J+1)*ID_WIDTH-1:PE_POSITION_J*ID_WIDTH];
            // assign int_axis_lr_tdest  [NODE]          = s_axis_left_tdest    [(PE_POSITION_J+1)*DEST_WIDTH-1:PE_POSITION_J*DEST_WIDTH];
          end 

          if (PE_POSITION_I == PE_NUMBER_I-1) begin
            // Drop Output from Right Border
            assign int_axis_lr_tready[NODE_R] = 1'b1;
          end 

          if (batch == 0) begin
            localparam TOP_POS = PE_POSITION_J * PE_NUMBER_I + PE_POSITION_I;
            localparam LSB = TOP_POS*DATA_WIDTH_OP1;
            localparam MSB = LSB + DATA_WIDTH_OP1 -1;

            // Connect Input to Top Border
            assign int_axis_tb_tdata  [NODE]    = s_axis_top_tdata   [MSB:LSB];
            assign int_axis_tb_tvalid [NODE]    = s_axis_top_tvalid  [TOP_POS];
            assign s_axis_top_tready  [TOP_POS] = int_axis_tb_tready [NODE];
            assign int_axis_tb_tlast  [NODE]    = s_axis_top_tlast   [TOP_POS];
          end
          
          if (batch == BATCH_SIZE-1) begin
            // Drop Output from Bottom Border
            assign int_axis_tb_tready[NODE_B] = 1'b1;
          end 
          
          if (PE_POSITION_J == 0) begin
            // Close Input from Up Border
            assign int_axis_ud_tvalid[NODE] = 1'b0;
          end 
          
          if (PE_POSITION_J == PE_NUMBER_J-1) begin
            localparam DOWN_POS = batch * PE_NUMBER_I + PE_POSITION_I;
            localparam LSB = DOWN_POS*DATA_WIDTH_PSUM + MAC_RSLT_LSB;
            localparam MSB = LSB + DATA_WIDTH_RSLT -1;

            assign m_axis_down_tdata  [MSB:LSB]  = int_axis_tb_tdata  [NODE_D][MAC_RSLT_MSB:MAC_RSLT_LSB];
            assign m_axis_down_tvalid [DOWN_POS] = int_axis_tb_tvalid [NODE_D];
            assign int_axis_tb_tready [NODE_D]   = m_axis_down_tready [DOWN_POS];
            assign m_axis_down_tlast  [DOWN_POS] = int_axis_tb_tlast  [NODE_D];
          end 
        end 
      end
    end
  endgenerate

endmodule

`resetall
