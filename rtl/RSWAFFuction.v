`resetall
`timescale 1ns/1ps
`default_nettype none

module RSWAFFunction #
(
  parameter DATA_WIDTH_IN = 16,
  parameter DATA_WIDTH_OUT = 16,
  parameter FRACTIONAL_BITS_IN = 12,
  parameter FRACTIONAL_BITS_OUT = 16,
  parameter CHANNELS = 1,
  parameter SHARE_SCALE = 1,
  parameter EXTRA_CYCLE = 0,
  parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : CHANNELS
)
(
  input clk,
  input rst
);

  reg [DATA_WIDTH_IN*CHANNELS-1:0] s_axis_data_tdata;
  reg [CHANNELS-1:0] s_axis_data_tkeep;
  reg s_axis_data_tlast;
  reg s_axis_data_tvalid;
  wire s_axis_data_tready;
  reg [DATA_WIDTH_IN*CHANNELS-1:0] s_axis_grid_tdata;
  reg [CHANNELS-1:0] s_axis_grid_tkeep;
  reg s_axis_grid_tlast;
  reg s_axis_grid_tvalid;
  wire s_axis_grid_tready;
  reg [DATA_WIDTH_IN*SCALE_CHANNELS-1:0] s_axis_scale_tdata;
  reg [((SHARE_SCALE)?0:SCALE_CHANNELS)-1:0] s_axis_scale_tkeep;
  reg s_axis_scale_tlast;
  reg s_axis_scale_tvalid;
  wire s_axis_scale_tready;
  wire [DATA_WIDTH_OUT*CHANNELS-1:0] m_axis_data_tdata;
  wire [CHANNELS-1:0] m_axis_data_tkeep;
  wire m_axis_data_tlast;
  wire m_axis_data_tvalid;
  reg m_axis_data_tready;
  wire [CHANNELS*DATA_WIDTH_IN-1:0] x_tdata_int;
  wire [CHANNELS-1:0] x_tlast_int;
  wire [CHANNELS-1:0] x_tvalid_int;
  wire [CHANNELS-1:0] x_tready_int;
  wire [CHANNELS*DATA_WIDTH_IN-1:0] grid_tdata_int;
  wire [CHANNELS-1:0] grid_tlast_int;
  wire [CHANNELS-1:0] grid_tvalid_int;
  wire [CHANNELS-1:0] grid_tready_int;
  wire [CHANNELS*DATA_WIDTH_IN-1:0] scale_tdata_int;
  wire [CHANNELS-1:0] scale_tlast_int;
  wire [CHANNELS-1:0] scale_tvalid_int;
  wire [CHANNELS-1:0] scale_tready_int;
  wire [CHANNELS*DATA_WIDTH_IN-1:0] diff_tdata_int;
  wire [CHANNELS-1:0] diff_tlast_int;
  wire [CHANNELS-1:0] diff_tvalid_int;
  wire [CHANNELS-1:0] diff_tready_int;
  wire [CHANNELS*DATA_WIDTH_OUT-1:0] act_tdata_int;
  wire [CHANNELS-1:0] act_tlast_int;
  wire [CHANNELS-1:0] act_tvalid_int;
  wire [CHANNELS-1:0] act_tready_int;

  AXISSplitter
  #(
    .DATA_WIDTH(DATA_WIDTH_IN),
    .CHANNELS(CHANNELS),
    .FIFO_DEPTH(CHANNELS)
  )
  x_splitter_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(s_axis_data_tdata),
    .s_axis_0_tkeep(s_axis_data_tkeep),
    .s_axis_0_tlast(s_axis_data_tlast),
    .s_axis_0_tvalid(s_axis_data_tvalid),
    .s_axis_0_tready(s_axis_data_tready),
    .m_axis_0_tdata(x_tdata_int),
    .m_axis_0_tlast(x_tlast_int),
    .m_axis_0_tvalid(x_tvalid_int),
    .m_axis_0_tready(x_tready_int)
  );


  AXISSplitter_
  #(
    .DATA_WIDTH(DATA_WIDTH_IN),
    .CHANNELS(CHANNELS),
    .FIFO_DEPTH(CHANNELS)
  )
  grid_splitter_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(s_axis_grid_tdata),
    .s_axis_0_tkeep(s_axis_grid_tkeep),
    .s_axis_0_tlast(s_axis_grid_tlast),
    .s_axis_0_tvalid(s_axis_grid_tvalid),
    .s_axis_0_tready(s_axis_grid_tready),
    .m_axis_0_tdata(grid_tdata_int),
    .m_axis_0_tlast(grid_tlast_int),
    .m_axis_0_tvalid(grid_tvalid_int),
    .m_axis_0_tready(grid_tready_int)
  );


  generate if(SHARE_SCALE) begin

    AXISBroadcaster
    #(
      .DATA_WIDTH(DATA_WIDTH_IN),
      .CHANNELS(CHANNELS)
    )
    scale_broadcaster_inst
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_axis_scale_tdata),
      .s_axis_0_tvalid(s_axis_scale_tvalid),
      .s_axis_0_tready(s_axis_scale_tready),
      .s_axis_0_tlast(s_axis_scale_tlast),
      .m_axis_0_tdata(scale_tdata_int),
      .m_axis_0_tvalid(scale_tvalid_int),
      .m_axis_0_tready(scale_tready_int),
      .m_axis_0_tlast(scale_tlast_int)
    );

  end else begin

    AXISSplitter
    #(
      .DATA_WIDTH(DATA_WIDTH_IN),
      .CHANNELS(CHANNELS),
      .FIFO_DEPTH(CHANNELS)
    )
    scale_splitter_inst
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_axis_scale_tdata),
      .s_axis_0_tvalid(s_axis_scale_tvalid),
      .s_axis_0_tready(s_axis_scale_tready),
      .s_axis_0_tlast(s_axis_scale_tlast),
      .s_axis_0_tkeep(s_axis_scale_tkeep),
      .m_axis_0_tdata(scale_tdata_int),
      .m_axis_0_tvalid(scale_tvalid_int),
      .m_axis_0_tready(scale_tready_int),
      .m_axis_0_tlast(scale_tlast_int)
    );

  end
  endgenerate

  genvar CHN;

  generate for(CHN=0; CHN<CHANNELS; CHN=CHN+1) begin
    wire [DATA_WIDTH_IN-1:0] x_tdata_int_slice;
    wire x_tvalid_int_slice;
    wire x_tready_int_slice;
    wire x_tlast_int_slice;
    wire [DATA_WIDTH_IN-1:0] grid_tdata_int_slice;
    wire grid_tvalid_int_slice;
    wire grid_tready_int_slice;
    wire grid_tlast_int_slice;
    wire [DATA_WIDTH_IN-1:0] scale_tdata_int_slice;
    wire scale_tvalid_int_slice;
    wire scale_tready_int_slice;
    wire scale_tlast_int_slice;
    wire [DATA_WIDTH_IN-1:0] rslt_tdata_int_slice;
    wire rslt_tvalid_int_slice;
    wire rslt_tready_int_slice;
    wire rslt_tlast_int_slice;
    assign x_tdata_int_slice = x_tdata_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign x_tvalid_int_slice = x_tvalid_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign x_tready_int_slice = x_tready_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign x_tlast_int_slice = x_tlast_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign grid_tdata_int_slice = grid_tdata_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign grid_tvalid_int_slice = grid_tvalid_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign grid_tready_int_slice = grid_tready_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign grid_tlast_int_slice = grid_tlast_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign scale_tdata_int_slice = scale_tdata_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign scale_tvalid_int_slice = scale_tvalid_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign scale_tready_int_slice = scale_tready_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign scale_tlast_int_slice = scale_tlast_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign rslt_tdata_int_slice = diff_tdata_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign rslt_tvalid_int_slice = diff_tvalid_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign rslt_tready_int_slice = diff_tready_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];
    assign rslt_tlast_int_slice = diff_tlast_int[DATA_WIDTH_IN*(CHN+1)-1:DATA_WIDTH_IN*CHN];

    SubMult
    #(
      .DATA_WIDTH("DATA_WIDTH_IN")
    )
    subMult_inst
    (
      .clk(clk),
      .rst(rst),
      .axis_x_tdata(x_tdata_int_slice),
      .axis_x_tvalid(x_tvalid_int_slice),
      .axis_x_tready(x_tready_int_slice),
      .axis_x_tlast(x_tlast_int_slice),
      .axis_grid_tdata(grid_tdata_int_slice),
      .axis_grid_tvalid(grid_tvalid_int_slice),
      .axis_grid_tready(grid_tready_int_slice),
      .axis_grid_tlast(grid_tlast_int_slice),
      .axis_scale_tdata(scale_tdata_int_slice),
      .axis_scale_tvalid(scale_tvalid_int_slice),
      .axis_scale_tready(scale_tready_int_slice),
      .axis_scale_tlast(scale_tlast_int_slice),
      .axis_rslt_tdata(rslt_tdata_int_slice),
      .axis_rslt_tvalid(rslt_tvalid_int_slice),
      .axis_rslt_tready(rslt_tready_int_slice),
      .axis_rslt_tlast(rslt_tlast_int_slice)
    );

  end
  endgenerate


  sech2_lutram
  #(
    .DATA_WIDTH_IN(DATA_WIDTH_IN),
    .DATA_WIDTH_OUT(DATA_WIDTH_OUT),
    .FRACTIONAL_BITS_IN(FRACTIONAL_BITS_IN),
    .FRACTIONAL_BITS_OUT(FRACTIONAL_BITS_OUT),
    .CHANNELS(CHANNELS),
    .EXTRA_CYCLE(EXTRA_CYCLE)
  )
  act_function_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(diff_tdata_int),
    .s_axis_0_tlast(diff_tlast_int),
    .s_axis_0_tvalid(diff_tvalid_int),
    .s_axis_0_tready(diff_tready_int),
    .m_axis_0_tdata(act_tdata_int),
    .m_axis_0_tlast(act_tlast_int),
    .m_axis_0_tvalid(act_tvalid_int),
    .m_axis_0_tready(act_tready_int)
  );


  AXISCombiner
  #(
    .DATA_WIDTH(DATA_WIDTH_OUT),
    .CHANNELS(CHANNELS)
  )
  AXISCombiner_inst
  (
    .clk(clk),
    .rst(rst),
    .s_axis_0_tdata(act_tdata_int),
    .s_axis_0_tlast(act_tlast_int),
    .s_axis_0_tvalid(act_tvalid_int),
    .s_axis_0_tready(act_tready_int),
    .m_axis_0_tdata(m_axis_data_tdata),
    .m_axis_0_tkeep(m_axis_data_tkeep),
    .m_axis_0_tlast(m_axis_data_tlast),
    .m_axis_0_tvalid(m_axis_data_tvalid),
    .m_axis_0_tready(m_axis_data_tready)
  );


endmodule



module AXISBroadcaster #
(
  parameter DATA_WIDTH = 16,
  parameter CHANNELS = 16
)
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] s_axis_0_tdata,
  input s_axis_0_tvalid,
  output s_axis_0_tready,
  input s_axis_0_tlast,
  output [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tvalid,
  input [CHANNELS-1:0] m_axis_0_tready,
  output [CHANNELS-1:0] m_axis_0_tlast
);

  localparam FIFO_DEPTH = 4;
  reg [DATA_WIDTH:0] data_reg;
  reg [CHANNELS-1:0] data_keep_reg;
  wire s_axis_0_tready_reg;
  wire [DATA_WIDTH:0] data_reg_next;
  wire [DATA_WIDTH:0] data_in_next;
  wire [CHANNELS-1:0] data_keep_next;
  wire [CHANNELS-1:0] data_keep_reg_next;
  wire [CHANNELS-1:0] data_keep_in_next;
  wire load_from_reg;
  wire load_from_in;
  wire input_handshake;
  assign load_from_reg = |data_keep_next;
  assign load_from_in = !load_from_reg;
  assign input_handshake = (load_from_in)? s_axis_0_tvalid & s_axis_0_tready_reg : 0;
  assign data_in_next = (input_handshake)? { s_axis_0_tlast, s_axis_0_tdata } : data_reg;
  assign data_reg_next = (load_from_reg)? data_reg : data_in_next;
  assign data_keep_in_next = (input_handshake)? -1 : data_keep_next;
  assign data_keep_reg_next = (load_from_reg)? data_keep_next : data_keep_in_next;
  assign s_axis_0_tready = s_axis_0_tready_reg;
  assign s_axis_0_tready_reg = (rst)? 0 : load_from_in;

  always @(posedge clk) begin
    if(rst) begin
      data_reg <= 0;
      data_keep_reg <= 0;
    end else begin
      data_reg <= data_reg_next;
      data_keep_reg <= data_keep_reg_next;
    end
  end

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
    wire s_fifo_handshake;
    wire m_fifo_handshake;

    always @(*) begin
      s_fifo_tdata <= data_reg[DATA_WIDTH-1:0];
    end

    assign s_fifo_tlast = data_reg[DATA_WIDTH];
    assign s_fifo_tvalid = data_keep_reg;
    assign s_fifo_handshake = s_fifo_tready && s_fifo_tvalid;
    assign data_keep_next[CHN] = (s_fifo_handshake)? 0 : s_fifo_tvalid;
    assign m_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = m_fifo_tdata;
    assign m_fifo_tready = m_axis_0_tready[CHN];
    assign m_axis_0_tvalid[CHN] = m_fifo_tvalid;
    assign m_axis_0_tlast[CHN] = m_fifo_tlast;

    AXISFifo
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
    )
    AXISFifo_inst_i
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_fifo_tdata),
      .s_axis_0_tvalid(s_fifo_tvalid),
      .s_axis_0_tready(s_fifo_tready),
      .s_axis_0_tlast(s_fifo_tlast),
      .m_axis_0_tdata(m_fifo_tdata),
      .m_axis_0_tvalid(m_fifo_tvalid),
      .m_axis_0_tready(m_fifo_tready),
      .m_axis_0_tlast(m_fifo_tlast)
    );

  end
  endgenerate


endmodule



module SubMult #
(
  parameter DATA_WIDTH = 16
)
(
  input clk,
  input rst,
  input [DATA_WIDTH-1:0] axis_x_tdata,
  input axis_x_tvalid,
  output axis_x_tready,
  input axis_x_tlast,
  input [DATA_WIDTH-1:0] axis_grid_tdata,
  input axis_grid_tvalid,
  output axis_grid_tready,
  input axis_grid_tlast,
  input [DATA_WIDTH-1:0] axis_scale_tdata,
  input axis_scale_tvalid,
  output axis_scale_tready,
  input axis_scale_tlast,
  output reg [DATA_WIDTH-1:0] axis_rslt_tdata,
  output reg axis_rslt_tvalid,
  input axis_rslt_tready,
  output reg axis_rslt_tlast
);

  wire _axis_x_read_req_fifo_enq;
  wire [105-1:0] _axis_x_read_req_fifo_wdata;
  wire _axis_x_read_req_fifo_full;
  wire _axis_x_read_req_fifo_almost_full;
  wire _axis_x_read_req_fifo_deq;
  wire [105-1:0] _axis_x_read_req_fifo_rdata;
  wire _axis_x_read_req_fifo_empty;
  wire _axis_x_read_req_fifo_almost_empty;
  assign _axis_x_read_req_fifo_enq = 0;
  assign _axis_x_read_req_fifo_wdata = 'hx;
  assign _axis_x_read_req_fifo_deq = 0;

  _axis_x_read_req_fifo
  inst__axis_x_read_req_fifo
  (
    .CLK(clk),
    .RST(rst),
    ._axis_x_read_req_fifo_enq(_axis_x_read_req_fifo_enq),
    ._axis_x_read_req_fifo_wdata(_axis_x_read_req_fifo_wdata),
    ._axis_x_read_req_fifo_full(_axis_x_read_req_fifo_full),
    ._axis_x_read_req_fifo_almost_full(_axis_x_read_req_fifo_almost_full),
    ._axis_x_read_req_fifo_deq(_axis_x_read_req_fifo_deq),
    ._axis_x_read_req_fifo_rdata(_axis_x_read_req_fifo_rdata),
    ._axis_x_read_req_fifo_empty(_axis_x_read_req_fifo_empty),
    ._axis_x_read_req_fifo_almost_empty(_axis_x_read_req_fifo_almost_empty)
  );

  reg [1-1:0] count__axis_x_read_req_fifo;
  wire [8-1:0] _axis_x_read_op_sel_fifo;
  wire [32-1:0] _axis_x_read_local_addr_fifo;
  wire [32-1:0] _axis_x_read_local_stride_fifo;
  wire [33-1:0] _axis_x_read_local_size_fifo;
  wire [8-1:0] unpack_read_req_op_sel_0;
  wire [32-1:0] unpack_read_req_local_addr_1;
  wire [32-1:0] unpack_read_req_local_stride_2;
  wire [33-1:0] unpack_read_req_local_size_3;
  assign unpack_read_req_op_sel_0 = _axis_x_read_req_fifo_rdata[104:97];
  assign unpack_read_req_local_addr_1 = _axis_x_read_req_fifo_rdata[96:65];
  assign unpack_read_req_local_stride_2 = _axis_x_read_req_fifo_rdata[64:33];
  assign unpack_read_req_local_size_3 = _axis_x_read_req_fifo_rdata[32:0];
  assign _axis_x_read_op_sel_fifo = unpack_read_req_op_sel_0;
  assign _axis_x_read_local_addr_fifo = unpack_read_req_local_addr_1;
  assign _axis_x_read_local_stride_fifo = unpack_read_req_local_stride_2;
  assign _axis_x_read_local_size_fifo = unpack_read_req_local_size_3;
  reg [8-1:0] _axis_x_read_op_sel_buf;
  reg [32-1:0] _axis_x_read_local_addr_buf;
  reg [32-1:0] _axis_x_read_local_stride_buf;
  reg [33-1:0] _axis_x_read_local_size_buf;
  reg _axis_x_read_data_busy;
  wire _axis_x_read_data_idle;
  wire _axis_x_read_idle;
  assign _axis_x_read_data_idle = _axis_x_read_req_fifo_empty && !_axis_x_read_data_busy;
  assign _axis_x_read_idle = _axis_x_read_data_idle;
  wire _axis_grid_read_req_fifo_enq;
  wire [105-1:0] _axis_grid_read_req_fifo_wdata;
  wire _axis_grid_read_req_fifo_full;
  wire _axis_grid_read_req_fifo_almost_full;
  wire _axis_grid_read_req_fifo_deq;
  wire [105-1:0] _axis_grid_read_req_fifo_rdata;
  wire _axis_grid_read_req_fifo_empty;
  wire _axis_grid_read_req_fifo_almost_empty;
  assign _axis_grid_read_req_fifo_enq = 0;
  assign _axis_grid_read_req_fifo_wdata = 'hx;
  assign _axis_grid_read_req_fifo_deq = 0;

  _axis_grid_read_req_fifo
  inst__axis_grid_read_req_fifo
  (
    .CLK(clk),
    .RST(rst),
    ._axis_grid_read_req_fifo_enq(_axis_grid_read_req_fifo_enq),
    ._axis_grid_read_req_fifo_wdata(_axis_grid_read_req_fifo_wdata),
    ._axis_grid_read_req_fifo_full(_axis_grid_read_req_fifo_full),
    ._axis_grid_read_req_fifo_almost_full(_axis_grid_read_req_fifo_almost_full),
    ._axis_grid_read_req_fifo_deq(_axis_grid_read_req_fifo_deq),
    ._axis_grid_read_req_fifo_rdata(_axis_grid_read_req_fifo_rdata),
    ._axis_grid_read_req_fifo_empty(_axis_grid_read_req_fifo_empty),
    ._axis_grid_read_req_fifo_almost_empty(_axis_grid_read_req_fifo_almost_empty)
  );

  reg [1-1:0] count__axis_grid_read_req_fifo;
  wire [8-1:0] _axis_grid_read_op_sel_fifo;
  wire [32-1:0] _axis_grid_read_local_addr_fifo;
  wire [32-1:0] _axis_grid_read_local_stride_fifo;
  wire [33-1:0] _axis_grid_read_local_size_fifo;
  wire [8-1:0] unpack_read_req_op_sel_4;
  wire [32-1:0] unpack_read_req_local_addr_5;
  wire [32-1:0] unpack_read_req_local_stride_6;
  wire [33-1:0] unpack_read_req_local_size_7;
  assign unpack_read_req_op_sel_4 = _axis_grid_read_req_fifo_rdata[104:97];
  assign unpack_read_req_local_addr_5 = _axis_grid_read_req_fifo_rdata[96:65];
  assign unpack_read_req_local_stride_6 = _axis_grid_read_req_fifo_rdata[64:33];
  assign unpack_read_req_local_size_7 = _axis_grid_read_req_fifo_rdata[32:0];
  assign _axis_grid_read_op_sel_fifo = unpack_read_req_op_sel_4;
  assign _axis_grid_read_local_addr_fifo = unpack_read_req_local_addr_5;
  assign _axis_grid_read_local_stride_fifo = unpack_read_req_local_stride_6;
  assign _axis_grid_read_local_size_fifo = unpack_read_req_local_size_7;
  reg [8-1:0] _axis_grid_read_op_sel_buf;
  reg [32-1:0] _axis_grid_read_local_addr_buf;
  reg [32-1:0] _axis_grid_read_local_stride_buf;
  reg [33-1:0] _axis_grid_read_local_size_buf;
  reg _axis_grid_read_data_busy;
  wire _axis_grid_read_data_idle;
  wire _axis_grid_read_idle;
  assign _axis_grid_read_data_idle = _axis_grid_read_req_fifo_empty && !_axis_grid_read_data_busy;
  assign _axis_grid_read_idle = _axis_grid_read_data_idle;
  wire _axis_scale_read_req_fifo_enq;
  wire [105-1:0] _axis_scale_read_req_fifo_wdata;
  wire _axis_scale_read_req_fifo_full;
  wire _axis_scale_read_req_fifo_almost_full;
  wire _axis_scale_read_req_fifo_deq;
  wire [105-1:0] _axis_scale_read_req_fifo_rdata;
  wire _axis_scale_read_req_fifo_empty;
  wire _axis_scale_read_req_fifo_almost_empty;
  assign _axis_scale_read_req_fifo_enq = 0;
  assign _axis_scale_read_req_fifo_wdata = 'hx;
  assign _axis_scale_read_req_fifo_deq = 0;

  _axis_scale_read_req_fifo
  inst__axis_scale_read_req_fifo
  (
    .CLK(clk),
    .RST(rst),
    ._axis_scale_read_req_fifo_enq(_axis_scale_read_req_fifo_enq),
    ._axis_scale_read_req_fifo_wdata(_axis_scale_read_req_fifo_wdata),
    ._axis_scale_read_req_fifo_full(_axis_scale_read_req_fifo_full),
    ._axis_scale_read_req_fifo_almost_full(_axis_scale_read_req_fifo_almost_full),
    ._axis_scale_read_req_fifo_deq(_axis_scale_read_req_fifo_deq),
    ._axis_scale_read_req_fifo_rdata(_axis_scale_read_req_fifo_rdata),
    ._axis_scale_read_req_fifo_empty(_axis_scale_read_req_fifo_empty),
    ._axis_scale_read_req_fifo_almost_empty(_axis_scale_read_req_fifo_almost_empty)
  );

  reg [2-1:0] count__axis_scale_read_req_fifo;
  wire [8-1:0] _axis_scale_read_op_sel_fifo;
  wire [32-1:0] _axis_scale_read_local_addr_fifo;
  wire [32-1:0] _axis_scale_read_local_stride_fifo;
  wire [33-1:0] _axis_scale_read_local_size_fifo;
  wire [8-1:0] unpack_read_req_op_sel_8;
  wire [32-1:0] unpack_read_req_local_addr_9;
  wire [32-1:0] unpack_read_req_local_stride_10;
  wire [33-1:0] unpack_read_req_local_size_11;
  assign unpack_read_req_op_sel_8 = _axis_scale_read_req_fifo_rdata[104:97];
  assign unpack_read_req_local_addr_9 = _axis_scale_read_req_fifo_rdata[96:65];
  assign unpack_read_req_local_stride_10 = _axis_scale_read_req_fifo_rdata[64:33];
  assign unpack_read_req_local_size_11 = _axis_scale_read_req_fifo_rdata[32:0];
  assign _axis_scale_read_op_sel_fifo = unpack_read_req_op_sel_8;
  assign _axis_scale_read_local_addr_fifo = unpack_read_req_local_addr_9;
  assign _axis_scale_read_local_stride_fifo = unpack_read_req_local_stride_10;
  assign _axis_scale_read_local_size_fifo = unpack_read_req_local_size_11;
  reg [8-1:0] _axis_scale_read_op_sel_buf;
  reg [32-1:0] _axis_scale_read_local_addr_buf;
  reg [32-1:0] _axis_scale_read_local_stride_buf;
  reg [33-1:0] _axis_scale_read_local_size_buf;
  reg _axis_scale_read_data_busy;
  wire _axis_scale_read_data_idle;
  wire _axis_scale_read_idle;
  assign _axis_scale_read_data_idle = _axis_scale_read_req_fifo_empty && !_axis_scale_read_data_busy;
  assign _axis_scale_read_idle = _axis_scale_read_data_idle;
  wire _axis_rslt_write_req_fifo_enq;
  wire [105-1:0] _axis_rslt_write_req_fifo_wdata;
  wire _axis_rslt_write_req_fifo_full;
  wire _axis_rslt_write_req_fifo_almost_full;
  wire _axis_rslt_write_req_fifo_deq;
  wire [105-1:0] _axis_rslt_write_req_fifo_rdata;
  wire _axis_rslt_write_req_fifo_empty;
  wire _axis_rslt_write_req_fifo_almost_empty;
  assign _axis_rslt_write_req_fifo_enq = 0;
  assign _axis_rslt_write_req_fifo_wdata = 'hx;
  assign _axis_rslt_write_req_fifo_deq = 0;

  _axis_rslt_write_req_fifo
  inst__axis_rslt_write_req_fifo
  (
    .CLK(clk),
    .RST(rst),
    ._axis_rslt_write_req_fifo_enq(_axis_rslt_write_req_fifo_enq),
    ._axis_rslt_write_req_fifo_wdata(_axis_rslt_write_req_fifo_wdata),
    ._axis_rslt_write_req_fifo_full(_axis_rslt_write_req_fifo_full),
    ._axis_rslt_write_req_fifo_almost_full(_axis_rslt_write_req_fifo_almost_full),
    ._axis_rslt_write_req_fifo_deq(_axis_rslt_write_req_fifo_deq),
    ._axis_rslt_write_req_fifo_rdata(_axis_rslt_write_req_fifo_rdata),
    ._axis_rslt_write_req_fifo_empty(_axis_rslt_write_req_fifo_empty),
    ._axis_rslt_write_req_fifo_almost_empty(_axis_rslt_write_req_fifo_almost_empty)
  );

  reg [1-1:0] count__axis_rslt_write_req_fifo;
  wire [8-1:0] _axis_rslt_write_op_sel_fifo;
  wire [32-1:0] _axis_rslt_write_local_addr_fifo;
  wire [32-1:0] _axis_rslt_write_local_stride_fifo;
  wire [33-1:0] _axis_rslt_write_size_fifo;
  wire [8-1:0] unpack_write_req_op_sel_12;
  wire [32-1:0] unpack_write_req_local_addr_13;
  wire [32-1:0] unpack_write_req_local_stride_14;
  wire [33-1:0] unpack_write_req_local_size_15;
  assign unpack_write_req_op_sel_12 = _axis_rslt_write_req_fifo_rdata[104:97];
  assign unpack_write_req_local_addr_13 = _axis_rslt_write_req_fifo_rdata[96:65];
  assign unpack_write_req_local_stride_14 = _axis_rslt_write_req_fifo_rdata[64:33];
  assign unpack_write_req_local_size_15 = _axis_rslt_write_req_fifo_rdata[32:0];
  assign _axis_rslt_write_op_sel_fifo = unpack_write_req_op_sel_12;
  assign _axis_rslt_write_local_addr_fifo = unpack_write_req_local_addr_13;
  assign _axis_rslt_write_local_stride_fifo = unpack_write_req_local_stride_14;
  assign _axis_rslt_write_size_fifo = unpack_write_req_local_size_15;
  reg [8-1:0] _axis_rslt_write_op_sel_buf;
  reg [32-1:0] _axis_rslt_write_local_addr_buf;
  reg [32-1:0] _axis_rslt_write_local_stride_buf;
  reg [33-1:0] _axis_rslt_write_size_buf;
  reg _axis_rslt_write_data_busy;
  wire _axis_rslt_write_data_idle;
  wire _axis_rslt_write_idle;
  assign _axis_rslt_write_data_idle = _axis_rslt_write_req_fifo_empty && !_axis_rslt_write_data_busy;
  assign _axis_rslt_write_idle = _axis_rslt_write_data_idle;
  reg [32-1:0] th_comp;
  localparam th_comp_init = 0;
  reg signed [DATA_WIDTH-1:0] axistreamin_tdata_16;
  reg axistreamin_tlast_17;
  assign axis_scale_tready = th_comp == 3;
  reg signed [32-1:0] _th_comp_scale_0;
  reg signed [32-1:0] _th_comp_scale_last_1;
  reg signed [32-1:0] _th_comp_x_last_2;
  reg signed [32-1:0] _th_comp_grid_last_3;
  reg signed [DATA_WIDTH-1:0] axistreamin_tdata_18;
  reg axistreamin_tlast_19;
  assign axis_x_tready = th_comp == 11;
  reg signed [32-1:0] _th_comp_x_4;
  reg signed [DATA_WIDTH-1:0] axistreamin_tdata_20;
  reg axistreamin_tlast_21;
  assign axis_grid_tready = th_comp == 14;
  reg signed [32-1:0] _th_comp_grid_5;
  reg signed [32-1:0] _th_comp_rslt_6;
  reg signed [32-1:0] _th_comp_rslt_last_7;
  reg _axis_rslt_cond_0_1;

endmodule



module _axis_x_read_req_fifo
(
  input CLK,
  input RST,
  input _axis_x_read_req_fifo_enq,
  input [105-1:0] _axis_x_read_req_fifo_wdata,
  output _axis_x_read_req_fifo_full,
  output _axis_x_read_req_fifo_almost_full,
  input _axis_x_read_req_fifo_deq,
  output [105-1:0] _axis_x_read_req_fifo_rdata,
  output _axis_x_read_req_fifo_empty,
  output _axis_x_read_req_fifo_almost_empty
);

  reg [105-1:0] mem [0:1-1];
  reg [0-1:0] head;
  reg [0-1:0] tail;
  wire is_empty;
  wire is_almost_empty;
  wire is_full;
  wire is_almost_full;
  assign is_empty = head == tail;
  assign is_almost_empty = head == (tail + 1 & 0);
  assign is_full = (head + 1 & 0) == tail;
  assign is_almost_full = (head + 2 & 0) == tail;
  wire [105-1:0] rdata;
  assign _axis_x_read_req_fifo_full = is_full;
  assign _axis_x_read_req_fifo_almost_full = is_almost_full || is_full;
  assign _axis_x_read_req_fifo_empty = is_empty;
  assign _axis_x_read_req_fifo_almost_empty = is_almost_empty || is_empty;
  assign rdata = mem[tail];
  assign _axis_x_read_req_fifo_rdata = rdata;

  always @(posedge CLK) begin
    if(RST) begin
      head <= 0;
      tail <= 0;
    end else begin
      if(_axis_x_read_req_fifo_enq && !is_full) begin
        mem[head] <= _axis_x_read_req_fifo_wdata;
        head <= head + 1;
      end 
      if(_axis_x_read_req_fifo_deq && !is_empty) begin
        tail <= tail + 1;
      end 
    end
  end


endmodule



module _axis_grid_read_req_fifo
(
  input CLK,
  input RST,
  input _axis_grid_read_req_fifo_enq,
  input [105-1:0] _axis_grid_read_req_fifo_wdata,
  output _axis_grid_read_req_fifo_full,
  output _axis_grid_read_req_fifo_almost_full,
  input _axis_grid_read_req_fifo_deq,
  output [105-1:0] _axis_grid_read_req_fifo_rdata,
  output _axis_grid_read_req_fifo_empty,
  output _axis_grid_read_req_fifo_almost_empty
);

  reg [105-1:0] mem [0:1-1];
  reg [0-1:0] head;
  reg [0-1:0] tail;
  wire is_empty;
  wire is_almost_empty;
  wire is_full;
  wire is_almost_full;
  assign is_empty = head == tail;
  assign is_almost_empty = head == (tail + 1 & 0);
  assign is_full = (head + 1 & 0) == tail;
  assign is_almost_full = (head + 2 & 0) == tail;
  wire [105-1:0] rdata;
  assign _axis_grid_read_req_fifo_full = is_full;
  assign _axis_grid_read_req_fifo_almost_full = is_almost_full || is_full;
  assign _axis_grid_read_req_fifo_empty = is_empty;
  assign _axis_grid_read_req_fifo_almost_empty = is_almost_empty || is_empty;
  assign rdata = mem[tail];
  assign _axis_grid_read_req_fifo_rdata = rdata;

  always @(posedge CLK) begin
    if(RST) begin
      head <= 0;
      tail <= 0;
    end else begin
      if(_axis_grid_read_req_fifo_enq && !is_full) begin
        mem[head] <= _axis_grid_read_req_fifo_wdata;
        head <= head + 1;
      end 
      if(_axis_grid_read_req_fifo_deq && !is_empty) begin
        tail <= tail + 1;
      end 
    end
  end


endmodule



module _axis_scale_read_req_fifo
(
  input CLK,
  input RST,
  input _axis_scale_read_req_fifo_enq,
  input [105-1:0] _axis_scale_read_req_fifo_wdata,
  output _axis_scale_read_req_fifo_full,
  output _axis_scale_read_req_fifo_almost_full,
  input _axis_scale_read_req_fifo_deq,
  output [105-1:0] _axis_scale_read_req_fifo_rdata,
  output _axis_scale_read_req_fifo_empty,
  output _axis_scale_read_req_fifo_almost_empty
);

  reg [105-1:0] mem [0:2-1];
  reg [1-1:0] head;
  reg [1-1:0] tail;
  wire is_empty;
  wire is_almost_empty;
  wire is_full;
  wire is_almost_full;
  assign is_empty = head == tail;
  assign is_almost_empty = head == (tail + 1 & 1);
  assign is_full = (head + 1 & 1) == tail;
  assign is_almost_full = (head + 2 & 1) == tail;
  wire [105-1:0] rdata;
  assign _axis_scale_read_req_fifo_full = is_full;
  assign _axis_scale_read_req_fifo_almost_full = is_almost_full || is_full;
  assign _axis_scale_read_req_fifo_empty = is_empty;
  assign _axis_scale_read_req_fifo_almost_empty = is_almost_empty || is_empty;
  assign rdata = mem[tail];
  assign _axis_scale_read_req_fifo_rdata = rdata;

  always @(posedge CLK) begin
    if(RST) begin
      head <= 0;
      tail <= 0;
    end else begin
      if(_axis_scale_read_req_fifo_enq && !is_full) begin
        mem[head] <= _axis_scale_read_req_fifo_wdata;
        head <= head + 1;
      end 
      if(_axis_scale_read_req_fifo_deq && !is_empty) begin
        tail <= tail + 1;
      end 
    end
  end


endmodule



module _axis_rslt_write_req_fifo
(
  input CLK,
  input RST,
  input _axis_rslt_write_req_fifo_enq,
  input [105-1:0] _axis_rslt_write_req_fifo_wdata,
  output _axis_rslt_write_req_fifo_full,
  output _axis_rslt_write_req_fifo_almost_full,
  input _axis_rslt_write_req_fifo_deq,
  output [105-1:0] _axis_rslt_write_req_fifo_rdata,
  output _axis_rslt_write_req_fifo_empty,
  output _axis_rslt_write_req_fifo_almost_empty
);

  reg [105-1:0] mem [0:1-1];
  reg [0-1:0] head;
  reg [0-1:0] tail;
  wire is_empty;
  wire is_almost_empty;
  wire is_full;
  wire is_almost_full;
  assign is_empty = head == tail;
  assign is_almost_empty = head == (tail + 1 & 0);
  assign is_full = (head + 1 & 0) == tail;
  assign is_almost_full = (head + 2 & 0) == tail;
  wire [105-1:0] rdata;
  assign _axis_rslt_write_req_fifo_full = is_full;
  assign _axis_rslt_write_req_fifo_almost_full = is_almost_full || is_full;
  assign _axis_rslt_write_req_fifo_empty = is_empty;
  assign _axis_rslt_write_req_fifo_almost_empty = is_almost_empty || is_empty;
  assign rdata = mem[tail];
  assign _axis_rslt_write_req_fifo_rdata = rdata;

  always @(posedge CLK) begin
    if(RST) begin
      head <= 0;
      tail <= 0;
    end else begin
      if(_axis_rslt_write_req_fifo_enq && !is_full) begin
        mem[head] <= _axis_rslt_write_req_fifo_wdata;
        head <= head + 1;
      end 
      if(_axis_rslt_write_req_fifo_deq && !is_empty) begin
        tail <= tail + 1;
      end 
    end
  end


endmodule



module AXISSplitter #
(
  parameter DATA_WIDTH = 16,
  parameter CHANNELS = 16,
  parameter FIFO_DEPTH = 4
)
(
  input clk,
  input rst,
  input [DATA_WIDTH*CHANNELS-1:0] s_axis_0_tdata,
  input s_axis_0_tvalid,
  output s_axis_0_tready,
  input s_axis_0_tlast,
  input [CHANNELS-1:0] s_axis_0_tkeep,
  output [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tvalid,
  input [CHANNELS-1:0] m_axis_0_tready,
  output [CHANNELS-1:0] m_axis_0_tlast
);

  reg [DATA_WIDTH*CHANNELS:0] data_reg;
  reg [CHANNELS-1:0] data_keep_reg;
  wire s_axis_0_tready_reg;
  wire [DATA_WIDTH*CHANNELS:0] data_reg_next;
  wire [DATA_WIDTH*CHANNELS:0] data_in_next;
  wire [CHANNELS-1:0] data_keep_next;
  wire [CHANNELS-1:0] data_keep_reg_next;
  wire [CHANNELS-1:0] data_keep_in_next;
  wire load_from_reg;
  wire load_from_in;
  wire input_handshake;
  assign load_from_reg = |data_keep_next;
  assign load_from_in = !load_from_reg;
  assign input_handshake = (load_from_in)? s_axis_0_tvalid & s_axis_0_tready_reg : 0;
  assign data_in_next = (input_handshake)? { s_axis_0_tlast, s_axis_0_tdata } : data_reg;
  assign data_reg_next = (load_from_reg)? data_reg : data_in_next;
  assign data_keep_in_next = (input_handshake)? s_axis_0_tkeep : data_keep_next;
  assign data_keep_reg_next = (load_from_reg)? data_keep_next : data_keep_in_next;
  assign s_axis_0_tready = s_axis_0_tready_reg;
  assign s_axis_0_tready_reg = (rst)? 0 : load_from_in;

  always @(posedge clk) begin
    if(rst) begin
      data_reg <= 0;
      data_keep_reg <= 0;
    end else begin
      data_reg <= data_reg_next;
      data_keep_reg <= data_keep_reg_next;
    end
  end

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
    wire s_fifo_handshake;
    wire m_fifo_handshake;

    always @(*) begin
      s_fifo_tdata <= data_reg[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN];
    end

    assign s_fifo_tlast = data_reg[DATA_WIDTH * CHANNELS];
    assign s_fifo_tvalid = data_keep_reg[CHN];
    assign s_fifo_handshake = s_fifo_tready && s_fifo_tvalid;
    assign data_keep_next[CHN] = (s_fifo_handshake)? 0 : s_fifo_tvalid;
    assign m_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = m_fifo_tdata;
    assign m_fifo_tready = m_axis_0_tready[CHN];
    assign m_axis_0_tvalid[CHN] = m_fifo_tvalid;
    assign m_axis_0_tlast[CHN] = m_fifo_tlast;

    AXISFifo
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
    )
    AXISFifo_inst_i
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_fifo_tdata),
      .s_axis_0_tvalid(s_fifo_tvalid),
      .s_axis_0_tready(s_fifo_tready),
      .s_axis_0_tlast(s_fifo_tlast),
      .m_axis_0_tdata(m_fifo_tdata),
      .m_axis_0_tvalid(m_fifo_tvalid),
      .m_axis_0_tready(m_fifo_tready),
      .m_axis_0_tlast(m_fifo_tlast)
    );

  end
  endgenerate


endmodule



module AXISSplitter_ #
(
  parameter DATA_WIDTH = 16,
  parameter CHANNELS = 16,
  parameter FIFO_DEPTH = 4
)
(
  input clk,
  input rst,
  input [DATA_WIDTH*CHANNELS-1:0] s_axis_0_tdata,
  input s_axis_0_tvalid,
  output s_axis_0_tready,
  input s_axis_0_tlast,
  input [CHANNELS-1:0] s_axis_0_tkeep,
  output [DATA_WIDTH*CHANNELS-1:0] m_axis_0_tdata,
  output [CHANNELS-1:0] m_axis_0_tvalid,
  input [CHANNELS-1:0] m_axis_0_tready,
  output [CHANNELS-1:0] m_axis_0_tlast
);

  reg [DATA_WIDTH*CHANNELS:0] data_reg;
  reg [CHANNELS-1:0] data_keep_reg;
  wire s_axis_0_tready_reg;
  wire [DATA_WIDTH*CHANNELS:0] data_reg_next;
  wire [DATA_WIDTH*CHANNELS:0] data_in_next;
  wire [CHANNELS-1:0] data_keep_next;
  wire [CHANNELS-1:0] data_keep_reg_next;
  wire [CHANNELS-1:0] data_keep_in_next;
  wire load_from_reg;
  wire load_from_in;
  wire input_handshake;
  assign load_from_reg = |data_keep_next;
  assign load_from_in = !load_from_reg;
  assign input_handshake = (load_from_in)? s_axis_0_tvalid & s_axis_0_tready_reg : 0;
  assign data_in_next = (input_handshake)? { s_axis_0_tlast, s_axis_0_tdata } : data_reg;
  assign data_reg_next = (load_from_reg)? data_reg : data_in_next;
  assign data_keep_in_next = (input_handshake)? s_axis_0_tkeep : data_keep_next;
  assign data_keep_reg_next = (load_from_reg)? data_keep_next : data_keep_in_next;
  assign s_axis_0_tready = s_axis_0_tready_reg;
  assign s_axis_0_tready_reg = (rst)? 0 : load_from_in;

  always @(posedge clk) begin
    if(rst) begin
      data_reg <= 0;
      data_keep_reg <= 0;
    end else begin
      data_reg <= data_reg_next;
      data_keep_reg <= data_keep_reg_next;
    end
  end

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
    wire s_fifo_handshake;
    wire m_fifo_handshake;

    always @(*) begin
      s_fifo_tdata <= data_reg[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN];
    end

    assign s_fifo_tlast = data_reg[DATA_WIDTH * CHANNELS];
    assign s_fifo_tvalid = data_keep_reg[CHN];
    assign s_fifo_handshake = s_fifo_tready && s_fifo_tvalid;
    assign data_keep_next[CHN] = (s_fifo_handshake)? 0 : s_fifo_tvalid;
    assign m_axis_0_tdata[DATA_WIDTH*(CHN+1)-1:DATA_WIDTH*CHN] = m_fifo_tdata;
    assign m_fifo_tready = m_axis_0_tready[CHN];
    assign m_axis_0_tvalid[CHN] = m_fifo_tvalid;
    assign m_axis_0_tlast[CHN] = m_fifo_tlast;

    AXISFifo
    #(
      .DATA_WIDTH(DATA_WIDTH),
      .ADDRESS_WIDTH($clog2(FIFO_DEPTH))
    )
    AXISFifo_inst_i
    (
      .clk(clk),
      .rst(rst),
      .s_axis_0_tdata(s_fifo_tdata),
      .s_axis_0_tvalid(s_fifo_tvalid),
      .s_axis_0_tready(s_fifo_tready),
      .s_axis_0_tlast(s_fifo_tlast),
      .m_axis_0_tdata(m_fifo_tdata),
      .m_axis_0_tvalid(m_fifo_tvalid),
      .m_axis_0_tready(m_fifo_tready),
      .m_axis_0_tlast(m_fifo_tlast)
    );

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
