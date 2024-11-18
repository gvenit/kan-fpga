
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
    #500;
    $finish;
  end

  reg [100*DATA_CHANNELS*DATA_WIDTH-1:0] data_array;
  reg [5*DATA_WIDTH-1:0] grid_array;
  reg [100*WEIGHT_CHANNELS*DATA_WIDTH-1:0] weight_array;

  initial begin
    data_array = { 16'hf9ef, 16'h612, 16'hea30, 16'heea6, 16'h107f, 16'hfaa4, 16'h12d8, 16'h2e5, 16'hebb9, 16'h1267, 16'h2a1, 16'h2164, 16'hec9a, 16'hf448, 16'heea1, 16'hfaf7, 16'hcea, 16'h1a93, 16'hf4fb, 16'h1415, 16'he64e, 16'hf29a, 16'hfdfc, 16'hf98c, 16'h10a2, 16'hde08, 16'hee72, 16'h1298, 16'hf2b4, 16'h77e, 16'h331, 16'hecd4, 16'hfc46, 16'hba, 16'hcea, 16'h16ad, 16'heac8, 16'h507, 16'hcb7, 16'hf3a3, 16'h111c, 16'h17ee, 16'h1c14, 16'he40, 16'h111b, 16'h79, 16'hf33c, 16'h1be6, 16'hef62, 16'heb4c, 16'h23cf, 16'hfa8, 16'h69b, 16'h2647, 16'hffd0, 16'h56a, 16'h92e, 16'hf9bf, 16'he45c, 16'hf31e, 16'h489, 16'hf1ee, 16'hb02, 16'hb, 16'hfd39, 16'hed6, 16'hf4ce, 16'he3a8, 16'hd339, 16'hfbe9, 16'hf237, 16'hfdc3, 16'he925, 16'he83, 16'hf5cc, 16'hebf1, 16'h12d0, 16'hf107, 16'h17da, 16'hbcc, 16'h62d, 16'h1010, 16'h22fd, 16'h234b, 16'hf90d, 16'hf8e6, 16'hf5c8, 16'h17dc, 16'hfe7d, 16'hf524, 16'hf222, 16'h1441, 16'hf924, 16'hd92d, 16'h1a6c, 16'hf6bf, 16'he7e7, 16'h487, 16'hff5, 16'heea2 };
    grid_array = { 16'h1000, 16'h800, 16'h0, 16'hf800, 16'hf000 };
    weight_array = { 16'h8857, 16'h647, 16'h4ed7, 16'hd55f, 16'h6567, 16'h1f92, 16'h46ec, 16'haf6, 16'hdfc5, 16'h82d, 16'h9f91, 16'h8a42, 16'hcadc, 16'hcc74, 16'h77d4, 16'h78f2, 16'hf35a, 16'hd62c, 16'hdc2, 16'hf96b, 16'h60cf, 16'h18e2, 16'h10a4, 16'h8ec, 16'h41cd, 16'hb515, 16'hfbe1, 16'h7587, 16'hc8c5, 16'hc85c, 16'he510, 16'hc452, 16'hb1d2, 16'hcd54, 16'h8b30, 16'ha5c6, 16'ha43f, 16'hda12, 16'h9db2, 16'h1128, 16'h88bc, 16'h3727, 16'h2e7b, 16'hee1, 16'h20d, 16'hb454, 16'h5b3c, 16'h7708, 16'hfab3, 16'h9fce, 16'hf91b, 16'hbd6e, 16'h766d, 16'hda42, 16'h405a, 16'h1d3f, 16'hf747, 16'h551f, 16'haed3, 16'h63d0, 16'hbe39, 16'hfd58, 16'h52fc, 16'heeb4, 16'ha35a, 16'hf41a, 16'h762f, 16'hdf41, 16'hb3c8, 16'h23df, 16'hc880, 16'hf65c, 16'hf9a3, 16'h40a2, 16'hd432, 16'hc5df, 16'hefb4, 16'h5d44, 16'h1f23, 16'hd6be, 16'h70e9, 16'he24e, 16'h8473, 16'h774e, 16'hfa24, 16'hb884, 16'h373d, 16'h5a2e, 16'h2d66, 16'h4786, 16'h66b1, 16'h81ed, 16'h1862, 16'he201, 16'h5b0, 16'h1a39, 16'h9132, 16'hf05, 16'he7aa, 16'h2902, 16'h3255, 16'h93df, 16'ha471, 16'hb22c, 16'hfb7e, 16'h954a, 16'h31c1, 16'h12eb, 16'he4, 16'h9b2c, 16'h5f54, 16'ha601, 16'h1b91, 16'h4983, 16'hc161, 16'h15a1, 16'h949e, 16'h9e07, 16'h84f8, 16'h7ffa, 16'h4720, 16'h98f3, 16'h8305, 16'he349, 16'h5e6f, 16'hb083, 16'h3680, 16'hc85, 16'h34a8, 16'h72b6, 16'hd269, 16'hc475, 16'hda00, 16'h6900, 16'h4518, 16'hbd63, 16'h7617, 16'hdaac, 16'h759a, 16'h8047, 16'h38fa, 16'h2685, 16'hcb94, 16'h42df, 16'he328, 16'h559d, 16'h5d89, 16'hb9b6, 16'h445b, 16'hd90d, 16'ha41f, 16'hf508, 16'h1ff8, 16'h85d, 16'h9351, 16'hca66, 16'h79d1, 16'h7ca1, 16'h413f, 16'h8e8b, 16'hd69a, 16'h16f8, 16'ha99c, 16'h6815, 16'h6412, 16'hf9fd, 16'h391c, 16'ha2b2, 16'h94f8, 16'h7abb, 16'h3832, 16'ha1b7, 16'h20c5, 16'h1394, 16'heec, 16'hdff3, 16'h65a9, 16'h8bd3, 16'h50ab, 16'h19f2, 16'h3a80, 16'h3c84, 16'h6ad7, 16'h3e1e, 16'h1827, 16'hd816, 16'h1762, 16'h833d, 16'h8725, 16'h2d51, 16'haf1d, 16'h8cbd, 16'h33fe, 16'hfd98, 16'ha2fc, 16'h235f, 16'h55be, 16'h4b3a, 16'he356, 16'h2191, 16'he1e2, 16'h8d8a, 16'h2ad0, 16'h7595, 16'h76b3, 16'he47, 16'h41f, 16'hcafb, 16'h74e2, 16'h971d, 16'h2f86, 16'h912f, 16'h385e, 16'hb31, 16'ha77d, 16'h482e, 16'h142c, 16'h4a12, 16'h23bb, 16'h3ad5, 16'h241, 16'h8e3f, 16'h2738, 16'h699f, 16'h7e74, 16'hd331, 16'hb0e8, 16'h780, 16'h4bb2, 16'hcfc7, 16'hba25, 16'hd79a, 16'h8bdb, 16'h2adc, 16'h4334, 16'hb862, 16'h8fa, 16'hadef, 16'h4cb2, 16'hb8e5, 16'hc0d9, 16'h446e, 16'heb57, 16'h967f, 16'hce58, 16'hf4ff, 16'h2a48, 16'hf0b6, 16'hc21c, 16'h38d3, 16'h48d4, 16'hd2b7, 16'h4f04, 16'hef79, 16'h22c4, 16'he5a7, 16'h6866, 16'h5acf, 16'h32ee, 16'h61f2, 16'h4145, 16'h13d4, 16'h8a69, 16'hca57, 16'had7e, 16'h9e24, 16'h2c43, 16'h29e5, 16'h4b3c, 16'h39e5, 16'hdd89, 16'h26b5, 16'h978d, 16'h8ff5, 16'h41fd, 16'h2176, 16'hbec6, 16'h1c31, 16'h2682, 16'h2a19, 16'hb024, 16'he479, 16'h9885, 16'hd1b1, 16'h9472, 16'h7930, 16'ha492, 16'h20aa, 16'h17dd, 16'h72aa, 16'h4d37, 16'h9293, 16'h4e4, 16'h7f18, 16'hffdc, 16'hf1a8, 16'h8d40, 16'he99b, 16'h9152, 16'hc02, 16'h14d4, 16'h33a6, 16'hd6cc, 16'hed88, 16'h4648, 16'hee91, 16'hf5c6, 16'h22ec, 16'h9ff8, 16'h4645, 16'h6a49, 16'h7e04, 16'hc761, 16'h7bcd, 16'he74d, 16'h6046, 16'ha769, 16'haad4, 16'h8f5b, 16'h59e9, 16'h91fc, 16'h24df, 16'ha08c, 16'h11f7, 16'h8aa0, 16'hca33, 16'ha0da, 16'h876a, 16'hc9fc, 16'h7440, 16'hb90c, 16'h5f7f, 16'h7bdf, 16'h9cc7, 16'h794b, 16'hde32, 16'h34f3, 16'he70f, 16'h5686, 16'hf754, 16'h2260, 16'h7e7a, 16'h2341, 16'h3800, 16'hdd96, 16'h330b, 16'h447c, 16'h6501, 16'h4936, 16'h202e, 16'h4377, 16'h81c9, 16'h6ebb, 16'hff79, 16'h3bac, 16'h7989, 16'ha272, 16'hd969, 16'h8853, 16'h4f1a, 16'h16e8, 16'hc8cf, 16'he7f, 16'h4ab0, 16'hb37f, 16'hb37a, 16'h287d, 16'h8979, 16'h9c0, 16'h6728, 16'h1ff3, 16'h82fd, 16'h3dc, 16'h7e94, 16'hdfab, 16'hf5e4, 16'h84f9, 16'h32b3, 16'h74ef, 16'h9ae3, 16'hb135, 16'h4302, 16'h678b, 16'h4220, 16'h73e1, 16'h2fb3, 16'hff6f, 16'h94e, 16'h68a0, 16'h94e4, 16'h954b, 16'h436e, 16'h82cf, 16'h152c, 16'h5027, 16'ha78c, 16'h2dbe, 16'h5180, 16'h4db, 16'h16a3, 16'hb63a, 16'h12fa, 16'hfb36, 16'hb52c, 16'h736e, 16'hd6be, 16'hccd8, 16'h65b9, 16'hed1e, 16'hbb09, 16'h8101, 16'hd8be, 16'h6ee7, 16'hf516, 16'h60d4, 16'h6ef, 16'hc157, 16'h77c1, 16'hdd36, 16'h787e, 16'hd4e5, 16'h1efa, 16'hc842, 16'h4b3d, 16'heaf7, 16'h916d, 16'hf2cb, 16'h7e19, 16'hb12b, 16'h831, 16'hb039, 16'h4c71, 16'h60b4, 16'hf013, 16'h1360, 16'h19c2, 16'h5c90, 16'h6b10, 16'h5f12, 16'h9713, 16'hadb2, 16'ha400, 16'h6bbc, 16'hbf95, 16'hed0b, 16'hbfd2, 16'h928b, 16'h29b6, 16'haf67, 16'head7, 16'h6a43, 16'hef33, 16'hbc23, 16'hfd1, 16'hf46, 16'hcdbf, 16'h9cb6, 16'hd5cb, 16'h637b, 16'hd5b2, 16'h318b, 16'h36a5, 16'hb811, 16'h5585, 16'ha928, 16'hca93, 16'h7390, 16'hc216, 16'hbf19, 16'hae7, 16'hee56, 16'h928a, 16'h3400, 16'h681b, 16'hf3c6, 16'hca3, 16'h4ba3, 16'h1257, 16'h6bae, 16'h8438, 16'ha257, 16'he639, 16'h56c4, 16'hc4d9, 16'h1b0a, 16'hb16b, 16'hef87, 16'h3e11, 16'h8431, 16'h991d, 16'hfae1, 16'h351f, 16'h4ad8, 16'h983c, 16'h82fc, 16'h7f4f, 16'hfa7d, 16'hebe5, 16'hf298, 16'h294c };
  end


  initial begin
    $display("Data: %x", data_array);
    $display("%x", data_array[15:0]);
    $display("Grid: %x", grid_array);
    $display("Weight: %x", weight_array);
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
      wait(clk);
      s_axis_data_tvalid[data_chn] = 1;
      for(i_data=0; i_data<500; i_data=i_data+1) begin
        case(i_data / 5)
          0: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(0*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(0*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          1: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(1*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(1*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          2: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(2*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(2*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          3: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(3*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(3*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          4: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(4*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(4*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          5: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(5*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(5*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          6: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(6*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(6*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          7: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(7*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(7*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          8: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(8*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(8*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          9: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(9*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(9*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          10: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(10*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(10*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          11: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(11*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(11*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          12: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(12*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(12*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          13: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(13*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(13*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          14: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(14*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(14*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          15: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(15*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(15*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          16: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(16*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(16*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          17: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(17*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(17*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          18: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(18*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(18*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          19: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(19*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(19*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          20: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(20*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(20*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          21: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(21*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(21*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          22: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(22*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(22*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          23: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(23*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(23*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          24: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(24*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(24*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          25: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(25*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(25*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          26: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(26*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(26*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          27: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(27*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(27*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          28: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(28*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(28*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          29: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(29*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(29*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          30: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(30*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(30*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          31: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(31*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(31*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          32: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(32*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(32*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          33: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(33*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(33*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          34: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(34*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(34*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          35: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(35*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(35*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          36: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(36*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(36*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          37: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(37*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(37*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          38: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(38*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(38*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          39: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(39*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(39*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          40: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(40*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(40*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          41: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(41*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(41*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          42: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(42*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(42*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          43: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(43*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(43*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          44: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(44*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(44*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          45: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(45*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(45*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          46: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(46*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(46*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          47: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(47*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(47*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          48: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(48*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(48*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          49: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(49*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(49*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          50: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(50*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(50*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          51: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(51*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(51*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          52: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(52*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(52*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          53: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(53*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(53*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          54: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(54*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(54*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          55: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(55*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(55*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          56: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(56*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(56*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          57: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(57*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(57*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          58: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(58*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(58*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          59: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(59*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(59*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          60: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(60*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(60*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          61: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(61*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(61*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          62: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(62*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(62*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          63: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(63*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(63*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          64: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(64*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(64*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          65: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(65*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(65*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          66: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(66*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(66*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          67: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(67*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(67*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          68: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(68*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(68*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          69: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(69*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(69*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          70: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(70*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(70*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          71: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(71*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(71*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          72: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(72*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(72*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          73: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(73*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(73*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          74: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(74*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(74*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          75: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(75*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(75*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          76: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(76*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(76*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          77: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(77*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(77*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          78: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(78*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(78*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          79: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(79*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(79*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          80: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(80*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(80*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          81: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(81*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(81*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          82: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(82*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(82*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          83: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(83*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(83*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          84: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(84*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(84*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          85: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(85*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(85*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          86: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(86*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(86*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          87: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(87*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(87*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          88: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(88*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(88*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          89: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(89*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(89*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          90: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(90*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(90*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          91: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(91*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(91*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          92: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(92*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(92*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          93: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(93*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(93*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          94: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(94*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(94*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          95: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(95*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(95*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          96: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(96*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(96*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          97: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(97*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(97*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          98: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(98*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(98*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          99: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = weight_array[(99*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1:(99*DATA_CHANNELS+data_chn)*DATA_WIDTH];
          end
          default: begin
            s_axis_data_tdata[(data_chn+1)*DATA_WIDTH-1:data_chn*DATA_WIDTH] = 0;
          end
        endcase
        s_axis_data_tlast[data_chn] = i_data == 499;
        wait(~clk);
        while(~s_axis_data_tready[data_chn]) begin
          wait(clk);
          wait(~clk);
        end
        wait(clk);
      end
      s_axis_data_tvalid[data_chn] = 0;
      s_axis_data_tlast[data_chn] = 0;
    end


    initial begin
      wait(reset_done);
      wait(clk);
      wait(s_axis_grid_tready[data_chn]);
      wait(~clk);
      wait(clk);
      s_axis_grid_tvalid[data_chn] = 1;
      for(i_grid=0; i_grid<500; i_grid=i_grid+1) begin
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
        s_axis_grid_tlast[data_chn] = i_grid == 499;
        wait(~clk);
        while(~s_axis_grid_tready[data_chn]) begin
          wait(clk);
          wait(~clk);
        end
        wait(clk);
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
      wait(clk);
      s_axis_weight_tvalid = 1;
      for(i_weight=0; i_weight<500; i_weight=i_weight+1) begin
        case(i_weight)
          0: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(0*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(0*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          1: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(1*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(1*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          2: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(2*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(2*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          3: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(3*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(3*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          4: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(4*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(4*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          5: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(5*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(5*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          6: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(6*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(6*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          7: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(7*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(7*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          8: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(8*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(8*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          9: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(9*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(9*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          10: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(10*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(10*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          11: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(11*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(11*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          12: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(12*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(12*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          13: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(13*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(13*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          14: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(14*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(14*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          15: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(15*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(15*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          16: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(16*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(16*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          17: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(17*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(17*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          18: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(18*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(18*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          19: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(19*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(19*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          20: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(20*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(20*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          21: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(21*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(21*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          22: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(22*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(22*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          23: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(23*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(23*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          24: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(24*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(24*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          25: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(25*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(25*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          26: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(26*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(26*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          27: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(27*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(27*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          28: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(28*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(28*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          29: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(29*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(29*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          30: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(30*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(30*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          31: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(31*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(31*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          32: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(32*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(32*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          33: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(33*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(33*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          34: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(34*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(34*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          35: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(35*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(35*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          36: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(36*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(36*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          37: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(37*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(37*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          38: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(38*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(38*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          39: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(39*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(39*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          40: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(40*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(40*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          41: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(41*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(41*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          42: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(42*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(42*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          43: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(43*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(43*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          44: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(44*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(44*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          45: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(45*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(45*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          46: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(46*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(46*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          47: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(47*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(47*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          48: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(48*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(48*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          49: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(49*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(49*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          50: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(50*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(50*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          51: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(51*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(51*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          52: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(52*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(52*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          53: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(53*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(53*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          54: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(54*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(54*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          55: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(55*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(55*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          56: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(56*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(56*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          57: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(57*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(57*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          58: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(58*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(58*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          59: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(59*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(59*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          60: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(60*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(60*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          61: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(61*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(61*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          62: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(62*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(62*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          63: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(63*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(63*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          64: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(64*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(64*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          65: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(65*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(65*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          66: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(66*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(66*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          67: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(67*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(67*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          68: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(68*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(68*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          69: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(69*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(69*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          70: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(70*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(70*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          71: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(71*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(71*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          72: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(72*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(72*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          73: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(73*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(73*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          74: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(74*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(74*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          75: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(75*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(75*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          76: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(76*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(76*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          77: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(77*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(77*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          78: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(78*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(78*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          79: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(79*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(79*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          80: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(80*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(80*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          81: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(81*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(81*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          82: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(82*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(82*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          83: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(83*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(83*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          84: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(84*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(84*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          85: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(85*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(85*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          86: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(86*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(86*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          87: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(87*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(87*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          88: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(88*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(88*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          89: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(89*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(89*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          90: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(90*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(90*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          91: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(91*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(91*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          92: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(92*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(92*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          93: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(93*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(93*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          94: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(94*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(94*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          95: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(95*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(95*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          96: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(96*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(96*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          97: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(97*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(97*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          98: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(98*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(98*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          99: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(99*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(99*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          100: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(100*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(100*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          101: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(101*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(101*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          102: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(102*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(102*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          103: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(103*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(103*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          104: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(104*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(104*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          105: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(105*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(105*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          106: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(106*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(106*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          107: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(107*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(107*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          108: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(108*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(108*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          109: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(109*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(109*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          110: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(110*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(110*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          111: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(111*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(111*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          112: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(112*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(112*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          113: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(113*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(113*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          114: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(114*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(114*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          115: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(115*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(115*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          116: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(116*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(116*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          117: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(117*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(117*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          118: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(118*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(118*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          119: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(119*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(119*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          120: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(120*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(120*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          121: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(121*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(121*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          122: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(122*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(122*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          123: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(123*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(123*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          124: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(124*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(124*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          125: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(125*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(125*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          126: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(126*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(126*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          127: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(127*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(127*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          128: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(128*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(128*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          129: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(129*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(129*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          130: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(130*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(130*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          131: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(131*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(131*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          132: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(132*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(132*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          133: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(133*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(133*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          134: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(134*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(134*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          135: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(135*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(135*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          136: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(136*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(136*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          137: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(137*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(137*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          138: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(138*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(138*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          139: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(139*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(139*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          140: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(140*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(140*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          141: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(141*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(141*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          142: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(142*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(142*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          143: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(143*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(143*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          144: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(144*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(144*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          145: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(145*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(145*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          146: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(146*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(146*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          147: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(147*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(147*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          148: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(148*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(148*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          149: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(149*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(149*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          150: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(150*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(150*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          151: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(151*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(151*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          152: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(152*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(152*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          153: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(153*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(153*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          154: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(154*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(154*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          155: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(155*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(155*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          156: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(156*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(156*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          157: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(157*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(157*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          158: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(158*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(158*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          159: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(159*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(159*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          160: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(160*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(160*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          161: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(161*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(161*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          162: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(162*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(162*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          163: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(163*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(163*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          164: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(164*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(164*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          165: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(165*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(165*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          166: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(166*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(166*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          167: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(167*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(167*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          168: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(168*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(168*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          169: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(169*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(169*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          170: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(170*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(170*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          171: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(171*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(171*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          172: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(172*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(172*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          173: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(173*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(173*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          174: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(174*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(174*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          175: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(175*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(175*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          176: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(176*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(176*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          177: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(177*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(177*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          178: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(178*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(178*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          179: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(179*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(179*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          180: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(180*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(180*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          181: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(181*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(181*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          182: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(182*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(182*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          183: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(183*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(183*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          184: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(184*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(184*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          185: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(185*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(185*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          186: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(186*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(186*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          187: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(187*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(187*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          188: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(188*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(188*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          189: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(189*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(189*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          190: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(190*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(190*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          191: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(191*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(191*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          192: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(192*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(192*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          193: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(193*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(193*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          194: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(194*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(194*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          195: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(195*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(195*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          196: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(196*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(196*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          197: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(197*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(197*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          198: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(198*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(198*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          199: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(199*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(199*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          200: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(200*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(200*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          201: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(201*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(201*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          202: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(202*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(202*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          203: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(203*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(203*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          204: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(204*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(204*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          205: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(205*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(205*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          206: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(206*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(206*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          207: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(207*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(207*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          208: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(208*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(208*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          209: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(209*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(209*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          210: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(210*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(210*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          211: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(211*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(211*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          212: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(212*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(212*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          213: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(213*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(213*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          214: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(214*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(214*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          215: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(215*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(215*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          216: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(216*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(216*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          217: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(217*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(217*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          218: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(218*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(218*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          219: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(219*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(219*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          220: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(220*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(220*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          221: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(221*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(221*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          222: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(222*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(222*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          223: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(223*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(223*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          224: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(224*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(224*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          225: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(225*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(225*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          226: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(226*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(226*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          227: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(227*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(227*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          228: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(228*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(228*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          229: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(229*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(229*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          230: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(230*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(230*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          231: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(231*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(231*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          232: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(232*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(232*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          233: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(233*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(233*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          234: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(234*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(234*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          235: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(235*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(235*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          236: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(236*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(236*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          237: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(237*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(237*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          238: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(238*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(238*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          239: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(239*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(239*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          240: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(240*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(240*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          241: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(241*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(241*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          242: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(242*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(242*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          243: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(243*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(243*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          244: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(244*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(244*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          245: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(245*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(245*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          246: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(246*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(246*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          247: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(247*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(247*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          248: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(248*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(248*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          249: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(249*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(249*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          250: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(250*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(250*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          251: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(251*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(251*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          252: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(252*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(252*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          253: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(253*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(253*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          254: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(254*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(254*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          255: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(255*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(255*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          256: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(256*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(256*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          257: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(257*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(257*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          258: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(258*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(258*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          259: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(259*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(259*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          260: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(260*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(260*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          261: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(261*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(261*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          262: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(262*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(262*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          263: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(263*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(263*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          264: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(264*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(264*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          265: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(265*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(265*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          266: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(266*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(266*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          267: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(267*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(267*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          268: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(268*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(268*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          269: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(269*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(269*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          270: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(270*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(270*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          271: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(271*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(271*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          272: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(272*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(272*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          273: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(273*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(273*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          274: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(274*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(274*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          275: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(275*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(275*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          276: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(276*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(276*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          277: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(277*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(277*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          278: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(278*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(278*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          279: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(279*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(279*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          280: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(280*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(280*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          281: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(281*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(281*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          282: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(282*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(282*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          283: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(283*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(283*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          284: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(284*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(284*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          285: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(285*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(285*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          286: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(286*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(286*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          287: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(287*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(287*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          288: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(288*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(288*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          289: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(289*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(289*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          290: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(290*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(290*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          291: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(291*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(291*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          292: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(292*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(292*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          293: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(293*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(293*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          294: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(294*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(294*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          295: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(295*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(295*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          296: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(296*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(296*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          297: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(297*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(297*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          298: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(298*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(298*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          299: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(299*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(299*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          300: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(300*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(300*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          301: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(301*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(301*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          302: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(302*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(302*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          303: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(303*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(303*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          304: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(304*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(304*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          305: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(305*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(305*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          306: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(306*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(306*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          307: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(307*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(307*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          308: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(308*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(308*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          309: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(309*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(309*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          310: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(310*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(310*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          311: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(311*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(311*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          312: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(312*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(312*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          313: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(313*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(313*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          314: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(314*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(314*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          315: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(315*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(315*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          316: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(316*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(316*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          317: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(317*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(317*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          318: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(318*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(318*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          319: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(319*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(319*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          320: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(320*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(320*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          321: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(321*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(321*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          322: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(322*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(322*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          323: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(323*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(323*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          324: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(324*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(324*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          325: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(325*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(325*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          326: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(326*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(326*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          327: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(327*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(327*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          328: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(328*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(328*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          329: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(329*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(329*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          330: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(330*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(330*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          331: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(331*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(331*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          332: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(332*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(332*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          333: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(333*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(333*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          334: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(334*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(334*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          335: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(335*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(335*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          336: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(336*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(336*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          337: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(337*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(337*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          338: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(338*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(338*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          339: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(339*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(339*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          340: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(340*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(340*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          341: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(341*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(341*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          342: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(342*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(342*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          343: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(343*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(343*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          344: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(344*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(344*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          345: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(345*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(345*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          346: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(346*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(346*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          347: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(347*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(347*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          348: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(348*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(348*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          349: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(349*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(349*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          350: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(350*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(350*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          351: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(351*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(351*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          352: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(352*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(352*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          353: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(353*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(353*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          354: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(354*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(354*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          355: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(355*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(355*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          356: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(356*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(356*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          357: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(357*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(357*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          358: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(358*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(358*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          359: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(359*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(359*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          360: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(360*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(360*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          361: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(361*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(361*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          362: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(362*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(362*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          363: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(363*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(363*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          364: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(364*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(364*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          365: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(365*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(365*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          366: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(366*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(366*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          367: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(367*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(367*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          368: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(368*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(368*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          369: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(369*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(369*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          370: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(370*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(370*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          371: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(371*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(371*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          372: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(372*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(372*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          373: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(373*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(373*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          374: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(374*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(374*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          375: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(375*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(375*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          376: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(376*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(376*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          377: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(377*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(377*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          378: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(378*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(378*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          379: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(379*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(379*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          380: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(380*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(380*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          381: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(381*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(381*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          382: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(382*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(382*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          383: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(383*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(383*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          384: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(384*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(384*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          385: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(385*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(385*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          386: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(386*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(386*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          387: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(387*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(387*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          388: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(388*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(388*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          389: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(389*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(389*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          390: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(390*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(390*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          391: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(391*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(391*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          392: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(392*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(392*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          393: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(393*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(393*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          394: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(394*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(394*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          395: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(395*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(395*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          396: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(396*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(396*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          397: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(397*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(397*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          398: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(398*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(398*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          399: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(399*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(399*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          400: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(400*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(400*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          401: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(401*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(401*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          402: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(402*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(402*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          403: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(403*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(403*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          404: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(404*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(404*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          405: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(405*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(405*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          406: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(406*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(406*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          407: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(407*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(407*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          408: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(408*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(408*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          409: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(409*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(409*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          410: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(410*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(410*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          411: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(411*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(411*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          412: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(412*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(412*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          413: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(413*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(413*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          414: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(414*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(414*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          415: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(415*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(415*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          416: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(416*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(416*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          417: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(417*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(417*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          418: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(418*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(418*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          419: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(419*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(419*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          420: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(420*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(420*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          421: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(421*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(421*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          422: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(422*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(422*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          423: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(423*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(423*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          424: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(424*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(424*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          425: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(425*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(425*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          426: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(426*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(426*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          427: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(427*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(427*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          428: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(428*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(428*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          429: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(429*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(429*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          430: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(430*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(430*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          431: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(431*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(431*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          432: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(432*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(432*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          433: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(433*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(433*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          434: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(434*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(434*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          435: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(435*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(435*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          436: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(436*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(436*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          437: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(437*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(437*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          438: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(438*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(438*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          439: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(439*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(439*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          440: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(440*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(440*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          441: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(441*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(441*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          442: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(442*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(442*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          443: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(443*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(443*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          444: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(444*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(444*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          445: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(445*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(445*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          446: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(446*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(446*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          447: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(447*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(447*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          448: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(448*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(448*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          449: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(449*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(449*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          450: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(450*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(450*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          451: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(451*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(451*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          452: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(452*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(452*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          453: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(453*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(453*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          454: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(454*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(454*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          455: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(455*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(455*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          456: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(456*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(456*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          457: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(457*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(457*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          458: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(458*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(458*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          459: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(459*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(459*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          460: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(460*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(460*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          461: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(461*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(461*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          462: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(462*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(462*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          463: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(463*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(463*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          464: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(464*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(464*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          465: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(465*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(465*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          466: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(466*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(466*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          467: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(467*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(467*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          468: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(468*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(468*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          469: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(469*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(469*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          470: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(470*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(470*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          471: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(471*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(471*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          472: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(472*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(472*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          473: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(473*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(473*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          474: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(474*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(474*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          475: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(475*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(475*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          476: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(476*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(476*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          477: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(477*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(477*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          478: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(478*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(478*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          479: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(479*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(479*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          480: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(480*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(480*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          481: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(481*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(481*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          482: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(482*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(482*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          483: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(483*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(483*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          484: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(484*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(484*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          485: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(485*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(485*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          486: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(486*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(486*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          487: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(487*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(487*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          488: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(488*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(488*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          489: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(489*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(489*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          490: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(490*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(490*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          491: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(491*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(491*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          492: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(492*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(492*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          493: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(493*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(493*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          494: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(494*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(494*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          495: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(495*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(495*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          496: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(496*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(496*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          497: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(497*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(497*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          498: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(498*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(498*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          499: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = grid_array[(499*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1:(499*WEIGHT_CHANNELS+weight_chn)*DATA_WIDTH];
          end
          default: begin
            s_axis_weight_tdata[(weight_chn+1)*DATA_WIDTH-1:weight_chn*DATA_WIDTH] = 0;
          end
        endcase
        s_axis_weight_tlast[weight_chn] = i_weight == 499;
        wait(~clk);
        while(~s_axis_weight_tready[weight_chn]) begin
          wait(clk);
          wait(~clk);
        end
        wait(clk);
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
