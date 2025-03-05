
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_DataSplitter
(

);

  localparam OUTPUT_DATA_WIDTH = 8;
  localparam CHANNELS = 6;
  localparam INPUT_KEEP_ENABLE = CHANNELS * OUTPUT_DATA_WIDTH > 8;
  localparam INPUT_KEEP_WIDTH = (CHANNELS * OUTPUT_DATA_WIDTH + 7) / 8;
  localparam OUTPUT_KEEP_ENABLE = OUTPUT_DATA_WIDTH > 8;
  localparam OUTPUT_KEEP_WIDTH = (OUTPUT_DATA_WIDTH + 7) / 8;
  localparam LAST_ENABLE = 1;
  localparam ID_ENABLE = 1;
  localparam ID_WIDTH = 8;
  localparam DEST_ENABLE = 1;
  localparam DEST_WIDTH = 8;
  localparam USER_ENABLE = 1;
  localparam USER_WIDTH = 8;
  localparam EXTRA_CYCLE = 1;
  reg clk;
  reg rst;
  reg [CHANNELS*OUTPUT_DATA_WIDTH-1+1-1:0] s_axis_tdata;
  reg [INPUT_KEEP_WIDTH-1+1-1:0] s_axis_tkeep;
  reg s_axis_tvalid;
  wire s_axis_tready;
  reg s_axis_tlast;
  reg [ID_WIDTH-1+1-1:0] s_axis_tid;
  reg [DEST_WIDTH-1+1-1:0] s_axis_tdest;
  reg [USER_WIDTH-1+1-1:0] s_axis_tuser;
  wire [CHANNELS*OUTPUT_DATA_WIDTH-1+1-1:0] m_axis_tdata;
  wire [CHANNELS*OUTPUT_KEEP_WIDTH-1+1-1:0] m_axis_tkeep;
  wire [CHANNELS-1+1-1:0] m_axis_tvalid;
  reg [CHANNELS-1+1-1:0] m_axis_tready;
  wire [CHANNELS-1+1-1:0] m_axis_tlast;
  wire [CHANNELS*ID_WIDTH-1+1-1:0] m_axis_tid;
  wire [CHANNELS*DEST_WIDTH-1+1-1:0] m_axis_tdest;
  wire [CHANNELS*USER_WIDTH-1+1-1:0] m_axis_tuser;
  reg reset_done;

  DataSplitter
  #(
    .OUTPUT_DATA_WIDTH(OUTPUT_DATA_WIDTH),
    .CHANNELS(CHANNELS),
    .INPUT_KEEP_ENABLE(INPUT_KEEP_ENABLE),
    .INPUT_KEEP_WIDTH(INPUT_KEEP_WIDTH),
    .OUTPUT_KEEP_ENABLE(OUTPUT_KEEP_ENABLE),
    .OUTPUT_KEEP_WIDTH(OUTPUT_KEEP_WIDTH),
    .LAST_ENABLE(LAST_ENABLE),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .EXTRA_CYCLE(EXTRA_CYCLE)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast(m_axis_tlast),
    .m_axis_tid(m_axis_tid),
    .m_axis_tdest(m_axis_tdest),
    .m_axis_tuser(m_axis_tuser)
  );


  initial begin
    $dumpfile("../vcd/tb_DataSplitter.vcd");
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
    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tvalid = 0;
    m_axis_tready = 0;
    s_axis_tlast = 0;
    s_axis_tid = 0;
    s_axis_tdest = 0;
    s_axis_tuser = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    s_axis_tvalid = 1;
    s_axis_tkeep = -1;
    s_axis_tdata = 48'hAABBCCDDEEFF;
    m_axis_tready = -1;
    #500;
    $finish;
  end

  integer counter;
  reg [OUTPUT_DATA_WIDTH-1:0] _tmp_0;
  reg [1-1:0] _tmp_1;

  always @(posedge clk) begin
    if(reset_done) begin
      if(s_axis_tready && s_axis_tvalid) begin
        counter <= counter + 1;
        { s_axis_tdata, _tmp_0 } <= { s_axis_tdata[OUTPUT_DATA_WIDTH:0], s_axis_tdata };
        s_axis_tkeep <= { 1'b1, s_axis_tkeep } >> 1;
        { _tmp_1, m_axis_tready } <= { m_axis_tready, 1'b1 };
        s_axis_tlast <= ~s_axis_tlast;
      end 
      if(counter == CHANNELS) begin
        s_axis_tkeep[CHANNELS - 1] <= 0;
      end 
      if(counter == 3 * CHANNELS) begin
        m_axis_tready[0] <= 0;
      end 
      if(counter == 7 * CHANNELS) begin
        s_axis_tkeep[CHANNELS - 1] <= 0;
        m_axis_tready[0] <= 0;
      end 
      if(counter == 9 * CHANNELS) begin
        $finish;
      end 
    end else begin
      counter <= 0;
    end
  end


endmodule

`resetall
