`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  AxisPacketJoiner : Accepts multiple input AXI-Stream Packets 
 *    and outputs a single Axi-Stream Packet. The output packet 
 *    is a concatenation of the input packets. The module awaits
 *    data from the specified channels, starting from the first
 *    channel.
 */
`include "header_utils.vh"

module AxisPacketJoiner #(
  // Number of Channels
  parameter CHANNELS = 2,
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
  // Allow locking module in its current state
  parameter ALLOW_LOCKS = 1
) (
  input  wire                             clk,
  input  wire                             rst,

  /*
   * Control signals
   */
  input  wire                             operation_start,
  input  wire [CHANNELS-1:0]              use_channels,
  
  /*
   * Input Interrupt signals
   */
  input  wire                             lock,
  input  wire                             interrupt,
  
  /*
   * Output Interrupt signals
   */
  output reg                              operation_busy,
  output reg                              operation_complete,
  output reg                              operation_error,
  output reg                              transmission,       // Active high if bus transmitted data in the current cycle

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]   s_axis_tdata,
  input  wire [CHANNELS*KEEP_WIDTH-1:0]   s_axis_tkeep,
  input  wire [CHANNELS-1:0]              s_axis_tvalid,  
  output wire [CHANNELS-1:0]              s_axis_tready,
  input  wire [CHANNELS-1:0]              s_axis_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]     s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]   s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]   s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [DATA_WIDTH-1:0]            m_axis_tdata,
  output wire [KEEP_WIDTH-1:0]            m_axis_tkeep,
  output wire                             m_axis_tvalid,
  input  wire                             m_axis_tready,
  output wire                             m_axis_tlast,
  output wire [ID_WIDTH-1:0]              m_axis_tid,
  output wire [DEST_WIDTH-1:0]            m_axis_tdest,
  output wire [USER_WIDTH-1:0]            m_axis_tuser
);

generate
 if (CHANNELS == 1) begin : pass_through_genblock
  reg allow_transmission = 1'b1;

  // Pass through
  assign m_axis_tdata  = s_axis_tdata;
  assign m_axis_tkeep  = s_axis_tkeep;
  assign m_axis_tvalid = s_axis_tvalid && allow_transmission;
  assign s_axis_tready = m_axis_tready && allow_transmission;
  assign m_axis_tlast  = s_axis_tlast;
  assign m_axis_tid    = s_axis_tid;
  assign m_axis_tdest  = s_axis_tdest;
  assign m_axis_tuser  = s_axis_tuser;

  always @(posedge clk ) begin
    if (rst) begin
      operation_error    <= 1'b0;
      operation_busy     <= 1'b0;
      operation_complete <= 1'b0;

      transmission       <= 1'b0;
      allow_transmission <= 1'b0;
        
    end else begin
      operation_error    <= 1'b0;
      operation_busy     <= operation_start || operation_busy;
      operation_complete <= 1'b0;

      transmission       <= m_axis_tvalid && m_axis_tready;
      allow_transmission <= operation_start || allow_transmission;

      if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
        operation_busy     <= operation_start;
        operation_complete <= 1'b1;
        allow_transmission <= operation_start;
      end
    end
  end

 end else begin : joiner_logic_genblock
  // Local Parameters
  localparam CLOG2_CHANNELS = `LOG2( CHANNELS );

  // Global FSM states
`ifdef USE_ONE_HOT_ENCODING_FSM
  localparam FSM_WIDTH = 4;
  localparam FSM_STR = 2 ** 0;
  localparam FSM_OPE = 2 ** 1;
  localparam FSM_ERR = 2 ** 2;
  localparam FSM_END = 2 ** 3;
