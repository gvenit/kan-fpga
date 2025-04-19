`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * MemoryControlUnit : A Memory Controller that coordinates
 *      the streaming processes for all data, grid and scale 
 *      streams for the data processor.
 * 
 *    The module consists of a global FSM and one local FSM
 *      per output stream. Each FSM may operate with different
 *      clock drivers. The global FSM is expected to work with
 *      the slowest clock of the module.
 * 
 */

//`include "rtl/IFOptions.vh"
`include "IFOptions.vh"

module MemoryControlUnit #(
  `include "rtl/MCUGlobalFSMParameters.vh"
  `ifdef BRAM_ACK_SIG_OPTION
    // BRAM control has ack signal
    parameter BRAM_ACK_SIG = 1,
  `endif 
  // Number of batches per run
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
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
  parameter USER_WIDTH = 1,
  // Number of Independent AXI-Stream Data Channels per Batch
  parameter DATA_CHANNELS = 1,
  // Use Common Share Channel 
  parameter SHARE_SCALE = 1,
  // Input Scale Channels
  parameter SCALE_CHANNELS_IN = (SHARE_SCALE)? 1 : DATA_CHANNELS,
  // Output Scale Channels
  parameter SCALE_CHANNELS_OUT = (SHARE_SCALE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Use Common Grid Channel 
  parameter SHARE_GRID = 0,
  // Input Grid Channels
  parameter GRID_CHANNELS_IN = (SHARE_GRID)? 1 : DATA_CHANNELS,
  // Output Grid Channels
  parameter GRID_CHANNELS_OUT = (SHARE_GRID)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Data Width of address bus in bits
  parameter ADDR_WIDTH_DATA = 32,
  // Grid Width of address bus in bits
  parameter ADDR_WIDTH_GRID = 32,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_SCALE = 32,
  // Data FIFO size per stream
  parameter FIFO_DEPTH_DATA = $sqrt(BATCH_SIZE + DATA_CHANNELS),
  // Grid FIFO size per stream
  parameter FIFO_DEPTH_GRID = $sqrt(BATCH_SIZE + DATA_CHANNELS),
  // Scale FIFO size per stream
  parameter FIFO_DEPTH_SCALE = (SHARE_SCALE) ? 0 : $sqrt(BATCH_SIZE + DATA_CHANNELS)
) (
  input  wire                                                       fsm_clk,
  input  wire                                                       rst,

  /*
   * Control signals -- Corresponding clock : fsm_clk
   */
  input  wire                                                       operation_start,
  input  wire [ADDR_WIDTH_DATA:0]                                   data_size,
  input  wire [ADDR_WIDTH_GRID:0]                                   grid_size,
  input  wire [ADDR_WIDTH_SCALE:0]                                  scle_size,
  
  /*
   * Interrupt signals -- Corresponding clock : fsm_clk
   */
  output reg                                                        operation_busy,
  output reg                                                        operation_complete,
  output reg                                                        operation_error,

  `ifdef DATA_IF_IS_BRAM
    /*
    * Data BRAM Control Interface -- Corresponding clock : data_bram_clk
    */
    input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_clk,
    output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_en,
    // output wire [BATCH_SIZE*DATA_CHANNELS*WE-1:0]                   data_bram_we,  // Read Only Operations allowed
    output wire [BATCH_SIZE*DATA_CHANNELS*ADDR_WIDTH_DATA-1:0]      data_bram_addr,
    // input  wire [BATCH_SIZE*DATA_CHANNELS*WIDTH-1:0]                data_bram_wrdata,
    input  wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      data_bram_rddata,
    input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_rdack,  // Ignore if BRAM_ACK_SIG == 0
  `endif

  `ifdef DATA_IF_IS_AXIL
    /*
    * Data AXI lite Master Interface -- Corresponding clock : m_axil_data_aclk
    */
    input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_aclk,
    output wire [BATCH_SIZE*DATA_CHANNELS*ADDR_WIDTH_DATA-1:0]      m_axil_data_araddr,
    output wire [BATCH_SIZE*DATA_CHANNELS*3-1:0]                    m_axil_data_arprot,
    output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_arvalid,
    input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_arready,
    input  wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_SCALE-1:0]     m_axil_data_rdata,
    input  wire [BATCH_SIZE*DATA_CHANNELS*2-1:0]                    m_axil_data_rresp,
    input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_rvalid,
    output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_rready,
  `endif

  /*
   * AXI Stream Data Output -- Corresponding clock : m_axis_data_aclk
   */
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                        m_axis_data_aclk,
  output wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]        m_axis_data_tdata,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                        m_axis_data_tvalid,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                        m_axis_data_tready,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                        m_axis_data_tlast,
  output wire [BATCH_SIZE*DATA_CHANNELS*ID_WIDTH-1:0]               m_axis_data_tid,
  output wire [BATCH_SIZE*DATA_CHANNELS*DEST_WIDTH-1:0]             m_axis_data_tdest,
  output wire [BATCH_SIZE*DATA_CHANNELS*USER_WIDTH-1:0]             m_axis_data_tuser,

  `ifdef GRID_IF_IS_BRAM
    /*
    * Grid BRAM Control Interface -- Corresponding clock : grid_bram_clk
    */
    input  wire [GRID_CHANNELS_IN-1:0]                              grid_bram_clk,
    output wire [GRID_CHANNELS_IN-1:0]                              grid_bram_en,
    // output wire [GRID_CHANNELS_IN*WE-1:0]                           grid_bram_we,  // Read Only Operations allowed
    output wire [GRID_CHANNELS_IN*ADDR_WIDTH_DATA-1:0]              grid_bram_addr,
    // input  wire [GRID_CHANNELS_IN*WIDTH-1:0]                        grid_bram_wrdata,
    input  wire [GRID_CHANNELS_IN*DATA_WIDTH_DATA-1:0]              grid_bram_rddata,
    input  wire [GRID_CHANNELS_IN-1:0]                              grid_bram_rdack,  // Ignore if BRAM_ACK_SIG == 0                                     
  `endif

  `ifdef GRID_IF_IS_AXIL
    /*
    * Grid AXI lite Master  -- Corresponding clock : m_axil_grid_aclk
    */
    input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_aclk,
    output wire [GRID_CHANNELS_IN*ADDR_WIDTH_GRID-1:0]              m_axil_grid_araddr,
    output wire [GRID_CHANNELS_IN*3-1:0]                            m_axil_grid_arprot,
    output wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_arvalid,
    input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_arready,
    input  wire [GRID_CHANNELS_IN*DATA_WIDTH_DATA-1:0]              m_axil_grid_rdata,
    input  wire [GRID_CHANNELS_IN*2-1:0]                            m_axil_grid_rresp,
    input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_rvalid,
    output wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_rready,
  `endif

  /*
   * AXI Stream Grid Output -- Corresponding clock : m_axis_grid_aclk
   */
  output wire [GRID_CHANNELS_OUT-1:0]                               m_axis_grid_aclk,
  output wire [GRID_CHANNELS_OUT*DATA_WIDTH_DATA-1:0]               m_axis_grid_tdata,
  output wire [GRID_CHANNELS_OUT-1:0]                               m_axis_grid_tvalid,
  input  wire [GRID_CHANNELS_OUT-1:0]                               m_axis_grid_tready,
  output wire [GRID_CHANNELS_OUT-1:0]                               m_axis_grid_tlast,
  output wire [GRID_CHANNELS_OUT*ID_WIDTH-1:0]                      m_axis_grid_tid,
  output wire [GRID_CHANNELS_OUT*DEST_WIDTH-1:0]                    m_axis_grid_tdest,
  output wire [GRID_CHANNELS_OUT*USER_WIDTH-1:0]                    m_axis_grid_tuser,

  `ifdef SCALE_IF_IS_BRAM
    /*
    * Scale BRAM Control Interface -- Corresponding clock : scle_bram_clk
    */
    input  wire [SCALE_CHANNELS_IN-1:0]                             scle_bram_clk,
    output wire [SCALE_CHANNELS_IN-1:0]                             scle_bram_en,
    // output wire [SCALE_CHANNELS_IN*WE-1:0]                          scle_bram_we,  // Read Only Operations allowed
    output wire [SCALE_CHANNELS_IN*ADDR_WIDTH_SCALE-1:0]            scle_bram_addr,
    // input  wire [SCALE_CHANNELS_IN*WIDTH-1:0]                       scle_bram_wrdata,
    input  wire [SCALE_CHANNELS_IN*DATA_WIDTH_SCALE-1:0]            scle_bram_rddata,
    input  wire [SCALE_CHANNELS_IN-1:0]                             scle_bram_rdack,  // Ignore if BRAM_ACK_SIG == 0
  `endif

  `ifdef SCALE_IF_IS_AXIL
    /*
    * Scale AXI lite Master Interface -- Corresponding clock : m_axil_scle_aclk
    */
    input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_aclk,
    output wire [SCALE_CHANNELS_IN*ADDR_WIDTH_DATA-1:0]             m_axil_scle_araddr,
    output wire [SCALE_CHANNELS_IN*3-1:0]                           m_axil_scle_arprot,
    output wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_arvalid,
    input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_arready,
    input  wire [SCALE_CHANNELS_IN*DATA_WIDTH_SCALE-1:0]            m_axil_scle_rdata,
    input  wire [SCALE_CHANNELS_IN*2-1:0]                           m_axil_scle_rresp,
    input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_rvalid,
    output wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_rready,
  `endif
  
  /*
   * AXI Stream Scale Output -- Corresponding clock : m_axis_scle_aclk
   */
  output wire [SCALE_CHANNELS_OUT-1:0]                              m_axis_scle_aclk,
  output wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]             m_axis_scle_tdata,
  output wire [SCALE_CHANNELS_OUT-1:0]                              m_axis_scle_tvalid,
  input  wire [SCALE_CHANNELS_OUT-1:0]                              m_axis_scle_tready,
  output wire [SCALE_CHANNELS_OUT-1:0]                              m_axis_scle_tlast,
  output wire [SCALE_CHANNELS_OUT*ID_WIDTH-1:0]                     m_axis_scle_tid,
  output wire [SCALE_CHANNELS_OUT*DEST_WIDTH-1:0]                   m_axis_scle_tdest,
  output wire [SCALE_CHANNELS_OUT*USER_WIDTH-1:0]                   m_axis_scle_tuser
);

  // Control Registers & Wires
  reg  op_in_progress_reg = 1'b0;
  reg  [ADDR_WIDTH_DATA:0]  data_size_reg;
  reg  [ADDR_WIDTH_GRID:0]  grid_size_reg;
  reg  [ADDR_WIDTH_SCALE:0] scle_size_reg;

  // Local FSM output signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_tlast_transmitted;
  wire [GRID_CHANNELS_IN-1:0]         grid_tlast_transmitted;
  wire [SCALE_CHANNELS_IN-1:0]        scle_tlast_transmitted;

  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_error;
  wire [GRID_CHANNELS_IN-1:0]         grid_error;
  wire [SCALE_CHANNELS_IN-1:0]        scle_error;

  // Global FSM input signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_op_done_reg_next = data_op_done_reg | data_tlast_transmitted;
  wire [GRID_CHANNELS_IN-1:0]         grid_op_done_reg_next = grid_op_done_reg | grid_tlast_transmitted;
  wire [SCALE_CHANNELS_IN-1:0]        scle_op_done_reg_next = scle_op_done_reg | scle_tlast_transmitted;

  wire op_done              =  &{data_op_done_reg, grid_op_done_reg, scle_op_done_reg};
  
  // wire data_error_reduced   = |data_error;
  // wire grid_error_reduced   =  grid_error;
  // wire scle_error_reduced   = |scle_error;
  // wire internal_error       = data_error_reduced || grid_error_reduced || scle_error_reduced;
  wire internal_error       = |{data_error, grid_error, scle_error};

  // Global FSM output signals
  reg  [GLO_FSM_WIDTH-1:0] glo_fsm_state, glo_fsm_state_next;
  reg  [BATCH_SIZE*DATA_CHANNELS-1:0] data_op_done_reg;
  reg  [GRID_CHANNELS_IN-1:0]         grid_op_done_reg;
  reg  [SCALE_CHANNELS_IN-1:0]        scle_op_done_reg;

  // Global FSM state logic
  always @(posedge fsm_clk ) begin
    if (rst) begin
      glo_fsm_state <= GLO_FSM_ST0;

      data_op_done_reg <= {(BATCH_SIZE*DATA_CHANNELS){1'b0}};
      grid_op_done_reg <= 1'b0;

      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

    end else begin
      glo_fsm_state <= glo_fsm_state_next;

      data_op_done_reg <= {(BATCH_SIZE*DATA_CHANNELS){1'b0}};
      grid_op_done_reg <= {GRID_CHANNELS_IN{1'b0}};
      scle_op_done_reg <= {SCALE_CHANNELS_IN{1'b0}};

      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

      case (glo_fsm_state_next)
        GLO_FSM_ST0: begin

        end
        GLO_FSM_STR: begin
          operation_busy <= 1'b1;

        end
        GLO_FSM_OPE: begin
          data_op_done_reg <= data_op_done_reg_next;
          grid_op_done_reg <= grid_op_done_reg_next;
          scle_op_done_reg <= scle_op_done_reg_next;

          operation_busy <= 1'b1;

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
      if ((data_size[ADDR_WIDTH_DATA] && (|data_size[ADDR_WIDTH_DATA-1:0])) || ~|data_size) begin \
        glo_fsm_state_next <= GLO_FSM_ERR; \
      end else begin \
        data_size_reg <= data_size; \
      end \
      if ((grid_size[ADDR_WIDTH_DATA] && (|grid_size[ADDR_WIDTH_DATA-1:0])) || ~|grid_size) begin \
        glo_fsm_state_next <= GLO_FSM_ERR; \
      end else begin \
        grid_size_reg <= grid_size; \
      end \
      if ((scle_size[ADDR_WIDTH_DATA] && (|scle_size[ADDR_WIDTH_DATA-1:0])) || ~|scle_size) begin \
        glo_fsm_state_next <= GLO_FSM_ERR; \
      end else begin \
        scle_size_reg <= scle_size; \
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
        glo_fsm_state_next <= GLO_FSM_OPE;
      end
      GLO_FSM_OPE: begin
        if (op_done) begin
          glo_fsm_state_next <= GLO_FSM_END;
        end
      end
      GLO_FSM_END: begin
        `GLO_CHECK_OP_START
      end
      GLO_FSM_ERR: begin
        glo_fsm_state_next <= GLO_FSM_ST0;
        
      end
      default: begin
        glo_fsm_state_next <= GLO_FSM_ST0;
        
      end 
    endcase
    if (internal_error) begin
      glo_fsm_state_next <= GLO_FSM_ERR;
    end
    if (rst) begin
      glo_fsm_state_next <= GLO_FSM_ST0;
    end
  end

  genvar pos, batch;

 generate
  if (SHARE_SCALE == 0) begin
    for (pos = 0; pos < DATA_CHANNELS; pos = pos + 1) begin // One scale per data channel
      // Channel's clk driver
      wire scle_clk_pos = 
        `ifdef SCALE_IF_IS_AXIL
          m_axil_scle_aclk[pos];
        `endif 
        `ifdef SCALE_IF_IS_BRAM
          scle_bram_clk[pos];
        `endif 

      // Local Scale FIFO I/O
      wire [DATA_WIDTH_SCALE-1:0] scle_fifo_in_axis_tdata,  scle_fifo_out_axis_tdata;
      wire                        scle_fifo_in_axis_tvalid, scle_fifo_out_axis_tvalid;
      wire                        scle_fifo_in_axis_tready, scle_fifo_out_axis_tready;
      wire                        scle_fifo_in_axis_tlast,  scle_fifo_out_axis_tlast;

      // Local Grid Broadcaster I/O
      wire [DATA_WIDTH_SCALE-1:0]            scle_bcst_in_axis_tdata;  
      wire                                   scle_bcst_in_axis_tvalid; 
      wire                                   scle_bcst_in_axis_tready; 
      wire                                   scle_bcst_in_axis_tlast;

      wire [BATCH_SIZE*DATA_WIDTH_SCALE-1:0] scle_bcst_out_axis_tdata;
      wire [BATCH_SIZE-1:0]                  scle_bcst_out_axis_tvalid;
      wire [BATCH_SIZE-1:0]                  scle_bcst_out_axis_tready;
      wire [BATCH_SIZE-1:0]                  scle_bcst_out_axis_tlast;

      `ifdef SCALE_IF_IS_AXIL
      MCULocalAxilFSM 
      `endif 
      `ifdef SCALE_IF_IS_BRAM
      MCULocalBramFSM
      `endif 
      #(
        `include "rtl/MCUGlobalFSMParametersInst.vh"
        `ifdef BRAM_ACK_SIG_OPTION
          // BRAM control has valid signal
          .BRAM_ACK_SIG(BRAM_ACK_SIG),
        `endif 
        // Width of AXI stream Output interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_SCALE),
        // Width of address bus in bits
        .ADDR_WIDTH(ADDR_WIDTH_SCALE),
        // Width of inter-iteration counters
        .INTER_ITER_WIDTH(1),
        // Width of intra-iteration counters
        .INTRA_ITER_WIDTH(1)
      ) MCULocalFSM_scle_pos_inst (
        .clk(scle_clk_pos),
        .rst(rst),
        `ifdef SCALE_IF_IS_BRAM
          .bram_en(scle_bram_en[pos]),
          // .bram_we(bram_we[pos*WE +: WE]),  // Read Only Operations allowed
          .bram_addr(scle_bram_addr[pos*ADDR_WIDTH_SCALE +: ADDR_WIDTH_SCALE]),
          // .bram_wrdata(bram_wrdata[pos*DATA_WIDTH_SCALE +: DATA_WIDTH_SCALE]),
          .bram_rddata(scle_bram_rddata[pos*DATA_WIDTH_SCALE +: DATA_WIDTH_SCALE]),
          .bram_rdack(scle_bram_rdack[pos]),
        `endif 
        `ifdef SCALE_IF_IS_AXIL
          .m_axil_araddr(m_axil_scle_araddr[pos*ADDR_WIDTH_SCALE +: ADDR_WIDTH_SCALE]),
          .m_axil_arprot(m_axil_scle_arprot[pos*3 +:3]),
          .m_axil_arvalid(m_axil_scle_arvalid[pos]),
          .m_axil_arready(m_axil_scle_arready[pos]),
          .m_axil_rdata(m_axil_scle_rdata[pos*DATA_WIDTH_SCALE +: DATA_WIDTH_SCALE]),
          .m_axil_rresp(m_axil_scle_rresp[pos*2 +:2]),
          .m_axil_rvalid(m_axil_scle_rvalid[pos]),
          .m_axil_rready(m_axil_scle_rready[pos]),
        `endif 
        .m_axis_tdata(scle_fifo_in_axis_tdata),
        .m_axis_tvalid(scle_fifo_in_axis_tvalid),
        .m_axis_tready(scle_fifo_in_axis_tready),
        .m_axis_tlast(scle_fifo_in_axis_tlast),
        .glo_fsm_state(glo_fsm_state),
        .addr_counter_max(scle_size_reg),   //  Unique scale per data per grid
        .inter_counter_max(1'b1),
        .intra_counter_max(1'b1),
        .tlast_transmitted(scle_tlast_transmitted[pos]),
        .error(scle_error[pos])
      );

      axis_broadcast #(
        .M_COUNT(BATCH_SIZE),
        .DATA_WIDTH(DATA_WIDTH_SCALE),
        .KEEP_ENABLE(0),
        .KEEP_WIDTH(1),
        .LAST_ENABLE(1),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
      )
      axis_broadcast_scle_pos_inst (
        .clk(scle_clk_pos),
        .rst(rst),
        // AXI input
        .s_axis_tdata(s_axis_scale_tdata),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(s_axis_scale_tvalid),
        .s_axis_tready(s_axis_scale_tready),
        .s_axis_tlast(s_axis_scale_tlast),
        .s_axis_tid(s_axis_scale_tid),
        .s_axis_tdest(s_axis_scale_tdest),
        .s_axis_tuser(s_axis_scale_tuser),
        // AXI outputs
        .m_axis_tdata(s_axis_scale_tdata_int),
        // .m_axis_tkeep(s_axis_scale_tkeep_int),
        .m_axis_tvalid(s_axis_scale_tvalid_int),
        .m_axis_tready(s_axis_scale_tready_int),
        .m_axis_tlast(s_axis_scale_tlast_int),
        .m_axis_tid(s_axis_scale_tid_int),
        .m_axis_tdest(s_axis_scale_tdest_int),
        .m_axis_tuser(s_axis_scale_tuser_int)
      );
      if (FIFO_DEPTH_SCALE > 0) begin
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
          .DEPTH((FIFO_DEPTH_SCALE+1)>>1)
        ) axis_fifo_scle_pos_batch_inst (
          .clk(scle_clk_pos),
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
          .m_axis_tlast(scle_fifo_out_axis_tlast)
        );
      end else begin
        assign scle_fifo_out_axis_tdata  = scle_fifo_in_axis_tdata;
        assign scle_fifo_out_axis_tvalid = scle_fifo_in_axis_tvalid;
        assign scle_fifo_in_axis_tready  = scle_fifo_out_axis_tready;
        assign scle_fifo_out_axis_tlast  = scle_fifo_in_axis_tlast;
      end

      for (batch=0; batch < BATCH_SIZE; batch = batch+1) begin  // Broadcast scales to BATCH_SIZE channels
        localparam LFT_POS = batch * DATA_CHANNELS + pos;
        // Batch Local Scale FIFO I/O
        wire [DATA_WIDTH_SCALE-1:0] scle_batch_fifo_in_axis_tdata,  scle_batch_fifo_out_axis_tdata;
        wire                        scle_batch_fifo_in_axis_tvalid, scle_batch_fifo_out_axis_tvalid;
        wire                        scle_batch_fifo_in_axis_tready, scle_batch_fifo_out_axis_tready;
        wire                        scle_batch_fifo_in_axis_tlast,  scle_batch_fifo_out_axis_tlast;

        assign scle_bcst_in_axis_tdata [batch*DATA_WIDTH_SCALE +: DATA_WIDTH_SCALE] = scle_batch_fifo_in_axis_tdata;
        assign scle_bcst_in_axis_tvalid[batch] = scle_batch_fifo_in_axis_tvalid;
        assign scle_batch_fifo_in_axis_tready  = scle_bcst_in_axis_tready[batch];
        assign scle_bcst_in_axis_tlast [batch] = scle_batch_fifo_in_axis_tlast;

        if (FIFO_DEPTH_SCALE < 2) begin
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
            .DEPTH(FIFO_DEPTH_SCALE >> 1)
          ) axis_fifo_scle_batch_inst (
            .clk(scle_clk_pos),
            .rst(rst),
            .s_axis_tdata(scle_batch_fifo_in_axis_tdata),
            .s_axis_tkeep(1'b1),
            .s_axis_tvalid(scle_batch_fifo_in_axis_tvalid),
            .s_axis_tready(scle_batch_fifo_in_axis_tready),
            .s_axis_tlast(scle_batch_fifo_in_axis_tlast),
            .s_axis_tid(1'b0),
            .s_axis_tdest(1'b0),
            .s_axis_tuser(1'b0),
            .m_axis_tdata(scle_batch_fifo_out_axis_tdata),
            .m_axis_tvalid(scle_batch_fifo_out_axis_tvalid),
            .m_axis_tready(scle_batch_fifo_out_axis_tready),
            .m_axis_tlast(scle_batch_fifo_out_axis_tlast)
          );
        end else begin
          assign scle_batch_fifo_out_axis_tdata  = scle_batch_fifo_in_axis_tdata;
          assign scle_batch_fifo_out_axis_tvalid = scle_batch_fifo_in_axis_tvalid;
          assign scle_batch_fifo_in_axis_tready  = scle_batch_fifo_out_axis_tready;
          assign scle_batch_fifo_out_axis_tlast  = scle_batch_fifo_in_axis_tlast;
        end

        assign m_axis_scle_aclk   [LFT_POS] = scle_clk_pos;
        assign m_axis_scle_tdata  [LFT_POS*DATA_WIDTH_SCALE +: DATA_WIDTH_SCALE] = scle_batch_fifo_out_axis_tdata;
        assign m_axis_scle_tvalid [LFT_POS] = scle_batch_fifo_out_axis_tvalid;
        assign scle_batch_fifo_out_axis_tready = m_axis_scle_tready[LFT_POS];
        assign m_axis_scle_tlast  [LFT_POS] = scle_batch_fifo_out_axis_tlast;
      end
    end
  end else begin // One scale per data channel
    // Channel's clk driver
    wire scle_clk = 
      `ifdef SCALE_IF_IS_AXIL
        m_axil_scle_aclk[0];
      `endif 
      `ifdef SCALE_IF_IS_BRAM
        scle_bram_clk[0];
      `endif 

    // Local Scale FIFO I/O
    wire [DATA_WIDTH_SCALE-1:0] scle_fifo_in_axis_tdata,  scle_fifo_out_axis_tdata;
    wire                        scle_fifo_in_axis_tvalid, scle_fifo_out_axis_tvalid;
    wire                        scle_fifo_in_axis_tready, scle_fifo_out_axis_tready;
    wire                        scle_fifo_in_axis_tlast,  scle_fifo_out_axis_tlast;

    `ifdef SCALE_IF_IS_AXIL
    MCULocalAxilFSM 
    `endif 
    `ifdef SCALE_IF_IS_BRAM
    MCULocalBramFSM
    `endif 
    #(
      `include "rtl/MCUGlobalFSMParametersInst.vh"
      `ifdef BRAM_ACK_SIG_OPTION
        // BRAM control has valid signal
        .BRAM_ACK_SIG(BRAM_ACK_SIG),
      `endif 
      // Width of AXI stream Output interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_SCALE),
      // Width of address bus in bits
      .ADDR_WIDTH(ADDR_WIDTH_SCALE),
      // Width of inter-iteration counters
      .INTER_ITER_WIDTH(1),
      // Width of intra-iteration counters
      .INTRA_ITER_WIDTH(1)
    ) MCULocalFSM_scle_pos_inst (
      .clk(scle_clk),
      .rst(rst),
      `ifdef SCALE_IF_IS_BRAM
        .bram_en(scle_bram_en),
        // .bram_we(scle_bram_we),  // Read Only Operations allowed
        .bram_addr(scle_bram_addr),
        // .bram_wrdata(scle_bram_wrdata),
        .bram_rddata(scle_bram_rddata),
        .bram_rdack(scle_bram_rdack),
      `endif 
      `ifdef SCALE_IF_IS_AXIL
        .m_axil_araddr(m_axil_scle_araddr),
        .m_axil_arprot(m_axil_scle_arprot),
        .m_axil_arvalid(m_axil_scle_arvalid),
        .m_axil_arready(m_axil_scle_arready[0]),
        .m_axil_rdata(m_axil_scle_rdata),
        .m_axil_rresp(m_axil_scle_rresp),
        .m_axil_rvalid(m_axil_scle_rvalid),
        .m_axil_rready(m_axil_scle_rready),
      `endif 
      .m_axis_tdata(scle_fifo_in_axis_tdata),
      .m_axis_tvalid(scle_fifo_in_axis_tvalid),
      .m_axis_tready(scle_fifo_in_axis_tready),
      .m_axis_tlast(scle_fifo_in_axis_tlast),
      .glo_fsm_state(glo_fsm_state),
      .addr_counter_max(scle_size_reg),   //  Unique scale per data per grid
      .inter_counter_max(1'b1),
      .intra_counter_max(1'b1),
      .tlast_transmitted(scle_tlast_transmitted[0]),
      .error(scle_error[0])
    );

    if (FIFO_DEPTH_SCALE > 1) begin
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
        .DEPTH(FIFO_DEPTH_SCALE)
      ) axis_fifo_scle_pos_batch_inst (
        .clk(scle_clk),
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
        .m_axis_tlast(scle_fifo_out_axis_tlast)
      );
    end else begin
      assign scle_fifo_out_axis_tdata  = scle_fifo_in_axis_tdata;
      assign scle_fifo_out_axis_tvalid = scle_fifo_in_axis_tvalid;
      assign scle_fifo_in_axis_tready  = scle_fifo_out_axis_tready;
      assign scle_fifo_out_axis_tlast  = scle_fifo_in_axis_tlast;
    end

    assign m_axis_scle_aclk   [0] = scle_clk;
    assign m_axis_scle_tdata      = scle_fifo_out_axis_tdata;
    assign m_axis_scle_tvalid [0] = scle_fifo_out_axis_tvalid;
    assign scle_fifo_out_axis_tready  = m_axis_scle_tready[0];
    assign m_axis_scle_tlast  [0] = scle_fifo_out_axis_tlast;
  end

  if (SHARE_GRID == 0) begin
    for (pos = 0; pos < DATA_CHANNELS; pos = pos + 1) begin // One scale per data channel
      // Channel's clk driver
      wire grid_clk_pos = 
        `ifdef GRID_IF_IS_AXIL
          m_axil_grid_aclk[pos];
        `endif 
        `ifdef GRID_IF_IS_BRAM
          grid_bram_clk[pos];
        `endif 

      // Local Scale FIFO I/O
      wire [DATA_WIDTH_DATA-1:0]  grid_fifo_in_axis_tdata,  grid_fifo_out_axis_tdata;
      wire                        grid_fifo_in_axis_tvalid, grid_fifo_out_axis_tvalid;
      wire                        grid_fifo_in_axis_tready, grid_fifo_out_axis_tready;
      wire                        grid_fifo_in_axis_tlast,  grid_fifo_out_axis_tlast;

      // Local Grid Broadcaster I/O
      wire [DATA_WIDTH_DATA-1:0]             grid_bcst_in_axis_tdata;  
      wire                                   grid_bcst_in_axis_tvalid; 
      wire                                   grid_bcst_in_axis_tready; 
      wire                                   grid_bcst_in_axis_tlast;

      wire [BATCH_SIZE*DATA_WIDTH_DATA-1:0]  grid_bcst_out_axis_tdata;
      wire [BATCH_SIZE-1:0]                  grid_bcst_out_axis_tvalid;
      wire [BATCH_SIZE-1:0]                  grid_bcst_out_axis_tready;
      wire [BATCH_SIZE-1:0]                  grid_bcst_out_axis_tlast;

      `ifdef GRID_IF_IS_AXIL
      MCULocalAxilFSM 
      `endif 
      `ifdef GRID_IF_IS_BRAM
      MCULocalBramFSM
      `endif 
      #(
        `include "rtl/MCUGlobalFSMParametersInst.vh"
        `ifdef BRAM_ACK_SIG_OPTION
          // BRAM control has valid signal
          .BRAM_ACK_SIG(BRAM_ACK_SIG),
        `endif 
        // Width of AXI stream Output interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_DATA),
        // Width of address bus in bits
        .ADDR_WIDTH(ADDR_WIDTH_GRID),
        // Width of inter-iteration counters
        .INTER_ITER_WIDTH(1),
        // Width of intra-iteration counters
        .INTRA_ITER_WIDTH(ADDR_WIDTH_DATA+1)
      ) MCULocalFSM_grid_pos_inst (
        .clk(grid_clk_pos),
        .rst(rst),
        `ifdef GRID_IF_IS_BRAM
          .bram_en(grid_bram_en[pos]),
          // .bram_we(bram_we[pos*WE +: WE]),  // Read Only Operations allowed
          .bram_addr(grid_bram_addr[pos*ADDR_WIDTH_GRID +: ADDR_WIDTH_GRID]),
          // .bram_wrdata(bram_wrdata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
          .bram_rddata(grid_bram_rddata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
          .bram_rdack(grid_bram_rdack[pos]),
        `endif 
        `ifdef GRID_IF_IS_AXIL
          .m_axil_araddr(m_axil_grid_araddr[pos*ADDR_WIDTH_GRID +: ADDR_WIDTH_GRID]),
          .m_axil_arprot(m_axil_grid_arprot[pos*3 +:3]),
          .m_axil_arvalid(m_axil_grid_arvalid[pos]),
          .m_axil_arready(m_axil_grid_arready[pos]),
          .m_axil_rdata(m_axil_grid_rdata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
          .m_axil_rresp(m_axil_grid_rresp[pos*2 +:2]),
          .m_axil_rvalid(m_axil_grid_rvalid[pos]),
          .m_axil_rready(m_axil_grid_rready[pos]),
        `endif 
        .m_axis_tdata(grid_fifo_in_axis_tdata),
        .m_axis_tvalid(grid_fifo_in_axis_tvalid),
        .m_axis_tready(grid_fifo_in_axis_tready),
        .m_axis_tlast(grid_fifo_in_axis_tlast),
        .glo_fsm_state(glo_fsm_state),
        .addr_counter_max(grid_size_reg),   //  Multiple data per grid
        .inter_counter_max($unsigned(1)),
        .intra_counter_max(data_size_reg),
        .tlast_transmitted(grid_tlast_transmitted[pos]),
        .error(grid_error[pos])
      );

      axis_broadcast #(
        .M_COUNT(BATCH_SIZE),
        .DATA_WIDTH(DATA_WIDTH_DATA),
        .KEEP_ENABLE(0),
        .KEEP_WIDTH(1),
        .LAST_ENABLE(1),
        .ID_ENABLE(ID_ENABLE),
        .ID_WIDTH(ID_WIDTH),
        .DEST_ENABLE(DEST_ENABLE),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_ENABLE(USER_ENABLE),
        .USER_WIDTH(USER_WIDTH)
      ) axis_broadcast_grid_pos_inst (
        .clk(grid_clk_pos),
        .rst(rst),
        // AXI input
        .s_axis_tdata(s_axis_scale_tdata),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(s_axis_scale_tvalid),
        .s_axis_tready(s_axis_scale_tready),
        .s_axis_tlast(s_axis_scale_tlast),
        .s_axis_tid(s_axis_scale_tid),
        .s_axis_tdest(s_axis_scale_tdest),
        .s_axis_tuser(s_axis_scale_tuser),
        // AXI outputs
        .m_axis_tdata(s_axis_scale_tdata_int),
        // .m_axis_tkeep(s_axis_scale_tkeep_int),
        .m_axis_tvalid(s_axis_scale_tvalid_int),
        .m_axis_tready(s_axis_scale_tready_int),
        .m_axis_tlast(s_axis_scale_tlast_int),
        .m_axis_tid(s_axis_scale_tid_int),
        .m_axis_tdest(s_axis_scale_tdest_int),
        .m_axis_tuser(s_axis_scale_tuser_int)
      );

      if (FIFO_DEPTH_GRID > 0) begin
        axis_srl_fifo #(
          // Width of AXI stream interfaces in bits
          .DATA_WIDTH(DATA_WIDTH_DATA),
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
          .DEPTH((FIFO_DEPTH_GRID+1)>>1)
        ) axis_fifo_grid_pos_batch_inst (
          .clk(grid_clk_pos),
          .rst(rst),
          .s_axis_tdata(grid_fifo_in_axis_tdata),
          .s_axis_tkeep(1'b1),
          .s_axis_tvalid(grid_fifo_in_axis_tvalid),
          .s_axis_tready(grid_fifo_in_axis_tready),
          .s_axis_tlast(grid_fifo_in_axis_tlast),
          .s_axis_tid(1'b0),
          .s_axis_tdest(1'b0),
          .s_axis_tuser(1'b0),
          .m_axis_tdata(grid_fifo_out_axis_tdata),
          .m_axis_tvalid(grid_fifo_out_axis_tvalid),
          .m_axis_tready(grid_fifo_out_axis_tready),
          .m_axis_tlast(grid_fifo_out_axis_tlast)
        );
      end else begin
        assign grid_fifo_out_axis_tdata  = grid_fifo_in_axis_tdata;
        assign grid_fifo_out_axis_tvalid = grid_fifo_in_axis_tvalid;
        assign grid_fifo_in_axis_tready  = grid_fifo_out_axis_tready;
        assign grid_fifo_out_axis_tlast  = grid_fifo_in_axis_tlast;
      end

      for (batch=0; batch < BATCH_SIZE; batch = batch+1) begin  // Broadcast scales to BATCH_SIZE channels
        localparam LFT_POS = batch * DATA_CHANNELS + pos;
        // Batch Local Scale FIFO I/O
        wire [DATA_WIDTH_DATA-1:0]  grid_batch_fifo_in_axis_tdata,  grid_batch_fifo_out_axis_tdata;
        wire                        grid_batch_fifo_in_axis_tvalid, grid_batch_fifo_out_axis_tvalid;
        wire                        grid_batch_fifo_in_axis_tready, grid_batch_fifo_out_axis_tready;
        wire                        grid_batch_fifo_in_axis_tlast,  grid_batch_fifo_out_axis_tlast;

        assign grid_bcst_in_axis_tdata [batch*DATA_WIDTH_DATA +: DATA_WIDTH_DATA] = grid_batch_fifo_in_axis_tdata;
        assign grid_bcst_in_axis_tvalid[batch] = grid_batch_fifo_in_axis_tvalid;
        assign grid_batch_fifo_in_axis_tready  = grid_bcst_in_axis_tready[batch];
        assign grid_bcst_in_axis_tlast [batch] = grid_batch_fifo_in_axis_tlast;

        if (FIFO_DEPTH_GRID < 2) begin
          axis_srl_fifo #(
            // Width of AXI stream interfaces in bits
            .DATA_WIDTH(DATA_WIDTH_DATA),
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
            .DEPTH(FIFO_DEPTH_GRID >> 1)
          ) axis_fifo_grid_batch_inst (
            .clk(grid_clk_pos),
            .rst(rst),
            .s_axis_tdata(grid_batch_fifo_in_axis_tdata),
            .s_axis_tkeep(1'b1),
            .s_axis_tvalid(grid_batch_fifo_in_axis_tvalid),
            .s_axis_tready(grid_batch_fifo_in_axis_tready),
            .s_axis_tlast(grid_batch_fifo_in_axis_tlast),
            .s_axis_tid(1'b0),
            .s_axis_tdest(1'b0),
            .s_axis_tuser(1'b0),
            .m_axis_tdata(grid_batch_fifo_out_axis_tdata),
            .m_axis_tvalid(grid_batch_fifo_out_axis_tvalid),
            .m_axis_tready(grid_batch_fifo_out_axis_tready),
            .m_axis_tlast(grid_batch_fifo_out_axis_tlast)
          );
        end else begin
          assign grid_batch_fifo_out_axis_tdata  = grid_batch_fifo_in_axis_tdata;
          assign grid_batch_fifo_out_axis_tvalid = grid_batch_fifo_in_axis_tvalid;
          assign grid_batch_fifo_in_axis_tready  = grid_batch_fifo_out_axis_tready;
          assign grid_batch_fifo_out_axis_tlast  = grid_batch_fifo_in_axis_tlast;
        end

        assign m_axis_grid_aclk   [LFT_POS] = grid_clk_pos;
        assign m_axis_grid_tdata  [LFT_POS*DATA_WIDTH_DATA +: DATA_WIDTH_DATA] = grid_batch_fifo_out_axis_tdata;
        assign m_axis_grid_tvalid [LFT_POS] = grid_batch_fifo_out_axis_tvalid;
        assign grid_batch_fifo_out_axis_tready = m_axis_grid_tready[LFT_POS];
        assign m_axis_grid_tlast  [LFT_POS] = grid_batch_fifo_out_axis_tlast;
      end
    end
  end else begin // One scale per data channel
    // Channel's clk driver
    wire grid_clk = 
      `ifdef SCALE_IF_IS_AXIL
        m_axil_scle_aclk[0];
      `endif 
      `ifdef SCALE_IF_IS_BRAM
        scle_bram_clk[0];
      `endif 

    // Local Grid FIFO I/O
    wire [DATA_WIDTH_DATA-1:0]  grid_fifo_in_axis_tdata,  grid_fifo_out_axis_tdata;
    wire                        grid_fifo_in_axis_tvalid, grid_fifo_out_axis_tvalid;
    wire                        grid_fifo_in_axis_tready, grid_fifo_out_axis_tready;
    wire                        grid_fifo_in_axis_tlast,  grid_fifo_out_axis_tlast;

    `ifdef GRID_IF_IS_AXIL
    MCULocalAxilFSM 
    `endif 
    `ifdef GRID_IF_IS_BRAM
    MCULocalBramFSM
    `endif 
    #(
      `include "rtl/MCUGlobalFSMParametersInst.vh"
      `ifdef BRAM_ACK_SIG_OPTION
        // BRAM control has valid signal
        .BRAM_ACK_SIG(BRAM_ACK_SIG),
      `endif 
      // Width of AXI stream Output interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_DATA),
      // Width of address bus in bits
      .ADDR_WIDTH(ADDR_WIDTH_GRID),
      // Width of inter-iteration counters
      .INTER_ITER_WIDTH(1),
      // Width of intra-iteration counters
      .INTRA_ITER_WIDTH(ADDR_WIDTH_DATA+1)
    ) MCULocalFSM_grid_pos_inst (
      .clk(grid_clk),
      .rst(rst),
      `ifdef GRID_IF_IS_BRAM
        .bram_en(grid_bram_en),
        // .bram_we(grid_bram_we),  // Read Only Operations allowed
        .bram_addr(grid_bram_addr),
        // .bram_wrdata(grid_bram_wrdata),
        .bram_rddata(grid_bram_rddata),
        .bram_rdack(grid_bram_rdack),
      `endif 
      `ifdef GRID_IF_IS_AXIL
        .m_axil_araddr(m_axil_grid_araddr),
        .m_axil_arprot(m_axil_grid_arprot),
        .m_axil_arvalid(m_axil_grid_arvalid),
        .m_axil_arready(m_axil_grid_arready),
        .m_axil_rdata(m_axil_grid_rdata),
        .m_axil_rresp(m_axil_grid_rresp),
        .m_axil_rvalid(m_axil_grid_rvalid),
        .m_axil_rready(m_axil_grid_rready),
      `endif 
      .m_axis_tdata(grid_fifo_in_axis_tdata),
      .m_axis_tvalid(grid_fifo_in_axis_tvalid),
      .m_axis_tready(grid_fifo_in_axis_tready),
      .m_axis_tlast(grid_fifo_in_axis_tlast),
      .glo_fsm_state(glo_fsm_state),
      .addr_counter_max(grid_size_reg),   //  Multiple data per grid
      .inter_counter_max(1'b1),
      .intra_counter_max(data_size_reg),
      .tlast_transmitted(grid_tlast_transmitted[0]),
      .error(grid_error[0])
    );

    if (FIFO_DEPTH_GRID > 1) begin
      axis_srl_fifo #(
        // Width of AXI stream interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_DATA),
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
        .DEPTH(FIFO_DEPTH_GRID)
      ) axis_fifo_grid_pos_batch_inst (
        .clk(grid_clk),
        .rst(rst),
        .s_axis_tdata(grid_fifo_in_axis_tdata),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(grid_fifo_in_axis_tvalid),
        .s_axis_tready(grid_fifo_in_axis_tready),
        .s_axis_tlast(grid_fifo_in_axis_tlast),
        .s_axis_tid(1'b0),
        .s_axis_tdest(1'b0),
        .s_axis_tuser(1'b0),
        .m_axis_tdata(grid_fifo_out_axis_tdata),
        .m_axis_tvalid(grid_fifo_out_axis_tvalid),
        .m_axis_tready(grid_fifo_out_axis_tready),
        .m_axis_tlast(grid_fifo_out_axis_tlast)
      );
    end else begin
      assign grid_fifo_out_axis_tdata  = grid_fifo_in_axis_tdata;
      assign grid_fifo_out_axis_tvalid = grid_fifo_in_axis_tvalid;
      assign grid_fifo_in_axis_tready  = grid_fifo_out_axis_tready;
      assign grid_fifo_out_axis_tlast  = grid_fifo_in_axis_tlast;
    end

    assign m_axis_grid_aclk   [0] = grid_clk;
    assign m_axis_grid_tdata  = grid_fifo_out_axis_tdata;
    assign m_axis_grid_tvalid [0] = grid_fifo_out_axis_tvalid;
    assign grid_fifo_out_axis_tready = m_axis_grid_tready[0];
    assign m_axis_grid_tlast  [0] = grid_fifo_out_axis_tlast;
  end

  for (pos = 0; pos < BATCH_SIZE*DATA_CHANNELS; pos = pos + 1) begin // One data per data channel per batch
    // Channel's clk driver
    wire data_clk_pos = 
      `ifdef GRID_IF_IS_AXIL
        m_axil_data_aclk[pos];
      `endif 
      `ifdef GRID_IF_IS_BRAM
        data_bram_clk[pos];
      `endif 

    // Local Data FIFO I/O
    wire [DATA_WIDTH_DATA-1:0]  data_fifo_in_axis_tdata,  data_fifo_out_axis_tdata;
    wire                        data_fifo_in_axis_tvalid, data_fifo_out_axis_tvalid;
    wire                        data_fifo_in_axis_tready, data_fifo_out_axis_tready;
    wire                        data_fifo_in_axis_tlast,  data_fifo_out_axis_tlast;

    `ifdef DATA_IF_IS_AXIL
    MCULocalAxilFSM 
    `endif 
    `ifdef DATA_IF_IS_BRAM
    MCULocalBramFSM
    `endif 
    #(
      `include "rtl/MCUGlobalFSMParametersInst.vh"
      `ifdef BRAM_ACK_SIG_OPTION
        // BRAM control has valid signal
        .BRAM_ACK_SIG(BRAM_ACK_SIG),
      `endif 
      // Width of AXI stream Output interfaces in bits
      .DATA_WIDTH(DATA_WIDTH_DATA),
      // Width of address bus in bits
      .ADDR_WIDTH(ADDR_WIDTH_DATA),
      // Width of inter-iteration counters
      .INTER_ITER_WIDTH(ADDR_WIDTH_GRID+1),
      // Width of intra-iteration counters
      .INTRA_ITER_WIDTH(1)
    ) MCULocalFSM_data_pos_inst (
      .clk(data_clk_pos),
      .rst(rst),
      `ifdef DATA_IF_IS_BRAM
        .bram_en(data_bram_en[pos]),
        // .bram_we(data_bram_we[pos*WE +: WE]),  // Read Only Operations allowed
        .bram_addr(data_bram_addr[pos*ADDR_WIDTH_DATA +: ADDR_WIDTH_DATA]),
        // .bram_wrdata(data_bram_wrdata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
        .bram_rddata(data_bram_rddata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
        .bram_rdack(data_bram_rdack[pos]),
      `endif 
      `ifdef DATA_IF_IS_AXIL
        .m_axil_araddr(m_axil_data_araddr[pos*ADDR_WIDTH_DATA +: ADDR_WIDTH_DATA]),
        .m_axil_arprot(m_axil_data_arprot[pos*3 +: 3]),
        .m_axil_arvalid(m_axil_data_arvalid[pos]),
        .m_axil_arready(m_axil_data_arready[pos]),
        .m_axil_rdata(m_axil_data_rdata[pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA]),
        .m_axil_rresp(m_axil_data_rresp[pos*2 +: 2]),
        .m_axil_rvalid(m_axil_data_rvalid[pos]),
        .m_axil_rready(m_axil_data_rready[pos]),
      `endif 
      .m_axis_tdata(data_fifo_in_axis_tdata),
      .m_axis_tvalid(data_fifo_in_axis_tvalid),
      .m_axis_tready(data_fifo_in_axis_tready),
      .m_axis_tlast(data_fifo_in_axis_tlast),
      .glo_fsm_state(glo_fsm_state),
      .addr_counter_max(data_size_reg),   //  One data per grid
      .inter_counter_max(grid_size_reg),
      .intra_counter_max(1'b1),
      .tlast_transmitted(data_tlast_transmitted[pos]),
      .error(data_error[pos])
    );

    if (FIFO_DEPTH_DATA > 1) begin
      axis_srl_fifo #(
        // Width of AXI stream interfaces in bits
        .DATA_WIDTH(DATA_WIDTH_DATA),
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
        .DEPTH(FIFO_DEPTH_DATA)
      ) axis_fifo_data_inst (
        .clk(data_clk_pos),
        .rst(rst),
        .s_axis_tdata(data_fifo_in_axis_tdata),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(data_fifo_in_axis_tvalid),
        .s_axis_tready(data_fifo_in_axis_tready),
        .s_axis_tlast(data_fifo_in_axis_tlast),
        .s_axis_tid(1'b0),
        .s_axis_tdest(1'b0),
        .s_axis_tuser(1'b0),
        .m_axis_tdata(data_fifo_out_axis_tdata),
        .m_axis_tvalid(data_fifo_out_axis_tvalid),
        .m_axis_tready(data_fifo_out_axis_tready),
        .m_axis_tlast(data_fifo_out_axis_tlast)
      );
    end else begin
      assign data_fifo_out_axis_tdata  = data_fifo_in_axis_tdata;
      assign data_fifo_out_axis_tvalid = data_fifo_in_axis_tvalid;
      assign data_fifo_in_axis_tready  = data_fifo_out_axis_tready;
      assign data_fifo_out_axis_tlast  = data_fifo_in_axis_tlast;
    end

    assign m_axis_data_aclk    [pos] = data_clk_pos;
    assign m_axis_data_tdata   [pos*DATA_WIDTH_DATA +: DATA_WIDTH_DATA] = data_fifo_out_axis_tdata;
    assign m_axis_data_tvalid  [pos] = data_fifo_out_axis_tvalid;
    assign data_fifo_out_axis_tready = m_axis_data_tready[pos];
    assign m_axis_data_tlast   [pos] = data_fifo_out_axis_tlast;
  end
 endgenerate

endmodule

`resetall
