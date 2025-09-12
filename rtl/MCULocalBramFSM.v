`resetall
`timescale 1ns/1ps
`default_nettype none

module MCULocalBramFSM #(
  `include "header_MCUGlobalFSMParameters.vh"

 `ifdef DEBUG
  parameter DEBUG_WIRE_LENGTH = 3,
 `endif 

  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 16,
  // Data Strobe Width
  parameter DATA_STRB_WIDTH = DATA_WIDTH / 8,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of inter-iteration counters
  parameter INTER_ITER_WIDTH = 32,
  // Width of intra-iteration counters
  parameter INTRA_ITER_WIDTH = 32,
  // BRAM control has valid signal
  parameter BRAM_ACK_SIG = 1
) (
  input  wire                        clk,
  input  wire                        rst,
 
 `ifdef DEBUG
  output wire [DEBUG_WIRE_LENGTH-1:0]                               debug_wire,
 `endif
  
  /* 
   * Data BRAM Control Interface 
   */ 
  output wire                        bram_en,
  // output wire [WE-1:0]               bram_we,  // Read Only Operations allowed
  output wire [ADDR_WIDTH-1:0]       bram_addr,
  // input  wire [DATA_WIDTH-1:0]       bram_wrdata,
  input  wire [DATA_WIDTH-1:0]       bram_rddata,
  input  wire                        bram_rdack,  // Ignore if BRAM_ACK_SIG == 0
 
  /* 
   * AXI Stream Data Output 
   */ 
  output wire [DATA_WIDTH-1:0]       m_axis_tdata,
  output wire                        m_axis_tvalid,
  input  wire                        m_axis_tready,
  output wire                        m_axis_tlast,
  
  /*
   * Local FSM input signals -- Controlled by Global FSM
   */
  input  wire [GLO_FSM_WIDTH-1:0]    glo_fsm_state,
  input  wire [ADDR_WIDTH:0]         addr_counter_max,
  input  wire [INTER_ITER_WIDTH-1:0] inter_counter_max,
  input  wire [INTRA_ITER_WIDTH-1:0] intra_counter_max,
 
  /* 
   * Local FSM output signals 
   */ 
  output wire                        tlast_transmitted,
  output wire                        error
);
  // Local FSM states
`ifdef USE_ONE_HOT_ENCODING_FSM
  localparam LOC_FSM_WIDTH = 4;
  localparam LOC_FSM_STR = 2 ** 0;
  localparam LOC_FSM_OPE = 2 ** 1;
  localparam LOC_FSM_ERR = 2 ** 2;
  localparam LOC_FSM_END = 2 ** 3;
`else
  localparam LOC_FSM_WIDTH = 2;
  localparam LOC_FSM_STR = 0;
  localparam LOC_FSM_OPE = 1;
  localparam LOC_FSM_ERR = 2;
  localparam LOC_FSM_END = 3;
