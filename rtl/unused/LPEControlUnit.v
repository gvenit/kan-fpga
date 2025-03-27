`resetall
`timescale 1ns/1ps
`default_nettype none

`include "utils.vh"

/* 
 * LPEControlUnit : Control Unit for LinearProcessingElement
 * 
 */

module LPEControlUnit #(
    // Number of PEs in Processing Array j axis
    parameter PE_NUMBER_J = 4,
    // Position of current PE in the j axis
    parameter PE_POSITION_J = 0,
    // tuser signal width
    parameter USER_WIDTH = 8 , // 2 + `LOG2(PE_NUMBER_J),
    // Output Destination 
    parameter OUTPUT_DEST = 1,
    // Output Destination 
    parameter OUTPUT_ID = 1,
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
  input  wire                         int_axis_up_tvalid,
  input  wire                         int_axis_up_tready,
  input  wire                         int_axis_up_tlast,
  input  wire [USER_WIDTH-1:0]        int_axis_up_tuser,

  /*
   * AXI Stream Left input
   */
  input  wire                         int_axis_left_tvalid,
  input  wire                         int_axis_left_tready,
  input  wire                         int_axis_left_tlast,

  /*
   * AXI Stream Down Output
   */
  input  wire                         int_axis_down_tvalid,
  input  wire                         int_axis_down_tready,

  /*
   * AXI Stream Right Output
   */
  input  wire                         int_axis_right_tvalid,
  input  wire                         int_axis_right_tready,

  output wire                         store_l,
  output wire                         store_u,
  output wire                         forward_l,
  output wire                         forward_u,
  output wire                         drop_l,
  output wire                         drop_u,
  // output wire                         push_d,
  output wire                         export_rslt,

  output wire                         op_start,
  output wire                         bypass_adder,

  /*
   * Error Outputs
   */
  output wire err_unalligned_data,
  output wire err_user_flag
);
  // Output Control Local Parameters
  localparam PE_J_WIDTH = `LOG2(PE_NUMBER_J);

  // FSM States
  localparam FSM_STATE_WIDTH = 3;
  localparam FSM_STRT = 3'd0;
  localparam FSM_STRL = 3'd1;
  localparam FSM_STRU = 3'd2;
  localparam FSM_MAC  = 3'd3;
  localparam FSM_ERR  = 3'd4;
  localparam FSM_END  = 3'd5;

  // FSM Registers & Wires
  reg  [FSM_STATE_WIDTH-1:0] fsm_state, fsm_state_next;

  // DataFlow Registers & Wires
  reg  partial_sum_last_reg = 1'b0;
  
  // FSM input signals
  wire op0_flag  = int_axis_left_tvalid;
  wire op1_flag  = int_axis_up_tvalid && (int_axis_up_tuser & OP1_USER_MASK);
  wire rslt_flag = int_axis_up_tvalid && (int_axis_up_tuser & RSLT_USER_MASK);

  wire op0_last_flag  = op0_flag && int_axis_left_tlast;
  wire op1_last_flag  = op1_flag && int_axis_up_tlast;

  wire op_valid = op0_flag && op1_flag;

  wire partial_sum_last_reg_next = (fsm_state == FSM_END) ? partial_sum_last_reg : op0_last_flag && op1_last_flag;

  wire err_unalligned_data_int = op0_last_flag ^ op1_last_flag ;
  wire err_user_flag_int = op1_flag && rslt_flag;

  // FSM Output Signals
  reg  store_l_reg, store_u_reg;
  reg  forward_l_reg, forward_u_reg;
  
  reg  drop_l_reg, drop_u_reg;
  reg  push_d_reg;
  reg  [PE_J_WIDTH-1:0] timer; // To keep track that all nodes above have transfered their results first
 
  reg  op_start_reg;
  reg  bypass_adder_reg;

  wire export_rslt_int = push_d_reg && (!timer);
 
  reg  err_unalligned_data_reg, err_user_flag_reg;

  // Output Control Registers & Wires
  wire handshake_down  = int_axis_down_tvalid && int_axis_down_tready;
  wire handshake_right = int_axis_right_tvalid && int_axis_right_tready;

  // FSM Logic
  always @(posedge clk) begin
    if (rst) begin
      fsm_state <= FSM_STRT;
      
      // Freeze all data flows
      store_l_reg      <= 0;
      store_u_reg      <= 0;

      // forward_l_reg    <= 0;
      // forward_u_reg    <= 0;

      // Empty Buffers
      drop_l_reg       <= 1;
      drop_u_reg       <= 1;
      
      push_d_reg       <= 0;

      op_start_reg     <= 1;
      // bypass_adder_reg <= 1;
      partial_sum_last_reg <= 0;

      // Reset Errors
      err_unalligned_data_reg <= 0;
      err_user_flag_reg <= 0;

      // Reset Timer
      timer <= PE_POSITION_J;

    end else begin
      fsm_state <= fsm_state_next;
      
      case (fsm_state_next)
        FSM_STRT : begin
          // Store & Forward Left and Up
          store_l_reg      <= 1;
          store_u_reg      <= 1;

          // forward_l_reg    <= 1;
          // forward_u_reg    <= 1;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;

          // No Results to push yet
          push_d_reg       <= 0;

          // Reset Partial Sum
          op_start_reg     <= 1;
          // bypass_adder_reg <= 0;
          partial_sum_last_reg <= 0;

          // No Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;
        end
        FSM_STRL : begin
          // Store Up
          store_l_reg      <= 0;
          store_u_reg      <= 1;

          // forward_l_reg    <= 0;
          // forward_u_reg    <= 0;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;

         // No Results to push yet
          push_d_reg       <= 0;

          // Lock Partial Sum
          op_start_reg     <= 0;
          // bypass_adder_reg <= 1;
          partial_sum_last_reg <= 0;

          // No Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;

        end
        FSM_STRU : begin
          // Store Left
          store_l_reg      <= 1;
          store_u_reg      <= 0;

          // forward_l_reg    <= 0;
          // forward_u_reg    <= 0;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;

         // No Results to push yet
          push_d_reg       <= 0;

          // Lock Partial Sum
          op_start_reg     <= 0;
          // bypass_adder_reg <= 1;
          partial_sum_last_reg <= 0;

          // No Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;

        end
        FSM_MAC : begin
          // Store & Forward Left and Up
          store_l_reg      <= 1;
          store_u_reg      <= 1;

          // forward_l_reg    <= 1;
          // forward_u_reg    <= 1;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;

         // No Results to push yet
          push_d_reg       <= 0;

          // Update Partial Sum
          op_start_reg     <= 0;
          // bypass_adder_reg <= 0;
          partial_sum_last_reg <= partial_sum_last_reg_next;

          // No Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;

        end
        FSM_END : begin
          // Return & Forward Up
          store_l_reg      <= 0;
          store_u_reg      <= 1;

          // forward_l_reg    <= 0;
          // forward_u_reg    <= 1;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;

          // Push down
          push_d_reg       <= 1;

          // Lock Partial Sum
          op_start_reg     <= 0;
          // bypass_adder_reg <= 1;
          partial_sum_last_reg <= partial_sum_last_reg_next; 

          // No Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;

          if (timer && rslt_flag && handshake_down) begin
            timer <= timer - 1;
          end
        end
        FSM_ERR : begin
          // Flush Up and Left
          store_l_reg      <= 0;
          store_u_reg      <= 0;

          // forward_l_reg    <= 0;
          // forward_u_reg    <= 0;

          drop_l_reg       <= 1;
          drop_u_reg       <= 1;

         // Invalid Results
          push_d_reg       <= 0;

          // Lock Partial Sum
          op_start_reg     <= 0;
          // bypass_adder_reg <= 1;
          partial_sum_last_reg <= partial_sum_last_reg; 

          // Sample Errors
          err_unalligned_data_reg <= err_unalligned_data_int;
          err_user_flag_reg <= err_user_flag_int;

        end
        default: begin
          fsm_state <= FSM_STRT;
          partial_sum_last_reg <= 0;
          
          // Freeze all data flows
          store_l_reg      <= 0;
          store_u_reg      <= 0;

          // forward_l_reg    <= 0;
          // forward_u_reg    <= 0;

          drop_l_reg       <= 0;
          drop_u_reg       <= 0;
          
          push_d_reg       <= 0;

          op_start_reg     <= 0;
          // bypass_adder_reg <= 1;

          // Reset Errors
          err_unalligned_data_reg <= 0;
          err_user_flag_reg <= 0;

          // Reset Timer
          timer <= PE_POSITION_J;
        end
      endcase
    end
  end

  // FSM Next Stage Early Logic
  always @(fsm_state_next,fsm_state) begin
    
      case (fsm_state_next)
        FSM_STRT, FSM_MAC : begin
          // Forward Left and Up
          forward_l_reg    <= ~(fsm_state == FSM_END);
          forward_u_reg    <= 1;

          // Reset/Update Partial Sum
          bypass_adder_reg <= 0;
        end
        FSM_STRL : begin
          // Freeze Forwarding Left
          forward_l_reg    <= 0;
          forward_u_reg    <= 1;

          // Lock Partial Sum
          bypass_adder_reg <= 1;
        end
        FSM_STRU : begin
          // Freeze Forwarding Up
          forward_l_reg    <= 1;
          forward_u_reg    <= 0;

          // Lock Partial Sum
          bypass_adder_reg <= 1;
        end
        FSM_END : begin
          // Return & Forward Up
          forward_l_reg    <= op0_last_flag;
          forward_u_reg    <= 1;

          // Lock Partial Sum
          bypass_adder_reg <= (fsm_state == FSM_END);
        end
        FSM_ERR : begin
          // Flush Up and Left
          forward_l_reg    <= 0;
          forward_u_reg    <= 0;

          // Lock Partial Sum
          bypass_adder_reg <= 1;
        end
        default: begin
          // Freeze all data flows
          forward_l_reg    <= 0;
          forward_u_reg    <= 0;

          bypass_adder_reg <= 1;
        end
      endcase
  end

  `define CHECK_OP_LAST \
      if (partial_sum_last_reg_next) begin \
        fsm_state_next <= FSM_END; \
      end else if(op0_last_flag|op1_last_flag) begin \
        fsm_state_next <= FSM_ERR; \
      end else begin \
        fsm_state_next <= FSM_MAC; \
      end \

  // FSM Next State Logic
  always @(*) begin
    case (fsm_state)
      FSM_STRT, FSM_MAC : begin  
        if (op_valid) begin
          `CHECK_OP_LAST
        end else if(op0_flag) begin
          fsm_state_next <= FSM_STRL;
        end else if(op1_flag) begin
          fsm_state_next <= FSM_STRU;
        end
      end
      FSM_STRL : begin
        if (op_valid) begin
          `CHECK_OP_LAST
        end else begin
          fsm_state_next <= FSM_STRL;
        end
      end
      FSM_STRU : begin
        if (op_valid) begin
          `CHECK_OP_LAST
        end else begin
          fsm_state_next <= FSM_STRU;
        end
      end
      FSM_END : begin
        if (export_rslt_int && handshake_down) begin
          fsm_state_next <= FSM_STRT;  
        end else begin
          fsm_state_next <= FSM_END;
        end
      end
      FSM_ERR :
        fsm_state_next <= FSM_STRT;

      default: 
        fsm_state_next <= FSM_STRT;

    endcase
    if (err_unalligned_data_int || err_user_flag_int) begin
      fsm_state_next <= FSM_ERR;
    end
    if (rst) begin
      fsm_state_next <= FSM_STRT;
    end
  end


  // Control Unit Output
  assign store_l = store_l_reg;
  assign store_u = store_u_reg;
  assign forward_l = forward_l_reg;
  assign forward_u = forward_u_reg;
  assign drop_l = drop_l_reg;
  assign drop_u = drop_u_reg | (fsm_state == FSM_END && op1_flag);
  assign export_rslt = export_rslt_int;
  assign op_start = op_start_reg;
  assign bypass_adder = bypass_adder_reg  | !op_valid;
  assign err_unalligned_data = err_unalligned_data_reg;
  assign err_user_flag = err_user_flag_reg;

endmodule

`resetall
