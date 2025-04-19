`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  SubMult : Accepts three input AXI-Stream frames and returns
 *    the result (x-grid)*scale.
 *    If the three input frames don't have the same length, the
 *    two shortest are extended to match the length of the longest.
 */

module SubMult #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Fractional bits of input data & grid
  parameter FRACTIONAL_BITS_DATA = 12,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
  // Fractional bits of input scale
  parameter FRACTIONAL_BITS_SCALE = 12,
  // Width of AXI stream Output Data interface in bits
  parameter DATA_WIDTH_RSLT = 16,
  // Fractional bits of output data
  parameter FRACTIONAL_BITS_RSLT = 12,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH_RSLT > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH_RSLT + 7) / 8) : 1,
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
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1
) (
  input wire clk,
  input wire rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_WIDTH_DATA-1:0]  s_axis_data_tdata,
  input  wire                   s_axis_data_tvalid,
  output wire                   s_axis_data_tready,
  input  wire                   s_axis_data_tlast,
  input  wire [ID_WIDTH-1:0]    s_axis_data_tid,
  input  wire [DEST_WIDTH-1:0]  s_axis_data_tdest,
  input  wire [USER_WIDTH-1:0]  s_axis_data_tuser,

  /*
    * AXI Stream Grid input
    */
  input  wire [DATA_WIDTH_DATA-1:0] s_axis_grid_tdata,
  input  wire                       s_axis_grid_tvalid,
  output wire                       s_axis_grid_tready,
  input  wire                       s_axis_grid_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_grid_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_grid_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [DATA_WIDTH_SCALE-1:0]  s_axis_scle_tdata,
  input  wire                         s_axis_scle_tvalid,
  output wire                         s_axis_scle_tready,
  input  wire                         s_axis_scle_tlast,
  input  wire [ID_WIDTH-1:0]          s_axis_scle_tid,
  input  wire [DEST_WIDTH-1:0]        s_axis_scle_tdest,
  input  wire [USER_WIDTH-1:0]        s_axis_scle_tuser,

  /*
    * AXI Stream output
    */
  output wire [DATA_WIDTH_RSLT-1:0] m_axis_data_tdata,
  output wire [KEEP_WIDTH-1:0]      m_axis_data_tkeep,
  output wire                       m_axis_data_tvalid,
  input  wire                       m_axis_data_tready,
  output wire                       m_axis_data_tlast,
  output wire [ID_WIDTH-1:0]        m_axis_data_tid,
  output wire [DEST_WIDTH-1:0]      m_axis_data_tdest,
  output wire [USER_WIDTH-1:0]      m_axis_data_tuser

  // // Error Signals
  // output                  err_unalligned_data,
  // output                  err_unalligned_scale
);
  // Local Parameters
  localparam OP_SIZE  = (DATA_WIDTH_RSLT > DATA_WIDTH_DATA + DATA_WIDTH_SCALE) ? DATA_WIDTH_RSLT : DATA_WIDTH_DATA + DATA_WIDTH_SCALE;
  localparam RSLT_LSB = FRACTIONAL_BITS_DATA + FRACTIONAL_BITS_SCALE - FRACTIONAL_BITS_RSLT;
  localparam RSLT_MSB = RSLT_LSB + DATA_WIDTH_RSLT - 1;

  // Internal Registers & Wires
  // Data wires
  wire [DATA_WIDTH_DATA-1:0]  stage_1_in_axis_data_tdata, stage_1_out_axis_data_tdata, stage_1_fb_axis_data_tdata;
  // wire [KEEP_WIDTH-1:0]       stage_1_in_axis_data_tkeep, stage_1_out_axis_data_tkeep, stage_1_fb_axis_data_tkeep;
  wire                        stage_1_in_axis_data_tvalid, stage_1_out_axis_data_tvalid, stage_1_fb_axis_data_tvalid;
  wire                        stage_1_in_axis_data_tready, stage_1_out_axis_data_tready, stage_1_fb_axis_data_tready;
  wire                        stage_1_in_axis_data_tlast, stage_1_out_axis_data_tlast, stage_1_fb_axis_data_tlast;
  wire [ID_WIDTH-1:0]         stage_1_in_axis_data_tid, stage_1_out_axis_data_tid, stage_1_fb_axis_data_tid;
  wire [DEST_WIDTH-1:0]       stage_1_in_axis_data_tdest, stage_1_out_axis_data_tdest, stage_1_fb_axis_data_tdest;
  wire [USER_WIDTH-1:0]       stage_1_in_axis_data_tuser, stage_1_out_axis_data_tuser, stage_1_fb_axis_data_tuser;

  wire [DATA_WIDTH_RSLT-1:0]  stage_2_in_axis_data_tdata, stage_2_out_axis_data_tdata;
  wire [KEEP_WIDTH-1:0]       stage_2_in_axis_data_tkeep, stage_2_out_axis_data_tkeep;
  wire                        stage_2_in_axis_data_tvalid, stage_2_out_axis_data_tvalid;
  wire                        stage_2_in_axis_data_tready, stage_2_out_axis_data_tready;
  wire                        stage_2_in_axis_data_tlast, stage_2_out_axis_data_tlast;
  wire [ID_WIDTH-1:0]         stage_2_in_axis_data_tid, stage_2_out_axis_data_tid;
  wire [DEST_WIDTH-1:0]       stage_2_in_axis_data_tdest, stage_2_out_axis_data_tdest;
  wire [USER_WIDTH-1:0]       stage_2_in_axis_data_tuser, stage_2_out_axis_data_tuser;
  
  // Grid Wires
  wire [DATA_WIDTH_DATA-1:0]  stage_1_in_axis_grid_tdata, stage_1_out_axis_grid_tdata, stage_1_fb_axis_grid_tdata;
  // wire [KEEP_WIDTH-1:0]       stage_1_in_axis_grid_tkeep, stage_1_out_axis_grid_tkeep, stage_1_fb_axis_grid_tkeep;
  wire                        stage_1_in_axis_grid_tvalid, stage_1_out_axis_grid_tvalid, stage_1_fb_axis_grid_tvalid;
  wire                        stage_1_in_axis_grid_tready, stage_1_out_axis_grid_tready, stage_1_fb_axis_grid_tready;
  wire                        stage_1_in_axis_grid_tlast, stage_1_out_axis_grid_tlast, stage_1_fb_axis_grid_tlast;
  wire [ID_WIDTH-1:0]         stage_1_in_axis_grid_tid, stage_1_out_axis_grid_tid, stage_1_fb_axis_grid_tid;
  wire [DEST_WIDTH-1:0]       stage_1_in_axis_grid_tdest, stage_1_out_axis_grid_tdest, stage_1_fb_axis_grid_tdest;
  wire [USER_WIDTH-1:0]       stage_1_in_axis_grid_tuser, stage_1_out_axis_grid_tuser, stage_1_fb_axis_grid_tuser;

  // Scale Wires
  wire [DATA_WIDTH_SCALE-1:0] stage_1_in_axis_scale_tdata, stage_1_out_axis_scale_tdata, stage_1_fb_axis_scale_tdata;
  // wire [KEEP_WIDTH-1:0]       stage_1_in_axis_scale_tkeep, stage_1_out_axis_scale_tkeep, stage_1_fb_axis_scale_tkeep;
  wire                        stage_1_in_axis_scale_tvalid, stage_1_out_axis_scale_tvalid, stage_1_fb_axis_scale_tvalid;
  wire                        stage_1_in_axis_scale_tready, stage_1_out_axis_scale_tready, stage_1_fb_axis_scale_tready;
  wire                        stage_1_in_axis_scale_tlast, stage_1_out_axis_scale_tlast, stage_1_fb_axis_scale_tlast;
  wire [ID_WIDTH-1:0]         stage_1_in_axis_scale_tid, stage_1_out_axis_scale_tid, stage_1_fb_axis_scale_tid;
  wire [DEST_WIDTH-1:0]       stage_1_in_axis_scale_tdest, stage_1_out_axis_scale_tdest, stage_1_fb_axis_scale_tdest;
  wire [USER_WIDTH-1:0]       stage_1_in_axis_scale_tuser, stage_1_out_axis_scale_tuser, stage_1_fb_axis_scale_tuser;

  // Control Logic Registers & Wires
  wire                  stage_2_in_handshake;
  wire                  data_lock, grid_lock, scale_lock;
  // wire                  data_halt, grid_halt, scale_halt;
  wire                  unlock_int;

  // Operation Data Wires
  wire signed [DATA_WIDTH_DATA-1:0] diff; 
  wire signed [DATA_WIDTH_RSLT-1:0] res; 
  wire signed [OP_SIZE-1:0] diff_ext, scale_ext, res_ext;

  assign stage_2_in_handshake = stage_2_in_axis_data_tready & stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scale_tvalid;
  assign unlock_int           = stage_2_in_axis_data_tlast & stage_2_in_handshake;
  assign data_lock   = stage_1_out_axis_data_tlast & stage_1_out_axis_data_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);
  assign grid_lock   = stage_1_out_axis_grid_tlast & stage_1_out_axis_grid_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);
  assign scale_lock  = stage_1_out_axis_scale_tlast & stage_1_out_axis_scale_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);

  // assign data_halt  = data_lock  | (stage_1_out_axis_data_tvalid  & !stage_2_in_axis_data_tvalid);
  // assign grid_halt  = grid_lock  | (stage_1_out_axis_grid_tvalid  & !stage_2_in_axis_data_tvalid);
  // assign scale_halt = scale_lock | (stage_1_out_axis_scale_tvalid & !stage_2_in_axis_data_tvalid);

  // Stage 1 Data Input
  assign stage_1_in_axis_data_tdata   = (data_lock) ? stage_1_fb_axis_data_tdata  : s_axis_data_tdata;
  // assign stage_1_in_axis_data_tkeep   = (data_lock) ? stage_1_fb_axis_data_tkeep  : s_axis_data_tkeep;
  assign stage_1_in_axis_data_tvalid  = (data_lock) ? stage_1_fb_axis_data_tvalid : s_axis_data_tvalid;
  assign s_axis_data_tready           = (data_lock) ? stage_1_fb_axis_data_tready : stage_1_in_axis_data_tready;
  assign stage_1_in_axis_data_tlast   = (data_lock) ? stage_1_fb_axis_data_tlast  : s_axis_data_tlast;
  assign stage_1_in_axis_data_tid     = (data_lock) ? stage_1_fb_axis_data_tid    : s_axis_data_tid;
  assign stage_1_in_axis_data_tdest   = (data_lock) ? stage_1_fb_axis_data_tdest  : s_axis_data_tdest;
  assign stage_1_in_axis_data_tuser   = (data_lock) ? stage_1_fb_axis_data_tuser  : s_axis_data_tuser;

  // Stage 1 Grid Input
  assign stage_1_in_axis_grid_tdata   = (grid_lock) ? stage_1_fb_axis_grid_tdata  : s_axis_grid_tdata;
  // assign stage_1_in_axis_grid_tkeep   = (grid_lock) ? stage_1_fb_axis_grid_tkeep  : s_axis_grid_tkeep;
  assign stage_1_in_axis_grid_tvalid  = (grid_lock) ? stage_1_fb_axis_grid_tvalid : s_axis_grid_tvalid;
  assign s_axis_grid_tready           = (grid_lock) ? stage_1_fb_axis_grid_tready : stage_1_in_axis_grid_tready;
  assign stage_1_in_axis_grid_tlast   = (grid_lock) ? stage_1_fb_axis_grid_tlast  : s_axis_grid_tlast;
  assign stage_1_in_axis_grid_tid     = (grid_lock) ? stage_1_fb_axis_grid_tid    : s_axis_grid_tid;
  assign stage_1_in_axis_grid_tdest   = (grid_lock) ? stage_1_fb_axis_grid_tdest  : s_axis_grid_tdest;
  assign stage_1_in_axis_grid_tuser   = (grid_lock) ? stage_1_fb_axis_grid_tuser  : s_axis_grid_tuser;

  // Stage 1 Scale Input
  assign stage_1_in_axis_scale_tdata   = (scale_lock) ? stage_1_fb_axis_scale_tdata  : s_axis_scle_tdata;
  // assign stage_1_in_axis_scale_tkeep   = (scale_lock) ? stage_1_fb_axis_scale_tkeep  : s_axis_scle_tkeep;
  assign stage_1_in_axis_scale_tvalid  = (scale_lock) ? stage_1_fb_axis_scale_tvalid : s_axis_scle_tvalid;
  assign s_axis_scle_tready           = (scale_lock) ? stage_1_fb_axis_scale_tready : stage_1_in_axis_scale_tready;
  assign stage_1_in_axis_scale_tlast   = (scale_lock) ? stage_1_fb_axis_scale_tlast  : s_axis_scle_tlast;
  assign stage_1_in_axis_scale_tid     = (scale_lock) ? stage_1_fb_axis_scale_tid    : s_axis_scle_tid;
  assign stage_1_in_axis_scale_tdest   = (scale_lock) ? stage_1_fb_axis_scale_tdest  : s_axis_scle_tdest;
  assign stage_1_in_axis_scale_tuser   = (scale_lock) ? stage_1_fb_axis_scale_tuser  : s_axis_scle_tuser;

  // Stage 1 Data Feedback
  assign stage_1_fb_axis_data_tdata  = stage_1_out_axis_data_tdata;
  // assign stage_1_fb_axis_data_tkeep  = stage_1_out_axis_data_tkeep;
  assign stage_1_fb_axis_data_tvalid = stage_1_out_axis_data_tvalid;
  assign stage_1_fb_axis_data_tready = 0;
  assign stage_1_fb_axis_data_tlast  = stage_1_out_axis_data_tlast;
  assign stage_1_fb_axis_data_tid    = stage_1_out_axis_data_tid;
  assign stage_1_fb_axis_data_tdest  = stage_1_out_axis_data_tdest;
  assign stage_1_fb_axis_data_tuser  = stage_1_out_axis_data_tuser;
  
  // Stage 1 Grid Feedback
  assign stage_1_fb_axis_grid_tdata  = stage_1_out_axis_grid_tdata;
  // assign stage_1_fb_axis_grid_tkeep  = stage_1_out_axis_grid_tkeep;
  assign stage_1_fb_axis_grid_tvalid = stage_1_out_axis_grid_tvalid;
  assign stage_1_fb_axis_grid_tready = 0;
  assign stage_1_fb_axis_grid_tlast  = stage_1_out_axis_grid_tlast;
  assign stage_1_fb_axis_grid_tid    = stage_1_out_axis_grid_tid;
  assign stage_1_fb_axis_grid_tdest  = stage_1_out_axis_grid_tdest;
  assign stage_1_fb_axis_grid_tuser  = stage_1_out_axis_grid_tuser;
  
  // Stage 1 Scale Feedback
  assign stage_1_fb_axis_scale_tdata  = stage_1_out_axis_scale_tdata;
  // assign stage_1_fb_axis_scale_tkeep  = stage_1_out_axis_scale_tkeep;
  assign stage_1_fb_axis_scale_tvalid = stage_1_out_axis_scale_tvalid;
  assign stage_1_fb_axis_scale_tready = 0;
  assign stage_1_fb_axis_scale_tlast  = stage_1_out_axis_scale_tlast;
  assign stage_1_fb_axis_scale_tid    = stage_1_out_axis_scale_tid;
  assign stage_1_fb_axis_scale_tdest  = stage_1_out_axis_scale_tdest;
  assign stage_1_fb_axis_scale_tuser  = stage_1_out_axis_scale_tuser;

  // Stage 1 Skid Data Register
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
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
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_data_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(stage_1_in_axis_data_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(stage_1_in_axis_data_tvalid),
    .s_axis_tready(stage_1_in_axis_data_tready),
    .s_axis_tlast(stage_1_in_axis_data_tlast),
    .s_axis_tid(stage_1_in_axis_data_tid),
    .s_axis_tdest(stage_1_in_axis_data_tdest),
    .s_axis_tuser(stage_1_in_axis_data_tuser),
    .m_axis_tdata(stage_1_out_axis_data_tdata),
    // .m_axis_tkeep(stage_1_out_axis_data_tkeep),
    .m_axis_tvalid(stage_1_out_axis_data_tvalid),
    .m_axis_tready(stage_1_out_axis_data_tready),
    .m_axis_tlast(stage_1_out_axis_data_tlast),
    .m_axis_tid(stage_1_out_axis_data_tid),
    .m_axis_tdest(stage_1_out_axis_data_tdest),
    .m_axis_tuser(stage_1_out_axis_data_tuser)
  );

  // Stage 1 Skid Grid Register
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
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
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_grid_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(stage_1_in_axis_grid_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(stage_1_in_axis_grid_tvalid),
    .s_axis_tready(stage_1_in_axis_grid_tready),
    .s_axis_tlast(stage_1_in_axis_grid_tlast),
    .s_axis_tid(stage_1_in_axis_grid_tid),
    .s_axis_tdest(stage_1_in_axis_grid_tdest),
    .s_axis_tuser(stage_1_in_axis_grid_tuser),
    .m_axis_tdata(stage_1_out_axis_grid_tdata),
    // .m_axis_tkeep(stage_1_out_axis_grid_tkeep),
    .m_axis_tvalid(stage_1_out_axis_grid_tvalid),
    .m_axis_tready(stage_1_out_axis_grid_tready),
    .m_axis_tlast(stage_1_out_axis_grid_tlast),
    .m_axis_tid(stage_1_out_axis_grid_tid),
    .m_axis_tdest(stage_1_out_axis_grid_tdest),
    .m_axis_tuser(stage_1_out_axis_grid_tuser)
  );

  // Stage 1 Skid Scale Register
  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH_DATA),
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
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) axis_register_scale_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(stage_1_in_axis_scale_tdata),
    .s_axis_tkeep(1'b1),
    .s_axis_tvalid(stage_1_in_axis_scale_tvalid),
    .s_axis_tready(stage_1_in_axis_scale_tready),
    .s_axis_tlast(stage_1_in_axis_scale_tlast),
    .s_axis_tid(stage_1_in_axis_scale_tid),
    .s_axis_tdest(stage_1_in_axis_scale_tdest),
    .s_axis_tuser(stage_1_in_axis_scale_tuser),
    .m_axis_tdata(stage_1_out_axis_scale_tdata),
    // .m_axis_tkeep(stage_1_out_axis_scale_tkeep),
    .m_axis_tvalid(stage_1_out_axis_scale_tvalid),
    .m_axis_tready(stage_1_out_axis_scale_tready),
    .m_axis_tlast(stage_1_out_axis_scale_tlast),
    .m_axis_tid(stage_1_out_axis_scale_tid),
    .m_axis_tdest(stage_1_out_axis_scale_tdest),
    .m_axis_tuser(stage_1_out_axis_scale_tuser)
  );

  // DSP Flow
  assign diff      = stage_1_out_axis_data_tdata - stage_1_out_axis_grid_tdata;
  assign diff_ext  = {{(OP_SIZE-DATA_WIDTH_DATA){diff[DATA_WIDTH_DATA-1]}}, diff};
  assign scale_ext = {{(OP_SIZE-DATA_WIDTH_SCALE){stage_1_out_axis_scale_tdata[DATA_WIDTH_SCALE-1]}}, stage_1_out_axis_scale_tdata};
  assign res_ext   = diff_ext * scale_ext;
  assign res       = res_ext[RSLT_MSB:RSLT_LSB];
  
  // Stage 2 Input
  assign stage_2_in_axis_data_tdata    = res;
  assign stage_2_in_axis_data_tkeep    = {KEEP_WIDTH{1'b1}};
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
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
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
