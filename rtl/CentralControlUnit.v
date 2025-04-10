`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * CentralControlUnit : The high level Controller for KanLayer.
 *    The module consists of an FSM that handles requests and interrupts
 *        from both the Processing System and the Programmable Logic.
 *        The core also updates the PS with the core status and 
 *        some statistics about the data processing time and latency.
 * 
 */

module CentralControlUnit #(
  `include "rtl/ControlRegisters.vh"
  // Data Width of address bus in bits
  parameter ADDR_WIDTH_DATA = 32,
  // Grid Width of address bus in bits
  parameter ADDR_WIDTH_GRID = 32,
  // Scale Width of address bus in bits
  parameter ADDR_WIDTH_SCALE = 32,
  // Width of Packet size bus in bits
  parameter PKT_SIZE_WIDTH = ADDR_WIDTH_DATA + ADDR_WIDTH_GRID -1,
  // Number of Peripherals to control
  parameter NUM_PERIPHERALS = 1
) (
  input  wire                                                       fsm_clk,
  input  wire                                                       rst,

  /*
   * Control signals -- Corresponding clock : fsm_clk
   */
  output reg                                                        operation_start,
  output reg  [ADDR_WIDTH_DATA:0]                                   data_size,
  output reg  [ADDR_WIDTH_GRID:0]                                   grid_size,
  output reg  [ADDR_WIDTH_SCALE:0]                                  scle_size,
  output reg  [PKT_SIZE_WIDTH-1:0]                                  pkt_size,
  
  /*
   * Input Interrupt signals -- Corresponding clock : fsm_clk
   */
  input  wire [NUM_PERIPHERALS-1:0]                                 peripheral_operation_busy,
  input  wire [NUM_PERIPHERALS-1:0]                                 peripheral_operation_complete,
  input  wire [NUM_PERIPHERALS-1:0]                                 peripheral_operation_error,

  /*
   * Output Interrupt signals -- Corresponding clock : fsm_clk
   */
  output reg                                                        operation_busy,
  output reg                                                        operation_complete,
  output reg                                                        operation_error,

  /*
   * AXI-Lite Control -- Corresponding clock : fsm_clk
   */
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 fsm_clk AWADDR" *)
  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN fsm_clk,READ_WRITE_MODE READ_WRITE,ADDR_WIDTH GRID_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH DATA_WIDTH_GRID" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWPROT" *)
  input  wire [2:0]             s_axil_ctrl_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWVALID" *)
  input  wire                   s_axil_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr AWREADY" *)
  output wire                   s_axil_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WDATA" *)
  input  wire [31:0]            s_axil_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WSTRB" *)
  input  wire [3:0]             s_axil_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WVALID" *)
  input  wire                   s_axil_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr WREADY" *)
  output wire                   s_axil_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BRESP" *)
  output wire [1:0]             s_axil_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BVALID" *)
  output wire                   s_axil_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr BREADY" *)
  input  wire                   s_axil_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARADDR" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARPROT" *)
  input  wire [2:0]             s_axil_ctrl_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARVALID" *)
  input  wire                   s_axil_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr ARREADY" *)
  output wire                   s_axil_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RDATA" *)
  output wire [31:0]            s_axil_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RRESP" *)
  output wire [1:0]             s_axil_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RVALID" *)
  output wire                   s_axil_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctr RREADY" *)
  input  wire                   s_axil_ctrl_rready
);

endmodule

`resetall
