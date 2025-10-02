`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AxisClamp : An Clamp wrapper that allows data processing 
 *  using the AXI-Stream Protocol.
 *
 *    The component resizes the input data to the desired output.
 *        The component supports signed / unsigned input option and
 *         
 */

`include "header_utils.vh"

module AxisClamp #(
  // Data Width of Input Data
  parameter DATA_WIDTH = 16,
  // Data Width of Output Data
  parameter RSLT_WIDTH = 16,
  // Data Width of Input Data's Fractional Bits 
  parameter DATA_FRACTIONAL_BITS = 8,
  // Data Width of Output Data's Fractional Bits
  parameter RSLT_FRACTIONAL_BITS = 8,
  // Number of Independent AXI-Stream Channels
  parameter CHANNELS = 1,
  // Propagate tlast signal
  parameter LAST_ENABLE = 1,
  // Propagate tid signal
  parameter ID_ENABLE = 0,
  // tid signal width
  parameter ID_WIDTH = 8,
  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = 8,
  // Propagate tuser signal
  parameter USER_ENABLE = 1,
  // tuser signal width
  parameter USER_WIDTH = 1,
  // Input is unsigned
  parameter UNSIGNED_DATA = 0,
  // Output is unsigned
  parameter UNSIGNED_RSLT = UNSIGNED_DATA,
  // Use infinity
  parameter USE_INFINITY = 1,
  // Register type
  // 0 to bypass, 1 for simple buffer, 2 for skid buffer
  parameter REG_TYPE = 2
) (
  input  wire [CHANNELS-1:0]                  clk,
  input  wire [CHANNELS-1:0]                  rst,

  /*
   * AXI Stream Data input
   */
  input  wire [CHANNELS*DATA_WIDTH-1:0]       s_axis_tdata,
  input  wire [CHANNELS-1:0]                  s_axis_tvalid,
  output wire [CHANNELS-1:0]                  s_axis_tready,
  input  wire [CHANNELS-1:0]                  s_axis_tlast,
  input  wire [CHANNELS*ID_WIDTH-1:0]         s_axis_tid,
  input  wire [CHANNELS*DEST_WIDTH-1:0]       s_axis_tdest,
  input  wire [CHANNELS*USER_WIDTH-1:0]       s_axis_tuser,

  /*
   * AXI Stream output
   */
  output wire [CHANNELS*RSLT_WIDTH-1:0]       m_axis_tdata,
  output wire [CHANNELS-1:0]                  m_axis_tvalid,
  input  wire [CHANNELS-1:0]                  m_axis_tready,
  output wire [CHANNELS-1:0]                  m_axis_tlast,
  output wire [CHANNELS*ID_WIDTH-1:0]         m_axis_tid,
  output wire [CHANNELS*DEST_WIDTH-1:0]       m_axis_tdest,
  output wire [CHANNELS*USER_WIDTH-1:0]       m_axis_tuser
);

 initial begin
  if (UNSIGNED_RSLT > 0 && UNSIGNED_DATA == 0) begin
    $error("Cannot have unsigned output with signed input.");
  end
 end

 localparam IN_MSB  = DATA_WIDTH + UNSIGNED_DATA - 1;
 localparam IN_LSB  = 0;

 localparam OUT_MSB = DATA_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS + RSLT_WIDTH + UNSIGNED_RSLT - 1;
 localparam OUT_LSB = DATA_FRACTIONAL_BITS - RSLT_FRACTIONAL_BITS;

 localparam MSB = `MAX( IN_MSB, OUT_MSB );
 localparam LSB = `MIN( IN_LSB, OUT_LSB );
 
 localparam EXPAND_LSB = `MAX( 0, LSB - IN_LSB );
 localparam EXPAND_MSB = `MAX( 0, MSB - IN_MSB );

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

