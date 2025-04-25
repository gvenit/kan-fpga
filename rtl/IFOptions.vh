`ifndef IF_OPTIONS_INST_H
`define IF_OPTIONS_INST_H

// Uncomment for AXI-Lite IF for Data 
`define DATA_IF_IS_AXIL

// Uncomment for Bram IF for Data 
//  `define DATA_IF_IS_BRAM

// Uncomment for GRID_SHARE == 1
`define GRID_IS_SHARED

// Uncomment for SCALE_SHARE == 1
`define SCALE_IS_SHARED

// Macro fixups -- DO NOT EDIT BEYOND THIS POINT
`ifndef GRID_IS_SHARED
  `define GRID_IF_IS_BRAM
  `undef GRID_IS_SHARED
  `define GRID_IS_SHARED 0
`elsif GRID_IS_SHARED
  `define GRID_IF_IS_AXIL
  `undef GRID_IS_SHARED
  `define GRID_IS_SHARED 1
`endif

`ifndef SCALE_IS_SHARED
  `define SCALE_IF_IS_BRAM
  `undef SCALE_IS_SHARED
  `define SCALE_IS_SHARED 0
`elsif SCALE_IS_SHARED
  `define SCALE_IF_IS_AXIL
  `undef SCALE_IS_SHARED
  `define SCALE_IS_SHARED 1
`endif

// Data Interface Options DATA_IF_IS_AXIL, DATA_IF_IS_BRAM
`ifdef DATA_IF_IS_AXIL
  `ifdef DATA_IF_IS_BRAM
    `undef DATA_IF_IS_BRAM
  `endif 
`endif 
`ifndef DATA_IF_IS_AXIL
  `ifndef DATA_IF_IS_BRAM
      `define DATA_IF_IS_AXIL
  `endif 
`endif

// Data Interface Options GRID_IF_IS_AXIL, GRID_IF_IS_BRAM
`ifdef GRID_IF_IS_AXIL
  `ifdef GRID_IF_IS_BRAM
    `undef GRID_IF_IS_BRAM
  `endif 
`else 
  `ifndef GRID_IF_IS_BRAM
    `define GRID_IF_IS_AXIL
  `endif 
`endif

// Data Interface Options SCALE_IF_IS_AXIL, SCALE_IF_IS_BRAM
`ifdef SCALE_IF_IS_AXIL
  `ifdef SCALE_IF_IS_BRAM
    `undef SCALE_IF_IS_BRAM
  `endif
`else 
  `ifndef SCALE_IF_IS_BRAM
    `define SCALE_IF_IS_AXIL
  `endif 
`endif

`ifdef DATA_IF_IS_BRAM
  `ifndef BRAM_ACK_SIG_OPTION
    `define BRAM_ACK_SIG_OPTION
  `endif
`elsif GRID_IF_IS_BRAM
  `ifndef BRAM_ACK_SIG_OPTION
    `define BRAM_ACK_SIG_OPTION
  `endif
`elsif SCALE_IF_IS_BRAM
  `ifndef BRAM_ACK_SIG_OPTION
    `define BRAM_ACK_SIG_OPTION
  `endif
`else
  `undef BRAM_ACK_SIG_OPTION
`endif 

`endif