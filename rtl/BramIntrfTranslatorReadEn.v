`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * BramIntrfTranslatorReadEn: This module transform the single bram interface
 * into multiple ones depending on the number of banks the user whishes there are.
 *
 *  It only works for banks that are a power of 2
 *  and input words that store data that are a number of two.
 *  
 *  Furthermore the BRAM banks will have a single datum in a word
 *  no matter what (if this is byte addressible
 *  it does not mean that it is not a single datum)
 *  
 *  It is also important to note that this module
 *  was created for a specific reason:
 *  to translate the interface of a BRAM Controller IP into multiple bank BRAMs.
 *  This means that the input parameters are ususally specified
 *  by the xst tool and are passed by hand.
 *  The multibank parameters are calculated internally in the module.
 *  This also has the implication that the initial interface
 *  can be byte addressible depending on the number
 *  of write-enable bits: each bits corresponds to a byte within a word.
 *  Therefore the multi-bank BRAMs could be byte addressible too.
 *  Note that the input data words can store multiple data
 *  and THE CONVENTION is that they store them from lsb to msb. 
 *  THIS MIGHT CHANGE IN FUTURE TESTS.
 */

`include "header_utils.vh"

module BramIntrfTranslatorReadEn #(
  // Width of Input Data
  parameter DATA_WIDTH_IN = 32,
  // Width of Output Data
  parameter DATA_WIDTH_OUT = 16,
  // Number of Output BRAM banks
  parameter BANKS = 4,
  // Memory bank depth
  parameter DEPTH_PER_BANK = 256,
  // Memory Read Latency
  parameter RD_LATENCY = 1
) (
  input  wire                             clk,
  /*-----------------------------------------------
      Input BRAM interface
  -----------------------------------------------*/
  input  wire                             rden_i,
  input  wire                             wren_i,
  input  wire [STRB_WIDTH_IN-1:0]         wrstrb_i,
  input  wire [ADDR_WIDTH_IN-1:0]         addr_i,
  input  wire [DATA_WIDTH_IN-1:0]         din_i,
  output wire [DATA_WIDTH_IN-1:0]         dout_i,
  output wire                             dack_i,

  /*-----------------------------------------------
      Output multi-bank BRAM interface
  -----------------------------------------------*/
  output wire [BANKS-1:0]                 rden_o,
  output wire [BANKS-1:0]                 wren_o,
  output wire [BANKS*STRB_WIDTH_OUT-1:0]  wrstrb_o,
  output wire [BANKS*ADDR_WIDTH_OUT-1:0]  addr_o,
  output wire [BANKS*DATA_WIDTH_OUT-1:0]  din_o,
  input  wire [BANKS*DATA_WIDTH_OUT-1:0]  dout_o,
  input  wire [BANKS-1:0]                 dack_o
);
  localparam  IN_WORD_DATA = DATA_WIDTH_IN / DATA_WIDTH_OUT;  // number of data packed in an input word
  localparam  ADDR_WIDTH_OUT = `LOG2( DEPTH_PER_BANK ); // number of output address bits
  localparam  STRB_WIDTH_OUT = DATA_WIDTH_OUT / 8;       // number of output write-enable bits
  /*-------------------------------------------------------------------------------------*/
  localparam  TOTAL_DEPTH = BANKS * DEPTH_PER_BANK * DATA_WIDTH_OUT / DATA_WIDTH_IN; // number of total input data
  localparam  ADDR_WIDTH_IN = `LOG2( TOTAL_DEPTH );  // number of input address bits
  localparam  STRB_WIDTH_IN = DATA_WIDTH_IN / 8;  // number of input write-enable bits

  /********************************
    Internal signals / local params
  ********************************/

  genvar i;
  integer j, k;

  localparam INJ_BITS  = `RLOG2( IN_WORD_DATA ); // injected bits to the addressing to account for multiple banks
  localparam BANK_BITS = `LOG2( BANKS );       // number of bits needed to represent the number of banks
  localparam ITRL_ADDR = `MAX( ADDR_WIDTH_IN + INJ_BITS, BANK_BITS + ADDR_WIDTH_OUT );  // each input address gets transformed into as many addresses as data in a word each with one extra bit

  reg  [INJ_BITS-1:0]         addr_injected_bits [IN_WORD_DATA-1:0];
  reg  [BANK_BITS-1:0]        target_banks [IN_WORD_DATA-1:0];
 
  reg  [BANKS-1:0]            rden_itrl [IN_WORD_DATA-1:0]; // !!! different logic from all the others
  reg  [BANKS-1:0]            rden_reduct;                  // value to reduce to final enabkle

  reg  [BANKS-1:0]            wren_itrl [IN_WORD_DATA-1:0]; // !!! different logic from all the others
  reg  [BANKS-1:0]            wren_reduct;                  // value to reduce to final enabkle

  wire [STRB_WIDTH_OUT-1:0]   wrstrb_itrl [IN_WORD_DATA-1:0];
  reg  [ITRL_ADDR-1:0]        addr_itrl [IN_WORD_DATA-1:0];
  wire [DATA_WIDTH_OUT-1:0]   din_itrl [IN_WORD_DATA-1:0];

  wire [DATA_WIDTH_OUT-1:0]   dout_itrl_mbanks [BANKS-1:0];
  wire [DATA_WIDTH_OUT-1:0]   dout_itrl [IN_WORD_DATA-1:0];

  reg  [BANK_BITS-1:0]        target_banks_pipeline [0 : RD_LATENCY-1][IN_WORD_DATA-1:0];

  /********************************
    Function prototypes
  ********************************/

  function [BANKS-1:0] bin_to_redhot;
    input [BANK_BITS-1:0] bin;
    begin
      bin_to_redhot = 0;
      bin_to_redhot[bin] = 1'b1;
    end
  endfunction

  /********************************
    Immediate assignments:
    - Input interface
      to internal representation
  ********************************/

  // transforming input addr into internal representation
  for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
    always @(addr_i, addr_injected_bits[i], addr_itrl[i]) begin
      addr_injected_bits[i] = i;
      addr_itrl[i][ITRL_ADDR-1:INJ_BITS] = addr_i << (BANK_BITS - `RLOG2( BANKS ));
      if (INJ_BITS)
        addr_itrl[i][INJ_BITS-1:0] = addr_injected_bits[i];
      
      target_banks[i] = addr_itrl[i][BANK_BITS-1:0];
    end
  end

  assign dack_i = |dack_o;

  generate
    // transforming read and write data into internal representation
    for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
      assign din_itrl[i] = din_i[i*DATA_WIDTH_OUT +: DATA_WIDTH_OUT];
      assign dout_i[i*DATA_WIDTH_OUT +: DATA_WIDTH_OUT] = dout_itrl[i];
    end

    // transforming write enable into internal representation
    for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
      assign wrstrb_itrl[i] = wrstrb_i[i*STRB_WIDTH_OUT +: STRB_WIDTH_OUT];
    end

    // transforming enable into internal representation
    for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
      always @(target_banks[i]) begin
        rden_itrl[i] = bin_to_redhot(target_banks[i]);
        wren_itrl[i] = bin_to_redhot(target_banks[i]);
      end
    end
  
    /********************************
      Immediate assignments:
      - Internal representation
        to output interface
    ********************************/

    // assigning output interface addr
    for (i = 0; i < BANKS; i = i + 1) begin
      assign addr_o[i*ADDR_WIDTH_OUT +: ADDR_WIDTH_OUT] = $unsigned(addr_itrl[i%IN_WORD_DATA][BANK_BITS +: ADDR_WIDTH_OUT]);  // !!! Worried about the second indexing
    end

    // assigning output interface write data 
    for (i = 0; i < BANKS; i = i + 1) begin
      assign din_o[i*DATA_WIDTH_OUT +: DATA_WIDTH_OUT] = din_itrl[i%IN_WORD_DATA];
    end

    // assigning output interface read data 
    for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
      assign dout_itrl[i] = dout_o[(target_banks_pipeline[0][i])*DATA_WIDTH_OUT +: DATA_WIDTH_OUT];
    end

    // assigning output interface write-enable
    for (i = 0; i < BANKS; i = i + 1) begin
      assign wrstrb_o[i*STRB_WIDTH_OUT +: STRB_WIDTH_OUT] = wrstrb_itrl[i%IN_WORD_DATA];
    end
  endgenerate

  // assigning output interface enable
  always @(*) begin
    if (rden_i) begin
      rden_reduct = 0;
      for (k = 0; k < IN_WORD_DATA; k = k + 1) begin
        rden_reduct = (rden_reduct | rden_itrl[k]);
      end
    end else begin
      rden_reduct = 0;
    end
  end

  assign rden_o = rden_reduct;

  always @(*) begin
    if (wren_i) begin
      wren_reduct = 0;
      for (k = 0; k < IN_WORD_DATA; k = k + 1) begin
        wren_reduct = (wren_reduct | wren_itrl[k]);
      end
    end else begin
      wren_reduct = 0;
    end
  end

  assign wren_o = wren_reduct;

  always @(posedge clk ) begin
    for (k = 0; k < IN_WORD_DATA; k = k + 1) begin
      target_banks_pipeline[0][k] <= target_banks[k]; 
      for (j = 0; j < RD_LATENCY-1; j = j + 1) begin
        target_banks_pipeline[j+1][k] <= target_banks_pipeline[j][k];
      end
    end
  end

endmodule

`resetall
