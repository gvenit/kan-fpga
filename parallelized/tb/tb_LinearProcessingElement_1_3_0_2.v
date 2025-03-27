
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_LinearProcessingElement_1_3_0_2
(

);

  localparam PE_NUMBER_I = 1;
  localparam PE_NUMBER_J = 3;
  localparam PE_POSITION_I = 0;
  localparam PE_POSITION_J = 2;
  localparam DATA_WIDTH_OP0 = 16;
  localparam FRACTIONAL_BITS_OP0 = 13;
  localparam IS_UNSIGNED_OP0 = 0;
  localparam DATA_WIDTH_OP1 = DATA_WIDTH_OP0;
  localparam FRACTIONAL_BITS_OP1 = 15;
  localparam IS_UNSIGNED_OP1 = 0;
  localparam DATA_WIDTH_PSUM = DATA_WIDTH_OP0 + DATA_WIDTH_OP1;
  reg clk;
  reg rst;
  reg [DATA_WIDTH_OP0-1+1-1:0] s_axis_l_tdata;
  reg s_axis_l_tvalid;
  wire s_axis_l_tready;
  reg s_axis_l_tlast;
  wire [DATA_WIDTH_OP0-1+1-1:0] m_axis_r_tdata;
  wire m_axis_r_tvalid;
  reg m_axis_r_tready;
  wire m_axis_r_tlast;
  reg [DATA_WIDTH_OP1-1+1-1:0] s_axis_t_tdata;
  reg s_axis_t_tvalid;
  wire s_axis_t_tready;
  reg s_axis_t_tlast;
  wire [DATA_WIDTH_OP1-1+1-1:0] m_axis_b_tdata;
  wire m_axis_b_tvalid;
  reg m_axis_b_tready;
  wire m_axis_b_tlast;
  reg [DATA_WIDTH_PSUM-1+1-1:0] s_axis_u_tdata;
  reg s_axis_u_tvalid;
  wire s_axis_u_tready;
  reg s_axis_u_tlast;
  wire [DATA_WIDTH_PSUM-1+1-1:0] m_axis_d_tdata;
  wire m_axis_d_tvalid;
  reg m_axis_d_tready;
  wire m_axis_d_tlast;
  wire err_unalligned_data;
  reg reset_done;

  LinearProcessingElementWrapper
  #(
    .PE_NUMBER_I(PE_NUMBER_I),
    .PE_NUMBER_J(PE_NUMBER_J),
    .PE_POSITION_I(PE_POSITION_I),
    .PE_POSITION_J(PE_POSITION_J),
    .DATA_WIDTH_OP0(DATA_WIDTH_OP0),
    .FRACTIONAL_BITS_OP0(FRACTIONAL_BITS_OP0),
    .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
    .DATA_WIDTH_OP1(DATA_WIDTH_OP1),
    .FRACTIONAL_BITS_OP1(FRACTIONAL_BITS_OP1),
    .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
    .DATA_WIDTH_PSUM(DATA_WIDTH_PSUM)
  )
  uut
  (
    .clk(clk),
    .rst(rst),
    .s_axis_l_tdata(s_axis_l_tdata),
    .s_axis_l_tvalid(s_axis_l_tvalid),
    .s_axis_l_tready(s_axis_l_tready),
    .s_axis_l_tlast(s_axis_l_tlast),
    .m_axis_r_tdata(m_axis_r_tdata),
    .m_axis_r_tvalid(m_axis_r_tvalid),
    .m_axis_r_tready(m_axis_r_tready),
    .m_axis_r_tlast(m_axis_r_tlast),
    .s_axis_t_tdata(s_axis_t_tdata),
    .s_axis_t_tvalid(s_axis_t_tvalid),
    .s_axis_t_tready(s_axis_t_tready),
    .s_axis_t_tlast(s_axis_t_tlast),
    .m_axis_b_tdata(m_axis_b_tdata),
    .m_axis_b_tvalid(m_axis_b_tvalid),
    .m_axis_b_tready(m_axis_b_tready),
    .m_axis_b_tlast(m_axis_b_tlast),
    .s_axis_u_tdata(s_axis_u_tdata),
    .s_axis_u_tvalid(s_axis_u_tvalid),
    .s_axis_u_tready(s_axis_u_tready),
    .s_axis_u_tlast(s_axis_u_tlast),
    .m_axis_d_tdata(m_axis_d_tdata),
    .m_axis_d_tvalid(m_axis_d_tvalid),
    .m_axis_d_tready(m_axis_d_tready),
    .m_axis_d_tlast(m_axis_d_tlast),
    .err_unalligned_data(err_unalligned_data)
  );


  initial begin
    $dumpfile("../vcd/tb_LinearProcessingElement_1_3_0_2.vcd");
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
    s_axis_u_tdata = 0;
    s_axis_u_tlast = 0;
    s_axis_u_tvalid = 0;
    m_axis_r_tready = 0;
    m_axis_b_tready = 0;
    m_axis_d_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
    m_axis_b_tready = 1;
    m_axis_d_tready = 1;
    m_axis_r_tready = 1;
    #500;
    $finish;
  end

  integer count_op0;
  integer count_op1;
  integer count_res;
  integer count2_op0;
  integer count2_op1;
  integer timer_op0;
  integer timer_op1;
  integer _tmp_0;
  integer _tmp_1;
  reg [1-1:0] _tmp_2;

  always @(posedge clk) begin
    if(reset_done) begin
      rst <= _tmp_2 != 0;
      _tmp_2 <= _tmp_2 << 1;
      if(err_unalligned_data) begin
        _tmp_2 <= _tmp_2 | 1;
      end 
      if(_tmp_2 != 0) begin
        s_axis_l_tvalid <= 0;
        s_axis_t_tvalid <= 0;
        s_axis_u_tvalid <= 0;
      end else begin
        _tmp_1 <= count_op1 % 5;
        _tmp_0 <= count_op0 / 5 % 5;
        $display("Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X", count_op0, count_op1, s_axis_l_tready, s_axis_l_tvalid, s_axis_l_tlast, s_axis_t_tready, s_axis_t_tvalid, s_axis_t_tlast, s_axis_u_tready, s_axis_u_tvalid, s_axis_u_tlast, m_axis_r_tready, m_axis_r_tvalid, m_axis_r_tlast, m_axis_b_tready, m_axis_b_tvalid, m_axis_b_tlast, m_axis_d_tready, m_axis_d_tvalid, m_axis_d_tlast);
        if(count_res) begin
          $display("Res: %d", count_res);
        end 
        if(s_axis_l_tready && s_axis_l_tvalid) begin
          count_op0 <= count_op0 + 1;
        end 
        if(s_axis_t_tready && s_axis_t_tvalid) begin
          count_op1 <= count_op1 + 1;
        end 
        case(_tmp_0)
          4: begin
            s_axis_l_tdata <= 32768;
          end
          3: begin
            s_axis_l_tdata <= 4096;
          end
          2: begin
            s_axis_l_tdata <= 0;
          end
          1: begin
            s_axis_l_tdata <= -4096;
          end
          default: begin
            s_axis_l_tdata <= -32768;
          end
        endcase
        case(_tmp_1)
          4: begin
            s_axis_t_tdata <= 32768;
          end
          3: begin
            s_axis_t_tdata <= 4096;
          end
          2: begin
            s_axis_t_tdata <= 0;
          end
          1: begin
            s_axis_t_tdata <= -4096;
          end
          default: begin
            s_axis_t_tdata <= -32768;
          end
        endcase
        if(!s_axis_l_tvalid && (count_op0 < 70)) begin
          s_axis_l_tvalid <= 1;
        end 
        if(!s_axis_t_tvalid && (count_op1 < 70)) begin
          s_axis_t_tvalid <= 1;
        end 
        if((count_op0 == 22) || (count_op0 == 60) || (count_op0 == 80) || (count_op0 == 85)) begin
          s_axis_l_tlast <= 1;
        end 
        if((count_op1 == 24) || (count_op1 == 60) || (count_op1 == 80) || (count_op1 == 85)) begin
          s_axis_t_tlast <= 1;
        end 
        if(~m_axis_d_tready && m_axis_d_tvalid) begin
          m_axis_d_tready <= 1;
        end 
        if((count_op0 == 81) && (count_op1 == 81)) begin
          m_axis_d_tready <= 0;
        end 
        if(s_axis_l_tready && s_axis_l_tvalid && s_axis_l_tlast || (count_op0 > 86)) begin
          s_axis_l_tlast <= 0;
        end 
        if(s_axis_t_tready && s_axis_t_tvalid && s_axis_t_tlast || (count_op1 > 86)) begin
          s_axis_t_tlast <= 0;
        end 
        if(count_op1 == 64) begin
          s_axis_t_tlast <= 0;
        end 
        if((count_op0 == 27) && m_axis_r_tvalid) begin
          s_axis_l_tvalid <= 0;
        end 
        if((count_op1 == 27) && m_axis_r_tvalid) begin
          s_axis_t_tvalid <= 0;
        end 
        if((count_op0 > 70) && !timer_op0 && !m_axis_r_tvalid) begin
          $finish;
        end 
        count2_op0 <= count_op0;
        if((count_op0 == count2_op0) || !(s_axis_l_tvalid || m_axis_r_tready)) begin
          if(timer_op0) begin
            timer_op0 <= timer_op0 - 1;
          end else begin
            timer_op0 <= 4;
          end
        end else begin
          timer_op0 <= 4;
        end
        if((count_op1 == count2_op1) || !(s_axis_t_tvalid || m_axis_b_tready)) begin
          if(timer_op1) begin
            timer_op1 <= timer_op1 - 1;
          end else begin
            timer_op1 <= 4;
          end
        end else begin
          timer_op1 <= 4;
        end
        if(count_op0 > 85) begin
          s_axis_l_tvalid <= 0;
          s_axis_l_tlast <= 0;
        end 
        if(count_op1 > 85) begin
          s_axis_t_tvalid <= 0;
          s_axis_t_tlast <= 0;
        end 
      end
    end else begin
      count_op0 <= 0;
      count_op1 <= 0;
      _tmp_2 <= 0;
    end
  end


  always @(posedge clk) begin
    if(reset_done) begin
      if((count_op0 > 60) && (count_op0 < 65) && s_axis_u_tready) begin
        count_res <= 1;
        if(count_res) begin
          count_res <= count_res + 1;
          s_axis_u_tdata <= 2 ** DATA_WIDTH_OP0 - s_axis_u_tdata;
          s_axis_u_tvalid <= 1;
        end 
        if(count_res == 6) begin
          s_axis_u_tlast <= 1;
          count_res <= 0;
        end 
      end 
      if((count_op0 > 63) && (count_op0 < 65) && (count_res == 0)) begin
        count_res <= 0;
        s_axis_u_tvalid <= 0;
      end 
      if((count_op0 > 76) && (count_op0 < 85) && s_axis_u_tready) begin
        count_res <= 1;
        if(count_res) begin
          $display("Res: %d", count_res);
          count_res <= count_res + 1;
          s_axis_u_tdata <= $signed((-s_axis_u_tdata));
          s_axis_u_tvalid <= 1;
        end 
        if(count_res == 6) begin
          s_axis_u_tlast <= 1;
        end 
      end 
      if((count_op0 > 83) && (count_op0 < 85) && (count_res == 0)) begin
        count_res <= 0;
        s_axis_u_tvalid <= 0;
      end 
      if((count_op0 > 84) && (count_op0 < 90)) begin
        m_axis_d_tready <= 0;
        if(s_axis_u_tready) begin
          count_res <= 1;
          if(count_res) begin
            $display("Res: %d", count_res);
            count_res <= count_res + 1;
            s_axis_u_tdata <= $signed((-s_axis_u_tdata));
            s_axis_u_tvalid <= 1;
          end 
          if(count_res == 3) begin
            s_axis_u_tlast <= 1;
          end 
        end 
      end 
      if((count_op0 > 86) && (count_op0 < 90) && (count_res == 0)) begin
        count_res <= 0;
        s_axis_u_tvalid <= 0;
        m_axis_d_tready <= 1;
      end 
      if(s_axis_u_tlast) begin
        s_axis_u_tlast <= 0;
        s_axis_u_tvalid <= 0;
        count_res <= 0;
      end 
    end else begin
      count_res <= 0;
      s_axis_u_tdata <= 1;
    end
  end


endmodule

`resetall
