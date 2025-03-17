
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_LinearProcessingArray_1_1_1
(

);

  localparam PE_NUMBER_I = 1;
  localparam PE_NUMBER_J = 1;
  localparam BATCH_SIZE = 1;
  localparam INTERNAL_RESET = 1;
  localparam DATA_WIDTH_OP0 = 16;
  localparam FRACTIONAL_BITS_OP0 = 12;
  localparam IS_UNSIGNED_OP0 = 0;
  localparam DATA_WIDTH_OP1 = DATA_WIDTH_OP0;
  localparam FRACTIONAL_BITS_OP1 = 12;
  localparam IS_UNSIGNED_OP1 = 0;
  localparam DATA_WIDTH_RSLT = DATA_WIDTH_OP0;
  localparam FRACTIONAL_BITS_RSLT = 12;
  localparam ID_ENABLE = 0;
  localparam ID_WIDTH = (ID_ENABLE)? 8 : 1;
  localparam DEST_ENABLE = 0;
  localparam DEST_WIDTH = (DEST_ENABLE)? 8 : 1;
  localparam USER_ENABLE = 0;
  localparam USER_WIDTH = (USER_ENABLE)? 8 : 1;
  localparam OUTPUT_DEST = 0;
  localparam OUTPUT_ID = 1;
  reg clk;
  reg rst;
  reg [PE_NUMBER_I*PE_NUMBER_J*DATA_WIDTH_OP1-1+1-1:0] s_axis_t_tdata;
  reg [PE_NUMBER_I*PE_NUMBER_J-1+1-1:0] s_axis_t_tvalid;
  wire [PE_NUMBER_I*PE_NUMBER_J-1+1-1:0] s_axis_t_tready;
  reg [PE_NUMBER_I*PE_NUMBER_J-1+1-1:0] s_axis_t_tlast;
  reg [PE_NUMBER_I*PE_NUMBER_J*ID_WIDTH-1+1-1:0] s_axis_t_tid;
  reg [PE_NUMBER_I*PE_NUMBER_J*DEST_WIDTH-1+1-1:0] s_axis_t_tdest;
  reg [PE_NUMBER_I*PE_NUMBER_J*USER_WIDTH-1+1-1:0] s_axis_t_tuser;
  reg [PE_NUMBER_J*BATCH_SIZE*DATA_WIDTH_OP0-1+1-1:0] s_axis_l_tdata;
  reg [PE_NUMBER_J*BATCH_SIZE-1+1-1:0] s_axis_l_tvalid;
  wire [PE_NUMBER_J*BATCH_SIZE-1+1-1:0] s_axis_l_tready;
  reg [PE_NUMBER_J*BATCH_SIZE-1+1-1:0] s_axis_l_tlast;
  reg [PE_NUMBER_J*BATCH_SIZE*ID_WIDTH-1+1-1:0] s_axis_l_tid;
  reg [PE_NUMBER_J*BATCH_SIZE*DEST_WIDTH-1+1-1:0] s_axis_l_tdest;
  reg [PE_NUMBER_J*BATCH_SIZE*USER_WIDTH-1+1-1:0] s_axis_l_tuser;
  wire [PE_NUMBER_I*BATCH_SIZE*DATA_WIDTH_RSLT-1+1-1:0] m_axis_d_tdata;
  wire [PE_NUMBER_I*BATCH_SIZE-1+1-1:0] m_axis_d_tvalid;
  reg [PE_NUMBER_I*BATCH_SIZE-1+1-1:0] m_axis_d_tready;
  wire [PE_NUMBER_I*BATCH_SIZE-1+1-1:0] m_axis_d_tlast;
  wire [PE_NUMBER_I*BATCH_SIZE*ID_WIDTH-1+1-1:0] m_axis_d_tid;
  wire [PE_NUMBER_I*BATCH_SIZE*DEST_WIDTH-1+1-1:0] m_axis_d_tdest;
  wire [PE_NUMBER_I*BATCH_SIZE*USER_WIDTH-1+1-1:0] m_axis_d_tuser;
  wire err_unalligned_data;
  wire core_rst;
  reg reset_done;

  LPArray_wrapper
  #(
    .PE_NUMBER_I(PE_NUMBER_I),
    .PE_NUMBER_J(PE_NUMBER_J),
    .BATCH_SIZE(BATCH_SIZE),
    .INTERNAL_RESET(INTERNAL_RESET),
    .DATA_WIDTH_OP0(DATA_WIDTH_OP0),
    .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
    .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
    .DATA_WIDTH_OP1(DATA_WIDTH_OP1),
    .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
    .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
    .DATA_WIDTH_RSLT(DATA_WIDTH_RSLT),
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    .ID_ENABLE(ID_ENABLE),
    .ID_WIDTH(ID_WIDTH),
    .DEST_ENABLE(DEST_ENABLE),
    .DEST_WIDTH(DEST_WIDTH),
    .USER_ENABLE(USER_ENABLE),
    .USER_WIDTH(USER_WIDTH),
    .OUTPUT_DEST(OUTPUT_DEST),
    .OUTPUT_ID(OUTPUT_ID)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_t_tdata(s_axis_t_tdata),
    .s_axis_t_tvalid(s_axis_t_tvalid),
    .s_axis_t_tready(s_axis_t_tready),
    .s_axis_t_tlast(s_axis_t_tlast),
    .s_axis_t_tid(s_axis_t_tid),
    .s_axis_t_tdest(s_axis_t_tdest),
    .s_axis_t_tuser(s_axis_t_tuser),
    .s_axis_l_tdata(s_axis_l_tdata),
    .s_axis_l_tvalid(s_axis_l_tvalid),
    .s_axis_l_tready(s_axis_l_tready),
    .s_axis_l_tlast(s_axis_l_tlast),
    .s_axis_l_tid(s_axis_l_tid),
    .s_axis_l_tdest(s_axis_l_tdest),
    .s_axis_l_tuser(s_axis_l_tuser),
    .m_axis_d_tdata(m_axis_d_tdata),
    .m_axis_d_tvalid(m_axis_d_tvalid),
    .m_axis_d_tready(m_axis_d_tready),
    .m_axis_d_tlast(m_axis_d_tlast),
    .m_axis_d_tid(m_axis_d_tid),
    .m_axis_d_tdest(m_axis_d_tdest),
    .m_axis_d_tuser(m_axis_d_tuser),
    .err_unalligned_data(err_unalligned_data),
    .core_rst(core_rst)
  );


  initial begin
    $dumpfile("../vcd/tb_LinearProcessingArray_1_1_1.vcd");
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
    s_axis_l_tdata = 0;
    s_axis_l_tvalid = 0;
    s_axis_l_tlast = 0;
    s_axis_t_tdata = 0;
    s_axis_t_tlast = 0;
    s_axis_t_tvalid = 0;
    m_axis_d_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_d_tready = 1;
    #5000;
    $finish;
  end

  `define assert(signal, value)     if (signal !== value) begin         $display("ASSERTION FAILED in %m: %s != %s",`"signal`", `"value`");         $display("---- Time %0t",$time);         $display("---- %s = 0x%h",`"signal`",signal);         $display("---- %s = 0x%h",`"value`",value);         $finish;     end
      `define assertTrue(signal)     if (~signal) begin         $display("ASSERTION FAILED in %m: %s is not True",`"signal`");         $display("---- Time %0t",$time);         $display("---- %s = 0x%h",`"signal`",signal);         $finish;     end
    
  genvar CHN_I;
  genvar CHN_J;
  genvar CHN_K;

  generate for(CHN_J=0; CHN_J<PE_NUMBER_J; CHN_J=CHN_J+1) begin
    for(CHN_K=0; CHN_K<PE_NUMBER_J; CHN_K=CHN_K+1) begin
      localparam LFT_POS = CHN_K * PE_NUMBER_J + CHN_J;
      integer i_op0;

      initial begin
        wait(reset_done);
        wait(clk);
        wait(s_axis_l_tready[LFT_POS]);
        wait(~clk);
        wait(clk);
        s_axis_l_tvalid[LFT_POS] = 1;
        s_axis_l_tlast[LFT_POS] = 0;
        for(i_op0=0; i_op0<5; i_op0=i_op0+1) begin
          wait(~clk);
          case((i_op0 + LFT_POS) % 5)
            0: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          while(~s_axis_l_tready[LFT_POS]) begin
            wait(clk);
            wait(~clk);
          end
          wait(clk);
        end
        wait(err_unalligned_data);
        wait(core_rst);
        s_axis_l_tvalid[LFT_POS] = 0;
        s_axis_l_tlast[LFT_POS] = 0;
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_l_tvalid[LFT_POS] = 1;
        for(i_op0=0; i_op0<5; i_op0=i_op0+1) begin
          wait(~clk);
          case((i_op0 + LFT_POS) % 5)
            0: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_l_tlast[LFT_POS] = i_op0 == 4;
          while(~s_axis_l_tready[LFT_POS]) begin
            wait(clk);
            wait(~clk);
          end
          wait(clk);
        end
        wait(err_unalligned_data);
        if((LFT_POS == 0) && ~INTERNAL_RESET) begin
          rst = 1;
          s_axis_l_tvalid[LFT_POS] = 0;
          s_axis_l_tlast[LFT_POS] = 0;
          wait(~clk);
          wait(clk);
          rst = 0;
        end 
        wait(core_rst);
        s_axis_l_tvalid[LFT_POS] = 0;
        s_axis_l_tlast[LFT_POS] = 0;
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_l_tvalid[LFT_POS] = 1;
        while(~core_rst) begin
          wait(~clk);
          case(LFT_POS % 5)
            0: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_l_tlast = 1;
          wait(clk);
        end
        s_axis_l_tvalid[LFT_POS] = 0;
        s_axis_l_tlast[LFT_POS] = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_l_tvalid[LFT_POS] = 1;
        while(~core_rst) begin
          wait(~clk);
          case(LFT_POS % 5)
            0: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_l_tlast = 1;
          wait(clk);
        end
        s_axis_l_tvalid[LFT_POS] = 0;
        s_axis_l_tlast[LFT_POS] = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_l_tvalid[LFT_POS] = 1;
        while(~core_rst) begin
          for(i_op0=0; (i_op0<25)&&~core_rst; i_op0=i_op0+1) begin
            wait(~clk);
            case((i_op0 + LFT_POS) % 5)
              0: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
              end
              1: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -2048;
              end
              2: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 0;
              end
              3: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 2048;
              end
              4: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = 8192;
              end
              default: begin
                s_axis_l_tdata[(LFT_POS+1)*DATA_WIDTH_OP0-1:LFT_POS*DATA_WIDTH_OP0] = -8192;
              end
            endcase
            s_axis_l_tlast[LFT_POS] = i_op0 == 24;
            if((i_op0 + LFT_POS) % 5 == 0) begin
              s_axis_l_tvalid[LFT_POS] = 0;
              wait(clk);
              wait(~clk);
              wait(clk);
              wait(~clk);
              s_axis_l_tvalid[LFT_POS] = 1;
            end 
            while(~s_axis_l_tready[LFT_POS] && ~core_rst) begin
              wait(clk);
              wait(~clk);
            end
            wait(clk);
          end
        end
        s_axis_l_tvalid[LFT_POS] = 0;
        s_axis_l_tlast[LFT_POS] = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
      end

    end
  end
  endgenerate


  generate for(CHN_I=0; CHN_I<PE_NUMBER_I; CHN_I=CHN_I+1) begin
    for(CHN_J=0; CHN_J<PE_NUMBER_J; CHN_J=CHN_J+1) begin
      localparam TOP_POS = CHN_J * PE_NUMBER_I + CHN_I;
      integer i_op1;

      initial begin
        wait(reset_done);
        wait(clk);
        wait(s_axis_t_tready[TOP_POS]);
        wait(~clk);
        wait(clk);
        s_axis_t_tvalid[TOP_POS] = 1;
        for(i_op1=0; i_op1<5; i_op1=i_op1+1) begin
          wait(~clk);
          case((i_op1 + TOP_POS) % 5)
            0: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_t_tlast[TOP_POS] = i_op1 == 4;
          while(~s_axis_t_tready[TOP_POS]) begin
            wait(clk);
            wait(~clk);
          end
          wait(clk);
        end
        wait(err_unalligned_data);
        if((TOP_POS == 0) && ~INTERNAL_RESET) begin
          rst = 1;
          s_axis_t_tvalid[TOP_POS] = 0;
          s_axis_t_tlast[TOP_POS] = 0;
          wait(~clk);
          wait(clk);
          rst = 0;
        end 
        wait(core_rst);
        s_axis_t_tvalid[TOP_POS] = 0;
        s_axis_t_tlast[TOP_POS] = 0;
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_t_tvalid[TOP_POS] = 1;
        s_axis_t_tlast[TOP_POS] = 0;
        for(i_op1=0; i_op1<5; i_op1=i_op1+1) begin
          wait(~clk);
          case((i_op1 + TOP_POS) % 5)
            0: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          while(~s_axis_t_tready[TOP_POS]) begin
            wait(~clk);
            wait(clk);
          end
          wait(clk);
        end
        wait(err_unalligned_data);
        wait(core_rst);
        s_axis_t_tvalid[TOP_POS] = 0;
        s_axis_t_tlast[TOP_POS] = 0;
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_t_tvalid[TOP_POS] = 1;
        while(~core_rst) begin
          wait(~clk);
          case(TOP_POS % 5)
            0: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_t_tlast = 1;
          wait(clk);
        end
        s_axis_t_tvalid[TOP_POS] = 0;
        s_axis_t_tlast[TOP_POS] = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_t_tvalid[TOP_POS] = 1;
        while(~core_rst) begin
          wait(~clk);
          case(TOP_POS % 5)
            0: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
            1: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -2048;
            end
            2: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 0;
            end
            3: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 2048;
            end
            4: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 8192;
            end
            default: begin
              s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
            end
          endcase
          s_axis_t_tlast = 1;
          wait(clk);
        end
        s_axis_t_tvalid[TOP_POS] = 0;
        s_axis_t_tlast[TOP_POS] = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        s_axis_t_tvalid[TOP_POS] = 1;
        while(~core_rst) begin
          for(i_op1=0; (i_op1<25)&&~core_rst; i_op1=i_op1+1) begin
            wait(~clk);
            case((i_op1 + TOP_POS) % 5)
              0: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
              end
              1: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -2048;
              end
              2: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 0;
              end
              3: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 2048;
              end
              4: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = 8192;
              end
              default: begin
                s_axis_t_tdata[(TOP_POS+1)*DATA_WIDTH_OP0-1:TOP_POS*DATA_WIDTH_OP0] = -8192;
              end
            endcase
            s_axis_t_tlast[TOP_POS] = i_op1 == 24;
            if((i_op1 + TOP_POS) % 3 == 0) begin
              s_axis_t_tvalid[TOP_POS] = 0;
              wait(clk);
              wait(~clk);
              s_axis_t_tvalid[TOP_POS] = 1;
            end 
            while(~s_axis_t_tready[TOP_POS] && ~core_rst) begin
              wait(clk);
              wait(~clk);
            end
            wait(clk);
          end
        end
        s_axis_t_tvalid = 0;
        s_axis_t_tlast = 0;
        wait(~core_rst);
        wait(~clk);
        wait(clk);
      end

    end
    for(CHN_K=0; CHN_K<BATCH_SIZE; CHN_K=CHN_K+1) begin
      localparam DWN_POS = CHN_K * PE_NUMBER_I + CHN_I;
      integer i_res;

      initial begin
        wait(reset_done);
        wait(clk);
        wait(err_unalligned_data);
        wait(core_rst);
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        wait(err_unalligned_data);
        wait(core_rst);
        wait(~err_unalligned_data);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        m_axis_d_tready[DWN_POS] = 0;
        wait(m_axis_d_tvalid[DWN_POS]);
        wait(~clk);
        for(i_res=0; i_res<10; i_res=i_res+1) begin
          wait(clk);
          wait(~clk);
        end
        for(i_res=0; i_res<10; i_res=i_res+1) begin
          m_axis_d_tready[DWN_POS] = ~m_axis_d_tready[DWN_POS];
          wait(clk);
          if(m_axis_d_tready[DWN_POS]) begin
            wait(m_axis_d_tvalid);
          end 
          wait(~clk);
        end
        m_axis_d_tready[DWN_POS] = 0;
        for(i_res=0; i_res<10; i_res=i_res+1) begin
          wait(clk);
          wait(~clk);
        end
        wait(clk);
        if(DWN_POS == 0) begin
          rst = 1;
          wait(~clk);
          wait(clk);
          rst = 0;
        end 
        wait(core_rst);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        for(i_res=0; i_res<PE_NUMBER_I+PE_NUMBER_J+BATCH_SIZE+10; i_res=i_res+1) begin
          wait(~clk);
          m_axis_d_tready[DWN_POS] = 1;
          while(~m_axis_d_tvalid[DWN_POS]) begin
            wait(clk);
            wait(~clk);
          end
          `assertTrue(m_axis_d_tlast[DWN_POS])
          case(DWN_POS)
            0: begin
              `assert(m_axis_d_tdata[(((DWN_POS + 1) * DATA_WIDTH_OP0) - 1):(DWN_POS * DATA_WIDTH_OP0)],16'h4000)
            end
            default: begin
              `assertTrue(0)
            end
          endcase
          wait(clk);
        end
        wait(~clk);
        m_axis_d_tready[DWN_POS] = 0;
        if(DWN_POS == 0) begin
          wait(m_axis_d_tready == 0);
          rst = 1;
          wait(clk);
          wait(~clk);
          rst = 0;
        end 
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        wait(~clk);
        m_axis_d_tready[DWN_POS] = 1;
        for(i_res=0; i_res<2; i_res=i_res+1) begin
          while(~m_axis_d_tvalid[DWN_POS]) begin
            wait(clk);
            wait(~clk);
          end
          if(~m_axis_d_tready[DWN_POS]) begin
            wait(clk);
            m_axis_d_tready[DWN_POS] = 1;
            wait(~clk);
          end 
          if(m_axis_d_tvalid[DWN_POS]) begin
            `assertTrue(m_axis_d_tlast[DWN_POS])
            case(DWN_POS)
              0: begin
                $display("Time -- %0t", $time);
                $display("%d -- %h", m_axis_d_tdata[(DWN_POS+1)*DATA_WIDTH_OP0-1:DWN_POS*DATA_WIDTH_OP0], m_axis_d_tdata[(DWN_POS+1)*DATA_WIDTH_OP0-1:DWN_POS*DATA_WIDTH_OP0]);
                `assert(m_axis_d_tdata[(((DWN_POS + 1) * DATA_WIDTH_OP0) - 1):(DWN_POS * DATA_WIDTH_OP0)],16'ha800)
              end
              default: begin
              end
            endcase
          end 
          wait(clk);
          wait(~clk);
          m_axis_d_tready[DWN_POS] = 0;
        end
        wait(clk);
        if(DWN_POS == 0) begin
          wait(m_axis_d_tready == 0);
          rst = 1;
          wait(~clk);
          wait(clk);
          rst = 0;
        end 
        wait(core_rst);
        wait(~core_rst);
        wait(~clk);
        wait(clk);
        #5;
        $finish;
      end

    end
  end
  endgenerate


endmodule

`resetall
