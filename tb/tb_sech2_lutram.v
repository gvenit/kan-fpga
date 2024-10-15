
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_sech2_lutram
(

);

  localparam DATA_WIDTH_IN = 16;
  localparam DATA_WIDTH_OUT = 16;
  localparam FRACTIONAL_BITS_IN = 12;
  localparam FRACTIONAL_BITS_OUT = 16;
  localparam CHANNELS = 1;
  localparam EXTRA_CYCLE = 1;
  reg clk;
  reg rst;
  reg [DATA_WIDTH_IN*CHANNELS-1:0] s_axis_0_tdata;
  reg [CHANNELS-1:0] s_axis_0_tlast;
  reg [CHANNELS-1:0] s_axis_0_tvalid;
  wire [CHANNELS-1:0] s_axis_0_tready;
  wire [DATA_WIDTH_OUT*CHANNELS-1:0] m_axis_0_tdata;
  wire [CHANNELS-1:0] m_axis_0_tlast;
  wire [CHANNELS-1:0] m_axis_0_tvalid;
  reg [CHANNELS-1:0] m_axis_0_tready;
  reg reset_done;

  sech2_lutram
  #(
    .DATA_WIDTH_IN(DATA_WIDTH_IN),
    .DATA_WIDTH_OUT(DATA_WIDTH_OUT),
    .FRACTIONAL_BITS_IN(FRACTIONAL_BITS_IN),
    .FRACTIONAL_BITS_OUT(FRACTIONAL_BITS_OUT),
    .CHANNELS(CHANNELS),
    .EXTRA_CYCLE(EXTRA_CYCLE)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(s_axis_0_tdata),
    .s_axis_0_tlast(s_axis_0_tlast),
    .s_axis_0_tvalid(s_axis_0_tvalid),
    .s_axis_0_tready(s_axis_0_tready),
    .m_axis_0_tdata(m_axis_0_tdata),
    .m_axis_0_tlast(m_axis_0_tlast),
    .m_axis_0_tvalid(m_axis_0_tvalid),
    .m_axis_0_tready(m_axis_0_tready)
  );


  initial begin
    $dumpfile("../vcd/tb_sech2_lutram.vcd");
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
    s_axis_0_tvalid = -1;
    m_axis_0_tready = -1;
    @(posedge clk);
    #1;
    #(2 * 2 ** DATA_WIDTH_IN / CHANNELS);
    $finish;
  end

  reg [DATA_WIDTH_IN-1:0] _tmp_0 [0:CHANNELS-1];
  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    reg [DATA_WIDTH_IN-1:0] data_reg;
    wire [DATA_WIDTH_IN-1:0] data_next;

    always @(*) begin
      s_axis_0_tdata[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN] <= data_reg;
    end

    assign data_next = data_reg + CHANNELS;

    always @(posedge clk) begin
      if(reset_done) begin
        if((data_reg == 65 + CHN) || (data_reg == 65 + CHN + 3)) begin
          s_axis_0_tvalid[CHN] <= 0;
        end 
        if(!s_axis_0_tvalid[CHN]) begin
          s_axis_0_tvalid[CHN] <= 1;
        end 
        if((data_reg == 65 + CHN) || (data_reg == 65 + CHN + 3)) begin
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
        data_reg <= 2 ** (DATA_WIDTH_IN - 1) + CHN;
      end
    end

  end
  endgenerate


endmodule



