
`resetall
`timescale 1ns/1ps
`default_nettype none

module tb_DataProcessor
(

);

  localparam DATA_WIDTH = 16;
  localparam FRACTIONAL_BITS_DATA = 12;
  localparam FRACTIONAL_BITS_SCALE = 15;
  localparam FRACTIONAL_BITS_SCALED_DIFF = 13;
  localparam FRACTIONAL_BITS_ACT = 16;
  localparam FRACTIONAL_BITS_WEIGHT = 16;
  localparam FRACTIONAL_BITS_RSLT = 12;
  localparam IS_UNSIGNED_OP0 = 1;
  localparam INTERNAL_RESET = 0;
  localparam USER_WIDTH = 1;
  localparam DATA_CHANNELS = 1;
  localparam WEIGHT_CHANNELS = 1;
  localparam SHARE_SCALE = 1;
  localparam ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt";
  reg clk;
  reg rst;
  reg [DATA_WIDTH*DATA_CHANNELS-1:0] s_axis_data_tdata;
  reg [DATA_CHANNELS-1:0] s_axis_data_tlast;
  reg [DATA_CHANNELS-1:0] s_axis_data_tvalid;
  wire [DATA_CHANNELS-1:0] s_axis_data_tready;
  reg [USER_WIDTH*DATA_CHANNELS-1:0] s_axis_data_tuser;
  reg [DATA_WIDTH*DATA_CHANNELS-1:0] s_axis_grid_tdata;
  reg [DATA_CHANNELS-1:0] s_axis_grid_tlast;
  reg [DATA_CHANNELS-1:0] s_axis_grid_tvalid;
  wire [DATA_CHANNELS-1:0] s_axis_grid_tready;
  reg [USER_WIDTH*DATA_CHANNELS-1:0] s_axis_grid_tuser;
  reg [DATA_WIDTH-1:0] s_axis_scale_tdata;
  reg s_axis_scale_tlast;
  reg s_axis_scale_tvalid;
  wire s_axis_scale_tready;
  reg [USER_WIDTH-1:0] s_axis_scale_tuser;
  reg [DATA_WIDTH*WEIGHT_CHANNELS-1:0] s_axis_weight_tdata;
  reg [WEIGHT_CHANNELS-1:0] s_axis_weight_tlast;
  reg [WEIGHT_CHANNELS-1:0] s_axis_weight_tvalid;
  wire [WEIGHT_CHANNELS-1:0] s_axis_weight_tready;
  wire [DATA_WIDTH*WEIGHT_CHANNELS-1:0] m_axis_data_tdata;
  wire [WEIGHT_CHANNELS-1:0] m_axis_data_tlast;
  wire [WEIGHT_CHANNELS-1:0] m_axis_data_tvalid;
  reg [WEIGHT_CHANNELS-1:0] m_axis_data_tready;
  wire [USER_WIDTH*WEIGHT_CHANNELS-1:0] m_axis_data_tuser;
  wire err_unalligned_data;
  wire err_user_flag;
  wire core_rst;
  reg reset_done;
  DataProcessor #(
    // Width of AXI stream Input Data & Grid interfaces in bits
    .DATA_WIDTH_DATA(DATA_WIDTH),
    // Fractional bits of input data & grid
    .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
    // Width of AXI stream Scale interface in bits
    .DATA_WIDTH_SCALE(DATA_WIDTH),
    // Fractional bits of input scale
    .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
    // Width of AXI stream Input Weight interface in bits
    .DATA_WIDTH_WEIGHT(DATA_WIDTH),
    // Fractional bits of output data
    .FRACTIONAL_BITS_WEIGHT(FRACTIONAL_BITS_WEIGHT),
    // Width of Scaled Data in bits
    .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH),
    // Fractional bits of Scaled Data
    .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
    // Width of AXI stream Activation Function Data interface in bits
    .DATA_WIDTH_ACT(DATA_WIDTH),
    // Fractional bits of Activation Function Data
    .FRACTIONAL_BITS_ACT(FRACTIONAL_BITS_ACT),
    // Width of AXI stream Output Data interface in bits
    .DATA_WIDTH_RSLT(DATA_WIDTH),
    // Fractional bits of output data
    .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
    // Propagate tkeep signal
    .KEEP_ENABLE(0),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(1),
    // Propagate tid signal
    .ID_ENABLE(0),
    // tid signal width
    .ID_WIDTH(1),
    // Propagate tdest signal
    .DEST_ENABLE(0),
    // tdest signal width
    .DEST_WIDTH(1),
    // Propagate tuser signal
    .USER_ENABLE(0),
    // tuser signal width
    .USER_WIDTH(1),
    // Number of Independent AXI-Stream Data Channels
    .DATA_CHANNELS(DATA_CHANNELS),
    // Number of Independent AXI-Stream Weight Channels
    .WEIGHT_CHANNELS(WEIGHT_CHANNELS),
    // Use Common Share Channel 
    .SHARE_SCALE(SHARE_SCALE),
    // Path to ROM Data
    .ROM_DATA_PATH(ROM_DATA_PATH),
    // Output Destination 
    .OUTPUT_DEST(0),
    // Output Thread ID 
    .OUTPUT_ID(1)
  ) 
  uut
   (
    .clk(clk),
    .rst(rst),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tlast(s_axis_data_tlast),
    // .s_axis_data_tid(s_axis_data_tid),
    // .s_axis_data_tdest(s_axis_data_tdest),
    .s_axis_data_tuser(s_axis_data_tuser),
    .s_axis_grid_tdata(s_axis_grid_tdata),
    .s_axis_grid_tvalid(s_axis_grid_tvalid),
    .s_axis_grid_tready(s_axis_grid_tready),
    .s_axis_grid_tlast(s_axis_grid_tlast),
    // .s_axis_grid_tid(s_axis_grid_tid),
    // .s_axis_grid_tdest(s_axis_grid_tdest),
    .s_axis_grid_tuser(s_axis_grid_tuser),
    .s_axis_scale_tdata(s_axis_scale_tdata),
    .s_axis_scale_tvalid(s_axis_scale_tvalid),
    .s_axis_scale_tready(s_axis_scale_tready),
    .s_axis_scale_tlast(s_axis_scale_tlast),
    // .s_axis_scale_tid(s_axis_scale_tid),
    // .s_axis_scale_tdest(s_axis_scale_tdest),
    .s_axis_scale_tuser(s_axis_scale_tuser),
    .s_axis_weight_tdata(s_axis_weight_tdata),
    .s_axis_weight_tvalid(s_axis_weight_tvalid),
    .s_axis_weight_tready(s_axis_weight_tready),
    .s_axis_weight_tlast(s_axis_weight_tlast),
    // .s_axis_weight_tid(s_axis_weight_tid),
    // .s_axis_weight_tdest(s_axis_weight_tdest),
    // .s_axis_weight_tuser(s_axis_weight_tuser),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tlast(m_axis_data_tlast),
    // .m_axis_data_tid(m_axis_data_tid),
    // .m_axis_data_tdest(m_axis_data_tdest),
    .m_axis_data_tuser(m_axis_data_tuser),
    .err_unalligned_data(err_unalligned_data),
    .err_user_flag(err_user_flag),
    .core_rst(core_rst)
  );

  initial begin
    $dumpfile("../vcd/tb_DataProcessor.vcd");
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
    s_axis_data_tlast = 0;
    s_axis_data_tvalid = 0;
    s_axis_grid_tlast = 0;
    s_axis_grid_tvalid = 0;
    s_axis_scale_tlast = 0;
    s_axis_scale_tvalid = 0;
    s_axis_weight_tvalid = 0;
    s_axis_weight_tlast = 0;
    m_axis_data_tready = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;
    #10;
    reset_done = 1;
    @(posedge clk);
    #1;
  end

  reg [5*DATA_CHANNELS*DATA_WIDTH-1:0] data_array;
  reg [5*DATA_WIDTH-1:0] grid_array;

  initial begin
    data_array = { 16'hf6bf, 16'he7e7, 16'h487, 16'hff5, 16'heea2 };
    grid_array = { 16'h1000, 16'h800, 16'h0, 16'hf800, 16'hf000 };
  end


  initial begin
    $display("Data: %x", data_array);
    $display("%x", data_array[15:0]);
    $display("Grid: %x", grid_array);
    wait(reset_done);
    wait(clk);
    wait(s_axis_scale_tready);
    wait(~clk);
    wait(clk);
    s_axis_scale_tdata = 8192;
    s_axis_scale_tvalid = 1;
    s_axis_scale_tlast = 1;
    wait(~clk);
    while(~s_axis_data_tready) begin
      wait(clk);
      wait(~clk);
    end
    wait(clk);
    wait(~clk);
    s_axis_scale_tvalid = 0;
    s_axis_scale_tlast = 0;
  end

  genvar data_chn;

  generate for(data_chn=0; data_chn<DATA_CHANNELS; data_chn=data_chn+1) begin
    integer i_data;
    integer i_grid;

    initial begin
      wait(reset_done);
      wait(clk);
      wait(s_axis_data_tready[data_chn]);
      wait(~clk);
      s_axis_data_tvalid[data_chn] = 1;
      for(i_data=0; i_data<25; i_data=i_data+1) begin
        case(i_data / 5)
          0: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = data_array[(0*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(0*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          1: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = data_array[(1*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(1*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          2: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = data_array[(2*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(2*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          3: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = data_array[(3*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(3*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          4: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = data_array[(4*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(4*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          default: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = 0;
          end
        endcase
        s_axis_data_tlast[data_chn] = i_data == 24;
        wait(clk);
        while(~s_axis_data_tready[data_chn]) begin
          wait(~clk);
          wait(clk);
        end
        wait(~clk);
      end
      s_axis_data_tvalid[data_chn] = 0;
      s_axis_data_tlast[data_chn] = 0;
    end


    initial begin
      wait(reset_done);
      wait(clk);
      wait(s_axis_grid_tready[data_chn]);
      wait(~clk);
      s_axis_grid_tvalid[data_chn] = 1;
      for(i_grid=0; i_grid<25; i_grid=i_grid+1) begin
        case(i_grid % 5)
          0: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = grid_array[0];
          end
          1: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = grid_array[1];
          end
          2: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = grid_array[2];
          end
          3: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = grid_array[3];
          end
          4: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = grid_array[4];
          end
          default: begin
            s_axis_grid_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = 0;
          end
        endcase
        s_axis_grid_tlast[data_chn] = i_grid == 24;
        wait(clk);
        while(~s_axis_grid_tready[data_chn]) begin
          wait(~clk);
          wait(clk);
        end
        wait(~clk);
      end
      s_axis_grid_tvalid[data_chn] = 0;
      s_axis_grid_tlast[data_chn] = 0;
    end

  end
  endgenerate

  genvar weight_chn;

  generate for(weight_chn=0; weight_chn<DATA_CHANNELS; weight_chn=weight_chn+1) begin
    integer i_weight;

    initial begin
      wait(reset_done);
      wait(clk);
      wait(s_axis_weight_tready[weight_chn]);
      wait(~clk);
      s_axis_weight_tvalid = 1;
      for(i_weight=0; i_weight<25; i_weight=i_weight+1) begin
        case(i_weight)
          0: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h84ed;
          end
          1: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hd0af;
          end
          2: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h4e1;
          end
          3: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h1b9e;
          end
          4: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h2825;
          end
          5: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hc55d;
          end
          6: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hfb9;
          end
          7: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h70b8;
          end
          8: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h1a19;
          end
          9: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hc313;
          end
          10: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h5148;
          end
          11: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h5315;
          end
          12: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hf7ed;
          end
          13: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hf7db;
          end
          14: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hdd98;
          end
          15: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'ha68c;
          end
          16: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hc68b;
          end
          17: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'he394;
          end
          18: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hc70e;
          end
          19: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h2d52;
          end
          20: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h2361;
          end
          21: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h4590;
          end
          22: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h34cf;
          end
          23: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'hde79;
          end
          24: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 16'h686b;
          end
          default: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 0;
          end
        endcase
        s_axis_weight_tlast[weight_chn] = i_weight == 24;
        wait(clk);
        while(~s_axis_weight_tready[weight_chn]) begin
          wait(~clk);
          wait(clk);
        end
        wait(~clk);
      end
      s_axis_weight_tvalid[weight_chn] = 0;
      s_axis_weight_tlast[weight_chn] = 0;
    end


    initial begin
      wait(reset_done);
      wait(m_axis_data_tvalid[weight_chn]);
      wait(clk);
      m_axis_data_tready[weight_chn] = 1;
      wait(~m_axis_data_tvalid[weight_chn]);
      wait(clk);
      m_axis_data_tready[weight_chn] = 0;
      finished[weight_chn] = 1;
      if(weight_chn == 0) begin
        wait(&finished);
        #25;
        $finish;
      end 
    end

  end
  endgenerate

  reg [WEIGHT_CHANNELS-1:0] finished;

endmodule

`resetall
