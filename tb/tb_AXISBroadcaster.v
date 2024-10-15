
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_AXISBroadcaster
(

);

  localparam DATA_WIDTH = 16;
  localparam CHANNELS = 4;
  reg clk;
  reg rst;
  reg [DATA_WIDTH-1:0] s_axis_0_tdata;
  reg s_axis_0_tvalid;
  wire s_axis_0_tready;
  reg s_axis_0_tlast;
  wire [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata;
  wire [CHANNELS-1:0] m_axis_0_tvalid;
  reg [CHANNELS-1:0] m_axis_0_tready;
  wire [CHANNELS-1:0] m_axis_0_tlast;
  reg reset_done;

  AXISBroadcaster
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .CHANNELS(CHANNELS)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(s_axis_0_tdata),
    .s_axis_0_tvalid(s_axis_0_tvalid),
    .s_axis_0_tready(s_axis_0_tready),
    .s_axis_0_tlast(s_axis_0_tlast),
    .m_axis_0_tdata(m_axis_0_tdata),
    .m_axis_0_tvalid(m_axis_0_tvalid),
    .m_axis_0_tready(m_axis_0_tready),
    .m_axis_0_tlast(m_axis_0_tlast)
  );


  initial begin
    $dumpfile("../vcd/tb_AXISBroadcaster.vcd");
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
    s_axis_0_tvalid = 0;
    s_axis_0_tlast = 0;
    m_axis_0_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    count = 0;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_0_tready = -1;
    #500;
    $finish;
  end

  integer count;
  integer count2;
  integer timer;
  integer _tmp_0;

  always @(posedge clk) begin
    if(reset_done) begin
      $display("Count : %d -- %d:%d:%d:%X:%X:%X", count, s_axis_0_tready, s_axis_0_tvalid, s_axis_0_tlast, m_axis_0_tready, m_axis_0_tvalid, m_axis_0_tlast);
      if(s_axis_0_tready && s_axis_0_tvalid) begin
        count <= count + 1;
      end 
      _tmp_0 <= count % CHANNELS;
      case(_tmp_0)
        3: begin
          s_axis_0_tdata <= 57005;
        end
        2: begin
          s_axis_0_tdata <= 48815;
        end
        1: begin
          s_axis_0_tdata <= 51966;
        end
        default: begin
          s_axis_0_tdata <= 47806;
        end
      endcase
      if(!s_axis_0_tvalid && (count < 60)) begin
        s_axis_0_tvalid <= 1;
      end 
      if((count == 24) || (count == 52) || (count == 76)) begin
        s_axis_0_tlast <= 1;
      end 
      if(s_axis_0_tready && s_axis_0_tlast || (count > 84)) begin
        s_axis_0_tlast <= 0;
        s_axis_0_tvalid <= 0;
      end 
      if((count == 25) && m_axis_0_tvalid) begin
        s_axis_0_tvalid <= 0;
      end 
      if((count > 84) && !timer) begin
        $finish;
      end 
      count2 <= count;
      if((count == count2) || !(s_axis_0_tvalid || m_axis_0_tready)) begin
        if(timer) begin
          timer <= timer - 1;
        end else begin
          timer <= 3;
        end
      end else begin
        timer <= 3;
      end
    end 
  end

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin

    always @(posedge clk) begin
      if(reset_done) begin
        if((count >= 21 + CHN) && (count < 21 + CHN + 2) && timer || (count >= 76 - CHN) && (count < 80 - CHN) && timer || (count > 84)) begin
          m_axis_0_tready[CHN] <= 0;
        end else begin
          m_axis_0_tready[CHN] <= 1;
        end
      end 
    end

  end
  endgenerate


endmodule



module AXISBroadcaster #
(
  parameter DATA_WIDTH = 16,
  parameter CHANNELS = 16
)
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] s_axis_0_tdata,
  input s_axis_0_tvalid,
  output s_axis_0_tready,
  input s_axis_0_tlast,
  output [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tvalid,
  input [CHANNELS-1:0] m_axis_0_tready,
  output [CHANNELS-1:0] m_axis_0_tlast
);

  localparam FIFO_DEPTH = 4;
  reg [DATA_WIDTH:0] data_reg;
  reg [CHANNELS-1:0] data_keep_reg;
  wire s_axis_0_tready_reg;
  wire [DATA_WIDTH:0] data_reg_next;
  wire [DATA_WIDTH:0] data_in_next;
  wire [CHANNELS-1:0] data_keep_next;
  wire [CHANNELS-1:0] data_keep_reg_next;
  wire [CHANNELS-1:0] data_keep_in_next;
  wire load_from_reg;
  wire load_from_in;
  wire input_handshake;
  assign load_from_reg = |data_keep_next;
  assign load_from_in = !load_from_reg;
  assign input_handshake = (load_from_in)? s_axis_0_tvalid & s_axis_0_tready_reg : 0;
  assign data_in_next = (input_handshake)? { s_axis_0_tlast, s_axis_0_tdata } : data_reg;
  assign data_reg_next = (load_from_reg)? data_reg : data_in_next;
  assign data_keep_in_next = (input_handshake)? -1 : data_keep_next;
  assign data_keep_reg_next = (load_from_reg)? data_keep_next : data_keep_in_next;
  assign s_axis_0_tready = s_axis_0_tready_reg;
  assign s_axis_0_tready_reg = (rst)? 0 : load_from_in;

  always @(posedge clk) begin
    if(rst) begin
      data_reg <= 0;
      data_keep_reg <= 0;
    end else begin
      data_reg <= data_reg_next;
      data_keep_reg <= data_keep_reg_next;
    end
  end

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    reg [DATA_WIDTH-1:0] s_fifo_tdata;
    wire [DATA_WIDTH-1:0] m_fifo_tdata;
    wire s_fifo_tready;
    wire m_fifo_tready;
    wire s_fifo_tvalid;
    wire m_fifo_tvalid;
    wire s_fifo_tlast;
    wire m_fifo_tlast;
    wire s_fifo_handshake;
    wire m_fifo_handshake;

    always @(*) begin
      s_fifo_tdata <= data_reg[DATA_WIDTH-1:0];
    end

    assign s_fifo_tlast = data_reg[DATA_WIDTH];
    assign s_fifo_tvalid = data_keep_reg;
    assign s_fifo_handshake = s_fifo_tready && s_fifo_tvalid;
    assign data_keep_next[CHN] = (s_fifo_handshake)? 0 : s_fifo_tvalid;
    assign m_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = m_fifo_tdata;
    assign m_fifo_tready = m_axis_0_tready[CHN];
    assign m_axis_0_tvalid[CHN] = m_fifo_tvalid;
    assign m_axis_0_tlast[CHN] = m_fifo_tlast;

    AXISFifo
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
    )
    AXISFifo_inst_i
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_fifo_tdata),
      .s_axis_0_tvalid(s_fifo_tvalid),
      .s_axis_0_tready(s_fifo_tready),
      .s_axis_0_tlast(s_fifo_tlast),
      .m_axis_0_tdata(m_fifo_tdata),
      .m_axis_0_tvalid(m_fifo_tvalid),
      .m_axis_0_tready(m_fifo_tready),
      .m_axis_0_tlast(m_fifo_tlast)
    );

  end
  endgenerate


endmodule

`resetall