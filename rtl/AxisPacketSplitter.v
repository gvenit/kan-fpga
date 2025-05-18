`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  AxisPacketSplitter : Accepts one input AXI-Stream and splits
 *    it to multiple packets in one output AXI-Streams.
 */

module AxisPacketSplitter #(
  // Width of AXI stream Data interfaces in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
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
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,
  // Width of Packet Size
  parameter PCKT_WIDTH = 32,
  // Allow locking module in its current state
  parameter ALLOW_LOCKS = 1,
  // Raise error flag if input packet non divisible
  parameter RAISE_NON_DIVISIBLE = 1
) (
  input  wire                   clk,
  input  wire                   rst,

  /*
   * Control signals
   */
  input  wire                   operation_start,
  input  wire [PCKT_WIDTH-1:0]  pckt_size,
  
  /*
   * Input Interrupt signals
   */
  input  wire                   lock,
  input  wire                   external_error,
  
  /*
   * Output Interrupt signals
   */
  output reg                    operation_busy,
  output reg                    operation_complete,
  output reg                    operation_error,
  output reg                    transmission,       // Active high if bus transmitted data in the current cycle

  /*
   * AXI Stream Data input
   */
  input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
  input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
  input  wire                   s_axis_tvalid,  
  output wire                   s_axis_tready,
  input  wire                   s_axis_tlast,
  input  wire [ID_WIDTH-1:0]    s_axis_tid,
  input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
  input  wire [USER_WIDTH-1:0]  s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [DATA_WIDTH-1:0]  m_axis_tdata,
  output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
  output wire                   m_axis_tvalid,
  input  wire                   m_axis_tready,
  output wire                   m_axis_tlast,
  output wire [ID_WIDTH-1:0]    m_axis_tid,
  output wire [DEST_WIDTH-1:0]  m_axis_tdest,
  output wire [USER_WIDTH-1:0]  m_axis_tuser
);
  // Global FSM states
  localparam FSM_WIDTH = 2;
  localparam FSM_STR = 0;
  localparam FSM_OPE = 1;
  localparam FSM_ERR = 2;
  localparam FSM_END = 3;

  // Control Registers & Wires
  reg  op_in_progress_reg = 1'b0;
  reg  [PCKT_WIDTH-1:0]  pckt_size_reg_early;

  // FSM Logic output Restiters & Wires
  reg  [FSM_WIDTH-1:0]  fsm_state, fsm_state_next;
  reg  [PCKT_WIDTH-1:0] pckt_size_counter_reg;

  // FSM Logic intput Registers & Wires
  wire s_axis_tready_int;
  wire get_next = operation_busy && s_axis_tvalid && s_axis_tready_int;
  wire [PCKT_WIDTH-1:0] pckt_size_counter_reg_next = (get_next) ? pckt_size_counter_reg+1 : pckt_size_counter_reg;

  wire generate_tlast = get_next && (pckt_size_counter_reg == pckt_size_reg_early);

  assign s_axis_tready     = operation_busy && s_axis_tready_int;
  wire   s_axis_tvalid_int = operation_busy && s_axis_tvalid;
  wire   s_axis_tlast_int  = generate_tlast || s_axis_tlast;

  // Global FSM state logic
  always @(posedge clk ) begin
    if (rst) begin
      fsm_state <= FSM_STR;

    end else begin
      fsm_state <= fsm_state_next;

      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

      case (fsm_state_next)
        FSM_STR: begin
          pckt_size_counter_reg <= $unsigned(0);
          pckt_size_reg_early <= pckt_size-1;

        end
        FSM_OPE: begin
          if (fsm_state != FSM_OPE) begin
            pckt_size_reg_early <= pckt_size-1;
          end
          if (get_next && generate_tlast) begin
            pckt_size_counter_reg <= $unsigned(0);
          end else begin
            pckt_size_counter_reg <= pckt_size_counter_reg_next;
          end
          operation_busy <= 1'b1;

        end
        FSM_END: begin
          pckt_size_counter_reg <= $unsigned(0);
          operation_complete <= 1'b1;
          
        end
        FSM_ERR: begin
          operation_error <= 1'b1;

        end
        default: begin
          
        end 
      endcase
    end
  end

  `define CHECK_OP_START \
    if (operation_start) begin \
      fsm_state_next <= FSM_OPE; \
    end else begin \
      fsm_state_next <= FSM_STR; \
    end 

  // Global FSM next state logic
  always @(*) begin
    if (~ALLOW_LOCKS || ~lock) begin
      case (fsm_state)
        FSM_STR: begin
          `CHECK_OP_START
        end
        FSM_OPE: begin
          fsm_state_next <= FSM_OPE;
          if (get_next && s_axis_tlast) begin
            if (generate_tlast) begin
              fsm_state_next <= FSM_END;
            end else if (RAISE_NON_DIVISIBLE) begin
              fsm_state_next <= FSM_ERR;
            end else begin
              fsm_state_next <= FSM_END;
            end
          end
        end
        FSM_END: begin
          `CHECK_OP_START
        end
        FSM_ERR: begin
          fsm_state_next <= FSM_STR;
          
        end
        default: begin
          fsm_state_next <= FSM_STR;
          
        end 
      endcase
    end 
    if (external_error) begin
      fsm_state_next <= FSM_ERR;
    end
    if (rst) begin
      fsm_state_next <= FSM_STR;
    end
  end

  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
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
  ) in_axis_register_inst (
    .clk                  (clk),
    .rst                  (rst),
    .s_axis_tdata         (s_axis_tdata),
    .s_axis_tkeep         (s_axis_tkeep),
    .s_axis_tvalid        (s_axis_tvalid_int),
    .s_axis_tready        (s_axis_tready_int),
    .s_axis_tlast         (s_axis_tlast_int),
    .s_axis_tid           (s_axis_tid),
    .s_axis_tdest         (s_axis_tdest),
    .s_axis_tuser         (s_axis_tuser),
    .m_axis_tdata         (m_axis_tdata),
    .m_axis_tkeep         (m_axis_tkeep),
    .m_axis_tvalid        (m_axis_tvalid),
    .m_axis_tready        (m_axis_tready),
    .m_axis_tlast         (m_axis_tlast),
    .m_axis_tid           (m_axis_tid),
    .m_axis_tdest         (m_axis_tdest),
    .m_axis_tuser         (m_axis_tuser)
  );

  // Transmission flag
  always @(posedge clk ) begin
    transmission <= 1'b0;
    if (m_axis_tvalid && m_axis_tready) begin
      transmission <= 1'b1;
    end
  end

`undef CHECK_OP_START
endmodule

`resetall
