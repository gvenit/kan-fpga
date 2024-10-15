
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_AXISCombiner
(

);

  localparam DATA_WIDTH = 16;
  localparam CHANNELS = 4;
  localparam FIFO_DEPTH = 4;
  reg clk;
  reg rst;
  reg [DATA_WIDTH*CHANNELS-1:0] s_axis_0_tdata;
  reg [CHANNELS-1:0] s_axis_0_tlast;
  reg [CHANNELS-1:0] s_axis_0_tvalid;
  wire [CHANNELS-1:0] s_axis_0_tready;
  wire [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata;
  wire [CHANNELS-1:0] m_axis_0_tkeep;
  wire m_axis_0_tlast;
  wire m_axis_0_tvalid;
  reg m_axis_0_tready;
  reg reset_done;

  AXISCombiner
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
    .m_axis_0_tkeep(m_axis_0_tkeep),
    .m_axis_0_tlast(m_axis_0_tlast),
    .m_axis_0_tvalid(m_axis_0_tvalid),
    .m_axis_0_tready(m_axis_0_tready)
  );


  initial begin
    $dumpfile("../vcd/tb_AXISCombiner.vcd");
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
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_0_tready = 1;
    #500;
    $finish;
  end

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    integer count;
    integer count2;
    integer timer;
    integer _tmp_0;

    always @(*) begin
      if(CHN == 0) begin
        count_Ref <= count;
        timer_Ref <= timer;
      end 
      _tmp_0 <= (count + CHN) % CHANNELS;
    end


    always @(posedge clk) begin
      if(reset_done) begin
        if(CHN == 0) begin
          $display("Count : %d -- %X:%X:%X:%X:%X:%X", count, s_axis_0_tready, s_axis_0_tvalid, s_axis_0_tlast, m_axis_0_tready, m_axis_0_tvalid, m_axis_0_tlast);
        end 
        if(s_axis_0_tready[CHN] && s_axis_0_tvalid[CHN]) begin
          count <= count + 1;
        end 
        case(_tmp_0)
          3: begin
            s_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] <= 57005;
          end
          2: begin
            s_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] <= 48815;
          end
          1: begin
            s_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] <= 51966;
          end
          default: begin
            s_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] <= 47806;
          end
        endcase
        if(!s_axis_0_tvalid[CHN] && (count < 70)) begin
          s_axis_0_tvalid[CHN] <= 1;
        end 
        if((count == 20 + FIFO_DEPTH) || (count == 60 - 2 * FIFO_DEPTH + (CHANNELS - 1) * CHN) || (count == 80 - FIFO_DEPTH)) begin
          s_axis_0_tlast[CHN] <= 1;
        end 
        if(s_axis_0_tready[CHN] && s_axis_0_tlast[CHN] || (count > 80 + FIFO_DEPTH)) begin
          s_axis_0_tlast[CHN] <= 0;
          s_axis_0_tvalid[CHN] <= 0;
        end 
        if((count == 20 + FIFO_DEPTH + 1) && m_axis_0_tvalid || (count >= 40) && (count <= 41) && m_axis_0_tvalid) begin
          s_axis_0_tvalid[CHN] <= 0;
        end 
        if((CHN == CHANNELS - 1) && (count > 70 + FIFO_DEPTH) && !timer && !m_axis_0_tvalid) begin
          $finish;
        end 
        count2 <= count;
        if((count == count2) || !(s_axis_0_tvalid[CHN] || m_axis_0_tready)) begin
          if(timer) begin
            timer <= timer - 1;
          end else begin
            timer <= FIFO_DEPTH - 1;
          end
        end else begin
          timer <= FIFO_DEPTH - 1;
        end
      end else begin
        count <= 0;
      end
    end

  end
  endgenerate

  integer count_Ref;
  integer timer_Ref;

  always @(posedge clk) begin
    if(reset_done) begin
      if((count_Ref >= 21) && (count_Ref < 21 + FIFO_DEPTH) && timer_Ref || (count_Ref == 80 - FIFO_DEPTH) && timer_Ref || (count_Ref > 80 + FIFO_DEPTH)) begin
        m_axis_0_tready <= 0;
      end else begin
        m_axis_0_tready <= 1;
      end
    end 
  end


endmodule



