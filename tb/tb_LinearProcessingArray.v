
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_LinearProcessingArray
(

);

  localparam PE_NUMBER_I = 1;
  localparam PE_NUMBER_J = 1;
  localparam DATA_WIDTH = 16;
  localparam FRACTIONAL_BITS_OP0 = 13;
  localparam FRACTIONAL_BITS_OP1 = 15;
  localparam FRACTIONAL_BITS_RSLT = 13;
  localparam IS_UNSIGNED_OP0 = 1;
  localparam INTERNAL_RESET = 0;
  localparam USER_WIDTH = 1;
  reg clk;
  reg rst;
  reg [DATA_WIDTH*PE_NUMBER_I-1:0] s_axis_up_tdata;
  reg [PE_NUMBER_I-1:0] s_axis_up_tlast;
  reg [PE_NUMBER_I-1:0] s_axis_up_tvalid;
  wire [PE_NUMBER_I-1:0] s_axis_up_tready;
  reg [USER_WIDTH*PE_NUMBER_I-1:0] s_axis_up_tuser;
  reg [DATA_WIDTH*PE_NUMBER_J-1:0] s_axis_left_tdata;
  reg [PE_NUMBER_J-1:0] s_axis_left_tlast;
  reg [PE_NUMBER_J-1:0] s_axis_left_tvalid;
  wire [PE_NUMBER_J-1:0] s_axis_left_tready;
  wire [DATA_WIDTH*PE_NUMBER_I-1:0] m_axis_down_tdata;
  wire [PE_NUMBER_I-1:0] m_axis_down_tlast;
  wire [PE_NUMBER_I-1:0] m_axis_down_tvalid;
  reg [PE_NUMBER_I-1:0] m_axis_down_tready;
  wire [USER_WIDTH*PE_NUMBER_I-1:0] m_axis_down_tuser;
  wire err_unalligned_data;
  wire err_user_flag;
  wire core_rst;
  reg reset_done;
  LinearProcessingArray #(
    .PE_NUMBER_I(PE_NUMBER_I),
    .PE_NUMBER_J(PE_NUMBER_J),
    .INTERNAL_RESET(INTERNAL_RESET),
    .DATA_WIDTH_OP0(DATA_WIDTH),
    .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
    .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
    .DATA_WIDTH_OP1(DATA_WIDTH),
    // .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
    .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
    .DATA_WIDTH_RSLT(DATA_WIDTH),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .ID_ENABLE(0),
    // .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(0),
    // .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_WIDTH>1),
    .USER_WIDTH(USER_WIDTH)
    // .OUTPUT_DEST(OUTPUT_DEST),
    // .OUTPUT_ID(OUTPUT_ID),
    // .DATA_WIDTH_U_D(DATA_WIDTH_U_D),
    // .DATA_WIDTH_L_R(DATA_WIDTH_L_R)  
  ) 
  uut
   (
    .clk(clk),
    .rst(rst),
    .s_axis_up_tdata(s_axis_up_tdata),
    .s_axis_up_tvalid(s_axis_up_tvalid),
    .s_axis_up_tready(s_axis_up_tready),
    .s_axis_up_tlast(s_axis_up_tlast),
    // .s_axis_up_tid(s_axis_up_tid),
    // .s_axis_up_tdest(s_axis_up_tdest),
    .s_axis_up_tuser(s_axis_up_tuser),
    .s_axis_left_tdata(s_axis_left_tdata),
    .s_axis_left_tvalid(s_axis_left_tvalid),
    .s_axis_left_tready(s_axis_left_tready),
    .s_axis_left_tlast(s_axis_left_tlast),
    // .s_axis_left_tid(s_axis_left_tid),
    // .s_axis_left_tdest(s_axis_left_tdest),
    // .s_axis_left_tuser(s_axis_left_tuser),
    .m_axis_down_tdata(m_axis_down_tdata),
    .m_axis_down_tvalid(m_axis_down_tvalid),
    .m_axis_down_tready(m_axis_down_tready),
    .m_axis_down_tlast(m_axis_down_tlast),
    // .m_axis_down_tid(m_axis_down_tid),
    // .m_axis_down_tdest(m_axis_down_tdest),
    .m_axis_down_tuser(m_axis_down_tuser),
    .err_unalligned_data(err_unalligned_data),
    .err_user_flag(err_user_flag),
    .core_rst(core_rst)
  );

  initial begin
    $dumpfile("../vcd/tb_LinearProcessingArray.vcd");
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
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    if(USER_WIDTH > 1) begin
      s_axis_up_tuser = 16045690984503098046;
    end 
    @(posedge clk);
    #1;
    #500;
    $finish;
  end

  genvar CHN;

  generate for(CHN=0; CHN<PE_NUMBER_I+PE_NUMBER_J; CHN=CHN+1) begin
    integer _tmp_0;
    integer _tmp_1;
    integer frame_op0;
    integer frame_op1;

    initial begin
      wait(reset_done);
      if(CHN < PE_NUMBER_J) begin
        wait(s_axis_left_tready == {PE_NUMBER_J{1'b1}});
      end 
      if(CHN < PE_NUMBER_I) begin
        wait(s_axis_up_tready == {PE_NUMBER_I{1'b1}});
      end 
      for(_tmp_0=0; _tmp_0<CHN; _tmp_0=_tmp_0+1) begin
        wait(!clk);
        wait(clk);
      end
      if(CHN < PE_NUMBER_I) begin
        s_axis_up_tvalid[CHN] = 1;
        m_axis_down_tready[CHN] = 0;
      end 
      if(CHN < PE_NUMBER_J) begin
        s_axis_left_tvalid[CHN] = 1;
      end 
      for(_tmp_0=CHN; _tmp_0<CHN+25; _tmp_0=_tmp_0+1) begin
        if(CHN < PE_NUMBER_J) begin
          case(_tmp_0 % 5)
            4: begin
              s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 32768;
            end
            3: begin
              s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 4096;
            end
            2: begin
              s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 1;
            end
            1: begin
              s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -4096;
            end
            default: begin
              s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
            end
          endcase
        end 
        if(CHN < PE_NUMBER_I) begin
          case(_tmp_0 / 5 % 5)
            4: begin
              s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 32768;
            end
            3: begin
              s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 4096;
            end
            2: begin
              s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 1;
            end
            1: begin
              s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -4096;
            end
            default: begin
              s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
            end
          endcase
          m_axis_down_tready[CHN] = !m_axis_down_tready[CHN];
        end 
        wait(!clk);
        wait(clk);
      end
      s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 32768;
      s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 32768;
      s_axis_up_tlast[CHN] = 1;
      wait(!clk);
      wait(clk);
      s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
      s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
      s_axis_up_tlast[CHN] = 0;
      wait(!clk);
      wait(clk);
      s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
      s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -4096;
      s_axis_left_tlast[CHN] = 1;
      wait(!clk);
      wait(clk);
      s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = -32768;
      s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = 1;
      s_axis_left_tlast[CHN] = 0;
      wait(!clk);
      wait(clk);
      s_axis_up_tvalid[CHN] = 0;
      s_axis_left_tvalid[CHN] = 0;
      m_axis_down_tready[CHN] = 0;
      if(~INTERNAL_RESET && ~core_rst) begin
        rst = 1;
        wait(!clk);
        wait(clk);
        wait(!clk);
        wait(clk);
        rst = 0;
      end 
      s_axis_up_tvalid[CHN] = 0;
      s_axis_left_tvalid[CHN] = 0;
      m_axis_down_tready[CHN] = 0;
      wait(~core_rst);
      if(CHN < PE_NUMBER_J) begin
        wait(s_axis_left_tready == {PE_NUMBER_J{1'b1}});
      end 
      if(CHN < PE_NUMBER_I) begin
        wait(s_axis_up_tready == {PE_NUMBER_I{1'b1}});
      end 
      _tmp_0 = CHN;
      _tmp_1 = CHN;
      frame_op0 = 0;
      frame_op1 = 0;
      while(~(frame_op0 && frame_op1)) begin
        if(CHN < PE_NUMBER_J) begin
          if(_tmp_0 > CHN + 10) begin
            s_axis_left_tlast[CHN] = 0;
            s_axis_left_tvalid[CHN] = 0;
          end else if(_tmp_0 == CHN + 10) begin
            s_axis_left_tlast[CHN] = 1;
            s_axis_left_tvalid[CHN] = 1;
            frame_op0 = 1;
          end else begin
            s_axis_left_tlast[CHN] = 0;
            s_axis_left_tvalid[CHN] = 1;
          end
          s_axis_left_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = _tmp_0 ** (CHN + 1) << FRACTIONAL_BITS_OP0 - 3;
        end 
        if(CHN < PE_NUMBER_I) begin
          if(_tmp_1 > CHN + 10) begin
            s_axis_up_tlast[CHN] = 0;
            s_axis_up_tvalid[CHN] = 0;
          end else if(_tmp_1 == CHN + 10) begin
            s_axis_up_tlast[CHN] = 1;
            s_axis_up_tvalid[CHN] = 1;
            frame_op1 = 1;
          end else begin
            s_axis_up_tlast[CHN] = 0;
            s_axis_up_tvalid[CHN] = 1;
          end
          s_axis_up_tdata[(CHN+1)*DATA_WIDTH-1:CHN*DATA_WIDTH] = (_tmp_1 - 5) ** (CHN + 1) << FRACTIONAL_BITS_OP1 - 4;
          m_axis_down_tready[CHN] = !m_axis_down_tready[CHN];
        end 
        wait(!clk);
        wait(clk);
        if(s_axis_left_tready[CHN]) begin
          _tmp_0 = _tmp_0 + 1;
        end 
        if(s_axis_up_tready[CHN]) begin
          _tmp_1 = _tmp_1 + 1;
        end 
      end
      if(CHN < PE_NUMBER_I) begin
        s_axis_up_tvalid[CHN] = 0;
        s_axis_up_tlast[CHN] = 0;
        m_axis_down_tready[CHN] = 0;
      end 
      if(CHN < PE_NUMBER_J) begin
        s_axis_left_tvalid[CHN] = 0;
        s_axis_left_tlast[CHN] = 0;
      end 
      for(_tmp_0=0; _tmp_0<PE_NUMBER_I+2-CHN; _tmp_0=_tmp_0+1) begin
        wait(!clk);
        wait(clk);
      end
      m_axis_down_tready[CHN] = 1;
      for(_tmp_0=0; _tmp_0<PE_NUMBER_I; _tmp_0=_tmp_0+1) begin
        wait(!clk);
        wait(clk);
      end
      #20;
      if(CHN == 0) begin
        $finish;
      end 
    end

  end
  endgenerate


endmodule

`resetall