module sech2_lutram #
(
  parameter DATA_WIDTH_IN = 16,
  parameter DATA_WIDTH_OUT = 16,
  parameter FRACTIONAL_BITS_IN = 12,
  parameter FRACTIONAL_BITS_OUT = 16,
  parameter CHANNELS = 1,
  parameter EXTRA_CYCLE = 0
)
(
  input clk,
  input rst,
  input [DATA_WIDTH_IN*CHANNELS-1:0] s_axis_0_tdata,
  input [CHANNELS-1:0] s_axis_0_tlast,
  input [CHANNELS-1:0] s_axis_0_tvalid,
  output [CHANNELS-1:0] s_axis_0_tready,
  output [DATA_WIDTH_OUT*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tlast,
  output [CHANNELS-1:0] m_axis_0_tvalid,
  input [CHANNELS-1:0] m_axis_0_tready
);

  reg [321-1:0] ROM_DATA_PATH;
  reg [DATA_WIDTH_OUT-1:0] LUTRAM_ARRAY [0:2**DATA_WIDTH_IN-1];

  initial begin
    $sformat(ROM_DATA_PATH, "../data/sech2_lutram_%0d.%0d_%0d.%0d.txt", DATA_WIDTH_IN, FRACTIONAL_BITS_IN, DATA_WIDTH_OUT, FRACTIONAL_BITS_OUT);
    $display("ROM_DATA_PATH is : %s", ROM_DATA_PATH);
    $readmemh(ROM_DATA_PATH, LUTRAM_ARRAY);
  end

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    wire [DATA_WIDTH_IN-1:0] d_data_int_slice;
    wire d_last_int_slice;
    wire d_valid_int_slice;
    wire d_ready_int_slice;
    wire [DATA_WIDTH_OUT-1:0] q_data_int_slice;
    wire q_last_int_slice;
    wire q_valid_int_slice;
    wire q_ready_int_slice;
    wire [2+EXTRA_CYCLE-1:0] d_valid_int_next_slice;
    wire [2+EXTRA_CYCLE-1:0] d_ready_int_next_slice;
    wire [DATA_WIDTH_OUT-1:0] q_data_int_next_slice [0:1+EXTRA_CYCLE-1];
    wire [1+EXTRA_CYCLE-1:0] q_last_int_next_slice;
    reg [DATA_WIDTH_IN-1:0] d_data_int_reg_slice;
    reg d_last_int_reg_slice;
    reg [2+EXTRA_CYCLE-1:0] d_valid_int_reg_slice;
    reg [2+EXTRA_CYCLE-1:0] d_ready_int_reg_slice;
    reg [DATA_WIDTH_OUT-1:0] q_data_int_reg_slice [0:1+EXTRA_CYCLE-1];
    reg [1+EXTRA_CYCLE-1:0] q_last_int_reg_slice;
    wire [2+EXTRA_CYCLE-1:0] handshakes_next;
    reg [2+EXTRA_CYCLE-1:0] handshakes_reg;
    wire store_in_tmp_next;
    wire load_from_tmp_next;
    reg store_in_tmp_reg;
    reg load_from_tmp_reg;
    reg [DATA_WIDTH_IN-1:0] tmp_data;
    reg tmp_last;
    assign d_data_int_slice = s_axis_0_tdata[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign d_last_int_slice = s_axis_0_tlast[CHN];
    assign d_valid_int_slice = s_axis_0_tvalid[CHN];
    assign s_axis_0_tready[CHN] = d_ready_int_slice;
    assign m_axis_0_tdata[DATA_WIDTH_OUT*(CHN+1)-1:DATA_WIDTH_OUT*CHN] = q_data_int_slice;
    assign m_axis_0_tlast[CHN] = q_last_int_slice;
    assign m_axis_0_tvalid[CHN] = q_valid_int_slice;
    assign q_ready_int_slice = m_axis_0_tready[CHN];
    assign d_ready_int_slice = d_ready_int_next_slice[0];
    assign d_valid_int_next_slice[0] = d_valid_int_slice;
    assign d_ready_int_next_slice[1 + EXTRA_CYCLE] = q_ready_int_slice;
    assign q_valid_int_slice = d_valid_int_next_slice[1 + EXTRA_CYCLE];
    assign handshakes_next = d_ready_int_next_slice & d_valid_int_next_slice;
    assign store_in_tmp_next = handshakes_next[0] && d_valid_int_next_slice[1] && !d_ready_int_next_slice[1] && !load_from_tmp_reg;
    assign load_from_tmp_next = (load_from_tmp_reg)? !handshakes_next[1] : store_in_tmp_reg;
    assign d_ready_int_next_slice[0] = !load_from_tmp_next & (!d_valid_int_reg_slice[1] || d_ready_int_reg_slice[1] && d_valid_int_reg_slice[0]);
    if(EXTRA_CYCLE) begin
      assign d_valid_int_next_slice[1] = (handshakes_reg[0] | load_from_tmp_reg)? 1 : 
                                         (handshakes_reg[1])? 0 : d_valid_int_reg_slice[1];
    end 
    if(EXTRA_CYCLE) begin
      assign d_ready_int_next_slice[1] = !d_valid_int_reg_slice[2] || d_ready_int_next_slice[2] && d_valid_int_reg_slice[1];
    end 
    assign d_valid_int_next_slice[1 + EXTRA_CYCLE] = ((EXTRA_CYCLE)? handshakes_reg[EXTRA_CYCLE] : handshakes_reg[EXTRA_CYCLE] | load_from_tmp_reg)? 1 : 
                                                     (handshakes_reg[1 + EXTRA_CYCLE])? 0 : d_valid_int_reg_slice[1 + EXTRA_CYCLE];
    assign q_data_int_next_slice[0] = LUTRAM_ARRAY[d_data_int_reg_slice];
    assign q_last_int_next_slice[0] = d_last_int_reg_slice;
    if(EXTRA_CYCLE) begin
      assign q_data_int_next_slice[1] = q_data_int_reg_slice[0];
    end 
    if(EXTRA_CYCLE) begin
      assign q_last_int_next_slice[1] = q_last_int_reg_slice[0];
    end 
    assign q_data_int_slice = q_data_int_next_slice[EXTRA_CYCLE];
    assign q_last_int_slice = q_last_int_next_slice[EXTRA_CYCLE];

    always @(posedge clk) begin
      if(rst) begin
        d_valid_int_reg_slice <= 0;
        d_ready_int_reg_slice <= 0;
        handshakes_reg <= 0;
        store_in_tmp_reg <= 0;
        load_from_tmp_reg <= 0;
      end else begin
        d_valid_int_reg_slice <= d_valid_int_next_slice;
        d_ready_int_reg_slice <= d_ready_int_next_slice;
        handshakes_reg <= handshakes_next;
        store_in_tmp_reg <= store_in_tmp_next;
        load_from_tmp_reg <= load_from_tmp_next;
        if(handshakes_next[0]) begin
          if(store_in_tmp_next) begin
            tmp_data <= d_data_int_slice;
            tmp_last <= d_last_int_slice;
          end else begin
            d_data_int_reg_slice <= d_data_int_slice;
            d_last_int_reg_slice <= d_last_int_slice;
          end
        end else if(load_from_tmp_next) begin
          d_data_int_reg_slice <= tmp_data;
          d_last_int_reg_slice <= tmp_last;
        end 
        if(handshakes_next[1]) begin
          q_data_int_reg_slice[0] <= q_data_int_next_slice[0];
          q_last_int_reg_slice[0] <= q_last_int_next_slice[0];
        end 
        if(EXTRA_CYCLE) begin
          if(handshakes_next[2]) begin
            q_data_int_reg_slice[1] <= q_data_int_next_slice[1];
            q_last_int_reg_slice[1] <= q_last_int_next_slice[1];
          end 
        end 
      end
    end

  end
  endgenerate


endmodule

`resetall