module AXISCombiner #
(
  parameter DATA_WIDTH = 16,
  parameter CHANNELS = 16
)
(
  input clk,
  input rst,
  input [DATA_WIDTH*CHANNELS-1:0] s_axis_0_tdata,
  input [CHANNELS-1:0] s_axis_0_tlast,
  input [CHANNELS-1:0] s_axis_0_tvalid,
  output [CHANNELS-1:0] s_axis_0_tready,
  output [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tkeep,
  output m_axis_0_tlast,
  output m_axis_0_tvalid,
  input m_axis_0_tready
);

  localparam FIFO_DEPTH = 4;
  reg [DATA_WIDTH*CHANNELS-1:0] data_reg;
  reg [CHANNELS-1:0] data_keep_reg;
  reg [CHANNELS-1:0] data_last_reg;
  wire [DATA_WIDTH*CHANNELS-1:0] data_reg_next;
  wire [DATA_WIDTH*CHANNELS-1:0] data_in_next;
  wire [CHANNELS-1:0] data_keep_next;
  wire [CHANNELS-1:0] data_keep_reg_next;
  wire [CHANNELS-1:0] data_keep_in_next;
  wire [CHANNELS-1:0] data_last_in_next;
  wire [CHANNELS-1:0] data_last_reg_next;
  wire [CHANNELS-1:0] data_ready_in_next;
  wire [CHANNELS-1:0] data_ready_in_early_next;
  wire [CHANNELS-1:0] data_valid_in_next;
  wire generate_tlast;
  wire output_handshake;
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
    wire m_fifo_handshake;

    always @(*) begin
      s_fifo_tdata <= s_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN];
    end

    assign s_fifo_tlast = s_axis_0_tlast[CHN];
    assign s_fifo_tvalid = s_axis_0_tvalid[CHN];
    assign s_axis_0_tready[CHN] = s_fifo_tready;
    assign s_fifo_handshake = s_fifo_tready && s_fifo_tvalid;
    assign data_keep_next[CHN] = (s_fifo_handshake)? 0 : s_fifo_tvalid;
    assign m_fifo_handshake = m_fifo_tready && m_fifo_tvalid;
    assign data_in_next[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = m_fifo_tdata;
    assign m_fifo_tready = data_ready_in_next[CHN];
    assign data_valid_in_next[CHN] = m_fifo_tvalid;
    assign data_last_in_next[CHN] = m_fifo_tlast;

    AXISFifo
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
    )
    AXISFifo_in_inst_i
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_fifo_tdata),
      .s_axis_0_tlast(s_fifo_tlast),
      .s_axis_0_tvalid(s_fifo_tvalid),
      .s_axis_0_tready(s_fifo_tready),
      .m_axis_0_tdata(m_fifo_tdata),
      .m_axis_0_tlast(m_fifo_tlast),
      .m_axis_0_tvalid(m_fifo_tvalid),
      .m_axis_0_tready(m_fifo_tready)
    );

    assign data_ready_in_early_next[CHN] = !data_keep_reg[CHN] | output_handshake;
    assign data_ready_in_next[CHN] = data_ready_in_early_next[CHN] && (generate_tlast || !data_last_reg[CHN]);
    assign data_keep_in_next[CHN] = m_fifo_handshake;
    assign data_reg_next[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = (data_keep_in_next[CHN])? data_in_next[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] : data_reg[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN];
  end
  endgenerate

  assign output_handshake = generate_tvalid & data_ready_in;
  assign data_keep_reg_next = (output_handshake)? data_keep_in_next : data_keep_reg | data_keep_in_next;
  assign data_last_reg_next = (output_handshake & generate_tlast)? data_last_in_next : data_last_reg | data_last_in_next & data_keep_in_next & data_ready_in_early_next;
  assign generate_tlast = &data_last_reg;
  assign generate_tvalid = |data_keep_reg;

  always @(posedge clk) begin
    if(rst) begin
      data_reg <= 0;
      data_keep_reg <= 0;
      data_last_reg <= 0;
    end else begin
      data_reg <= data_reg_next;
      data_keep_reg <= data_keep_reg_next;
      data_last_reg <= data_last_reg_next;
    end
  end


  AXISFifo
  #(
    .DATA_WIDTH((DATA_WIDTH + 1) * CHANNELS),
    .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
  )
  AXISFifo_out_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata({ data_reg, data_keep_reg }),
    .s_axis_0_tlast(generate_tlast),
    .s_axis_0_tvalid(generate_tvalid),
    .s_axis_0_tready(data_ready_in),
    .m_axis_0_tdata({ m_axis_0_tdata, m_axis_0_tkeep }),
    .m_axis_0_tlast(m_axis_0_tlast),
    .m_axis_0_tvalid(m_axis_0_tvalid),
    .m_axis_0_tready(m_axis_0_tready)
  );


endmodule

`resetall
