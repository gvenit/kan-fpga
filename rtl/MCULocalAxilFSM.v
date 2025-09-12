`resetall
`timescale 1ns/1ps
`default_nettype none

module MCULocalAxilFSM #(
  `include "header_MCUGlobalFSMParameters.vh"
  // Width of AXI stream Output interfaces in bits
  parameter DATA_WIDTH = 16,
  // Data Strobe Width
  parameter DATA_STRB_WIDTH = DATA_WIDTH / 8,
  // Width of address bus in bits
  parameter ADDR_WIDTH = 32,
  // Width of inter-iteration counters
  parameter INTER_ITER_WIDTH = 32,
  // Width of intra-iteration counters
  parameter INTRA_ITER_WIDTH = 32
) (
  input  wire                         clk,
  input  wire                         rst,

  /*
   * Data Axi-Lite Interface
   */
  output wire [ADDR_WIDTH-1:0]        m_axil_araddr,
  output wire [2:0]                   m_axil_arprot,
  output wire                         m_axil_arvalid,
  input  wire                         m_axil_arready,
  input  wire [DATA_WIDTH-1:0]        m_axil_rdata,
  input  wire [1:0]                   m_axil_rresp,
  input  wire                         m_axil_rvalid,
  output wire                         m_axil_rready,

  /*
   * AXI Stream Data Output
   */
  output wire [DATA_WIDTH-1:0]        m_axis_tdata,
  output wire                         m_axis_tvalid,
  input  wire                         m_axis_tready,
  output wire                         m_axis_tlast,
  
  /*
   * Local FSM input signals -- Controlled by Global FSM
   */
  input  wire [GLO_FSM_WIDTH-1:0]     glo_fsm_state,
  input  wire [ADDR_WIDTH:0]          addr_counter_max,
  input  wire [INTER_ITER_WIDTH-1:0]  inter_counter_max,
  input  wire [INTRA_ITER_WIDTH-1:0]  intra_counter_max,

  /*
   * Local FSM output signals
   */
  output wire                         tlast_transmitted,
  output wire                         error
);
  // Axi-Lite FIFO wires
  wire [ADDR_WIDTH-1:0] int_axil_araddr;
  wire [2:0]            int_axil_arprot;
  wire                  int_axil_arvalid;
  wire                  int_axil_arready;
  wire [DATA_WIDTH-1:0] int_axil_rdata;
  wire [1:0]            int_axil_rresp;
  wire                  int_axil_rvalid;
  wire                  int_axil_rready;

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

  // Local Register I/O Registers & Wires
  wire [DATA_WIDTH-1:0] loc_in_axis_tdata,  loc_out_axis_tdata;
  wire                  loc_in_axis_tvalid, loc_out_axis_tvalid;
  wire                  loc_in_axis_tready, loc_out_axis_tready;
  wire                  loc_in_axis_tlast,  loc_out_axis_tlast;

  // Local FSM Output Registers & Wires
  reg  [LOC_FSM_WIDTH-1:0]    loc_fsm_state, loc_fsm_state_next;
  reg  [ADDR_WIDTH-1:0]       loc_counter_addr_reg;
  reg  [INTER_ITER_WIDTH-1:0] addr_inter_counter_reg; // Inter-Iteration Counter
  reg                         addr_en, tlast_transmitted_reg;
  reg                         get_next_iter;
  reg                         error_reg;

  // Local FSM Input Registers & Wires
  wire [ADDR_WIDTH:0]         loc_counter_addr_reg_next = (get_next_addr) ? loc_counter_addr_reg + 1 : loc_counter_addr_reg;
  wire [INTER_ITER_WIDTH-1:0] addr_inter_counter_reg_next = (get_next_iter) ? addr_inter_counter_reg + 1 : addr_inter_counter_reg; // Inter-Iteration Counter
  
  wire internal_error = int_axil_rready && int_axil_rvalid && int_axil_rresp != 2'b00; // Error reading on AXI-Lite slave side

  wire get_next_addr = int_axil_arready && int_axil_arvalid;
  
  `define LOC_CHECK_OP_START(operation_start, loc_fsm_state_next, addr_counter_max, inter_counter_max)\
    if (operation_start) begin \
      if(addr_counter_max == 0 || inter_counter_max == 0) begin \
        loc_fsm_state_next <= LOC_FSM_ERR; \
      end else begin \
        loc_fsm_state_next <= LOC_FSM_OPE; \
      end \
    end else begin \
      loc_fsm_state_next <= LOC_FSM_STR; \
    end 

  // Local FSM state logic
  always @(posedge clk ) begin
    if (rst) begin 
      loc_fsm_state <= LOC_FSM_STR;
      loc_counter_addr_reg <= $unsigned(0);
      addr_inter_counter_reg <= $unsigned(0);
      tlast_transmitted_reg <= 1'b0;

    end else begin
      loc_fsm_state   <= loc_fsm_state_next;
      loc_counter_addr_reg <= $unsigned(0);
      addr_inter_counter_reg <= $unsigned(0);
      tlast_transmitted_reg <= 1'b0;
      error_reg <= 1'b0;

      case (loc_fsm_state_next)
        LOC_FSM_OPE: begin
          if (get_next_iter) begin
            loc_counter_addr_reg <= $unsigned(0);
          end else begin
            loc_counter_addr_reg <= loc_counter_addr_reg_next;
          end
          addr_inter_counter_reg <= addr_inter_counter_reg_next;
        end
        LOC_FSM_END: begin
          tlast_transmitted_reg <= tlast_transmitted;
          
        end
        LOC_FSM_ERR: begin
          error_reg <= 1'b1;
        end
        default: begin
        end
      endcase
    end
  end
  
  // Local FSM next state logic
  always @(*) begin
    get_next_iter <= 1'b0;
    addr_en <= 1'b0;
    case (loc_fsm_state)
      LOC_FSM_STR: begin
        `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, loc_fsm_state_next, addr_counter_max, inter_counter_max)
      end
      LOC_FSM_OPE: begin
        addr_en <= 1'b1;
        loc_fsm_state_next <= LOC_FSM_OPE;
        if (loc_counter_addr_reg_next == addr_counter_max) begin
          get_next_iter <= 1'b1;
          if (addr_inter_counter_reg_next == inter_counter_max) begin
            loc_fsm_state_next <= LOC_FSM_END;
          end
        end
      end
      LOC_FSM_END: begin
        if (glo_fsm_state == GLO_FSM_END) begin
          loc_fsm_state_next <= LOC_FSM_STR;
        end
        // if (tlast_transmitted) begin
        //   `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, loc_fsm_state_next, addr_counter_max, inter_counter_max)
        // end
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
    if (internal_error) begin
      loc_fsm_state_next <= LOC_FSM_ERR;
    end
    if (rst) begin
      loc_fsm_state_next <= LOC_FSM_STR;
      addr_en <= 1'b0;
    end
  end 

  // Input data counter
  reg  [ADDR_WIDTH-1:0]       loc_counter_data_reg;
  wire [ADDR_WIDTH:0]         loc_counter_data_reg_next = loc_counter_data_reg + 1;

  reg  [INTER_ITER_WIDTH-1:0] data_inter_counter_reg; // Inter-Iteration Counter
  wire [INTER_ITER_WIDTH:0]   data_inter_counter_reg_next = data_inter_counter_reg + 1;

  wire incr_iter = (loc_counter_data_reg_next == addr_counter_max);
  wire last_flag = incr_iter && ( data_inter_counter_reg_next == inter_counter_max );

  // Last flag logic
  always @(posedge clk ) begin
    if (rst) begin
      loc_counter_data_reg <= $unsigned(0);
      data_inter_counter_reg <= $unsigned(0);
    end else begin
      case (loc_fsm_state_next)
        LOC_FSM_STR: begin
          loc_counter_data_reg <= $unsigned(0);
          data_inter_counter_reg <= $unsigned(0);
        end
        LOC_FSM_ERR:begin
          loc_counter_data_reg <= $unsigned(0);
          data_inter_counter_reg <= $unsigned(0);
        end
        default: begin
          if (loc_in_axis_tready && loc_in_axis_tvalid && int_axil_rresp == 2'b00) begin
            loc_counter_data_reg <= loc_counter_data_reg_next[ADDR_WIDTH-1:0];
            if (incr_iter) begin
              loc_counter_data_reg <= $unsigned(0);
              data_inter_counter_reg <= data_inter_counter_reg_next;
            end
          end
        end
      endcase
    end
  end

  assign loc_in_axis_tdata  = int_axil_rdata;
  assign loc_in_axis_tvalid = int_axil_rvalid;
  assign loc_in_axis_tlast  = last_flag;
  assign int_axil_rready = loc_in_axis_tready;

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
  ) loc_axis_register_inst (
    .clk              (clk),
    .rst              (rst),
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
  reg  [INTRA_ITER_WIDTH-1:0] intra_counter_reg;
  // reg  forward_reg;

  wire [INTRA_ITER_WIDTH-1:0] intra_counter_reg_next = intra_counter_reg + 1;
  wire forward_reg_next = (intra_counter_reg_next == intra_counter_max) ;

  always @(posedge clk ) begin
    if (rst) begin
      // forward_reg <= 1'b0;
      intra_counter_reg <= $unsigned(0);
    end else begin
      // forward_reg <= forward_reg_next;
      if (loc_out_axis_tvalid && m_axis_tready) begin
        intra_counter_reg <= forward_reg_next ? $unsigned(0) : intra_counter_reg_next;
      end
    end
  end
  
axil_fifo_rd # (
  // Width of data bus in bits
  .DATA_WIDTH(DATA_WIDTH),
  // Width of address bus in bits
  .ADDR_WIDTH(ADDR_WIDTH),
  // Read data FIFO depth (cycles)
  .FIFO_DEPTH(2),
  // Hold read address until space available in FIFO for data, if possible
  .FIFO_DELAY(0)
) axil_fifo_rd_inst (
  .clk             (clk),
  .rst             (rst),
  .s_axil_araddr   (int_axil_araddr << `RLOG2( DATA_STRB_WIDTH )),
  .s_axil_arprot   (int_axil_arprot),
  .s_axil_arvalid  (int_axil_arvalid),
  .s_axil_arready  (int_axil_arready),
  .s_axil_rdata    (int_axil_rdata),
  .s_axil_rresp    (int_axil_rresp),
  .s_axil_rvalid   (int_axil_rvalid),
  .s_axil_rready   (int_axil_rready),
  .m_axil_araddr   (m_axil_araddr),
  .m_axil_arprot   (m_axil_arprot),
  .m_axil_arvalid  (m_axil_arvalid),
  .m_axil_arready  (m_axil_arready),
  .m_axil_rdata    (m_axil_rdata),
  .m_axil_rresp    (m_axil_rresp),
  .m_axil_rvalid   (m_axil_rvalid),
  .m_axil_rready   (m_axil_rready)
);

  // Output AXI_Stream Drivers
  assign m_axis_tdata         = loc_out_axis_tdata;
  assign m_axis_tvalid        = loc_out_axis_tvalid;
  assign loc_out_axis_tready  = m_axis_tready && forward_reg_next;
  assign m_axis_tlast         = loc_out_axis_tlast && forward_reg_next;

  // Output AXI-Lite Drivers
  assign int_axil_araddr  = loc_counter_addr_reg;
  assign int_axil_arprot  = 3'b000;
  assign int_axil_arvalid = addr_en;

  // Output Control Drivers
  assign error = error_reg;
  assign tlast_transmitted = tlast_transmitted_reg | (loc_out_axis_tlast && loc_out_axis_tready && loc_out_axis_tvalid);

`undef LOC_CHECK_OP_START
endmodule

`resetall
