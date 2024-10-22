`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * LinearProcessingElement : Accepts and returns two AXI-Streams
 *   from neighbouring `LinearProcessingElement` modules. Input
 *   streams are up (i,j-1) and left (i-1,j) and output streams
 *   are down (i,j+1) and right (i+1,j). The modlue works as a
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
    // Number of PEs in Processing Array 
    parameter PE_NUMBER = 8,
    // Position of current PE in the i axis
    parameter PE_POSITION_I = 0,
    // Position of current PE in the j axis
    parameter PE_POSITION_J = 0,
    // Data Width of Input Data (L-AXIS)
    parameter DATA_WIDTH_OP0 = 16,
    // Fractional Bits of Input Data (L-AXIS)
    parameter FRACTIONAL_BITS_OP0 = 12,
    // Data Width of Input Weights (U-AXIS)
    parameter DATA_WIDTH_OP1 = 16,
    // Fractional Bits of Input Weights (U-AXIS)
    parameter FRACTIONAL_BITS_OP1 = 12,
    // Data Width of Output Data (D-AXIS)
    parameter DATA_WIDTH_RSLT = 16,
    // Fractional Bits of Output Data (D-AXIS)
    parameter FRACTIONAL_BITS_RSLT = 12,
    // Propagate tid signal
    parameter ID_ENABLE = 0,
    // tid signal width
    parameter ID_WIDTH = 8,
    // Propagate tdest signal
    parameter DEST_ENABLE = 1,
    // tdest signal width
    parameter DEST_WIDTH = 8,
    // Propagate tuser signal
    parameter USER_ENABLE = 1,
    // tuser signal width
    parameter USER_WIDTH = 8,
    // Output Destination 
    parameter OUTPUT_DEST = 1;
    // Output Destination 
    parameter OUTPUT_ID = 1;
    // Resolve Up/Down Bit Width
    parameter DATA_WIDTH_U_D = (DATA_WIDTH_OP1 > DATA_WIDTH_RSLT) ? DATA_WIDTH_OP1 : DATA_WIDTH_RSLT,
    // Resolve Left/Right Bit Width
    parameter DATA_WIDTH_L_R = DATA_WIDTH_DATA,
    // Operator 1 Mask
    parameter OP1_USER_MASK = USER_WIDTH'h40,
    // Result Mask
    parameter RSLT_USER_MASK = USER_WIDTH'h80
) (
  input                             clk,
  input                             rst,

  /*
   * AXI Stream Up input
   */
  input  [DATA_WIDTH_U_D-1:0]    s_axis_up_tdata,
  input                          s_axis_up_tvalid,
  output                         s_axis_up_tready,
  input                          s_axis_up_tlast,
  input  [ID_WIDTH-1:0]          s_axis_up_tid,
  input  [DEST_WIDTH-1:0]        s_axis_up_tdest,
  input  [USER_WIDTH-1:0]        s_axis_up_tuser,

  /*
   * AXI Stream Left input
   */
  input  [DATA_WIDTH_L_R-1:0]    s_axis_left_tdata,
  input                          s_axis_left_tvalid,
  output                         s_axis_left_tready,
  input                          s_axis_left_tlast,
  input  [ID_WIDTH-1:0]          s_axis_left_tid,
  input  [DEST_WIDTH-1:0]        s_axis_left_tdest,
  input  [USER_WIDTH-1:0]        s_axis_left_tuser,

  /*
   * AXI Stream Down Output
   */
  output [DATA_WIDTH_U_D-1:0]    m_axis_down_tdata,
  output                         m_axis_down_tvalid,
  input                          m_axis_down_tready,
  output                         m_axis_down_tlast,
  output [ID_WIDTH-1:0]          m_axis_down_tid,
  output [DEST_WIDTH-1:0]        m_axis_down_tdest,
  output [USER_WIDTH-1:0]        m_axis_down_tuser,

  /*
   * AXI Stream Right Output
   */
  output [DATA_WIDTH_L_R-1:0]    m_axis_right_tdata,
  output                         m_axis_right_tvalid,
  input                          m_axis_right_tready,
  output                         m_axis_right_tlast,
  output [ID_WIDTH-1:0]          m_axis_right_tid,
  output [DEST_WIDTH-1:0]        m_axis_right_tdest,
  output [USER_WIDTH-1:0]        m_axis_right_tuser,

  /*
   * Error Outputs
   */
  output err_unalligned_data;
);
  // Up AXI-Stream internal signals
  wire [DATA_WIDTH_U_D-1:0] int_axis_up_tdata;
  wire                      int_axis_up_tvalid;
  wire                      int_axis_up_tready;
  wire                      int_axis_up_tlast;
  wire [ID_WIDTH-1:0]       int_axis_up_tid;
  wire [DEST_WIDTH-1:0]     int_axis_up_tdest;
  wire [USER_WIDTH-1:0]     int_axis_up_tuser;

  // Left AXI-Stream internal signals
  wire [DATA_WIDTH_L_R-1:0] int_axis_left_tdata;
  wire                      int_axis_left_tvalid;
  wire                      int_axis_left_tready;
  wire                      int_axis_left_tlast;
  wire [ID_WIDTH-1:0]       int_axis_left_tid;
  wire [DEST_WIDTH-1:0]     int_axis_left_tdest;
  wire [USER_WIDTH-1:0]     int_axis_left_tuser;

  // Down AXI-Stream internal signals
  wire [DATA_WIDTH_U_D-1:0] int_axis_down_tdata;
  wire                      int_axis_down_tvalid;
  wire                      int_axis_down_tready;
  wire                      int_axis_down_tlast;
  wire [ID_WIDTH-1:0]       int_axis_down_tid;
  wire [DEST_WIDTH-1:0]     int_axis_down_tdest;
  wire [USER_WIDTH-1:0]     int_axis_down_tuser;

  // Right AXI-Stream internal signals
  wire [DATA_WIDTH_L_R-1:0] int_axis_right_tdata;
  wire                      int_axis_right_tvalid;
  wire                      int_axis_right_tready;
  wire                      int_axis_right_tlast;
  wire [ID_WIDTH-1:0]       int_axis_right_tid;
  wire [DEST_WIDTH-1:0]     int_axis_right_tdest;
  wire [USER_WIDTH-1:0]     int_axis_right_tuser;

  // FSM input signals
  wire in_handshake_up   = s_axis_up_tvalid && s_axis_up_tready;
  wire in_handshake_left = s_axis_left_tvalid && s_axis_left_tready;
  wire op_retry = !(int_axis_left_tvalid && int_axis_up_tvalid && (int_axis_up_tuser & OP1_USER_MASK));

  wire err_user_flag_int = int_axis_up_tvalid && ^(int_axis_up_tuser & (OP1_USER_MASK | RSLT_USER_MASK));
  wire err_unalligned_data_int = !(op_retry || !(int_axis_left_tlast ^ int_axis_up_tlast)) ;

  // FSM Output Signals
  reg store_l, store_u;
  reg forward_l, forward_u;
  reg push_d;

  reg op_start;
  reg bypass_adder;

  // FSM States
  localparam FSM_STATE_WIDTH = 3;
  localparam FSM_STRT = FSM_STATE_WIDTH'd0;
  localparam FSM_STRL = FSM_STATE_WIDTH'd1;
  localparam FSM_STRU = FSM_STATE_WIDTH'd2;
  localparam FSM_MAC  = FSM_STATE_WIDTH'd3;
  localparam FSM_ERR  = FSM_STATE_WIDTH'd4;
  localparam FSM_END  = FSM_STATE_WIDTH'd5;

  // FSM Registers & Wires
  reg  [FSM_STATE_WIDTH-1:0] fsm_state = FSM_START;
  wire [FSM_STATE_WIDTH-1:0] fsm_state_next;

  // DataFlow Local Parameters
  localparam MAC_OP_SIZE  = (DATA_WIDTH_RSLT > DATA_WIDTH_OP0 + DATA_WIDTH_SCALE) ? DATA_WIDTH_RSLT : DATA_WIDTH_OP0 + DATA_WIDTH_SCALE;
  localparam MLT_OP_SIZE  = DATA_WIDTH_OP0 + DATA_WIDTH_SCALE;
  localparam MAC_RSLT_LSB = FRACTIONAL_BITS_DATA + FRACTIONAL_BITS_SCALE - FRACTIONAL_BITS_RSLT;
  localparam MAC_RSLT_MSB = RSLT_LSB + DATA_WIDTH_RSLT - 1;

  // DataFlow Registers & Wires
  reg [MAC_OP_SIZE-1:0] partial_sum_reg = 0, partial_sum_reg_next, partial_sum_fb, partial_sum_rslt;
  reg [MLT_OP_SIZE-1:0] mult_res;

  wire [DATA_WIDTH_OP0-1:] mult_op0;
  wire [DATA_WIDTH_OP1-1:] mult_op1;

  // FSM Logic
  always @(posedge clk) begin
    if (rst) begin
      fsm_state <= FSM_START;
      
      // Freeze all data flows
      store_l      <= 1'b0;
      store_u      <= 1'b0;

      forward_l    <= 1'b0;
      forward_u    <= 1'b0;
      
      push_d       <= 1'0;

      op_start     <= 1'b0;
      bypass_adder <= 1'b1;

      // Reset Errors
      err_unalligned_data <= 1'b0;
      err_user_flag <= 1'b0

    end else begin
      fsm_state <= fsm_state_next;
      
      case (fsm_state)
        FSM_STRT :
          // Store & Forward Left and Up
          store_l      <= 1'b1;
          store_u      <= 1'b1;

          forward_l    <= 1'b1;
          forward_u    <= 1'b1;

          // No Results to push yet
          push_d       <= 1'0;

          // Reset Partial Sum
          op_start     <= 1'b1;
          bypass_adder <= 1'b1;

          // No Errors
          err_unalligned_data <= 1'b0;
          err_user_flag <= 1'b0

        FSM_STRL :
          // Store Up
          store_l      <= 1'b0;
          store_u      <= 1'b1;

          forward_l    <= 1'b0;
          forward_u    <= 1'b0;

         // No Results to push yet
          push_d       <= 1'0;

          // Lock Partial Sum
          op_start     <= 1'b0;
          bypass_adder <= 1'b1;

          // No Errors
          err_unalligned_data <= 1'b0;
          err_user_flag <= 1'b0

        FSM_STRU :
          // Store Left
          store_l      <= 1'b1;
          store_u      <= 1'b0;

          forward_l    <= 1'b0;
          forward_u    <= 1'b0;

         // No Results to push yet
          push_d       <= 1'0;

          // Lock Partial Sum
          op_start     <= 1'b0;
          bypass_adder <= 1'b1;

          // No Errors
          err_unalligned_data <= 1'b0;
          err_user_flag <= 1'b0

        FSM_MAC :
          // Store & Forward Left and Up
          store_l      <= 1'b1;
          store_u      <= 1'b1;

          forward_l    <= 1'b1;
          forward_u    <= 1'b1;

         // No Results to push yet
          push_d       <= 1'0;

          // Update Partial Sum
          op_start     <= 1'b0;
          bypass_adder <= 1'b0;

          // No Errors
          err_unalligned_data <= 1'b0;
          err_user_flag <= 1'b0

        FSM_END :
          // Return & Forward Up
          store_l      <= 1'b0;
          store_u      <= 1'b0;

          forward_l    <= 1'b0;
          forward_u    <= 1'b1;

          // Push down
          push_d       <= 1'1;

          // Lock Partial Sum
          op_start     <= 1'b0;
          bypass_adder <= 1'b1;

          // No Errors
          err_unalligned_data <= 1'b0;
          err_user_flag <= 1'b0;

        FSM_ERR :
          // Return & Forward Up
          store_l      <= 1'b0;
          store_u      <= 1'b0;

          forward_l    <= 1'b0;
          forward_u    <= 1'b0;

         // Invalid Results
          push_d       <= 1'0;

          // Lock Partial Sum
          op_start     <= 1'b0;
          bypass_adder <= 1'b1;

          // Sample Errors
          err_unalligned_data <= err_unalligned_data_int;
          err_user_flag <= err_user_flag_int;

        default: 
          ;
      endcase
    end
  end

  // FSM Next State Logic
  always @(*) begin
    case (fsm_state)
      FSM_START :
        if (in_handshake_left && in_handshake_up) begin
          fsm_state_next <= FSM_MAC;
        end else if(in_handshake_left) begin
          fsm_state_next <= FSM_STRL;
        end else if(in_handshake_up) begin
          fsm_state_next <= FSM_STRU;
        end

      FSM_STRL :
        if (in_handshake_up) begin
          fsm_state_next <= FSM_MAC;
        end

      FSM_STRU :
        if (in_handshake_left) begin
          fsm_state_next <= FSM_MAC;
        end

      FSM_MAC :
        if (in_handshake_left && in_handshake_up) begin
          if (in_last_left && in_last_up) begin
            fsm_state_next <= FSM_END;
          end else if(in_last_left|in_last_up) begin
            fsm_state_next <= FSM_ERR;
          end else begin
            fsm_state_next <= FSM_MAC;
          end
        end else if(in_handshake_left) begin
          fsm_state_next <= FSM_STRL;
        end else if(in_handshake_up) begin
          fsm_state_next <= FSM_STRU;
        end

      FSM_ERR :
        fsm_state_next <= FSM_STRT;

      default: 
        fsm_state_next <= FSM_START;

    endcase
    if (err_user_flag) begin
      fsm_state_next <= FSM_ERR;
    end
  end

  // Up AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_U_D),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(ID_ENABLE),
    // tid signal width
    .ID_WIDTH(ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(USER_ENABLE),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_up_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_up_tdata),
    .s_axis_tkeep(s_axis_up_tkeep),
    .s_axis_tvalid(s_axis_up_tvalid),
    .s_axis_tready(s_axis_up_tready),
    .s_axis_tlast(s_axis_up_tlast),
    .s_axis_tid(s_axis_up_tid),
    .s_axis_tdest(s_axis_up_tdest),
    .s_axis_tuser(s_axis_up_tuser),
    .m_axis_tdata(int_axis_up_tdata),
    .m_axis_tkeep(int_axis_up_tkeep),
    .m_axis_tvalid(int_axis_up_tvalid),
    .m_axis_tready(int_axis_up_tready),
    .m_axis_tlast(int_axis_up_tlast),
    .m_axis_tid(int_axis_up_tid),
    .m_axis_tdest(int_axis_up_tdest),
    .m_axis_tuser(int_axis_up_tuser)
  );

  // Left AXI-Stream Skid Buffer
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_L_R),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Propagate tid signal
    .ID_ENABLE(ID_ENABLE),
    // tid signal width
    .ID_WIDTH(ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(USER_ENABLE),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_up_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_left_tdata),
    .s_axis_tkeep(s_axis_left_tkeep),
    .s_axis_tvalid(s_axis_left_tvalid),
    .s_axis_tready(s_axis_left_tready),
    .s_axis_tlast(s_axis_left_tlast),
    .s_axis_tid(s_axis_left_tid),
    .s_axis_tdest(s_axis_left_tdest),
    .s_axis_tuser(s_axis_left_tuser),
    .m_axis_tdata(int_axis_left_tdata),
    .m_axis_tkeep(int_axis_left_tkeep),
    .m_axis_tvalid(int_axis_left_tvalid),
    .m_axis_tready(int_axis_left_tready),
    .m_axis_tlast(int_axis_left_tlast),
    .m_axis_tid(int_axis_left_tid),
    .m_axis_tdest(int_axis_left_tdest),
    .m_axis_tuser(int_axis_left_tuser)
  );

  // DataFlow
  assign mult_op0 = int_axis_left_tdata;
  assign mult_op1 = int_axis_up_tdata[DATA_WIDTH_OP1-1:0];

  assign mult_res = mult_op0 * mult_op1;
  assign partial_sum_rslt = partial_sum_fb + mult_res;

  assign partial_sum_fb = (op_start) ? MAC_OP_SIZE'0 : partial_sum_reg;
  assign partial_sum_reg_next = (bypass_adder) ? partial_sum_fb : partial_sum_rslt;

endmodule