`endif 

  // Input signals
  wire bram_rdack_int;

  generate
    if (BRAM_ACK_SIG > 0) begin
      assign bram_rdack_int = bram_rdack;
    end else begin
      assign bram_rdack_int = 1'b1;
    end
  endgenerate

  // Local Register I/O Registers & Wires
  wire [DATA_WIDTH-1:0] loc_in_axis_tdata,  loc_out_axis_tdata;
  wire                  loc_in_axis_tvalid, loc_out_axis_tvalid;
  wire                  loc_in_axis_tready, loc_out_axis_tready;
  wire                  loc_in_axis_tlast,  loc_out_axis_tlast;

  // Intra-Iteration Counter Registers & Wires
  wire get_next_intra_iter = loc_out_axis_tvalid && m_axis_tready;
  reg  [INTRA_ITER_WIDTH-1:0] intra_counter_reg;
  wire [INTRA_ITER_WIDTH-1:0] intra_counter_reg_next = intra_counter_reg + 1;
  // wire forward_reg_next = get_next_intra_iter && (~|(intra_counter_reg ^ intra_counter_max_reg) );
  wire forward_reg_next = get_next_intra_iter && ( (intra_counter_reg == intra_counter_max_reg) );

  // Local FSM Output Registers & Wires
  reg [LOC_FSM_WIDTH-1:0]     loc_fsm_state, loc_fsm_state_next;
  reg [ADDR_WIDTH-1:0]        loc_counter_addr_reg;
  reg [INTER_ITER_WIDTH-1:0]  inter_counter_reg; // Inter-Iteration Counter
  reg                         bram_en_reg, store_data_reg;
  reg                         tlast_transmitted_reg;
  reg                         get_next_inter_iter;
  reg                         error_reg;

  reg [ADDR_WIDTH-1:0]        addr_counter_max_reg  = 0;
  reg [INTER_ITER_WIDTH-1:0]  inter_counter_max_reg = 0;
  reg [INTRA_ITER_WIDTH-1:0]  intra_counter_max_reg = 0;

  assign bram_en    = (loc_fsm_state == LOC_FSM_OPE) ? bram_en_reg || (m_axis_tready && forward_reg_next) : 1'b0;
  // assign bram_en    = (loc_fsm_state == LOC_FSM_OPE) ? bram_en_reg || loc_out_axis_tready : 1'b0;
  assign bram_addr  = loc_counter_addr_reg;
  // assign store_data = store_data_reg;

  assign loc_in_axis_tdata  = bram_rddata;
  assign loc_in_axis_tvalid = bram_rdack_int;
  assign loc_in_axis_tlast  = loc_fsm_state == LOC_FSM_END;

  // Local FSM Input Registers & Wires
  wire                        get_next_addr              = bram_en; // loc_in_axis_tvalid && loc_in_axis_tready;
  wire [ADDR_WIDTH:0]         loc_counter_addr_reg_next  = (get_next_addr) ? loc_counter_addr_reg + 1 : loc_counter_addr_reg;
  wire [INTER_ITER_WIDTH-1:0] inter_counter_reg_next     = (get_next_inter_iter) ? inter_counter_reg + 1 : inter_counter_reg; // Inter-Iteration Counter
  // wire                        internal_error             = 1'b0;
  wire                        tlast_transmitted_reg_next = tlast_transmitted_reg || (loc_out_axis_tlast && loc_out_axis_tready && loc_out_axis_tvalid);

 `ifdef DEBUG
  assign debug_wire = {DEBUG_WIRE_LENGTH{glo_fsm_state == GLO_FSM_STR}} & {
    addr_counter_max == 0,
    inter_counter_max == 0,
    intra_counter_max == 0};
 `endif

  // Local FSM state logic
  always @(posedge clk ) begin
    if (rst) begin 
      loc_fsm_state <= LOC_FSM_STR;

      loc_counter_addr_reg  <= $unsigned(0);
      inter_counter_reg     <= $unsigned(0);
      store_data_reg        <= 1'b0;
      error_reg             <= 1'b0;
      bram_en_reg           <= 1'b0;
      tlast_transmitted_reg <= 1'b0;

      addr_counter_max_reg  <= 0;
      inter_counter_max_reg <= 0;
      intra_counter_max_reg <= 0;

    end else begin
      loc_fsm_state        <= loc_fsm_state_next;
      loc_counter_addr_reg <= loc_counter_addr_reg;
      inter_counter_reg    <= inter_counter_reg;
      store_data_reg       <= 1'b0;
      error_reg            <= 1'b0;
      bram_en_reg          <= 1'b0;
      tlast_transmitted_reg<= 1'b0;

      case (loc_fsm_state_next)
        LOC_FSM_STR: begin
          loc_counter_addr_reg <= $unsigned(0);
          inter_counter_reg    <= $unsigned(0);
        end
        LOC_FSM_OPE: begin
          if (loc_fsm_state == LOC_FSM_STR) begin
            addr_counter_max_reg  <= addr_counter_max -1;
            inter_counter_max_reg <= inter_counter_max-1;
            intra_counter_max_reg <= intra_counter_max-1;
          end

          store_data_reg       <= 1'b1;
          bram_en_reg          <= (loc_fsm_state != LOC_FSM_OPE);
          loc_counter_addr_reg <= loc_counter_addr_reg_next;
          inter_counter_reg    <= inter_counter_reg_next;

          if (get_next_inter_iter && bram_en) begin
            loc_counter_addr_reg <= $unsigned(0);
          end

        end
        LOC_FSM_END: begin
          store_data_reg <= 1'b1;
          tlast_transmitted_reg <= tlast_transmitted_reg_next;
          
        end
        LOC_FSM_ERR: begin
          error_reg <= 1'b1;
        end
        default: begin
        end
      endcase
    end
  end
  
  // Local Scale FSM next state logic
  always @(*) begin
    get_next_inter_iter <= 1'b0;
    loc_fsm_state_next <= loc_fsm_state;
    case (loc_fsm_state)
      LOC_FSM_STR: begin
        if (glo_fsm_state == GLO_FSM_STR) begin 
          loc_fsm_state_next <= LOC_FSM_OPE; 
        end else begin 
          loc_fsm_state_next <= LOC_FSM_STR; 
        end 
      end
      LOC_FSM_OPE: begin
        loc_fsm_state_next <= LOC_FSM_OPE;
        if (get_next_addr && loc_counter_addr_reg == addr_counter_max_reg) begin
          get_next_inter_iter <= 1'b1;
          if (inter_counter_reg == inter_counter_max_reg) begin
            loc_fsm_state_next <= LOC_FSM_END;
          end
        end
      end
      LOC_FSM_END: begin
        if (glo_fsm_state == GLO_FSM_END) begin
          loc_fsm_state_next <= LOC_FSM_STR;
        end
      end
      LOC_FSM_ERR: begin
        if (glo_fsm_state == GLO_FSM_ERR) begin
          loc_fsm_state_next <= LOC_FSM_STR;
        end else begin
          loc_fsm_state_next <= LOC_FSM_ERR;
        end
      end
      default: begin
        loc_fsm_state_next <= LOC_FSM_STR;
        
      end 
    endcase
    // if (internal_error) begin
    //   loc_fsm_state_next <= LOC_FSM_ERR;
    // end
    if (rst) begin
      loc_fsm_state_next <= LOC_FSM_STR;
      get_next_inter_iter <= 1'b0;
    end
  end 

  axis_register #(
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
    .clk              (clk),
    .rst              (rst || (loc_fsm_state == LOC_FSM_ERR)),
    .s_axis_tdata     (loc_in_axis_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (loc_in_axis_tvalid),
    .s_axis_tready    (loc_in_axis_tready),
    .s_axis_tlast     (loc_in_axis_tlast),
    .s_axis_tid       (1'b0),
    .s_axis_tdest     (1'b0),
    .s_axis_tuser     (1'b0),
    .m_axis_tdata     (loc_out_axis_tdata),
    .m_axis_tvalid    (loc_out_axis_tvalid),
    .m_axis_tready    (loc_out_axis_tready),
    .m_axis_tlast     (loc_out_axis_tlast)
  );

  // Intra-Iteration Counter

  always @(posedge clk ) begin
    if (rst) begin
      // forward_reg <= 1'b0;
      intra_counter_reg <= $unsigned(0);
    end else begin
      // forward_reg <= forward_reg_next;
      if (get_next_intra_iter) begin
        intra_counter_reg <= forward_reg_next ? $unsigned(0) : intra_counter_reg_next;
      end
    end
  end
  
  // Output AXI_Stream Drivers
  assign m_axis_tdata   = loc_out_axis_tdata;
  assign m_axis_tvalid  = loc_out_axis_tvalid;
  assign loc_out_axis_tready = m_axis_tready && forward_reg_next;
  assign m_axis_tlast   = loc_out_axis_tlast && forward_reg_next;

  // Local FSM output signals
  assign tlast_transmitted = tlast_transmitted_reg;
  assign error = error_reg;

endmodule

`resetall
