#!/usr/bin/env python
"""
Generates an KanLayer wrapper with the specified batch size and other system parameters.
"""
import argparse
import os
from jinja2 import Template

TOP_DIR = os.path.dirname(  # .../kan-fpga
    os.path.dirname(
        os.path.dirname(
            os.path.abspath(__file__)
        )
    )
)
print(TOP_DIR)

def main():
    parser = argparse.ArgumentParser(description=__doc__.strip())
    parser.add_argument('-b', '--batch-size',  type=int, default=1, help="batch size", dest='batch_size')
    parser.add_argument('--dma-width',  type=int, default=64, help="DMA Data Width", dest='dma_width')
    parser.add_argument('--ctrl-addr',  type=int, default=13, help="Control Address Width", dest='ctrl_addr')
    
    parser.add_argument('--data-width',     type=int, default=16, help="Data & Grid Width", dest='data_width')
    parser.add_argument('--data-frac-bits', type=int, default=12, help="Data & Grid Fractional Bits", dest='data_fbits')
    parser.add_argument('--data-chn',       type=int, default=4, help="Data Channels", dest='data_chn')
    parser.add_argument('--data-depth',     type=int, default=1024, help="Data Depth", dest='data_depth')
    parser.add_argument('--data-axil',      action='store_true', dest='data_axil')
    parser.add_argument('--data-bram',      action='store_true', dest='data_bram')
    
    parser.add_argument('--grid-depth', type=int, default=16, help="Grid Depth", dest='grid_depth')
    parser.add_argument('--grid-share', action='store_true', dest='grid_share')
    parser.add_argument('--grid-axil',  action='store_true', dest='grid_axil')
    parser.add_argument('--grid-bram',  action='store_true', dest='grid_bram')
    
    parser.add_argument('--scale-width',     '--scle-width',     type=int, default=16, help="Scale Width", dest='scle_width')
    parser.add_argument('--scale-frac-bits', '--scle-frac-bits', type=int, default=12, help="Scale Fractional Bits", dest='scle_fbits')
    parser.add_argument('--scale-depth',     '--scle-depth',     type=int, default=16, help="Scale Depth", dest='scle_depth')
    parser.add_argument('--scale-share',     '--scle-share',     action='store_true', dest='scle_share')
    parser.add_argument('--scale-axil',      '--scle-axil',      action='store_true', dest='scle_axil')
    parser.add_argument('--scale-bram',      '--scle-bram',      action='store_true', dest='scle_bram')
    
    parser.add_argument('--weight-width',     '--wght-width',     type=int, default=16, help="Weight Width", dest='wght_width')
    parser.add_argument('--weight-frac-bits', '--wght-frac-bits', type=int, default=12, help="Weight Fractional Bits", dest='wght_fbits')
    parser.add_argument('--weight-depth',     '--wght-depth',     type=int, default=16, help="Weight Depth", dest='wght_depth')
    
    parser.add_argument('--scaled-diff-width',     '--sdff-width',     type=int, default=16, help="Scaled Difference Width", dest='sdff_width')
    parser.add_argument('--scaled-diff-frac-bits', '--sdff-frac-bits', type=int, default=13, help="Scaled Difference Fractional Bits", dest='sdff_fbits')
    
    parser.add_argument('--activation-function-width',     '--actf-width',     type=int, default=16, help="Activation Function Width", dest='actf_width')
    parser.add_argument('--activation-function-frac-bits', '--actf-frac-bits', type=int, default=16, help="Activation Function Fractional Bits", dest='actf_fbits')
    
    parser.add_argument('--result-chn',       '--rslt-chn',       type=int, default=1, help="Result Channels", dest='rslt_chn')
    parser.add_argument('--result-width',     '--rslt-width',     type=int, default=16, help="Result Width", dest='rslt_width')
    parser.add_argument('--result-frac-bits', '--rslt-frac-bits', type=int, default=12, help="Result Fractional Bits", dest='rslt_fbits')
    parser.add_argument('--result-depth',     '--rslt-depth',     type=int, default=8, help="Result Depth", dest='rslt_depth')
    
    parser.add_argument('--bram-width', type=int, default=32, help="batch size", dest='bram_width')
    parser.add_argument('--bram-we',    type=int, default=4, help="batch size",  dest='bram_we')
    parser.add_argument('--bram-addr',  type=int, default=13, help="batch size", dest='bram_addr')
    
    parser.add_argument('-n', '--name',   type=str, help="module name")
    parser.add_argument('-o', '--output', type=str, help="output file name")

    args = parser.parse_args()
    
    # Resolve Arguments
    if (not args.grid_share) :
        args.grid_axil = False
        args.grid_bram = True
    elif not (args.grid_axil or args.grid_bram) :
        args.grid_axil = True
      
    if (not args.scle_share) :
        args.scle_axil = False
        args.scle_bram = True
    elif not (args.scle_axil or args.scle_bram) :
        args.scle_axil = True
        
    if (args.data_axil and args.data_chn != 1) :
        raise ValueError('Cannot use Axi-Lite with multiple data channels.')
    elif (args.data_chn > 1) :
        args.data_axil = False
        args.data_bram = True
    elif (args.data_chn == 1) and not (args.data_axil or args.data_bram):
        args.data_axil = True
        args.data_adata_bramxil = False
        
        print(args.data_chn, args.data_bram)
    
    try:
        generate(**args.__dict__)
    except IOError as ex:
        print(ex)
        exit(1)


