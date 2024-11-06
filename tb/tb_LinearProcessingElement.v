
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_LinearProcessingElement
(

);

  localparam PE_NUMBER_I = 4;
  localparam PE_NUMBER_J = 4;
  localparam PE_POSITION_I = 1;
  localparam PE_POSITION_J = 1;
  localparam DATA_WIDTH_OP0 = 16;
  localparam FRACTIONAL_BITS_OP0 = 13;
  localparam IS_UNSIGNED_OP0 = 0;
  localparam DATA_WIDTH_OP1 = DATA_WIDTH_OP0;
  localparam IS_UNSIGNED_OP1 = 0;
  localparam FRACTIONAL_BITS_OP1 = 15;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_OP0;
  localparam FRACTIONAL_BITS_RSLT = 15;
  localparam USER_WIDTH = 8;
  localparam OUTPUT_DEST = 1;
  localparam OUTPUT_ID = 1;
  localparam DATA_WIDTH_U_D = (DATA_WIDTH_OP1 > DATA_WIDTH_RSLT)? DATA_WIDTH_OP1 : DATA_WIDTH_RSLT;
  localparam DATA_WIDTH_L_R = 16;
  localparam OP1_USER_MASK = 1 << USER_WIDTH - 2;
  localparam RSLT_USER_MASK = 1 << USER_WIDTH - 1;
  reg clk;
  reg rst;
  reg [DATA_WIDTH_U_D-1+1-1:0] s_axis_up_tdata;
  reg s_axis_up_tvalid;
  wire s_axis_up_tready;
  reg s_axis_up_tlast;
  reg [USER_WIDTH-1+1-1:0] s_axis_up_tuser;
  reg [DATA_WIDTH_L_R-1+1-1:0] s_axis_left_tdata;
  reg s_axis_left_tvalid;
  wire s_axis_left_tready;
  reg s_axis_left_tlast;
  wire [DATA_WIDTH_U_D-1+1-1:0] m_axis_down_tdata;
  wire m_axis_down_tvalid;
  reg m_axis_down_tready;
  wire m_axis_down_tlast;
  wire [USER_WIDTH-1+1-1:0] m_axis_down_tuser;
  wire [DATA_WIDTH_L_R-1+1-1:0] m_axis_right_tdata;
  wire m_axis_right_tvalid;
  reg m_axis_right_tready;
  wire m_axis_right_tlast;
  wire err_unalligned_data;
  wire err_user_flag;
  reg reset_done;

  LinearProcessingElement
  #(
    .PE_NUMBER_I(PE_NUMBER_I),
    .PE_NUMBER_J(PE_NUMBER_J),
    .PE_POSITION_I(PE_POSITION_I),
    .PE_POSITION_J(PE_POSITION_J),
    .DATA_WIDTH_OP0(DATA_WIDTH_OP0),
    .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
    .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
    .DATA_WIDTH_OP1(DATA_WIDTH_OP1),
    .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
    .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .USER_WIDTH(USER_WIDTH),
    .OUTPUT_DEST(OUTPUT_DEST),
    .OUTPUT_ID(OUTPUT_ID),
    .DATA_WIDTH_U_D(DATA_WIDTH_U_D),
    .DATA_WIDTH_L_R(DATA_WIDTH_L_R),
    .OP1_USER_MASK(OP1_USER_MASK),
    .RSLT_USER_MASK(RSLT_USER_MASK)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_up_tdata(s_axis_up_tdata),
    .s_axis_up_tvalid(s_axis_up_tvalid),
    .s_axis_up_tready(s_axis_up_tready),
    .s_axis_up_tlast(s_axis_up_tlast),
    .s_axis_up_tuser(s_axis_up_tuser),
    .s_axis_left_tdata(s_axis_left_tdata),
    .s_axis_left_tvalid(s_axis_left_tvalid),
    .s_axis_left_tready(s_axis_left_tready),
    .s_axis_left_tlast(s_axis_left_tlast),
    .m_axis_down_tdata(m_axis_down_tdata),
    .m_axis_down_tvalid(m_axis_down_tvalid),
    .m_axis_down_tready(m_axis_down_tready),
    .m_axis_down_tlast(m_axis_down_tlast),
    .m_axis_down_tuser(m_axis_down_tuser),
    .m_axis_right_tdata(m_axis_right_tdata),
    .m_axis_right_tvalid(m_axis_right_tvalid),
    .m_axis_right_tready(m_axis_right_tready),
    .m_axis_right_tlast(m_axis_right_tlast),
    .err_unalligned_data(err_unalligned_data),
    .err_user_flag(err_user_flag)
  );


  initial begin
    $dumpfile("../vcd/tb_LinearProcessingElement.vcd");
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
    s_axis_left_tdata = 0;
    s_axis_left_tvalid = 0;
    s_axis_left_tlast = 0;
    s_axis_up_tdata = 0;
    s_axis_up_tlast = 0;
    s_axis_up_tvalid = 0;
    m_axis_down_tready = 0;
    m_axis_right_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_down_tready = 1;
    m_axis_right_tready = 1;
    #500;
    $finish;
  end

  integer count_op0;
  integer count_op1;
  integer count2_op0;
  integer count2_op1;
  integer timer_op0;
  integer timer_op1;
  integer _tmp_0;
  integer _tmp_1;

  always @(posedge clk) begin
    if(reset_done) begin
      _tmp_1 <= count_op1 % 5;
      _tmp_0 <= count_op0 / 5 % 5;
      $display("Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X", count_op0, count_op1, s_axis_left_tready, s_axis_left_tvalid, s_axis_left_tlast, s_axis_up_tready, s_axis_up_tvalid, s_axis_up_tlast, m_axis_right_tready, m_axis_right_tvalid, m_axis_right_tlast, m_axis_down_tready, m_axis_down_tvalid, m_axis_down_tlast);
      if(s_axis_left_tready && s_axis_left_tvalid) begin
        count_op0 <= count_op0 + 1;
      end 
      if(s_axis_up_tready && s_axis_up_tvalid) begin
        count_op1 <= count_op1 + 1;
      end 
      case(_tmp_0)
        4: begin
          s_axis_left_tdata <= 32768;
        end
        3: begin
          s_axis_left_tdata <= 4096;
        end
        2: begin
          s_axis_left_tdata <= 0;
        end
        1: begin
          s_axis_left_tdata <= -4096;
        end
        default: begin
          s_axis_left_tdata <= -32768;
        end
      endcase
      case(_tmp_1)
        4: begin
          s_axis_up_tdata <= 32768;
        end
        3: begin
          s_axis_up_tdata <= 4096;
        end
        2: begin
          s_axis_up_tdata <= 0;
        end
        1: begin
          s_axis_up_tdata <= -4096;
        end
        default: begin
          s_axis_up_tdata <= -32768;
        end
      endcase
      if(!s_axis_left_tvalid && (count_op0 < 70)) begin
        s_axis_left_tvalid <= 1;
      end 
      if(!s_axis_up_tvalid && (count_op1 < 70)) begin
        s_axis_up_tvalid <= 1;
        s_axis_up_tuser <= OP1_USER_MASK;
      end 
      if((count_op0 == 22) || (count_op0 == 60) || (count_op0 == 80)) begin
        s_axis_left_tlast <= 1;
      end 
      if((count_op1 == 24) || (count_op1 == 60) || (count_op1 == 80)) begin
        s_axis_up_tlast <= 1;
      end 
      if(s_axis_left_tready && s_axis_left_tvalid && s_axis_left_tlast || (count_op0 > 80)) begin
        s_axis_left_tlast <= 0;
      end 
      if(s_axis_up_tready && s_axis_up_tvalid && s_axis_up_tlast || (count_op1 > 80)) begin
        s_axis_up_tlast <= 0;
      end 
      if(s_axis_up_tuser | RSLT_USER_MASK) begin
        s_axis_up_tuser <= OP1_USER_MASK;
      end 
      if(count_op0 == 30) begin
        s_axis_up_tuser <= OP1_USER_MASK | RSLT_USER_MASK;
      end 
      if(count_op1 == 64) begin
        s_axis_up_tlast <= 0;
        s_axis_up_tuser <= RSLT_USER_MASK;
      end 
      if((count_op0 == 27) && m_axis_right_tvalid) begin
        s_axis_left_tvalid <= 0;
      end 
      if((count_op1 == 27) && m_axis_right_tvalid) begin
        s_axis_up_tvalid <= 0;
      end 
      if((count_op0 > 70) && !timer_op0 && !m_axis_right_tvalid) begin
        $finish;
      end 
      count2_op0 <= count_op0;
      if((count_op0 == count2_op0) || !(s_axis_left_tvalid || m_axis_right_tready)) begin
        if(timer_op0) begin
          timer_op0 <= timer_op0 - 1;
        end else begin
          timer_op0 <= 3;
        end
      end else begin
        timer_op0 <= 3;
      end
      if((count_op1 == count2_op1) || !(s_axis_up_tvalid || m_axis_down_tready)) begin
        if(timer_op1) begin
          timer_op1 <= timer_op1 - 1;
        end else begin
          timer_op1 <= 3;
        end
      end else begin
        timer_op1 <= 3;
      end
    end else begin
      count_op0 <= 0;
      count_op1 <= 0;
    end
  end


endmodule

`resetall
