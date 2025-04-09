`resetall
`timescale 1ns/1ps
`default_nettype none

module ParallelizedDataProcessor #(
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scale
  parameter FRACTIONAL_BITS_SCALE= 12,
  // Width of AXI stream Input Weight interface in bits
  parameter DATA_WIDTH_WEIGHT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_WEIGHT = 12,
  // Width of Scaled Data in bits
  parameter DATA_WIDTH_SCALED_DIFF = 16,
  // Fractional bits of Scaled Data
  parameter FRACTIONAL_BITS_SCALED_DIFF = 13,
  // Width of Activation Function Data in bits
  parameter DATA_WIDTH_ACT = 16,
  // Fractional bits of Activation Function Data
  parameter FRACTIONAL_BITS_ACT = 16,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH_RSLT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH_RSLT+7)/8) : 1,
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
  parameter SHARE_SCALE = 1,
  // Scale Channels
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Use Common Grid Channel 
  parameter SHARE_GRID = 0,
  // Grid Channels
  parameter GRID_CHANNELS = (SHARE_GRID)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../../data/Sech2Lutram_n_16.12_16.16.txt",
  // Output Destination 
  parameter OUTPUT_DEST = 0,
  // Output Thread ID 
  parameter OUTPUT_ID = 1
) (
  input  wire                            clk,
  input  wire                            rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_CHANNELS*BATCH_SIZE*DATA_WIDTH_DATA-1:0]  s_axis_data_tdata,
  input  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tvalid,
  output wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tready,
  input  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                  s_axis_data_tlast,
  input  wire [DATA_CHANNELS*BATCH_SIZE*ID_WIDTH-1:0]         s_axis_data_tid,
  input  wire [DATA_CHANNELS*BATCH_SIZE*DEST_WIDTH-1:0]       s_axis_data_tdest,
  input  wire [DATA_CHANNELS*BATCH_SIZE*USER_WIDTH-1:0]       s_axis_data_tuser,

  /*      
    * AXI Stream Grid input  wire    
    */      
  input  wire [GRID_CHANNELS*DATA_WIDTH_DATA-1:0]             s_axis_grid_tdata,
  input  wire [GRID_CHANNELS-1:0]                             s_axis_grid_tvalid,
  output wire [GRID_CHANNELS-1:0]                             s_axis_grid_tready,
  input  wire [GRID_CHANNELS-1:0]                             s_axis_grid_tlast,
  input  wire [GRID_CHANNELS*ID_WIDTH-1:0]                    s_axis_grid_tid,
  input  wire [GRID_CHANNELS*DEST_WIDTH-1:0]                  s_axis_grid_tdest,
  input  wire [GRID_CHANNELS*USER_WIDTH-1:0]                  s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0]           s_axis_scale_tdata,
  input  wire [SCALE_CHANNELS-1:0]                            s_axis_scale_tvalid,
  output wire [SCALE_CHANNELS-1:0]                            s_axis_scale_tready,
  input  wire [SCALE_CHANNELS-1:0]                            s_axis_scale_tlast,
  input  wire [SCALE_CHANNELS*ID_WIDTH-1:0]                   s_axis_scale_tid,
  input  wire [SCALE_CHANNELS*DEST_WIDTH-1:0]                 s_axis_scale_tdest,
  input  wire [SCALE_CHANNELS*USER_WIDTH-1:0]                 s_axis_scale_tuser,

  /*
    * AXI Stream Weight input
    */
  input  wire [WEIGHT_CHANNELS*DATA_WIDTH_SCALE-1:0]          s_axis_weight_tdata,
  input  wire [WEIGHT_CHANNELS-1:0]                           s_axis_weight_tvalid,
  output wire [WEIGHT_CHANNELS-1:0]                           s_axis_weight_tready,
  input  wire [WEIGHT_CHANNELS-1:0]                           s_axis_weight_tlast,
  input  wire [WEIGHT_CHANNELS*ID_WIDTH-1:0]                  s_axis_weight_tid,
  input  wire [WEIGHT_CHANNELS*DEST_WIDTH-1:0]                s_axis_weight_tdest,
  input  wire [WEIGHT_CHANNELS*USER_WIDTH-1:0]                s_axis_weight_tuser,

  /*
    * AXI Stream output
    */
  output wire [RSLT_CHANNELS*BATCH_SIZE*DATA_WIDTH_RSLT-1:0]  m_axis_data_tdata,
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
  output wire err_unalligned_data,

  /*
   * Interrupts
   */
  output wire core_rst
);
  // Internal Activation Function Output AXI-Stream Wires
  wire [DATA_CHANNELS*BATCH_SIZE*DATA_WIDTH_ACT-1:0]             int_axis_act_func_tdata;
  wire [DATA_CHANNELS*BATCH_SIZE*KEEP_WIDTH-1:0]                 int_axis_act_func_tkeep;
  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                            int_axis_act_func_tvalid;
  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                            int_axis_act_func_tready;
  wire [DATA_CHANNELS*BATCH_SIZE-1:0]                            int_axis_act_func_tlast;
  wire [DATA_CHANNELS*BATCH_SIZE*ID_WIDTH-1:0]                   int_axis_act_func_tid;
  wire [DATA_CHANNELS*BATCH_SIZE*DEST_WIDTH-1:0]                 int_axis_act_func_tdest;
  wire [DATA_CHANNELS*BATCH_SIZE*USER_WIDTH-1:0]                 int_axis_act_func_tuser;
  
  RSWAFFunction #(
    // Width of AXI stream Input Data & Grid interfaces in bits
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    // Fractional bits of input data & grid
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    // Width of AXI stream Scale interface in bits
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    // Fractional bits of input scale
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    // Width of AXI stream Output Data interface in bits
    .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH_SCALED_DIFF),
    // Fractional bits of output data
    .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
    // Width of AXI stream Output Data interface in bits
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    // Fractional bits of output data
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
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
    .CHANNELS(DATA_CHANNELS*BATCH_SIZE),
    // Use Common Share Channel 
    .SHARE_SCALE(SHARE_SCALE),
    // Scale Channels
    .SCALE_CHANNELS(SCALE_CHANNELS),
    // Use Common Grid Channel 
    .SHARE_GRID(SHARE_GRID),
    // Grid Channels
    .GRID_CHANNELS(GRID_CHANNELS),
    // Path to ROM Data
    .ROM_DATA_PATH(ROM_DATA_PATH)
  ) act_func_inst (
    .clk(clk),
    .rst(core_rst),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tid(s_axis_data_tid),
    .s_axis_data_tdest(s_axis_data_tdest),
    .s_axis_data_tuser(s_axis_data_tuser),
    .s_axis_grid_tdata(s_axis_grid_tdata),
    .s_axis_grid_tvalid(s_axis_grid_tvalid),
    .s_axis_grid_tready(s_axis_grid_tready),
    .s_axis_grid_tlast(s_axis_grid_tlast),
    .s_axis_grid_tid(s_axis_grid_tid),
    .s_axis_grid_tdest(s_axis_grid_tdest),
    .s_axis_grid_tuser(s_axis_grid_tuser),
    .s_axis_scale_tdata(s_axis_scale_tdata),
    .s_axis_scale_tvalid(s_axis_scale_tvalid),
    .s_axis_scale_tready(s_axis_scale_tready),
    .s_axis_scale_tlast(s_axis_scale_tlast),
    .s_axis_scale_tid(s_axis_scale_tid),
    .s_axis_scale_tdest(s_axis_scale_tdest),
    .s_axis_scale_tuser(s_axis_scale_tuser),
    .m_axis_data_tdata(int_axis_act_func_tdata),
    // .m_axis_data_tkeep(int_axis_act_func_tkeep),
    .m_axis_data_tvalid(int_axis_act_func_tvalid),
    .m_axis_data_tready(int_axis_act_func_tready),
    .m_axis_data_tlast(int_axis_act_func_tlast),
    .m_axis_data_tid(int_axis_act_func_tid),
    .m_axis_data_tdest(int_axis_act_func_tdest),
    .m_axis_data_tuser(int_axis_act_func_tuser)
  );

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
    .DATA_WIDTH_OP0(DATA_WIDTH_ACT),
    // Fractional Bits of Input Data (L-AXIS)
    .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_ACT),
    // Treat operand 0 as unsigned
    .IS_UNSIGNED_OP0(1),
    // Data Width of Input Weights (U-AXIS)
    .DATA_WIDTH_OP1(DATA_WIDTH_WEIGHT),
    // Fractional Bits of Input Weights (U-AXIS)
    .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_WEIGHT),
    // Treat operand 1 as unsigned
    .IS_UNSIGNED_OP1(0),
    // Data Width of Output Data (D-AXIS)
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    // Fractional Bits of Output Data (D-AXIS)
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
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
    // Output Destination 
    .OUTPUT_DEST(OUTPUT_DEST),
    // Output Thread ID 
    .OUTPUT_ID(OUTPUT_ID)
  ) parallelized_lpa_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_t_tdata(s_axis_weight_tdata),
    .s_axis_t_tvalid(s_axis_weight_tvalid),
    .s_axis_t_tready(s_axis_weight_tready),
    .s_axis_t_tlast(s_axis_weight_tlast),
    .s_axis_t_tid(s_axis_weight_tid),
    .s_axis_t_tdest(s_axis_weight_tdest),
    .s_axis_t_tuser(s_axis_weight_tuser),
    .s_axis_l_tdata(int_axis_act_func_tdata),
    .s_axis_l_tvalid(int_axis_act_func_tvalid),
    .s_axis_l_tready(int_axis_act_func_tready),
    .s_axis_l_tlast(int_axis_act_func_tlast),
    .s_axis_l_tid(int_axis_act_func_tid),
    .s_axis_l_tdest(int_axis_act_func_tdest),
    .s_axis_l_tuser(int_axis_act_func_tuser),
    .m_axis_d_tdata(m_axis_data_tdata),
    .m_axis_d_tvalid(m_axis_data_tvalid),
    .m_axis_d_tready(m_axis_data_tready),
    .m_axis_d_tlast(m_axis_data_tlast),
    .m_axis_d_tid(m_axis_data_tid),
    .m_axis_d_tdest(m_axis_data_tdest),
    .m_axis_d_tuser(m_axis_data_tuser),
    .err_unalligned_data(err_unalligned_data),
    .core_rst(core_rst)
  );

endmodule

`resetall
