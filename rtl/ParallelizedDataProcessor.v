`resetall
`timescale 1ns/1ps
`default_nettype none

module ParallelizedDataProcessor #(
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scale
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Width of AXI stream Input Weight interface in bits
  parameter WEIGHT_WIDTH = 16,
  // Fractional bits of output data
  parameter WEIGHT_FRACTIONAL_BITS = 12,
  // Width of Scaled Data in bits
  parameter SCALED_DIFF_WIDTH = 16,
  // Fractional bits of Scaled Data
  parameter SCALED_DIFF_FRACTIONAL_BITS = 13,
  // Width of Activation Function Data in bits
  parameter ACT_WIDTH = 16,
  // Fractional bits of Activation Function Data
  parameter ACT_FRACTIONAL_BITS = 16,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (RSLT_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((RSLT_WIDTH + 7) / 8) : 1,
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
  // Number of Independent AXI-Stream Data Channels per Batch
  parameter DATA_CHANNELS = 1,
  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Number of Independent AXI-Stream Weight Channels per Batch
  parameter WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS,
  // Use Common Share Channel 
  parameter SCALE_SHARE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SCALE_SHARE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Use Common Grid Channel 
  parameter GRID_SHARE = 0,
  // Grid Channels
  parameter GRID_CHANNELS = (GRID_SHARE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt",
  // Output User
  parameter OUTPUT_USER = 0,
  // Output Destination 
  parameter OUTPUT_DEST = 0,
  // Output Thread ID 
  parameter OUTPUT_ID = 1,
  // Input FIFO size
  parameter FIFO_DEPTH = 0
) (
  input  wire                                                 clk,
  input  wire                                                 rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_CHANNELS*BATCH_SIZE*DATA_WIDTH-1:0]       s_axis_data_tdata,
  input  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tvalid,
  output wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tready,
  input  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tlast,
  input  wire [DATA_CHANNELS*BATCH_SIZE*ID_WIDTH-1:0]         s_axis_data_tid,
  input  wire [DATA_CHANNELS*BATCH_SIZE*DEST_WIDTH-1:0]       s_axis_data_tdest,
  input  wire [DATA_CHANNELS*BATCH_SIZE*USER_WIDTH-1:0]       s_axis_data_tuser,

  /*      
    * AXI Stream Grid input  wire    
    */      
  input  wire [GRID_CHANNELS*DATA_WIDTH-1:0]                  s_axis_grid_tdata,
  input  wire [GRID_CHANNELS-1:0]                             s_axis_grid_tvalid,
  output wire [GRID_CHANNELS-1:0]                             s_axis_grid_tready,
  input  wire [GRID_CHANNELS-1:0]                             s_axis_grid_tlast,
  input  wire [GRID_CHANNELS*ID_WIDTH-1:0]                    s_axis_grid_tid,
  input  wire [GRID_CHANNELS*DEST_WIDTH-1:0]                  s_axis_grid_tdest,
  input  wire [GRID_CHANNELS*USER_WIDTH-1:0]                  s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [SCALE_CHANNELS*SCALE_WIDTH-1:0]                s_axis_scle_tdata,
  input  wire [SCALE_CHANNELS-1:0]                            s_axis_scle_tvalid,
  output wire [SCALE_CHANNELS-1:0]                            s_axis_scle_tready,
  input  wire [SCALE_CHANNELS-1:0]                            s_axis_scle_tlast,
  input  wire [SCALE_CHANNELS*ID_WIDTH-1:0]                   s_axis_scle_tid,
  input  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]                 s_axis_scle_tdest,
  input  wire [SCALE_CHANNELS*USER_WIDTH-1:0]                 s_axis_scle_tuser,

  /*
    * AXI Stream Weight input
    */
  input  wire [WEIGHT_CHANNELS*SCALE_WIDTH-1:0]               s_axis_wght_tdata,
  input  wire [WEIGHT_CHANNELS-1:0]                           s_axis_wght_tvalid,
  output wire [WEIGHT_CHANNELS-1:0]                           s_axis_wght_tready,
  input  wire [WEIGHT_CHANNELS-1:0]                           s_axis_wght_tlast,
  input  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]                  s_axis_wght_tid,
  input  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]                s_axis_wght_tdest,
  input  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]                s_axis_wght_tuser,

  /*
    * AXI Stream output
    */
  output wire [RSLT_CHANNELS*BATCH_SIZE*RSLT_WIDTH-1:0]       m_axis_data_tdata,
  output wire [RSLT_CHANNELS*BATCH_SIZE*KEEP_WIDTH-1:0]       m_axis_data_tkeep,
  output wire [RSLT_CHANNELS*BATCH_SIZE-1:0]                  m_axis_data_tvalid,
  input  wire [RSLT_CHANNELS*BATCH_SIZE-1:0]                  m_axis_data_tready,
  output wire [RSLT_CHANNELS*BATCH_SIZE-1:0]                  m_axis_data_tlast,
  output wire [RSLT_CHANNELS*BATCH_SIZE*ID_WIDTH-1:0]         m_axis_data_tid,
  output wire [RSLT_CHANNELS*BATCH_SIZE*DEST_WIDTH-1:0]       m_axis_data_tdest,
  output wire [RSLT_CHANNELS*BATCH_SIZE*USER_WIDTH-1:0]       m_axis_data_tuser,

  /*
   * Error Outputs
   */
  output wire                                                 err_unalligned_data,

  /*
   * Interrupts
   */
  output wire                                                 core_rst
);
  localparam DATA_CHANNELS_OUT = DATA_CHANNELS*BATCH_SIZE;
  // Internal Activation Function Output AXI-Stream Wires
  wire [DATA_CHANNELS_OUT*ACT_WIDTH-1:0]       int_axis_act_func_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_act_func_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_act_func_tready;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_act_func_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]        int_axis_act_func_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]      int_axis_act_func_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]      int_axis_act_func_tuser;

  wire [DATA_CHANNELS_OUT*ACT_WIDTH-1:0]       int_axis_srl_func_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_srl_func_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_srl_func_tready;
  wire [DATA_CHANNELS_OUT-1:0]                 int_axis_srl_func_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]        int_axis_srl_func_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]      int_axis_srl_func_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]      int_axis_srl_func_tuser;
  
  RSWAFFunction #(
    // Width of AXI stream Input Data & Grid interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Fractional bits of input data & grid
    .DATA_FRACTIONAL_BITS(DATA_FRACTIONAL_BITS),
    // Width of AXI stream Scale interface in bits
    .SCALE_WIDTH(SCALE_WIDTH),
    // Fractional bits of input scale
    .SCALE_FRACTIONAL_BITS(SCALE_FRACTIONAL_BITS),
    // Width of AXI stream Output Data interface in bits
    .SCALED_DIFF_WIDTH(SCALED_DIFF_WIDTH),
    // Fractional bits of output data
    .SCALED_DIFF_FRACTIONAL_BITS(SCALED_DIFF_FRACTIONAL_BITS),
    // Width of AXI stream Output Data interface in bits
    .RSLT_WIDTH(RSLT_WIDTH),
    // Fractional bits of output data
    .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
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
    // Number of Independent AXI-Stream Channels
    .CHANNELS(DATA_CHANNELS_OUT),
    // Use Common Share Channel 
    .SCALE_SHARE(SCALE_SHARE),
    // Scale Channels
    .SCALE_CHANNELS(SCALE_CHANNELS),
    // Use Common Grid Channel 
    .GRID_SHARE(GRID_SHARE),
    // Grid Channels
    .GRID_CHANNELS(GRID_CHANNELS),
    // Path to ROM Data
    .ROM_DATA_PATH(ROM_DATA_PATH),
    // Use FIFO for inputs
    .FIFO_DEPTH(FIFO_DEPTH)
  ) act_func_inst (
    .clk                  (clk),
    .rst                  (core_rst),
    .s_axis_data_tdata    (s_axis_data_tdata),
    .s_axis_data_tvalid   (s_axis_data_tvalid),
    .s_axis_data_tready   (s_axis_data_tready),
    .s_axis_data_tlast    (s_axis_data_tlast),
    .s_axis_data_tid      (s_axis_data_tid),
    .s_axis_data_tdest    (s_axis_data_tdest),
    .s_axis_data_tuser    (s_axis_data_tuser),
    .s_axis_grid_tdata    (s_axis_grid_tdata),
    .s_axis_grid_tvalid   (s_axis_grid_tvalid),
    .s_axis_grid_tready   (s_axis_grid_tready),
    .s_axis_grid_tlast    (s_axis_grid_tlast),
    .s_axis_grid_tid      (s_axis_grid_tid),
    .s_axis_grid_tdest    (s_axis_grid_tdest),
    .s_axis_grid_tuser    (s_axis_grid_tuser),
    .s_axis_scle_tdata    (s_axis_scle_tdata),
    .s_axis_scle_tvalid   (s_axis_scle_tvalid),
    .s_axis_scle_tready   (s_axis_scle_tready),
    .s_axis_scle_tlast    (s_axis_scle_tlast),
    .s_axis_scle_tid      (s_axis_scle_tid),
    .s_axis_scle_tdest    (s_axis_scle_tdest),
    .s_axis_scle_tuser    (s_axis_scle_tuser),
    .m_axis_data_tdata    (int_axis_act_func_tdata),
    .m_axis_data_tvalid   (int_axis_act_func_tvalid),
    .m_axis_data_tready   (int_axis_act_func_tready),
    .m_axis_data_tlast    (int_axis_act_func_tlast),
    .m_axis_data_tid      (int_axis_act_func_tid),
    .m_axis_data_tdest    (int_axis_act_func_tdest),
    .m_axis_data_tuser    (int_axis_act_func_tuser)
  );

 genvar CHN;
 generate for (CHN = 0; CHN < DATA_CHANNELS_OUT; CHN = CHN + 1) begin
  axis_srl_fifo #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(ACT_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
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
    // FIFO depth in cycles
    .DEPTH(4)
  ) fifo_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (int_axis_act_func_tdata    [CHN*ACT_WIDTH +: ACT_WIDTH]),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (int_axis_act_func_tvalid   [CHN]),
    .s_axis_tready    (int_axis_act_func_tready   [CHN]),
    .s_axis_tlast     (int_axis_act_func_tlast    [CHN]),
    .s_axis_tid       (int_axis_act_func_tid      [CHN*ID_WIDTH   +: ID_WIDTH]),
    .s_axis_tdest     (int_axis_act_func_tdest    [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .s_axis_tuser     (int_axis_act_func_tuser    [CHN*USER_WIDTH +: USER_WIDTH]),
    .m_axis_tdata     (int_axis_srl_func_tdata    [CHN*ACT_WIDTH  +: ACT_WIDTH]),
    .m_axis_tvalid    (int_axis_srl_func_tvalid   [CHN]),
    .m_axis_tready    (int_axis_srl_func_tready   [CHN]),
    .m_axis_tlast     (int_axis_srl_func_tlast    [CHN]),
    .m_axis_tid       (int_axis_srl_func_tid      [CHN*ID_WIDTH   +: ID_WIDTH]),
    .m_axis_tdest     (int_axis_srl_func_tdest    [CHN*DEST_WIDTH +: DEST_WIDTH]),
    .m_axis_tuser     (int_axis_srl_func_tuser    [CHN*USER_WIDTH +: USER_WIDTH])
  );
 end
 endgenerate

  ParallelizedLinearProcessingArray #(
    // Number of PEs in Processing Array i axis -- Number of results per batch per run
    .PE_NUMBER_I(RSLT_CHANNELS),
    // Number of PEs in Processing Array j axis -- Number of partial sums per result
    .PE_NUMBER_J(DATA_CHANNELS),
    // Number of PEs in Processing Array k axis -- Number of batches per run
    .BATCH_SIZE(BATCH_SIZE),
    // Enable module to do internal resets
    .INTERNAL_RESET(1'b1),
    // Data Width of Input Data (L-AXIS)
    .OP0_WIDTH(ACT_WIDTH),
    // Fractional Bits of Input Data (L-AXIS)
    .OP0_FRACTIONAL_BITS(ACT_FRACTIONAL_BITS),
    // Treat operand 0 as unsigned
    .IS_UNSIGNED_OP0(1),
    // Data Width of Input Weights (U-AXIS)
    .OP1_WIDTH(WEIGHT_WIDTH),
    // Fractional Bits of Input Weights (U-AXIS)
    .OP1_FRACTIONAL_BITS(WEIGHT_FRACTIONAL_BITS),
    // Treat operand 1 as unsigned
    .IS_UNSIGNED_OP1(0),
    // Data Width of Output Data (D-AXIS)
    .RSLT_WIDTH(RSLT_WIDTH),
    // Fractional Bits of Output Data (D-AXIS)
    .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
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
    // Output User 
    .OUTPUT_USER(OUTPUT_USER),
    // Output Destination 
    .OUTPUT_DEST(OUTPUT_DEST),
    // Output Thread ID 
    .OUTPUT_ID(OUTPUT_ID)
  ) parallelized_lpa_inst (
    .clk                    (clk),
    .rst                    (rst),
    .s_axis_t_tdata         (s_axis_wght_tdata),
    .s_axis_t_tvalid        (s_axis_wght_tvalid),
    .s_axis_t_tready        (s_axis_wght_tready),
    .s_axis_t_tlast         (s_axis_wght_tlast),
    .s_axis_t_tid           (s_axis_wght_tid),
    .s_axis_t_tdest         (s_axis_wght_tdest),
    .s_axis_t_tuser         (s_axis_wght_tuser),
    .s_axis_l_tdata         (int_axis_srl_func_tdata),
    .s_axis_l_tvalid        (int_axis_srl_func_tvalid),
    .s_axis_l_tready        (int_axis_srl_func_tready),
    .s_axis_l_tlast         (int_axis_srl_func_tlast),
    .s_axis_l_tid           (int_axis_srl_func_tid),
    .s_axis_l_tdest         (int_axis_srl_func_tdest),
    .s_axis_l_tuser         (int_axis_srl_func_tuser),
    .m_axis_d_tdata         (m_axis_data_tdata),
    .m_axis_d_tvalid        (m_axis_data_tvalid),
    .m_axis_d_tready        (m_axis_data_tready),
    .m_axis_d_tlast         (m_axis_data_tlast),
    .m_axis_d_tid           (m_axis_data_tid),
    .m_axis_d_tdest         (m_axis_data_tdest),
    .m_axis_d_tuser         (m_axis_data_tuser),
    .err_unalligned_data    (err_unalligned_data),
    .core_rst               (core_rst)
  );

endmodule

`resetall
