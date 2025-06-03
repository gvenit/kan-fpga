`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream register
 */
module Sech2Lutram #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = 16,
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = 16,
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
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_16.13_16.16.txt"
) (
  input  wire                                 clk,
  input  wire                                 rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]       s_axis_tdata,
  input  wire [CHANNELS-1:0]                  s_axis_tlast,
  input  wire [CHANNELS-1:0]                  s_axis_tvalid,
  output wire [CHANNELS-1:0]                  s_axis_tready,
  input  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*RSLT_WIDTH-1:0]       m_axis_tdata,
  output wire [CHANNELS-1:0]                  m_axis_tlast,
  output wire [CHANNELS-1:0]                  m_axis_tvalid,
  input  wire [CHANNELS-1:0]                  m_axis_tready,
  output wire [CHANNELS*ID_WIDTH-1:0]         m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]       m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]       m_axis_tuser
);
  // Part of code : https://github.com/alexforencich/verilog-axis/blob/master/rtl/axis_register.v
/*

Copyright (c) 2014-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Per Channel LUTRAM Access
 genvar CHN;

 wire [DATA_WIDTH-1:0] addr_in  [0:CHANNELS-1];
 wire [RSLT_WIDTH-1:0] data_out [0:CHANNELS-1];
 
 generate 
  for (CHN = 0; CHN < CHANNELS; CHN = CHN+1) begin 
  // skid buffer, no bubble cycles
  assign addr_in[CHN] = s_axis_tdata [CHN*DATA_WIDTH +: DATA_WIDTH];

  ROM #(
    .ADDR_WIDTH     (DATA_WIDTH),
    .DATA_WIDTH     (RSLT_WIDTH),
    .ROM_DATA_PATH  (ROM_DATA_PATH)
  ) rom_inst (
    .clk            (clk),
    .addr_A         (addr_in  [CHN]),
    .en_A           (s_axis_tvalid && s_axis_tready),
    .data_A         (data_out [CHN])
  );

  // datapath registers
  reg                  s_axis_tready_reg = 1'b0;

  reg [RSLT_WIDTH-1:0] m_axis_tdata_reg  = {RSLT_WIDTH{1'b0}};
  reg                  m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
  reg                  m_axis_tlast_reg  = 1'b0;
  reg [ID_WIDTH-1:0]   m_axis_tid_reg    = {ID_WIDTH{1'b0}};
  reg [DEST_WIDTH-1:0] m_axis_tdest_reg  = {DEST_WIDTH{1'b0}};
  reg [USER_WIDTH-1:0] m_axis_tuser_reg  = {USER_WIDTH{1'b0}};

  reg [RSLT_WIDTH-1:0] temp_m_axis_tdata_reg  = {RSLT_WIDTH{1'b0}};
  reg                  temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
  reg                  temp_m_axis_tlast_reg  = 1'b0;
  reg [ID_WIDTH-1:0]   temp_m_axis_tid_reg    = {ID_WIDTH{1'b0}};
  reg [DEST_WIDTH-1:0] temp_m_axis_tdest_reg  = {DEST_WIDTH{1'b0}};
  reg [USER_WIDTH-1:0] temp_m_axis_tuser_reg  = {USER_WIDTH{1'b0}};

  // datapath control
  reg store_axis_input_to_output, store_axis_input_to_output_reg;
  reg store_axis_input_to_temp, store_axis_input_to_temp_reg;
  reg store_axis_temp_to_output, store_axis_temp_to_output_reg;

  assign s_axis_tready [CHN] = s_axis_tready_reg;

  assign m_axis_tdata  [CHN*RSLT_WIDTH +: RSLT_WIDTH] = m_axis_tdata_reg;
  assign m_axis_tvalid [CHN]                          = m_axis_tvalid_reg;
  assign m_axis_tlast  [CHN]                          = LAST_ENABLE ? m_axis_tlast_reg : 1'b1;
  assign m_axis_tid    [CHN*ID_WIDTH   +: ID_WIDTH]   = ID_ENABLE   ? m_axis_tid_reg   : {ID_WIDTH{1'b0}};
  assign m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH] = DEST_ENABLE ? m_axis_tdest_reg : {DEST_WIDTH{1'b0}};
  assign m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH] = USER_ENABLE ? m_axis_tuser_reg : {USER_WIDTH{1'b0}};

  // enable ready input next cycle if output is ready or the temp reg will not be filled on the next cycle (output reg empty or no input)
  wire s_axis_tready_early = m_axis_tready[CHN] || (!temp_m_axis_tvalid_reg && (!m_axis_tvalid_reg || !s_axis_tvalid[CHN]));

  always @* begin
    // transfer sink ready state to source
    m_axis_tvalid_next = m_axis_tvalid_reg;
    temp_m_axis_tvalid_next = temp_m_axis_tvalid_reg;

    store_axis_input_to_output = 1'b0;
    store_axis_input_to_temp = 1'b0;
    store_axis_temp_to_output = 1'b0;

    if (s_axis_tready_reg) begin
      // input is ready
      if (m_axis_tready[CHN] || !m_axis_tvalid_reg) begin
        // output is ready or currently not valid, transfer data to output
        m_axis_tvalid_next = s_axis_tvalid [CHN];
        store_axis_input_to_output = 1'b1;
      end else begin
        // output is not ready, store input in temp
        temp_m_axis_tvalid_next = s_axis_tvalid [CHN];
        store_axis_input_to_temp = 1'b1;
      end
    end else if (m_axis_tready[CHN]) begin
      // input is not ready, but output is ready
      m_axis_tvalid_next = temp_m_axis_tvalid_reg;
      temp_m_axis_tvalid_next = 1'b0;
      store_axis_temp_to_output = 1'b1;
    end
  end

  always @(posedge clk) begin
    s_axis_tready_reg <= s_axis_tready_early;
    m_axis_tvalid_reg <= m_axis_tvalid_next;
    temp_m_axis_tvalid_reg <= temp_m_axis_tvalid_next;

    // datapath
    if (store_axis_input_to_output) begin
      // m_axis_tdata_reg <= data_out      [CHN];
      m_axis_tlast_reg <= s_axis_tlast  [CHN];
      m_axis_tid_reg   <= s_axis_tid    [CHN*ID_WIDTH +: ID_WIDTH];
      m_axis_tdest_reg <= s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH];
      m_axis_tuser_reg <= s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH];
    end else if (store_axis_temp_to_output) begin
      // m_axis_tdata_reg <= temp_m_axis_tdata_reg;
      m_axis_tlast_reg <= temp_m_axis_tlast_reg;
      m_axis_tid_reg   <= temp_m_axis_tid_reg;
      m_axis_tdest_reg <= temp_m_axis_tdest_reg;
      m_axis_tuser_reg <= temp_m_axis_tuser_reg;
    end

    if (store_axis_input_to_temp) begin
      // temp_m_axis_tdata_reg <= data_out      [CHN];
      temp_m_axis_tlast_reg <= s_axis_tlast  [CHN];
      temp_m_axis_tid_reg   <= s_axis_tid    [CHN*ID_WIDTH +: ID_WIDTH];
      temp_m_axis_tdest_reg <= s_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH];
      temp_m_axis_tuser_reg <= s_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH];
    end

    store_axis_input_to_output_reg <= store_axis_input_to_output;
    store_axis_input_to_temp_reg   <= store_axis_input_to_temp;
    store_axis_temp_to_output_reg  <= store_axis_temp_to_output;

    if (rst) begin
      s_axis_tready_reg <= 1'b0;
      m_axis_tvalid_reg <= 1'b0;
      temp_m_axis_tvalid_reg <= 1'b0;
    
      store_axis_input_to_output_reg <= 1'b0;
      store_axis_input_to_temp_reg   <= 1'b0;
      store_axis_temp_to_output_reg  <= 1'b0;
    end
  end

  always @(*) begin
    if (store_axis_input_to_output_reg) begin
      m_axis_tdata_reg <= data_out [CHN];
    end else if (store_axis_temp_to_output_reg) begin
      m_axis_tdata_reg <= temp_m_axis_tdata_reg;
    end else begin
      m_axis_tdata_reg <= m_axis_tdata_reg;
    end
    if (store_axis_input_to_temp_reg) begin
      temp_m_axis_tdata_reg <= data_out [CHN];
    end else begin
      temp_m_axis_tdata_reg <= temp_m_axis_tdata_reg;
    end
  end

 end
 endgenerate

endmodule

`resetall
