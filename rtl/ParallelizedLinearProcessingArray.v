`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * ParallelizedLinearProcessingArray : Accepts N+M and returns N AXI-Streams. Input
 *   The module works as a systolic array for the Matrix-Matrix Multiplication.
 * 
 * Array Positioning : (Weights from Top to Bottom)
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

module ParallelizedLinearProcessingArray #(
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
  parameter OUTPUT_ID = 0,
  // Pipeline Level to use for dsp
  parameter PIPELINE_LEVEL = 0
) (
  input  wire                                                 clk,
  input  wire                                                 rst,

  /*
   * AXI Stream Top Input -- Weight Input
   */
  input  wire [PE_NUMBER_I*PE_NUMBER_J*OP1_WIDTH-1:0]         s_axis_t_tdata,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tvalid,
  output wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tready,
  input  wire [PE_NUMBER_I*PE_NUMBER_J-1:0]                   s_axis_t_tlast,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*ID_WIDTH-1:0]          s_axis_t_tid,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*DEST_WIDTH-1:0]        s_axis_t_tdest,
  input  wire [PE_NUMBER_I*PE_NUMBER_J*USER_WIDTH-1:0]        s_axis_t_tuser,

  /*
   * AXI Stream Left Input -- Data Input
   */
  input  wire [PE_NUMBER_J*BATCH_SIZE*OP0_WIDTH-1:0]          s_axis_l_tdata,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                    s_axis_l_tvalid,
  output wire [PE_NUMBER_J*BATCH_SIZE-1:0]                    s_axis_l_tready,
  input  wire [PE_NUMBER_J*BATCH_SIZE-1:0]                    s_axis_l_tlast,
  input  wire [PE_NUMBER_J*BATCH_SIZE*ID_WIDTH-1:0]           s_axis_l_tid,
  input  wire [PE_NUMBER_J*BATCH_SIZE*DEST_WIDTH-1:0]         s_axis_l_tdest,
  input  wire [PE_NUMBER_J*BATCH_SIZE*USER_WIDTH-1:0]         s_axis_l_tuser,

  /*
   * AXI Stream Down Output -- Partial Sum Output
   */
  output wire [PE_NUMBER_I*BATCH_SIZE*RSLT_WIDTH-1:0]         m_axis_d_tdata,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                    m_axis_d_tvalid,
  input  wire [PE_NUMBER_I*BATCH_SIZE-1:0]                    m_axis_d_tready,
  output wire [PE_NUMBER_I*BATCH_SIZE-1:0]                    m_axis_d_tlast,
  output wire [PE_NUMBER_I*BATCH_SIZE*ID_WIDTH-1:0]           m_axis_d_tid,
  output wire [PE_NUMBER_I*BATCH_SIZE*DEST_WIDTH-1:0]         m_axis_d_tdest,
  output wire [PE_NUMBER_I*BATCH_SIZE*USER_WIDTH-1:0]         m_axis_d_tuser,

  /*
   * Error Outputs
   */
  output wire                                                 err_unalligned_data,

  /*
   * Interrupts
   */
  output wire                                                 core_rst
);
  // Global Local Parameters
  localparam MLT_OP_SIZE     = OP0_WIDTH + OP1_WIDTH + IS_UNSIGNED_OP0 + IS_UNSIGNED_OP1;
  localparam PSUM_WIDTH      = 48; // `MAX( RSLT_WIDTH, MLT_OP_SIZE);
  localparam MAC_RSLT_LSB    = OP0_FRACTIONAL_BITS + OP1_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS;

  localparam IS_UNSIGNED_RES = (IS_UNSIGNED_OP0 > 0) && (IS_UNSIGNED_OP1 > 0);

  // Internal AXI-Stream Signals
  // Output Partial Sums (Up->Down)
  wire [PSUM_WIDTH-1:0]                             int_axis_ud_tdata    [0:PE_NUMBER_I*(PE_NUMBER_J+1)*BATCH_SIZE-1];
  wire [0:PE_NUMBER_I*(PE_NUMBER_J+1)*BATCH_SIZE-1] int_axis_ud_tvalid;
  wire [0:PE_NUMBER_I*(PE_NUMBER_J+1)*BATCH_SIZE-1] int_axis_ud_tready;
  wire [0:PE_NUMBER_I*(PE_NUMBER_J+1)*BATCH_SIZE-1] int_axis_ud_tlast;

  // Input Data (Left->Right)
  wire [OP0_WIDTH-1:0]                              int_axis_lr_tdata    [0:(PE_NUMBER_I+1)*PE_NUMBER_J*BATCH_SIZE-1];
  wire [0:(PE_NUMBER_I+1)*PE_NUMBER_J*BATCH_SIZE-1] int_axis_lr_tvalid;
  wire [0:(PE_NUMBER_I+1)*PE_NUMBER_J*BATCH_SIZE-1] int_axis_lr_tready;
  wire [0:(PE_NUMBER_I+1)*PE_NUMBER_J*BATCH_SIZE-1] int_axis_lr_tlast;

  // Input Weights (Top->Bottom)
  wire [OP1_WIDTH-1:0]                              int_axis_tb_tdata    [0:PE_NUMBER_I*PE_NUMBER_J*(BATCH_SIZE+1)-1];
  wire [0:PE_NUMBER_I*PE_NUMBER_J*(BATCH_SIZE+1)-1] int_axis_tb_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J*(BATCH_SIZE+1)-1] int_axis_tb_tready;
  wire [0:PE_NUMBER_I*PE_NUMBER_J*(BATCH_SIZE+1)-1] int_axis_tb_tlast;

  // Internal Error Signals
  wire [0:PE_NUMBER_I*PE_NUMBER_J*BATCH_SIZE-1]     err_unalligned_data_int;

  // Debugging Signals
  wire [0:PE_NUMBER_I*(PE_NUMBER_J+1)*BATCH_SIZE-1] int_axis_ud_handshake = int_axis_ud_tready & int_axis_ud_tvalid;
  wire [0:(PE_NUMBER_I+1)*PE_NUMBER_J*BATCH_SIZE-1] int_axis_lr_handshake = int_axis_lr_tready & int_axis_lr_tvalid;
  wire [0:PE_NUMBER_I*PE_NUMBER_J*(BATCH_SIZE+1)-1] int_axis_tb_handshake = int_axis_tb_tready & int_axis_tb_tvalid;

  // Internal Reset
  reg  [3:0]  rst_pipeline;
  wire        rst_int;

  // Error Signal Reduction
  assign err_unalligned_data = |err_unalligned_data_int;

  // Reset Management
  always @(posedge clk ) begin
    rst_pipeline[1] <= rst_pipeline[0];
    rst_pipeline[2] <= rst_pipeline[1];
    rst_pipeline[3] <= |rst_pipeline[2:0];
  end

  assign rst_int  = rst_pipeline[3];
  assign core_rst = rst_int;

  // PE Coordinates
  genvar pe_pos_i, pe_pos_j, batch;

  generate
    always @* begin
      if (INTERNAL_RESET) begin : internal_reset_genblock
        rst_pipeline[0] <= rst | err_unalligned_data;
      end else begin : internal_reset_ignore_genblock
       rst_pipeline[0] <= rst;
      end
    end

    for (batch = 0; batch < BATCH_SIZE; batch = batch + 1) begin  : batch_plane_genblock
      for (pe_pos_j = 0; pe_pos_j < PE_NUMBER_J; pe_pos_j = pe_pos_j + 1) begin : col_genblock
        for (pe_pos_i = 0; pe_pos_i < PE_NUMBER_I; pe_pos_i = pe_pos_i + 1) begin : row_genblock
          localparam PE_POSITION_I = pe_pos_i;
          localparam PE_POSITION_J = pe_pos_j;
          localparam UID    = (  batch    *  PE_NUMBER_J    +  PE_POSITION_J    ) *  PE_NUMBER_I    +  PE_POSITION_I;
          localparam NODE_L = (  batch    *  PE_NUMBER_J    +  PE_POSITION_J    ) * (PE_NUMBER_I+1) +  PE_POSITION_I;
          localparam NODE_R = (  batch    *  PE_NUMBER_J    +  PE_POSITION_J    ) * (PE_NUMBER_I+1) + (PE_POSITION_I+1);
          localparam NODE_T = (  batch    *  PE_NUMBER_J    +  PE_POSITION_J    ) *  PE_NUMBER_I    +  PE_POSITION_I;
          localparam NODE_B = ( (batch+1) *  PE_NUMBER_J    +  PE_POSITION_J    ) *  PE_NUMBER_I    +  PE_POSITION_I;
          localparam NODE_U = (  batch    * (PE_NUMBER_J+1) +  PE_POSITION_J    ) *  PE_NUMBER_I    +  PE_POSITION_I;
          localparam NODE_D = (  batch    * (PE_NUMBER_J+1) + (PE_POSITION_J+1) ) *  PE_NUMBER_I    +  PE_POSITION_I;

          ParallelizedLinearProcessingElement #(
            .PE_NUMBER_I            (PE_NUMBER_I),
            .PE_NUMBER_J            (PE_NUMBER_J),
            .PE_POSITION_I          (PE_POSITION_I),
            .PE_POSITION_J          (PE_POSITION_J),
            .OP0_WIDTH              (OP0_WIDTH),
            .IS_UNSIGNED_OP0        (IS_UNSIGNED_OP0),
            .OP1_WIDTH              (OP1_WIDTH),
            .IS_UNSIGNED_OP1        (IS_UNSIGNED_OP1),
            .PSUM_WIDTH             (PSUM_WIDTH),
            .PIPELINE_LEVEL         (PIPELINE_LEVEL)
          ) parallelized_lpe_ijk (
            .clk                    (clk),
            .rst                    (rst_int),
            .s_axis_u_tdata         (int_axis_ud_tdata        [NODE_U]),
            .s_axis_u_tvalid        (int_axis_ud_tvalid       [NODE_U]),
            .s_axis_u_tready        (int_axis_ud_tready       [NODE_U]),
            .s_axis_u_tlast         (int_axis_ud_tlast        [NODE_U]),
            .m_axis_d_tdata         (int_axis_ud_tdata        [NODE_D]),
            .m_axis_d_tvalid        (int_axis_ud_tvalid       [NODE_D]),
            .m_axis_d_tready        (int_axis_ud_tready       [NODE_D]),
            .m_axis_d_tlast         (int_axis_ud_tlast        [NODE_D]),
            .s_axis_l_tdata         (int_axis_lr_tdata        [NODE_L]),
            .s_axis_l_tvalid        (int_axis_lr_tvalid       [NODE_L]),
            .s_axis_l_tready        (int_axis_lr_tready       [NODE_L]),
            .s_axis_l_tlast         (int_axis_lr_tlast        [NODE_L]),
            .m_axis_r_tdata         (int_axis_lr_tdata        [NODE_R]),
            .m_axis_r_tvalid        (int_axis_lr_tvalid       [NODE_R]),
            .m_axis_r_tready        (int_axis_lr_tready       [NODE_R]),
            .m_axis_r_tlast         (int_axis_lr_tlast        [NODE_R]),
            .s_axis_t_tdata         (int_axis_tb_tdata        [NODE_T]),
            .s_axis_t_tvalid        (int_axis_tb_tvalid       [NODE_T]),
            .s_axis_t_tready        (int_axis_tb_tready       [NODE_T]),
            .s_axis_t_tlast         (int_axis_tb_tlast        [NODE_T]),
            .m_axis_b_tdata         (int_axis_tb_tdata        [NODE_B]),
            .m_axis_b_tvalid        (int_axis_tb_tvalid       [NODE_B]),
            .m_axis_b_tready        (int_axis_tb_tready       [NODE_B]),
            .m_axis_b_tlast         (int_axis_tb_tlast        [NODE_B]),
            .err_unalligned_data    (err_unalligned_data_int  [UID])
          );

          if (PE_POSITION_I == 0) begin : left_pos_input_connections_genblock
            localparam LFT_POS = batch * PE_NUMBER_J + PE_POSITION_J;
            localparam LSB = LFT_POS*OP0_WIDTH;
            localparam MSB = LSB + OP0_WIDTH -1;

            // Connect Input to Left Border
            assign int_axis_lr_tdata   [NODE_L]    = s_axis_l_tdata  [MSB:LSB];
            assign int_axis_lr_tvalid  [NODE_L]    = s_axis_l_tvalid [LFT_POS];
            assign s_axis_l_tready     [LFT_POS] = int_axis_lr_tready [NODE_L];
            assign int_axis_lr_tlast   [NODE_L]    = s_axis_l_tlast  [LFT_POS];
          end 

          if (PE_POSITION_I == PE_NUMBER_I-1) begin : right_pos_output_connections_drop_genblock
            // Drop Output from Right Border
            assign int_axis_lr_tready[NODE_R] = 1'b1;
          end 

          if (batch == 0) begin : top_pos_input_connections_genblock
            localparam TOP_POS = PE_POSITION_J * PE_NUMBER_I + PE_POSITION_I;
            localparam LSB = TOP_POS*OP1_WIDTH;
            localparam MSB = LSB + OP1_WIDTH -1;

            // Connect Input to Top Border
            assign int_axis_tb_tdata  [NODE_T]    = s_axis_t_tdata  [MSB:LSB];
            assign int_axis_tb_tvalid [NODE_T]    = s_axis_t_tvalid [TOP_POS];
            assign s_axis_t_tready    [TOP_POS] = int_axis_tb_tready [NODE_T];
            assign int_axis_tb_tlast  [NODE_T]    = s_axis_t_tlast  [TOP_POS];
          end
          
          if (batch == BATCH_SIZE-1) begin : bottom_pos_output_connections_drop_genblock
            // Drop Output from Bottom Border
            assign int_axis_tb_tready[NODE_B] = 1'b1;
          end 
          
          if (PE_POSITION_J == 0) begin : up_pos_input_connections_disconnect_genblock
            // Close Input from Up Border -- Disconnect Up Border
            assign int_axis_ud_tdata  [NODE_U] = {PSUM_WIDTH{1'bZ}};
            assign int_axis_ud_tvalid [NODE_U] = 1'bZ;
            assign int_axis_ud_tlast  [NODE_U] = 1'bZ;
          end 
          
          if (PE_POSITION_J == PE_NUMBER_J-1) begin : down_pos_output_connections_genblock
            localparam DWN_POS = batch * PE_NUMBER_I + PE_POSITION_I;
            localparam LSB = DWN_POS*RSLT_WIDTH;
            localparam MSB = LSB + RSLT_WIDTH -1;

            if (IS_UNSIGNED_RES) begin
              assign m_axis_d_tdata   [MSB:LSB]  = $unsigned(int_axis_ud_tdata [NODE_D][PSUM_WIDTH-1:MAC_RSLT_LSB]);
            end else begin
              assign m_axis_d_tdata   [MSB:LSB]  =   $signed(int_axis_ud_tdata [NODE_D][PSUM_WIDTH-1:MAC_RSLT_LSB]);
            end
            assign m_axis_d_tvalid    [DWN_POS]  = int_axis_ud_tvalid [NODE_D];
            assign int_axis_ud_tready [NODE_D]   = m_axis_d_tready   [DWN_POS];
            assign m_axis_d_tlast     [DWN_POS]  = int_axis_ud_tlast  [NODE_D];

            assign m_axis_d_tdest     [DWN_POS*DEST_WIDTH] = (DEST_ENABLE) ? OUTPUT_DEST : {DEST_WIDTH{1'b0}};
            assign m_axis_d_tid       [DWN_POS*ID_WIDTH]   =   (ID_ENABLE) ? OUTPUT_ID   :   {ID_WIDTH{1'b0}};
            assign m_axis_d_tuser     [DWN_POS*USER_WIDTH] = (USER_ENABLE) ? OUTPUT_USER : {USER_WIDTH{1'b0}};
          end 
        end 
      end
    end
  endgenerate

endmodule

`resetall
