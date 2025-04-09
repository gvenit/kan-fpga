`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  AxisSplitter : Accepts one input AXI-Stream and splits
 *    it to multiple output AXI-Streams.
 *    Big Endianness is assumed
 */

module AxisSplitter #(
  // Width of AXI stream Output Data interfaces in bits
  parameter OUTPUT_DATA_WIDTH = 16,
  // Number of Independent Output AXI-Stream Channels
  parameter CHANNELS = 1,
  // Propagate tkeep signal
  parameter INPUT_KEEP_ENABLE = (CHANNELS*OUTPUT_DATA_WIDTH>8),
  // tkeep signal width (words per cycle)
  parameter INPUT_KEEP_WIDTH = (INPUT_KEEP_ENABLE) ? ((CHANNELS*OUTPUT_DATA_WIDTH+7)/8) : CHANNELS,
  // Propagate tkeep signal
  parameter OUTPUT_KEEP_ENABLE = (OUTPUT_DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter OUTPUT_KEEP_WIDTH = (OUTPUT_KEEP_ENABLE) ? ((OUTPUT_DATA_WIDTH + 7) / 8) : 1,
  // Propagate tlast signal
  parameter LAST_ENABLE = 1,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = (ID_ENABLE) ? 8 : 1,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,
  // Add Buffer on Output Streams
  parameter EXTRA_CYCLE = 0
) (
  input  wire                                   clk,
  input  wire                                   rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*OUTPUT_DATA_WIDTH-1:0]   s_axis_tdata,
  input  wire [INPUT_KEEP_WIDTH-1:0]             s_axis_tkeep,
  input  wire                                    s_axis_tvalid,  
  output wire                                    s_axis_tready,
  input  wire                                    s_axis_tlast,
  input  wire  [ID_WIDTH-1:0]                    s_axis_tid,
  input  wire  [DEST_WIDTH-1:0]                  s_axis_tdest,
  input  wire  [USER_WIDTH-1:0]                  s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*OUTPUT_DATA_WIDTH-1:0]   m_axis_tdata,
  output wire [CHANNELS*OUTPUT_KEEP_WIDTH-1:0]   m_axis_tkeep,
  output wire [CHANNELS-1:0]                     m_axis_tvalid,
  input  wire [CHANNELS-1:0]                     m_axis_tready,
  output wire [CHANNELS-1:0]                     m_axis_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]            m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]          m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]          m_axis_tuser

);
  // DataFlow Local Parameters
  localparam INPUT_DATA_WIDTH = CHANNELS*OUTPUT_DATA_WIDTH;

  // AXI-Stream internal signals
  wire [INPUT_DATA_WIDTH-1:0] int_axis_tdata;
  wire [INPUT_KEEP_WIDTH-1:0] int_axis_tkeep;
  wire                        int_axis_tvalid;
  wire                        int_axis_tready;
  wire                        int_axis_tlast;
  wire [ID_WIDTH-1:0]         int_axis_tid;
  wire [DEST_WIDTH-1:0]       int_axis_tdest;
  wire [USER_WIDTH-1:0]       int_axis_tuser;


  // AXI-Stream internal channel signals
  wire [OUTPUT_DATA_WIDTH-1:0] int_axis_chn_tdata [0:CHANNELS-1];
  wire [OUTPUT_KEEP_WIDTH-1:0] int_axis_chn_tkeep [0:CHANNELS-1];
  wire [CHANNELS-1:0]          int_axis_chn_tvalid;
  wire [CHANNELS-1:0]          int_axis_chn_tready;
  // Copies of the int_axis_tXXX signals
  // wire [CHANNELS-1:0]          int_axis_chn_tlast;
  // wire [ID_WIDTH-1:0]          int_axis_chn_tid   [0:CHANNELS-1];
  // wire [DEST_WIDTH-1:0]        int_axis_chn_tdest [0:CHANNELS-1];
  // wire [USER_WIDTH-1:0]        int_axis_chn_tuser [0:CHANNELS-1];

  // Control signals
  reg  [CHANNELS-1:0]           locked_channels_reg;    // Channels that should wait for other channels to complete their transfer
  wire [CHANNELS-1:0]           locked_channels_next;   // Channels that should wait for other channels to complete their transfer in the next cycle
  wire [CHANNELS-1:0]           handshakes;             // Possible handshakes in the current cycle
  wire [CHANNELS-1:0]           keep_channels;          // Channels that contain data
  wire                          new_transfer;           // Gate to allow processing of new data on next cycle

  axis_register #(
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(CHANNELS*OUTPUT_DATA_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(INPUT_KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(INPUT_KEEP_WIDTH),
    // Propagate tlast signal
    .LAST_ENABLE(LAST_ENABLE),
    // Propagate tid signal
    .ID_ENABLE(ID_ENABLE),
    // tid signal width
    .ID_WIDTH(ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(USER_ENABLE),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Register type
    // 0 to bypass, 1 for simple buffer, 2 for skid buffer
    .REG_TYPE(2)
  ) in_axis_register_inst (
    .clk(clk),
    .rst(rst),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .s_axis_tid(s_axis_tid),
    .s_axis_tdest(s_axis_tdest),
    .s_axis_tuser(s_axis_tuser),
    .m_axis_tdata(int_axis_tdata),
    .m_axis_tkeep(int_axis_tkeep),
    .m_axis_tvalid(int_axis_tvalid),
    .m_axis_tready(int_axis_tready),
    .m_axis_tlast(int_axis_tlast),
    .m_axis_tid(int_axis_tid),
    .m_axis_tdest(int_axis_tdest),
    .m_axis_tuser(int_axis_tuser)
  );

  genvar CHN;

  // Control Signals
  assign locked_channels_next = new_transfer == 1'b1 ? {CHANNELS{1'b0}} : ( locked_channels_reg | handshakes );

  assign handshakes = int_axis_chn_tvalid & int_axis_chn_tready;

  // Validate data transfer from slave side
  assign int_axis_tready = new_transfer;

  assign new_transfer = &( ( ~keep_channels ) | ( locked_channels_reg | handshakes ) );

  generate
    for ( CHN = 0 ; CHN < CHANNELS ; CHN=CHN+1 ) begin
      // Break Internal AXI_Stream Data into channels
      assign int_axis_chn_tdata    [CHN] = int_axis_tdata  [(CHN+1)*OUTPUT_DATA_WIDTH-1 : CHN*OUTPUT_DATA_WIDTH];

      if (INPUT_KEEP_ENABLE) begin
        // Split KEEP signal to the corresponding channel
        assign int_axis_chn_tkeep  [CHN] = int_axis_tkeep [(CHN+1)*OUTPUT_KEEP_WIDTH-1 : CHN*OUTPUT_KEEP_WIDTH];

        // Check if there is data to keep in each channel
        assign keep_channels       [CHN] = |( int_axis_chn_tkeep[CHN] );
      end else begin
        // Channels always contain data
        assign keep_channels       [CHN] = 1'b1;
      end

      // Validate data transfer from master side
      assign int_axis_chn_tvalid   [CHN] = int_axis_tvalid && ~ locked_channels_reg[CHN] && keep_channels[CHN];

      if (EXTRA_CYCLE) begin
        axis_register #(
          // Width of AXI stream interfaces in bits
          .DATA_WIDTH(OUTPUT_DATA_WIDTH),
          // Propagate tkeep signal
          .KEEP_ENABLE(OUTPUT_KEEP_ENABLE),
          // tkeep signal width (words per cycle)
          .KEEP_WIDTH(OUTPUT_KEEP_WIDTH),
          // Propagate tlast signal
          .LAST_ENABLE(LAST_ENABLE),
          // Propagate tid signal
          .ID_ENABLE(ID_ENABLE),
          // tid signal width
          .ID_WIDTH(ID_WIDTH),
          // Propagate tdest signal
          .DEST_ENABLE(DEST_ENABLE),
          // tdest signal width
          .DEST_WIDTH(DEST_WIDTH),
          // Propagate tuser signal
          .USER_ENABLE(USER_ENABLE),
          // tuser signal width
          .USER_WIDTH(USER_WIDTH),
          // Register type
          // 0 to bypass, 1 for simple buffer, 2 for skid buffer
          .REG_TYPE(2)
        ) out_axis_register_inst (
          .clk(clk),
          .rst(rst),
          .s_axis_tdata(int_axis_chn_tdata[CHN]),
          .s_axis_tkeep(int_axis_chn_tkeep[CHN]),
          .s_axis_tvalid(int_axis_chn_tvalid[CHN]),
          .s_axis_tready(int_axis_chn_tready[CHN]),
          .s_axis_tlast(int_axis_tlast),
          .s_axis_tid(int_axis_tid),
          .s_axis_tdest(int_axis_tdest),
          .s_axis_tuser(int_axis_tuser),
          .m_axis_tdata(m_axis_tdata[(CHN+1)*OUTPUT_DATA_WIDTH-1 : CHN*OUTPUT_DATA_WIDTH]),
          .m_axis_tkeep(m_axis_tkeep[(CHN+1)*OUTPUT_KEEP_WIDTH-1 : CHN*OUTPUT_KEEP_WIDTH]),
          .m_axis_tvalid(m_axis_tvalid[CHN]),
          .m_axis_tready(m_axis_tready[CHN]),
          .m_axis_tlast(m_axis_tlast[CHN]),
          .m_axis_tid(m_axis_tid[(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH]),
          .m_axis_tdest(m_axis_tdest[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH]),
          .m_axis_tuser(m_axis_tuser[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH])
        );

      end else begin
          assign m_axis_tdata[(CHN+1)*OUTPUT_DATA_WIDTH-1 : CHN*OUTPUT_DATA_WIDTH] = int_axis_chn_tdata[CHN];
          assign m_axis_tvalid[CHN]                                                = int_axis_chn_tvalid[CHN];
          assign int_axis_chn_tready[CHN]                                          = m_axis_tready[CHN];
          assign m_axis_tlast[CHN]                                                 = int_axis_tlast;
          assign m_axis_tid[(CHN+1)*ID_WIDTH-1 : CHN*ID_WIDTH]                     = int_axis_tid;
          assign m_axis_tdest[(CHN+1)*DEST_WIDTH-1 : CHN*DEST_WIDTH]               = int_axis_tdest;
          assign m_axis_tuser[(CHN+1)*USER_WIDTH-1 : CHN*USER_WIDTH]               = int_axis_tuser;

          assign m_axis_tkeep[(CHN+1)*OUTPUT_KEEP_WIDTH-1 : CHN*OUTPUT_KEEP_WIDTH] = (OUTPUT_KEEP_ENABLE) ? int_axis_chn_tkeep[CHN]  : {OUTPUT_KEEP_WIDTH{1'bX}};
      end

    end
 endgenerate

  // Update locked_channels register
  always @(posedge clk ) begin
    if (rst == 1'b1) begin
      locked_channels_reg <= {CHANNELS{1'b0}};
    end else begin
      locked_channels_reg <= locked_channels_next;
    end
  end

endmodule

`resetall