`else
  localparam FSM_WIDTH = 2;
  localparam FSM_STR = 0;
  localparam FSM_OPE = 1;
  localparam FSM_ERR = 2;
  localparam FSM_END = 3;
`endif 

  // Control Registers & Wires
  wire int_rst = rst || interrupt;
  reg  lock_reg;

  reg  [CHANNELS-1:0]  use_channels_reg;

  // FSM Logic output Restiters & Wires
  reg  [FSM_WIDTH-1:0] fsm_state, fsm_state_next;

  // FSM Logic intput Registers & 
  wire [CHANNELS-1:0]       s_axis_tready_int;
  wire [CHANNELS-1:0]       s_axis_tvalid_int = {CHANNELS{(operation_busy || ~lock_reg)}} & use_channels_reg & s_axis_tvalid;

  wire                      grant_valid;
  wire [CHANNELS-1:0]       grant;
  wire [CHANNELS-1:0]       acknowledge = s_axis_tlast & s_axis_tvalid_int & s_axis_tready_int & grant;
  wire [CLOG2_CHANNELS-1:0] grant_encoded;

  wire                      generate_tlast = (use_channels_reg & (~acknowledge)) == 0; // $unsigned(use_channels_reg & (~grant)) < $unsigned(grant);
  wire                      generate_tlast_out;
  wire                      tlast_transmitted = m_axis_tready && m_axis_tvalid && m_axis_tlast && generate_tlast_out;

  wire                      m_axis_tlast_int;
  assign                    m_axis_tlast = m_axis_tlast_int && generate_tlast_out;

  assign s_axis_tready = {CHANNELS{(operation_busy || ~lock_reg)}} & use_channels_reg & s_axis_tready_int;

  // Global FSM state logic
  always @(posedge clk ) begin
    if (rst) begin
      fsm_state <= FSM_STR;

      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;
      use_channels_reg      <= 0;

      lock_reg              <= 1'b0;

    end else begin
      fsm_state <= fsm_state_next;

      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;
      use_channels_reg      <= use_channels_reg;

      lock_reg              <= lock;

      case (fsm_state_next)
        FSM_STR: begin
          use_channels_reg   <= 0;
        end
        FSM_OPE: begin
          if (fsm_state != FSM_OPE && operation_start) begin
            use_channels_reg <= use_channels;
          end else begin
            use_channels_reg <= use_channels_reg & (~acknowledge);
          end
          operation_busy <= 1'b1;

        end
        FSM_END: begin
          operation_complete <= 1'b1;
          use_channels_reg   <= 0;
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
      if (use_channels) begin \
        fsm_state_next <= FSM_OPE; \
      end else begin \
        fsm_state_next <= FSM_ERR; \
      end \
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
          if (tlast_transmitted) begin
            fsm_state_next <= FSM_END;
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
    if (int_rst) begin
      fsm_state_next <= FSM_STR;
    end
  end

  wire [CHANNELS*(USER_WIDTH+1)-1:0] s_axis_tuser_int;

  genvar CHN;
  for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1) begin
    assign s_axis_tuser_int[CHN*(USER_WIDTH+1) +: USER_WIDTH+1] = {generate_tlast, s_axis_tuser[CHN*USER_WIDTH +: USER_WIDTH]};
  end

  axis_mux #(
    // Number of AXI stream inputs
    .S_COUNT(CHANNELS),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
    // Propagate tid signal
    .ID_ENABLE(ID_ENABLE),
    // tid signal width
    .ID_WIDTH(ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(1),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH+1)
  ) axis_mux_inst (
    .clk            (clk),
    .rst            (int_rst),
    .s_axis_tdata   (s_axis_tdata),
    .s_axis_tkeep   (s_axis_tkeep),
    .s_axis_tvalid  (s_axis_tvalid_int),
    .s_axis_tready  (s_axis_tready_int),
    .s_axis_tlast   (s_axis_tlast),
    .s_axis_tid     (s_axis_tid),
    .s_axis_tdest   (s_axis_tdest),
    .s_axis_tuser   (s_axis_tuser_int),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tkeep   (m_axis_tkeep),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast_int),
    .m_axis_tid     (m_axis_tid),
    .m_axis_tdest   (m_axis_tdest),
    .m_axis_tuser   ({generate_tlast_out, m_axis_tuser}),
    .enable         (grant_valid),
    .select         (grant_encoded)
  );

  arbiter # (
    .PORTS(CHANNELS),
    // select round robin arbitration
    .ARB_TYPE_ROUND_ROBIN(1),
    // blocking arbiter enable
    .ARB_BLOCK(1),
    // block on acknowledge assert when nonzero, request deassert when 0
    .ARB_BLOCK_ACK(1),
    // LSB priority selection
    .ARB_LSB_HIGH_PRIORITY(1)
  ) arbiter_inst (
    .clk           (clk),
    .rst           (int_rst || fsm_state == FSM_END),
    .request       (use_channels_reg),
    .acknowledge   (acknowledge),
    .grant         (grant),
    .grant_valid   (grant_valid),
    .grant_encoded (grant_encoded)
  );

  // Transmission flag
  always @(posedge clk ) begin
    transmission <= 1'b0;
    if (m_axis_tvalid && m_axis_tready) begin
      transmission <= 1'b1;
    end
  end

 end
endgenerate

`undef CHECK_OP_START
endmodule

`resetall
