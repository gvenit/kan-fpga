
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_AXISFIFO
(

);

  localparam DATA_WIDTH = 16;
  localparam ADDRESS_WIDTH = 2;
  reg clk;
  reg rst;
  reg [DATA_WIDTH-1:0] s_axis_0_tdata;
  reg s_axis_0_tvalid;
  wire s_axis_0_tready;
  reg s_axis_0_tlast;
  wire [DATA_WIDTH-1:0] m_axis_0_tdata;
  wire m_axis_0_tvalid;
  reg m_axis_0_tready;
  wire m_axis_0_tlast;
  reg reset_done;

  AXISFifo
  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH)
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
    $dumpfile("../vcd/tb_AXISFifo.vcd");
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
    s_axis_0_tdata = -1;
    m_axis_0_tready = 1;
    timer = 2 ** ADDRESS_WIDTH - 1;
    @(posedge clk);
    #1;
  end

  integer count;
  integer count2;
  integer timer;

  always @(posedge clk) begin
    if(reset_done) begin
      $display("Count : %d -- %d:%d:%d:%X:%X:%X", (count - 1), s_axis_0_tready, s_axis_0_tvalid, s_axis_0_tlast, m_axis_0_tready, m_axis_0_tvalid, m_axis_0_tlast);
      if(s_axis_0_tready && s_axis_0_tvalid) begin
        count <= count + 1;
      end 
      if(!s_axis_0_tvalid && (count < 44)) begin
        s_axis_0_tvalid <= 1;
      end 
      if((count == 20 + 2 ** ADDRESS_WIDTH) || (count == 40)) begin
        s_axis_0_tlast <= 1;
      end 
      if((count < 1) && timer || s_axis_0_tready && s_axis_0_tlast || (count > 40)) begin
        s_axis_0_tlast <= 0;
        s_axis_0_tvalid <= 0;
      end 
      if((count > 40) && !timer) begin
        $finish;
      end 
      count2 <= count;
      if((count == count2) || !(s_axis_0_tvalid || m_axis_0_tready)) begin
        if(timer) begin
          timer <= timer - 1;
        end else begin
          timer <= 2 ** ADDRESS_WIDTH - 1;
        end
      end 
    end 
  end

  integer _tmp_0;

  always @(posedge clk) begin
    if(reset_done) begin
      _tmp_0 <= count % 4;
      case(_tmp_0)
        3: begin
          s_axis_0_tdata <= 47806;
        end
        2: begin
          s_axis_0_tdata <= 51966;
        end
        1: begin
          s_axis_0_tdata <= 48815;
        end
        default: begin
          s_axis_0_tdata <= 57005;
        end
      endcase
      if((count >= 21) && (count <= 21 + 2 ** ADDRESS_WIDTH + 1) && timer || (count >= 40 - 2 ** ADDRESS_WIDTH) && (count < 40) && timer || (count > 44)) begin
        m_axis_0_tready <= 0;
      end else if(!m_axis_0_tready) begin
        m_axis_0_tready <= 1;
      end 
    end 
  end


endmodule



module AXISFifo #
(
  parameter DATA_WIDTH = 16,
  parameter ADDRESS_WIDTH = 4
)
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] s_axis_0_tdata,
  input s_axis_0_tvalid,
  output s_axis_0_tready,
  input s_axis_0_tlast,
  output [DATA_WIDTH-1:0] m_axis_0_tdata,
  output m_axis_0_tvalid,
  input m_axis_0_tready,
  output m_axis_0_tlast,
  output full,
  output almost_full,
  output empty,
  output almost_empty
);

  reg s_axis_0_tready_int;
  reg m_axis_0_tvalid_int;
  wire enq;
  wire deq;
  localparam EXP_ADDR_WIDTH = 2 ** ADDRESS_WIDTH - 1;
  reg [DATA_WIDTH:0] mem [0:EXP_ADDR_WIDTH];
  reg [ADDRESS_WIDTH-1:0] head;
  reg [ADDRESS_WIDTH-1:0] tail;
  wire is_empty;
  wire is_almost_empty;
  wire is_full;
  wire is_almost_full;
  assign is_empty = head == tail;
  assign is_almost_empty = head == (tail + 1 & EXP_ADDR_WIDTH);
  assign is_full = (head + 1 & EXP_ADDR_WIDTH) == tail;
  assign is_almost_full = (head + 2 & EXP_ADDR_WIDTH) == tail;
  assign full = is_full;
  assign almost_full = is_almost_full || is_full;
  assign empty = is_empty;
  assign almost_empty = is_almost_empty || is_empty;
  assign s_axis_0_tready = s_axis_0_tready_int;
  assign m_axis_0_tvalid = m_axis_0_tvalid_int;
  integer i;

  initial begin
    head = 0;
    tail = 0;
    for(i=0; i<=EXP_ADDR_WIDTH; i=i+1) begin
      mem[i] = 0;
    end
  end


  always @(*) begin
    if(rst) begin
      s_axis_0_tready_int <= 0;
      m_axis_0_tvalid_int <= 0;
    end else begin
      s_axis_0_tready_int <= !is_full;
      m_axis_0_tvalid_int <= !is_empty;
    end
  end

  assign enq = s_axis_0_tready_int && s_axis_0_tvalid;
  assign deq = m_axis_0_tvalid_int && m_axis_0_tready;
  assign { m_axis_0_tlast, m_axis_0_tdata } = mem[tail];

  always @(posedge clk) begin
    if(rst) begin
      head <= 0;
      tail <= 0;
    end else begin
      if(enq) begin
        mem[head] <= { s_axis_0_tlast, s_axis_0_tdata };
        head <= head + 1;
      end 
      if(deq) begin
        tail <= tail + 1;
      end 
    end
  end


endmodule

