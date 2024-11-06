
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_Sech2Lutram
(

);

  localparam DATA_WIDTH_DATA = 16;
  localparam FRACTIONAL_BITS_DATA = 13;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_RSLT = 16;
  localparam KEEP_ENABLE_DATA = DATA_WIDTH_DATA > 8;
  localparam KEEP_WIDTH_DATA = (DATA_WIDTH_DATA + 7) / 8;
  localparam KEEP_ENABLE_RSLT = DATA_WIDTH_RSLT > 8;
  localparam KEEP_WIDTH_RSLT = (DATA_WIDTH_RSLT + 7) / 8;
  localparam ID_ENABLE = 0;
  localparam ID_WIDTH = 8;
  localparam DEST_ENABLE = 0;
  localparam DEST_WIDTH = 8;
  localparam USER_ENABLE = 0;
  localparam USER_WIDTH = 1;
  localparam CHANNELS = 4;
  localparam ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt";
  reg clk;
  reg rst;
  reg [CHANNELS*DATA_WIDTH_DATA-1+1-1:0] s_axis_0_tdata;
  wire [CHANNELS*KEEP_WIDTH_DATA-1+1-1:0] s_axis_0_tkeep;
  reg [CHANNELS-1+1-1:0] s_axis_0_tlast;
  reg [CHANNELS-1+1-1:0] s_axis_0_tvalid;
  wire [CHANNELS-1+1-1:0] s_axis_0_tready;
  reg [CHANNELS*ID_WIDTH-1+1-1:0] s_axis_0_tid;
  reg [CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_0_tdest;
  reg [CHANNELS*USER_WIDTH-1+1-1:0] s_axis_0_tuser;
  wire [CHANNELS*DATA_WIDTH_RSLT-1+1-1:0] m_axis_0_tdata;
  wire [CHANNELS*KEEP_WIDTH_RSLT-1+1-1:0] m_axis_0_tkeep;
  wire [CHANNELS-1+1-1:0] m_axis_0_tlast;
  wire [CHANNELS-1+1-1:0] m_axis_0_tvalid;
  reg [CHANNELS-1+1-1:0] m_axis_0_tready;
  wire [CHANNELS*ID_WIDTH-1+1-1:0] m_axis_0_tid;
  wire [CHANNELS*DEST_WIDTH-1+1-1:0] m_axis_0_tdest;
  wire [CHANNELS*USER_WIDTH-1+1-1:0] m_axis_0_tuser;
  reg reset_done;

  Sech2Lutram
  #(
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .KEEP_ENABLE_DATA(KEEP_ENABLE_DATA),
    .KEEP_WIDTH_DATA(KEEP_WIDTH_DATA),
    .KEEP_ENABLE_RSLT(KEEP_ENABLE_RSLT),
    .KEEP_WIDTH_RSLT(KEEP_WIDTH_RSLT),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .CHANNELS(CHANNELS),
    .ROM_DATA_PATH(ROM_DATA_PATH)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(s_axis_0_tdata),
    .s_axis_0_tkeep(s_axis_0_tkeep),
    .s_axis_0_tlast(s_axis_0_tlast),
    .s_axis_0_tvalid(s_axis_0_tvalid),
    .s_axis_0_tready(s_axis_0_tready),
    .s_axis_0_tid(s_axis_0_tid),
    .s_axis_0_tdest(s_axis_0_tdest),
    .s_axis_0_tuser(s_axis_0_tuser),
    .m_axis_0_tdata(m_axis_0_tdata),
    .m_axis_0_tkeep(m_axis_0_tkeep),
    .m_axis_0_tlast(m_axis_0_tlast),
    .m_axis_0_tvalid(m_axis_0_tvalid),
    .m_axis_0_tready(m_axis_0_tready),
    .m_axis_0_tid(m_axis_0_tid),
    .m_axis_0_tdest(m_axis_0_tdest),
    .m_axis_0_tuser(m_axis_0_tuser)
  );


  initial begin
    $dumpfile("../vcd/tb_Sech2Lutram.vcd");
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
    s_axis_0_tdata = 0;
    s_axis_0_tlast = 0;
    s_axis_0_tvalid = 0;
    m_axis_0_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #20;
    reset_done = 1;
    @(posedge clk);
    #1;
    #(2 * 2 ** DATA_WIDTH_DATA / CHANNELS);
    $finish;
  end

  reg [DATA_WIDTH_DATA-1:0] _tmp_0 [0:CHANNELS-1];
  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    reg [DATA_WIDTH_DATA-1:0] data_reg;
    wire [DATA_WIDTH_DATA-1:0] data_next;

    always @(*) begin
      s_axis_0_tdata[DATA_WIDTH_DATA*(CHN+1)-1:DATA_WIDTH_DATA*CHN] <= data_reg;
    end

    assign data_next = data_reg + CHANNELS;

    always @(posedge clk) begin
      if(reset_done) begin
        if((data_reg == 64 + CHN) || (data_reg == 64 + CHANNELS * (CHN + 3) + CHN)) begin
          s_axis_0_tvalid[CHN] <= 0;
        end 
        if(!s_axis_0_tvalid[CHN]) begin
          s_axis_0_tvalid[CHN] <= 1;
        end 
        if((data_reg == 64 + CHN) || (data_reg == 64 + CHANNELS * (CHN + 3) + CHN)) begin
          m_axis_0_tready[CHN] <= 0;
        end 
        if(!m_axis_0_tready[CHN]) begin
          m_axis_0_tready[CHN] <= 1;
        end 
        if(data_next % 2 ** (CHN + 1) == 0) begin
          s_axis_0_tlast[CHN] <= 1;
        end 
        if(data_next == 2 ** CHN) begin
          s_axis_0_tlast[CHN] <= 1;
        end 
        if(s_axis_0_tlast[CHN] && s_axis_0_tready[CHN] && s_axis_0_tvalid[CHN]) begin
          s_axis_0_tlast[CHN] <= 0;
        end 
        if(s_axis_0_tready[CHN] && s_axis_0_tvalid[CHN]) begin
          data_reg <= data_next;
        end 
      end else begin
        data_reg <= CHN;
      end
    end

  end
  endgenerate


endmodule

`resetall
