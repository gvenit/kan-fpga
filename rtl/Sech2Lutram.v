`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  Sech2Lutram : Accepts an input as address and returns a value
 *    that corresponds to sech^2(x), where x is the input in fixed
 *    point arithmetics (N.Q) as signed or unsigned.
 */

module Sech2Lutram #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output wire data
  parameter RSLT_FRACTIONAL_BITS = 16,
  // Propagate tkeep signal
  parameter DATA_KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter DATA_KEEP_WIDTH = ((DATA_WIDTH + 7) / 8),
  // Propagate tkeep signal
  parameter RSLT_KEEP_ENABLE = (RSLT_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter RSLT_KEEP_WIDTH = ((RSLT_WIDTH + 7) / 8),
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
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.12_16.16.txt"
) (
  input  wire                                 clk,
  input  wire                                 rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]       s_axis_0_tdata,
  output wire [CHANNELS*DATA_KEEP_WIDTH-1:0]  s_axis_0_tkeep,
  input  wire [CHANNELS-1:0]                  s_axis_0_tlast,
  input  wire [CHANNELS-1:0]                  s_axis_0_tvalid,
  output wire [CHANNELS-1:0]                  s_axis_0_tready,
  input  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_0_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_0_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_0_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*RSLT_WIDTH-1:0]       m_axis_0_tdata,
  output wire [CHANNELS*RSLT_KEEP_WIDTH-1:0]  m_axis_0_tkeep,
  output wire [CHANNELS-1:0]                  m_axis_0_tlast,
  output wire [CHANNELS-1:0]                  m_axis_0_tvalid,
  input  wire [CHANNELS-1:0]                  m_axis_0_tready,
  output wire [CHANNELS*ID_WIDTH-1:0]         m_axis_0_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]       m_axis_0_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]       m_axis_0_tuser
);
  // LUTRAM Configuration    
  reg [RSLT_WIDTH-1:0] LUTRAM_ARRAY [0:2**DATA_WIDTH-1];

  // LUTRAM Instantiation
  initial begin
    $readmemh(ROM_DATA_PATH, LUTRAM_ARRAY);
  end

  genvar CHN;

  // Per Channel LUTRAM Access
  generate for (CHN = 0; CHN < CHANNELS; CHN = CHN+1) begin      
    // Internal Registers & Wires
    // Data wires
    wire [DATA_WIDTH-1:0]       stage_1_in_axis_0_tdata, stage_1_out_axis_0_tdata;
    wire [DATA_KEEP_WIDTH-1:0]  stage_1_in_axis_0_tkeep, stage_1_out_axis_0_tkeep;
    wire                        stage_1_in_axis_0_tvalid, stage_1_out_axis_0_tvalid;
    wire                        stage_1_in_axis_0_tready, stage_1_out_axis_0_tready;
    wire                        stage_1_in_axis_0_tlast, stage_1_out_axis_0_tlast;
    wire [ID_WIDTH-1:0]         stage_1_in_axis_0_tid, stage_1_out_axis_0_tid;
    wire [DEST_WIDTH-1:0]       stage_1_in_axis_0_tdest, stage_1_out_axis_0_tdest;
    wire [USER_WIDTH-1:0]       stage_1_in_axis_0_tuser, stage_1_out_axis_0_tuser;

    wire [RSLT_WIDTH-1:0]       stage_2_in_axis_0_tdata, stage_2_out_axis_0_tdata;
    wire [RSLT_KEEP_WIDTH-1:0]  stage_2_in_axis_0_tkeep, stage_2_out_axis_0_tkeep;
    wire                        stage_2_in_axis_0_tvalid, stage_2_out_axis_0_tvalid;
    wire                        stage_2_in_axis_0_tready, stage_2_out_axis_0_tready;
    wire                        stage_2_in_axis_0_tlast, stage_2_out_axis_0_tlast;
    wire [ID_WIDTH-1:0]         stage_2_in_axis_0_tid, stage_2_out_axis_0_tid;
    wire [DEST_WIDTH-1:0]       stage_2_in_axis_0_tdest, stage_2_out_axis_0_tdest;
    wire [USER_WIDTH-1:0]       stage_2_in_axis_0_tuser, stage_2_out_axis_0_tuser;

    // Stage 1 Data Input
    assign stage_1_in_axis_0_tdata   = s_axis_0_tdata[(CHN+1)*DATA_WIDTH -1: CHN*DATA_WIDTH];
    assign stage_1_in_axis_0_tkeep   = s_axis_0_tkeep[(CHN+1)*DATA_KEEP_WIDTH -1: CHN*DATA_KEEP_WIDTH];
    assign stage_1_in_axis_0_tvalid  = s_axis_0_tvalid[CHN];
    assign s_axis_0_tready[CHN]      = stage_1_in_axis_0_tready;
    assign stage_1_in_axis_0_tlast   = s_axis_0_tlast[CHN];
    assign stage_1_in_axis_0_tid     = s_axis_0_tid  [(CHN+1)*ID_WIDTH -1: CHN*ID_WIDTH];
    assign stage_1_in_axis_0_tdest   = s_axis_0_tdest[(CHN+1)*DEST_WIDTH -1: CHN*DEST_WIDTH];
    assign stage_1_in_axis_0_tuser   = s_axis_0_tuser[(CHN+1)*USER_WIDTH -1: CHN*USER_WIDTH];

    // Stage 1 Skid Data Register
    axis_register #(
      // Width of AXI stream interfaces in bits
      .DATA_WIDTH(DATA_WIDTH),
      // Propagate tkeep signal
      .KEEP_ENABLE(DATA_KEEP_ENABLE),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(DATA_KEEP_WIDTH),
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
      .USER_WIDTH(USER_WIDTH)
    ) axis_register_data_inst (
      .clk              (clk),
      .rst              (rst),
      .s_axis_tdata     (stage_1_in_axis_0_tdata),
      .s_axis_tkeep     (stage_1_in_axis_0_tkeep),
      .s_axis_tvalid    (stage_1_in_axis_0_tvalid),
      .s_axis_tready    (stage_1_in_axis_0_tready),
      .s_axis_tlast     (stage_1_in_axis_0_tlast),
      .s_axis_tid       (stage_1_in_axis_0_tid),
      .s_axis_tdest     (stage_1_in_axis_0_tdest),
      .s_axis_tuser     (stage_1_in_axis_0_tuser),
      .m_axis_tdata     (stage_1_out_axis_0_tdata),
      .m_axis_tkeep     (stage_1_out_axis_0_tkeep),
      .m_axis_tvalid    (stage_1_out_axis_0_tvalid),
      .m_axis_tready    (stage_1_out_axis_0_tready),
      .m_axis_tlast     (stage_1_out_axis_0_tlast),
      .m_axis_tid       (stage_1_out_axis_0_tid),
      .m_axis_tdest     (stage_1_out_axis_0_tdest),
      .m_axis_tuser     (stage_1_out_axis_0_tuser)
    );

    // Stage 2 Input
    assign stage_2_in_axis_0_tdata    = LUTRAM_ARRAY[stage_1_out_axis_0_tdata];
    assign stage_2_in_axis_0_tkeep    = {RSLT_KEEP_WIDTH{1'b1}};
    assign stage_2_in_axis_0_tvalid   = stage_1_out_axis_0_tvalid;
    assign stage_1_out_axis_0_tready  = stage_2_in_axis_0_tready;
    assign stage_2_in_axis_0_tlast    = stage_1_out_axis_0_tlast ;
    assign stage_2_in_axis_0_tid      = stage_1_out_axis_0_tid;
    assign stage_2_in_axis_0_tdest    = stage_1_out_axis_0_tdest;
    assign stage_2_in_axis_0_tuser    = stage_1_out_axis_0_tuser;

    // Stage 2 Skid Register
    axis_register #(
      // Width of AXI stream interfaces in bits
      .DATA_WIDTH(RSLT_WIDTH),
      // Propagate tkeep signal
      .KEEP_ENABLE(RSLT_KEEP_ENABLE),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(RSLT_KEEP_WIDTH),
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
      // Register type
      // 0 to bypass, 1 for simple buffer, 2 for skid buffer
      .REG_TYPE(2)
    ) axis_register_output_inst (
      .clk              (clk),
      .rst              (rst),
      .s_axis_tdata     (stage_2_in_axis_0_tdata),
      .s_axis_tkeep     (stage_2_in_axis_0_tkeep),
      .s_axis_tvalid    (stage_2_in_axis_0_tvalid),
      .s_axis_tready    (stage_2_in_axis_0_tready),
      .s_axis_tlast     (stage_2_in_axis_0_tlast),
      .s_axis_tid       (stage_2_in_axis_0_tid),
      .s_axis_tdest     (stage_2_in_axis_0_tdest),
      .s_axis_tuser     (stage_2_in_axis_0_tuser),
      .m_axis_tdata     (stage_2_out_axis_0_tdata),
      .m_axis_tkeep     (stage_2_out_axis_0_tkeep),
      .m_axis_tvalid    (stage_2_out_axis_0_tvalid),
      .m_axis_tready    (stage_2_out_axis_0_tready),
      .m_axis_tlast     (stage_2_out_axis_0_tlast),
      .m_axis_tid       (stage_2_out_axis_0_tid),
      .m_axis_tdest     (stage_2_out_axis_0_tdest),
      .m_axis_tuser     (stage_2_out_axis_0_tuser)
    );

    // Output Control Logic
    assign m_axis_0_tdata[(CHN+1)*DATA_WIDTH -1: CHN*DATA_WIDTH]            = stage_2_out_axis_0_tdata ;
    assign m_axis_0_tkeep[(CHN+1)*DATA_KEEP_WIDTH -1: CHN*DATA_KEEP_WIDTH]  = stage_2_out_axis_0_tkeep ;
    assign m_axis_0_tvalid[CHN]                                             = stage_2_out_axis_0_tvalid;
    assign stage_2_out_axis_0_tready                                        = m_axis_0_tready[CHN]     ;
    assign m_axis_0_tlast[CHN]                                              = stage_2_out_axis_0_tlast ;
    assign m_axis_0_tid  [(CHN+1)*ID_WIDTH -1: CHN*ID_WIDTH]                = stage_2_out_axis_0_tid   ;
    assign m_axis_0_tdest[(CHN+1)*DEST_WIDTH -1: CHN*DEST_WIDTH]            = stage_2_out_axis_0_tdest ;
    assign m_axis_0_tuser[(CHN+1)*USER_WIDTH -1: CHN*USER_WIDTH]            = stage_2_out_axis_0_tuser ;

  end
  endgenerate
endmodule

`resetall
