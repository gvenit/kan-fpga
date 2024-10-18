
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_RSWAFFunction
(

);

  localparam DATA_WIDTH_DATA = 16;
  localparam FRACTIONAL_BITS_DATA = 12;
  localparam DATA_WIDTH_SCALE = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_SCALE = 12;
  localparam DATA_WIDTH_SCALED_DIFF = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_SCALED_DIFF = 13;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_DATA;
  localparam FRACTIONAL_BITS_RSLT = 16;
  localparam KEEP_ENABLE = DATA_WIDTH_RSLT > 8;
  localparam KEEP_WIDTH = (DATA_WIDTH_RSLT + 7) / 8;
  localparam ID_ENABLE = 0;
  localparam ID_WIDTH = 8;
  localparam DEST_ENABLE = 0;
  localparam DEST_WIDTH = 8;
  localparam USER_ENABLE = 0;
  localparam USER_WIDTH = 1;
  localparam CHANNELS = 5;
  localparam USE_UNSIGNED = 1;
  localparam SHARE_SCALE = 1;
  localparam SCALE_CHANNELS = (SHARE_SCALE)? 1 : CHANNELS;
  reg clk;
  reg rst;
  reg [CHANNELS*DATA_WIDTH_DATA-1+1-1:0] s_axis_data_tdata;
  reg [CHANNELS-1+1-1:0] s_axis_data_tvalid;
  wire [CHANNELS-1+1-1:0] s_axis_data_tready;
  reg [CHANNELS-1+1-1:0] s_axis_data_tlast;
  reg [CHANNELS*ID_WIDTH-1+1-1:0] s_axis_data_tid;
  reg [CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_data_tdest;
  reg [CHANNELS*USER_WIDTH-1+1-1:0] s_axis_data_tuser;
  reg [CHANNELS*DATA_WIDTH_DATA-1+1-1:0] s_axis_grid_tdata;
  reg [CHANNELS-1+1-1:0] s_axis_grid_tvalid;
  wire [CHANNELS-1+1-1:0] s_axis_grid_tready;
  reg [CHANNELS-1+1-1:0] s_axis_grid_tlast;
  reg [CHANNELS*ID_WIDTH-1+1-1:0] s_axis_grid_tid;
  reg [CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_grid_tdest;
  reg [CHANNELS*USER_WIDTH-1+1-1:0] s_axis_grid_tuser;
  reg [SCALE_CHANNELS*DATA_WIDTH_SCALE-1+1-1:0] s_axis_scale_tdata;
  reg [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tvalid;
  wire [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tready;
  reg [SCALE_CHANNELS-1+1-1:0] s_axis_scale_tlast;
  reg [SCALE_CHANNELS*ID_WIDTH-1+1-1:0] s_axis_scale_tid;
  reg [SCALE_CHANNELS*DEST_WIDTH-1+1-1:0] s_axis_scale_tdest;
  reg [SCALE_CHANNELS*USER_WIDTH-1+1-1:0] s_axis_scale_tuser;
  wire [CHANNELS*DATA_WIDTH_RSLT-1+1-1:0] m_axis_data_tdata;
  wire [CHANNELS*KEEP_WIDTH-1+1-1:0] m_axis_data_tkeep;
  wire [CHANNELS-1+1-1:0] m_axis_data_tvalid;
  reg [CHANNELS-1+1-1:0] m_axis_data_tready;
  wire [CHANNELS-1+1-1:0] m_axis_data_tlast;
  wire [CHANNELS*ID_WIDTH-1+1-1:0] m_axis_data_tid;
  wire [CHANNELS*DEST_WIDTH-1+1-1:0] m_axis_data_tdest;
  wire [CHANNELS*USER_WIDTH-1+1-1:0] m_axis_data_tuser;
  reg reset_done;

  RSWAFFunction
  #(
    .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH_SCALED_DIFF),
    .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
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
    .CHANNELS(CHANNELS),
    .USE_UNSIGNED(USE_UNSIGNED),
    .SHARE_SCALE(SHARE_SCALE),
    .SCALE_CHANNELS(SCALE_CHANNELS)
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
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tkeep(m_axis_data_tkeep),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tid(m_axis_data_tid),
    .m_axis_data_tdest(m_axis_data_tdest),
    .m_axis_data_tuser(m_axis_data_tuser)
  );


  initial begin
    $dumpfile("../vcd/tb_RSWAFFunction.vcd");
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
    s_axis_grid_tlast = 0;
    s_axis_grid_tvalid = 0;
    s_axis_scale_tdata = 0;
    s_axis_scale_tlast = 0;
    s_axis_scale_tvalid = 0;
    m_axis_data_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_data_tready = -1;
    #500;
    $finish;
  end

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    integer _tmp_0;
    integer _tmp_1;

    always @(posedge clk) begin
      if(reset_done) begin
        _tmp_1 <= (count_grid + CHN) % 5;
        _tmp_0 <= (count_data + CHN) / 5 % 5;
        if(CHN == 0) begin
          $display("Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X", count_data, count_grid, s_axis_data_tready, s_axis_data_tvalid, s_axis_data_tlast, s_axis_grid_tready, s_axis_grid_tvalid, s_axis_grid_tlast, s_axis_scale_tready, s_axis_scale_tvalid, s_axis_scale_tlast, m_axis_data_tready, m_axis_data_tvalid, m_axis_data_tlast);
        end 
        if(s_axis_data_tready[CHN] && s_axis_data_tvalid[CHN]) begin
          count_data <= count_data + 1;
        end 
        if(s_axis_grid_tready[CHN] && s_axis_grid_tvalid[CHN]) begin
          count_grid <= count_grid + 1;
        end 
        if(count_data == 0) begin
          s_axis_scale_tdata <= 1 << FRACTIONAL_BITS_SCALE;
          s_axis_scale_tlast[CHN] <= 1;
          s_axis_scale_tvalid[CHN] <= 1;
        end 
        if((count_data != 0) && (count_data < 25)) begin
          s_axis_scale_tdata <= 5 << FRACTIONAL_BITS_SCALE;
        end 
        if(count_data == 25) begin
          s_axis_scale_tdata <= 1 << FRACTIONAL_BITS_SCALE - 1;
          s_axis_scale_tlast[CHN] <= 0;
          s_axis_scale_tvalid[CHN] <= 0;
        end 
        if((count_data > 25) && (count_data < 50)) begin
          s_axis_scale_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= s_axis_scale_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] + 8;
        end 
        case(_tmp_0)
          4: begin
            s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 4 << FRACTIONAL_BITS_DATA;
          end
          3: begin
            s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 1 << FRACTIONAL_BITS_DATA - 1;
          end
          2: begin
            s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 0;
          end
          1: begin
            s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= -1 << FRACTIONAL_BITS_DATA - 1;
          end
          default: begin
            s_axis_data_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= -4 << FRACTIONAL_BITS_DATA;
          end
        endcase
        case(_tmp_1)
          4: begin
            s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 4 << FRACTIONAL_BITS_DATA;
          end
          3: begin
            s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 1 << FRACTIONAL_BITS_DATA - 1;
          end
          2: begin
            s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= 0;
          end
          1: begin
            s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= -1 << FRACTIONAL_BITS_DATA - 1;
          end
          default: begin
            s_axis_grid_tdata[(CHN+1)*DATA_WIDTH_DATA-1:CHN*DATA_WIDTH_DATA] <= -4 << FRACTIONAL_BITS_DATA;
          end
        endcase
        if(!s_axis_data_tvalid[CHN] && (count_data < 70)) begin
          s_axis_data_tvalid[CHN] <= 1;
        end 
        if(!s_axis_grid_tvalid[CHN] && (count_grid < 70)) begin
          s_axis_grid_tvalid[CHN] <= 1;
        end 
        if((count_data == 25 / CHANNELS - 1) || (count_data == 60) || (count_data == 80)) begin
          s_axis_data_tlast[CHN] <= 1;
        end 
        if((count_grid == 25 / CHANNELS - 1) || (count_grid == 60) || (count_grid == 80)) begin
          s_axis_grid_tlast[CHN] <= 1;
        end 
        if(s_axis_data_tready[CHN] && s_axis_data_tvalid[CHN] && s_axis_data_tlast[CHN] || (count_data > 80)) begin
          s_axis_data_tlast[CHN] <= 0;
        end 
        if(s_axis_grid_tready[CHN] && s_axis_grid_tvalid[CHN] && s_axis_grid_tlast[CHN] || (count_grid > 80)) begin
          s_axis_grid_tlast[CHN] <= 0;
        end 
        if((count_data == 25 / CHANNELS + 2) && m_axis_data_tvalid[CHN]) begin
          s_axis_data_tvalid[CHN] <= 0;
        end 
        if((count_grid == 25 / CHANNELS + 2) && m_axis_data_tvalid[CHN]) begin
          s_axis_grid_tvalid[CHN] <= 0;
        end 
        if((count_data == 1) && m_axis_data_tvalid[CHN]) begin
          s_axis_scale_tvalid[CHN] <= 1;
        end 
        if(s_axis_scale_tvalid[CHN]) begin
          s_axis_scale_tvalid[CHN] <= 0;
        end 
        if((count_data > 70) && !timer_data && !m_axis_data_tvalid[CHN]) begin
          $finish;
        end 
        if(CHN == 0) begin
          count2_data <= count_data;
          if((count_data == count2_data) || !(s_axis_data_tvalid[CHN] || m_axis_data_tready[CHN])) begin
            if(timer_data) begin
              timer_data <= timer_data - 1;
            end else begin
              timer_data <= 3;
            end
          end else begin
            timer_data <= 3;
          end
          if((count_grid == count2_grid) || !(s_axis_grid_tvalid[CHN] || m_axis_data_tready[CHN])) begin
            if(timer_grid) begin
              timer_grid <= timer_grid - 1;
            end else begin
              timer_grid <= 3;
            end
          end else begin
            timer_grid <= 3;
          end
        end 
      end else begin
        if(CHN == 0) begin
          count_data <= 0;
          count_grid <= 0;
        end 
      end
    end

  end
  endgenerate

  integer count_data;
  integer count_grid;
  integer count2_data;
  integer count2_grid;
  integer timer_data;
  integer timer_grid;

endmodule

`resetall