def generate(batch_size=4, name=None, output=None, **kwargs):
    n = batch_size

    if name is None:
        name = "KanLayerInstWrapper{0}".format(n)

    if output is None:
        output = os.path.join(TOP_DIR, 'rtl', 'wrapper', name + ".v")
        
    print("Generating {0} port AXI stream broadcast wrapper {1}...".format(n, name))

    cn = (n-1).bit_length()
    
    # Produce Rom File
    exec_str = ' '.join([
        'python',
        os.path.join(TOP_DIR,'auxiliary/Sech2Lutram.py'),
        '-I', f'uint{kwargs["sdff_width"]}',
        '-i', f'{kwargs["sdff_fbits"]}',
        '-O', f'uint{kwargs["actf_width"]}',
        '-o', f'{kwargs["actf_fbits"]}',
        '-N'
    ])
    print(exec_str)
    os.system(exec_str)
        
    t = Template(u"""
`resetall
`timescale 1ns/1ps
`default_nettype none

`ifdef IF_OPTIONS_INST_H
`undef IF_OPTIONS_INST_H
`endif

{% if data_axil %}`define DATA_IF_IS_AXIL{% elif data_bram %}`define DATA_IF_IS_BRAM{% endif %}
{% if grid_share %}`define GRID_IS_SHARED{% endif %}
{% if scle_share %}`define SCALE_IS_SHARED{% endif %}

`include "header_utils.vh"
`include "header_IFOptions.vh"

module {{name}} #(
  /*------------------------------------------------------------------
    Genreal parameters of the architecture
  ------------------------------------------------------------------*/
  
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = {{n}},

  /*------------------------------------------------------------------
    DMA parameters
  ------------------------------------------------------------------*/
  
  // Width of DMA streams
  parameter DMA_WIDTH = {{dma_width}},
  // Propagate tkeep signal
  parameter DMA_KEEP_ENABLE = (DMA_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter DMA_KEEP_WIDTH = (DMA_KEEP_ENABLE) ? ((DMA_WIDTH + 7) / 8) : 1,

  /*------------------------------------------------------------------
    AXI_Lite controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter AXIL_WIDTH = 32,
  parameter AXIL_STRB_WIDTH = (AXIL_WIDTH / 8),

  /*------------------------------------------------------------------
    Bram controller mem interface parameters
  ------------------------------------------------------------------*/

  parameter BRAM_CTRL_WIDTH = {{bram_width}},
  parameter BRAM_CTRL_WE = {{bram_we}},
  parameter BRAM_CTRL_ADDR = {{bram_addr}},

  /*------------------------------------------------------------------
    DATA parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Width of AXI stream Input Data & Grid interfaces in bits
  parameter DATA_WIDTH = {{data_width}},
  // Fractional bits of input data & grid
  parameter DATA_FRACTIONAL_BITS = {{data_fbits}},
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = {{data_chn}},
  // Total memory size allocated for Data in words
  parameter DATA_DEPTH = {{data_depth}},
{% if data_axil %}
  // Data Strobe Width
  parameter DATA_STRB_WIDTH = DATA_WIDTH / 8,
  // Data Address Width
  parameter DATA_ADDR = `LOG2( DATA_DEPTH * DATA_STRB_WIDTH ),
{% endif %}

  /*------------------------------------------------------------------
    GRID parameters for AXI stream and BRAM interface
  ------------------------------------------------------------------*/

  // Use Common Grid Channel 
  parameter GRID_SHARE = {{ grid_share | int }}, 
  // Total memory size allocated for Grid in words
  parameter GRID_DEPTH = {{grid_depth}},
{% if grid_axil %}
  // Grid Address Width
  parameter GRID_ADDR = `LOG2( GRID_DEPTH * DATA_STRB_WIDTH ),
{% endif %}

  /*------------------------------------------------------------------
    SCALE streams parameters
  ------------------------------------------------------------------*/

  // Use Common Share Channel 
  parameter SCALE_SHARE = {{ scle_share | int }},
  // Width of AXI stream Scale interface in bits
  parameter SCALE_WIDTH = {{scle_width}},
  // Fractional bits of input scle
  parameter SCALE_FRACTIONAL_BITS = {{scle_fbits}},
  // Total memory size allocated for Data in words
  parameter SCALE_DEPTH = {{scle_depth}},

  /*------------------------------------------------------------------
    RESULT / OUTPUT parameters
  ------------------------------------------------------------------*/

  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = {{rslt_chn}},
  // Width of AXI stream Output Data interface in bits
  parameter RSLT_WIDTH = {{rslt_width}},
  // Fractional bits of output data
  parameter RSLT_FRACTIONAL_BITS = {{rslt_fbits}},
  // tkeep signal width (words per cycle)
  parameter RSLT_KEEP_WIDTH = ((RSLT_WIDTH + 7) / 8),
  // FIFO Depth for results
  parameter RSLT_FIFO_DEPTH = {{rslt_depth}},
{% if scle_axil %}
  // Scale Strobe Width
  parameter SCALE_STRB_WIDTH = SCALE_WIDTH / 8,
  // Scale Address Width
  parameter SCALE_ADDR = `MAX( `LOG2( SCALE_DEPTH * SCALE_STRB_WIDTH ), SCALE_STRB_WIDTH),
{% endif %}

  /*------------------------------------------------------------------
    WEIGHT streams parameters
  ------------------------------------------------------------------*/

  // Width of input wght word
  parameter WEIGHT_WIDTH = {{wght_width}},
  // Fractional bits of wght data
  parameter WEIGHT_FRACTIONAL_BITS = {{wght_fbits}},
  // Propagate tkeep signal
  parameter WEIGHT_KEEP_ENABLE = (WEIGHT_WIDTH > 8),
  // tkeep signal width (words per cycle)
  parameter WEIGHT_KEEP_WIDTH = (WEIGHT_KEEP_ENABLE) ? ((WEIGHT_WIDTH + 7) / 8) : 1,
  // FIFO Depth for WEIGHT parameters
  parameter WEIGHT_FIFO_DEPTH = {{wght_depth}},

  /*------------------------------------------------------------------
    SCALED_DIFF parameters
  ------------------------------------------------------------------*/

  // Width of Scaled Data in bits
  parameter SCALED_DIFF_WIDTH = {{sdff_width}},
  // Fractional bits of Scaled Data
  parameter SCALED_DIFF_FRACTIONAL_BITS = {{sdff_fbits}},

  /*------------------------------------------------------------------
    ACT parameters
  ------------------------------------------------------------------*/

  // Width of Activation Function Data in bits
  parameter ACT_WIDTH = {{actf_width}},
  // Fractional bits of Activation Function Data
  parameter ACT_FRACTIONAL_BITS = {{actf_fbits}},

  /*------------------------------------------------------------------
    Various AXI parameters
  ------------------------------------------------------------------*/

  // Propagate tid signal
  parameter WEIGHT_ID_ENABLE = 0,
  // tid signal width
  parameter WEIGHT_ID_WIDTH = (WEIGHT_ID_ENABLE) ? 8 : 1,

  // Propagate tid signal
  parameter RSLT_ID_ENABLE = 1,
  // tid signal width
  parameter RSLT_ID_WIDTH = (RSLT_ID_ENABLE) ? `LOG2(BATCH_SIZE) : 1,
  // tid value
  parameter ID_OUTPUT = 0,

  // Propagate tdest signal
  parameter DEST_ENABLE = 0,
  // tdest signal width
  parameter DEST_WIDTH = (DEST_ENABLE) ? 8 : 1,
  // tdest value
  parameter DEST_OUTPUT = 0,

  // Propagate tuser signal
  parameter USER_ENABLE = 0,
  // tuser signal width
  parameter USER_WIDTH = (USER_ENABLE) ? 8 : 1,
  // tuser value
  parameter USER_OUTPUT = 0,

  /*------------------------------------------------------------------
    Miscalleneous parameters
  ------------------------------------------------------------------*/

  // Add Buffer on Output Streams
  parameter EXTRA_CYCLE = 0,
  // Central Control Address Width
  parameter CTRL_ADDR = {{ctrl_addr}}, // 13 

  /*------------------------------------------------------------------
    Input / Output file constants
  ------------------------------------------------------------------*/

  // Path to ROM Data
  parameter ROM_DATA_PATH = "../data/Sech2Lutram_n_{{sdff_width}}.{{sdff_fbits}}_{{actf_width}}.{{actf_fbits}}.txt"
) (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 fsm_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_ctrl, ASSOCIATED_RESET fsm_rst" *)
  input  wire                                       fsm_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 fsm_rst RST" *)
   (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       fsm_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_RESET core_rst" *)
  input  wire                                       core_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  output wire                                       core_rst,

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 dma_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis_wght:m_axis_rslt, ASSOCIATED_RESET dma_rst" *)
  input  wire                                       dma_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 dma_rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       dma_rst,

  /*------------------------------------------------------------------
      Generated Interrupts & Resets
  ------------------------------------------------------------------*/
  output wire                                       operation_busy,
  output wire                                       operation_complete,
  output wire                                       operation_error,
  output wire                                       locked,
  output wire                                       pl2ps_intr,

  /*------------------------------------------------------------------
      BRAM Data Control interface
  ------------------------------------------------------------------*/
{% if data_axil %}{%- for p in range(n) %}
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s{{'%02d'%p}}_axil_data_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s{{'%02d'%p}}_axil_data, ASSOCIATED_RESET s{{'%02d'%p}}_axil_data_areset" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s{{'%02d'%p}}_axil_data_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [DATA_ADDR-1:0]                       s{{'%02d'%p}}_axil_data_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data AWPROT" *)
  input  wire [2:0]                                 s{{'%02d'%p}}_axil_data_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data AWVALID" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data AWREADY" *)
  output wire                                       s{{'%02d'%p}}_axil_data_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data WDATA" *)
  input  wire [AXIL_WIDTH-1:0]                      s{{'%02d'%p}}_axil_data_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data WSTRB" *)
  input  wire [AXIL_STRB_WIDTH-1:0]                 s{{'%02d'%p}}_axil_data_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data WVALID" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data WREADY" *)
  output wire                                       s{{'%02d'%p}}_axil_data_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data BRESP" *)
  output wire [1:0]                                 s{{'%02d'%p}}_axil_data_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data BVALID" *)
  output wire                                       s{{'%02d'%p}}_axil_data_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data BREADY" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data ARADDR" *)
  input  wire [DATA_ADDR-1:0]                       s{{'%02d'%p}}_axil_data_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data ARPROT" *)
  input  wire [2:0]                                 s{{'%02d'%p}}_axil_data_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data ARVALID" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data ARREADY" *)
  output wire                                       s{{'%02d'%p}}_axil_data_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data RDATA" *)
  output wire [AXIL_WIDTH-1:0]                      s{{'%02d'%p}}_axil_data_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data RRESP" *)
  output wire [1:0]                                 s{{'%02d'%p}}_axil_data_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data RVALID" *)
  output wire                                       s{{'%02d'%p}}_axil_data_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s{{'%02d'%p}}_axil_data RREADY" *)
  input  wire                                       s{{'%02d'%p}}_axil_data_rready,
{% endfor -%}{% endif %}
{% if data_bram %}{%- for p in range(n) %}
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF bram{{'%02d'%p}}_ctrl_data, ASSOCIATED_RESET bram{{'%02d'%p}}_ctrl_data_rst" *)
  input  wire                                       bram{{'%02d'%p}}_ctrl_data_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data RST" *)
  input  wire                                       bram{{'%02d'%p}}_ctrl_data_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data EN" *)
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                                       bram{{'%02d'%p}}_ctrl_data_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data WE" *)
  input  wire [BRAM_CTRL_WE-1:0]                    bram{{'%02d'%p}}_ctrl_data_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]                  bram{{'%02d'%p}}_ctrl_data_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0]                 bram{{'%02d'%p}}_ctrl_data_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram{{'%02d'%p}}_ctrl_data DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0]                 bram{{'%02d'%p}}_ctrl_data_dout,
{% endfor -%}{% endif %}

  /*------------------------------------------------------------------
      BRAM Grid Control interface
  ------------------------------------------------------------------*/
{% if grid_axil %}
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_grid_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_grid, ASSOCIATED_RESET s_axil_grid_areset" *)
  input  wire                                       s_axil_grid_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_grid_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       s_axil_grid_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [GRID_ADDR-1:0]                       s_axil_grid_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWPROT" *)
  input  wire [2:0]                                 s_axil_grid_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWVALID" *)
  input  wire                                       s_axil_grid_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid AWREADY" *)
  output wire                                       s_axil_grid_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WDATA" *)
  input  wire [AXIL_WIDTH-1:0]                      s_axil_grid_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WSTRB" *)
  input  wire [AXIL_STRB_WIDTH-1:0]                 s_axil_grid_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WVALID" *)
  input  wire                                       s_axil_grid_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid WREADY" *)
  output wire                                       s_axil_grid_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BRESP" *)
  output wire [1:0]                                 s_axil_grid_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BVALID" *)
  output wire                                       s_axil_grid_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid BREADY" *)
  input  wire                                       s_axil_grid_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARADDR" *)
  input  wire [GRID_ADDR-1:0]                       s_axil_grid_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARPROT" *)
  input  wire [2:0]                                 s_axil_grid_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARVALID" *)
  input  wire                                       s_axil_grid_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid ARREADY" *)
  output wire                                       s_axil_grid_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RDATA" *)
  output wire [AXIL_WIDTH-1:0]                      s_axil_grid_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RRESP" *)
  output wire [1:0]                                 s_axil_grid_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RVALID" *)
  output wire                                       s_axil_grid_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_grid RREADY" *)
  input  wire                                       s_axil_grid_rready,
{% endif %}
{% if grid_bram %}
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF bram_ctrl_grid, ASSOCIATED_RESET bram_ctrl_grid_rst" *)
  input  wire                                       bram_ctrl_grid_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid RST" *)
  input  wire                                       bram_ctrl_grid_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                                       bram_ctrl_grid_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid WE" *)
  input  wire [BRAM_CTRL_WE-1:0]                    bram_ctrl_grid_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]                  bram_ctrl_grid_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_grid_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_grid DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_grid_dout,
{% endif %}

    /*------------------------------------------------------------------
        BRAM Scale Control interface
    ------------------------------------------------------------------*/

{% if scle_axil %}
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axil_scle_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axil_scle, ASSOCIATED_RESET s_axil_scle_areset" *)
  input  wire                                       s_axil_scle_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axil_scle_areset RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input  wire                                       s_axil_scle_areset,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWADDR" *)
    (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE" *)
  input  wire [SCALE_ADDR-1:0]                      s_axil_scle_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWPROT" *)
  input  wire [2:0]                                 s_axil_scle_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWVALID" *)
  input  wire                                       s_axil_scle_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle AWREADY" *)
  output wire                                       s_axil_scle_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WDATA" *)
  input  wire [AXIL_WIDTH-1:0]                      s_axil_scle_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WSTRB" *)
  input  wire [AXIL_STRB_WIDTH-1:0]                 s_axil_scle_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WVALID" *)
  input  wire                                       s_axil_scle_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle WREADY" *)
  output wire                                       s_axil_scle_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BRESP" *)
  output wire [1:0]                                 s_axil_scle_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BVALID" *)
  output wire                                       s_axil_scle_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle BREADY" *)
  input  wire                                       s_axil_scle_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARADDR" *)
  input  wire [SCALE_ADDR-1:0]                      s_axil_scle_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARPROT" *)
  input  wire [2:0]                                 s_axil_scle_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARVALID" *)
  input  wire                                       s_axil_scle_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle ARREADY" *)
  output wire                                       s_axil_scle_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RDATA" *)
  output wire [AXIL_WIDTH-1:0]                      s_axil_scle_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RRESP" *)
  output wire [1:0]                                 s_axil_scle_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RVALID" *)
  output wire                                       s_axil_scle_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_scle RREADY" *)
  input  wire                                       s_axil_scle_rready,
{% endif %}
{% if scle_bram %}
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF bram_ctrl_scle, ASSOCIATED_RESET bram_ctrl_scle_rst" *)
  input  wire                                       bram_ctrl_scle_clk,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle RST" *)
  input  wire                                       bram_ctrl_scle_rst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle EN" *)
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL , READ_WRITE_MODE READ_WRITE" *)
  input  wire                                       bram_ctrl_scle_en,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle WE" *)
  input  wire [BRAM_CTRL_WE-1:0]                    bram_ctrl_scle_we,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle ADDR" *)
  input  wire [BRAM_CTRL_ADDR-1:0]                  bram_ctrl_scle_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DIN" *)
  input  wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_scle_din,
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 bram_ctrl_scle DOUT" *)
  output wire [BRAM_CTRL_WIDTH-1:0]                 bram_ctrl_scle_dout,
{% endif %}
 
  /*------------------------------------------------------------------
      AXI-Lite Control Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWADDR" *)
  (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,PROTOCOL AXI4LITE,DATA_WIDTH 32" *)
  input  wire [CTRL_ADDR-1:0]                       s_axil_ctrl_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWPROT" *)
  input  wire [2:0]                                 s_axil_ctrl_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWVALID" *)
  input  wire                                       s_axil_ctrl_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl AWREADY" *)
  output wire                                       s_axil_ctrl_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WDATA" *)
  input  wire [31:0]                                s_axil_ctrl_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WSTRB" *)
  input  wire [3:0]                                 s_axil_ctrl_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WVALID" *)
  input  wire                                       s_axil_ctrl_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl WREADY" *)
  output wire                                       s_axil_ctrl_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BRESP" *)
  output wire [1:0]                                 s_axil_ctrl_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BVALID" *)
  output wire                                       s_axil_ctrl_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl BREADY" *)
  input  wire                                       s_axil_ctrl_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARADDR" *)
  input  wire [CTRL_ADDR-1:0]                       s_axil_ctrl_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARPROT" *)
  input  wire [2:0]                                 s_axil_ctrl_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARVALID" *)
  input  wire                                       s_axil_ctrl_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl ARREADY" *)
  output wire                                       s_axil_ctrl_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RDATA" *)
  output wire [31:0]                                s_axil_ctrl_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RRESP" *)
  output wire [1:0]                                 s_axil_ctrl_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RVALID" *)
  output wire                                       s_axil_ctrl_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil_ctrl RREADY" *)
  input  wire                                       s_axil_ctrl_rready,

  /*------------------------------------------------------------------
      AXI-Stream Weight Slave interface
  ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDATA" *)
    (* X_INTERFACE_PARAMETER = "HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  input  wire [DMA_WIDTH-1:0]                       s_axis_wght_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TKEEP" *)
  input  wire [DMA_KEEP_WIDTH-1:0]                  s_axis_wght_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TVALID" *)
  input  wire                                       s_axis_wght_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TREADY" *)
  output wire                                       s_axis_wght_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TLAST" *)
  input  wire                                       s_axis_wght_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TID" *)
  input  wire [WEIGHT_ID_WIDTH-1:0]                 s_axis_wght_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TDEST" *)
  input  wire [DEST_WIDTH-1:0]                      s_axis_wght_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis_wght TUSER" *)
  input  wire [USER_WIDTH-1:0]                      s_axis_wght_tuser,

    /*------------------------------------------------------------------
        AXI-Stream Results / Output Master interface
    ------------------------------------------------------------------*/

  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDATA" *)
    (* X_INTERFACE_PARAMETER = "HAS_TLAST 1,HAS_TSTRB 0,HAS_TREADY 1" *)
  output wire [DMA_WIDTH-1:0]                       m_axis_rslt_tdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TKEEP" *)
  output wire [DMA_KEEP_WIDTH-1:0]                  m_axis_rslt_tkeep,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TVALID" *)
  output wire                                       m_axis_rslt_tvalid,  
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TREADY" *)
  input  wire                                       m_axis_rslt_tready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TLAST" *)
  output wire                                       m_axis_rslt_tlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TID" *)
  output wire [RSLT_ID_WIDTH-1:0]                   m_axis_rslt_tid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TDEST" *)
  output wire [DEST_WIDTH-1:0]                      m_axis_rslt_tdest,
  (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis_rslt TUSER" *)
  output wire [USER_WIDTH-1:0]                      m_axis_rslt_tuser
);

  // Grid Data Width
  localparam GRID_WIDTH = DATA_WIDTH;
  // Grid Strobe Width
  localparam GRID_STRB_WIDTH = GRID_WIDTH / 8;
  

  KanLayer #(
    .BATCH_SIZE                     (BATCH_SIZE),
    .DMA_WIDTH                      (DMA_WIDTH),
    .DMA_KEEP_ENABLE                (DMA_KEEP_ENABLE),
    .DMA_KEEP_WIDTH                 (DMA_KEEP_WIDTH),
    .AXIL_WIDTH                     (AXIL_WIDTH),
    .AXIL_STRB_WIDTH                (AXIL_STRB_WIDTH),
    .BRAM_CTRL_WIDTH                (BRAM_CTRL_WIDTH),
    .BRAM_CTRL_WE                   (BRAM_CTRL_WE),
    .BRAM_CTRL_ADDR                 (BRAM_CTRL_ADDR),
    .DATA_WIDTH                     (DATA_WIDTH),
    .DATA_FRACTIONAL_BITS           (DATA_FRACTIONAL_BITS),
    .DATA_CHANNELS                  (DATA_CHANNELS),
    .DATA_DEPTH                     (DATA_DEPTH),
{% if data_axil %}
    .DATA_ADDR                      (DATA_ADDR),
    .DATA_STRB_WIDTH                (DATA_STRB_WIDTH),
{% endif %}
    .GRID_SHARE                     (GRID_SHARE), 
    .GRID_DEPTH                     (GRID_DEPTH),
{% if grid_axil %}
//    .GRID_ADDR                      (GRID_ADDR),
//    .GRID_STRB_WIDTH                (GRID_STRB_WIDTH),
{% endif %}
    .SCALE_SHARE                    (SCALE_SHARE),
    .SCALE_WIDTH                    (SCALE_WIDTH),
    .SCALE_FRACTIONAL_BITS          (SCALE_FRACTIONAL_BITS),
    .SCALE_DEPTH                    (SCALE_DEPTH),
{% if scle_axil %}
//    .SCALE_ADDR                     (SCALE_ADDR),
//    .SCALE_STRB_WIDTH               (SCALE_STRB_WIDTH),
{% endif %}
    .RSLT_CHANNELS                  (RSLT_CHANNELS),
    .RSLT_WIDTH                     (RSLT_WIDTH),
    .RSLT_FRACTIONAL_BITS           (RSLT_FRACTIONAL_BITS),
    .RSLT_KEEP_WIDTH                (RSLT_KEEP_WIDTH),
    .RSLT_FIFO_DEPTH                (RSLT_FIFO_DEPTH),
    .WEIGHT_WIDTH                   (WEIGHT_WIDTH),
    .WEIGHT_FRACTIONAL_BITS         (WEIGHT_FRACTIONAL_BITS),
    .WEIGHT_KEEP_ENABLE             (WEIGHT_KEEP_ENABLE),
    .WEIGHT_KEEP_WIDTH              (WEIGHT_KEEP_WIDTH),
    .WEIGHT_FIFO_DEPTH              (WEIGHT_FIFO_DEPTH),
    .SCALED_DIFF_WIDTH              (SCALED_DIFF_WIDTH),
    .SCALED_DIFF_FRACTIONAL_BITS    (SCALED_DIFF_FRACTIONAL_BITS),
    .ACT_WIDTH                      (ACT_WIDTH),
    .ACT_FRACTIONAL_BITS            (ACT_FRACTIONAL_BITS),
    .WEIGHT_ID_ENABLE               (WEIGHT_ID_ENABLE),
    .WEIGHT_ID_WIDTH                (WEIGHT_ID_WIDTH),
    .RSLT_ID_ENABLE                 (RSLT_ID_ENABLE),
    .RSLT_ID_WIDTH                  (RSLT_ID_WIDTH),
    .ID_OUTPUT                      (ID_OUTPUT),
    .DEST_ENABLE                    (DEST_ENABLE),
    .DEST_WIDTH                     (DEST_WIDTH),
    .DEST_OUTPUT                    (DEST_OUTPUT),
    .USER_ENABLE                    (USER_ENABLE),
    .USER_WIDTH                     (USER_WIDTH),
    .USER_OUTPUT                    (USER_OUTPUT),
    .EXTRA_CYCLE                    (EXTRA_CYCLE),
    .ROM_DATA_PATH                  (ROM_DATA_PATH)
  ) wrapper (
    .fsm_clk                        (fsm_clk),
    .fsm_rst                        (fsm_rst),

    .core_clk                       (core_clk),
    .core_rst                       (core_rst),

    .dma_clk                        (dma_clk),
    .dma_rst                        (dma_rst),

    /*------------------------------------------------------------------
        Generated Interrupts & Resets
    ------------------------------------------------------------------*/
    .operation_busy                 (operation_busy),
    .operation_complete             (operation_complete),
    .operation_error                (operation_error),
    .locked                         (locked),
    .pl2ps_intr                     (pl2ps_intr),

    /*------------------------------------------------------------------
        BRAM Data Control interface
    ------------------------------------------------------------------*/
{% if data_axil %}
    .s_axil_data_aclk               ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_aclk{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_areset             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_areset{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_awaddr             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_awaddr{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_awprot             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_awprot{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_awvalid            ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_awvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_awready            ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_awready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_wdata              ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_wdata{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_wstrb              ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_wstrb{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_wvalid             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_wvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_wready             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_wready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_bresp              ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_bresp{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_bvalid             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_bvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_bready             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_bready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_araddr             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_araddr{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_arprot             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_arprot{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_arvalid            ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_arvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_arready            ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_arready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_rdata              ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_rdata{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_rresp              ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_rresp{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_rvalid             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_rvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axil_data_rready             ({ {% for p in range(n-1,-1,-1) %}s{{'%02d'%p}}_axil_data_rready{% if not loop.last %}, {% endif %}{% endfor %} }),
{% endif %}
{% if data_bram %}
    .bram_ctrl_data_clk             ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_clk{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_rst             ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_rst{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_en              ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_en{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_we              ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_we{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_addr            ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_addr{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_din             ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_din{% if not loop.last %}, {% endif %}{% endfor %} }),
    .bram_ctrl_data_dout            ({ {% for p in range(n-1,-1,-1) %}bram{{'%02d'%p}}_ctrl_data_dout{% if not loop.last %}, {% endif %}{% endfor %} }),
{% endif %}

    /*------------------------------------------------------------------
        BRAM Grid Control interface
    ------------------------------------------------------------------*/
{% if grid_axil %}
    .s_axil_grid_aclk               (s_axil_grid_aclk),
    .s_axil_grid_areset             (s_axil_grid_areset),
    .s_axil_grid_awaddr             (s_axil_grid_awaddr),
    .s_axil_grid_awprot             (s_axil_grid_awprot),
    .s_axil_grid_awvalid            (s_axil_grid_awvalid),
    .s_axil_grid_awready            (s_axil_grid_awready),
    .s_axil_grid_wdata              (s_axil_grid_wdata),
    .s_axil_grid_wstrb              (s_axil_grid_wstrb),
    .s_axil_grid_wvalid             (s_axil_grid_wvalid),
    .s_axil_grid_wready             (s_axil_grid_wready),
    .s_axil_grid_bresp              (s_axil_grid_bresp),
    .s_axil_grid_bvalid             (s_axil_grid_bvalid),
    .s_axil_grid_bready             (s_axil_grid_bready),
    .s_axil_grid_araddr             (s_axil_grid_araddr),
    .s_axil_grid_arprot             (s_axil_grid_arprot),
    .s_axil_grid_arvalid            (s_axil_grid_arvalid),
    .s_axil_grid_arready            (s_axil_grid_arready),
    .s_axil_grid_rdata              (s_axil_grid_rdata),
    .s_axil_grid_rresp              (s_axil_grid_rresp),
    .s_axil_grid_rvalid             (s_axil_grid_rvalid),
    .s_axil_grid_rready             (s_axil_grid_rready),
{% endif %}
{% if grid_bram %}
    .bram_ctrl_grid_clk             (bram_ctrl_grid_clk),
    .bram_ctrl_grid_rst             (bram_ctrl_grid_rst),
    .bram_ctrl_grid_en              (bram_ctrl_grid_en),
    .bram_ctrl_grid_we              (bram_ctrl_grid_we),
    .bram_ctrl_grid_addr            (bram_ctrl_grid_addr),
    .bram_ctrl_grid_din             (bram_ctrl_grid_din),
    .bram_ctrl_grid_dout            (bram_ctrl_grid_dout),
{% endif %}

    /*------------------------------------------------------------------
        BRAM Scale Control interface
    ------------------------------------------------------------------*/

{% if scle_axil %}
    .s_axil_scle_aclk               (s_axil_scle_aclk),
    .s_axil_scle_areset             (s_axil_scle_areset),
    .s_axil_scle_awaddr             (s_axil_scle_awaddr),
    .s_axil_scle_awprot             (s_axil_scle_awprot),
    .s_axil_scle_awvalid            (s_axil_scle_awvalid),
    .s_axil_scle_awready            (s_axil_scle_awready),
    .s_axil_scle_wdata              (s_axil_scle_wdata),
    .s_axil_scle_wstrb              (s_axil_scle_wstrb),
    .s_axil_scle_wvalid             (s_axil_scle_wvalid),
    .s_axil_scle_wready             (s_axil_scle_wready),
    .s_axil_scle_bresp              (s_axil_scle_bresp),
    .s_axil_scle_bvalid             (s_axil_scle_bvalid),
    .s_axil_scle_bready             (s_axil_scle_bready),
    .s_axil_scle_araddr             (s_axil_scle_araddr),
    .s_axil_scle_arprot             (s_axil_scle_arprot),
    .s_axil_scle_arvalid            (s_axil_scle_arvalid),
    .s_axil_scle_arready            (s_axil_scle_arready),
    .s_axil_scle_rdata              (s_axil_scle_rdata),
    .s_axil_scle_rresp              (s_axil_scle_rresp),
    .s_axil_scle_rvalid             (s_axil_scle_rvalid),
    .s_axil_scle_rready             (s_axil_scle_rready),
{% endif %}
{% if scle_bram %}
    .bram_ctrl_scle_clk             (bram_ctrl_scle_clk),
    .bram_ctrl_scle_rst             (bram_ctrl_scle_rst),
    .bram_ctrl_scle_en              (bram_ctrl_scle_en),
    .bram_ctrl_scle_we              (bram_ctrl_scle_we),
    .bram_ctrl_scle_addr            (bram_ctrl_scle_addr),
    .bram_ctrl_scle_din             (bram_ctrl_scle_din),
    .bram_ctrl_scle_dout            (bram_ctrl_scle_dout),
{% endif %}
  
    /*------------------------------------------------------------------
        AXI-Lite Control Slave interface
    ------------------------------------------------------------------*/

    .s_axil_ctrl_awaddr             (s_axil_ctrl_awaddr[5:0]),
    .s_axil_ctrl_awprot             (s_axil_ctrl_awprot),
    .s_axil_ctrl_awvalid            (s_axil_ctrl_awvalid),
    .s_axil_ctrl_awready            (s_axil_ctrl_awready),
    .s_axil_ctrl_wdata              (s_axil_ctrl_wdata),
    .s_axil_ctrl_wstrb              (s_axil_ctrl_wstrb),
    .s_axil_ctrl_wvalid             (s_axil_ctrl_wvalid),
    .s_axil_ctrl_wready             (s_axil_ctrl_wready),
    .s_axil_ctrl_bresp              (s_axil_ctrl_bresp),
    .s_axil_ctrl_bvalid             (s_axil_ctrl_bvalid),
    .s_axil_ctrl_bready             (s_axil_ctrl_bready),
    .s_axil_ctrl_araddr             (s_axil_ctrl_araddr[5:0]),
    .s_axil_ctrl_arprot             (s_axil_ctrl_arprot),
    .s_axil_ctrl_arvalid            (s_axil_ctrl_arvalid),
    .s_axil_ctrl_arready            (s_axil_ctrl_arready),
    .s_axil_ctrl_rdata              (s_axil_ctrl_rdata),
    .s_axil_ctrl_rresp              (s_axil_ctrl_rresp),
    .s_axil_ctrl_rvalid             (s_axil_ctrl_rvalid),
    .s_axil_ctrl_rready             (s_axil_ctrl_rready),

    /*------------------------------------------------------------------
        AXI-Stream WEIGHT Slave interface
    ------------------------------------------------------------------*/

    .s_axis_wght_tdata              (s_axis_wght_tdata),
    .s_axis_wght_tkeep              (s_axis_wght_tkeep),
    .s_axis_wght_tvalid             (s_axis_wght_tvalid),  
    .s_axis_wght_tready             (s_axis_wght_tready),
    .s_axis_wght_tlast              (s_axis_wght_tlast),
    .s_axis_wght_tid                (s_axis_wght_tid),
    .s_axis_wght_tdest              (s_axis_wght_tdest),
    .s_axis_wght_tuser              (s_axis_wght_tuser),

    /*------------------------------------------------------------------
        AXI-Stream Results / Output Master interface
    ------------------------------------------------------------------*/

    .m_axis_rslt_tdata              (m_axis_rslt_tdata),
    .m_axis_rslt_tkeep              (m_axis_rslt_tkeep),
    .m_axis_rslt_tvalid             (m_axis_rslt_tvalid),  
    .m_axis_rslt_tready             (m_axis_rslt_tready),
    .m_axis_rslt_tlast              (m_axis_rslt_tlast),
    .m_axis_rslt_tid                (m_axis_rslt_tid),
    .m_axis_rslt_tdest              (m_axis_rslt_tdest),
    .m_axis_rslt_tuser              (m_axis_rslt_tuser)
  );

endmodule

`resetall

""")
    print(f"Writing file '{output}'...")
    
    with open(output, 'w') as f:
        f.write(t.render(
            n=n,
            cn=cn,
            name=name,
            **kwargs
        ))
        f.flush()

    print("Done")

if __name__ == "__main__":
    main()
