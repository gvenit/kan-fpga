
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_DataProcessor_8_4_32
(

);

  localparam BATCH_SIZE = 32;
  localparam DATA_WIDTH_DATA = 16;
  localparam FRACTIONAL_BITS_DATA = 12;
  localparam DATA_WIDTH_SCALE = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_SCALE = 12;
  localparam DATA_WIDTH_WEIGHT = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_WEIGHT = 12;
  localparam DATA_WIDTH_SCALED_DIFF = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_SCALED_DIFF = 13;
  localparam DATA_WIDTH_ACT = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_ACT = 16;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_RSLT = 12;
  localparam KEEP_ENABLE = DATA_WIDTH_RSLT > 8;
  localparam KEEP_WIDTH = (DATA_WIDTH_RSLT + 7) / 8;
  localparam ID_ENABLE = 0;
  localparam ID_WIDTH = 8;
  localparam DEST_ENABLE = 0;
  localparam DEST_WIDTH = 8;
  localparam USER_ENABLE = 0;
  localparam USER_WIDTH = 1;
  localparam DATA_CHANNELS = 4;
  localparam RSLT_CHANNELS = 8;
  localparam WEIGHT_CHANNELS = RSLT_CHANNELS * DATA_CHANNELS;
  localparam SHARE_SCALE = 1;
  localparam SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS * BATCH_SIZE;
  localparam ROM_DATA_PATH = "../../data/Sech2Lutram_n_16.13_16.16.txt";
  localparam OUTPUT_DEST = 0;
  localparam OUTPUT_ID = 1;
  reg clk;
  reg rst;
  reg [DATA_CHANNELS*BATCH_SIZE*DATA_WIDTH_DATA-1+1-1:0] s_axis_data_tdata;
  reg [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_data_tvalid;
  wire [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_data_tready;
  reg [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_data_tlast;
  reg [DATA_CHANNELS*BATCH_SIZE*ID_WIDTH-1+1-1:0] s_axis_data_tid;
  reg [DATA_CHANNELS*BATCH_SIZE*DEST_WIDTH-1+1-1:0] s_axis_data_tdest;
  reg [DATA_CHANNELS*BATCH_SIZE*USER_WIDTH-1+1-1:0] s_axis_data_tuser;
  reg [DATA_CHANNELS*BATCH_SIZE*DATA_WIDTH_DATA-1+1-1:0] s_axis_grid_tdata;
  reg [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_grid_tvalid;
  wire [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_grid_tready;
  reg [DATA_CHANNELS*BATCH_SIZE-1+1-1:0] s_axis_grid_tlast;
  reg [DATA_CHANNELS*BATCH_SIZE*ID_WIDTH-1+1-1:0] s_axis_grid_tid;
  reg [DATA_CHANNELS*BATCH_SIZE*DEST_WIDTH-1+1-1:0] s_axis_grid_tdest;
  reg [DATA_CHANNELS*BATCH_SIZE*USER_WIDTH-1+1-1:0] s_axis_grid_tuser;
  reg [SCALE_CHANNELS*DATA_WIDTH_SCALE-1+1-1:0] s_axis_scale_tdata;
  reg [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tvalid;
  wire [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tready;
  reg [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tlast;
  reg [SCALE_CHANNELS*ID_WIDTH-1+1-1:0] s_axis_scale_tid;
  reg [SCALE_CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_scale_tdest;
  reg [SCALE_CHANNELS*USER_WIDTH-1+1-1:0] s_axis_scale_tuser;
  reg [WEIGHT_CHANNELS*DATA_WIDTH_SCALE-1+1-1:0] s_axis_weight_tdata;
  reg [WEIGHT_CHANNELS-1+1-1:0] s_axis_weight_tvalid;
  wire [WEIGHT_CHANNELS-1+1-1:0] s_axis_weight_tready;
  reg [WEIGHT_CHANNELS-1+1-1:0] s_axis_weight_tlast;
  reg [WEIGHT_CHANNELS*ID_WIDTH-1+1-1:0] s_axis_weight_tid;
  reg [WEIGHT_CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_weight_tdest;
  reg [WEIGHT_CHANNELS*USER_WIDTH-1+1-1:0] s_axis_weight_tuser;
  wire [RSLT_CHANNELS*BATCH_SIZE*DATA_WIDTH_RSLT-1+1-1:0] m_axis_data_tdata;
  wire [RSLT_CHANNELS*BATCH_SIZE*KEEP_WIDTH-1+1-1:0] m_axis_data_tkeep;
  wire [RSLT_CHANNELS*BATCH_SIZE-1+1-1:0] m_axis_data_tvalid;
  reg [RSLT_CHANNELS*BATCH_SIZE-1+1-1:0] m_axis_data_tready;
  wire [RSLT_CHANNELS*BATCH_SIZE-1+1-1:0] m_axis_data_tlast;
  wire [RSLT_CHANNELS*BATCH_SIZE*ID_WIDTH-1+1-1:0] m_axis_data_tid;
  wire [RSLT_CHANNELS*BATCH_SIZE*DEST_WIDTH-1+1-1:0] m_axis_data_tdest;
  wire [RSLT_CHANNELS*BATCH_SIZE*USER_WIDTH-1+1-1:0] m_axis_data_tuser;
  wire err_unalligned_data;
  wire core_rst;
  reg reset_done;

  DataProcessor
  #(
    .BATCH_SIZE(BATCH_SIZE),
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    .DATA_WIDTH_WEIGHT(DATA_WIDTH_WEIGHT),
    .FRACTIONAL_BITS_WEIGHT(FRACTIONAL_BITS_WEIGHT),
    .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
    .DATA_WIDTH_ACT(DATA_WIDTH_ACT),
    .FRACTIONAL_BITS_ACT(FRACTIONAL_BITS_ACT),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE(KEEP_ENABLE),
    .KEEP_WIDTH(KEEP_WIDTH),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .DATA_CHANNELS(DATA_CHANNELS),
    .RSLT_CHANNELS(RSLT_CHANNELS),
    .WEIGHT_CHANNELS(WEIGHT_CHANNELS),
    .SHARE_SCALE(SHARE_SCALE),
    .SCALE_CHANNELS(SCALE_CHANNELS),
    .ROM_DATA_PATH(ROM_DATA_PATH),
    .OUTPUT_DEST(OUTPUT_DEST),
    .OUTPUT_ID(OUTPUT_ID)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
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
    .s_axis_weight_tdata(s_axis_weight_tdata),
    .s_axis_weight_tvalid(s_axis_weight_tvalid),
    .s_axis_weight_tready(s_axis_weight_tready),
    .s_axis_weight_tlast(s_axis_weight_tlast),
    .s_axis_weight_tid(s_axis_weight_tid),
    .s_axis_weight_tdest(s_axis_weight_tdest),
    .s_axis_weight_tuser(s_axis_weight_tuser),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tkeep(m_axis_data_tkeep),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tid(m_axis_data_tid),
    .m_axis_data_tdest(m_axis_data_tdest),
    .m_axis_data_tuser(m_axis_data_tuser),
    .err_unalligned_data(err_unalligned_data),
    .core_rst(core_rst)
  );


  initial begin
    $dumpfile("../vcd/tb_DataProcessor_8_4_32.vcd");
    $dumpvars(0, uut);
  end


  initial begin
    clk = 0;
    forever begin
      #1 clk = !clk;
    end
  end


  initial begin
    rst = 0;
    reset_done = 0;
    s_axis_data_tdata = 0;
    s_axis_data_tvalid = 0;
    s_axis_data_tlast = 0;
    s_axis_grid_tdata = 0;
    s_axis_grid_tvalid = 0;
    s_axis_grid_tlast = 0;
    s_axis_scale_tdata = 0;
    s_axis_scale_tlast = 0;
    s_axis_scale_tvalid = 0;
    s_axis_weight_tdata = 0;
    s_axis_weight_tlast = 0;
    s_axis_weight_tvalid = 0;
    m_axis_data_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_data_tready = 1;
    #5000;
    $finish;
  end

  `define assert(signal, value)     if (signal !== value) begin         $display("ASSERTION FAILED in %m: %s != %s",`"signal`", `"value`");         $display("---- Time %0t",$time);         $display("---- %s = 0x%h",`"signal`",signal);         $display("---- %s = 0x%h",`"value`",value);         $finish;     end
      `define assertTrue(signal)     if (~signal) begin         $display("ASSERTION FAILED in %m: %s is not True",`"signal`");         $display("---- Time %0t",$time);         $display("---- %s = 0x%h",`"signal`",signal);         $finish;     end
    

endmodule

`resetall
