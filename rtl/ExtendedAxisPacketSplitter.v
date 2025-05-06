`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 *  ExtendedAxisPacketSplitter : Accepts multiple input AXI-Stream and splits
 *    them to multiple packets in the corresponding output AXI-Streams.
 */

module ExtendedAxisPacketSplitter # (
  // Number of AXI-Stream channels to control
  parameter CHANNELS = 1,
  // Width of AXI stream Data interfaces in bits
  parameter DATA_WIDTH = 16,
  // Propagate tkeep signal
  parameter KEEP_ENABLE = (DATA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter KEEP_WIDTH = (KEEP_ENABLE) ? ((DATA_WIDTH + 7) / 8) : 1,
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
  // Width of Packet Size
  parameter PCKT_WIDTH = 32,
  // Raise error flag if input packet non divisible
  parameter RAISE_NON_DIVISIBLE = 1
) (
  input  wire                            clk,
  input  wire                            rst,

  /*
   * Control signals
   */
  input  wire                            operation_start,
  input  wire [PCKT_WIDTH-1:0]           pckt_size,
  
  /*
   * Input Interrupt signals
   */
  input  wire                            external_error,
  
  /*
   * Output Interrupt signals
   */
  output reg                             operation_busy,
  output reg                             operation_complete,
  output reg                             operation_error,
  output reg  [CHANNELS-1:0]             transmission,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]  s_axis_tdata,
  input  wire [CHANNELS*KEEP_WIDTH-1:0]  s_axis_tkeep,
  input  wire [CHANNELS-1:0]             s_axis_tvalid,  
  output wire [CHANNELS-1:0]             s_axis_tready,
  input  wire [CHANNELS-1:0]             s_axis_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]    s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]  s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]  s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*DATA_WIDTH-1:0]  m_axis_tdata,
  output wire [CHANNELS*KEEP_WIDTH-1:0]  m_axis_tkeep,
  output wire [CHANNELS-1:0]             m_axis_tvalid,
  input  wire [CHANNELS-1:0]             m_axis_tready,
  output wire [CHANNELS-1:0]             m_axis_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]    m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]  m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]  m_axis_tuser
);

  wire [CHANNELS-1:0] operation_busy_bus;
  wire [CHANNELS-1:0] operation_complete_bus;
  wire [CHANNELS-1:0] operation_error_bus;
  wire [CHANNELS-1:0] transmission_wire;
  wire [CHANNELS-1:0] lock_bus;

  wire int_external_error; 

  genvar CHN;

  generate
    if (CHANNELS == 1) begin : single_channel_genblock
      assign lock_bus = 0;
      assign int_external_error = external_error; 

      always @(*) begin
        operation_busy     <= operation_busy_bus[0];
        operation_complete <= operation_complete_bus[0];
        operation_error    <= operation_error_bus[0];
      end
    end else begin : multi_channel_genblock
      reg                 operation_error_reg_reduced;
      reg  [CHANNELS-1:0] operation_complete_bus_reg;
      wire [CHANNELS-1:0] operation_complete_bus_reg_next = operation_complete_bus | operation_complete_bus_reg;

      wire op_done = &operation_complete_bus_reg_next;
      wire op_busy = |operation_busy_bus;

      assign lock_bus = operation_complete_bus_reg & {CHANNELS{~op_done}};
      assign int_external_error = (&operation_error_bus) ? external_error : (operation_error_reg_reduced || external_error); 
      
      always @(*) begin
        if (rst) begin
          operation_busy     <= 1'b0;
          operation_complete <= 1'b0;
          operation_error    <= 1'b0;
        end else begin
          operation_busy     <= 1'b0;
          operation_complete <= 1'b0;
          operation_error    <= 1'b0;
          if (operation_error_reg_reduced) begin
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
          operation_complete_bus_reg <= 0;
          operation_error_reg_reduced <= 1'b0;
        end else begin
          operation_complete_bus_reg <= 0;
          operation_error_reg_reduced <= 1'b0;
          if (int_external_error) begin
          end if (|operation_error_bus) begin
            operation_error_reg_reduced <= 1'b1;
          end else if (op_done) begin
          end else if (op_busy) begin
            operation_complete_bus_reg <= operation_complete_bus_reg_next;
          end
        end
      end
    end

    for (CHN = 0; CHN < CHANNELS; CHN = CHN + 1) begin : axis_packet_splitter_genblock
      wire                   int_lock; 
      wire                   int_operation_busy;
      wire                   int_operation_complete;
      wire                   int_operation_error;
      wire                   int_transmission;
      wire [DATA_WIDTH-1:0]  int_s_axis_tdata;
      wire [KEEP_WIDTH-1:0]  int_s_axis_tkeep;
      wire                   int_s_axis_tvalid;
      wire                   int_s_axis_tready;
      wire                   int_s_axis_tlast;
      wire [ID_WIDTH-1:0]    int_s_axis_tid;
      wire [DEST_WIDTH-1:0]  int_s_axis_tdest;
      wire [USER_WIDTH-1:0]  int_s_axis_tuser;
      wire [DATA_WIDTH-1:0]  int_m_axis_tdata;
      wire [KEEP_WIDTH-1:0]  int_m_axis_tkeep;
      wire                   int_m_axis_tvalid;
      wire                   int_m_axis_tready;
      wire                   int_m_axis_tlast;
      wire [ID_WIDTH-1:0]    int_m_axis_tid;
      wire [DEST_WIDTH-1:0]  int_m_axis_tdest;
      wire [USER_WIDTH-1:0]  int_m_axis_tuser;

      AxisPacketSplitter  #(
        // Width of AXI stream Data interfaces in bits
        .DATA_WIDTH (DATA_WIDTH),
        // Propagate tkeep signal
        .KEEP_ENABLE(KEEP_ENABLE),
        // tkeep signal width (words per cycle)
        .KEEP_WIDTH(KEEP_WIDTH),
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
        // Width of Packet Size
        .PCKT_WIDTH(PCKT_WIDTH),
        // Allow locking module in its current state
        .ALLOW_LOCKS(1),
        // Raise error flag if input packet non divisible
        .RAISE_NON_DIVISIBLE(RAISE_NON_DIVISIBLE)
      ) axis_packet_splitter_inst (
        .clk                 (clk),
        .rst                 (rst),
        .operation_start     (operation_start),
        .pckt_size           (pckt_size),
        .lock                (int_lock),
        .external_error      (int_external_error),
        .operation_busy      (int_operation_busy),
        .operation_complete  (int_operation_complete),
        .operation_error     (int_operation_error),
        .transmission        (int_transmission),
        .s_axis_tdata        (int_s_axis_tdata),
        .s_axis_tkeep        (int_s_axis_tkeep),
        .s_axis_tvalid       (int_s_axis_tvalid),  
        .s_axis_tready       (int_s_axis_tready),
        .s_axis_tlast        (int_s_axis_tlast),
        .s_axis_tid          (int_s_axis_tid),
        .s_axis_tdest        (int_s_axis_tdest),
        .s_axis_tuser        (int_s_axis_tuser),
        .m_axis_tdata        (int_m_axis_tdata),
        .m_axis_tkeep        (int_m_axis_tkeep),
        .m_axis_tvalid       (int_m_axis_tvalid),
        .m_axis_tready       (int_m_axis_tready),
        .m_axis_tlast        (int_m_axis_tlast),
        .m_axis_tid          (int_m_axis_tid),
        .m_axis_tdest        (int_m_axis_tdest),
        .m_axis_tuser        (int_m_axis_tuser)
      );

      assign int_lock                     = lock_bus[CHN];
      assign operation_busy_bus[CHN]      = int_operation_busy;
      assign operation_complete_bus[CHN]  = int_operation_complete;
      assign operation_error_bus[CHN]     = int_operation_error;

      assign int_s_axis_tdata     = s_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH];
      assign int_s_axis_tkeep     = s_axis_tkeep  [CHN*KEEP_WIDTH +: KEEP_WIDTH];
      assign int_s_axis_tvalid    = s_axis_tvalid [CHN];
      assign s_axis_tready [CHN]  = int_s_axis_tready;
      assign int_s_axis_tlast     = s_axis_tlast  [CHN];
      assign int_s_axis_tid       = s_axis_tid    [CHN*ID_WIDTH +: ID_WIDTH];
      assign int_s_axis_tdest     = s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH];
      assign int_s_axis_tuser     = s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH];

      assign m_axis_tdata  [CHN*DATA_WIDTH +: DATA_WIDTH] = int_m_axis_tdata;
      assign m_axis_tkeep  [CHN*KEEP_WIDTH +: KEEP_WIDTH] = int_m_axis_tkeep;
      assign m_axis_tvalid [CHN]                          = int_m_axis_tvalid;
      assign int_m_axis_tready                            = m_axis_tready [CHN];
      assign m_axis_tlast  [CHN]                          = int_m_axis_tlast;
      assign m_axis_tid    [CHN*ID_WIDTH +: ID_WIDTH]     = int_m_axis_tid;
      assign m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH] = int_m_axis_tdest;
      assign m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH] = int_m_axis_tuser;

      always @(*) begin
        transmission[CHN] <= int_transmission;
      end
    end

  endgenerate
endmodule

`resetall
