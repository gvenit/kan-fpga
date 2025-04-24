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
`include "utils.vh"

module BatchedAxisPacketJoiner #(
  // Number of Channels
  parameter CHANNELS = 2,
  // Number of Channels
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Data interfaces in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter S_ID_WIDTH = (ID_ENABLE) ? 8 : 1,
  // tid signal width output
  parameter M_ID_WIDTH = ((ID_ENABLE) ? S_ID_WIDTH : 0) + `LOG2(BATCH_SIZE),
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1
) (
  input  wire                                         clk,
  input  wire                                         rst,

  /*
   * Control signals
   */
  input  wire                                         operation_start,
  input  wire [CHANNELS-1:0]                          use_channels,
  input  wire [BATCH_SIZE-1:0]                        use_batch,
  
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
  input  wire [BATCH_SIZE*CHANNELS*DATA_WIDTH-1:0]    s_axis_tdata,
  input  wire [BATCH_SIZE*CHANNELS*KEEP_WIDTH-1:0]    s_axis_tkeep,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tvalid,  
  output wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tready,
  input  wire [BATCH_SIZE*CHANNELS-1:0]               s_axis_tlast,
  input  wire [BATCH_SIZE*CHANNELS*S_ID_WIDTH-1:0]    s_axis_tid,
  input  wire [BATCH_SIZE*CHANNELS*DEST_WIDTH-1:0]    s_axis_tdest,
  input  wire [BATCH_SIZE*CHANNELS*USER_WIDTH-1:0]    s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [DATA_WIDTH-1:0]                        m_axis_tdata,
  output wire [KEEP_WIDTH-1:0]                        m_axis_tkeep,
  output wire                                         m_axis_tvalid,
  input  wire                                         m_axis_tready,
  output wire                                         m_axis_tlast,
  output wire [M_ID_WIDTH-1:0]                        m_axis_tid,
  output wire [DEST_WIDTH-1:0]                        m_axis_tdest,
  output wire [USER_WIDTH-1:0]                        m_axis_tuser
);

  wire [BATCH_SIZE*DATA_WIDTH-1:0]   batch_axis_tdata;
  wire [BATCH_SIZE*KEEP_WIDTH-1:0]   batch_axis_tkeep;
  wire [BATCH_SIZE-1:0]              batch_axis_tvalid;
  wire [BATCH_SIZE-1:0]              batch_axis_tready;
  wire [BATCH_SIZE-1:0]              batch_axis_tlast;
  wire [BATCH_SIZE*S_ID_WIDTH-1:0]   batch_axis_tid;
  wire [BATCH_SIZE*DEST_WIDTH-1:0]   batch_axis_tdest;
  wire [BATCH_SIZE*USER_WIDTH-1:0]   batch_axis_tuser;

  // Handle module statistics
  reg  [BATCH_SIZE-1:0] use_batch_reg;
  reg  [BATCH_SIZE-1:0] batch_operation_complete_reg;
  wire [BATCH_SIZE-1:0] batch_operation_complete_reg_next = batch_operation_complete | batch_operation_complete_reg;

  wire [BATCH_SIZE-1:0] batch_lock;
  wire [BATCH_SIZE-1:0] batch_interrupt;
  wire [BATCH_SIZE-1:0] batch_operation_busy;
  wire [BATCH_SIZE-1:0] batch_operation_complete;
  wire [BATCH_SIZE-1:0] batch_operation_error;
  wire [BATCH_SIZE-1:0] batch_transmission;

  wire int_external_error = 1'b0;
  wire op_done = &batch_operation_complete_reg_next;
  wire op_busy = |batch_operation_busy;

