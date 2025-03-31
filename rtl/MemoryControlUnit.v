`resetall
`timescale 1ns/1ps
`default_nettype none

module MemoryControlUnit #(
  `include "MCUGlobalFSMparameters.vh"
  // Number of batches per run
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH_RSLT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = ((DATA_WIDTH_RSLT+7)/8),
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = 8,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = 8,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = 1,
  // Number of Independent AXI-Stream Data Channels per Batch
  parameter DATA_CHANNELS = 1,
  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Use Common Share Channel 
  parameter SHARE_SCALE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_DATA = 32,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_GRID = 32,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_SCALE = 32,
  // BRAM control has valid signal
  parameter BRAM_VALID_SIG = 1
) (
  input  wire                                                     bram_clk,
  input  wire                                                     m_axis_aclk,
  input  wire                                                     rst,

  /*
   * Data BRAM Control Interface
   */
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_en;
  // output wire [BATCH_SIZE*DATA_CHANNELS*WE-1:0]                   data_bram_we;  // Read Only Operations allowed
  output wire [BATCH_SIZE*DATA_CHANNELS*ADDR_WIDTH_DATA-1:0]      data_bram_addr;
  // input  wire [BATCH_SIZE*DATA_CHANNELS*WIDTH-1:0]                data_bram_wrdata;
  input  wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      data_bram_rddata,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_rdvalid,  // Ignore if BRAM_VALID_SIG == 0

  /*
   * AXI Stream Data Output
   */
  output wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      m_axis_data_tdata,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tvalid,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tready,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tlast,
  output wire [BATCH_SIZE*DATA_CHANNELS*ID_WIDTH-1:0]             m_axis_data_tid,
  output wire [BATCH_SIZE*DATA_CHANNELS*DEST_WIDTH-1:0]           m_axis_data_tdest,
  output wire [BATCH_SIZE*DATA_CHANNELS*USER_WIDTH-1:0]           m_axis_data_tuser,

  /*
   * Grid BRAM Control Interface
   */
  output wire                                                     grid_bram_en,
  // output wire [WE-1:0]                                            grid_bram_we,  // Read Only Operations allowed
  output wire [ADDR_WIDTH_GRID-1:0]                               grid_bram_addr,
  // input  wire [WIDTH-1:0]                                         grid_bram_wrdata,
  input  wire [DATA_WIDTH_DATA-1:0]                               grid_bram_rddata,
  input  wire                                                     grid_bram_rdvalid,  // Ignore if BRAM_VALID_SIG == 0

  /*
   * AXI Stream Grid Output
   */
  output wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      m_axis_grid_tdata,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_grid_tvalid,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_grid_tready,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_grid_tlast,
  output wire [BATCH_SIZE*DATA_CHANNELS*ID_WIDTH-1:0]             m_axis_grid_tid,
  output wire [BATCH_SIZE*DATA_CHANNELS*DEST_WIDTH-1:0]           m_axis_grid_tdest,
  output wire [BATCH_SIZE*DATA_CHANNELS*USER_WIDTH-1:0]           m_axis_grid_tuser,

  /*
   * Scale BRAM Control Interface -- Available only when SHARE_SCALE == 0
   */
  output wire [DATA_CHANNELS-1:0]                                 scle_bram_en,
  // output wire [DATA_CHANNELS*WE-1:0]                              scle_bram_we,  // Read Only Operations allowed
  output wire [DATA_CHANNELS*ADDR_WIDTH_SCALE-1:0]                scle_bram_addr,
  // input  wire [DATA_CHANNELS*WIDTH-1:0]                           scle_bram_wrdata,
  input  wire [DATA_CHANNELS*DATA_WIDTH_SCALE-1:0]                scle_bram_rddata,
  input  wire [DATA_CHANNELS-1:0]                                 scle_bram_rdvalid,  // Ignore if BRAM_VALID_SIG == 0

  /*
   * Scale AXI lite Master Interface -- Available only when SHARE_SCALE == 1
   */
  output wire [ADDR_WIDTH_SCALE-1:0]                              m_axil_scle_araddr,
  output wire [2:0]                                               m_axil_scle_arprot,
  output wire                                                     m_axil_scle_arvalid,
  input  wire                                                     m_axil_scle_arready,
  input  wire [DATA_WIDTH_SCALE-1:0]                              m_axil_scle_rdata,
  input  wire [1:0]                                               m_axil_scle_rresp,
  input  wire                                                     m_axil_scle_rvalid,
  output wire                                                     m_axil_scle_rready,
  
  /*
   * AXI Stream Scale Output
   */
  output wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]               m_axis_scle_tdata,
  output wire [SCALE_CHANNELS-1:0]                                m_axis_scle_tvalid,
  input  wire [SCALE_CHANNELS-1:0]                                m_axis_scle_tready,
  output wire [SCALE_CHANNELS-1:0]                                m_axis_scle_tlast,
  output wire [SCALE_CHANNELS*ID_WIDTH-1:0]                       m_axis_scle_tid,
  output wire [SCALE_CHANNELS*DEST_WIDTH-1:0]                     m_axis_scle_tdest,
  output wire [SCALE_CHANNELS*USER_WIDTH-1:0]                     m_axis_scle_tuser,

  /*
   * Control signals
   */
  input  wire operation_start,
  input  wire [ADDR_WIDTH_DATA-1:0]  data_size,
  input  wire [ADDR_WIDTH_GRID-1:0]  grid_size,
  input  wire [ADDR_WIDTH_SCALE-1:0] scle_size,
  
  /*
   * Interrupt signals
   */
  output reg operation_in_progress,
  output reg operation_complete,
  output reg operation_error

);
  // Control Registers & Wires
  reg  op_in_progress_reg = 1'b0;
  reg  [ADDR_WIDTH_DATA-1:0]  data_size_reg;
  reg  [ADDR_WIDTH_GRID-1:0]  grid_size_reg;
  reg  [ADDR_WIDTH_SCALE-1:0] scle_size_reg;

  // Local FSM output signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_tlast_transmitted;
  wire                                grid_tlast_transmitted;
  wire [SCALE_CHANNELS-1:0]           scle_tlast_transmitted;

  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_error;
  wire                                grid_error;
  wire [SCALE_CHANNELS-1:0]           scle_error;

  // Global FSM input signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_op_done_reg_next = data_op_done_reg | data_tlast_transmitted;
  wire                                grid_op_done_reg_next = grid_op_done_reg | grid_tlast_transmitted;
  wire [SCALE_CHANNELS-1:0]           scle_op_done_reg_next = scle_op_done_reg | scle_tlast_transmitted;

  // wire data_op_done_reduced = &data_op_done_reg_next;
  // wire grid_op_done_reduced =  grid_op_done_reg_next;
  // wire scle_op_done_reduced = &scle_op_done_reg_next;
  // wire op_done              =  data_op_done_reduced && grid_op_done_reduced && scle_op_done_reduced;
  wire op_done              =  &{data_op_done, grid_op_done, scle_op_done};
  
  // wire data_error_reduced   = |data_error;
  // wire grid_error_reduced   =  grid_error;
  // wire scle_error_reduced   = |scle_error;
  // wire internal_error       = data_error_reduced || grid_error_reduced || scle_error_reduced;
  wire internal_error       = |{data_error, grid_error, scle_error};

  // Global FSM output signals
  reg  [GLO_FSM_WIDTH-1:0] glo_fsm_state, glo_fsm_state_next;
  reg  [BATCH_SIZE*DATA_CHANNELS-1:0] data_op_done_reg;
  reg                                 grid_op_done_reg;
  reg  [SCALE_CHANNELS-1:0]           scle_op_done_reg;

  // Global FSM state logic
  always @(posedge clk ) begin
    if (rst) begin
      glo_fsm_state <= GLO_FSM_ST0;

      data_op_done_reg <= {(BATCH_SIZE*DATA_CHANNELS){1'b0}};
      grid_op_done_reg <= 1'b0;

    end else begin
      glo_fsm_state <= glo_fsm_state_next;

      data_op_done_reg <= {(BATCH_SIZE*DATA_CHANNELS){1'b0}};
      grid_op_done_reg <= 1'b0;
      scle_op_done_reg <= {SCALE_CHANNELS{1'b0}};

      operation_in_progress <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

      case (glo_fsm_state_next)
        GLO_FSM_ST0: begin

        end
        GLO_FSM_STR: begin
          operation_in_progress <= 1'b1;

        end
        GLO_FSM_OPE: begin
          data_op_done_reg <= data_op_done_reg_next;
          grid_op_done_reg <= grid_op_done_reg_next;
          scle_op_done_reg <= scle_op_done_reg_next;

          operation_in_progress <= 1'b1;

        end
        GLO_FSM_END: begin
          operation_complete <= 1'b1;
          
        end
        GLO_FSM_ERR: begin
          operation_error <= 1'b1;

        end
        default: begin
          
        end 
      endcase
    end
  end

  `define GLO_CHECK_OP_START \
    if (operation_start) begin \
      glo_fsm_state_next <= GLO_FSM_STR; \
      if (data_size[ADDR_WIDTH_DATA] && (|data_size[ADDR_WIDTH_DATA-1:0])) begin
        glo_fsm_state_next <= GLO_FSM_ERR; \
      end else begin \
        data_size_reg <= data_size; \
      end \
      if (grid_size[ADDR_WIDTH_DATA] && (|grid_size[ADDR_WIDTH_DATA-1:0])) begin
        glo_fsm_state_next <= GLO_FSM_ERR; \
      end else begin \
        grid_size_reg <= grid_size; \
      end \
      if (SCALE_CHANNELS == 0) begin \
        if (scle_size[ADDR_WIDTH_DATA] && (|scle_size[ADDR_WIDTH_DATA-1:0])) begin
          glo_fsm_state_next <= GLO_FSM_ERR; \
        end else begin \
          scle_size_reg <= scle_size; \
        end \
      end \
    end else begin \
      glo_fsm_state_next <= GLO_FSM_ST0; \
    end 

  // Global FSM next state logic
  always @(*) begin
    case (glo_fsm_state)
      GLO_FSM_ST0: begin
        `GLO_CHECK_OP_START
      end
      GLO_FSM_STR: begin

      end
      GLO_FSM_OPE: begin

      end
      GLO_FSM_END: begin
        if (op_done) begin
          `GLO_CHECK_OP_START
        end
      end
      GLO_FSM_ERR: begin
        glo_fsm_state_next <= GLO_FSM_ST0;
        
      end
      default: begin
        glo_fsm_state_next <= glo_fsm_state;
        
      end 
    endcase
    if (internal_error) begin
      glo_fsm_state_next <= GLO_FSM_ERR;
    end
    if (rst) begin
      glo_fsm_state_next <= GLO_FSM_ST0;
    end
  end

  genvar pos;

 generate
  for (pos = 0; pos < BATCH_SIZE*DATA_CHANNELS; pos = pos + 1) begin
    if (SHARE_SCALE == 0) begin
      // Local FIFO I/O
      wire [DATA_WIDTH_DATA-1:0]  scle_fifo_in_axis_tdata,  scle_fifo_out_axis_tdata;
      wire                        scle_fifo_in_axis_tvalid, scle_fifo_out_axis_tvalid;
      wire                        scle_fifo_in_axis_tready, scle_fifo_out_axis_tready;
      wire                        scle_fifo_in_axis_tlast,  scle_fifo_out_axis_tlast;

      MCULocalFSM #(
        `include "MCUGlobalFSMparametersInst.vh"
        // Width of AXI stream Output interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_SCALE),
        // Width of address bus in bits
        .ADDR_WIDTH(ADDR_WIDTH_SCALE),
        // Width of iteration counters
        .ITER_WIDTH(ITER_WIDTH),
        // BRAM control has valid signal
        .BRAM_VALID_SIG(BRAM_VALID_SIG)
      ) (
        .clk(clk),
        .rst(rst),
        .bram_en(scle_bram_en[pos]),
        // .bram_we(bram_we),  // Read Only Operations allowed
        .bram_addr(scle_bram_addr[pos*ADDR_WIDTH_SCALE +: ADDR_WIDTH_SCALE]),
        // .bram_wrdata(bram_wrdata),
        .bram_rddata(scle_bram_rddata[pos*ADDR_WIDTH_SCALE +: ADDR_WIDTH_SCALE]),
        .bram_rdvalid(scle_bram_rdvalid[pos]),
        .m_axis_data_tdata(scle_fifo_in_axis_tdata),
        .m_axis_data_tvalid(scle_fifo_in_axis_tvalid),
        .m_axis_data_tready(scle_fifo_in_axis_tready),
        .m_axis_data_tlast(scle_fifo_in_axis_tlast),
        .glo_fsm_state(glo_fsm_state),
        .addr_counter_max(scle_size_reg),
        .inter_counter_max(1),
        .intra_counter_max(1),
        .tlast_transmitted(tlast_transmitted),
        .error(error)
      );
      axis_srl_fifo #(
        // Width of AXI stream interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_SCALE),
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
        // FIFO depth in cycles
        .DEPTH(8)
      ) axis_fifo_scle_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(scle_fifo_in_axis_tdata),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(scle_fifo_in_axis_tvalid),
        .s_axis_tready(scle_fifo_in_axis_tready),
        .s_axis_tlast(scle_fifo_in_axis_tlast),
        .s_axis_tid(1'b0),
        .s_axis_tdest(1'b0),
        .s_axis_tuser(1'b0),
        .m_axis_tdata(scle_fifo_out_axis_tdata),
        .m_axis_tvalid(scle_fifo_out_axis_tvalid),
        .m_axis_tready(scle_fifo_out_axis_tready),
        .m_axis_tlast(scle_fifo_out_axis_tlast),
      );
    
      
    end
  end
 endgenerate
    
endmodule

`resetall
