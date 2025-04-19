`ifndef IF_OPTIONS_INST_H
`define IF_OPTIONS_INST_H

// Uncomment for AXI-Lite IF for Data 
//`define DATA_IF_IS_AXIL

// Uncomment for Bram IF for Data 
 `define DATA_IF_IS_BRAM

// Uncomment for SHARE_GRID == 1
//`define GRID_IS_SHARED

// Uncomment for SHARE_SCALE == 1
//`define SCALE_IS_SHARED

// Macro fixups -- DO NOT EDIT BEYOND THIS POINT
`ifdef GRID_IS_SHARED
  `define GRID_IF_IS_AXIL
  `undef GRID_IS_SHARED
  `define GRID_IS_SHARED 1
`else
  `define GRID_IF_IS_BRAM
  `undef GRID_IS_SHARED
  `define GRID_IS_SHARED 0
`endif

`ifdef SCALE_IS_SHARED
  `define SCALE_IF_IS_AXIL
  `undef SCALE_IS_SHARED
  `define SCALE_IS_SHARED 1
`else
  `define SCALE_IF_IS_BRAM
  `undef SCALE_IS_SHARED
  `define SCALE_IS_SHARED 0
`endif

`include "IFOptions.vh"

`endif