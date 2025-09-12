`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * ParallelizedLPEControlUnit : Control Unit for ParallelizedLinearProcessingElement
 * 
 * Top-Axis Forwarding Protocol
 *  1. Only add partial sums when PE is in END state.
 *  2. If a PE accepts data when not in END state, the local partial 
 *      sum shall inherit the tlast flag of the accepted data and 
 *      the accepted data shall have the tlast flag unset.
 *  3. The first PE shall only forward the partial sum it produces
 *      with the tlαst flag set.
 *  4. Always add partial sums when possible. The summation inherits
 *      the tlast flag of the accepted partial sum.
 *  5. When addition is not possible, forward data to the next PE.
 *  6. If forwarding is not possible, keep the data until one of 
 *      the previous steps can be executed.
 *  7. If the PE forwards the partial sum with the tlast set, the
 *      PE shall change its state from END to STRT.
 *  8. The last PE shall only forward data when the local partial sum
 *      inherits a tlast flag that is set.
 */

module ParallelizedLPEControlUnit #(
    // Number of PEs in Processing Array j axis
    parameter PE_NUMBER_J = 4,
    // Position of current PE in the j axis
    parameter PE_POSITION_J = 0
) (
  input  wire                       clk,
  input  wire                       rst,

  /*
   * AXI Stream Up input
   */
  input  wire                       int_axis_u_tvalid,
  input  wire                       int_axis_u_tlast,

  /*
   * AXI Stream Down Output
   */
  input  wire                       int_axis_d_tready,

  /*
   * AXI Stream Left input
   */
  input  wire                       int_axis_l_tvalid,
  input  wire                       int_axis_l_tlast,

  /*
   * AXI Stream Right Output
   */
  input  wire                       int_axis_r_tready,
  
  /*
   * AXI Stream Top Output
   */
  input  wire                       int_axis_t_tvalid,
  input  wire                       int_axis_t_tlast,

  /*
   * AXI Stream Bottom Output
   */
  input  wire                       int_axis_b_tready,
  
  // input  wire                       export_rslt_sync,
  // input  wire                       export_rslt_last_sync,

  output wire                       store_l,
  output wire                       store_t,
  output wire                       store_u,
  output wire                       forward_l,
  output wire                       forward_t,
  output wire                       forward_u,
  output wire                       drop_l,
  output wire                       drop_t,
  output wire                       drop_u,
  output wire                       export_rslt,
  output wire                       export_rslt_last,

  output wire                       op_start,
  output wire                       bypass_adder,
  output wire                       acc_res,

  /*
   * Error Outputs
   */
  output wire                       err_unalligned_data
);
  // FSM States
`ifdef USE_ONE_HOT_ENCODING_FSM
  localparam FSM_STATE_WIDTH = 6;
  localparam FSM_ST0  = 2 ** 0;
  localparam FSM_STRL = 2 ** 1;
  localparam FSM_STRT = 2 ** 2;
  localparam FSM_MAC  = 2 ** 3;
  localparam FSM_ERR  = 2 ** 4;
  localparam FSM_END  = 2 ** 5;
