`include "utils.vh"

module MemoryControlUnit #(

        /*------------------------------------------------------------------
          DATA parameters for AXI stream and BRAM interface
        ------------------------------------------------------------------*/

        // Width of AXI stream Input Data & Grid interfaces in bits
        parameter DATA_WIDTH_DATA = 16,
        // Fractional bits of input data & grid
        parameter FRACTIONAL_BITS_DATA = 12,
        // Number of Independent AXI-Stream Data Channels
        parameter DATA_CHANNELS = 1,

        // number of DATA bram banks
        parameter DATA_BANKS = 4,
        // number of elements on a single bram bank
        parameter DATA_BANK_DEPTH = 256,
        // number of address bits needed for each bank
        parameter DATA_ADDR = `LOG2(DATA_BANK_DEPTH),
        // number of DATA_WE bits needed for each bank
        parameter DATA_WE = DATA_WIDTH_DATA / 8,

        /*------------------------------------------------------------------
          Other AXI stream parameters
        ------------------------------------------------------------------*/

        // tid signal width
        parameter ID_WIDTH = 8,
        // tdest signal width
        parameter DEST_WIDTH = 8,
        // tuser signal width
        parameter USER_WIDTH = 1

    ) (

        /*------------------------------------------------------------------
            Mutli-Bank BRAM Data Input Interface
        ------------------------------------------------------------------*/

        output wire [DATA_BANKS-1:0]                    mb_bram_en,
        output wire [(DATA_BANKS*DATA_ADDR)-1:0]        mb_bram_addr,
        input wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0]   mb_bram_rddata,
        input wire [DATA_BANKS-1:0]                     mb_bram_rdstrobe,
    
        /*------------------------------------------------------------------
            AXI-Stream Data Master Interface with Multiple Streams
        ------------------------------------------------------------------*/

        output wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0] axis_data_tdata,
        output wire [DATA_CHANNELS-1:0]                 axis_data_tvalid,
        input wire [DATA_CHANNELS-1:0]                  axis_data_tready,
        output wire [DATA_CHANNELS-1:0]                 axis_data_tlast,
        output wire [DATA_CHANNELS*ID_WIDTH-1:0]        axis_data_tid,
        output wire [DATA_CHANNELS*DEST_WIDTH-1:0]      axis_data_tdest,
        output wire [DATA_CHANNELS*USER_WIDTH-1:0]      axis_data_tuser

    );
    
endmodule