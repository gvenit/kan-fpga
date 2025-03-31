`resetall
`timescale 1ns/1ps
`default_nettype none

module MCULocalFSM #(
  `include "MCUGlobalFSMparameters.vh"
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 16,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of iteration counters
  parameter ITER_WIDTH = 32,
  // BRAM control has valid signal
  parameter BRAM_VALID_SIG = 1
) (
  input  wire                       clk,
  input  wire                       rst,

  /*
   * Data BRAM Control Interface
   */
  output wire                       bram_en;
  // output wire [WE-1:0]              bram_we;  // Read Only Operations allowed
  output wire [ADDR_WIDTH-1:0]      bram_addr;
  // input  wire [DATA_WIDTH-1:0]      bram_wrdata;
  input  wire [DATA_WIDTH-1:0]      bram_rddata,
  input  wire                       bram_rdvalid,  // Ignore if BRAM_VALID_SIG == 0

  /*
   * AXI Stream Data Output
   */
  output wire [DATA_WIDTH-1:0]      m_axis_data_tdata,
  output wire                       m_axis_data_tvalid,
  input  wire                       m_axis_data_tready,
  output wire                       m_axis_data_tlast,
  
  /*
   * Local FSM input signals
   */
  input  wire [GLO_FSM_WIDTH-1:0]   glo_fsm_state,
  input  wire [ADDR_WIDTH:0]        addr_counter_max,
  input  wire [ITER_WIDTH-1:0]      inter_counter_max,
  input  wire [ITER_WIDTH-1:0]      intra_counter_max,

  /*
   * Local FSM output signals
   */
  output wire                       tlast_transmitted,
  output wire                       error
);
  // Local FSM states
  localparam LOC_FSM_WIDTH = 3;
  localparam LOC_FSM_ST0 = 0;
  localparam LOC_FSM_STR = 1;
  localparam LOC_FSM_OPE = 2;
  localparam LOC_FSM_END = 3;
  localparam LOC_FSM_ERR = 4;

  // Input signals
  wire bram_rdvalid_int;

  generate
    if (BRAM_VALID_SIG > 0) begin
      assign bram_rdvalid_int = bram_rdvalid;
    end else begin
      assign bram_rdvalid_int = 1'b1;
    end
  endgenerate

  // Local Register I/O Registers & Wires
  wire [DATA_WIDTH_DATA-1:0]  loc_in_axis_tdata,  loc_out_axis_tdata;
  wire                        loc_in_axis_tvalid, loc_out_axis_tvalid;
  wire                        loc_in_axis_tready, loc_out_axis_tready;
  wire                        loc_in_axis_tlast,  loc_out_axis_tlast;

  // Local FSM Internal Registers & Wires
  reg [LOC_FSM_WIDTH-1:0]    loc_fsm_state, loc_fsm_state_next;
  reg [ADDR_WIDTH:0]         loc_counter_addr_reg, loc_counter_addr_reg_next;
  reg [ITER_WIDTH-1:0]       loc_counter_iter_reg, loc_counter_iter_reg_next; // Inter-Iteration Counter
  reg                        bram_en_reg, store_data_reg, last_flag, last_flag_reg;
  wire get_next_addr = loc_in_tvalid && loc_in_tready;
  reg  get_next_iter;

  assign loc_counter_addr_reg_next = (get_next_iter) ? $unsigned(0) : (
                                        (get_next_addr) ? loc_counter_addr_reg + 1 : loc_counter_addr_reg
                                    );
  assign loc_counter_iter_reg_next = (get_next_iter) ? loc_counter_iter_reg + 1 : loc_counter_iter_reg;

  
  // Local FSM Output Registers & Wires
  assign bram_en    = bram_en_reg && ((loc_fsm_state == LOC_FSM_STR || loc_fsm_state == LOC_FSM_END) ? 1'b1 : loc_out_axis_tready);
  assign bram_addr  = (loc_fsm_state == LOC_FSM_STR || get_next_iter) ? $unsigned(0) : loc_counter_addr_reg[ADDR_WIDTH-1:0];
  assign store_data = store_data_reg;

  assign loc_in_axis_tdata  = bram_rddata;
  assign loc_in_axis_tvalid = bram_rdvalid_int;
  assign loc_in_axis_tlast  = last_flag || last_flag_reg;

  `define LOC_CHECK_OP_START(operation_start, fsm_state_next, bram_en_reg, last_flag, addr_counter_max, inter_counter_max)\
    bram_en_reg <= 1'b0; \
      last_flag <= 1'b0; \
    if (operation_start) begin \
      if(counter_max == 0) begin \
        fsm_state_next <= LOC_FSM_ERR; \
      end else if (addr_counter_max == 1 && inter_counter_max == 1) begin \
        fsm_state_next <= LOC_FSM_END; \
        bram_en_reg <= 1'b1; \
        last_flag <= 1'b1; \
      end else begin \
        fsm_state_next <= LOC_FSM_OPE; \
        bram_en_reg <= 1'b1; \
      end \
    end else begin \
      fsm_state_next <= LOC_FSM_STR; \
    end 

  // Local FSM state logic
  always @(posedge clk ) begin
    if (rst) begin 
      loc_fsm_state <= LOC_FSM_STR;

      loc_counter_addr_reg <= 0;

    end else begin
      loc_fsm_state   <= loc_fsm_state_next;
      loc_counter_addr_reg <= $unsigned(0);
      store_data_reg       <= 1'b0;
      loc_counter_iter_reg <= loc_counter_iter_reg;

      case (loc_fsm_state_next)
        LOC_FSM_STR: begin
          loc_counter_addr_reg <= $unsigned(1);
          loc_counter_iter_reg <= $unsigned(1);
        end
        LOC_FSM_OPE: begin
          store_data_reg <= 1'b1;
          loc_counter_addr_reg <= loc_counter_addr_reg_next;
          loc_counter_iter_reg <= loc_counter_iter_reg_next;

        end
        LOC_FSM_END: begin
          store_data_reg <= 1'b1;
          
        end
        LOC_FSM_ERR: begin
          
        end
        default: begin
        end
      endcase
    end
  end
  
  // Local Scale FSM next state logic
  always @(*) begin
    bram_en_reg   <= 1'b0;
    get_next_iter <= 1'b0;
    case (loc_fsm_state)
      LOC_FSM_STR: begin
        `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, fsm_state_next, bram_en_reg, last_flag, addr_counter_max, inter_counter_max)
      end
      LOC_FSM_OPE: begin
        bram_en_reg <= 1'b1;
        fsm_state_next <= LOC_FSM_OPE;
        if (loc_counter_addr_reg == addr_counter_max) begin
          get_next_iter <= 1'b1;
          if (loc_counter_iter_reg == inter_counter_max) begin
            last_flag <= 1'b1;
            fsm_state_next <= LOC_FSM_END;
          end
        end
      end
      LOC_FSM_END: begin
        `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, fsm_state_next, bram_en_reg, last_flag, addr_counter_max, inter_counter_max)
      end
      LOC_FSM_ERR: begin
        loc_fsm_state_next <= LOC_FSM_STR;
        
      end
      default: begin
        loc_fsm_state_next <= LOC_FSM_STR;
        
      end 
    endcase
    if (internal_error) begin
      loc_fsm_state_next <= LOC_FSM_ERR;
    end
    if (rst) begin
      loc_fsm_state_next <= LOC_FSM_STR;
    end
  end 

  // Last flag store
  always @(posedge clk ) begin
    last_flag_reg <= 1'b0;
    if (!(loc_in_axis_tready && loc_in_axis_tvalid)) begin
      last_flag_reg <= loc_in_axis_tlast;
    end
    if (rst) begin
      last_flag_reg <= 1'b0;
    end
  end

  loc_axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
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
  ) out_axis_register_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(loc_in_axis_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(loc_in_axis_tvalid),
    .s_axis_tready(loc_in_axis_tready),
    .s_axis_tlast(loc_in_axis_tlast),
    .s_axis_tid(1'b0),
    .s_axis_tdest(1'b0),
    .s_axis_tuser(1'b0),
    .m_axis_tdata(loc_out_axis_tdata),
    .m_axis_tvalid(loc_out_axis_tvalid),
    .m_axis_tready(loc_out_axis_tready),
    .m_axis_tlast(loc_out_axis_tlast),
  );

  // Intra-Iteration Counter
  reg  [ITER_WIDTH-1:0] intra_counter_reg, intra_counter_reg_next;
  reg  forward_reg;

  wire [ITER_WIDTH-1:0] intra_counter_reg_next = intra_counter_reg + 1;
  wire forward_reg_next = (intra_counter_reg_next == intra_counter_max);

  always @(posedge clk ) begin
    if (rst) begin
      forward_reg <= 1'b0;
      intra_counter_reg <= $unsigned(1);
    end else begin
      if (loc_out_axis_tvalid && m_axis_data_tready) begin
        intra_counter_reg <= (intra_counter_reg_next == intra_counter_max) ? $unsigned(1) : intra_counter_reg_next;
        forward_reg <= forward_reg_next;
      end
    end
  end
  
  // Output AXI_Stream Drivers
  assign m_axis_data_tdata   = loc_out_axis_tdata;
  assign m_axis_data_tvalid  = loc_out_axis_tvalid;
  assign loc_out_axis_tready = m_axis_data_tready && forward_reg;
  assign m_axis_data_tlast   = loc_out_axis_tlast && forward_reg;

  assign tlast_transmitted   = loc_out_axis_tlast && loc_out_axis_tready && loc_out_axis_tvalid;

endmodule

`resetall
