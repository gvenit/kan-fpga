`ifndef IF_OPTIONS_H
`define IF_OPTIONS_H

// Data Interface Options DATA_IF_IS_AXIL, DATA_IF_IS_BRAM
`ifdef DATA_IF_IS_AXIL
	`ifdef DATA_IF_IS_BRAM
		`undef DATA_IF_IS_BRAM
	`endif 
`else 
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
	`ifndef BRAM_VALID_SIG_OPTION
		`define BRAM_VALID_SIG_OPTION
	`endif
`elsif GRID_IF_IS_BRAM
	`ifndef BRAM_VALID_SIG_OPTION
		`define BRAM_VALID_SIG_OPTION
	`endif
`elsif SCALE_IF_IS_BRAM
	`ifndef BRAM_VALID_SIG_OPTION
		`define BRAM_VALID_SIG_OPTION
	`endif
`else
	`undef BRAM_VALID_SIG_OPTION
`endif 


`endif