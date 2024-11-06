
`resetall
`timescale 1ns/1ps
`default_nettype none

module tbv2_LinearProcessingElement
(

);

  localparam PE_NUMBER_I = 1;
  localparam PE_NUMBER_J = 1;
  localparam PE_POSITION_I = 0;
  localparam PE_POSITION_J = 0;
  localparam DATA_WIDTH_OP0 = 16;
  localparam FRACTIONAL_BITS_OP0 = 12;
  localparam IS_UNSIGNED_OP0 = 0;
  localparam DATA_WIDTH_OP1 = DATA_WIDTH_OP0;
  localparam IS_UNSIGNED_OP1 = 0;
  localparam FRACTIONAL_BITS_OP1 = 12;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_OP0;
  localparam FRACTIONAL_BITS_RSLT = 12;
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
    $dumpfile("../vcd/tbv2_LinearProcessingElement.vcd");
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
    #500;
    $finish;
  end

  integer i_op0;
  integer i_op1;

  initial begin
    wait(reset_done);
    wait(clk);
    wait(s_axis_left_tready);
    wait(~clk);
    wait(clk);
    s_axis_left_tvalid = 1;
    m_axis_right_tready = 1;
    for(i_op0=0; i_op0<25; i_op0=i_op0+1) begin
      case(i_op0 % 5)
        0: begin
          s_axis_left_tdata = -16384;
        end
        1: begin
          s_axis_left_tdata = -4096;
        end
        2: begin
          s_axis_left_tdata = 0;
        end
        3: begin
          s_axis_left_tdata = 4096;
        end
        4: begin
          s_axis_left_tdata = 16384;
        end
        default: begin
          s_axis_left_tdata = -16384;
        end
      endcase
      s_axis_left_tlast = i_op0 == 24;
      wait(~clk);
      while(~s_axis_left_tready) begin
        wait(clk);
        wait(~clk);
      end
      wait(clk);
    end
    for(i_op0=0; i_op0<25; i_op0=i_op0+1) begin
      case(i_op0 % 5)
        0: begin
          s_axis_left_tdata = -16384;
        end
        1: begin
          s_axis_left_tdata = -4096;
        end
        2: begin
          s_axis_left_tdata = 0;
        end
        3: begin
          s_axis_left_tdata = 4096;
        end
        4: begin
          s_axis_left_tdata = 16384;
        end
        default: begin
          s_axis_left_tdata = -16384;
        end
      endcase
      s_axis_left_tlast = i_op0 == 24;
      wait(~clk);
      while(~s_axis_left_tready) begin
        wait(clk);
        wait(~clk);
      end
      wait(clk);
    end
    s_axis_left_tvalid = 0;
    s_axis_left_tlast = 0;
  end


  initial begin
    wait(reset_done);
    wait(clk);
    wait(s_axis_up_tready);
    wait(~clk);
    wait(clk);
    s_axis_up_tvalid = 1;
    s_axis_up_tuser = OP1_USER_MASK;
    m_axis_down_tready = 1;
    for(i_op1=0; i_op1<25; i_op1=i_op1+1) begin
      case(i_op1 / 5 % 5)
        0: begin
          s_axis_up_tdata = -16384;
        end
        1: begin
          s_axis_up_tdata = -4096;
        end
        2: begin
          s_axis_up_tdata = 0;
        end
        3: begin
          s_axis_up_tdata = 4096;
        end
        4: begin
          s_axis_up_tdata = 16384;
        end
        default: begin
          s_axis_up_tdata = -16384;
        end
      endcase
      s_axis_up_tlast = i_op1 == 24;
      wait(~clk);
      while(~s_axis_up_tready) begin
        wait(clk);
        wait(~clk);
      end
      wait(clk);
    end
    for(i_op1=0; i_op1<25; i_op1=i_op1+1) begin
      case(i_op1 / 5 % 5)
        0: begin
          s_axis_up_tdata = -16384;
        end
        1: begin
          s_axis_up_tdata = -4096;
        end
        2: begin
          s_axis_up_tdata = 0;
        end
        3: begin
          s_axis_up_tdata = 4096;
        end
        4: begin
          s_axis_up_tdata = 16384;
        end
        default: begin
          s_axis_up_tdata = -16384;
        end
      endcase
      s_axis_up_tlast = i_op1 == 24;
      wait(~clk);
      while(~s_axis_up_tready) begin
        wait(clk);
        wait(~clk);
      end
      wait(clk);
    end
    s_axis_up_tvalid = 0;
    s_axis_up_tlast = 0;
    wait(m_axis_down_tvalid);
    wait(~clk);
    wait(clk);
    #25;
    $finish;
  end


endmodule

`resetall