genvar CHN;
generate
for (CHN = 0; CHN < CHANNELS; CHN = CHN+1) begin: register_genblock
  wire [DATA_WIDTH + UNSIGNED_DATA-1:0]   din_i;
  wire sign = (UNSIGNED_DATA) ? 1'b0 : din_i [DATA_WIDTH  +  UNSIGNED_DATA-1];
  wire [MSB : LSB]                        data_slice_i = {{EXPAND_MSB{sign}}, din_i, {EXPAND_LSB{1'b0}}};
  wire [RSLT_WIDTH + UNSIGNED_RSLT-1:0]   dout_i;

  if (USE_INFINITY >0 && (MSB > OUT_MSB)) begin : use_infinity_genblock
    if (UNSIGNED_RSLT) begin : use_unsigned_genblock
      wire [MSB:OUT_MSB+1] tmp = data_slice_i[MSB:OUT_MSB+1];
      wire overflow = |(data_slice_i[MSB:OUT_MSB+1]);

      assign dout_i = (overflow) ? {(RSLT_WIDTH + UNSIGNED_RSLT){1'b1}} : data_slice_i[OUT_MSB:OUT_LSB];

    end else begin : use_signed_genblock
      wire overflow = ~&(data_slice_i[MSB:OUT_MSB+1]) || |(~data_slice_i[MSB:OUT_MSB+1]);
      
      assign dout_i = (overflow) ? {sign, {(RSLT_WIDTH-1){~sign}}} : data_slice_i[OUT_MSB:OUT_LSB];

    end
  end else begin : slice_genblock
    assign dout_i = data_slice_i[OUT_MSB:OUT_LSB];
  end

  if (REG_TYPE > 1) begin : skid_buffer_genblock
    // skid buffer, no bubble cycles

    // datapath registers
    reg                   s_axis_tready_reg = 1'b0;

    reg [RSLT_WIDTH-1:0]  m_axis_tdata_reg;
    reg                   m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
    reg                   m_axis_tlast_reg  = 1'b0;
    reg [ID_WIDTH-1:0]    m_axis_tid_reg    = {ID_WIDTH{1'b0}};
    reg [DEST_WIDTH-1:0]  m_axis_tdest_reg  = {DEST_WIDTH{1'b0}};
    reg [USER_WIDTH-1:0]  m_axis_tuser_reg  = {USER_WIDTH{1'b0}};

    reg [DATA_WIDTH-1:0] temp_m_axis_tdata_reg = {DATA_WIDTH{1'b0}};
    reg                   temp_m_axis_tvalid_reg = 1'b0, temp_m_axis_tvalid_next;
    reg                   temp_m_axis_tlast_reg  = 1'b0;
    reg [ID_WIDTH-1:0]    temp_m_axis_tid_reg    = {ID_WIDTH{1'b0}};
    reg [DEST_WIDTH-1:0]  temp_m_axis_tdest_reg  = {DEST_WIDTH{1'b0}};
    reg [USER_WIDTH-1:0]  temp_m_axis_tuser_reg  = {USER_WIDTH{1'b0}};

    // datapath control
    reg store_axis_input_to_output;
    reg store_axis_input_to_temp;
    reg store_axis_temp_to_output;

    assign s_axis_tready [CHN] = s_axis_tready_reg;

    assign m_axis_tdata  [CHN*RSLT_WIDTH +: RSLT_WIDTH] = m_axis_tdata_reg;
    assign m_axis_tvalid [CHN]                          = m_axis_tvalid_reg;

    if (LAST_ENABLE) assign m_axis_tlast [CHN] = m_axis_tlast_reg ; 
    else             assign m_axis_tlast [CHN] = 1'b1;
    if (  ID_ENABLE) assign m_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]   = m_axis_tid_reg; 
    else             assign m_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]   = {ID_WIDTH{1'b0}};
    if (DEST_ENABLE) assign m_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH] = m_axis_tdest_reg; 
    else             assign m_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH] = {DEST_WIDTH{1'b0}};
    if (USER_ENABLE) assign m_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH] = m_axis_tuser_reg; 
    else             assign m_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH] = {USER_WIDTH{1'b0}};

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
          m_axis_tvalid_next = s_axis_tvalid[CHN];
          store_axis_input_to_output = 1'b1;
        end else begin
          // output is not ready, store input in temp
          temp_m_axis_tvalid_next = s_axis_tvalid[CHN];
          store_axis_input_to_temp = 1'b1;
        end
      end else if (m_axis_tready[CHN]) begin
        // input is not ready, but output is ready
        m_axis_tvalid_next = temp_m_axis_tvalid_reg;
        temp_m_axis_tvalid_next = 1'b0;
        store_axis_temp_to_output = 1'b1;
      end
    end

    always @(posedge clk[CHN]) begin
      s_axis_tready_reg <= s_axis_tready_early;
      m_axis_tvalid_reg <= m_axis_tvalid_next;
      temp_m_axis_tvalid_reg <= temp_m_axis_tvalid_next;

      if (store_axis_input_to_output || store_axis_temp_to_output) begin
        m_axis_tdata_reg <= dout_i[RSLT_WIDTH-1 : 0];
      end

      // datapath
      if (store_axis_input_to_output) begin
        m_axis_tlast_reg <= s_axis_tlast [CHN];
        m_axis_tid_reg   <= s_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]  ;
        m_axis_tdest_reg <= s_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH];
        m_axis_tuser_reg <= s_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH];
      end else if (store_axis_temp_to_output) begin
        m_axis_tlast_reg <= temp_m_axis_tlast_reg;
        m_axis_tid_reg   <= temp_m_axis_tid_reg;
        m_axis_tdest_reg <= temp_m_axis_tdest_reg;
        m_axis_tuser_reg <= temp_m_axis_tuser_reg;
      end

      if (store_axis_input_to_temp) begin
        temp_m_axis_tdata_reg <= s_axis_tdata [CHN * DATA_WIDTH +: DATA_WIDTH];
        temp_m_axis_tlast_reg <= s_axis_tlast [CHN];
        temp_m_axis_tid_reg   <= s_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]  ;
        temp_m_axis_tdest_reg <= s_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH];
        temp_m_axis_tuser_reg <= s_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH];
      end

      if (rst[CHN]) begin
        s_axis_tready_reg <= 1'b0;
        m_axis_tvalid_reg <= 1'b0;
        temp_m_axis_tvalid_reg <= 1'b0;
      end
    end

    assign din_i  = {
      {UNSIGNED_DATA{1'b0}},
      (store_axis_input_to_output) ? s_axis_tdata [CHN * DATA_WIDTH +: DATA_WIDTH] : (
      (store_axis_temp_to_output)  ? temp_m_axis_tdata_reg : {DATA_WIDTH{1'bX}}
    )};

  end else if (REG_TYPE == 1) begin : simple_register_genblock
    // simple register, inserts bubble cycles

    // datapath registers
    reg                  s_axis_tready_reg = 1'b0;

    reg [RSLT_WIDTH-1:0] m_axis_tdata_reg;
    reg                  m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
    reg                  m_axis_tlast_reg  = 1'b0;
    reg [ID_WIDTH-1:0]   m_axis_tid_reg    = {ID_WIDTH{1'b0}};
    reg [DEST_WIDTH-1:0] m_axis_tdest_reg  = {DEST_WIDTH{1'b0}};
    reg [USER_WIDTH-1:0] m_axis_tuser_reg  = {USER_WIDTH{1'b0}};

    // datapath control
    reg store_axis_input_to_output;

    assign s_axis_tready [CHN] = s_axis_tready_reg;

    assign m_axis_tdata  [CHN*RSLT_WIDTH +: RSLT_WIDTH] = m_axis_tdata_reg;
    assign m_axis_tvalid [CHN]                          = m_axis_tvalid_reg;

    if (LAST_ENABLE) assign m_axis_tlast [CHN] = m_axis_tlast_reg ; 
    else             assign m_axis_tlast [CHN] = 1'b1;
    if (ID_ENABLE  ) assign m_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]   = m_axis_tid_reg; 
    else             assign m_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]   = {ID_WIDTH{1'b0}};
    if (DEST_ENABLE) assign m_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH] = m_axis_tdest_reg; 
    else             assign m_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH] = {DEST_WIDTH{1'b0}};
    if (USER_ENABLE) assign m_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH] = m_axis_tuser_reg; 
    else             assign m_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH] = {USER_WIDTH{1'b0}};

    // enable ready input next cycle if output buffer will be empty
    wire s_axis_tready_early = !m_axis_tvalid_next;

    always @* begin
      // transfer sink ready state to source
      m_axis_tvalid_next = m_axis_tvalid_reg;

      store_axis_input_to_output = 1'b0;

      if (s_axis_tready_reg) begin
        m_axis_tvalid_next = s_axis_tvalid[CHN];
        store_axis_input_to_output = 1'b1;
      end else if (m_axis_tready[CHN]) begin
        m_axis_tvalid_next = 1'b0;
      end
    end

    always @(posedge clk[CHN]) begin
      s_axis_tready_reg <= s_axis_tready_early;
      m_axis_tvalid_reg <= m_axis_tvalid_next;

      if (store_axis_input_to_output) begin
        m_axis_tdata_reg <= dout_i[RSLT_WIDTH-1 : 0];
      end

      // datapath
      if (store_axis_input_to_output) begin
        m_axis_tlast_reg <= s_axis_tlast [CHN];
        m_axis_tid_reg   <= s_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]  ;
        m_axis_tdest_reg <= s_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH];
        m_axis_tuser_reg <= s_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH];
      end

      if (rst[CHN]) begin
        s_axis_tready_reg <= 1'b0;
        m_axis_tvalid_reg <= 1'b0;
      end
    end

    assign din_i  = (store_axis_input_to_output) ? s_axis_tdata[CHN * DATA_WIDTH +: DATA_WIDTH] : {DATA_WIDTH{1'bX}};

  end else begin: bypass_genblock
    // bypass

    assign m_axis_tdata  [CHN*RSLT_WIDTH +: RSLT_WIDTH] = dout_i[RSLT_WIDTH-1 : 0];
    assign m_axis_tvalid [CHN] = s_axis_tvalid [CHN];
    assign m_axis_tlast  [CHN] = LAST_ENABLE ? s_axis_tlast [CHN] : 1'b1;
    assign m_axis_tid    [CHN*ID_WIDTH   +: ID_WIDTH]   = ID_ENABLE   ? s_axis_tid   [CHN*ID_WIDTH   +: ID_WIDTH]   : {ID_WIDTH{1'b0}};
    assign m_axis_tdest  [CHN*DEST_WIDTH +: DEST_WIDTH] = DEST_ENABLE ? s_axis_tdest [CHN*DEST_WIDTH +: DEST_WIDTH] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser  [CHN*USER_WIDTH +: USER_WIDTH] = USER_ENABLE ? s_axis_tuser [CHN*USER_WIDTH +: USER_WIDTH] : {USER_WIDTH{1'b0}};

    assign s_axis_tready [CHN] = m_axis_tready [CHN];

    assign din_i = s_axis_tdata[CHN * DATA_WIDTH +: DATA_WIDTH];
  end

end

endgenerate

endmodule

`resetall
