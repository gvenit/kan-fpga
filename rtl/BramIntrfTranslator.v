`resetall
`timescale 1ns/1ps
`default_nettype none

/*
 * BramIntrfTranslator: This module transform the single bram interface
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

`include "utils.vh"

module BramIntrfTranslator #(
        parameter IN_WIDTH = 32,    // width of input data
        parameter OUT_WIDTH = 16,   // width of output data
        /*-------------------------------------------------------------------------------------*/
        parameter BANKS = 4,                            // number of BRAM banks
        parameter IN_WORD_DATA = IN_WIDTH / OUT_WIDTH,  // number of data packed in an input word
        /*-------------------------------------------------------------------------------------*/
        parameter OUT_DEPTH = 256,              // the depth of each BRAM bank
        parameter OUT_ADDR = `LOG2(OUT_DEPTH), // number of output address bits
        parameter OUT_WE = OUT_WIDTH / 8,       // number of output write-enable bits
        /*-------------------------------------------------------------------------------------*/
        parameter IN_DEPTH = BANKS * OUT_DEPTH, // number of total input data
        parameter IN_ADDR = `LOG2(IN_DEPTH),   // number of input address bits
        parameter IN_WE = IN_WIDTH / 8          // number of input write-enable bits
    ) (
        /*-----------------------------------------------
            Input BRAM interface
        -----------------------------------------------*/

        input wire                  en_i,
        input wire [IN_WE-1:0]      we_i,
        input wire [IN_ADDR-1:0]    addr_i,
        input wire [IN_WIDTH-1:0]   wrdata_i,
        output wire [IN_WIDTH-1:0]  rddata_i,

        /*-----------------------------------------------
            Output multi-bank BRAM interface
        -----------------------------------------------*/

        output wire [BANKS-1:0]             en_o,
        output wire [(BANKS*OUT_WE)-1:0]    we_o,
        output wire [(BANKS*OUT_ADDR)-1:0]  addr_o,
        output wire [(BANKS*OUT_WIDTH)-1:0] wrdata_o,
        input wire [(BANKS*OUT_WIDTH)-1:0]  rddata_o
    );

    /********************************
     Internal signals / local params
    ********************************/

    genvar i;
    integer j, k;

    localparam INJ_BITS = `LOG2(IN_WORD_DATA); // injected bits to the addressing to account for multiple banks
    localparam BANK_BITS = `LOG2(BANKS);       // number of bits needed to represent the number of banks
    localparam ITRL_ADDR = IN_ADDR + INJ_BITS;  // each input address gets transformed into as many addresses as data in a word each with one extra bit

    reg [INJ_BITS-1:0]  addr_injected_bits [IN_WORD_DATA-1:0];
    reg [BANK_BITS-1:0] target_banks [IN_WORD_DATA-1:0];

    reg [BANKS-1:0] en_itrl [IN_WORD_DATA-1:0]; // !!! different logic from all the others
    reg [BANKS-1:0] en_reduct;                  // value to reduce to final enabkle

    wire [OUT_WE-1:0]       we_itrl [IN_WORD_DATA-1:0];
    reg [ITRL_ADDR-1:0]     addr_itrl [IN_WORD_DATA-1:0];
    wire [OUT_WIDTH-1:0]    wrdata_itrl [IN_WORD_DATA-1:0];

    wire [OUT_WIDTH-1:0]    rddata_itrl_mbanks [BANKS-1:0];
    wire [OUT_WIDTH-1:0]    rddata_itrl [IN_WORD_DATA-1:0];

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
    always @(*) begin
        for (j = 0; j < IN_WORD_DATA; j = j + 1) begin
            addr_injected_bits[j] = j;
            addr_itrl[j][ITRL_ADDR-1:INJ_BITS] = addr_i;
            addr_itrl[j][INJ_BITS-1:0] = addr_injected_bits[j];
            target_banks[j] = addr_itrl[j][BANK_BITS-1:0];
        end
    end

    // transforming read and write data into internal representation
    generate
        for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
            assign wrdata_itrl[i] = wrdata_i[(i+1)*OUT_WIDTH-1 : i*OUT_WIDTH];
            assign rddata_i[(i+1)*OUT_WIDTH-1 : i*OUT_WIDTH] = rddata_itrl[i];
        end
    endgenerate

    // transforming write enable into internal representation
    generate
        for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
            assign we_itrl[i] = we_i[(i+1)*OUT_WE-1 : i*OUT_WE];
        end
    endgenerate

    // transforming enable into internal representation
    generate
        for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
            always @(*) begin
                en_itrl[i] = bin_to_redhot(target_banks[i]);
            end
        end
    endgenerate
    
    /********************************
     Immediate assignments:
     - Internal representation
       to output interface
    ********************************/

    // assigning output interface addr
    generate
        for (i = 0; i < BANKS; i = i + 1) begin
            assign addr_o[(i+1)*OUT_ADDR-1 : i*OUT_ADDR] = addr_itrl[i%IN_WORD_DATA][BANK_BITS +: OUT_ADDR];  // !!! Worried about the second indexing
        end
    endgenerate

    // assigning output interface write data 
    generate
        for (i = 0; i < BANKS; i = i + 1) begin
            assign wrdata_o[(i+1)*OUT_WIDTH-1 : i*OUT_WIDTH] = wrdata_itrl[i%IN_WORD_DATA];
        end
    endgenerate

    // assigning output interface read data 
    generate
        for (i = 0; i < IN_WORD_DATA; i = i + 1) begin
            assign rddata_itrl[i] = rddata_o[(target_banks[i])*OUT_WIDTH +: OUT_WIDTH];
        end
    endgenerate

    // assigning output interface write-enable
    generate
        for (i = 0; i < BANKS; i = i + 1) begin
            assign we_o[(i+1)*OUT_WE-1 : i*OUT_WE] = we_itrl[i%IN_WORD_DATA];
        end
    endgenerate

    // assigning output interface enable
    always @(*) begin
        if (en_i) begin
            en_reduct = 0;
            for (k = 0; k < IN_WORD_DATA; k = k + 1) begin
                en_reduct = (en_reduct | en_itrl[k]);
            end
        end
        else
            en_reduct = 0;
    end
    assign en_o = en_reduct;

endmodule
