
`include "utils.vh"

module MemoryUnit #(

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

    /*------------------------------------------------------------------
      GRID parameters for AXI stream and BRAM interface
    ------------------------------------------------------------------*/

    // depth of the grid bram
    parameter GRID_DEPTH = 256,
    // number of address bits needed to represent the grid bram addresses
    parameter GRID_ADDR = `LOG2(GRID_DEPTH),

    /*------------------------------------------------------------------
      SCALE streams parameters
    ------------------------------------------------------------------*/

    // Width of AXI stream Scale interface in bits
    parameter DATA_WIDTH_SCALE = 16,
    // Fractional bits of input scale
    parameter FRACTIONAL_BITS_SCALE= 12,
    // Use Common Share Channel 
    parameter SHARE_SCALE = 1,
    // Scale Channels
    parameter SCALE_CHANNELS = (SHARE_SCALE)? 1 : DATA_CHANNELS,

    /*------------------------------------------------------------------
      Other AXI stream parameters
    ------------------------------------------------------------------*/

    // tid signal width
    parameter ID_WIDTH = (ID_ENABLE) ? 8 : 1,
    // tdest signal width
    parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
    // tuser signal width
    parameter USER_WIDTH = 1

    ) (

    /*------------------------------------------------------------------
        Data Mutli-Bank BRAM Input Interface
    ------------------------------------------------------------------*/

    output wire [DATA_BANKS-1:0]                    mb_bram_data_en,
    output wire [(DATA_BANKS*DATA_ADDR)-1:0]        mb_bram_data_addr,
    input wire [(DATA_BANKS*DATA_WIDTH_DATA)-1:0]   mb_bram_data_rddata,
    input wire [DATA_BANKS-1:0]                     mb_bram_data_rdstrobe,
    
    /*------------------------------------------------------------------
        Grid BRAM Input Interface
    ------------------------------------------------------------------*/

    output wire                       bram_grid_en,
    output wire [GRID_ADDR-1:0]       bram_grid_addr,
    input wire [DATA_WIDTH_DATA-1:0]  bram_grid_rddata,
    input wire                        bram_grid_rdstrobe,
    
    /*------------------------------------------------------------------
        Scale register interface
    ------------------------------------------------------------------*/

    input wire [DATA_WIDTH_SCALE-1:0] scale_reg,

    /*------------------------------------------------------------------
        AXI-Stream Data Master Interface with Multiple Streams
    ------------------------------------------------------------------*/

    output wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0] axis_data_tdata,
    output wire [DATA_CHANNELS-1:0]                 axis_data_tvalid,
    input wire [DATA_CHANNELS-1:0]                  axis_data_tready,
    output wire [DATA_CHANNELS-1:0]                 axis_data_tlast,
    output wire [DATA_CHANNELS*ID_WIDTH-1:0]        axis_data_tid,
    output wire [DATA_CHANNELS*DEST_WIDTH-1:0]      axis_data_tdest,
    output wire [DATA_CHANNELS*USER_WIDTH-1:0]      axis_data_tuser,

    /*------------------------------------------------------------------
        AXI-Stream Data Master Interface with Multiple Streams
    ------------------------------------------------------------------*/

    output wire [DATA_CHANNELS*DATA_WIDTH_DATA-1:0] axis_grid_tdata,
    output wire [DATA_CHANNELS-1:0]                 axis_grid_tvalid,
    input wire [DATA_CHANNELS-1:0]                  axis_grid_tready,
    output wire [DATA_CHANNELS-1:0]                 axis_grid_tlast,
    output wire [DATA_CHANNELS*ID_WIDTH-1:0]        axis_grid_tid,  
    output wire [DATA_CHANNELS*DEST_WIDTH-1:0]      axis_grid_tdest,
    output wire [DATA_CHANNELS*USER_WIDTH-1:0]      axis_grid_tuser,
                                                                  
    /*------------------------------------------------------------------
        AXI-Stream Scale Master Interface with Multiple Streams
    ------------------------------------------------------------------*/

    output wire [SCALE_CHANNELS*DATA_WIDTH_SCALE-1:0] axis_scale_tdata,
    output wire [SCALE_CHANNELS-1:0]                  axis_scale_tvalid,
    input wire [SCALE_CHANNELS-1:0]                   axis_scale_tready,
    output wire [SCALE_CHANNELS-1:0]                  axis_scale_tlast,
    output wire [SCALE_CHANNELS*ID_WIDTH-1:0]         axis_scale_tid, 
    output wire [SCALE_CHANNELS*DEST_WIDTH-1:0]       axis_scale_tdest,
    output wire [SCALE_CHANNELS*USER_WIDTH-1:0]       axis_scale_tuser

  );
    
endmodule