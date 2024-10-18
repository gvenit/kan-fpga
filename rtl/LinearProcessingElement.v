`resetall
`timescale 1ns/1ps
`default_nettype none

module LinearProcessingElement #(
    // Number of PEs in Processing Array 
    parameter PE_NUMBER = 8,
    // Position of current PE
    parameter PE_POSITION = 0,
    // Data Width of Input Data
    parameter DATA_WIDTH_DATA = 16,
    // Fractional Bits of Input Data
    parameter FRACTIONAL_BITS_DATA = 12,
    // Data Width of Input Weights
    parameter DATA_WIDTH_WEIGHT = 16,
    // Fractional Bits of Input Weights
    parameter FRACTIONAL_BITS_WEIGHT = 12,
    // Data Width of Output Data
    parameter DATA_WIDTH_RSLT = 16,
    // Fractional Bits of Output Data
    parameter FRACTIONAL_BITS_RSLT = 12,
    // Propagate tid signal
    parameter ID_ENABLE = 0,
    // tid signal width
    parameter ID_WIDTH = 8,
    // Propagate tdest signal
    parameter DEST_ENABLE = 1,
    // tdest signal width
    parameter DEST_WIDTH = 8,
    // Propagate tuser signal
    parameter USER_ENABLE = 1,
    // tuser signal width
    parameter USER_WIDTH = 8
) (
  input                             clk,
  input                             rst,

  /*
   * AXI Stream Data input
   */
  input  [DATA_WIDTH_DATA-1:0]   s_axis_data_tdata,
  input                          s_axis_data_tvalid,
  output                         s_axis_data_tready,
  input                          s_axis_data_tlast,
  input  [ID_WIDTH-1:0]          s_axis_data_tid,
  input  [DEST_WIDTH-1:0]        s_axis_data_tdest,
  input  [USER_WIDTH-1:0]        s_axis_data_tuser,

  /*
   * AXI Stream Weight input
   */
  input  [DATA_WIDTH_WEIGHT-1:0] s_axis_weight_tdata,
  input                          s_axis_weight_tvalid,
  output                         s_axis_weight_tready,
  input                          s_axis_weight_tlast,
  input  [ID_WIDTH-1:0]          s_axis_weight_tid,
  input  [DEST_WIDTH-1:0]        s_axis_weight_tdest,
  input  [USER_WIDTH-1:0]        s_axis_weight_tuser,

  /*
   * AXI Stream Output Down
   */
  output [DATA_WIDTH_RSLT-1:0]   m_axis_down_tdata,
  output [KEEP_WIDTH-1:0]        m_axis_down_tkeep,
  output                         m_axis_down_tvalid,
  input                          m_axis_down_tready,
  output                         m_axis_down_tlast,
  output [ID_WIDTH-1:0]          m_axis_down_tid,
  output [DEST_WIDTH-1:0]        m_axis_down_tdest,
  output [USER_WIDTH-1:0]        m_axis_down_tuser,

  /*
   * AXI Stream Output Next
   */
  output [DATA_WIDTH_RSLT-1:0]   m_axis_next_tdata,
  output [KEEP_WIDTH-1:0]        m_axis_next_tkeep,
  output                         m_axis_next_tvalid,
  input                          m_axis_next_tready,
  output                         m_axis_next_tlast,
  output [ID_WIDTH-1:0]          m_axis_next_tid,
  output [DEST_WIDTH-1:0]        m_axis_next_tdest,
  output [USER_WIDTH-1:0]        m_axis_next_tuser
);

  // localparam CL_S_COUNT = $clog2(S_COUNT);

  

    
endmodule