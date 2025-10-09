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
  parameter DATA_WIDTH = 16,
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = 12,
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = 16,
  // Fractional bits of input scale
  parameter SCALE_FRACTIONAL_BITS = 12,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = 12,
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
  input wire                        clk,
  input wire                        rst,

  /*
    * AXI Stream Data input
    */
  input  wire [DATA_WIDTH-1:0]      s_axis_data_tdata,
  input  wire                       s_axis_data_tvalid,
  output wire                       s_axis_data_tready,
  input  wire                       s_axis_data_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_data_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_data_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_data_tuser,

  /*
    * AXI Stream Grid input
    */
  input  wire [DATA_WIDTH-1:0]      s_axis_grid_tdata,
  input  wire                       s_axis_grid_tvalid,
  output wire                       s_axis_grid_tready,
  input  wire                       s_axis_grid_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_grid_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_grid_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_grid_tuser,

  /*
    * AXI Stream Scale input
    */
  input  wire [SCALE_WIDTH-1:0]     s_axis_scle_tdata,
  input  wire                       s_axis_scle_tvalid,
  output wire                       s_axis_scle_tready,
  input  wire                       s_axis_scle_tlast,
  input  wire [ID_WIDTH-1:0]        s_axis_scle_tid,
  input  wire [DEST_WIDTH-1:0]      s_axis_scle_tdest,
  input  wire [USER_WIDTH-1:0]      s_axis_scle_tuser,

  /*
    * AXI Stream output
    */
  output wire [RSLT_WIDTH-1:0]      m_axis_data_tdata,
  output wire                       m_axis_data_tvalid,
  input  wire                       m_axis_data_tready,
  output wire                       m_axis_data_tlast,
  output wire [ID_WIDTH-1:0]        m_axis_data_tid,
  output wire [DEST_WIDTH-1:0]      m_axis_data_tdest,
  output wire [USER_WIDTH-1:0]      m_axis_data_tuser
);
  // Local Parameters
  localparam SUB_WIDTH = DATA_WIDTH;
  localparam MTL_WIDTH = `MAX( RSLT_WIDTH, SUB_WIDTH + SCALE_WIDTH);
  localparam RSLT_LSB  = DATA_FRACTIONAL_BITS + SCALE_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS;

  // Internal Registers & Wires
  // Data wires
  wire [DATA_WIDTH-1:0]                 stage_1_in_axis_data_tdata,   stage_1_out_axis_data_tdata,    stage_1_fb_axis_data_tdata;
  wire                                  stage_1_in_axis_data_tvalid,  stage_1_out_axis_data_tvalid,   stage_1_fb_axis_data_tvalid;
  wire                                  stage_1_in_axis_data_tready,  stage_1_out_axis_data_tready,   stage_1_fb_axis_data_tready;
  wire                                  stage_1_in_axis_data_tlast,   stage_1_out_axis_data_tlast,    stage_1_fb_axis_data_tlast;
  wire [ID_WIDTH-1:0]                   stage_1_in_axis_data_tid,     stage_1_out_axis_data_tid,      stage_1_fb_axis_data_tid;
  wire [DEST_WIDTH-1:0]                 stage_1_in_axis_data_tdest,   stage_1_out_axis_data_tdest,    stage_1_fb_axis_data_tdest;
  wire [USER_WIDTH-1:0]                 stage_1_in_axis_data_tuser,   stage_1_out_axis_data_tuser,    stage_1_fb_axis_data_tuser;

  wire [DATA_WIDTH-1:0]                 stage_2_in_axis_data_tdata_op0, stage_2_in_axis_data_tdata_op1;
  wire [SUB_WIDTH-1:0]                  stage_2_out_axis_data_tdata;
  wire                                  stage_2_in_axis_data_tvalid,    stage_2_out_axis_data_tvalid;
  wire                                  stage_2_in_axis_data_tready,    stage_2_out_axis_data_tready;
  wire                                  stage_2_in_axis_data_tlast,     stage_2_out_axis_data_tlast;
  wire [ID_WIDTH-1:0]                   stage_2_in_axis_data_tid,       stage_2_out_axis_data_tid;
  wire [DEST_WIDTH-1:0]                 stage_2_in_axis_data_tdest,     stage_2_out_axis_data_tdest;
  wire [USER_WIDTH+SCALE_WIDTH-1:0]     stage_2_in_axis_data_tuser,     stage_2_out_axis_data_tuser;

  wire signed [SUB_WIDTH-1:0]           stage_3_in_axis_data_tdata_op0;
  wire signed [SCALE_WIDTH-1:0]         stage_3_in_axis_data_tdata_op1;
  wire [MTL_WIDTH-1:0]                  stage_3_out_axis_data_tdata;
  wire                                  stage_3_in_axis_data_tvalid,  stage_3_out_axis_data_tvalid;
  wire                                  stage_3_in_axis_data_tready,  stage_3_out_axis_data_tready;
  wire                                  stage_3_in_axis_data_tlast,   stage_3_out_axis_data_tlast;
  wire [ID_WIDTH-1:0]                   stage_3_in_axis_data_tid,     stage_3_out_axis_data_tid;
  wire [DEST_WIDTH-1:0]                 stage_3_in_axis_data_tdest,   stage_3_out_axis_data_tdest;
  wire [USER_WIDTH-1:0]                 stage_3_in_axis_data_tuser,   stage_3_out_axis_data_tuser;
  
  // Grid Wires
  wire [DATA_WIDTH-1:0]                 stage_1_in_axis_grid_tdata,   stage_1_out_axis_grid_tdata,    stage_1_fb_axis_grid_tdata;
  wire                                  stage_1_in_axis_grid_tvalid,  stage_1_out_axis_grid_tvalid,   stage_1_fb_axis_grid_tvalid;
  wire                                  stage_1_in_axis_grid_tready,  stage_1_out_axis_grid_tready,   stage_1_fb_axis_grid_tready;
  wire                                  stage_1_in_axis_grid_tlast,   stage_1_out_axis_grid_tlast,    stage_1_fb_axis_grid_tlast;
  wire [ID_WIDTH-1:0]                   stage_1_in_axis_grid_tid,     stage_1_out_axis_grid_tid,      stage_1_fb_axis_grid_tid;
  wire [DEST_WIDTH-1:0]                 stage_1_in_axis_grid_tdest,   stage_1_out_axis_grid_tdest,    stage_1_fb_axis_grid_tdest;
  wire [USER_WIDTH-1:0]                 stage_1_in_axis_grid_tuser,   stage_1_out_axis_grid_tuser,    stage_1_fb_axis_grid_tuser;

  // Scale Wires          
  wire [SCALE_WIDTH-1:0]                stage_1_in_axis_scle_tdata,   stage_1_out_axis_scle_tdata,    stage_1_fb_axis_scle_tdata;
  wire                                  stage_1_in_axis_scle_tvalid,  stage_1_out_axis_scle_tvalid,   stage_1_fb_axis_scle_tvalid;
  wire                                  stage_1_in_axis_scle_tready,  stage_1_out_axis_scle_tready,   stage_1_fb_axis_scle_tready;
  wire                                  stage_1_in_axis_scle_tlast,   stage_1_out_axis_scle_tlast,    stage_1_fb_axis_scle_tlast;
  wire [ID_WIDTH-1:0]                   stage_1_in_axis_scle_tid,     stage_1_out_axis_scle_tid,      stage_1_fb_axis_scle_tid;
  wire [DEST_WIDTH-1:0]                 stage_1_in_axis_scle_tdest,   stage_1_out_axis_scle_tdest,    stage_1_fb_axis_scle_tdest;
  wire [USER_WIDTH-1:0]                 stage_1_in_axis_scle_tuser,   stage_1_out_axis_scle_tuser,    stage_1_fb_axis_scle_tuser;

  // Control Logic Registers & Wires
  wire                          stage_2_in_handshake;
  wire                          data_lock, grid_lock, scale_lock;
  wire                          unlock_int;

  // Operation Data Wires
  wire signed [RSLT_WIDTH-1:0]  stage_2_rslt_trunc;

  // Stage 1 Skid Data Register
  axis_register #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_ENABLE      (0),
    .KEEP_WIDTH       (1),
    .LAST_ENABLE      (1),
    .ID_ENABLE        (ID_ENABLE),
    .ID_WIDTH         (ID_WIDTH),
    .DEST_ENABLE      (DEST_ENABLE),
    .DEST_WIDTH       (DEST_WIDTH),
    .USER_ENABLE      (USER_ENABLE),
    .USER_WIDTH       (USER_WIDTH),
    .REG_TYPE         (2)
  ) axis_reg_data_inst(
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (stage_1_in_axis_data_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (stage_1_in_axis_data_tvalid),
    .s_axis_tready    (stage_1_in_axis_data_tready),
    .s_axis_tlast     (stage_1_in_axis_data_tlast),
    .s_axis_tid       (stage_1_in_axis_data_tid),
    .s_axis_tdest     (stage_1_in_axis_data_tdest),
    .s_axis_tuser     (stage_1_in_axis_data_tuser),
    .m_axis_tdata     (stage_1_out_axis_data_tdata),
    .m_axis_tvalid    (stage_1_out_axis_data_tvalid),
    .m_axis_tready    (stage_1_out_axis_data_tready),
    .m_axis_tlast     (stage_1_out_axis_data_tlast),
    .m_axis_tid       (stage_1_out_axis_data_tid),
    .m_axis_tdest     (stage_1_out_axis_data_tdest),
    .m_axis_tuser     (stage_1_out_axis_data_tuser)
  );

  // Stage 1 Skid Grid Register
  axis_register #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_ENABLE      (0),
    .KEEP_WIDTH       (1),
    .LAST_ENABLE      (1),
    .ID_ENABLE        (ID_ENABLE),
    .ID_WIDTH         (ID_WIDTH),
    .DEST_ENABLE      (DEST_ENABLE),
    .DEST_WIDTH       (DEST_WIDTH),
    .USER_ENABLE      (USER_ENABLE),
    .USER_WIDTH       (USER_WIDTH),
    .REG_TYPE         (2)
  ) axis_reg_grid_inst(
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (stage_1_in_axis_grid_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (stage_1_in_axis_grid_tvalid),
    .s_axis_tready    (stage_1_in_axis_grid_tready),
    .s_axis_tlast     (stage_1_in_axis_grid_tlast),
    .s_axis_tid       (stage_1_in_axis_grid_tid),
    .s_axis_tdest     (stage_1_in_axis_grid_tdest),
    .s_axis_tuser     (stage_1_in_axis_grid_tuser),
    .m_axis_tdata     (stage_1_out_axis_grid_tdata),
    .m_axis_tvalid    (stage_1_out_axis_grid_tvalid),
    .m_axis_tready    (stage_1_out_axis_grid_tready),
    .m_axis_tlast     (stage_1_out_axis_grid_tlast),
    .m_axis_tid       (stage_1_out_axis_grid_tid),
    .m_axis_tdest     (stage_1_out_axis_grid_tdest),
    .m_axis_tuser     (stage_1_out_axis_grid_tuser)
  );

  // Stage 1 Skid Scale Register
  axis_register #(
    .DATA_WIDTH       (DATA_WIDTH),
    .KEEP_ENABLE      (0),
    .KEEP_WIDTH       (1),
    .LAST_ENABLE      (1),
    .ID_ENABLE        (ID_ENABLE),
    .ID_WIDTH         (ID_WIDTH),
    .DEST_ENABLE      (DEST_ENABLE),
    .DEST_WIDTH       (DEST_WIDTH),
    .USER_ENABLE      (USER_ENABLE),
    .USER_WIDTH       (USER_WIDTH),
    .REG_TYPE         (2)
  ) axis_reg_scle_inst(
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata     (stage_1_in_axis_scle_tdata),
    .s_axis_tkeep     (1'b1),
    .s_axis_tvalid    (stage_1_in_axis_scle_tvalid),
    .s_axis_tready    (stage_1_in_axis_scle_tready),
    .s_axis_tlast     (stage_1_in_axis_scle_tlast),
    .s_axis_tid       (stage_1_in_axis_scle_tid),
    .s_axis_tdest     (stage_1_in_axis_scle_tdest),
    .s_axis_tuser     (stage_1_in_axis_scle_tuser),
    .m_axis_tdata     (stage_1_out_axis_scle_tdata),
    .m_axis_tvalid    (stage_1_out_axis_scle_tvalid),
    .m_axis_tready    (stage_1_out_axis_scle_tready),
    .m_axis_tlast     (stage_1_out_axis_scle_tlast),
    .m_axis_tid       (stage_1_out_axis_scle_tid),
    .m_axis_tdest     (stage_1_out_axis_scle_tdest),
    .m_axis_tuser     (stage_1_out_axis_scle_tuser)
  );

  // Stage 2 Skid Register
  AxisALU #(
    .OP0_WIDTH        (DATA_WIDTH),
    .OP1_WIDTH        (DATA_WIDTH),
    .RSLT_WIDTH       (SUB_WIDTH),
    .CHANNELS         (1),
    .LAST_ENABLE      (1),
    .ID_ENABLE        (ID_ENABLE),
    .ID_WIDTH         (ID_WIDTH),
    .DEST_ENABLE      (DEST_ENABLE),
    .DEST_WIDTH       (DEST_WIDTH),
    .USER_ENABLE      (1),
    .USER_WIDTH       (USER_WIDTH+SCALE_WIDTH),
    .OP_MODE          (1),
    .REG_TYPE         (2)
  ) axis_alu_sub_inst (
    .clk              (clk),
    .rst              (rst),
    .s_axis_tdata_op0 (stage_2_in_axis_data_tdata_op0),
    .s_axis_tdata_op1 (stage_2_in_axis_data_tdata_op1),
    .s_axis_tvalid    (stage_2_in_axis_data_tvalid),
    .s_axis_tready    (stage_2_in_axis_data_tready),
    .s_axis_tlast     (stage_2_in_axis_data_tlast),
    .s_axis_tid       (stage_2_in_axis_data_tid),
    .s_axis_tdest     (stage_2_in_axis_data_tdest),
    .s_axis_tuser     (stage_2_in_axis_data_tuser),
    .m_axis_tdata     (stage_2_out_axis_data_tdata),
    .m_axis_tvalid    (stage_2_out_axis_data_tvalid),
    .m_axis_tready    (stage_2_out_axis_data_tready),
    .m_axis_tlast     (stage_2_out_axis_data_tlast),
    .m_axis_tid       (stage_2_out_axis_data_tid),
    .m_axis_tdest     (stage_2_out_axis_data_tdest),
    .m_axis_tuser     (stage_2_out_axis_data_tuser)
  );
  
  // Stage 3 Input
  assign stage_3_in_axis_data_tdata_op0 = stage_2_out_axis_data_tdata ;
  assign stage_3_in_axis_data_tvalid    = stage_2_out_axis_data_tvalid;
  assign stage_2_out_axis_data_tready   = stage_3_in_axis_data_tready ;
  assign stage_3_in_axis_data_tlast     = stage_2_out_axis_data_tlast ;
  assign stage_3_in_axis_data_tid       = stage_2_out_axis_data_tid   ;
  assign stage_3_in_axis_data_tdest     = stage_2_out_axis_data_tdest ;
  assign {stage_3_in_axis_data_tuser, stage_3_in_axis_data_tdata_op1} = stage_2_out_axis_data_tuser ;

  (* use_dsp="yes" *) 
   wire signed [MTL_WIDTH-1:0] stage_3_in_axis_data_tdata = stage_3_in_axis_data_tdata_op0 * stage_3_in_axis_data_tdata_op1;

   // Stage 3 Skid Register
   axis_register #(
     .DATA_WIDTH       (MTL_WIDTH),
     .KEEP_ENABLE      (0),
     .KEEP_WIDTH       (1),
     .LAST_ENABLE      (1),
     .ID_ENABLE        (ID_ENABLE),
     .ID_WIDTH         (ID_WIDTH),
     .DEST_ENABLE      (DEST_ENABLE),
     .DEST_WIDTH       (DEST_WIDTH),
     .USER_ENABLE      (USER_ENABLE),
     .USER_WIDTH       (USER_WIDTH),
     .REG_TYPE         (2)
   ) axis_alu_mlt_inst (
     .clk              (clk),
     .rst              (rst),
     .s_axis_tdata     (stage_3_in_axis_data_tdata),
     .s_axis_tkeep     (1'b1),
     .s_axis_tvalid    (stage_3_in_axis_data_tvalid),
     .s_axis_tready    (stage_3_in_axis_data_tready),
     .s_axis_tlast     (stage_3_in_axis_data_tlast),
     .s_axis_tid       (stage_3_in_axis_data_tid),
     .s_axis_tdest     (stage_3_in_axis_data_tdest),
     .s_axis_tuser     (stage_3_in_axis_data_tuser),
     .m_axis_tdata     (stage_3_out_axis_data_tdata),
     .m_axis_tvalid    (stage_3_out_axis_data_tvalid),
     .m_axis_tready    (stage_3_out_axis_data_tready),
     .m_axis_tlast     (stage_3_out_axis_data_tlast),
     .m_axis_tid       (stage_3_out_axis_data_tid),
     .m_axis_tdest     (stage_3_out_axis_data_tdest),
     .m_axis_tuser     (stage_3_out_axis_data_tuser)
   );

 
  assign stage_2_in_handshake = stage_2_in_axis_data_tready & stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scle_tvalid;
  assign unlock_int           = stage_2_in_axis_data_tlast & stage_2_in_handshake;
  assign data_lock   = stage_1_out_axis_data_tlast & stage_1_out_axis_data_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);
  assign grid_lock   = stage_1_out_axis_grid_tlast & stage_1_out_axis_grid_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);
  assign scale_lock  = stage_1_out_axis_scle_tlast & stage_1_out_axis_scle_tvalid & !unlock_int ; //!unlock_reg_next & (x_lock_reg | x_last_reg_next);

  // Stage 1 Data Input
  assign stage_1_in_axis_data_tdata   = (data_lock) ? stage_1_fb_axis_data_tdata  : s_axis_data_tdata;
  assign stage_1_in_axis_data_tvalid  = (data_lock) ? stage_1_fb_axis_data_tvalid : s_axis_data_tvalid;
  assign s_axis_data_tready           = (data_lock) ? stage_1_fb_axis_data_tready : stage_1_in_axis_data_tready;
  assign stage_1_in_axis_data_tlast   = (data_lock) ? stage_1_fb_axis_data_tlast  : s_axis_data_tlast;
  assign stage_1_in_axis_data_tid     = (data_lock) ? stage_1_fb_axis_data_tid    : s_axis_data_tid;
  assign stage_1_in_axis_data_tdest   = (data_lock) ? stage_1_fb_axis_data_tdest  : s_axis_data_tdest;
  assign stage_1_in_axis_data_tuser   = (data_lock) ? stage_1_fb_axis_data_tuser  : s_axis_data_tuser;

  // Stage 1 Grid Input
  assign stage_1_in_axis_grid_tdata   = (grid_lock) ? stage_1_fb_axis_grid_tdata  : s_axis_grid_tdata;
  assign stage_1_in_axis_grid_tvalid  = (grid_lock) ? stage_1_fb_axis_grid_tvalid : s_axis_grid_tvalid;
  assign s_axis_grid_tready           = (grid_lock) ? stage_1_fb_axis_grid_tready : stage_1_in_axis_grid_tready;
  assign stage_1_in_axis_grid_tlast   = (grid_lock) ? stage_1_fb_axis_grid_tlast  : s_axis_grid_tlast;
  assign stage_1_in_axis_grid_tid     = (grid_lock) ? stage_1_fb_axis_grid_tid    : s_axis_grid_tid;
  assign stage_1_in_axis_grid_tdest   = (grid_lock) ? stage_1_fb_axis_grid_tdest  : s_axis_grid_tdest;
  assign stage_1_in_axis_grid_tuser   = (grid_lock) ? stage_1_fb_axis_grid_tuser  : s_axis_grid_tuser;

  // Stage 1 Scale Input
  assign stage_1_in_axis_scle_tdata  = (scale_lock) ? stage_1_fb_axis_scle_tdata  : s_axis_scle_tdata;
  assign stage_1_in_axis_scle_tvalid = (scale_lock) ? stage_1_fb_axis_scle_tvalid : s_axis_scle_tvalid;
  assign s_axis_scle_tready          = (scale_lock) ? stage_1_fb_axis_scle_tready : stage_1_in_axis_scle_tready;
  assign stage_1_in_axis_scle_tlast  = (scale_lock) ? stage_1_fb_axis_scle_tlast  : s_axis_scle_tlast;
  assign stage_1_in_axis_scle_tid    = (scale_lock) ? stage_1_fb_axis_scle_tid    : s_axis_scle_tid;
  assign stage_1_in_axis_scle_tdest  = (scale_lock) ? stage_1_fb_axis_scle_tdest  : s_axis_scle_tdest;
  assign stage_1_in_axis_scle_tuser  = (scale_lock) ? stage_1_fb_axis_scle_tuser  : s_axis_scle_tuser;

  // Stage 1 Data Feedback
  assign stage_1_fb_axis_data_tdata   = stage_1_out_axis_data_tdata;
  assign stage_1_fb_axis_data_tvalid  = stage_2_in_handshake;
  assign stage_1_fb_axis_data_tready  = 0;
  assign stage_1_fb_axis_data_tlast   = stage_1_out_axis_data_tlast;
  assign stage_1_fb_axis_data_tid     = stage_1_out_axis_data_tid;
  assign stage_1_fb_axis_data_tdest   = stage_1_out_axis_data_tdest;
  assign stage_1_fb_axis_data_tuser   = stage_1_out_axis_data_tuser;
  
  // Stage 1 Grid Feedback  
  assign stage_1_fb_axis_grid_tdata   = stage_1_out_axis_grid_tdata;
  assign stage_1_fb_axis_grid_tvalid  = stage_2_in_handshake;
  assign stage_1_fb_axis_grid_tready  = 0;
  assign stage_1_fb_axis_grid_tlast   = stage_1_out_axis_grid_tlast;
  assign stage_1_fb_axis_grid_tid     = stage_1_out_axis_grid_tid;
  assign stage_1_fb_axis_grid_tdest   = stage_1_out_axis_grid_tdest;
  assign stage_1_fb_axis_grid_tuser   = stage_1_out_axis_grid_tuser;
  
  // Stage 1 Scale Feedback
  assign stage_1_fb_axis_scle_tdata  = stage_1_out_axis_scle_tdata;
  assign stage_1_fb_axis_scle_tvalid = stage_2_in_handshake;
  assign stage_1_fb_axis_scle_tready = 0;
  assign stage_1_fb_axis_scle_tlast  = stage_1_out_axis_scle_tlast;
  assign stage_1_fb_axis_scle_tid    = stage_1_out_axis_scle_tid;
  assign stage_1_fb_axis_scle_tdest  = stage_1_out_axis_scle_tdest;
  assign stage_1_fb_axis_scle_tuser  = stage_1_out_axis_scle_tuser;

  // Stage 2 Input
  assign stage_2_in_axis_data_tdata_op0 = stage_1_out_axis_data_tdata;
  assign stage_2_in_axis_data_tdata_op1 = stage_1_out_axis_grid_tdata;
  assign stage_2_in_axis_data_tvalid    = stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scle_tvalid;
  assign stage_1_out_axis_data_tready   = stage_2_in_axis_data_tready  & stage_1_out_axis_grid_tvalid & stage_1_out_axis_scle_tvalid;
  assign stage_1_out_axis_grid_tready   = stage_2_in_axis_data_tready  & stage_1_out_axis_data_tvalid & stage_1_out_axis_scle_tvalid;
  assign stage_1_out_axis_scle_tready   = stage_2_in_axis_data_tready  & stage_1_out_axis_data_tvalid & stage_1_out_axis_grid_tvalid;
  assign stage_2_in_axis_data_tlast     = stage_1_out_axis_data_tlast  & stage_1_out_axis_grid_tlast  & stage_1_out_axis_scle_tlast;
  assign stage_2_in_axis_data_tid       = stage_1_out_axis_data_tid;
  assign stage_2_in_axis_data_tdest     = stage_1_out_axis_data_tdest;
  assign stage_2_in_axis_data_tuser     = {stage_1_out_axis_data_tuser, stage_1_out_axis_scle_tdata};

  // Stage 3 Input
  assign stage_3_in_axis_data_tdata_op0 = stage_2_out_axis_data_tdata ;
  assign stage_3_in_axis_data_tvalid    = stage_2_out_axis_data_tvalid;
  assign stage_2_out_axis_data_tready   = stage_3_in_axis_data_tready ;
  assign stage_3_in_axis_data_tlast     = stage_2_out_axis_data_tlast ;
  assign stage_3_in_axis_data_tid       = stage_2_out_axis_data_tid   ;
  assign stage_3_in_axis_data_tdest     = stage_2_out_axis_data_tdest ;
  assign {stage_3_in_axis_data_tuser, stage_3_in_axis_data_tdata_op1} = stage_2_out_axis_data_tuser ;

  // Output Control Logic
  assign m_axis_data_tdata            = $signed(stage_3_out_axis_data_tdata[MTL_WIDTH-1:RSLT_LSB]);
  assign m_axis_data_tvalid           = stage_3_out_axis_data_tvalid;
  assign stage_3_out_axis_data_tready = m_axis_data_tready          ;
  assign m_axis_data_tlast            = stage_3_out_axis_data_tlast ;
  assign m_axis_data_tid              = stage_3_out_axis_data_tid   ;
  assign m_axis_data_tdest            = stage_3_out_axis_data_tdest ;
  assign m_axis_data_tuser            = stage_3_out_axis_data_tuser ;
endmodule

`resetall
