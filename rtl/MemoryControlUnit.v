`resetall
`timescale 1ns/1ps
`default_nettype none

module MemoryControlUnit #(
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
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      data_bram_en,
  // output wire [BATCH_SIZE*DATA_CHANNELS*WE-1:0]                   data_bram_we,  // Read Only Operations allowed
  output wire [BATCH_SIZE*DATA_CHANNELS*ADDR-1:0]                 data_bram_addr,
  // input  wire [BATCH_SIZE*DATA_CHANNELS*WIDTH-1:0]                data_bram_wrdata;
  input  wire [BATCH_SIZE*DATA_CHANNELS*WIDTH-1:0]                data_bram_rddata,
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
  output wire [ADDR-1:0]                                          grid_bram_addr,
  // input  wire [WIDTH-1:0]                                         grid_bram_wrdata;
  input  wire [WIDTH-1:0]                                         grid_bram_rddata,
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
  output wire [DATA_CHANNELS*ADDR-1:0]                            scle_bram_addr,
  // input  wire [DATA_CHANNELS*WIDTH-1:0]                           scle_bram_wrdata;
  input  wire [DATA_CHANNELS*WIDTH-1:0]                           scle_bram_rddata,
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
  input wire operation_start,
  input wire [ADDR_WIDTH_DATA-1:0]  data_size,
  input wire [ADDR_WIDTH_GRID-1:0]  grid_size,
  input wire [ADDR_WIDTH_SCALE-1:0] scle_size,
  
  /*
   * Interrupt signals
   */
  output reg operation_in_progress,
  output reg operation_complete,
  output reg operation_error

);
  // Input signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_bram_rdvalid_int;
  wire                                grid_bram_rdvalid_int;
  wire [DATA_CHANNELS-1:0]            scle_bram_rdvalid_int;  // Ignore if BRAM_VALID_SIG == 0

  generate
    if (BRAM_VALID_SIG > 0) begin
      assign data_bram_rdvalid_int = data_bram_rdvalid;
      assign grid_bram_rdvalid_int = grid_bram_rdvalid;
      assign scle_bram_rdvalid_int = scle_bram_rdvalid;
    end else begin
      assign data_bram_rdvalid_int = {BATCH_SIZE*DATA_CHANNELS{1'b1}};
      assign grid_bram_rdvalid_int = 1'b1;
      assign scle_bram_rdvalid_int = {DATA_CHANNELS{1'b1}};
    end
  endgenerate

  // Control Registers & Wires
  reg  op_in_progress_reg = 1'b0;
  reg  [ADDR_WIDTH_DATA-1:0]  data_size_reg;
  reg  [ADDR_WIDTH_GRID-1:0]  grid_size_reg;
  reg  [ADDR_WIDTH_SCALE-1:0] scle_size_reg;

  // Local FSM states
  localparam LOC_FSM_WIDTH = 3;
  localparam LOC_FSM_ST0 = 0;
  localparam LOC_FSM_STR = 1;
  localparam LOC_FSM_OPE = 2;
  localparam LOC_FSM_END = 3;
  localparam LOC_FSM_ERR = 4;

  // Local FSM output signals
  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_tlast_transmitted;
  wire                                grid_tlast_transmitted;
  wire [SCALE_CHANNELS-1:0]           scle_tlast_transmitted;

  wire [BATCH_SIZE*DATA_CHANNELS-1:0] data_error;
  wire                                grid_error;
  wire [SCALE_CHANNELS-1:0]           scle_error;

  // Lobal Scale FSM state logic
  `define LOCAL_FSM_STATE_LOGIC(loc_fsm_state, loc_fsm_state_next, loc_counter_reg, loc_counter_reg_next, get_next) \ 
    assign loc_countera_reg_next = (get_next) : loc_counter_reg + 1 : loc_counter_reg;
    assign loc_counterd_reg_next = (get_next) : loc_counter_reg + 1 : loc_counter_reg;
    always @(posedge clk ) begin
      if (rst) begin
        loc_fsm_state <= LOC_FSM_STR;

        loc_counter_reg <= 0;

      end else begin
        loc_fsm_state   <= loc_fsm_state_next;
        loc_counter_reg <= 0;
        case (loc_fsm_state_next)
          LOC_FSM_STR: begin

          end
          LOC_FSM_OPE: begin
            loc_counter_reg <= loc_counter_reg_next;

          end
          LOC_FSM_END: begin
            loc_counter_reg <= loc_counter_reg_next;
            
          end
          LOC_FSM_ERR: begin
            
          end
          default: begin
            
          end 
        endcase
      end
    end

  // Lobal Scale FSM next state logic
  always @(*) begin
    case (loc_scle_fsm_state)
      LOC_FSM_STR: begin
        `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, fsm_state_next, scle_counter_reg_next, ADDR_WIDTH_SCALE)
      end
      LOC_FSM_OPE: begin

      end
      LOC_FSM_END: begin
        if (op_done) begin
          `LOC_CHECK_OP_START(glo_fsm_state == GLO_FSM_STR, fsm_state_next, scle_counter_reg_next, ADDR_WIDTH_SCALE)
        end
      end
      LOC_FSM_ERR: begin
        loc_scle_fsm_state_next <= LOC_FSM_STR;
        
      end
      default: begin
        loc_scle_fsm_state_next <= loc_scle_fsm_state;
        
      end 
    endcase
    if (internal_error) begin
      loc_scle_fsm_state_next <= LOC_FSM_ERR;
    end
    if (rst) begin
      loc_scle_fsm_state_next <= LOC_FSM_STR;
    end
  end

  // Global FSM states
  localparam GLO_FSM_WIDTH = 3;
  localparam GLO_FSM_ST0 = 0;
  localparam GLO_FSM_STR = 1;
  localparam GLO_FSM_OPE = 2;
  localparam GLO_FSM_END = 3;
  localparam GLO_FSM_ERR = 4;

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
      data_size_reg <= data_size; \
      grid_size_reg <= grid_size; \
      if (SCALE_CHANNELS == 0) begin \
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

  `define LOC_CHECK_OP_START(operation_start, fsm_state_next, counter_reg_next, counter_max, COUNTER_REG_SIZE)\
    if (operation_start) begin \
      counter_reg_next <= {COUNTER_REG_SIZE{1'b0}}; \
      if(counter_max == 0) begin \
        fsm_state_next <= LOC_FSM_ERR; \
      end else if (counter_max == 1) begin \
        fsm_state_next <= LOC_FSM_END; \
      end else begin \
        fsm_state_next <= LOC_FSM_OPE; \
      end \
    end else begin \
      fsm_state_next <= LOC_FSM_STR; \
    end 

 generate
  for (pos = 0; pos < BATCH_SIZE*DATA_CHANNELS; pos = pos + 1) begin
    if (SHARE_SCALE == 0) begin
      reg [ADDR_WIDTH_SCALE-1:0] scle_counter_reg, scle_counter_reg_next;

      // Lobal Scale FSM output signals
      reg  [GLO_FSM_WIDTH-1:0] loc_scle_fsm_state, loc_scle_fsm_state_next;

      
    end
  end
 endgenerate
    
endmodule

`resetall
