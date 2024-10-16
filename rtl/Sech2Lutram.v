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
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE_DATA = (DATA_WIDTH_DATA>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_DATA = ((DATA_WIDTH_DATA+7)/8),
  // Propagate tkeep signal
  parameter KEEP_ENABLE_RSLT = (DATA_WIDTH_RSLT>8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH_RSLT = ((DATA_WIDTH_RSLT+7)/8),
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
  // Unsigned Input
  parameter USE_UNSIGNED = 1
) (
  input                             clk,
  input                             rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_WIDTH_DATA-1:0] s_axis_data_tdata,
  output wire [KEEP_WIDTH-1:0]      s_axis_data_tkeep,
  input  wire                       s_axis_data_tlast,
  input  wire                       s_axis_data_tvalid,
  output wire                       s_axis_data_tready,
  input  wire [ID_WIDTH-1:0]        s_axis_data_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_data_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_data_tuser,

  /*
    * AXI Stream output
    */
  output wire [DATA_WIDTH_RSLT-1:0] m_axis_data_tdata,
  output wire [KEEP_WIDTH-1:0]      m_axis_data_tkeep,
  output wire                       m_axis_data_tlast,
  output wire                       m_axis_data_tvalid,
  input  wire                       m_axis_data_tready,
  output wire [ID_WIDTH-1:0]        m_axis_data_tid,
  output wire [DEST_WIDTH-1:0]      m_axis_data_tdest,
  output wire [USER_WIDTH-1:0]      m_axis_data_tuser

  // // Error Signals
  // output                  err_unalligned_data,
  // output                  err_unalligned_scale
);
  
  // Internal Registers & Wires
  // Data wires
  wire [DATA_WIDTH_DATA-1:0]  stage_1_in_axis_data_tdata, stage_1_out_axis_data_tdata;
  wire [KEEP_WIDTH_DATA-1:0]  stage_1_in_axis_data_tkeep, stage_1_out_axis_data_tkeep;
  wire                        stage_1_in_axis_data_tvalid, stage_1_out_axis_data_tvalid;
  wire                        stage_1_in_axis_data_tready, stage_1_out_axis_data_tready;
  wire                        stage_1_in_axis_data_tlast, stage_1_out_axis_data_tlast;
  wire [ID_WIDTH-1:0]         stage_1_in_axis_data_tid, stage_1_out_axis_data_tid;
  wire [DEST_WIDTH-1:0]       stage_1_in_axis_data_tdest, stage_1_out_axis_data_tdest;
  wire [USER_WIDTH-1:0]       stage_1_in_axis_data_tuser, stage_1_out_axis_data_tuser;

  wire [DATA_WIDTH_RSLT-1:0]  stage_2_in_axis_data_tdata, stage_2_out_axis_data_tdata;
  wire [KEEP_WIDTH_RSLT-1:0]  stage_2_in_axis_data_tkeep, stage_2_out_axis_data_tkeep;
  wire                        stage_2_in_axis_data_tvalid, stage_2_out_axis_data_tvalid;
  wire                        stage_2_in_axis_data_tready, stage_2_out_axis_data_tready;
  wire                        stage_2_in_axis_data_tlast, stage_2_out_axis_data_tlast;
  wire [ID_WIDTH-1:0]         stage_2_in_axis_data_tid, stage_2_out_axis_data_tid;
  wire [DEST_WIDTH-1:0]       stage_2_in_axis_data_tdest, stage_2_out_axis_data_tdest;
  wire [USER_WIDTH-1:0]       stage_2_in_axis_data_tuser, stage_2_out_axis_data_tuser;
  
  reg [321-1:0] ROM_DATA_PATH;
  reg [DATA_WIDTH_RSLT-1:0] LUTRAM_ARRAY [0:2**DATA_WIDTH_DATA-1];

  initial begin
    if (USE_UNSIGNED) begin
        $sformat(ROM_DATA_PATH, "../data/sech2_lutram_n_%0d.%0d_%0d.%0d.txt", DATA_WIDTH_DATA, FRACTIONAL_BITS_DATA, DATA_WIDTH_RSLT, FRACTIONAL_BITS_RSLT);
    end
    else begin
        $sformat(ROM_DATA_PATH, "../data/sech2_lutram_%0d.%0d_%0d.%0d.txt", DATA_WIDTH_DATA, FRACTIONAL_BITS_DATA, DATA_WIDTH_RSLT, FRACTIONAL_BITS_RSLT);
    end
    $display("ROM_DATA_PATH is : %s", ROM_DATA_PATH);
    $readmemh(ROM_DATA_PATH, LUTRAM_ARRAY);
  end

  // Stage 1 Data Input
  assign stage_1_in_axis_data_tdata   = s_axis_data_tdata;
  assign stage_1_in_axis_data_tkeep   = s_axis_data_tkeep;
  assign stage_1_in_axis_data_tvalid  = s_axis_data_tvalid;
  assign s_axis_data_tready           = stage_1_in_axis_data_tready;
  assign stage_1_in_axis_data_tlast   = s_axis_data_tlast;
  assign stage_1_in_axis_data_tid     = s_axis_data_tid;
  assign stage_1_in_axis_data_tdest   = s_axis_data_tdest;
  assign stage_1_in_axis_data_tuser   = s_axis_data_tuser;

  // Stage 1 Skid Data Register
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
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
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(stage_1_in_axis_data_tdata),
    .s_axis_tkeep(stage_1_in_axis_data_tkeep),
    .s_axis_tvalid(stage_1_in_axis_data_tvalid),
    .s_axis_tready(stage_1_in_axis_data_tready),
    .s_axis_tlast(stage_1_in_axis_data_tlast),
    .s_axis_tid(stage_1_in_axis_data_tid),
    .s_axis_tdest(stage_1_in_axis_data_tdest),
    .s_axis_tuser(stage_1_in_axis_data_tuser),
    .m_axis_tdata(stage_1_out_axis_data_tdata),
    .m_axis_tkeep(stage_1_out_axis_data_tkeep),
    .m_axis_tvalid(stage_1_out_axis_data_tvalid),
    .m_axis_tready(stage_1_out_axis_data_tready),
    .m_axis_tlast(stage_1_out_axis_data_tlast),
    .m_axis_tid(stage_1_out_axis_data_tid),
    .m_axis_tdest(stage_1_out_axis_data_tdest),
    .m_axis_tuser(stage_1_out_axis_data_tuser)
  );

  // Stage 2 Input
  assign stage_2_in_axis_data_tdata    = LUTRAM_ARRAY[stage_1_out_axis_data_tdata];
  assign stage_2_in_axis_data_tkeep    = {KEEP_WIDTH_RSLT{1'b1}};
  assign stage_2_in_axis_data_tvalid   = stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scale_tvalid;
  assign stage_1_out_axis_data_tready  = stage_2_in_axis_data_tready & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scale_tvalid;
  assign stage_1_out_axis_grid_tready  = stage_2_in_axis_data_tready & stage_1_out_axis_data_tvalid & stage_1_out_axis_scale_tvalid;
  assign stage_1_out_axis_scale_tready = stage_2_in_axis_data_tready & stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid;
  assign stage_2_in_axis_data_tlast    = stage_1_out_axis_data_tlast & stage_1_out_axis_grid_tlast & stage_1_out_axis_scale_tlast;
  assign stage_2_in_axis_data_tid      = stage_1_out_axis_data_tid;
  assign stage_2_in_axis_data_tdest    = stage_1_out_axis_data_tdest;
  assign stage_2_in_axis_data_tuser    = stage_1_out_axis_data_tuser;

  // Stage 2 Skid Register
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_RSLT),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
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
  ) axis_register_output_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(stage_2_in_axis_data_tdata),
    .s_axis_tkeep(stage_2_in_axis_data_tkeep),
    .s_axis_tvalid(stage_2_in_axis_data_tvalid),
    .s_axis_tready(stage_2_in_axis_data_tready),
    .s_axis_tlast(stage_2_in_axis_data_tlast),
    .s_axis_tid(stage_2_in_axis_data_tid),
    .s_axis_tdest(stage_2_in_axis_data_tdest),
    .s_axis_tuser(stage_2_in_axis_data_tuser),
    .m_axis_tdata(stage_2_out_axis_data_tdata),
    .m_axis_tkeep(stage_2_out_axis_data_tkeep),
    .m_axis_tvalid(stage_2_out_axis_data_tvalid),
    .m_axis_tready(stage_2_out_axis_data_tready),
    .m_axis_tlast(stage_2_out_axis_data_tlast),
    .m_axis_tid(stage_2_out_axis_data_tid),
    .m_axis_tdest(stage_2_out_axis_data_tdest),
    .m_axis_tuser(stage_2_out_axis_data_tuser)
  );

  // Output Control Logic
  assign m_axis_data_tdata            = stage_2_out_axis_data_tdata ;
  assign m_axis_data_tkeep            = stage_2_out_axis_data_tkeep ;
  assign m_axis_data_tvalid           = stage_2_out_axis_data_tvalid;
  assign stage_2_out_axis_data_tready = m_axis_data_tready          ;
  assign m_axis_data_tlast            = stage_2_out_axis_data_tlast ;
  assign m_axis_data_tid              = stage_2_out_axis_data_tid   ;
  assign m_axis_data_tdest            = stage_2_out_axis_data_tdest ;
  assign m_axis_data_tuser            = stage_2_out_axis_data_tuser ;

endmodule

`resetall