`else
  localparam FSM_STATE_WIDTH = 3;
  localparam FSM_ST0  = 3'd0;
  localparam FSM_STRL = 3'd1;
  localparam FSM_STRT = 3'd2;
  localparam FSM_MAC  = 3'd3;
  localparam FSM_ERR  = 3'd4;
  localparam FSM_END  = 3'd5;
`endif 

  // FSM Registers & Wires
  reg  [FSM_STATE_WIDTH-1:0] fsm_state, fsm_state_next;
  
  // FSM Output Signals
  reg  store_l_reg, store_t_reg, store_u_reg;
  reg  forward_l_reg, forward_t_reg, forward_u_reg;
  
  reg  drop_l_reg, drop_t_reg, drop_u_reg;
  reg  export_rslt_reg;
  reg  export_rslt_last_reg;
 
  reg  op_start_reg;
  reg  bypass_adder_reg;
  reg  acc_res_reg;

  reg  err_unalligned_data_reg = 1'b0;

  // FSM input signals
  wire op0_flag  = int_axis_l_tvalid && int_axis_r_tready;
  wire op1_flag  = int_axis_t_tvalid && int_axis_b_tready;
  wire rslt_flag = int_axis_u_tvalid;

  wire down_axis_open = forward_u && int_axis_d_tready;

  wire op0_last_flag  = op0_flag && int_axis_l_tlast;
  wire op1_last_flag  = op1_flag && int_axis_t_tlast;
  wire rslt_last_flag = rslt_flag && int_axis_u_tlast;

  wire op_valid = op0_flag && op1_flag;

  wire partial_sum_last_reg_next = op0_last_flag && op1_last_flag;

  wire export_rslt_int;
  wire export_rslt_reg_next = export_rslt_reg || export_rslt_int;
  wire export_rslt_last_int;

  generate
    if (PE_POSITION_J == 0) begin
      assign export_rslt_int = fsm_state == FSM_END;
    end else if (PE_POSITION_J == PE_NUMBER_J-1 && PE_POSITION_J > 0) begin
      assign export_rslt_int = export_rslt_last_int;
    end else begin
      assign export_rslt_int = (fsm_state == FSM_END) ? !rslt_flag : 1'b0;
    end
  endgenerate

  wire err_unalligned_data_int = op_valid && (op0_last_flag ^ op1_last_flag) ;

  // // Output Control Registers & Wires -- For debugging
  // wire handshake_r = int_axis_r_tvalid && int_axis_r_tready;
  // wire handshake_d = int_axis_d_tvalid && int_axis_d_tready;
  // wire handshake_b = int_axis_b_tvalid && int_axis_b_tready;

  // FSM Logic
  always @(posedge clk) begin
    if (rst) begin
      fsm_state <= FSM_ST0;
      
      // Freeze all data flows
      store_l_reg      <= 1'b0;
      store_t_reg      <= 1'b0;
      store_u_reg      <= 1'b0;

      // Empty Buffers
      drop_l_reg       <= 1'b1;
      drop_t_reg       <= 1'b1;
      drop_u_reg       <= 1'b1;
      
      // Reset Partial Sum
      op_start_reg     <= 1'b1;
      // partial_sum_last_reg <= 1'b0; 

      // Do not Accumulate Partial Sums
      acc_res_reg      <= 1'b0;

      // Reset Errors
      err_unalligned_data_reg <= 1'b0;

    end else begin
      fsm_state <= fsm_state_next;
      
      case (fsm_state_next)
        FSM_ST0 : begin
          // Store & Forward Left and Up
          store_l_reg      <= 1'b1;
          store_t_reg      <= 1'b1;
          store_u_reg      <= 1'b1;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;

          // Reset/Update Partial Sum
          op_start_reg     <= 1'b1;
          // partial_sum_last_reg <= 1'b0;

          // Do not Accumulate Partial Sums
          acc_res_reg      <= 1'b0;

          // No Errors
          err_unalligned_data_reg <= 1'b0;

          export_rslt_reg <= 1'b0;

        end
        FSM_STRL : begin
          // Store Up
          store_l_reg      <= 1'b1;
          store_t_reg      <= 1'b1;
          store_u_reg      <= 1'b1;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;

          // Lock Partial Sum
          op_start_reg     <= 1'b0;
          // partial_sum_last_reg <= 1'b0;
          
          // Do not Accumulate Partial Sums
          acc_res_reg      <= 1'b0;
          
          // No Errors
          err_unalligned_data_reg <= 1'b0;

          export_rslt_reg <= 1'b0;

        end
        FSM_STRT : begin
          // Store Left
          store_l_reg      <= 1'b1;
          store_t_reg      <= 1'b1;
          store_u_reg      <= 1'b1;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;

          // Lock Partial Sum
          op_start_reg     <= 1'b0;
          // partial_sum_last_reg <= 1'b0;
          
          // Do not Accumulate Partial Sums
          acc_res_reg      <= 1'b0;

          // No Errors
          err_unalligned_data_reg <= 1'b0;

          export_rslt_reg <= 1'b0;

        end
        FSM_MAC : begin
          // Store & Forward Left and Up
          store_l_reg      <= 1'b1;
          store_t_reg      <= 1'b1;
          store_u_reg      <= 1'b1;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;
          
          // Reset/Update Partial Sum
          op_start_reg     <= 1'b0;
          // partial_sum_last_reg <= partial_sum_last_reg_next;

          // Do not Accumulate Partial Sums
          acc_res_reg      <= 1'b0;
          
          // No Errors
          err_unalligned_data_reg <= 1'b0;

          export_rslt_reg <= 1'b0;

        end
        FSM_END : begin
          // Return & Forward Up + Store Left & Top for new batch
          store_l_reg      <= 1'b1;
          store_t_reg      <= 1'b1;
          store_u_reg      <= 1'b1;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;

          // Lock Partial Sum
          op_start_reg     <= 1'b0;
          // partial_sum_last_reg <= partial_sum_last_reg_next; 

          // Accumulate Partial Sums
          // acc_res_reg      <= 1'b1;
          acc_res_reg      <= (PE_POSITION_J == PE_NUMBER_J-1);

          if (int_axis_d_tready) begin
            export_rslt_reg <= export_rslt_reg_next && (PE_POSITION_J != 0);
          end

          // No Errors
          err_unalligned_data_reg <= 1'b0;

        end
        FSM_ERR : begin
          // Flush Up and Left
          store_l_reg      <= 1'b0;
          store_t_reg      <= 1'b0;
          store_u_reg      <= 1'b0;

          drop_l_reg       <= 1'b1;
          drop_t_reg       <= 1'b1;
          drop_u_reg       <= 1'b1;

          // Lock Partial Sum
          op_start_reg     <= 1'b0;
          // partial_sum_last_reg <= partial_sum_last_reg; 

          // Do not Accumulate Partial Sums
          acc_res_reg      <= 1'b0;

          // Sample Errors
          err_unalligned_data_reg <= err_unalligned_data_int;

        end
        default: begin
          fsm_state <= FSM_ST0;
          // partial_sum_last_reg <= 1'b0;
          
          // Freeze all data flows
          store_l_reg      <= 1'b0;
          store_t_reg      <= 1'b0;
          store_u_reg      <= 1'b0;

          drop_l_reg       <= 1'b0;
          drop_t_reg       <= 1'b0;
          drop_u_reg       <= 1'b0;

          op_start_reg     <= 1'b0;
          acc_res_reg      <= 1'b0;

          // Reset Errors
          err_unalligned_data_reg <= 1'b0;
        end
      endcase
    end
  end

  // FSM Next Stage Early Logic
  always @(*) begin
    case (fsm_state_next)
      FSM_ST0, FSM_MAC : begin
        // Forward Left, Top and Up
        forward_l_reg    <= 1'b1;
        forward_t_reg    <= 1'b1;
        forward_u_reg    <= (PE_POSITION_J != PE_NUMBER_J-1);

        // Reset/Update Partial Sum
        bypass_adder_reg <= !op_valid;
      end
      FSM_STRL : begin
        // Freeze Forwarding Left
        forward_l_reg    <= 1'b0;
        forward_t_reg    <= 1'b1;
        forward_u_reg    <= (PE_POSITION_J != PE_NUMBER_J-1);

        // Lock Partial Sum
        bypass_adder_reg <= 1'b1;
      end
      FSM_STRT : begin
        // Freeze Forwarding Top
        forward_l_reg    <= 1'b1;
        forward_t_reg    <= 1'b0;
        forward_u_reg    <= (PE_POSITION_J != PE_NUMBER_J-1);

        // Lock Partial Sum
        bypass_adder_reg <= 1'b1;
      end
      FSM_END : begin
        // Add or Forward Up
        forward_l_reg    <= (fsm_state == FSM_END) ? export_rslt_int && op_valid : 1'b1;
        forward_t_reg    <= (fsm_state == FSM_END) ? export_rslt_int && op_valid : 1'b1;
        forward_u_reg    <= (PE_POSITION_J != PE_NUMBER_J-1);

        // Lock Partial Sum
        bypass_adder_reg <= (fsm_state == FSM_END) ? 
          (PE_POSITION_J ? export_rslt_reg_next || !rslt_flag : !int_axis_d_tready) : 
          !op_valid;
      end
      FSM_ERR : begin
        // Flush Top, Left and Up
        forward_l_reg    <= 1'b0;
        forward_t_reg    <= 1'b0;
        forward_u_reg    <= 1'b0;

        // Lock Partial Sum
        bypass_adder_reg <= 1'b1;
      end
      default: begin
        // Freeze all data flows
        forward_l_reg    <= 1'b0;
        forward_t_reg    <= 1'b0;
        forward_u_reg    <= 1'b0;

        // Lock Partial Sum
        bypass_adder_reg <= 1'b1;
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
      end 

  // FSM Next State Logic
  always @(*) begin
    fsm_state_next <= fsm_state;
    case (fsm_state)
      FSM_ST0, FSM_MAC : begin  
        if (op_valid) begin
          `CHECK_OP_LAST
        end else if(op0_flag) begin
          fsm_state_next <= FSM_STRL;
        end else if(op1_flag) begin
          fsm_state_next <= FSM_STRT;
        end
      end
      FSM_STRL : begin
        if (op_valid) begin
          `CHECK_OP_LAST
        end else begin
          fsm_state_next <= FSM_STRL;
        end
      end
      FSM_STRT : begin
        if (op_valid) begin
          `CHECK_OP_LAST
        end else begin
          fsm_state_next <= FSM_STRT;
        end
      end
      FSM_END : begin
        if (export_rslt_last_int && int_axis_d_tready) begin
          if (op_valid) begin
            `CHECK_OP_LAST
          end else if(op0_flag) begin
            fsm_state_next <= FSM_STRL;
          end else if(op1_flag) begin
            fsm_state_next <= FSM_STRT;
          end else begin
            fsm_state_next <= FSM_ST0;  
          end
        end else begin
          fsm_state_next <= FSM_END;
        end
      end
      FSM_ERR :
        fsm_state_next <= FSM_ST0;

      default: 
        fsm_state_next <= FSM_ST0;
    endcase
    if (err_unalligned_data_int) begin
      fsm_state_next <= FSM_ERR;
    end
    if (rst) begin
      fsm_state_next <= FSM_ST0;
    end
  end

  // Control Unit Output
  assign store_l = store_l_reg;
  assign store_t = store_t_reg;
  assign forward_l = forward_l_reg;
  assign forward_t = forward_t_reg;
  assign drop_l = drop_l_reg;
  assign drop_t = drop_t_reg;
  assign bypass_adder = bypass_adder_reg;
  assign err_unalligned_data = err_unalligned_data_int | err_unalligned_data_reg;

  assign op_start = op_start_reg || (fsm_state == FSM_END && fsm_state_next != FSM_END); 

  generate
    if (PE_POSITION_J) assign store_u = store_u_reg;
    if (PE_POSITION_J) assign forward_u = forward_u_reg;
    if (PE_POSITION_J) assign acc_res = fsm_state_next == FSM_END ? acc_res_reg : 1'b0;
    // if (PE_POSITION_J) assign op_start = op_start_reg | (down_axis_open && export_rslt_reg_next); 
    // if (PE_POSITION_J) assign op_start = op_start_reg || (fsm_state == FSM_END && fsm_state_next != FSM_END); 

    if (PE_POSITION_J == 0) begin
      // No Up Axis in this PE -- Always drop Up Axis 
      assign store_u   = 1'bZ;  // Not used
      assign forward_u = 1'bZ;  // Not used
      assign drop_u    = 1'bZ;  // Not used
      assign acc_res   = 1'b0;  // No data to accumulate
      // assign op_start = op_start_reg | (export_rslt && int_axis_d_tready);

      assign export_rslt_last_int = export_rslt;

      assign export_rslt = (export_rslt_reg) ? 0 : export_rslt_int;
      assign export_rslt_last = export_rslt_last_int;

    end else if (PE_POSITION_J == PE_NUMBER_J-1) begin
      // Registers & Wires
      reg  local_tlast_reg;
      
      wire partial_sum_updated  = acc_res_reg && !bypass_adder_reg;
      wire local_tlast_reg_next = partial_sum_updated && int_axis_u_tlast;

      always @(posedge clk ) begin
        if (rst) begin
          local_tlast_reg <= 1'b0;
        end else begin
          case (fsm_state)
            FSM_END: begin
              local_tlast_reg <= local_tlast_reg_next;
            end 
            default: begin
              local_tlast_reg <= 1'b0;
            end 
          endcase
        end
      end

      assign drop_u = drop_u_reg || partial_sum_updated;
      assign export_rslt_last_int = local_tlast_reg;

      assign export_rslt = export_rslt_int;
      assign export_rslt_last = export_rslt_last_int;

    end else begin
      // Registers & Wires
      reg  local_tlast_reg;

      wire partial_sum_updated  = acc_res_reg && !bypass_adder_reg;
      wire local_sum_tlast_reg_next = partial_sum_updated;        // Inherited from summing the last data
      wire local_fw_tlast_reg_next  = down_axis_open;             // Inherited from forwarding the last data
      wire local_tlast_reg_next = ((local_sum_tlast_reg_next || local_fw_tlast_reg_next) && rslt_last_flag) || local_tlast_reg;

      always @(posedge clk) begin
        if (rst) begin
          local_tlast_reg <= 1'b0;
        end else begin
          case (fsm_state_next)
            FSM_END: begin
              local_tlast_reg <= local_tlast_reg_next;
            end 
            default: begin
              local_tlast_reg <= 1'b0;
            end 
          endcase
        end
      end

      // Drop Up if used in addition
      assign drop_u = drop_u_reg || partial_sum_updated;
      assign export_rslt_last_int = (export_rslt_reg) ? rslt_last_flag : local_tlast_reg;
      
      assign export_rslt = (export_rslt_reg) ? 0 : export_rslt_int;
      assign export_rslt_last = export_rslt_last_int;
    end
  endgenerate

endmodule

`resetall
