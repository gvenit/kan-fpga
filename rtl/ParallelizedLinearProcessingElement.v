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

module ParallelizedLinearProcessingElement #(
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
  // Treat operand 0 as unsigned
  parameter IS_UNSIGNED_OP0 = 0,
  // Data Width of Input Weights (T-AXIS)
  parameter OP1_WIDTH = 16,
  // Treat operand 1 as unsigned
  parameter IS_UNSIGNED_OP1 = 0,
  // Data Width of Output Data (D-AXIS)
  parameter PSUM_WIDTH = OP0_WIDTH + OP1_WIDTH,
  // Pipeline Level to use for dsp
  parameter PIPELINE_LEVEL = 0
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
  output wire                         err_unalligned_data
);
  // DataFlow Local Parameters
  localparam MLT_OP_SIZE  = OP0_WIDTH + OP1_WIDTH + IS_UNSIGNED_OP0 + IS_UNSIGNED_OP1;

  // Left AXI-Stream internal signals
  wire [OP0_WIDTH-1:0]  int_axis_l_tdata;
  wire                  int_axis_l_tvalid;
  wire                  int_axis_l_tready;
  wire                  int_axis_l_tlast;

  // Right AXI-Stream internal signals
  wire [OP0_WIDTH-1:0]  int_axis_r_tdata;
  wire                  int_axis_r_tvalid;
  wire                  int_axis_r_tready;
  wire                  int_axis_r_tlast;

  // Top AXI-Stream internal signals
  wire [OP1_WIDTH-1:0]  int_axis_t_tdata;
  wire                  int_axis_t_tvalid;
  wire                  int_axis_t_tready;
  wire                  int_axis_t_tlast;

  // Bottom AXI-Stream internal signals
  wire [OP1_WIDTH-1:0]  int_axis_b_tdata;
  wire                  int_axis_b_tvalid;
  wire                  int_axis_b_tready;
  wire                  int_axis_b_tlast;

  // Up AXI-Stream internal signals
  wire [PSUM_WIDTH-1:0] int_axis_u_tdata;
  wire                  int_axis_u_tvalid;
  wire                  int_axis_u_tready;
  wire                  int_axis_u_tlast;

  // Down AXI-Stream internal signals
  wire [PSUM_WIDTH-1:0] int_axis_d_tdata;
  wire                  int_axis_d_tvalid;
  wire                  int_axis_d_tready;
  wire                  int_axis_d_tlast;

  // Control Unit Output Signals
  wire store_l, store_t, store_u;
  wire forward_l, forward_t, forward_u;
  wire drop_l, drop_t, drop_u;

  wire op_start;
  wire bypass_adder;
  wire acc_res;
  wire export_rslt;
  wire export_rslt_last;
  
  // Pipelined Output Signals
  wire export_rslt_sync, export_rslt_last_sync;

  // DataFlow Registers & Wires
  wire [PSUM_WIDTH-1:0]                   partial_sum_reg;
  wire [OP0_WIDTH + IS_UNSIGNED_OP0 -1:0] mult_op0 = { {IS_UNSIGNED_OP0{1'b0}}, int_axis_l_tdata};
  wire [OP1_WIDTH + IS_UNSIGNED_OP1 -1:0] mult_op1 = { {IS_UNSIGNED_OP1{1'b0}}, int_axis_t_tdata};

  DSPELogic #(
    .OP0_SIZE             (OP0_WIDTH + IS_UNSIGNED_OP0),
    .OP1_SIZE             (OP1_WIDTH + IS_UNSIGNED_OP1),
    .ACC_SIZE             (PSUM_WIDTH),
    .PIPELINE_LEVEL       (PIPELINE_LEVEL),
    .EXTRA_SIGNAL_SIZE    (2)
  ) data_processing_inst  (
    .clk                  (clk),
    .rst                  (rst),
    .bypass_mlt           (acc_res),
    .bypass_add           (bypass_adder),
    .reset_acc            (op_start),
    .op0                  (mult_op0),
    .op1                  (mult_op1),
    .op2                  (int_axis_u_tdata),
    .acc                  (partial_sum_reg),
    .extra_sig_in         ({export_rslt, export_rslt_last}),
    .extra_sig_out        ({export_rslt_sync, export_rslt_last_sync})
  );

  // Control Logic
  ParallelizedLPEControlUnit #(
    // Number of PEs in Processing Array j axis
    .PE_NUMBER_J(PE_NUMBER_J),
    // Position of current PE in the j axis
    .PE_POSITION_J(PE_POSITION_J)
  ) control_unit (
    .clk                    (clk),
    .rst                    (rst),
    .int_axis_u_tvalid      (int_axis_u_tvalid),
    .int_axis_u_tlast       (int_axis_u_tlast),
    .int_axis_l_tvalid      (int_axis_l_tvalid),
    .int_axis_l_tlast       (int_axis_l_tlast),
    .int_axis_t_tvalid      (int_axis_t_tvalid),
    .int_axis_t_tlast       (int_axis_t_tlast),
    .int_axis_d_tready      (int_axis_d_tready),
    .int_axis_r_tready      (int_axis_r_tready),
    .int_axis_b_tready      (int_axis_b_tready),
    .store_l                (store_l),
    .store_t                (store_t),
    .store_u                (store_u),
    .forward_l              (forward_l),
    .forward_t              (forward_t),
    .forward_u              (forward_u),
    .drop_l                 (drop_l), 
    .drop_t                 (drop_t),
    .drop_u                 (drop_u),
    .export_rslt            (export_rslt),
    .export_rslt_last       (export_rslt_last),
    .op_start               (op_start),
    .bypass_adder           (bypass_adder),
    .acc_res                (acc_res),
    .err_unalligned_data    (err_unalligned_data)
  );

  generate
    if (PE_POSITION_J == 0) begin : up_register_drop_genblock
      // Processing Element never accepts data from Up AxiS
      assign s_axis_u_tready   = 1'b0;
      assign int_axis_u_tdata  = {PSUM_WIDTH{1'bZ}};
      assign int_axis_u_tvalid = 1'b0;
      assign int_axis_u_tlast  = 1'bZ;
    end else begin : up_register_genblock
      // Up AXI-Stream Skid Buffer
      wire s_axis_u_tready_int;
      assign s_axis_u_tready = s_axis_u_tready_int & store_u;
      axis_register #(
        // Width of AXI stream interfaces in bits
        .DATA_WIDTH(PSUM_WIDTH),
        // Propagate tkeep signal
        .KEEP_ENABLE(0),
        // tkeep signal width (words per cycle)
        .KEEP_WIDTH(1),
        // Propagate tlast signal
        .LAST_ENABLE(1),
        // Propagate tid signal
        .ID_ENABLE(0),
        // tid signal width
        .ID_WIDTH(1),
        // Propagate tdest signal
        .DEST_ENABLE(0),
        // tdest signal width
        .DEST_WIDTH(1),
        // Propagate tuser signal
        .USER_ENABLE(0),
        // tuser signal width
        .USER_WIDTH(1),
        // Register type
        // 0 to bypass, 1 for simple buffer, 2 for skid buffer
        .REG_TYPE(2)
      ) axis_register_u_inst (
        .clk              (clk),
        .rst              (rst),
        .s_axis_tdata     (s_axis_u_tdata),
        .s_axis_tkeep     (1'b1),
        .s_axis_tvalid    (s_axis_u_tvalid & store_u),
        .s_axis_tready    (s_axis_u_tready_int),
        .s_axis_tlast     (s_axis_u_tlast),
        .s_axis_tid       (1'b0),
        .s_axis_tdest     (1'b0),
        .s_axis_tuser     (1'b0),
        .m_axis_tdata     (int_axis_u_tdata),
        .m_axis_tvalid    (int_axis_u_tvalid),
        .m_axis_tready    (int_axis_u_tready),
        .m_axis_tlast     (int_axis_u_tlast)
      );
    end
  endgenerate

  // Down AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(PSUM_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(0)
  ) axis_register_d_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (int_axis_d_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (int_axis_d_tvalid),
    .s_axis_tready    (int_axis_d_tready),
    .s_axis_tlast     (int_axis_d_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (m_axis_d_tdata),
    .m_axis_tvalid    (m_axis_d_tvalid),
    .m_axis_tready    (m_axis_d_tready),
    .m_axis_tlast     (m_axis_d_tlast)
  );

  // Left AXI-Stream Skid Buffer
  wire s_axis_l_tready_int;
  assign s_axis_l_tready = s_axis_l_tready_int & store_l;
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(OP0_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_l_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (s_axis_l_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (s_axis_l_tvalid & store_l),
    .s_axis_tready    (s_axis_l_tready_int),
    .s_axis_tlast     (s_axis_l_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (int_axis_l_tdata),
    .m_axis_tvalid    (int_axis_l_tvalid),
    .m_axis_tready    (int_axis_l_tready),
    .m_axis_tlast     (int_axis_l_tlast)
  );

  // Right AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(OP0_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(0)
  ) axis_register_r_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (int_axis_r_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (int_axis_r_tvalid),
    .s_axis_tready    (int_axis_r_tready),
    .s_axis_tlast     (int_axis_r_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (m_axis_r_tdata),
    .m_axis_tvalid    (m_axis_r_tvalid),
    .m_axis_tready    (m_axis_r_tready),
    .m_axis_tlast     (m_axis_r_tlast)
  );

  // Top AXI-Stream Skid Buffer
  wire s_axis_t_tready_int;
  assign s_axis_t_tready = s_axis_t_tready_int & store_t;
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(OP1_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_t_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (s_axis_t_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (s_axis_t_tvalid & store_t),
    .s_axis_tready    (s_axis_t_tready_int),
    .s_axis_tlast     (s_axis_t_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (int_axis_t_tdata),
    .m_axis_tvalid    (int_axis_t_tvalid),
    .m_axis_tready    (int_axis_t_tready),
    .m_axis_tlast     (int_axis_t_tlast)
  );

  // Bottom AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(OP1_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(0)
  ) axis_register_b_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (int_axis_b_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (int_axis_b_tvalid),
    .s_axis_tready    (int_axis_b_tready),
    .s_axis_tlast     (int_axis_b_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (m_axis_b_tdata),
    .m_axis_tvalid    (m_axis_b_tvalid),
    .m_axis_tready    (m_axis_b_tready),
    .m_axis_tlast     (m_axis_b_tlast)
  );

  // Output Down AXI-Stream Drivers
  generate
    if (PE_POSITION_J > 0) begin : up_down_connections_genblock
      assign int_axis_d_tdata   = (export_rslt_sync) ? partial_sum_reg       : int_axis_u_tdata;
      assign int_axis_d_tvalid  = (export_rslt_sync) ? 1'b1                  : int_axis_u_tvalid & forward_u & !drop_u;
      assign int_axis_u_tready  = (export_rslt_sync) ? 1'b0                  : int_axis_d_tready & forward_u |  drop_u;
      assign int_axis_d_tlast   = (export_rslt_sync) ? export_rslt_last_sync : export_rslt_last;
    end else begin : down_interface_genblock
      assign int_axis_d_tdata   = partial_sum_reg;
      assign int_axis_d_tvalid  = export_rslt_sync;
      assign int_axis_u_tready  = 1'bZ;             // Not used
      assign int_axis_d_tlast   = export_rslt_last_sync;
    end
  endgenerate

  // Output Right AXI-Stream Drivers
  assign int_axis_r_tdata   = int_axis_l_tdata;
  assign int_axis_r_tvalid  = int_axis_l_tvalid & forward_l & !drop_l;
  assign int_axis_l_tready  = int_axis_r_tready & forward_l |  drop_l;
  assign int_axis_r_tlast   = int_axis_l_tlast;

  // Output Bottom AXI-Stream Drivers
  assign int_axis_b_tdata   = int_axis_t_tdata;
  assign int_axis_b_tvalid  = int_axis_t_tvalid & forward_t & !drop_t;
  assign int_axis_t_tready  = int_axis_b_tready & forward_t |  drop_t;
  assign int_axis_b_tlast   = int_axis_t_tlast;

endmodule

`resetall