genvar batch;
generate
  for (batch = 0; batch < BATCH_SIZE; batch = batch + 1) begin
    AxisPacketJoiner #(
      // Number of Channels
      .CHANNELS(CHANNELS),
      // Width of AXI stream Data interfaces in bits
      .DATA_WIDTH(DATA_WIDTH),
      // Propagate tkeep signal
      .KEEP_ENABLE(KEEP_ENABLE),
      // tkeep signal width (words per cycle)
      .KEEP_WIDTH(KEEP_WIDTH),
      // Propagate tid signal
      .ID_ENABLE(ID_ENABLE),
      // tid signal width
      .ID_WIDTH(S_ID_WIDTH),
      // Propagate tdest signal
      .DEST_ENABLE(DEST_ENABLE),
      // tdest signal width
      .DEST_WIDTH(DEST_WIDTH),
      // Propagate tuser signal
      .USER_ENABLE(USER_ENABLE),
      // tuser signal width
      .USER_WIDTH(USER_WIDTH),
      // Allow locking module in its current state
      .ALLOW_LOCKS( BATCH_SIZE > 1)
    ) AxisPacketJoiner_i (
      .clk                (clk),
      .rst                (rst),
      .operation_start    ((BATCH_SIZE > 1 ? (op_busy ? use_batch_reg[batch] : operation_start && use_batch[batch]) : operation_start)),
      .use_channels       (use_channels),
      .lock               (batch_lock               [batch]),
      .interrupt          (interrupt),
      .operation_busy     (batch_operation_busy     [batch]),
      .operation_complete (batch_operation_complete [batch]),
      .operation_error    (batch_operation_error    [batch]),
      .transmission       (batch_transmission       [batch]),       // Active high if bus transmitted data in the current cycle
      .s_axis_tdata       (s_axis_tdata             [batch*CHANNELS*DATA_WIDTH +: CHANNELS*DATA_WIDTH]),
      .s_axis_tkeep       (s_axis_tkeep             [batch*CHANNELS*KEEP_WIDTH +: CHANNELS*KEEP_WIDTH]),
      .s_axis_tvalid      (s_axis_tvalid            [batch*CHANNELS +: CHANNELS]),
      .s_axis_tready      (s_axis_tready            [batch*CHANNELS +: CHANNELS]),
      .s_axis_tlast       (s_axis_tlast             [batch*CHANNELS +: CHANNELS]),
      .s_axis_tid         (s_axis_tid               [batch*CHANNELS*S_ID_WIDTH +: CHANNELS*S_ID_WIDTH]),
      .s_axis_tdest       (s_axis_tdest             [batch*CHANNELS*DEST_WIDTH +: CHANNELS*DEST_WIDTH]),
      .s_axis_tuser       (s_axis_tuser             [batch*CHANNELS*USER_WIDTH +: CHANNELS*USER_WIDTH]),
      .m_axis_tdata       (batch_axis_tdata         [batch*DATA_WIDTH +: DATA_WIDTH]),
      .m_axis_tkeep       (batch_axis_tkeep         [batch*KEEP_WIDTH +: KEEP_WIDTH]),
      .m_axis_tvalid      (batch_axis_tvalid        [batch]),
      .m_axis_tready      (batch_axis_tready        [batch]),
      .m_axis_tlast       (batch_axis_tlast         [batch]),
      .m_axis_tid         (batch_axis_tid           [batch*S_ID_WIDTH +: S_ID_WIDTH]),
      .m_axis_tdest       (batch_axis_tdest         [batch*DEST_WIDTH +: DEST_WIDTH]),
      .m_axis_tuser       (batch_axis_tuser         [batch*USER_WIDTH +: USER_WIDTH])
    );
  end 
 
 if (BATCH_SIZE == 1) begin
  assign m_axis_tdata  = batch_axis_tdata;
  assign m_axis_tkeep  = batch_axis_tkeep;
  assign m_axis_tvalid = batch_axis_tvalid;
  assign batch_axis_tready = m_axis_tready;
  assign m_axis_tlast  = batch_axis_tlast;
  assign m_axis_tid    = batch_axis_tid;
  assign m_axis_tdest  = batch_axis_tdest;
  assign m_axis_tuser  = batch_axis_tuser;
  
  assign batch_lock    = 0;

  always @(*) begin
    operation_busy     <= batch_operation_busy;
    operation_complete <= batch_operation_complete;
    operation_error    <= batch_operation_error;
    transmission       <= batch_transmission;
  end
 end else begin
  // Multiplex all packets to a single channel
  axis_arb_mux #(
    // Number of AXI stream inputs
    .S_COUNT(BATCH_SIZE),
    // Width of AXI stream interfaces in bits
    .DATA_WIDTH(DATA_WIDTH),
    // Propagate tkeep signal
    .KEEP_ENABLE(KEEP_ENABLE),
    // tkeep signal width (words per cycle)
    .KEEP_WIDTH(KEEP_WIDTH),
    // Propagate tid signal
    .ID_ENABLE(1),
    // input tid signal width
    .S_ID_WIDTH(S_ID_WIDTH),
    // output tid signal width
    .M_ID_WIDTH(M_ID_WIDTH),
    // Propagate tdest signal
    .DEST_ENABLE(DEST_ENABLE),
    // tdest signal width
    .DEST_WIDTH(DEST_WIDTH),
    // Propagate tuser signal
    .USER_ENABLE(USER_ENABLE),
    // tuser signal width
    .USER_WIDTH(USER_WIDTH),
    // Propagate tlast signal
    .LAST_ENABLE(1),
    // Update tid with routing information
    .UPDATE_TID(1),
    // select round robin arbitration
    .ARB_TYPE_ROUND_ROBIN(0),
    // LSB priority selection
    .ARB_LSB_HIGH_PRIORITY(1)
  ) packet_mux (
    .clk            (clk),
    .rst            (rst),
    .s_axis_tdata   (batch_axis_tdata),
    .s_axis_tkeep   (batch_axis_tkeep),
    .s_axis_tvalid  (batch_axis_tvalid),
    .s_axis_tready  (batch_axis_tready),
    .s_axis_tlast   (batch_axis_tlast),
    .s_axis_tid     (batch_axis_tid),
    .s_axis_tdest   (batch_axis_tdest),
    .s_axis_tuser   (batch_axis_tuser),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tkeep   (m_axis_tkeep),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast),
    .m_axis_tid     (m_axis_tid),
    .m_axis_tdest   (m_axis_tdest),
    .m_axis_tuser   (m_axis_tuser)
  );


  reg invalid_batch_config;

  assign batch_lock = {BATCH_SIZE{~op_done}} & batch_operation_complete_reg_next;
  assign batch_interrupt = (interrupt) || (|batch_operation_error) ? {BATCH_SIZE{1'b1}} : {BATCH_SIZE{1'b0}}; 

  always @(*) begin
    if (rst) begin
      operation_busy     <= 1'b0;
      operation_complete <= 1'b0;
      operation_error    <= 1'b0;
      transmission       <= 1'b0;
    end else begin
      operation_busy     <= 1'b0;
      operation_complete <= 1'b0;
      operation_error    <= 1'b0;
      transmission       <= m_axis_tready && m_axis_tvalid;
      if (|batch_operation_error || invalid_batch_config) begin
        operation_error    <= 1'b1;
      end else if (op_done) begin
        operation_complete <= 1'b1;
      end else if (op_busy) begin
        operation_busy     <= 1'b1;
      end
    end
  end

  always @(posedge clk ) begin
    if (rst) begin
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

endmodule

`resetall
