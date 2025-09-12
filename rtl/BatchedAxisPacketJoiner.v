`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  BatchedAxisPacketJoiner : Accepts multiple input AXI-Stream Packets 
 *    and outputs a multiple Axi-Stream Packets in a single channel. 
 *    The output packet is a concatenation of the input packets. 
 *    The module awaits data from the specified channels, starting 
 *    from the first channel.
 */
`include "header_utils.vh"

module BatchedAxisPacketJoiner #(
  // Number of Batches
  parameter BATCH_SIZE = 1,
  // Number of Channels per Batch
  parameter CHANNELS = 2,
  // Width of AXI stream input Data interfaces in bits
  parameter S_DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter S_KEEP_ENABLE = (S_DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter S_KEEP_WIDTH = (S_KEEP_ENABLE) ? ((S_DATA_WIDTH + 7) / 8) : 1,
  // Width of AXI stream output Data interfaces in bits
  parameter M_DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter M_KEEP_ENABLE = (M_DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter M_KEEP_WIDTH = (M_KEEP_ENABLE) ? ((M_DATA_WIDTH + 7) / 8) : 1,
  // Propagate tid signal
  parameter S_ID_ENABLE = 0,
  // tid signal width
  parameter S_ID_WIDTH = (S_ID_ENABLE) ? 8 : 1,
  // tid signal width output
  parameter M_ID_WIDTH = ((S_ID_ENABLE) ? S_ID_WIDTH : 0) + `LOG2(BATCH_SIZE),
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,
  // Word Width of maximum allowed packet size
  parameter PCKT_WIDTH = 32,
  // FIFO data depth per batch
  parameter FIFO_DEPTH = 4096
) (
  input  wire                                         s_clk,
  input  wire                                         s_rst,
  
  input  wire                                         m_clk,
  input  wire                                         m_rst,

  /*
   * Control signals
   */
  input  wire                                         operation_start,
  input  wire [CHANNELS-1:0]                          use_channels,
  input  wire [BATCH_SIZE-1:0]                        use_batch,
  input  wire [PCKT_WIDTH-1:0]                        pckt_size,
  
  /*
   * Input Interrupt signals
   */
  input  wire                                         interrupt,
  
  /*
   * Output Interrupt signals
   */
  output reg                                          operation_busy,
  output reg                                          operation_complete,
  output reg                                          operation_error,
  output reg                                          transmission,       // Active high if bus transmitted data in the current cycle

  /*
   * AXI Stream Data input
   */
  input  wire [BATCH_SIZE*CHANNELS*S_DATA_WIDTH-1:0]  s_axis_tdata,
  input  wire [BATCH_SIZE*CHANNELS*S_KEEP_WIDTH-1:0]  s_axis_tkeep,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tvalid,  
  output wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tready,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tlast,
  input  wire [BATCH_SIZE*CHANNELS*S_ID_WIDTH-1:0]    s_axis_tid,
  input  wire [BATCH_SIZE*CHANNELS*DEST_WIDTH-1:0]    s_axis_tdest,
  input  wire [BATCH_SIZE*CHANNELS*USER_WIDTH-1:0]    s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [M_DATA_WIDTH-1:0]                      m_axis_tdata,
  output wire [M_KEEP_WIDTH-1:0]                      m_axis_tkeep,
  output wire                                         m_axis_tvalid,
  input  wire                                         m_axis_tready,
  output wire                                         m_axis_tlast,
  output wire [M_ID_WIDTH-1:0]                        m_axis_tid,
  output wire [DEST_WIDTH-1:0]                        m_axis_tdest,
  output wire [USER_WIDTH-1:0]                        m_axis_tuser
);

  wire [BATCH_SIZE*CHANNELS*S_DATA_WIDTH-1:0]   int_jnr_btch_s_axis_tdata;
  wire [BATCH_SIZE*CHANNELS*S_KEEP_WIDTH-1:0]   int_jnr_btch_s_axis_tkeep;
  wire [BATCH_SIZE*CHANNELS-1:0]                int_jnr_btch_s_axis_tvalid;
  wire [BATCH_SIZE*CHANNELS-1:0]                int_jnr_btch_s_axis_tready;
  wire [BATCH_SIZE*CHANNELS-1:0]                int_jnr_btch_s_axis_tlast;
  wire [BATCH_SIZE*CHANNELS*S_ID_WIDTH-1:0]     int_jnr_btch_s_axis_tid;
  wire [BATCH_SIZE*CHANNELS*DEST_WIDTH-1:0]     int_jnr_btch_s_axis_tdest;
  wire [BATCH_SIZE*CHANNELS*USER_WIDTH-1:0]     int_jnr_btch_s_axis_tuser;

  wire [BATCH_SIZE*S_DATA_WIDTH-1:0]            int_jnr_btch_m_axis_tdata;
  wire [BATCH_SIZE*S_KEEP_WIDTH-1:0]            int_jnr_btch_m_axis_tkeep;
  wire [BATCH_SIZE-1:0]                         int_jnr_btch_m_axis_tvalid;
  wire [BATCH_SIZE-1:0]                         int_jnr_btch_m_axis_tready;
  wire [BATCH_SIZE-1:0]                         int_jnr_btch_m_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]              int_jnr_btch_m_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]              int_jnr_btch_m_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]              int_jnr_btch_m_axis_tuser;

  wire                                          aps_external_error;
  wire                                          aps_operation_busy;
  wire                                          aps_operation_complete;
  wire                                          aps_operation_error;
  wire [BATCH_SIZE-1:0]                         aps_transmission;

  wire [BATCH_SIZE*S_DATA_WIDTH-1:0]            int_aps_btch_s_axis_tdata , int_aps_btch_m_axis_tdata;
  wire [BATCH_SIZE*S_KEEP_WIDTH-1:0]            int_aps_btch_s_axis_tkeep , int_aps_btch_m_axis_tkeep;
  wire [BATCH_SIZE-1:0]                         int_aps_btch_s_axis_tvalid, int_aps_btch_m_axis_tvalid;
  wire [BATCH_SIZE-1:0]                         int_aps_btch_s_axis_tready, int_aps_btch_m_axis_tready;
  wire [BATCH_SIZE-1:0]                         int_aps_btch_s_axis_tlast , int_aps_btch_m_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]              int_aps_btch_s_axis_tid   , int_aps_btch_m_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]              int_aps_btch_s_axis_tdest , int_aps_btch_m_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]              int_aps_btch_s_axis_tuser , int_aps_btch_m_axis_tuser;

  wire [BATCH_SIZE*S_DATA_WIDTH-1:0]            int_adp_btch_s_axis_tdata;
  wire [BATCH_SIZE*S_KEEP_WIDTH-1:0]            int_adp_btch_s_axis_tkeep;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_s_axis_tvalid;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_s_axis_tready;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_s_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]              int_adp_btch_s_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]              int_adp_btch_s_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]              int_adp_btch_s_axis_tuser;

  wire [BATCH_SIZE*M_DATA_WIDTH-1:0]            int_adp_btch_m_axis_tdata;
  wire [BATCH_SIZE*M_KEEP_WIDTH-1:0]            int_adp_btch_m_axis_tkeep;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_m_axis_tvalid;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_m_axis_tready;
  wire [BATCH_SIZE-1:0]                         int_adp_btch_m_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]              int_adp_btch_m_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]              int_adp_btch_m_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]              int_adp_btch_m_axis_tuser;

  wire [BATCH_SIZE*M_DATA_WIDTH-1:0]            int_mux_btch_s_axis_tdata;
  wire [BATCH_SIZE*M_KEEP_WIDTH-1:0]            int_mux_btch_s_axis_tkeep;
  wire [BATCH_SIZE-1:0]                         int_mux_btch_s_axis_tvalid;
  wire [BATCH_SIZE-1:0]                         int_mux_btch_s_axis_tready;
  wire [BATCH_SIZE-1:0]                         int_mux_btch_s_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]              int_mux_btch_s_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]              int_mux_btch_s_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]              int_mux_btch_s_axis_tuser;

  wire [M_DATA_WIDTH-1:0]                       int_mux_btch_m_axis_tdata;
  wire [M_KEEP_WIDTH-1:0]                       int_mux_btch_m_axis_tkeep;
  wire                                          int_mux_btch_m_axis_tvalid;
  wire                                          int_mux_btch_m_axis_tready;
  wire                                          int_mux_btch_m_axis_tlast;
  wire [M_ID_WIDTH-1:0]                         int_mux_btch_m_axis_tid;
  wire [DEST_WIDTH-1:0]                         int_mux_btch_m_axis_tdest;
  wire [USER_WIDTH-1:0]                         int_mux_btch_m_axis_tuser;

  // Handle module statistics
  wire [BATCH_SIZE-1:0] batch_lock;
  wire [BATCH_SIZE-1:0] batch_interrupt;
  wire [BATCH_SIZE-1:0] batch_operation_busy;
  wire [BATCH_SIZE-1:0] batch_operation_complete;
  wire [BATCH_SIZE-1:0] batch_operation_error;
  wire [BATCH_SIZE-1:0] batch_transmission;

  reg  [BATCH_SIZE-1:0] use_batch_reg;
  reg  [BATCH_SIZE-1:0] batch_operation_complete_reg = 0;
  wire [BATCH_SIZE-1:0] batch_operation_complete_reg_next = batch_operation_complete | batch_operation_complete_reg;

  wire int_external_error = 1'b0;
  wire op_done = &batch_operation_complete_reg_next;
  wire op_busy = |batch_operation_busy;

 generate
  genvar batch;
  for (batch = 0; batch < BATCH_SIZE; batch = batch + 1) begin : axis_packet_joiner_batch_genblock
    AxisPacketJoiner #(
      .CHANNELS           (CHANNELS),
      .DATA_WIDTH         (S_DATA_WIDTH),
      .KEEP_ENABLE        (S_KEEP_ENABLE),
      .KEEP_WIDTH         (S_KEEP_WIDTH),
      .ID_ENABLE          (S_ID_ENABLE),
      .ID_WIDTH           (S_ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH),
      .ALLOW_LOCKS        (BATCH_SIZE > 1)
    ) AxisPacketJoiner_i  (
      .clk                (s_clk),
      .rst                (s_rst),
      .operation_start    ((BATCH_SIZE > 1 ? (op_busy ? use_batch_reg[batch] : operation_start && use_batch[batch]) : operation_start)),
      .use_channels       (use_channels),
      .lock               (batch_lock                   [batch]),
      .interrupt          (interrupt),
      .operation_busy     (batch_operation_busy         [batch]),
      .operation_complete (batch_operation_complete     [batch]),
      .operation_error    (batch_operation_error        [batch]),
      .transmission       (batch_transmission           [batch]),       // Active high if bus transmitted data in the current cycle
      .s_axis_tdata       (int_jnr_btch_s_axis_tdata    [batch*CHANNELS*S_DATA_WIDTH +: CHANNELS*S_DATA_WIDTH]),
      .s_axis_tkeep       (int_jnr_btch_s_axis_tkeep    [batch*CHANNELS*S_KEEP_WIDTH +: CHANNELS*S_KEEP_WIDTH]),
      .s_axis_tvalid      (int_jnr_btch_s_axis_tvalid   [batch*CHANNELS +: CHANNELS]),
      .s_axis_tready      (int_jnr_btch_s_axis_tready   [batch*CHANNELS +: CHANNELS]),
      .s_axis_tlast       (int_jnr_btch_s_axis_tlast    [batch*CHANNELS +: CHANNELS]),
      .s_axis_tid         (int_jnr_btch_s_axis_tid      [batch*CHANNELS*S_ID_WIDTH +: CHANNELS*S_ID_WIDTH]),
      .s_axis_tdest       (int_jnr_btch_s_axis_tdest    [batch*CHANNELS*DEST_WIDTH +: CHANNELS*DEST_WIDTH]),
      .s_axis_tuser       (int_jnr_btch_s_axis_tuser    [batch*CHANNELS*USER_WIDTH +: CHANNELS*USER_WIDTH]),
      .m_axis_tdata       (int_jnr_btch_m_axis_tdata    [batch*S_DATA_WIDTH +: S_DATA_WIDTH]),
      .m_axis_tkeep       (int_jnr_btch_m_axis_tkeep    [batch*S_KEEP_WIDTH +: S_KEEP_WIDTH]),
      .m_axis_tvalid      (int_jnr_btch_m_axis_tvalid   [batch]),
      .m_axis_tready      (int_jnr_btch_m_axis_tready   [batch]),
      .m_axis_tlast       (int_jnr_btch_m_axis_tlast    [batch]),
      .m_axis_tid         (int_jnr_btch_m_axis_tid      [batch*S_ID_WIDTH +: S_ID_WIDTH]),
      .m_axis_tdest       (int_jnr_btch_m_axis_tdest    [batch*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (int_jnr_btch_m_axis_tuser    [batch*USER_WIDTH +: USER_WIDTH])
    );
  end 
 endgenerate
 
  ExtendedAxisPacketSplitter #(
    .CHANNELS             (BATCH_SIZE),
    .DATA_WIDTH           (S_DATA_WIDTH),
    .KEEP_ENABLE          (S_KEEP_ENABLE),
    .KEEP_WIDTH           (S_KEEP_WIDTH),
    .ID_ENABLE            (S_ID_ENABLE),
    .ID_WIDTH             (S_ID_WIDTH),
    .DEST_ENABLE          (DEST_ENABLE),
    .DEST_WIDTH           (DEST_WIDTH),
    .USER_ENABLE          (USER_ENABLE),
    .USER_WIDTH           (USER_WIDTH),
    .PCKT_WIDTH           (PCKT_WIDTH),
    .IGNORE_TLAST         (1),
    .RAISE_NON_DIVISIBLE  (0)
  ) axis_aps_btch_inst    (
    .clk                  (s_clk),
    .rst                  (s_rst),
    .operation_start      (operation_start),
    .pckt_size            (pckt_size),
    .external_error       (aps_external_error),
    .operation_busy       (aps_operation_busy),
    .operation_complete   (aps_operation_complete),
    .operation_error      (aps_operation_error),
    .transmission         (aps_transmission),
    .s_axis_tdata         (int_aps_btch_s_axis_tdata),
    .s_axis_tkeep         (int_aps_btch_s_axis_tkeep),
    .s_axis_tvalid        (int_aps_btch_s_axis_tvalid),
    .s_axis_tready        (int_aps_btch_s_axis_tready),
    .s_axis_tlast         (int_aps_btch_s_axis_tlast),
    .s_axis_tid           (int_aps_btch_s_axis_tid),
    .s_axis_tdest         (int_aps_btch_s_axis_tdest),
    .s_axis_tuser         (int_aps_btch_s_axis_tuser),
    .m_axis_tdata         (int_aps_btch_m_axis_tdata),
    .m_axis_tkeep         (int_aps_btch_m_axis_tkeep),
    .m_axis_tvalid        (int_aps_btch_m_axis_tvalid),
    .m_axis_tready        (int_aps_btch_m_axis_tready),
    .m_axis_tlast         (int_aps_btch_m_axis_tlast),
    .m_axis_tid           (int_aps_btch_m_axis_tid),
    .m_axis_tdest         (int_aps_btch_m_axis_tdest),
    .m_axis_tuser         (int_aps_btch_m_axis_tuser)
  );

 generate
  for (batch = 0; batch < BATCH_SIZE; batch = batch + 1) begin : axis_adp_batch_genblock
    axis_async_fifo_adapter #(
      .DEPTH              (FIFO_DEPTH),
      .S_DATA_WIDTH       (S_DATA_WIDTH),
      .S_KEEP_ENABLE      (S_KEEP_ENABLE),
      .S_KEEP_WIDTH       (S_KEEP_WIDTH),
      .M_DATA_WIDTH       (M_DATA_WIDTH),
      .M_KEEP_ENABLE      (M_KEEP_ENABLE),
      .M_KEEP_WIDTH       (M_KEEP_WIDTH),
      .ID_ENABLE          (S_ID_ENABLE),
      .ID_WIDTH           (S_ID_WIDTH),
      .DEST_ENABLE        (DEST_ENABLE),
      .DEST_WIDTH         (DEST_WIDTH),
      .USER_ENABLE        (USER_ENABLE),
      .USER_WIDTH         (USER_WIDTH)
    ) axis_adp_batch_inst (
      .s_clk              (s_clk),
      .s_rst              (s_rst),
      .s_axis_tdata       (int_adp_btch_s_axis_tdata   [batch*S_DATA_WIDTH +: S_DATA_WIDTH]),
      .s_axis_tkeep       (int_adp_btch_s_axis_tkeep   [batch*S_KEEP_WIDTH +: S_KEEP_WIDTH]),
      .s_axis_tvalid      (int_adp_btch_s_axis_tvalid  [batch]),
      .s_axis_tready      (int_adp_btch_s_axis_tready  [batch]),
      .s_axis_tlast       (int_adp_btch_s_axis_tlast   [batch]),
      .s_axis_tid         (int_adp_btch_s_axis_tid     [batch*S_ID_WIDTH   +: S_ID_WIDTH]),
      .s_axis_tdest       (int_adp_btch_s_axis_tdest   [batch*DEST_WIDTH   +: DEST_WIDTH]),
      .s_axis_tuser       (int_adp_btch_s_axis_tuser   [batch*USER_WIDTH   +: USER_WIDTH]),
      .m_clk              (m_clk),
      .m_rst              (m_rst),
      .m_axis_tdata       (int_adp_btch_m_axis_tdata   [batch*M_DATA_WIDTH +: M_DATA_WIDTH]),
      .m_axis_tkeep       (int_adp_btch_m_axis_tkeep   [batch*M_KEEP_WIDTH +: M_KEEP_WIDTH]),
      .m_axis_tvalid      (int_adp_btch_m_axis_tvalid  [batch]),
      .m_axis_tready      (int_adp_btch_m_axis_tready  [batch]),
      .m_axis_tlast       (int_adp_btch_m_axis_tlast   [batch]),
      .m_axis_tid         (int_adp_btch_m_axis_tid     [batch*S_ID_WIDTH   +: S_ID_WIDTH]),
      .m_axis_tdest       (int_adp_btch_m_axis_tdest   [batch*DEST_WIDTH   +: DEST_WIDTH]),
      .m_axis_tuser       (int_adp_btch_m_axis_tuser   [batch*USER_WIDTH   +: USER_WIDTH]),
      .s_pause_req        (1'b0),
      .m_pause_req        (1'b0)
    );
  end 
 endgenerate

 generate if (BATCH_SIZE == 1) begin : single_batch_genblock
  assign int_mux_btch_m_axis_tdata  = int_mux_btch_s_axis_tdata;
  assign int_mux_btch_m_axis_tkeep  = int_mux_btch_s_axis_tkeep;
  assign int_mux_btch_m_axis_tvalid = int_mux_btch_s_axis_tvalid;
  assign int_mux_btch_s_axis_tready = int_mux_btch_m_axis_tready;
  assign int_mux_btch_m_axis_tlast  = int_mux_btch_s_axis_tlast;
  assign int_mux_btch_m_axis_tid    = int_mux_btch_s_axis_tid;
  assign int_mux_btch_m_axis_tdest  = int_mux_btch_s_axis_tdest;
  assign int_mux_btch_m_axis_tuser  = int_mux_btch_s_axis_tuser;
  
  assign batch_lock         = 0;
  assign aps_external_error = batch_operation_error;

  always @(*) begin
    operation_busy     <= batch_operation_busy;
    operation_complete <= batch_operation_complete;
    operation_error    <= batch_operation_error || aps_operation_error;
    transmission       <= batch_transmission;
  end
 end else begin : multi_batch_genblock
  // Multiplex all packets to a single channel
  axis_arb_mux #(
    .S_COUNT                  (BATCH_SIZE),
    .DATA_WIDTH               (M_DATA_WIDTH),
    .KEEP_ENABLE              (M_KEEP_ENABLE),
    .KEEP_WIDTH               (M_KEEP_WIDTH),
    .ID_ENABLE                (1),
    .S_ID_WIDTH               (S_ID_WIDTH),
    .M_ID_WIDTH               (M_ID_WIDTH),
    .DEST_ENABLE              (DEST_ENABLE),
    .DEST_WIDTH               (DEST_WIDTH),
    .USER_ENABLE              (USER_ENABLE),
    .USER_WIDTH               (USER_WIDTH),
    .LAST_ENABLE              (1),
    .UPDATE_TID               (1),
    .ARB_TYPE_ROUND_ROBIN     (0),
    .ARB_LSB_HIGH_PRIORITY    (1)
  ) packet_mux (
    .clk                      (m_clk),
    .rst                      (m_rst),
    .s_axis_tdata             (int_mux_btch_s_axis_tdata),
    .s_axis_tkeep             (int_mux_btch_s_axis_tkeep),
    .s_axis_tvalid            (int_mux_btch_s_axis_tvalid),
    .s_axis_tready            (int_mux_btch_s_axis_tready),
    .s_axis_tlast             (int_mux_btch_s_axis_tlast),
    .s_axis_tid               (int_mux_btch_s_axis_tid),
    .s_axis_tdest             (int_mux_btch_s_axis_tdest),
    .s_axis_tuser             (int_mux_btch_s_axis_tuser),
    .m_axis_tdata             (int_mux_btch_m_axis_tdata),
    .m_axis_tkeep             (int_mux_btch_m_axis_tkeep),
    .m_axis_tvalid            (int_mux_btch_m_axis_tvalid),
    .m_axis_tready            (int_mux_btch_m_axis_tready),
    .m_axis_tlast             (int_mux_btch_m_axis_tlast),
    .m_axis_tid               (int_mux_btch_m_axis_tid),
    .m_axis_tdest             (int_mux_btch_m_axis_tdest),
    .m_axis_tuser             (int_mux_btch_m_axis_tuser)
  );

  reg invalid_batch_config;

  assign batch_lock = {BATCH_SIZE{~op_done}} & batch_operation_complete_reg_next;
  assign batch_interrupt = (interrupt) || (|batch_operation_error) ? {BATCH_SIZE{1'b1}} : {BATCH_SIZE{1'b0}}; 

  assign aps_external_error = |{batch_operation_error, interrupt};

  always @(*) begin
    if (s_rst) begin
      operation_busy     <= 1'b0;
      operation_complete <= 1'b0;
      operation_error    <= 1'b0;
      transmission       <= 1'b0;
    end else begin
      operation_busy     <= 1'b0;
      operation_complete <= 1'b0;
      operation_error    <= 1'b0;
      transmission       <= m_axis_tready && m_axis_tvalid;
      if (|batch_operation_error || invalid_batch_config || aps_operation_error) begin
        operation_error    <= 1'b1;
      end else if (op_done) begin
        operation_complete <= 1'b1;
      end else if (op_busy) begin
        operation_busy     <= 1'b1;
      end
    end
  end

  always @(posedge s_clk ) begin
    if (s_rst) begin
      use_batch_reg                <= 0;
      batch_operation_complete_reg <= 0;
      invalid_batch_config         <= 1'b0;
    end else begin
      use_batch_reg                <= use_batch_reg;
      batch_operation_complete_reg <= 0;
      invalid_batch_config         <= 1'b0;
      if (int_external_error) begin
      // end else if (op_done) begin
      end else if (op_busy) begin
        use_batch_reg <= use_batch_reg & (~(batch_operation_busy | batch_operation_complete));
        batch_operation_complete_reg <= batch_operation_complete_reg_next;
      end else if (operation_start) begin
        if (use_batch) begin
          use_batch_reg                <= use_batch;
          batch_operation_complete_reg <= ~use_batch;
        end else begin
          invalid_batch_config         <= 1'b1;
        end
    end
    end
  end
 end
 endgenerate

  // Connect input stream to Axis Joiner per batch
  assign int_jnr_btch_s_axis_tdata  = s_axis_tdata;
  assign int_jnr_btch_s_axis_tkeep  = s_axis_tkeep;
  assign int_jnr_btch_s_axis_tvalid = s_axis_tvalid;
  assign s_axis_tready              = int_jnr_btch_s_axis_tready;
  assign int_jnr_btch_s_axis_tlast  = s_axis_tlast;
  assign int_jnr_btch_s_axis_tid    = s_axis_tid;
  assign int_jnr_btch_s_axis_tdest  = s_axis_tdest;
  assign int_jnr_btch_s_axis_tuser  = s_axis_tuser;

  // Connect batch stream from Axis Joiner per batch to Axis Packet Splitter
  assign int_aps_btch_s_axis_tdata  = int_jnr_btch_m_axis_tdata;
  assign int_aps_btch_s_axis_tkeep  = int_jnr_btch_m_axis_tkeep;
  assign int_aps_btch_s_axis_tvalid = int_jnr_btch_m_axis_tvalid;
  assign int_jnr_btch_m_axis_tready = int_aps_btch_s_axis_tready;
  assign int_aps_btch_s_axis_tlast  = int_jnr_btch_m_axis_tlast;
  assign int_aps_btch_s_axis_tid    = int_jnr_btch_m_axis_tid;
  assign int_aps_btch_s_axis_tdest  = int_jnr_btch_m_axis_tdest;
  assign int_aps_btch_s_axis_tuser  = int_jnr_btch_m_axis_tuser;

  // Connect batch stream from Axis Packet Splitter to Axis Async FIFO
  assign int_adp_btch_s_axis_tdata  = int_aps_btch_m_axis_tdata;
  assign int_adp_btch_s_axis_tkeep  = int_aps_btch_m_axis_tkeep;
  assign int_adp_btch_s_axis_tvalid = int_aps_btch_m_axis_tvalid;
  assign int_aps_btch_m_axis_tready = int_adp_btch_s_axis_tready;
  assign int_adp_btch_s_axis_tlast  = int_aps_btch_m_axis_tlast;
  assign int_adp_btch_s_axis_tid    = int_aps_btch_m_axis_tid;
  assign int_adp_btch_s_axis_tdest  = int_aps_btch_m_axis_tdest;
  assign int_adp_btch_s_axis_tuser  = int_aps_btch_m_axis_tuser;

  // Connect batch stream from Axis Async FIFO to Axis Multiplexer
  assign int_mux_btch_s_axis_tdata  = int_adp_btch_m_axis_tdata;
  assign int_mux_btch_s_axis_tkeep  = int_adp_btch_m_axis_tkeep;
  assign int_mux_btch_s_axis_tvalid = int_adp_btch_m_axis_tvalid;
  assign int_adp_btch_m_axis_tready = int_mux_btch_s_axis_tready;
  assign int_mux_btch_s_axis_tlast  = int_adp_btch_m_axis_tlast;
  assign int_mux_btch_s_axis_tid    = int_adp_btch_m_axis_tid;
  assign int_mux_btch_s_axis_tdest  = int_adp_btch_m_axis_tdest;
  assign int_mux_btch_s_axis_tuser  = int_adp_btch_m_axis_tuser;

  // Connect output stream to Axis Multiplexer
  assign m_axis_tdata               = int_mux_btch_m_axis_tdata;
  assign m_axis_tkeep               = int_mux_btch_m_axis_tkeep;
  assign m_axis_tvalid              = int_mux_btch_m_axis_tvalid;
  assign int_mux_btch_m_axis_tready = m_axis_tready;
  assign m_axis_tlast               = int_mux_btch_m_axis_tlast;
  assign m_axis_tid                 = int_mux_btch_m_axis_tid;
  assign m_axis_tdest               = int_mux_btch_m_axis_tdest;
  assign m_axis_tuser               = int_mux_btch_m_axis_tuser;

endmodule

`resetall
