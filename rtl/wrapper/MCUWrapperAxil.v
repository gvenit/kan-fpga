`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * MCUWrapperAxil : Wrapper for Memory Control Unit
 * 
 * MemoryControlUnit : A Memory Controller that coordinates
 *      the streaming processes for all data, grid and scale 
 *      streams for the data processor.
 * 
 *    The module consists of a global FSM and one local FSM
 *      per output stream. Each FSM may operate with different
 *      clock drivers. The global FSM is expected to work with
 *      the slowest clock of the module.
 * 
 */

module MCUWrapperAxil #(
  `include "rtl/MCUGlobalFSMParameters.vh"
  // Number of batches per run
  parameter BATCH_SIZE = 1,
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH_DATA = 16,
  // Width of AXI stream Scale interface in bits
  parameter DATA_WIDTH_SCALE = 16,
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
  parameter USER_WIDTH = 1,
  // Number of Independent AXI-Stream Data Channels per Batch
  parameter DATA_CHANNELS = 1,
  // Use Common Share Channel 
  parameter SHARE_SCALE = 1,
  // Input Scale Channels
  parameter SCALE_CHANNELS_IN = (SHARE_SCALE)? 1 : DATA_CHANNELS,
  // Output Scale Channels
  parameter SCALE_CHANNELS_OUT = (SHARE_SCALE)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Use Common Grid Channel 
  parameter SHARE_GRID = 0,
  // Input Grid Channels
  parameter GRID_CHANNELS_IN = (SHARE_GRID)? 1 : DATA_CHANNELS,
  // Output Grid Channels
  parameter GRID_CHANNELS_OUT = (SHARE_GRID)? 1 : DATA_CHANNELS*BATCH_SIZE,
  // Data Width of address bus in bits
  parameter ADDR_WIDTH_DATA = 32,
  // Grid Width of address bus in bits
  parameter ADDR_WIDTH_GRID = 32,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_SCALE = 32,
  // Data FIFO size per stream
  parameter FIFO_DEPTH_DATA = (BATCH_SIZE + DATA_CHANNELS),
  // Grid FIFO size per stream
  parameter FIFO_DEPTH_GRID = (BATCH_SIZE + DATA_CHANNELS),
  // Scale FIFO size per stream
  parameter FIFO_DEPTH_SCALE = (SHARE_SCALE) ? 0 : (BATCH_SIZE + DATA_CHANNELS)
) (
  input  wire                         fsm_clk,
  input  wire                         rst,

  /*
   * Control signals -- Corresponding clock : fsm_clk
   */
  input  wire operation_start,
  input  wire [ADDR_WIDTH_DATA:0]     data_size,
  input  wire [ADDR_WIDTH_GRID:0]     grid_size,
  input  wire [ADDR_WIDTH_SCALE:0]    scle_size,
  
  /*
   * Interrupt signals -- Corresponding clock : fsm_clk
   */
  output wire                         operation_busy,
  output wire                         operation_complete,
  output wire                         operation_error,

  /*
   * Data AXI lite Master Interface -- Corresponding clock : m_axil_data_aclk
   */
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_aclk,
  output wire [BATCH_SIZE*DATA_CHANNELS*ADDR_WIDTH_DATA-1:0]      m_axil_data_araddr,
  output wire [BATCH_SIZE*DATA_CHANNELS*3-1:0]                    m_axil_data_arprot,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_arvalid,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_arready,
  input  wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_SCALE-1:0]     m_axil_data_rdata,
  input  wire [BATCH_SIZE*DATA_CHANNELS*2-1:0]                    m_axil_data_rresp,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_rvalid,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axil_data_rready,

  /*
   * AXI Stream Data Output -- Corresponding clock : m_axis_data_aclk
   */
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_aclk,
  output wire [BATCH_SIZE*DATA_CHANNELS*DATA_WIDTH_DATA-1:0]      m_axis_data_tdata,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tvalid,
  input  wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tready,
  output wire [BATCH_SIZE*DATA_CHANNELS-1:0]                      m_axis_data_tlast,
  output wire [BATCH_SIZE*DATA_CHANNELS*ID_WIDTH-1:0]             m_axis_data_tid,
  output wire [BATCH_SIZE*DATA_CHANNELS*DEST_WIDTH-1:0]           m_axis_data_tdest,
  output wire [BATCH_SIZE*DATA_CHANNELS*USER_WIDTH-1:0]           m_axis_data_tuser,

  /*
   * Grid AXI lite Master  -- Corresponding clock : m_axil_grid_aclk
   */
  input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_aclk,
  output wire [GRID_CHANNELS_IN*ADDR_WIDTH_GRID-1:0]              m_axil_grid_araddr,
  output wire [GRID_CHANNELS_IN*3-1:0]                            m_axil_grid_arprot,
  output wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_arvalid,
  input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_arready,
  input  wire [GRID_CHANNELS_IN*DATA_WIDTH_DATA-1:0]              m_axil_grid_rdata,
  input  wire [GRID_CHANNELS_IN*2-1:0]                            m_axil_grid_rresp,
  input  wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_rvalid,
  output wire [GRID_CHANNELS_IN-1:0]                              m_axil_grid_rready,

  /*
   * AXI Stream Grid Output -- Corresponding clock : m_axis_grid_aclk
   */
  output wire [GRID_CHANNELS_OUT-1:0]                             m_axis_grid_aclk,
  output wire [GRID_CHANNELS_OUT*DATA_WIDTH_DATA-1:0]             m_axis_grid_tdata,
  output wire [GRID_CHANNELS_OUT-1:0]                             m_axis_grid_tvalid,
  input  wire [GRID_CHANNELS_OUT-1:0]                             m_axis_grid_tready,
  output wire [GRID_CHANNELS_OUT-1:0]                             m_axis_grid_tlast,
  output wire [GRID_CHANNELS_OUT*ID_WIDTH-1:0]                    m_axis_grid_tid,
  output wire [GRID_CHANNELS_OUT*DEST_WIDTH-1:0]                  m_axis_grid_tdest,
  output wire [GRID_CHANNELS_OUT*USER_WIDTH-1:0]                  m_axis_grid_tuser,

  /*
   * Scale AXI lite Master Interface -- Corresponding clock : m_axil_scle_aclk
   */
  input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_aclk,
  output wire [SCALE_CHANNELS_IN*ADDR_WIDTH_DATA-1:0]             m_axil_scle_araddr,
  output wire [SCALE_CHANNELS_IN*3-1:0]                           m_axil_scle_arprot,
  output wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_arvalid,
  input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_arready,
  input  wire [SCALE_CHANNELS_IN*DATA_WIDTH_SCALE-1:0]            m_axil_scle_rdata,
  input  wire [SCALE_CHANNELS_IN*2-1:0]                           m_axil_scle_rresp,
  input  wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_rvalid,
  output wire [SCALE_CHANNELS_IN-1:0]                             m_axil_scle_rready,
  
  /*
   * AXI Stream Scale Output -- Corresponding clock : m_axis_scle_aclk
   */
  output wire [SCALE_CHANNELS_OUT-1:0]                            m_axis_scle_aclk,
  output wire [SCALE_CHANNELS_OUT*DATA_WIDTH_SCALE-1:0]           m_axis_scle_tdata,
  output wire [SCALE_CHANNELS_OUT-1:0]                            m_axis_scle_tvalid,
  input  wire [SCALE_CHANNELS_OUT-1:0]                            m_axis_scle_tready,
  output wire [SCALE_CHANNELS_OUT-1:0]                            m_axis_scle_tlast,
  output wire [SCALE_CHANNELS_OUT*ID_WIDTH-1:0]                   m_axis_scle_tid,
  output wire [SCALE_CHANNELS_OUT*DEST_WIDTH-1:0]                 m_axis_scle_tdest,
  output wire [SCALE_CHANNELS_OUT*USER_WIDTH-1:0]                 m_axis_scle_tuser
);

 MemoryControlUnit #(
  `include "rtl/MCUGlobalFSMParametersInst.vh"
  // Number of batches per run
  .BATCH_SIZE(BATCH_SIZE),
  // Width of AXI stream Input Data & Grid interfaces in bits
  .DATA_WIDTH_DATA(DATA_WIDTH_DATA),
  // Width of AXI stream Scale interface in bits
  .DATA_WIDTH_SCALE(DATA_WIDTH_SCALE),
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
  // Number of Independent AXI-Stream Data Channels per Batch
  .DATA_CHANNELS(DATA_CHANNELS),
  // Use Common Share Channel 
  .SHARE_SCALE(SHARE_SCALE),
  // Input Scale Channels
  .SCALE_CHANNELS_IN(SCALE_CHANNELS_IN),
  // Output Scale Channels
  .SCALE_CHANNELS_OUT(SCALE_CHANNELS_OUT),
  // Use Common Grid Channel 
  .SHARE_GRID(SHARE_GRID),
  // Input Grid Channels
  .GRID_CHANNELS_IN(GRID_CHANNELS_IN),
  // Output Grid Channels
  .GRID_CHANNELS_OUT(GRID_CHANNELS_OUT),
  // Data Width of address bus in bits
  .ADDR_WIDTH_DATA(ADDR_WIDTH_DATA),
  // Grid Width of address bus in bits
  .ADDR_WIDTH_GRID(ADDR_WIDTH_GRID),
  // Scale Width of address bus in bits
  .ADDR_WIDTH_SCALE(ADDR_WIDTH_SCALE),
  // Data FIFO size per stream
  .FIFO_DEPTH_DATA(FIFO_DEPTH_DATA),
  // Grid FIFO size per stream
  .FIFO_DEPTH_GRID(FIFO_DEPTH_GRID),
  // Scale FIFO size per stream
  .FIFO_DEPTH_SCALE(FIFO_DEPTH_SCALE)
 ) mcu_inst (
  .fsm_clk(fsm_clk),
  .rst(rst),
  .operation_start(operation_start),
  .data_size(data_size),
  .grid_size(grid_size),
  .scle_size(scle_size),
  .operation_busy(operation_busy),
  .operation_complete(operation_complete),
  .operation_error(operation_error),
  .m_axil_data_aclk(m_axil_data_aclk),
  .m_axil_data_araddr(m_axil_data_araddr),
  .m_axil_data_arprot(m_axil_data_arprot),
  .m_axil_data_arvalid(m_axil_data_arvalid),
  .m_axil_data_arready(m_axil_data_arready),
  .m_axil_data_rdata(m_axil_data_rdata),
  .m_axil_data_rresp(m_axil_data_rresp),
  .m_axil_data_rvalid(m_axil_data_rvalid),
  .m_axil_data_rready(m_axil_data_rready),
  .m_axis_data_aclk(m_axis_data_aclk),
  .m_axis_data_tdata(m_axis_data_tdata),
  .m_axis_data_tvalid(m_axis_data_tvalid),
  .m_axis_data_tready(m_axis_data_tready),
  .m_axis_data_tlast(m_axis_data_tlast),
  .m_axis_data_tid(m_axis_data_tid),
  .m_axis_data_tdest(m_axis_data_tdest),
  .m_axis_data_tuser(m_axis_data_tuser),
  .m_axil_grid_aclk(m_axil_grid_aclk),
  .m_axil_grid_araddr(m_axil_grid_araddr),
  .m_axil_grid_arprot(m_axil_grid_arprot),
  .m_axil_grid_arvalid(m_axil_grid_arvalid),
  .m_axil_grid_arready(m_axil_grid_arready),
  .m_axil_grid_rdata(m_axil_grid_rdata),
  .m_axil_grid_rresp(m_axil_grid_rresp),
  .m_axil_grid_rvalid(m_axil_grid_rvalid),
  .m_axil_grid_rready(m_axil_grid_rready),
  .m_axis_grid_aclk(m_axis_grid_aclk),
  .m_axis_grid_tdata(m_axis_grid_tdata),
  .m_axis_grid_tvalid(m_axis_grid_tvalid),
  .m_axis_grid_tready(m_axis_grid_tready),
  .m_axis_grid_tlast(m_axis_grid_tlast),
  .m_axis_grid_tid(m_axis_grid_tid),
  .m_axis_grid_tdest(m_axis_grid_tdest),
  .m_axis_grid_tuser(m_axis_grid_tuser),
  .m_axil_scle_aclk(m_axil_scle_aclk),
  .m_axil_scle_araddr(m_axil_scle_araddr),
  .m_axil_scle_arprot(m_axil_scle_arprot),
  .m_axil_scle_arvalid(m_axil_scle_arvalid),
  .m_axil_scle_arready(m_axil_scle_arready),
  .m_axil_scle_rdata(m_axil_scle_rdata),
  .m_axil_scle_rresp(m_axil_scle_rresp),
  .m_axil_scle_rvalid(m_axil_scle_rvalid),
  .m_axil_scle_rready(m_axil_scle_rready),
  .m_axis_scle_aclk(m_axis_scle_aclk),
  .m_axis_scle_tdata(m_axis_scle_tdata),
  .m_axis_scle_tvalid(m_axis_scle_tvalid),
  .m_axis_scle_tready(m_axis_scle_tready),
  .m_axis_scle_tlast(m_axis_scle_tlast),
  .m_axis_scle_tid(m_axis_scle_tid),
  .m_axis_scle_tdest(m_axis_scle_tdest),
  .m_axis_scle_tuser(m_axis_scle_tuser)
);

endmodule

`resetall
