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
  parameter ACTF_WIDTH = 16,
  // Fractional bits of Activation Function Data
  parameter ACTF_FRACTIONAL_BITS = 16,
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
  parameter INPUT_FIFO_DEPTH = 0,
  // Internal FIFO size
  parameter INTERNAL_FIFO_DEPTH = 0,
  // Reset Pipeline Level
  parameter RESET_PIPELINE_LEVEL = 3
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
  input  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]              s_axis_wght_tdata,
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
  localparam RSLT_CHANNELS_OUT = RSLT_CHANNELS*BATCH_SIZE;

  // Internal Activation Function I/O AXI-Stream Wires
  wire [DATA_CHANNELS_OUT*DATA_WIDTH-1:0]       int_rbf_data_s_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_data_s_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_data_s_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_data_s_axis_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]         int_rbf_data_s_axis_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]       int_rbf_data_s_axis_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]       int_rbf_data_s_axis_tuser;

  wire [GRID_CHANNELS*DATA_WIDTH-1:0]           int_rbf_grid_s_axis_tdata;
  wire [GRID_CHANNELS-1:0]                      int_rbf_grid_s_axis_tvalid;
  wire [GRID_CHANNELS-1:0]                      int_rbf_grid_s_axis_tready;
  wire [GRID_CHANNELS-1:0]                      int_rbf_grid_s_axis_tlast;
  wire [GRID_CHANNELS*ID_WIDTH-1:0]             int_rbf_grid_s_axis_tid;
  wire [GRID_CHANNELS*DEST_WIDTH-1:0]           int_rbf_grid_s_axis_tdest;
  wire [GRID_CHANNELS*USER_WIDTH-1:0]           int_rbf_grid_s_axis_tuser;

  wire [SCALE_CHANNELS*SCALE_WIDTH-1:0]         int_rbf_scle_s_axis_tdata;
  wire [SCALE_CHANNELS-1:0]                     int_rbf_scle_s_axis_tvalid;
  wire [SCALE_CHANNELS-1:0]                     int_rbf_scle_s_axis_tready;
  wire [SCALE_CHANNELS-1:0]                     int_rbf_scle_s_axis_tlast;
  wire [SCALE_CHANNELS*ID_WIDTH-1:0]            int_rbf_scle_s_axis_tid;
  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]          int_rbf_scle_s_axis_tdest;
  wire [SCALE_CHANNELS*USER_WIDTH-1:0]          int_rbf_scle_s_axis_tuser;

  wire [DATA_CHANNELS_OUT*ACTF_WIDTH-1:0]       int_rbf_actf_m_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_actf_m_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_actf_m_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                  int_rbf_actf_m_axis_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]         int_rbf_actf_m_axis_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]       int_rbf_actf_m_axis_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]       int_rbf_actf_m_axis_tuser;  

  // Internal Activation Function SRL-FIFO Input/Output AXI-Stream Wires
  wire [DATA_CHANNELS_OUT*ACTF_WIDTH-1:0]       int_srl_actf_s_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_s_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_s_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_s_axis_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]         int_srl_actf_s_axis_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]       int_srl_actf_s_axis_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]       int_srl_actf_s_axis_tuser;
  
  wire [DATA_CHANNELS_OUT*ACTF_WIDTH-1:0]       int_srl_actf_m_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_m_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_m_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                  int_srl_actf_m_axis_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]         int_srl_actf_m_axis_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]       int_srl_actf_m_axis_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]       int_srl_actf_m_axis_tuser;

  // Internal Weight SRL-FIFO Input/Output AXI-Stream Wires
  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_srl_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_s_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_s_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_s_axis_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           int_srl_wght_s_axis_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         int_srl_wght_s_axis_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         int_srl_wght_s_axis_tuser;

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_srl_wght_m_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_m_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_m_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_srl_wght_m_axis_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           int_srl_wght_m_axis_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         int_srl_wght_m_axis_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         int_srl_wght_m_axis_tuser;

  // Internal Linear Processing Cube Input/Output AXI-Stream Wires
  wire [DATA_CHANNELS_OUT*ACTF_WIDTH-1:0]       int_lpc_actf_s_axis_tdata;
  wire [DATA_CHANNELS_OUT-1:0]                  int_lpc_actf_s_axis_tvalid;
  wire [DATA_CHANNELS_OUT-1:0]                  int_lpc_actf_s_axis_tready;
  wire [DATA_CHANNELS_OUT-1:0]                  int_lpc_actf_s_axis_tlast;
  wire [DATA_CHANNELS_OUT*ID_WIDTH-1:0]         int_lpc_actf_s_axis_tid;
  wire [DATA_CHANNELS_OUT*DEST_WIDTH-1:0]       int_lpc_actf_s_axis_tdest;
  wire [DATA_CHANNELS_OUT*USER_WIDTH-1:0]       int_lpc_actf_s_axis_tuser;

  wire [WEIGHT_CHANNELS*WEIGHT_WIDTH-1:0]       int_lpc_wght_s_axis_tdata;
  wire [WEIGHT_CHANNELS-1:0]                    int_lpc_wght_s_axis_tvalid;
  wire [WEIGHT_CHANNELS-1:0]                    int_lpc_wght_s_axis_tready;
  wire [WEIGHT_CHANNELS-1:0]                    int_lpc_wght_s_axis_tlast;
  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]           int_lpc_wght_s_axis_tid;
  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]         int_lpc_wght_s_axis_tdest;
  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]         int_lpc_wght_s_axis_tuser;

  wire [RSLT_CHANNELS_OUT*RSLT_WIDTH-1:0]       int_lpc_rslt_m_axis_tdata;
  wire [RSLT_CHANNELS_OUT-1:0]                  int_lpc_rslt_m_axis_tvalid;
  wire [RSLT_CHANNELS_OUT-1:0]                  int_lpc_rslt_m_axis_tready;
  wire [RSLT_CHANNELS_OUT-1:0]                  int_lpc_rslt_m_axis_tlast;
  wire [RSLT_CHANNELS_OUT*ID_WIDTH-1:0]         int_lpc_rslt_m_axis_tid;
  wire [RSLT_CHANNELS_OUT*DEST_WIDTH-1:0]       int_lpc_rslt_m_axis_tdest;
  wire [RSLT_CHANNELS_OUT*USER_WIDTH-1:0]       int_lpc_rslt_m_axis_tuser;

  // Activation Function Block
  RadialBasisFunctionUnit #(
    .DATA_WIDTH                   (DATA_WIDTH),
    .DATA_FRACTIONAL_BITS         (DATA_FRACTIONAL_BITS),
    .SCALE_WIDTH                  (SCALE_WIDTH),
    .SCALE_FRACTIONAL_BITS        (SCALE_FRACTIONAL_BITS),
    .SCALED_DIFF_WIDTH            (SCALED_DIFF_WIDTH),
    .SCALED_DIFF_FRACTIONAL_BITS  (SCALED_DIFF_FRACTIONAL_BITS),     
    .RSLT_WIDTH                   (ACTF_WIDTH),
    .RSLT_FRACTIONAL_BITS         (ACTF_FRACTIONAL_BITS),
    .ID_ENABLE                    (ID_ENABLE),                         
    .ID_WIDTH                     (ID_WIDTH),                       
    .DEST_ENABLE                  (DEST_ENABLE),
    .DEST_WIDTH                   (DEST_WIDTH),
    .USER_ENABLE                  (USER_ENABLE),
    .USER_WIDTH                   (USER_WIDTH),
    .CHANNELS                     (DATA_CHANNELS_OUT),                       
    .SCALE_SHARE                  (SCALE_SHARE),
    .SCALE_CHANNELS               (SCALE_CHANNELS),
    .GRID_SHARE                   (GRID_SHARE),
    .GRID_CHANNELS                (GRID_CHANNELS),
    .ROM_DATA_PATH                (ROM_DATA_PATH),
    .FIFO_DEPTH                   (INPUT_FIFO_DEPTH)
  ) rbf_inst (
    .clk                          (clk),
    .rst                          (core_rst),
    .s_axis_data_tdata            (int_rbf_data_s_axis_tdata),
    .s_axis_data_tvalid           (int_rbf_data_s_axis_tvalid),
    .s_axis_data_tready           (int_rbf_data_s_axis_tready),
    .s_axis_data_tlast            (int_rbf_data_s_axis_tlast),
    .s_axis_data_tid              (int_rbf_data_s_axis_tid),
    .s_axis_data_tdest            (int_rbf_data_s_axis_tdest),
    .s_axis_data_tuser            (int_rbf_data_s_axis_tuser),
    .s_axis_grid_tdata            (int_rbf_grid_s_axis_tdata),
    .s_axis_grid_tvalid           (int_rbf_grid_s_axis_tvalid),
    .s_axis_grid_tready           (int_rbf_grid_s_axis_tready),
    .s_axis_grid_tlast            (int_rbf_grid_s_axis_tlast),
    .s_axis_grid_tid              (int_rbf_grid_s_axis_tid),
    .s_axis_grid_tdest            (int_rbf_grid_s_axis_tdest),
    .s_axis_grid_tuser            (int_rbf_grid_s_axis_tuser),
    .s_axis_scle_tdata            (int_rbf_scle_s_axis_tdata),
    .s_axis_scle_tvalid           (int_rbf_scle_s_axis_tvalid),
    .s_axis_scle_tready           (int_rbf_scle_s_axis_tready),
    .s_axis_scle_tlast            (int_rbf_scle_s_axis_tlast),
    .s_axis_scle_tid              (int_rbf_scle_s_axis_tid),
    .s_axis_scle_tdest            (int_rbf_scle_s_axis_tdest),
    .s_axis_scle_tuser            (int_rbf_scle_s_axis_tuser),
    .m_axis_data_tdata            (int_rbf_actf_m_axis_tdata),
    .m_axis_data_tvalid           (int_rbf_actf_m_axis_tvalid),
    .m_axis_data_tready           (int_rbf_actf_m_axis_tready),
    .m_axis_data_tlast            (int_rbf_actf_m_axis_tlast),
    .m_axis_data_tid              (int_rbf_actf_m_axis_tid),
    .m_axis_data_tdest            (int_rbf_actf_m_axis_tdest),
    .m_axis_data_tuser            (int_rbf_actf_m_axis_tuser)
  );

  // SRL-FIFO Blocks
 genvar CHN;
 generate if (INTERNAL_FIFO_DEPTH > 0) begin : internal_fifo_genblock
  for (CHN = 0; CHN < DATA_CHANNELS_OUT; CHN = CHN + 1) begin : actf_axis_srl_fifo_genblock
    // Activation Function SRL-FIFO Block per channel
    axis_srl_fifo #(
      .DATA_WIDTH         (ACTF_WIDTH),
      .KEEP_ENABLE        (0),
      .KEEP_WIDTH         (1),
      .LAST_ENABLE        (1),
      .ID_ENABLE          (ID_ENABLE),
      .ID_WIDTH           (ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .DEPTH              (INTERNAL_FIFO_DEPTH)
    ) axis_fifo_actf_inst (
      .clk                (clk),
      .rst                (core_rst),
      .s_axis_tdata       (int_srl_actf_s_axis_tdata    [CHN*ACTF_WIDTH +: ACTF_WIDTH]),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (int_srl_actf_s_axis_tvalid   [CHN]),
      .s_axis_tready      (int_srl_actf_s_axis_tready   [CHN]),
      .s_axis_tlast       (int_srl_actf_s_axis_tlast    [CHN]),
      .s_axis_tid         (int_srl_actf_s_axis_tid      [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .s_axis_tdest       (int_srl_actf_s_axis_tdest    [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .s_axis_tuser       (int_srl_actf_s_axis_tuser    [CHN*USER_WIDTH +: USER_WIDTH]),
      .m_axis_tdata       (int_srl_actf_m_axis_tdata    [CHN*ACTF_WIDTH +: ACTF_WIDTH]),
      .m_axis_tvalid      (int_srl_actf_m_axis_tvalid   [CHN]),
      .m_axis_tready      (int_srl_actf_m_axis_tready   [CHN]),
      .m_axis_tlast       (int_srl_actf_m_axis_tlast    [CHN]),
      .m_axis_tid         (int_srl_actf_m_axis_tid      [CHN*  ID_WIDTH +:   ID_WIDTH]),
      .m_axis_tdest       (int_srl_actf_m_axis_tdest    [CHN*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (int_srl_actf_m_axis_tuser    [CHN*USER_WIDTH +: USER_WIDTH])
    );
  end
    
  for (CHN = 0; CHN < WEIGHT_CHANNELS; CHN = CHN + 1) begin : axis_srl_wght_genblock
    // Weight SRL-FIFO Block per channel
    axis_srl_fifo #(
      .DATA_WIDTH         (WEIGHT_WIDTH),
      .KEEP_ENABLE        (0),
      .KEEP_WIDTH         (1),
      .LAST_ENABLE        (1),
      .ID_ENABLE          (ID_ENABLE),
      .ID_WIDTH           (ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .DEPTH              (INTERNAL_FIFO_DEPTH)
    ) axis_fifo_data_inst (
      .clk                (clk),
      .rst                (core_rst),
      .s_axis_tdata       (int_srl_wght_s_axis_tdata    [CHN*WEIGHT_WIDTH  +: WEIGHT_WIDTH]),
      .s_axis_tkeep       (1'b1),
      .s_axis_tvalid      (int_srl_wght_s_axis_tvalid   [CHN]),
      .s_axis_tready      (int_srl_wght_s_axis_tready   [CHN]),
      .s_axis_tlast       (int_srl_wght_s_axis_tlast    [CHN]),
      .s_axis_tid         (int_srl_wght_s_axis_tid      [CHN*  ID_WIDTH    +:   ID_WIDTH]),
      .s_axis_tdest       (int_srl_wght_s_axis_tdest    [CHN*DEST_WIDTH    +: DEST_WIDTH]),
      .s_axis_tuser       (int_srl_wght_s_axis_tuser    [CHN*USER_WIDTH    +: USER_WIDTH]),
      .m_axis_tdata       (int_srl_wght_m_axis_tdata    [CHN*WEIGHT_WIDTH  +: WEIGHT_WIDTH]),
      .m_axis_tvalid      (int_srl_wght_m_axis_tvalid   [CHN]),
      .m_axis_tready      (int_srl_wght_m_axis_tready   [CHN]),
      .m_axis_tlast       (int_srl_wght_m_axis_tlast    [CHN]),
      .m_axis_tid         (int_srl_wght_m_axis_tid      [CHN*  ID_WIDTH    +:   ID_WIDTH]),
      .m_axis_tdest       (int_srl_wght_m_axis_tdest    [CHN*DEST_WIDTH    +: DEST_WIDTH]),
      .m_axis_tuser       (int_srl_wght_m_axis_tuser    [CHN*USER_WIDTH    +: USER_WIDTH])
    );
  end
 end else begin : internal_skip_fifo_genblock
    // Activation Function skip SRL-FIFO Block per channel
    assign int_srl_actf_m_axis_tdata  = int_srl_actf_s_axis_tdata;
    assign int_srl_actf_m_axis_tvalid = int_srl_actf_s_axis_tvalid;
    assign int_srl_actf_s_axis_tready = int_srl_actf_m_axis_tready;
    assign int_srl_actf_m_axis_tlast  = int_srl_actf_s_axis_tlast;
    assign int_srl_actf_m_axis_tid    = int_srl_actf_s_axis_tid;
    assign int_srl_actf_m_axis_tdest  = int_srl_actf_s_axis_tdest;
    assign int_srl_actf_m_axis_tuser  = int_srl_actf_s_axis_tuser;

    // Weight skip SRL-FIFO Block per channel
    assign int_srl_wght_m_axis_tdata  = int_srl_wght_s_axis_tdata;
    assign int_srl_wght_m_axis_tvalid = int_srl_wght_s_axis_tvalid;
    assign int_srl_wght_s_axis_tready = int_srl_wght_m_axis_tready;
    assign int_srl_wght_m_axis_tlast  = int_srl_wght_s_axis_tlast;
    assign int_srl_wght_m_axis_tid    = int_srl_wght_s_axis_tid;
    assign int_srl_wght_m_axis_tdest  = int_srl_wght_s_axis_tdest;
    assign int_srl_wght_m_axis_tuser  = int_srl_wght_s_axis_tuser;
  end
 endgenerate

  // Linear Processing Cube Block
  ParallelizedLinearProcessingArray #(
    .DATA_CHANNELS        (DATA_CHANNELS),
    .RSLT_CHANNELS        (RSLT_CHANNELS),
    .BATCH_SIZE           (BATCH_SIZE),
    .INTERNAL_RESET       (1'b1),
    .OP0_WIDTH            (ACTF_WIDTH),
    .OP0_FRACTIONAL_BITS  (ACTF_FRACTIONAL_BITS),
    .IS_UNSIGNED_OP0      (1),
    .OP1_WIDTH            (WEIGHT_WIDTH),
    .OP1_FRACTIONAL_BITS  (WEIGHT_FRACTIONAL_BITS),
    .IS_UNSIGNED_OP1      (0),
    .RSLT_WIDTH           (RSLT_WIDTH),
    .RSLT_FRACTIONAL_BITS (RSLT_FRACTIONAL_BITS),
    .ID_ENABLE            (ID_ENABLE),
    .ID_WIDTH             (ID_WIDTH),
    .DEST_ENABLE          (DEST_ENABLE),
    .DEST_WIDTH           (DEST_WIDTH),
    .USER_ENABLE          (USER_ENABLE),
    .USER_WIDTH           (USER_WIDTH),
    .OUTPUT_USER          (OUTPUT_USER),
    .OUTPUT_DEST          (OUTPUT_DEST),
    .OUTPUT_ID            (OUTPUT_ID),
    .RESET_PIPELINE_LEVEL (RESET_PIPELINE_LEVEL)
  ) lpc_inst (
    .clk                  (clk),
    .rst                  (rst),
    .s_axis_op0_tdata     (int_lpc_actf_s_axis_tdata),
    .s_axis_op0_tvalid    (int_lpc_actf_s_axis_tvalid),
    .s_axis_op0_tready    (int_lpc_actf_s_axis_tready),
    .s_axis_op0_tlast     (int_lpc_actf_s_axis_tlast),
    .s_axis_op0_tid       (int_lpc_actf_s_axis_tid),
    .s_axis_op0_tdest     (int_lpc_actf_s_axis_tdest),
    .s_axis_op0_tuser     (int_lpc_actf_s_axis_tuser),
    .s_axis_op1_tdata     (int_lpc_wght_s_axis_tdata),
    .s_axis_op1_tvalid    (int_lpc_wght_s_axis_tvalid),
    .s_axis_op1_tready    (int_lpc_wght_s_axis_tready),
    .s_axis_op1_tlast     (int_lpc_wght_s_axis_tlast),
    .s_axis_op1_tid       (int_lpc_wght_s_axis_tid),
    .s_axis_op1_tdest     (int_lpc_wght_s_axis_tdest),
    .s_axis_op1_tuser     (int_lpc_wght_s_axis_tuser),
    .m_axis_tdata         (int_lpc_rslt_m_axis_tdata),
    .m_axis_tvalid        (int_lpc_rslt_m_axis_tvalid),
    .m_axis_tready        (int_lpc_rslt_m_axis_tready),
    .m_axis_tlast         (int_lpc_rslt_m_axis_tlast),
    .m_axis_tid           (int_lpc_rslt_m_axis_tid),
    .m_axis_tdest         (int_lpc_rslt_m_axis_tdest),
    .m_axis_tuser         (int_lpc_rslt_m_axis_tuser),
    .err_unalligned_data  (err_unalligned_data),
    .core_rst             (core_rst)
  );
  
  // Connect input data streams with RBF unit
  assign int_rbf_data_s_axis_tdata  = s_axis_data_tdata;
  assign int_rbf_data_s_axis_tvalid = s_axis_data_tvalid;
  assign s_axis_data_tready = int_rbf_data_s_axis_tready;
  assign int_rbf_data_s_axis_tlast  = s_axis_data_tlast;
  assign int_rbf_data_s_axis_tid    = s_axis_data_tid;
  assign int_rbf_data_s_axis_tdest  = s_axis_data_tdest;
  assign int_rbf_data_s_axis_tuser  = s_axis_data_tuser;

  // Connect input grid streams with RBF unit
  assign int_rbf_grid_s_axis_tdata  = s_axis_grid_tdata;
  assign int_rbf_grid_s_axis_tvalid = s_axis_grid_tvalid;
  assign s_axis_grid_tready = int_rbf_grid_s_axis_tready;
  assign int_rbf_grid_s_axis_tlast  = s_axis_grid_tlast;
  assign int_rbf_grid_s_axis_tid    = s_axis_grid_tid;
  assign int_rbf_grid_s_axis_tdest  = s_axis_grid_tdest;
  assign int_rbf_grid_s_axis_tuser  = s_axis_grid_tuser;

  // Connect input scale streams with RBF unit
  assign int_rbf_scle_s_axis_tdata  = s_axis_scle_tdata;
  assign int_rbf_scle_s_axis_tvalid = s_axis_scle_tvalid;
  assign s_axis_scle_tready = int_rbf_scle_s_axis_tready;
  assign int_rbf_scle_s_axis_tlast  = s_axis_scle_tlast;
  assign int_rbf_scle_s_axis_tid    = s_axis_scle_tid;
  assign int_rbf_scle_s_axis_tdest  = s_axis_scle_tdest;
  assign int_rbf_scle_s_axis_tuser  = s_axis_scle_tuser;

  // Connect RBF unit results with SRL-FIFOs
  assign int_srl_actf_s_axis_tdata  = int_rbf_actf_m_axis_tdata;
  assign int_srl_actf_s_axis_tvalid = int_rbf_actf_m_axis_tvalid;
  assign int_rbf_actf_m_axis_tready = int_srl_actf_s_axis_tready;
  assign int_srl_actf_s_axis_tlast  = int_rbf_actf_m_axis_tlast;
  assign int_srl_actf_s_axis_tid    = int_rbf_actf_m_axis_tid;
  assign int_srl_actf_s_axis_tdest  = int_rbf_actf_m_axis_tdest;
  assign int_srl_actf_s_axis_tuser  = int_rbf_actf_m_axis_tuser;

  // Connect input weight streams with SRL-FIFOs
  assign int_srl_wght_s_axis_tdata  = s_axis_wght_tdata;
  assign int_srl_wght_s_axis_tvalid = s_axis_wght_tvalid;
  assign s_axis_wght_tready = int_srl_wght_s_axis_tready;
  assign int_srl_wght_s_axis_tlast  = s_axis_wght_tlast;
  assign int_srl_wght_s_axis_tid    = s_axis_wght_tid;
  assign int_srl_wght_s_axis_tdest  = s_axis_wght_tdest;
  assign int_srl_wght_s_axis_tuser  = s_axis_wght_tuser;

  // Connect SRL-FIFO activation function results with LPC
  assign int_lpc_actf_s_axis_tdata  = int_srl_actf_m_axis_tdata;
  assign int_lpc_actf_s_axis_tvalid = int_srl_actf_m_axis_tvalid;
  assign int_srl_actf_m_axis_tready = int_lpc_actf_s_axis_tready;
  assign int_lpc_actf_s_axis_tlast  = int_srl_actf_m_axis_tlast;
  assign int_lpc_actf_s_axis_tid    = int_srl_actf_m_axis_tid;
  assign int_lpc_actf_s_axis_tdest  = int_srl_actf_m_axis_tdest;
  assign int_lpc_actf_s_axis_tuser  = int_srl_actf_m_axis_tuser;

  // Connect SRL-FIFO weights with LPC
  assign int_lpc_wght_s_axis_tdata  = int_srl_wght_m_axis_tdata;
  assign int_lpc_wght_s_axis_tvalid = int_srl_wght_m_axis_tvalid;
  assign int_srl_wght_m_axis_tready = int_lpc_wght_s_axis_tready;
  assign int_lpc_wght_s_axis_tlast  = int_srl_wght_m_axis_tlast;
  assign int_lpc_wght_s_axis_tid    = int_srl_wght_m_axis_tid;
  assign int_lpc_wght_s_axis_tdest  = int_srl_wght_m_axis_tdest;
  assign int_lpc_wght_s_axis_tuser  = int_srl_wght_m_axis_tuser;

  // Connect LPC results with output result streams
  assign m_axis_data_tdata  = int_lpc_rslt_m_axis_tdata;
  assign m_axis_data_tvalid = int_lpc_rslt_m_axis_tvalid;
  assign int_lpc_rslt_m_axis_tready = m_axis_data_tready;
  assign m_axis_data_tlast  = int_lpc_rslt_m_axis_tlast;
  assign m_axis_data_tid    = int_lpc_rslt_m_axis_tid;
  assign m_axis_data_tdest  = int_lpc_rslt_m_axis_tdest;
  assign m_axis_data_tuser  = int_lpc_rslt_m_axis_tuser;
  
  assign m_axis_data_tkeep = -1;

endmodule

`resetall
