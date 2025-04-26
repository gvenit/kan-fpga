`resetall
`timescale 1ns/1ps
`default_nettype none

`include "header_utils.vh"

/* 
 * LinearProcessingElement : Accepts and returns two AXI-Streams
 *   from neighbouring `LinearProcessingElement` modules. Input
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

module LinearProcessingElement #(
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
    // Data Width of Input Weights (U-AXIS)
    parameter OP1_WIDTH = 16,
    // Treat operand 1 as unsigned
    parameter IS_UNSIGNED_OP1 = 0,
    // Fractional Bits of Input Weights (U-AXIS)
    parameter OP1_FRACTIONAL_BITS = 12,
    // Data Width of Output Data (D-AXIS)
    parameter RSLT_WIDTH = 16,
    // Fractional Bits of Output Data (D-AXIS)
    parameter RSLT_FRACTIONAL_BITS = 12,
    // tuser signal width
    parameter USER_WIDTH = 8 , // 2 + `LOG2(PE_NUMBER_J),
    // Output Destination 
    parameter OUTPUT_DEST = 1,
    // Output Destination 
    parameter OUTPUT_ID = 1,
    // Resolve Up/Down Bit Width
    parameter U_D_WIDTH = (OP1_WIDTH > RSLT_WIDTH) ? OP1_WIDTH : RSLT_WIDTH,
    // Resolve Left/Right Bit Width
    parameter L_R_WIDTH = OP0_WIDTH,
    // Operator 1 User Mask
    parameter OP1_USER_MASK = 1 << USER_WIDTH-2,
    // Result User Mask
    parameter RSLT_USER_MASK = 1 << USER_WIDTH-1
) (
  input  wire                            clk,
  input  wire                            rst,

  /*
   * AXI Stream Up input
   */
  input  wire [U_D_WIDTH-1:0]    s_axis_up_tdata,
  input  wire                         s_axis_up_tvalid,
  output wire                         s_axis_up_tready,
  input  wire                         s_axis_up_tlast,
  input  wire [USER_WIDTH-1:0]        s_axis_up_tuser,

  /*
   * AXI Stream Left input
   */
  input  wire [L_R_WIDTH-1:0]    s_axis_left_tdata,
  input  wire                         s_axis_left_tvalid,
  output wire                         s_axis_left_tready,
  input  wire                         s_axis_left_tlast,

  /*
   * AXI Stream Down Output
   */
  output wire [U_D_WIDTH-1:0]    m_axis_down_tdata,
  output wire                         m_axis_down_tvalid,
  input  wire                         m_axis_down_tready,
  output wire                         m_axis_down_tlast,
  output wire [USER_WIDTH-1:0]        m_axis_down_tuser,

  /*
   * AXI Stream Right Output
   */
  output wire [L_R_WIDTH-1:0]    m_axis_right_tdata,
  output wire                         m_axis_right_tvalid,
  input  wire                         m_axis_right_tready,
  output wire                         m_axis_right_tlast,

  /*
   * Error Outputs
   */
  output wire err_unalligned_data,
  output wire err_user_flag
);
  // DataFlow Local Parameters
  localparam MLT_OP_SIZE  = OP0_WIDTH + OP1_WIDTH + IS_UNSIGNED_OP0 + IS_UNSIGNED_OP1;
  localparam MAC_OP_SIZE  = (RSLT_WIDTH > MLT_OP_SIZE) ? RSLT_WIDTH : MLT_OP_SIZE;
  localparam MAC_RSLT_LSB = OP0_FRACTIONAL_BITS + OP1_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS;
  localparam MAC_RSLT_MSB = MAC_RSLT_LSB + RSLT_WIDTH - 1;

  // Up AXI-Stream internal signals
  wire [U_D_WIDTH-1:0] int_axis_up_tdata;
  wire                      int_axis_up_tvalid;
  wire                      int_axis_up_tready;
  wire                      int_axis_up_tlast;
  wire [USER_WIDTH-1:0]     int_axis_up_tuser;

  // Left AXI-Stream internal signals
  wire [L_R_WIDTH-1:0] int_axis_left_tdata;
  wire                      int_axis_left_tvalid;
  wire                      int_axis_left_tready;
  wire                      int_axis_left_tlast;

  // Down AXI-Stream internal signals
  wire [U_D_WIDTH-1:0] int_axis_down_tdata;
  wire                      int_axis_down_tvalid;
  wire                      int_axis_down_tready;
  wire                      int_axis_down_tlast;
  wire [USER_WIDTH-1:0]     int_axis_down_tuser;

  // Right AXI-Stream internal signals
  wire [L_R_WIDTH-1:0] int_axis_right_tdata;
  wire                      int_axis_right_tvalid;
  wire                      int_axis_right_tready;
  wire                      int_axis_right_tlast;

  // Control Unit Output Signals
  wire store_l, store_u;
  wire forward_l, forward_u;
  wire drop_l, drop_u;
  wire push_d;

  wire op_start;
  wire bypass_adder;
  wire export_rslt;

  // DataFlow Registers & Wires
  reg  [MAC_OP_SIZE-1:0]     partial_sum_reg = 0;

  wire [OP0_WIDTH-1:0]  mult_op0 = { {IS_UNSIGNED_OP0{1'b0}}, int_axis_left_tdata};
  wire [OP1_WIDTH-1:0]  mult_op1 = { {IS_UNSIGNED_OP1{1'b0}}, int_axis_up_tdata[OP1_WIDTH-1:0]};
  wire [MLT_OP_SIZE-1:0]     mult_res = mult_op0 * mult_op1;
  wire [MAC_OP_SIZE-1:0]     partial_sum_fb = (op_start) ? 0 : partial_sum_reg;
  wire [MAC_OP_SIZE-1:0]     partial_sum_rslt = partial_sum_fb + mult_res;
  wire [MAC_OP_SIZE-1:0]     partial_sum_reg_next = (bypass_adder) ? partial_sum_fb : partial_sum_rslt;

  wire [RSLT_WIDTH-1:0] rslt = partial_sum_reg[MAC_RSLT_MSB:MAC_RSLT_LSB];

  // Control Logic
  LPEControlUnit #(
    // Number of PEs in Processing Array j axis
    .PE_NUMBER_J(PE_NUMBER_J),
    // Position of current PE in the j axis
    .PE_POSITION_J(PE_POSITION_J),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH) , // 2 + `LOG2(PE_NUMBER_J),
    // Output Destination 
    .OUTPUT_DEST(OUTPUT_DEST),
    // Output Destination 
    .OUTPUT_ID(OUTPUT_ID),
    // Operator 1 User Mask
    .OP1_USER_MASK(OP1_USER_MASK),
    // Result User Mask
    .RSLT_USER_MASK(RSLT_USER_MASK)
  ) control_unit (
    .clk(clk),
    .rst(rst),
    .int_axis_up_tvalid(int_axis_up_tvalid),
    .int_axis_up_tready(int_axis_up_tready),
    .int_axis_up_tlast(int_axis_up_tlast),
    .int_axis_up_tuser(int_axis_up_tuser),
    .int_axis_left_tvalid(int_axis_left_tvalid),
    .int_axis_left_tready(int_axis_left_tready),
    .int_axis_left_tlast(int_axis_left_tlast),
    .int_axis_down_tvalid(int_axis_down_tvalid),
    .int_axis_down_tready(int_axis_down_tready),
    .int_axis_right_tvalid(int_axis_right_tvalid),
    .int_axis_right_tready(int_axis_right_tready),
    .store_l(store_l),
    .store_u(store_u),
    .forward_l(forward_l),
    .forward_u(forward_u),
    .drop_l(drop_l), 
    .drop_u(drop_u),
    .export_rslt(export_rslt),
    .op_start(op_start),
    .bypass_adder(bypass_adder),
    .err_unalligned_data(err_unalligned_data),
    .err_user_flag(err_user_flag)
  );

  // Up AXI-Stream Skid Buffer
  wire s_axis_up_tready_int;
  assign s_axis_up_tready = s_axis_up_tready_int & store_u;
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(U_D_WIDTH),
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
    .USER_ENABLE(1),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_up_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_up_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(s_axis_up_tvalid & store_u),
    .s_axis_tready(s_axis_up_tready_int),
    .s_axis_tlast(s_axis_up_tlast),
    .s_axis_tid(1'b0),
    .s_axis_tdest(1'b0),
    .s_axis_tuser(s_axis_up_tuser),
    .m_axis_tdata(int_axis_up_tdata),
    .m_axis_tvalid(int_axis_up_tvalid),
    .m_axis_tready(int_axis_up_tready),
    .m_axis_tlast(int_axis_up_tlast),
    .m_axis_tuser(int_axis_up_tuser)
  );

  // Left AXI-Stream Skid Buffer
  wire s_axis_left_tready_int;
  assign s_axis_left_tready = s_axis_left_tready_int & store_l;
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(L_R_WIDTH),
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
  ) axis_register_left_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_left_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(s_axis_left_tvalid & store_l),
    .s_axis_tready(s_axis_left_tready_int),
    .s_axis_tlast(s_axis_left_tlast),
    .s_axis_tid(1'b0),
    .s_axis_tdest(1'b0),
    .s_axis_tuser(1'b0),
    .m_axis_tdata(int_axis_left_tdata),
    .m_axis_tvalid(int_axis_left_tvalid),
    .m_axis_tready(int_axis_left_tready),
    .m_axis_tlast(int_axis_left_tlast)
  );

  // Down AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(U_D_WIDTH),
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
    .USER_ENABLE(1),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(0)
  ) axis_register_down_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(int_axis_down_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(int_axis_down_tvalid),
    .s_axis_tready(int_axis_down_tready),
    .s_axis_tlast(int_axis_down_tlast),
    .s_axis_tid(1'b0),
    .s_axis_tdest(1'b0),
    .s_axis_tuser(int_axis_down_tuser),
    .m_axis_tdata(m_axis_down_tdata),
    .m_axis_tvalid(m_axis_down_tvalid),
    .m_axis_tready(m_axis_down_tready),
    .m_axis_tlast(m_axis_down_tlast),
    .m_axis_tuser(m_axis_down_tuser)
  );

  // Right AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(L_R_WIDTH),
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
  ) axis_register_right_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(int_axis_right_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(int_axis_right_tvalid),
    .s_axis_tready(int_axis_right_tready),
    .s_axis_tlast(int_axis_right_tlast),
    .s_axis_tid(1'b0),
    .s_axis_tdest(1'b0),
    .s_axis_tuser(1'b0),
    .m_axis_tdata(m_axis_right_tdata),
    .m_axis_tvalid(m_axis_right_tvalid),
    .m_axis_tready(m_axis_right_tready),
    .m_axis_tlast(m_axis_right_tlast)
  );

  always @(posedge clk ) begin
    partial_sum_reg <= partial_sum_reg_next;
  end

  // Output Right AXI-Stream Drivers
  assign int_axis_right_tdata   = int_axis_left_tdata;
  assign int_axis_right_tvalid  = int_axis_left_tvalid  & forward_l & !drop_l;
  assign int_axis_left_tready   = int_axis_right_tready & forward_l |  drop_l;
  assign int_axis_right_tlast   = int_axis_left_tlast;

  // Output Down AXI-Stream Drivers
  assign int_axis_down_tdata   = (export_rslt) ? {{(U_D_WIDTH-RSLT_WIDTH){1'b0}}, rslt} : int_axis_up_tdata;
  assign int_axis_down_tvalid  = (export_rslt) ? 1'b1                           : int_axis_up_tvalid   & forward_u & !drop_u;
  assign int_axis_up_tready    = (export_rslt) ? 1'b0                           : int_axis_down_tready & forward_u |  drop_u;
  assign int_axis_down_tlast   = (export_rslt) ? PE_NUMBER_J == PE_POSITION_J+1 : int_axis_up_tlast;
  assign int_axis_down_tuser   = (export_rslt) ? PE_POSITION_J | RSLT_USER_MASK : int_axis_up_tuser;

endmodule

`resetall
