from __future__ import absolute_import
from __future__ import print_function
import sys
import os

# import pyverilog.vparser.ast as vast
# from pyverilog.ast_code_generator.codegen import ASTCodeGenerator
from veriloggen import *

TOP_DIR = os.path.dirname(  # .../kan-fpga
    os.path.dirname(
        os.path.abspath(__file__)
    )
)
sys.path.append(TOP_DIR)

from py import addTimeScale, stripModule, clear_hints, ctrl_reg
import numpy as np
import torch

hex_list = lambda x: [hex_list(_) for _ in x] if hasattr(x, '__iter__') else hex(x)

def find_strobe(out, address, word_size, clog_num_words, prints=False):
    slice = address.slice(
        msb = clog_num_words-1,
        lsb = 0
    )
    # if prints :
    #     prints = [Display('Strobe : %h -> [%h, %h)', address, slice, slice + word_size),]
    # else :
    #     prints = []
    
    return [
        out[bit_i]( Ands(
            bit_i < slice + word_size,
            bit_i >= slice,
        )) for bit_i in range(2 ** clog_num_words.value)
    ] # + prints

def KanLayer(I=1,J=1,K=1,N_in=256, data_width=16, sdff_width=12, is_async=True):
    basename = 'tb_kan_layer_wrapper'
    fname = os.path.join(TOP_DIR,f'rtl/wrapper/{basename}.v')
    exec_str = ' '.join([
        str(_) for _ in [
        os.path.join(TOP_DIR,'rtl/wrapper/KanLayerInst.py'),
        '--batch-size',             K,
        '--data-axil' if J == 1 else '--data-bram',              
        '--data-width',             data_width,
        '--data-frac-bits',         data_width-5,
        '--data-chn',               J,
        '--data-depth',             J * max(N_in // J, 1),
        '--grid-depth',             8,
        '--grid-share',             
        '--scle-width',             data_width,
        '--scle-frac-bits',         data_width-2,
        '--scle-depth',             1,
        '--scle-share',             
        '--wght-width',             data_width,
        '--wght-frac-bits',         data_width-5,
        '--wght-depth',             int(max(2 ** np.ceil(np.log2(I*J+K+8)+4), 8)) * 2,
        '--sdff-width',             sdff_width,
        '--sdff-frac-bits',         sdff_width-3,
        '--actf-width',             data_width,
        '--actf-frac-bits',         data_width,
        '--rslt-chn',               I,
        '--rslt-width',             data_width,
        '--rslt-frac-bits',         data_width-5,
        '--rslt-depth',             int(max( 2 ** np.ceil(np.log2(K + I + 8)), 8))*2,
        '--name',                   basename,
        '--output',                 fname
    ]] + (['--async'] if is_async else []))
    print(f'-- {exec_str}')
    os.system(exec_str)
    clear_hints(fname)
    return verilog.from_verilog.read_verilog_module(fname)[basename] 

def tb_KanLayer(I=1,J=1,K=1,N_in=256,N_out=256):
    module = Module(f'tb_KanLayer_{I}_{J}_{K}_{N_in}_{N_out}')
    
    module.EmbeddedCode(
    f'''
`ifdef IF_OPTIONS_INST_H
`undef IF_OPTIONS_INST_H
`endif
`define {"DATA_IF_IS_AXIL" if J == 1 else "DATA_IF_IS_BRAM"}
`define GRID_IS_SHARED
`define SCALE_IS_SHARED
`include "header_utils.vh"
`include "header_IFOptions.vh"
`define assert(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s != %s",`"signal`", `"value`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        $display("---- %s = 0x%h",`"value`",value); \
        #5 \
        $finish; \
    end
`define assertTrue(signal) \
    if (~signal) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s is not True",`"signal`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        #5 \
        $finish; \
    end
`define assertFalse(signal) \
    if (signal) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s is not False",`"signal`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        #5 \
        $finish; \
    end
`define assertAbsDiffLE(signal0, signal1, value) \
    if ( `ABS(signal0-signal1) > value) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- ABS(%s-%s) > %s",`"signal0`",`"signal1`",`"value`"); \
        $display("---- %s = 0x%h",`"signal0`",signal0); \
        $display("---- %s = 0x%h",`"signal1`",signal1); \
        $display("---- Abs Diff = 0x%h",`ABS(signal0-signal1)); \
        $display("---- %s = 0x%h",`"value`",value); \
        #5 \
        $finish; \
    end
    ''')
    def Assert(signal,value):
        return EmbeddedCode(f'`assert({signal},{value})')
    def AssertTrue(signal):
        return EmbeddedCode(f'`assertTrue({signal})')
    def AssertFalse(signal):
        return EmbeddedCode(f'`assertFalse({signal})')
    def AssertAbsDiffLE(signal0,signal1,value):
        return EmbeddedCode(f'`assertAbsDiffLE({signal0},{signal1},{value})')
    def LOG2(signal):
        return EmbeddedNumeric(f'`LOG2( {signal} )')
    def RLOG2(signal):
        return EmbeddedNumeric(f'`RLOG2( {signal} )')
    
    data_width = 16
    sdff_width = 12
    is_async = True
    
    fast_clk_hperiod = 2      # 250 MHz
    
    kan = KanLayer(I=I,J=J,K=K,N_in=N_in, data_width=data_width, sdff_width=sdff_width, is_async=is_async)
    params = module.copy_params_as_localparams(kan)
    ports  = module.copy_ports_as_vars(kan)
    final_dtype = getattr(torch,f'uint{((data_width +7)//8)*8}')

    DATA_CHANNELS               : Localparam = params['DATA_CHANNELS']
    RSLT_CHANNELS               : Localparam = params['RSLT_CHANNELS']
    BATCH_SIZE                  : Localparam = params['BATCH_SIZE']
    SCALE_SHARE                 : Localparam = params['SCALE_SHARE']
    GRID_SHARE                  : Localparam = params['GRID_SHARE']
    DATA_WIDTH                  : Localparam = params['DATA_WIDTH']
    DATA_FRACTIONAL_BITS        : Localparam = params['DATA_FRACTIONAL_BITS']
    SCALE_FRACTIONAL_BITS       : Localparam = params['SCALE_FRACTIONAL_BITS']
    WEIGHT_FRACTIONAL_BITS      : Localparam = params['WEIGHT_FRACTIONAL_BITS']
    SCALED_DIFF_WIDTH           : Localparam = params['SCALED_DIFF_WIDTH']
    SCALED_DIFF_FRACTIONAL_BITS : Localparam = params['SCALED_DIFF_FRACTIONAL_BITS']
    ACT_FRACTIONAL_BITS         : Localparam = params['ACT_FRACTIONAL_BITS']
    RSLT_FRACTIONAL_BITS        : Localparam = params['RSLT_FRACTIONAL_BITS']
    
    DMA_WIDTH                   : Localparam = params['DMA_WIDTH']
    DMA_STRB_WIDTH              : Localparam = params['AXIL_STRB_WIDTH']
    
    AXIL_WIDTH                  : Localparam = params['AXIL_WIDTH']
    AXIL_STRB_WIDTH             : Localparam = params['AXIL_STRB_WIDTH']
    
    BRAM_WIDTH                  : Localparam = params['BRAM_CTRL_WIDTH']
    BRAM_STRB_WIDTH             : Localparam = params['BRAM_CTRL_WE']
    
    if (J == 1):
        DATA_ADDR                   : Localparam = params['DATA_ADDR']
    else :
        DATA_ADDR               = module.Localparam('DATA_ADDR', LOG2(params['DATA_DEPTH']))
    GRID_ADDR                   : Localparam = params['GRID_ADDR']
    SCALE_ADDR                  : Localparam = params['SCALE_ADDR']
    
    if ('DATA_STRB_WIDTH' not in params):
        DATA_STRB_WIDTH         = module.Localparam('DATA_STRB_WIDTH', DATA_WIDTH / 8)
    else :
        DATA_STRB_WIDTH         : Localparam = params['DATA_STRB_WIDTH']
    
    RSLT_CHANNELS.value = I
    DATA_CHANNELS.value = J
    BATCH_SIZE.value  = K
    DATA_WIDTH.value = data_width
    DATA_STRB_WIDTH.value = data_width // 8
    DATA_FRACTIONAL_BITS.value = data_width-5
    SCALE_FRACTIONAL_BITS.value = data_width-2
    WEIGHT_FRACTIONAL_BITS.value = data_width-5
    SCALED_DIFF_WIDTH.value = sdff_width
    SCALED_DIFF_FRACTIONAL_BITS.value = sdff_width-3
    ACT_FRACTIONAL_BITS.value = data_width
    RSLT_FRACTIONAL_BITS.value = data_width-5
    
    DMA_WIDTH.value = 64
    DMA_STRB_WIDTH.value = 64 // 8
    
    AXIL_WIDTH.value = 32
    AXIL_STRB_WIDTH.value = 32 // 8
    CLOG_AXIL_STRB_WIDTH = module.Localparam('CLOG_AXIL_STRB_WIDTH', 2)
    
    BRAM_WIDTH.value = 32
    BRAM_STRB_WIDTH.value = 32 // 8 
    CLOG_BRAM_STRB_WIDTH = module.Localparam('CLOG_BRAM_STRB_WIDTH', 2)
    
    AXIL_CTRL_WIDTH =  module.Localparam('AXIL_CTRL_WIDTH',32)
    AXIL_CTRL_STRB_WIDTH =  module.Localparam('AXIL_CTRL_STRB_WIDTH',4)
    CLOG_AXIL_CTRL_STRB_WIDTH = module.Localparam('CLOG_AXIL_CTRL_STRB_WIDTH', 2)
    
    if SCALE_SHARE.value :
        SCALE_ADDR.value *= 4
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        kan,
        'uut',
        params,
        ports
    )
    
    fsm_clk                     = ports['fsm_clk']
    fsm_rst                     = ports['fsm_rst']
    core_clk                    = ports['core_clk']
    core_rst                    = ports['core_rst']
    dma_clk                     = ports['dma_clk']
    dma_rst                     = ports['dma_rst']
    
    operation_busy              = ports['operation_busy']
    operation_complete          = ports['operation_complete']
    operation_error             = ports['operation_error']
    locked                      = ports['locked']
    pl2ps_intr                  = ports['pl2ps_intr']
    
    if (DATA_CHANNELS.value == 1):
        s_axil_data_aclk      = [ports[f's{str(batch).zfill(2)}_axil_data_aclk']    for batch in range(K) ]
        s_axil_data_areset    = [ports[f's{str(batch).zfill(2)}_axil_data_areset']  for batch in range(K) ]
        s_axil_data_awaddr    = [ports[f's{str(batch).zfill(2)}_axil_data_awaddr']  for batch in range(K) ]
        s_axil_data_awprot    = [ports[f's{str(batch).zfill(2)}_axil_data_awprot']  for batch in range(K) ]
        s_axil_data_awvalid   = [ports[f's{str(batch).zfill(2)}_axil_data_awvalid'] for batch in range(K) ]
        s_axil_data_awready   = [ports[f's{str(batch).zfill(2)}_axil_data_awready'] for batch in range(K) ]
        s_axil_data_wdata     = [ports[f's{str(batch).zfill(2)}_axil_data_wdata']   for batch in range(K) ]
        s_axil_data_wstrb     = [ports[f's{str(batch).zfill(2)}_axil_data_wstrb']   for batch in range(K) ]
        s_axil_data_wvalid    = [ports[f's{str(batch).zfill(2)}_axil_data_wvalid']  for batch in range(K) ]
        s_axil_data_wready    = [ports[f's{str(batch).zfill(2)}_axil_data_wready']  for batch in range(K) ]
        s_axil_data_bresp     = [ports[f's{str(batch).zfill(2)}_axil_data_bresp']   for batch in range(K) ]
        s_axil_data_bvalid    = [ports[f's{str(batch).zfill(2)}_axil_data_bvalid']  for batch in range(K) ]
        s_axil_data_bready    = [ports[f's{str(batch).zfill(2)}_axil_data_bready']  for batch in range(K) ]
        s_axil_data_araddr    = [ports[f's{str(batch).zfill(2)}_axil_data_araddr']  for batch in range(K) ]
        s_axil_data_arprot    = [ports[f's{str(batch).zfill(2)}_axil_data_arprot']  for batch in range(K) ]
        s_axil_data_arvalid   = [ports[f's{str(batch).zfill(2)}_axil_data_arvalid'] for batch in range(K) ]
        s_axil_data_arready   = [ports[f's{str(batch).zfill(2)}_axil_data_arready'] for batch in range(K) ]
        s_axil_data_rdata     = [ports[f's{str(batch).zfill(2)}_axil_data_rdata']   for batch in range(K) ]
        s_axil_data_rresp     = [ports[f's{str(batch).zfill(2)}_axil_data_rresp']   for batch in range(K) ]
        s_axil_data_rvalid    = [ports[f's{str(batch).zfill(2)}_axil_data_rvalid']  for batch in range(K) ]
        s_axil_data_rready    = [ports[f's{str(batch).zfill(2)}_axil_data_rready']  for batch in range(K) ]
        
        DATA_ADDR_BYTES = module.Localparam('DATA_ADDR_BYTES', DATA_ADDR)
    else :
        bram_ctrl_data_clk    = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_clk']  for batch in range(K) ]
        bram_ctrl_data_rst    = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_rst']  for batch in range(K) ]
        bram_ctrl_data_en     = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_en']   for batch in range(K) ]
        bram_ctrl_data_we     = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_we']   for batch in range(K) ]
        bram_ctrl_data_addr   = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_addr'] for batch in range(K) ]
        bram_ctrl_data_din    = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_din']  for batch in range(K) ]
        bram_ctrl_data_dout   = [ports[f'bram{str(batch).zfill(2)}_ctrl_data_dout'] for batch in range(K) ]
    
        DATA_ADDR_BYTES = module.Localparam('DATA_ADDR_BYTES', DATA_ADDR + RLOG2(DATA_STRB_WIDTH) )
        
    if (GRID_SHARE.value):
        s_axil_grid_aclk        = ports['s_axil_grid_aclk']
        s_axil_grid_areset      = ports['s_axil_grid_areset']
        s_axil_grid_awaddr      = ports['s_axil_grid_awaddr']
        s_axil_grid_awprot      = ports['s_axil_grid_awprot']
        s_axil_grid_awvalid     = ports['s_axil_grid_awvalid']
        s_axil_grid_awready     = ports['s_axil_grid_awready']
        s_axil_grid_wdata       = ports['s_axil_grid_wdata']
        s_axil_grid_wstrb       = ports['s_axil_grid_wstrb']
        s_axil_grid_wvalid      = ports['s_axil_grid_wvalid']
        s_axil_grid_wready      = ports['s_axil_grid_wready']
        s_axil_grid_bresp       = ports['s_axil_grid_bresp']
        s_axil_grid_bvalid      = ports['s_axil_grid_bvalid']
        s_axil_grid_bready      = ports['s_axil_grid_bready']
        s_axil_grid_araddr      = ports['s_axil_grid_araddr']
        s_axil_grid_arprot      = ports['s_axil_grid_arprot']
        s_axil_grid_arvalid     = ports['s_axil_grid_arvalid']
        s_axil_grid_arready     = ports['s_axil_grid_arready']
        s_axil_grid_rdata       = ports['s_axil_grid_rdata']
        s_axil_grid_rresp       = ports['s_axil_grid_rresp']
        s_axil_grid_rvalid      = ports['s_axil_grid_rvalid']
        s_axil_grid_rready      = ports['s_axil_grid_rready']
        
        GRID_ADDR_BYTES = module.Localparam('GRID_ADDR_BYTES', GRID_ADDR)
    else :
        bram_ctrl_grid_clk      = ports['bram_ctrl_grid_clk']
        bram_ctrl_grid_rst      = ports['bram_ctrl_grid_rst']
        bram_ctrl_grid_en       = ports['bram_ctrl_grid_en']
        bram_ctrl_grid_we       = ports['bram_ctrl_grid_we']
        bram_ctrl_grid_addr     = ports['bram_ctrl_grid_addr']
        bram_ctrl_grid_din      = ports['bram_ctrl_grid_din']
        bram_ctrl_grid_dout     = ports['bram_ctrl_grid_dout']
    
        GRID_ADDR_BYTES = module.Localparam('GRID_ADDR_BYTES', GRID_ADDR + RLOG2(DATA_STRB_WIDTH))
        
    if (SCALE_SHARE.value):
        s_axil_scle_aclk        = ports['s_axil_scle_aclk']
        s_axil_scle_areset      = ports['s_axil_scle_areset']
        s_axil_scle_awaddr      = ports['s_axil_scle_awaddr']
        s_axil_scle_awprot      = ports['s_axil_scle_awprot']
        s_axil_scle_awvalid     = ports['s_axil_scle_awvalid']
        s_axil_scle_awready     = ports['s_axil_scle_awready']
        s_axil_scle_wdata       = ports['s_axil_scle_wdata']
        s_axil_scle_wstrb       = ports['s_axil_scle_wstrb']
        s_axil_scle_wvalid      = ports['s_axil_scle_wvalid']
        s_axil_scle_wready      = ports['s_axil_scle_wready']
        s_axil_scle_bresp       = ports['s_axil_scle_bresp']
        s_axil_scle_bvalid      = ports['s_axil_scle_bvalid']
        s_axil_scle_bready      = ports['s_axil_scle_bready']
        s_axil_scle_araddr      = ports['s_axil_scle_araddr']
        s_axil_scle_arprot      = ports['s_axil_scle_arprot']
        s_axil_scle_arvalid     = ports['s_axil_scle_arvalid']
        s_axil_scle_arready     = ports['s_axil_scle_arready']
        s_axil_scle_rdata       = ports['s_axil_scle_rdata']
        s_axil_scle_rresp       = ports['s_axil_scle_rresp']
        s_axil_scle_rvalid      = ports['s_axil_scle_rvalid']
        s_axil_scle_rready      = ports['s_axil_scle_rready']
        
        SCALE_ADDR_BYTES = module.Localparam('SCALE_ADDR_BYTES', SCALE_ADDR)
    else :
        bram_ctrl_scle_clk      = ports['bram_ctrl_scle_clk']
        bram_ctrl_scle_rst      = ports['bram_ctrl_scle_rst']
        bram_ctrl_scle_en       = ports['bram_ctrl_scle_en']
        bram_ctrl_scle_we       = ports['bram_ctrl_scle_we']
        bram_ctrl_scle_addr     = ports['bram_ctrl_scle_addr']
        bram_ctrl_scle_din      = ports['bram_ctrl_scle_din']
        bram_ctrl_scle_dout     = ports['bram_ctrl_scle_dout']
        
        SCALE_ADDR_BYTES = module.Localparam('SCALE_ADDR_BYTES', SCALE_ADDR + RLOG2(DATA_STRB_WIDTH))
    
    s_axil_ctrl_awaddr          = ports['s_axil_ctrl_awaddr']
    s_axil_ctrl_awprot          = ports['s_axil_ctrl_awprot']
    s_axil_ctrl_awvalid         = ports['s_axil_ctrl_awvalid']
    s_axil_ctrl_awready         = ports['s_axil_ctrl_awready']
    s_axil_ctrl_wdata           = ports['s_axil_ctrl_wdata']
    s_axil_ctrl_wstrb           = ports['s_axil_ctrl_wstrb']
    s_axil_ctrl_wvalid          = ports['s_axil_ctrl_wvalid']
    s_axil_ctrl_wready          = ports['s_axil_ctrl_wready']
    s_axil_ctrl_bresp           = ports['s_axil_ctrl_bresp']
    s_axil_ctrl_bvalid          = ports['s_axil_ctrl_bvalid']
    s_axil_ctrl_bready          = ports['s_axil_ctrl_bready']
    s_axil_ctrl_araddr          = ports['s_axil_ctrl_araddr']
    s_axil_ctrl_arprot          = ports['s_axil_ctrl_arprot']
    s_axil_ctrl_arvalid         = ports['s_axil_ctrl_arvalid']
    s_axil_ctrl_arready         = ports['s_axil_ctrl_arready']
    s_axil_ctrl_rdata           = ports['s_axil_ctrl_rdata']
    s_axil_ctrl_rresp           = ports['s_axil_ctrl_rresp']
    s_axil_ctrl_rvalid          = ports['s_axil_ctrl_rvalid']
    s_axil_ctrl_rready          = ports['s_axil_ctrl_rready']

    s_axis_wght_tdata           = ports['s_axis_wght_tdata']
    s_axis_wght_tkeep           = ports['s_axis_wght_tkeep']
    s_axis_wght_tlast           = ports['s_axis_wght_tlast']
    s_axis_wght_tvalid          = ports['s_axis_wght_tvalid']
    s_axis_wght_tready          = ports['s_axis_wght_tready']
    
    m_axis_rslt_tdata           = ports['m_axis_rslt_tdata']
    m_axis_rslt_tkeep           = ports['m_axis_rslt_tkeep']
    m_axis_rslt_tlast           = ports['m_axis_rslt_tlast']
    m_axis_rslt_tvalid          = ports['m_axis_rslt_tvalid']
    m_axis_rslt_tready          = ports['m_axis_rslt_tready']
    m_axis_rslt_tid             = ports['m_axis_rslt_tid']
    
    reset_stmt = []
    reset_stmt.append(reset_done(0))
    
    for batch in range(K):
        if (DATA_CHANNELS.value == 1):
            reset_stmt.append(s_axil_data_awvalid   [batch] (0))
            reset_stmt.append(s_axil_data_wvalid    [batch] (0))
            reset_stmt.append(s_axil_data_bready    [batch] (0))
            reset_stmt.append(s_axil_data_arvalid   [batch] (0))
            reset_stmt.append(s_axil_data_rready    [batch] (0))
            
            reset_stmt.append(s_axil_data_awprot    [batch](0))
            reset_stmt.append(s_axil_data_arprot    [batch](0))
        else :
            reset_stmt.append(bram_ctrl_data_en     [batch](0))
            reset_stmt.append(bram_ctrl_data_we     [batch](0))
        
    if (GRID_SHARE.value):
        reset_stmt.append(s_axil_grid_awvalid(0))
        reset_stmt.append(s_axil_grid_wvalid(0))
        reset_stmt.append(s_axil_grid_bready(0))
        reset_stmt.append(s_axil_grid_arvalid(0))
        reset_stmt.append(s_axil_grid_rready(0))
        
        reset_stmt.append(s_axil_grid_awprot(0))
        reset_stmt.append(s_axil_grid_arprot(0))
    else :
        reset_stmt.append(bram_ctrl_grid_en(0))
        reset_stmt.append(bram_ctrl_grid_we(0))
        
    if (SCALE_SHARE.value):
        reset_stmt.append(s_axil_scle_awvalid(0))
        reset_stmt.append(s_axil_scle_wvalid(0))
        reset_stmt.append(s_axil_scle_bready(0))
        reset_stmt.append(s_axil_scle_arvalid(0))
        reset_stmt.append(s_axil_scle_rready(0))
        
        reset_stmt.append(s_axil_scle_awprot(0))
        reset_stmt.append(s_axil_scle_arprot(0))
    else :
        reset_stmt.append(bram_ctrl_scle_en(0))
        reset_stmt.append(bram_ctrl_scle_we(0))
        
    
    reset_stmt.append(s_axil_ctrl_awvalid(0))
    reset_stmt.append(s_axil_ctrl_wvalid(0))
    reset_stmt.append(s_axil_ctrl_bready(0))
    reset_stmt.append(s_axil_ctrl_arvalid(0))
    reset_stmt.append(s_axil_ctrl_rready(0))
        
    reset_stmt.append(s_axil_ctrl_awprot(0))
    reset_stmt.append(s_axil_ctrl_arprot(0))
        
    reset_stmt.append(s_axis_wght_tvalid(0))
    reset_stmt.append(m_axis_rslt_tready(0))
    
    slow_clk_hperiod = fast_clk_hperiod * DMA_WIDTH / (DATA_CHANNELS*RSLT_CHANNELS*DATA_WIDTH) if is_async else fast_clk_hperiod

    vcd_name = os.path.join('..','vcd',f'tb_KanLayer_{I}_{J}_{K}_{N_in}_{N_out}.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, fsm_clk,  hperiod=slow_clk_hperiod)
    simulation.setup_clock(module, core_clk, hperiod=fast_clk_hperiod)
    
    # Clock & Reset Configuration
    module.Always()(
        dma_clk(fsm_clk),
        dma_rst(core_rst),
    )
    for batch in range(K):
        if(DATA_CHANNELS.value == 1):
            module.Always()(
                s_axil_data_aclk[batch](core_clk),
                s_axil_data_areset[batch](core_rst),
            )
        else:
            module.Always()(
                bram_ctrl_data_clk[batch](core_clk),
                bram_ctrl_data_rst[batch](core_rst),
            )
    if(GRID_SHARE.value):
        module.Always()(
            s_axil_grid_aclk(core_clk),
            s_axil_grid_areset(core_rst),
        )
    else:
        module.Always()(
            bram_ctrl_grid_clk(core_clk),
            bram_ctrl_grid_rst(core_rst),
        )
    if(SCALE_SHARE.value):
        module.Always()(
            s_axil_scle_aclk(core_clk),
            s_axil_scle_areset(core_rst),
        )
    else:
        module.Always()(
            bram_ctrl_scle_clk(core_clk),
            bram_ctrl_scle_rst(core_rst),
        )
    
    init = simulation.setup_reset(module, fsm_rst, reset_stmt, period=4*slow_clk_hperiod)

    nclk = simulation.next_clock
    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(fsm_clk),
        Delay(2000 + 8*N_in*N_out/DATA_CHANNELS/RSLT_CHANNELS * 2 * 4 * (2**5)),
        # Delay(10),
        Display('!! TIMEOUT ERROR !!'),
        AssertTrue(0),
    )
    
    global_stage_counter = module.Integer('global_stage_counter')

    # KAN Layer parameters
    device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
    data_len = DATA_CHANNELS.value * max(N_in // DATA_CHANNELS.value, 1)
    grid_len = 8
    scale_len = (1,1,1) if SCALE_SHARE.value else (1,data_len,grid_len)
    rslt_len = RSLT_CHANNELS.value * max(N_out // RSLT_CHANNELS.value, 1)
    weight_len = data_len*grid_len
    adder_size = 64
    pckt_len = (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value))
    # print(data_len,grid_len,scale_len,rslt_len,weight_len)
    
    # Create data - size = [BATCH X DATA X 1]
    layer_data = torch.randn(K, data_len, 1, device=device)
    # Quantize data
    layer_data_q = torch.tensor((layer_data * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'),device=device)
    # Dequantize data
    layer_data = layer_data_qd = layer_data_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create grid - size = [1 X 1 X GRID]
    layer_grid = torch.randn(1, 1, grid_len, device=device)
    # Quantize grid
    layer_grid_q = torch.tensor((layer_grid * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize grid
    layer_grid = layer_grid_qd = layer_grid_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create scale - size = [1 X DATA X GRID] or [1] 
    layer_scle = torch.rand(*scale_len, device=device) * 2 ** (DATA_WIDTH.value - SCALE_FRACTIONAL_BITS.value-1)
    # Quantize scale
    layer_scle_q = torch.tensor((layer_scle * 2 ** SCALE_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_scle = layer_scle_qd = layer_scle_q.to(torch.float32) / 2 ** SCALE_FRACTIONAL_BITS.value
    
    
    # Create weight - size = [WEIGHT x RESULT] or [1] 
    layer_wght = (torch.rand(weight_len, rslt_len, device=device) * 2 - 1)

    # Create expected scaled difference - size = [BATCH X GRID X DATA]
    layer_exp_sdff = (layer_scle * (layer_data - layer_grid)).abs()
    # Create expected activation data - size = [BATCH X GRID X DATA]
    layer_exp_actd = torch.tensor((1 - np.tanh(layer_exp_sdff.cpu().numpy().astype('float128'))**2).astype('float32'), device=device)
    # Reshape expected activation data - size = [BATCH X WEIGHT]
    layer_exp_actd = layer_exp_actd.reshape(-1, weight_len)

    if True:
        # Perform expected Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
        layer_exp_rslt = layer_exp_actd @ layer_wght
        
        # Normalize weights
        weight_scale = 1. / layer_exp_rslt.abs().max()
    
    
    # Normalize weight - size = [WEIGHT x RESULT] or [1] 
    layer_wght = layer_wght * weight_scale * 2 ** (DATA_WIDTH.value - WEIGHT_FRACTIONAL_BITS.value-1)
    # Quantize scale
    layer_wght_q = torch.tensor((layer_wght * 2 ** WEIGHT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{4*DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_wght = layer_wght_qd = layer_wght_q.to(torch.float32) / 2 ** WEIGHT_FRACTIONAL_BITS.value
    # print(layer_wght_q,layer_wght)
    # exit()
    
    
    # Create scaled difference - size = [BATCH X GRID X DATA]
    layer_diff = (layer_data_qd - layer_grid_qd)
    # Quantize scaled difference
    layer_diff_q = torch.tensor((layer_diff * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device).abs()
    # Dequantize scaled difference
    layer_diff_qd = layer_diff_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create scaled difference - size = [BATCH X GRID X DATA]
    layer_sdff = (layer_scle_qd * layer_diff_qd).abs()
    # Quantize scaled difference
    layer_sdff_q = torch.tensor((layer_sdff * 2 ** SCALED_DIFF_FRACTIONAL_BITS.value).clamp(
        min = 0,
        max = 2 ** SCALED_DIFF_WIDTH.value -1
    ).cpu().numpy().astype(f'int{adder_size}'), device=device).abs()
    # Dequantize scaled difference
    layer_sdff_qd = layer_sdff_q.cpu().numpy().astype('float128') / 2 ** SCALED_DIFF_FRACTIONAL_BITS.value
    
    # Create activation data - size = [BATCH X WEIGHT]
    layer_actd = 1 - np.tanh(layer_sdff_qd)**2
    # Quantize activation data
    layer_actd_q = torch.tensor((layer_actd * 2 ** ACT_FRACTIONAL_BITS.value).astype(f'int{2*DATA_WIDTH.value}'), device=device)
    # Unit correction
    if (DATA_WIDTH.value == ACT_FRACTIONAL_BITS.value):
        layer_actd_q = torch.where(
            layer_actd_q > 2 ** ACT_FRACTIONAL_BITS.value -1,
            2 ** ACT_FRACTIONAL_BITS.value - 1,
            layer_actd_q
        )
    # Reshape activation data - size = [BATCH X WEIGHT]
    layer_actd_q = layer_actd_q.movedim(-1,-2).reshape(-1, weight_len)
    # Dequantize activation data - size = [BATCH X WEIGHT]
    layer_actd_qd = layer_actd_q.to(torch.float32) / 2 ** ACT_FRACTIONAL_BITS.value
    
    # Perform expected Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
    layer_exp_rslt = layer_exp_actd @ layer_wght
    # Quantize expected result
    layer_exp_rslt_q = torch.tensor((layer_exp_rslt * 2 ** RSLT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    
    # Perform Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
    layer_rslt = layer_actd_qd @ layer_wght_qd
    # Quantize result
    layer_rslt_q = torch.tensor((layer_rslt * 2 ** RSLT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # # Dequantize result
    # layer_rslt_qd = layer_rslt_q.to('float32') / 2 ** RSLT_FRACTIONAL_BITS.value
    
    # Perform Linear Layer / Matrix-Matrix Multiplication -- with integers - size = [BATCH X RESULT]
    layer_rslt_int = torch.einsum("bw,wr->wbr", layer_actd_q, layer_wght_q).cpu().numpy().astype('int64')
    layer_rslt_int = torch.tensor(np.right_shift(np.sum(layer_rslt_int,axis=0).astype('int64'), -(RSLT_FRACTIONAL_BITS.value - (WEIGHT_FRACTIONAL_BITS.value + ACT_FRACTIONAL_BITS.value))).astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize result -- with integers
    layer_rslt_intd = layer_rslt_int.to(torch.float32) / 2 ** RSLT_FRACTIONAL_BITS.value
    
    layer_rslt      = layer_rslt.to(device=device, dtype=torch.float64)
    layer_rslt_intd = layer_rslt_intd.to(device=device, dtype=torch.float64)
    
    # Theoretical Device Simulation Bit Error Rate
    theo_dev_sim_ber = torch.sqrt(torch.mean(((layer_rslt_q - layer_rslt_int) ** 2).to(dtype=torch.float64))).cpu().numpy()
    print('Theoretical Device Simulation Bit Error Rate (should be zero):', theo_dev_sim_ber)
    
    # Theoretical Quantization Bit Error Rate
    theo_qber = torch.sqrt(torch.mean(((layer_exp_rslt_q - layer_rslt_int) ** 2).to(dtype=torch.float64))).cpu().numpy()
    print('Theoretical Quantization Bit Error Rate:', theo_qber)
    
    # Theoretical Quantization Error Rate
    theo_qer = torch.sqrt(torch.mean((layer_rslt - layer_rslt_intd) ** 2)).cpu().numpy()
    print('Theoretical Quantization Error Rate:', theo_qer)
    # exit()
    
    # Data, Grid & Scale coordinator
    test_data = layer_data_q.squeeze(-1).cpu().to(final_dtype).tolist()
    test_grid = layer_grid_q.squeeze().cpu().to(final_dtype).tolist()
    test_scle = layer_scle_q.squeeze(0).reshape(-1).cpu().to(final_dtype).tolist() if SCALE_SHARE.value else \
                torch.stack(layer_data_q.reshape(-1).split(DATA_CHANNELS.value,-1)).reshape(-1).cpu().to(final_dtype).tolist()

    # Data Driver
    addr_data   = [module.Integer(f'addr_data_{str(batch).zfill(2)}') for batch in range(K)]
    data_loaded = [module.Reg(f'data_loaded_{str(batch).zfill(2)}') for batch in range(K)]
    
    for batch, test_data_batch in enumerate(test_data):
        ## Data AXI-Lite Driver
        if (DATA_CHANNELS.value == 1):
            data_axil_gen = module.GenerateIf(DATA_CHANNELS == 1)
            
            data_axil_gen.Initial(
                data_loaded[batch](0),
                Wait(reset_done),
                Wait(s_axil_data_aclk[batch]),
                
                Wait(~s_axil_data_aclk[batch]),
                Wait(s_axil_data_aclk[batch]),
                
                # Test 0 : Write Data
                Wait(~s_axil_data_aclk[batch]),
                s_axil_data_wdata[batch](EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}")),
                For(addr_data[batch](0), addr_data[batch] < len(test_data_batch), addr_data[batch].inc())(
                    
                    s_axil_data_awvalid[batch](1),
                    s_axil_data_awaddr[batch](addr_data[batch] * DATA_STRB_WIDTH),
                    
                    s_axil_data_wvalid[batch](1),
                    *find_strobe(s_axil_data_wstrb[batch], s_axil_data_awaddr[batch], DATA_STRB_WIDTH, CLOG_AXIL_STRB_WIDTH),
                    
                    Case(addr_data[batch])(
                        *[
                            When(i)(
                                s_axil_data_wdata[batch].slice(
                                    msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                    lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                )(test_data_batch_i)
                            ) for i, test_data_batch_i in enumerate(test_data_batch)
                        ],
                        When( )(
                            s_axil_data_wdata[batch](EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}"))
                        ),
                    ),
                    
                    While(~s_axil_data_awready[batch])(
                        Wait(s_axil_data_aclk[batch]),
                        Wait(~s_axil_data_aclk[batch]),
                    ),
                    s_axil_data_awvalid[batch](0),
                    
                    While(~s_axil_data_wready[batch])(
                        Wait(s_axil_data_aclk[batch]),
                        Wait(~s_axil_data_aclk[batch]),
                    ),
                    s_axil_data_wvalid[batch](0),
                    
                    s_axil_data_bready[batch](1),
                    While(~s_axil_data_bvalid[batch])(
                        Wait(s_axil_data_aclk[batch]),
                        Wait(~s_axil_data_aclk[batch]),
                    ),
                    AssertFalse(s_axil_data_bresp[batch]),
                    
                    Wait(s_axil_data_aclk[batch]),
                    Wait(~s_axil_data_aclk[batch]),
                    s_axil_data_bready[batch](0),
                ),
                Wait(s_axil_data_aclk[batch]),
                
                # Test 1 : Read & Verify Data
                Wait(~s_axil_data_aclk[batch]),
                s_axil_data_wdata[batch](EmbeddedNumeric("{" f"{AXIL_WIDTH.value}" r"{1'bX}}")),
                For(addr_data[batch](0), addr_data[batch] < len(test_data_batch), addr_data[batch].inc())(
                    Wait(~s_axil_data_aclk[batch]),
                    
                    s_axil_data_arvalid[batch](1),
                    s_axil_data_araddr[batch](addr_data[batch] * DATA_STRB_WIDTH),
                    
                    While(~s_axil_data_arready[batch])(
                        Wait(s_axil_data_aclk[batch]),
                        Wait(~s_axil_data_aclk[batch]),
                    ),
                    s_axil_data_arvalid[batch](0),
                    s_axil_data_rready[batch](1),
                    
                    While(~s_axil_data_rvalid[batch])(
                        Wait(s_axil_data_aclk[batch]),
                        Wait(~s_axil_data_aclk[batch]),
                    ),
                    AssertFalse(s_axil_data_rresp[batch]),
                    Case(addr_data[batch])(
                        *[
                            When(i)(
                                Assert(
                                    s_axil_data_rdata[batch].slice(
                                        msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                        lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                    ),
                                    test_data_batch_i
                                )
                            ) for i, test_data_batch_i in enumerate(test_data_batch)
                        ],
                        When( )(AssertTrue(0)),
                    ),
                    Wait(s_axil_data_aclk[batch]),
                    Wait(~s_axil_data_aclk[batch]),
                    s_axil_data_rready[batch](0),
                ),
                Wait(~s_axil_data_aclk[batch]),
                data_loaded[batch](1),
            )
        
        ## Data Bram Driver
        else :
            data_bram_gen = module.GenerateIf(DATA_CHANNELS > 1)
            
            data_bram_gen.Initial(
                data_loaded[batch](0),
                Wait(reset_done),
                Wait(bram_ctrl_data_clk[batch]),
                
                Wait(~bram_ctrl_data_clk[batch]),
                Wait(bram_ctrl_data_clk[batch]),
                
                # Test 0 : Write Data
                Wait(~bram_ctrl_data_clk[batch]),
                bram_ctrl_data_en[batch](1),
                bram_ctrl_data_din[batch](EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}")),
                For(addr_data[batch](0), Ands(addr_data[batch] < len(test_data_batch),~bram_ctrl_data_rst[batch]), addr_data[batch].inc())(
                    
                    bram_ctrl_data_addr[batch](addr_data[batch] * (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)),
                    
                    *find_strobe(bram_ctrl_data_we[batch], bram_ctrl_data_addr[batch], DATA_STRB_WIDTH, CLOG_BRAM_STRB_WIDTH),
                    bram_ctrl_data_addr[batch](addr_data[batch]),
                    
                    Case(addr_data[batch])(
                        *[
                            When(i)(
                                bram_ctrl_data_din[batch].slice(
                                    msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                    lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                )(test_data_batch_i)
                            ) for i, test_data_batch_i in enumerate(test_data_batch)
                        ],
                        When( )(
                            bram_ctrl_data_din[batch](EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}"))
                        ),
                    ),
                    Display('Test : bram_ctrl_data_din[batch] = ', bram_ctrl_data_din[batch]),
                    Wait(bram_ctrl_data_clk[batch]),
                    Wait(~bram_ctrl_data_clk[batch]),
                ),
                bram_ctrl_data_en[batch](0),
                Wait(bram_ctrl_data_clk[batch]),
                
                # Test 1 : Read & Verify Data
                Wait(~bram_ctrl_data_clk[batch]),
                bram_ctrl_data_en[batch](1),
                bram_ctrl_data_we[batch](0),
                bram_ctrl_data_din[batch](EmbeddedNumeric("{" f"{BRAM_WIDTH.value}" r"{1'bX}}")),
                For(addr_data[batch](0), Ands(addr_data[batch] < len(test_data_batch),~bram_ctrl_data_rst[batch]), addr_data[batch].inc())(

                    bram_ctrl_data_addr[batch](addr_data[batch]),
                    Wait(bram_ctrl_data_clk[batch]),
                    Wait(~bram_ctrl_data_clk[batch]),

                    Case(addr_data[batch])(
                        *[
                            When(i)(
                                Assert(
                                    bram_ctrl_data_dout[batch].slice(
                                        msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                        lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                    ),
                                    test_data_batch_i
                                )
                            ) for i, test_data_batch_i in enumerate(test_data_batch)
                        ],
                        When( )(AssertTrue(0)),
                    ),
                ),
                bram_ctrl_data_en[batch](0),
                Wait(~bram_ctrl_data_clk[batch]),
                data_loaded[batch](1),
            )
            
    data_loaded_int = module.Wire('data_loaded')
    data_loaded_int.assign(Ors(*data_loaded))
    data_loaded     = data_loaded_int
    
    # Grid Driver
    addr_grid = module.Integer('addr_grid')
    grid_loaded = module.Reg('grid_loaded')
    
    ## Grid AXI-Lite Driver
    if (GRID_SHARE.value):
        grid_axil_gen = module.GenerateIf(GRID_SHARE)
        
        grid_axil_gen.Initial(
            grid_loaded(0),
            Wait(reset_done),
            Wait(s_axil_grid_aclk),
            
            Wait(~s_axil_grid_aclk),
            Wait(s_axil_grid_aclk),
            
            # Test 0 : Write Data
            Wait(~s_axil_grid_aclk),
            s_axil_grid_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}")),
            For(addr_grid(0), Ands(addr_grid < len(test_grid),~s_axil_grid_areset), addr_grid.inc())(
                
                s_axil_grid_awvalid(1),
                s_axil_grid_awaddr(addr_grid * DATA_STRB_WIDTH),
                
                s_axil_grid_wvalid(1),
                *find_strobe(s_axil_grid_wstrb, s_axil_grid_awaddr, DATA_STRB_WIDTH, CLOG_AXIL_STRB_WIDTH, True),
                
                Case(addr_grid)(
                    *[
                        When(i)(
                            s_axil_grid_wdata.slice(
                                msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                            )(test_grid_i)
                        ) for i, test_grid_i in enumerate(test_grid)
                    ],
                    When( )(
                        s_axil_grid_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}"))
                    ),
                ),
                
                While(Ands(~s_axil_grid_awready,~s_axil_grid_areset))(
                    Wait(s_axil_grid_aclk),
                    Wait(~s_axil_grid_aclk),
                ),
                s_axil_grid_awvalid(0),
                
                While(Ands(~s_axil_grid_wready,~s_axil_grid_areset))(
                    Wait(s_axil_grid_aclk),
                    Wait(~s_axil_grid_aclk),
                ),
                s_axil_grid_wvalid(0),
                
                s_axil_grid_bready(1),
                While(Ands(~s_axil_grid_bvalid,~s_axil_grid_areset))(
                    Wait(s_axil_grid_aclk),
                    Wait(~s_axil_grid_aclk),
                ),
                AssertFalse(s_axil_grid_bresp),
                
                Wait(s_axil_grid_aclk),
                Wait(~s_axil_grid_aclk),
                s_axil_grid_bready(0),
            ),
            Wait(s_axil_grid_aclk),
            
            # Test 1 : Read & Verify Data
            Wait(~s_axil_grid_aclk),
            s_axil_grid_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH.value}" r"{1'bX}}")),
            For(addr_grid(0), Ands(addr_grid < len(test_grid),~s_axil_grid_areset), addr_grid.inc())(
                Wait(~s_axil_grid_aclk),
                
                s_axil_grid_arvalid(1),
                s_axil_grid_araddr(addr_grid * DATA_STRB_WIDTH),
                
                While(Ands(~s_axil_grid_arready,~s_axil_grid_areset))(
                    Wait(s_axil_grid_aclk),
                    Wait(~s_axil_grid_aclk),
                ),
                s_axil_grid_arvalid(0),
                s_axil_grid_rready(1),
                
                While(Ands(~s_axil_grid_rvalid,~s_axil_grid_areset))(
                    Wait(s_axil_grid_aclk),
                    Wait(~s_axil_grid_aclk),
                ),
                AssertFalse(s_axil_grid_rresp),
                Case(addr_grid)(
                    *[
                        When(i)(
                            Assert(
                                s_axil_grid_rdata.slice(
                                    msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                    lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                ),
                                test_grid_i
                            )
                        ) for i, test_grid_i in enumerate(test_grid)
                    ],
                    When( )(AssertTrue(0)),
                ),
                Wait(s_axil_grid_aclk),
                Wait(~s_axil_grid_aclk),
                s_axil_grid_rready(0),
            ),
            Wait(~s_axil_grid_aclk),
            grid_loaded(1),
        )
    
    ## Grid Bram Driver
    else :
        grid_bram_gen = module.GenerateIf(~GRID_SHARE)
        
        grid_bram_gen.Initial(
            grid_loaded(0),
            Wait(reset_done),
            Wait(bram_ctrl_grid_clk),
            
            Wait(~bram_ctrl_grid_clk),
            Wait(bram_ctrl_grid_clk),
            
            # Test 0 : Write Data
            Wait(~bram_ctrl_grid_clk),
            bram_ctrl_grid_en(1),
            bram_ctrl_grid_din(EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}")),
            For(addr_grid(0), Ands(addr_grid < len(test_grid),~bram_ctrl_grid_rst), addr_grid.inc())(
                
                bram_ctrl_grid_addr(addr_grid),
                
                *find_strobe(bram_ctrl_grid_we, bram_ctrl_grid_addr, DATA_STRB_WIDTH, CLOG_BRAM_STRB_WIDTH),
                
                Case(addr_grid)(
                    *[
                        When(i)(
                            bram_ctrl_grid_din.slice(
                                msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                            )(test_grid_i)
                        ) for i, test_grid_i in enumerate(test_grid)
                    ],
                    When( )(
                        bram_ctrl_grid_din(EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}"))
                    ),
                ),
                Wait(bram_ctrl_grid_clk),
                Wait(~bram_ctrl_grid_clk),
            ),
            bram_ctrl_grid_en(0),
            Wait(bram_ctrl_grid_clk),
            
            # Test 1 : Read & Verify Data
            Wait(~bram_ctrl_grid_clk),
            bram_ctrl_grid_en(1),
            bram_ctrl_grid_we(0),
            bram_ctrl_grid_din(EmbeddedNumeric("{" f"{BRAM_WIDTH.value}" r"{1'bX}}")),
            For(addr_grid(0), Ands(addr_grid < len(test_grid),~bram_ctrl_grid_rst), addr_grid.inc())(

                bram_ctrl_grid_addr(addr_grid * DATA_STRB_WIDTH),
                Wait(bram_ctrl_grid_clk),
                Wait(~bram_ctrl_grid_clk),

                Case(addr_grid)(
                    *[
                        When(i)(
                            Assert(
                                bram_ctrl_grid_dout.slice(
                                    msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                    lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                ),
                                test_grid_i
                            )
                        ) for i, test_grid_i in enumerate(test_grid)
                    ],
                    When( )(AssertTrue(0)),
                ),
            ),
            bram_ctrl_grid_en(0),
            Wait(~bram_ctrl_grid_clk),
            grid_loaded(1),
        )
        
    # Scale Driver
    addr_scle = module.Integer('addr_scle')
    scle_loaded = module.Reg('scle_loaded')
    
    ## Scale AXI-Lite Driver
    if (SCALE_SHARE.value):
        scle_axil_gen = module.GenerateIf(SCALE_SHARE)
        
        scle_axil_gen.Initial(
            scle_loaded(0),
            Wait(reset_done),
            Wait(s_axil_scle_aclk),
            
            Wait(~s_axil_scle_aclk),
            Wait(s_axil_scle_aclk),
            
            # Test 0 : Write Data
            Wait(~s_axil_scle_aclk),
            s_axil_scle_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}")),
            For(addr_scle(0), Ands(addr_scle < len(test_scle),~s_axil_scle_areset), addr_scle.inc())(
                
                s_axil_scle_awvalid(1),
                s_axil_scle_awaddr(addr_scle * DATA_STRB_WIDTH),
                
                s_axil_scle_wvalid(1),
                *find_strobe(s_axil_scle_wstrb, s_axil_scle_awaddr, DATA_STRB_WIDTH, CLOG_AXIL_STRB_WIDTH),
                
                Case(addr_scle)(
                    *[
                        When(i)(
                            s_axil_scle_wdata.slice(
                                msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                            )(test_scle_i)
                        ) for i, test_scle_i in enumerate(test_scle)
                    ],
                    When( )(
                        s_axil_scle_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH}" r"{1'bX}}"))
                    ),
                ),
                
                While(Ands(~s_axil_scle_awready,~s_axil_scle_areset))(
                    Wait(s_axil_scle_aclk),
                    Wait(~s_axil_scle_aclk),
                ),
                s_axil_scle_awvalid(0),
                
                While(Ands(~s_axil_scle_wready,~s_axil_scle_areset))(
                    Wait(s_axil_scle_aclk),
                    Wait(~s_axil_scle_aclk),
                ),
                s_axil_scle_wvalid(0),
                
                s_axil_scle_bready(1),
                While(Ands(~s_axil_scle_bvalid,~s_axil_scle_areset))(
                    Wait(s_axil_scle_aclk),
                    Wait(~s_axil_scle_aclk),
                ),
                AssertFalse(s_axil_scle_bresp),
                
                Wait(s_axil_scle_aclk),
                Wait(~s_axil_scle_aclk),
                s_axil_scle_bready(0),
            ),
            Wait(s_axil_scle_aclk),
            
            # Test 1 : Read & Verify Data
            Wait(~s_axil_scle_aclk),
            s_axil_scle_wdata(EmbeddedNumeric("{" f"{AXIL_WIDTH.value}" r"{1'bX}}")),
            For(addr_scle(0), Ands(addr_scle < len(test_scle),~s_axil_scle_areset), addr_scle.inc())(
                Wait(~s_axil_scle_aclk),
                
                s_axil_scle_arvalid(1),
                s_axil_scle_araddr(addr_scle * DATA_STRB_WIDTH),
                
                While(Ands(~s_axil_scle_arready,~s_axil_scle_areset))(
                    Wait(s_axil_scle_aclk),
                    Wait(~s_axil_scle_aclk),
                ),
                s_axil_scle_arvalid(0),
                s_axil_scle_rready(1),
                
                While(Ands(~s_axil_scle_rvalid,~s_axil_scle_areset))(
                    Wait(s_axil_scle_aclk),
                    Wait(~s_axil_scle_aclk),
                ),
                AssertFalse(s_axil_scle_rresp),
                Case(addr_scle)(
                    *[
                        When(i)(
                            Assert(
                                s_axil_scle_rdata.slice(
                                    msb = ((i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH-1,
                                    lsb =  (i % (AXIL_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                ),
                                test_scle_i
                            )
                        ) for i, test_scle_i in enumerate(test_scle)
                    ],
                    When( )(AssertTrue(0)),
                ),
                Wait(s_axil_scle_aclk),
                Wait(~s_axil_scle_aclk),
                s_axil_scle_rready(0),
            ),
            Wait(~s_axil_scle_aclk),
            scle_loaded(1),
        )
    
    ## Scale Bram Driver
    else :
        scle_bram_gen = module.GenerateIf(~SCALE_SHARE)
        
        scle_bram_gen.Initial(
            scle_loaded(0),
            Wait(reset_done),
            Wait(bram_ctrl_scle_clk),
            
            Wait(~bram_ctrl_scle_clk),
            Wait(bram_ctrl_scle_clk),
            
            # Test 0 : Write Data
            Wait(~bram_ctrl_scle_clk),
            bram_ctrl_scle_en(1),
            bram_ctrl_scle_din(EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}")),
            For(addr_scle(0), Ands(addr_scle < len(test_scle),~bram_ctrl_scle_rst), addr_scle.inc())(
                
                bram_ctrl_scle_addr(addr_scle),
                
                *find_strobe(bram_ctrl_scle_we, bram_ctrl_scle_addr, DATA_STRB_WIDTH, CLOG_BRAM_STRB_WIDTH),
                
                Case(addr_scle)(
                    *[
                        When(i)(
                            bram_ctrl_scle_din.slice(
                                msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                            )(test_scle_i)
                        ) for i, test_scle_i in enumerate(test_scle)
                    ],
                    When( )(
                        bram_ctrl_scle_din(EmbeddedNumeric("{" f"{BRAM_WIDTH}" r"{1'bX}}"))
                    ),
                ),
                Wait(bram_ctrl_scle_clk),
                Wait(~bram_ctrl_scle_clk),
            ),
            bram_ctrl_scle_en(0),
            Wait(bram_ctrl_scle_clk),
            
            # Test 1 : Read & Verify Data
            Wait(~bram_ctrl_scle_clk),
            bram_ctrl_scle_en(1),
            bram_ctrl_scle_we(0),
            bram_ctrl_scle_din(EmbeddedNumeric("{" f"{BRAM_WIDTH.value}" r"{1'bX}}")),
            For(addr_scle(0), Ands(addr_scle < len(test_scle),~bram_ctrl_scle_rst), addr_scle.inc())(

                bram_ctrl_scle_addr(addr_scle * DATA_STRB_WIDTH),
                Wait(bram_ctrl_scle_clk),
                Wait(~bram_ctrl_scle_clk),

                Case(addr_scle)(
                    *[
                        When(i)(
                            Assert(
                                bram_ctrl_scle_dout.slice(
                                    msb = ((i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) + 1) * DATA_WIDTH -1,
                                    lsb =  (i % (BRAM_STRB_WIDTH / DATA_STRB_WIDTH)) * DATA_WIDTH
                                ),
                                test_scle_i
                            )
                        ) for i, test_scle_i in enumerate(test_scle)
                    ],
                    When( )(AssertTrue(0)),
                ),
            ),
            bram_ctrl_scle_en(0),
            Wait(~bram_ctrl_scle_clk),
            scle_loaded(1),
        )
        
    # Weight coordinator
    test_wght = torch.stack( torch.split(torch.cat(torch.split(layer_wght_q,RSLT_CHANNELS.value,1)), DATA_CHANNELS.value,0) ).cpu().to(final_dtype).reshape(-1).tolist()
    
    ## Weight driver
    intra_wght = module.Integer('intra_wght')
    total_wght = module.Integer('total_wght')
    wght_global_stage = module.Integer('wght_global_stage')
    
    module.Initial(
        wght_global_stage(0),
        Wait(reset_done),
        Wait(dma_clk),
        
        Wait(wght_global_stage != global_stage_counter),
        Wait(~dma_clk),
        Wait(dma_clk),
        
        # Test 0 : Load Weights
        While(1)(
            wght_global_stage(global_stage_counter),
            Wait(~dma_clk),
            total_wght(0),
            s_axis_wght_tvalid(1),
            While(Ands(total_wght < len(test_wght), ~dma_rst, wght_global_stage == global_stage_counter))(
                Wait(~dma_clk),
                s_axis_wght_tkeep(0),
                For(intra_wght(0), Ands(intra_wght < (DMA_WIDTH / DATA_WIDTH), total_wght < len(test_wght),~dma_rst, wght_global_stage == global_stage_counter), intra_wght.inc())(
                    Case(total_wght)(
                        *[
                            When(_iter)(
                                s_axis_wght_tdata.slice(
                                    msb = ((_iter % (DMA_WIDTH / DATA_WIDTH))+1) * DATA_WIDTH -1,
                                    lsb =  (_iter % (DMA_WIDTH / DATA_WIDTH)) * DATA_WIDTH
                                )(test_wght_i),
                                s_axis_wght_tkeep.slice(
                                    msb = (_iter % (DMA_WIDTH / DATA_WIDTH) + 1) * DATA_STRB_WIDTH -1,
                                    lsb = (_iter % (DMA_WIDTH / DATA_WIDTH)    ) * DATA_STRB_WIDTH
                                )(-1),
                            ) for _iter, test_wght_i in enumerate(test_wght)
                        ],
                        When( )(AssertTrue(0)),
                    ),
                    total_wght.inc(),
                ),
                s_axis_wght_tlast(total_wght == len(test_wght)-1),
                While(Ands(~s_axis_wght_tready, ~dma_rst, wght_global_stage == global_stage_counter))(
                    Wait(dma_clk),
                    Wait(~dma_clk),
                ),
                Wait(dma_clk),
            ),
            Wait(~dma_clk),
            s_axis_wght_tvalid(0),
            s_axis_wght_tlast(0),
            Wait(dma_clk),
            Wait(~dma_rst),
            Wait(wght_global_stage != global_stage_counter),
            Wait(~dma_clk),
            Wait(dma_clk),
        ),
    )
    
    # Result coordinator
    test_rslt = layer_rslt_int.cpu().to(final_dtype).tolist()
    # print('Test layer_data_q:', layer_data_q.shape)
    # print(np.array(hex_list(layer_data_q.squeeze().cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_grid_q:', layer_grid_q.shape)
    # print(np.array(hex_list(layer_grid_q.squeeze().cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_scle_q:', layer_scle_q.shape)
    # print(np.array(hex_list(layer_scle_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_diff_q:', layer_diff_q.shape)
    # print(np.array(hex_list(layer_diff_q.cpu().numpy().astype('uint32').tolist())))
    # print('Test layer_sdff_q:', layer_sdff_q.shape)
    # print(np.array(hex_list(layer_sdff_q.cpu().numpy().astype('uint16').tolist())))
    # x = torch.einsum("bw,wr->wbr", layer_actd_q, layer_wght_q).cpu().numpy().astype('int64')
    # print('Test layer_actd_q:', layer_actd_q.shape)
    # print(np.array(hex_list(layer_actd_q.to(final_dtype).squeeze().cpu().numpy())))
    # print('Test layer_wght_q:', layer_wght_q.shape)
    # print(np.array(hex_list(layer_wght_q.to(final_dtype).squeeze().cpu().numpy())))
    # print('Test psum')
    # print(*[np.array(hex_list([np.sum(x[offset:2*_iter+offset+1:DATA_CHANNELS.value],axis=0).astype('uint64').tolist() for _iter in range(x.shape[0] // DATA_CHANNELS.value)])) for offset in range(DATA_CHANNELS.value)], sep ='\n')
    # print('Test rslt')
    # print(hex_list( np.right_shift(np.sum(x,axis=0).astype('int64'), -(RSLT_FRACTIONAL_BITS.value - (WEIGHT_FRACTIONAL_BITS.value + ACT_FRACTIONAL_BITS.value))).astype('uint16').tolist() ))

    # Result driver
    rslt_done = module.Reg('rslt_done')
    intra_rslt = module.Integer('intra_rslt')
    total_rslt = [module.Integer(f'total_rslt_{batch}') for batch in range(K)]
    # curr_batch = module.Integer('curr_batch')
    rslt_global_stage = module.Integer('rslt_global_stage')
    update_total = module.Reg('update_total')
    rslt_buffer = module.Reg('rslt_buffer', DATA_WIDTH)
    
    module.Initial(
        rslt_global_stage(0),
        rslt_done(0),
        Wait(reset_done),
        Wait(~dma_clk),
        
        While(1)(
            *[total_rslt_i(0) for total_rslt_i in total_rslt],
            Wait(dma_clk),
            Wait(~dma_clk),
            While(Ands(~rslt_done, ~dma_rst, rslt_global_stage == global_stage_counter))(
                m_axis_rslt_tready(1),
                While(Ands(~m_axis_rslt_tvalid, ~dma_rst, rslt_global_stage == global_stage_counter))(
                    Wait(dma_clk),
                    Wait(~dma_clk),
                ),
                AssertTrue(m_axis_rslt_tkeep != 0),
                If(And(~dma_rst, rslt_global_stage == global_stage_counter))(
                    
                    Display('Rslt -- Caught batch %2d (%0t)', m_axis_rslt_tid, SystemTask('time')),
                    AssertTrue(m_axis_rslt_tid < K),
                    Case(m_axis_rslt_tid)(*[
                        When(batch)(
                            AssertTrue(total_rslt_i < rslt_len),
                            For(
                                intra_rslt(0), Ands(
                                    intra_rslt < DMA_STRB_WIDTH, Ors(*[
                                        total_rslt_j < rslt_len
                                            for total_rslt_j in total_rslt
                                    ]),
                                    total_rslt_i < rslt_len
                                ), 
                                intra_rslt.inc()
                            )(
                                update_total(1),
                                For(rslt_buffer(rslt_buffer), update_total, rslt_buffer((m_axis_rslt_tkeep >> (intra_rslt * DATA_STRB_WIDTH) & EmbeddedNumeric("{DATA_STRB_WIDTH{1'b1}}"))))(
                                    update_total(0),
                                ),
                                # Display("DEBUG: KEEP %h >> %2d = %h -> %b", m_axis_rslt_tkeep, (intra_rslt * DATA_STRB_WIDTH), m_axis_rslt_tkeep >> (intra_rslt * DATA_STRB_WIDTH), rslt_buffer),
                                Case(total_rslt_i)(*[
                                    When(i)(
                                        If(rslt_buffer == EmbeddedNumeric("{DATA_STRB_WIDTH{1'b1}}"))(
                                            AssertTrue(total_rslt_i < rslt_len),
                                            update_total(1),
                                            For(rslt_buffer(rslt_buffer), update_total, rslt_buffer(m_axis_rslt_tdata >> (intra_rslt * DATA_WIDTH)))(
                                                update_total(0),
                                            ),
                                    Display("DEBUG: DATA %h >> %2d = %h -> %h", m_axis_rslt_tdata, (intra_rslt * DATA_WIDTH), m_axis_rslt_tdata >> (intra_rslt * DATA_WIDTH), rslt_buffer),
                                            AssertAbsDiffLE(rslt_buffer, test_rslt_i,1),
                                            Display('Rslt -- Batch %2d -- Captured %3d -- PASSED', batch, total_rslt_i),
                                            If((total_rslt_i % RSLT_CHANNELS) == RSLT_CHANNELS-1)(
                                                AssertTrue(m_axis_rslt_tlast),
                                            ).Elif(intra_rslt == DMA_STRB_WIDTH - 1)(
                                                AssertFalse(m_axis_rslt_tlast),
                                            ),
                                            update_total(1),
                                        ) 
                                    ) for i, test_rslt_i in enumerate(test_rslt_batch)
                                ], When()(AssertTrue(0))
                                ),
                                For(total_rslt_i(total_rslt_i), update_total, total_rslt_i.inc())(
                                    update_total(0),
                                ),
                            ),
                            Display('Total after iteration : %3d', total_rslt_i),
                            
                        ) for batch, (total_rslt_i, test_rslt_batch) in enumerate(zip(total_rslt, test_rslt))
                    ], When()(AssertTrue(0))
                    ),
                ),
                Wait(dma_clk),
                Wait(~dma_clk),
                If(Ands(*[total_rslt_i == rslt_len for total_rslt_i in total_rslt]))(
                    rslt_done(1),
                    m_axis_rslt_tready(0),
                ),
            ),
            Wait(~rslt_done),
            Wait(~dma_rst),
            Wait(rslt_global_stage != global_stage_counter),
            rslt_global_stage(global_stage_counter),
        )
    )

    # Central Controller Driver
    ctrl_buffer = module.Integer('ctrl_buffer')
    ctrl_iter_buffer = module.Integer('ctrl_iter_buffer')
    
    def control_wr_seq(REG_NAME, value, value_size):
        return (
            s_axil_ctrl_awvalid(1),
            s_axil_ctrl_awaddr(ctrl_reg[REG_NAME]),
            s_axil_ctrl_wvalid(1),
            s_axil_ctrl_wdata(value << ((ctrl_reg[REG_NAME] % AXIL_CTRL_STRB_WIDTH)*8)),
            *find_strobe(s_axil_ctrl_wstrb,s_axil_ctrl_awaddr,value_size,CLOG_AXIL_CTRL_STRB_WIDTH),
                    
            While(~s_axil_ctrl_awready)(
                Wait(fsm_clk),
                Wait(~fsm_clk),
            ),
            # Display('s_axil_ctrl_wstrb : %b -- %2d',s_axil_ctrl_wstrb, value_size),
            s_axil_ctrl_awvalid(0),
            
            While(~s_axil_ctrl_wready)(
                Wait(fsm_clk),
                Wait(~fsm_clk),
            ),
            s_axil_ctrl_wvalid(0),
            
            s_axil_ctrl_bready(1),
            While(~s_axil_ctrl_bvalid)(
                Wait(fsm_clk),
                Wait(~fsm_clk),
            ),
            AssertFalse(s_axil_ctrl_bresp),
            
            Wait(fsm_clk),
            Wait(~fsm_clk),
            s_axil_ctrl_bready(0),
        )
        
    def control_rd_seq(REG_NAME, out, value_size):
        return (
            s_axil_ctrl_arvalid(1),
            s_axil_ctrl_araddr(ctrl_reg[REG_NAME]),
                    
            While(~s_axil_ctrl_arready)(
                Wait(fsm_clk),
                Wait(~fsm_clk),
            ),
            s_axil_ctrl_arvalid(0),
            s_axil_ctrl_rready(1),
            While(~s_axil_ctrl_rvalid)(
                Wait(fsm_clk),
                Wait(~fsm_clk),
            ),
            # Display('Ctrl read : %h >> %2d = %h', s_axil_ctrl_rdata, ((ctrl_reg[REG_NAME] % AXIL_CTRL_STRB_WIDTH)*8), (s_axil_ctrl_rdata >> ((ctrl_reg[REG_NAME] % AXIL_CTRL_STRB_WIDTH)*8))),
            out((s_axil_ctrl_rdata >> ((ctrl_reg[REG_NAME] % AXIL_CTRL_STRB_WIDTH)*8)) & EmbeddedNumeric("{" f'{value_size*8}' r"{1'b1}}")),
            
            Wait(fsm_clk),
            # Display('Ctrl read out : %h', out),
            Wait(~fsm_clk),
            s_axil_ctrl_rready(0),
        )
    
    scle_len_reduced = scale_len[0]*scale_len[1]*scale_len[2]  
    module.Initial(
        global_stage_counter(0),
        Wait(reset_done),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        
        # Test 0: Write Registers
        AssertFalse(Cat(operation_busy, operation_complete, operation_error)),
        *control_wr_seq('CTRL_REG_DATA_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_GRID_LEN', grid_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_SCLE_LEN', scle_len_reduced, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_RSLT_LEN', rslt_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_PCKT_LEN', (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value)), AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_BTCH_LEN', BATCH_SIZE, 1),
        *control_wr_seq('CTRL_REG_DATA_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_GRID_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_SCLE_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_WGHT_LDR', 1, 1),
        Display('-- Control Test 0 complete.'),
        
        # Test 1: Read Registers
        *control_rd_seq('CTRL_REG_DATA_LEN', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
        AssertFalse(ctrl_buffer),
        *control_rd_seq('CTRL_REG_GRID_LEN', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
        Assert(ctrl_buffer, grid_len),
        *control_rd_seq('CTRL_REG_SCLE_LEN', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
        Assert(ctrl_buffer, scle_len_reduced),
        *control_rd_seq('CTRL_REG_RSLT_LEN', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
        Assert(ctrl_buffer, rslt_len),
        *control_rd_seq('CTRL_REG_PCKT_LEN', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
        Assert(ctrl_buffer, pckt_len ),
        *control_rd_seq('CTRL_REG_BTCH_LEN', ctrl_buffer, 1),
        Assert(ctrl_buffer, BATCH_SIZE),
        *control_rd_seq('CTRL_REG_DATA_LDR', ctrl_buffer, 1),
        Assert(ctrl_buffer, 1),
        *control_rd_seq('CTRL_REG_GRID_LDR', ctrl_buffer, 1),
        Assert(ctrl_buffer, 1),
        *control_rd_seq('CTRL_REG_SCLE_LDR', ctrl_buffer, 1),
        Assert(ctrl_buffer, 1),
        Display('-- Control Test 1 complete.'),
        
        # Test 2: Check invalid configuration -- Data len = 0
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 2 complete.'),
        
        # Test 3: Run invalid configuration & interrupt core
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(pl2ps_intr),
        AssertTrue(operation_error),
        AssertTrue(locked),
        AssertFalse(Cat(operation_busy,operation_complete)),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        *control_rd_seq('CTRL_REG_OPER_STR', ctrl_buffer, 1),   # Register should be null in error state 
        AssertFalse(ctrl_buffer),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK']),
        *control_wr_seq('CTRL_REG_INTR_REG', ctrl_reg['CTRL_REG_INTR_MASK_SFT'], 1),
        *control_rd_seq('CTRL_REG_OPER_STR', ctrl_buffer, 1),
        AssertFalse(ctrl_buffer),
        AssertFalse(Cat(operation_busy,operation_complete,operation_error,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_INTR_REG', 0, 1),
        Display('-- Control Test 3 complete.'),
        
        # Test 4: Check invalid configuration -- Data len = 2**DATA_ADDR_BYTES+1
        *control_wr_seq('CTRL_REG_DATA_LEN', 2**DATA_ADDR_BYTES+1, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_DATA_LEN', data_len, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 4 complete.'),
        
        # Test 5: Check invalid configuration -- Grid len = 0
        *control_wr_seq('CTRL_REG_GRID_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 5 complete.'),
        
        # Test 6: Check invalid configuration -- Grid len = 2**GRID_ADDR_BYTES+1
        *control_wr_seq('CTRL_REG_GRID_LEN', 2**GRID_ADDR_BYTES+1, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_GRID_LEN', grid_len, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 6 complete.'),
        
        # Test 7: Check invalid configuration -- Scale len = 0
        *control_wr_seq('CTRL_REG_SCLE_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 7 complete.'),
        
        # Test 8: Check invalid configuration -- Scale len = 2**SCALE_ADDR_BYTES+1
        *control_wr_seq('CTRL_REG_SCLE_LEN', 2**SCALE_ADDR_BYTES+1, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_SCLE_LEN', scle_len_reduced, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 8 complete.'),
        
        # Test 9: Check invalid configuration -- Packet len = 0
        *control_wr_seq('CTRL_REG_PCKT_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 9 complete.'),
        
        # Test 10: Check invalid configuration -- Packet len = 2**(DATA_ADDR_BYTES + GRID_ADDR_BYTES)+1
        *control_wr_seq('CTRL_REG_PCKT_LEN', 2**(DATA_ADDR_BYTES + GRID_ADDR_BYTES)+1, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_PCKT_LEN', pckt_len, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 10 complete.'),
        
        # Test 11: Check invalid configuration -- Result size = 0
        *control_wr_seq('CTRL_REG_RSLT_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_RSLT_LEN', rslt_len, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 11 complete.'),
        
        # Test 12: Check invalid configuration -- Batch size = 0
        *control_wr_seq('CTRL_REG_BTCH_LEN', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 12 complete.'),
        
        # Test 13: Check invalid configuration -- Batch size = K+1
        *control_wr_seq('CTRL_REG_BTCH_LEN', K+1, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_BTCH_LEN', K, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 13 complete.'),
        
        # Test 14: Check invalid configuration -- Data not loaded
        *control_wr_seq('CTRL_REG_DATA_LDR', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('Waiting data...'),
        Wait(data_loaded),
        *control_wr_seq('CTRL_REG_DATA_LDR', 1, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 14 complete.'),
        
        # Test 15: Check invalid configuration -- Grid not loaded
        *control_wr_seq('CTRL_REG_GRID_LDR', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('Waiting grid...'),
        Wait(grid_loaded),
        *control_wr_seq('CTRL_REG_GRID_LDR', 1, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 15 complete.'),
        
        # Test 16: Check invalid configuration -- Scale not loaded
        *control_wr_seq('CTRL_REG_SCLE_LDR', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('Waiting scale...'),
        Wait(scle_loaded),
        *control_wr_seq('CTRL_REG_SCLE_LDR', 1, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 16 complete.'),
        
        # Test 17: Check invalid configuration -- Weights not loaded
        *control_wr_seq('CTRL_REG_WGHT_LDR', 0, AXIL_CTRL_STRB_WIDTH),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        *control_wr_seq('CTRL_REG_WGHT_LDR', 1, AXIL_CTRL_STRB_WIDTH),
        Display('-- Control Test 17 complete.'),
        
        # Test 18: Check valid configuration
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        Display('-- Control Test 18 complete.'),
        
        # Test 19: Test external error
        global_stage_counter.inc(),
        Display('Test 19 start...'),
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(operation_busy),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        AssertFalse(Cat(operation_error,operation_complete,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        If(rslt_len > RSLT_CHANNELS)(
            Display('-- Waiting for PL interrupt...'),
            Wait(pl2ps_intr),
        ).Else(
            Display('-- Waiting for time to pass...'),
            For(ctrl_buffer(0),ctrl_buffer < data_len, ctrl_buffer.inc())(
                Wait(~fsm_clk),
                Wait(fsm_clk),
            ),
        ),
        Display('-- Hit external error'),
        *control_wr_seq('CTRL_REG_INTR_REG', ctrl_reg['CTRL_REG_INTR_MASK_ERR'], 1),
        AssertTrue(operation_error),
        AssertFalse(Cat(operation_busy,operation_complete,locked)),
        Wait(~core_rst),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        ctrl_buffer(ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']),
        While(ctrl_buffer & ctrl_reg['CTRL_REG_OPER_STS_MASK_RST'])(
            *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
            Wait(~fsm_clk),
            Wait(fsm_clk),
        ),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR']),
        *control_wr_seq('CTRL_REG_INTR_REG', 0, 1),
        Display('-- Unset external error'),
        AssertFalse(Cat(operation_busy,operation_complete,operation_error,locked)),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
        Display('-- Control Test 19 complete.'),
        
        
        # Test 20: Test interrupt abort
        global_stage_counter.inc(),
        *control_wr_seq('CTRL_REG_DATA_LEN', data_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_GRID_LEN', grid_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_SCLE_LEN', scle_len_reduced, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_RSLT_LEN', rslt_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_PCKT_LEN', (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value)), AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_BTCH_LEN', K, 1),
        *control_wr_seq('CTRL_REG_DATA_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_GRID_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_SCLE_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_WGHT_LDR', 1, 1),
        Display('Test 20 start...'),
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(operation_busy),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        AssertFalse(Cat(operation_error,operation_complete,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        If(rslt_len > RSLT_CHANNELS)(
            Display('-- Waiting for PL interrupt...'),
            Wait(pl2ps_intr),
        ).Else(
            Display('-- Waiting for time to pass...'),
            For(ctrl_buffer(0),ctrl_buffer < (weight_len //  (DMA_STRB_WIDTH / DATA_STRB_WIDTH)) // 2, ctrl_buffer.inc())(
                Wait(~fsm_clk),
                Wait(fsm_clk),
            ),
        ),
        Display('-- Hit interrupt abort'),
        *control_wr_seq('CTRL_REG_INTR_REG', ctrl_reg['CTRL_REG_INTR_MASK_ABT'], 1),
        AssertFalse(Cat(operation_busy,operation_complete,operation_error,locked)),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        *control_wr_seq('CTRL_REG_INTR_REG', 0, 1),
        AssertFalse(Cat(operation_busy,operation_complete,operation_error,locked)),
        Wait(~core_rst),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        Display('-- Control Test 20 complete.'),
        
        # Test 21: Test interrupt soft
        global_stage_counter.inc(),
        Display('Test 21 start...'),
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(operation_busy),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        AssertFalse(Cat(operation_error,operation_complete,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        If(rslt_len > RSLT_CHANNELS)(
            Display('-- Waiting for PL interrupt...'),
            Wait(pl2ps_intr),
        ).Else(
            Display('-- Waiting for time to pass...'),
            For(ctrl_buffer(0),ctrl_buffer < (weight_len //  (DMA_STRB_WIDTH / DATA_STRB_WIDTH)) // 4, ctrl_buffer.inc())(
                Wait(~fsm_clk),
                Wait(fsm_clk),
            ),
        ),
        Display('-- Hit interrupt soft'),
        *control_wr_seq('CTRL_REG_INTR_REG', ctrl_reg['CTRL_REG_INTR_MASK_SFT'], 1),
        If(rslt_len / RSLT_CHANNELS == 1)( # Validate Nominal operation on the next test
            Wait(~fsm_clk),
            Wait(fsm_clk),
            Display('-- Waiting for results...'),
            Wait(rslt_done),
            Wait(~fsm_clk),
            rslt_done(0),
        ).Else(
            AssertTrue(operation_busy),
            AssertFalse(Cat(operation_complete,operation_error,locked)),
            Wait(~fsm_clk),
            Wait(fsm_clk),
            *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
            Assert(ctrl_buffer & (
                ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']
            ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
            *control_wr_seq('CTRL_REG_INTR_REG', 0, 1),
            AssertTrue(operation_busy),
            AssertFalse(Cat(operation_complete,operation_error,locked)),
            Wait(~fsm_clk),
            Wait(fsm_clk),
            *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
            Assert(ctrl_buffer & (
                ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']
            ), (ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] )),
            
            If(rslt_len // RSLT_CHANNELS == 2)(
                Display('-- Waiting for PL interrupt...'),
                Wait(pl2ps_intr),
                AssertTrue(operation_complete),
                AssertFalse(Cat(operation_busy,operation_error,locked)),
                *control_rd_seq('CTRL_REG_OPER_DNE', ctrl_buffer, 1),
                Assert(ctrl_buffer,1),
                Display('-- Waiting for rslt_done...'),
                Wait(rslt_done),
                Wait(~fsm_clk),
                rslt_done(0),
                *control_wr_seq('CTRL_REG_OPER_DNE', 0, 1),
                
            ).Else(
                Display('-- Waiting for PL interrupt...'),
                Wait(pl2ps_intr),
                AssertTrue(operation_busy),
                AssertFalse(Cat(operation_complete,operation_error,locked)),
            ),
            Display('-- Waiting core reset...'),
            For(ctrl_iter_buffer(0), Ands(ctrl_iter_buffer < 10, ~core_rst), ctrl_iter_buffer.inc())(
                Wait(~fsm_clk),
                Wait(fsm_clk),
            ),
            If(ctrl_iter_buffer == 10)(
              Display('-- Core reset not captured. Assuming core_rst happend in earlier time.'),
            ),
            Wait(~core_rst),
            Wait(~fsm_clk),
            Wait(fsm_clk),
            *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
            If(rslt_len / RSLT_CHANNELS <= 2)( 
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] ),
            ).Else(
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] ),
            ),
        ),
        Display('-- Control Test 21 complete.'),
        rslt_done(0),
        
        ## Fix operation valid for next test
        *control_wr_seq('CTRL_REG_DATA_LEN', data_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_GRID_LEN', grid_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_SCLE_LEN', scle_len_reduced, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_RSLT_LEN', rslt_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_PCKT_LEN', (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value)), AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_BTCH_LEN', K, 1),
        *control_wr_seq('CTRL_REG_DATA_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_GRID_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_SCLE_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_WGHT_LDR', 1, 1),
        
        # Test 22: Test nominal
        global_stage_counter.inc(),
        Display('Test 22 start...'),
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(operation_busy),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        AssertFalse(Cat(operation_error,operation_complete,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        ## Iterate until no results left
        Wait(rslt_global_stage == global_stage_counter),
        While(rslt_global_stage == global_stage_counter)( 
            Display('-- Waiting for PL interrupt...'),
            Wait(pl2ps_intr),
            *control_rd_seq('CTRL_REG_RSLT_PRG', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
            AssertTrue(ctrl_buffer > 0),
            AssertTrue(ctrl_buffer <= rslt_len),
            *control_rd_seq('CTRL_REG_ITER_PRG', ctrl_iter_buffer, AXIL_CTRL_STRB_WIDTH),
            Assert(ctrl_iter_buffer, ctrl_buffer // RSLT_CHANNELS - 1),
            Display('-- Iteration %2d done', ctrl_iter_buffer),
            Display('-- Results done = %3d', ctrl_buffer),
            If(ctrl_buffer == rslt_len)(
                Display('-- Final iteration'),
                Wait(~fsm_clk),
                Wait(fsm_clk),
                Assert(ctrl_buffer, rslt_len),
                AssertTrue(operation_complete),
                AssertTrue(locked),
                AssertFalse(Cat(operation_error,operation_busy)),
                Wait(~fsm_clk),
                Wait(fsm_clk),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK']),
                *control_rd_seq('CTRL_REG_OPER_DNE', ctrl_buffer, 1),
                Assert(ctrl_buffer, 1),
                Display('-- Waiting Result Done'),
                Wait(rslt_done),
                Wait(~fsm_clk),
                rslt_done(0),
                *control_wr_seq('CTRL_REG_OPER_DNE', 0, 1),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
                global_stage_counter.inc(),
            ).Else(
                AssertTrue(operation_busy),
                AssertFalse(Cat(operation_error,operation_complete,locked)),
                Wait(~pl2ps_intr),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
            ),
        ),
        Display('-- Control Test 22 complete.'),
        rslt_done(0),
        
        ## Fix operation valid for next test
        *control_wr_seq('CTRL_REG_DATA_LEN', data_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_GRID_LEN', grid_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_SCLE_LEN', scle_len_reduced, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_RSLT_LEN', rslt_len, AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_PCKT_LEN', (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value)), AXIL_CTRL_STRB_WIDTH),
        *control_wr_seq('CTRL_REG_BTCH_LEN', K, 1),
        *control_wr_seq('CTRL_REG_DATA_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_GRID_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_SCLE_LDR', 1, 1),
        *control_wr_seq('CTRL_REG_WGHT_LDR', 1, 1),
        
        # Test 23: Test nominal -- 2nd iteration
        Display('Test 23 start...'),
        *control_wr_seq('CTRL_REG_OPER_STR', 1, 1),
        Wait(operation_busy),
        Wait(~fsm_clk),
        Wait(fsm_clk),
        Wait(~fsm_clk),
        AssertFalse(Cat(operation_error,operation_complete,locked)),
        *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
        Assert(ctrl_buffer & (
            ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
        ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
            ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
        ## Iterate until no results left
        Wait(rslt_global_stage == global_stage_counter),
        While(rslt_global_stage == global_stage_counter)( 
            Display('-- Waiting for PL interrupt...'),
            Wait(pl2ps_intr),
            *control_rd_seq('CTRL_REG_RSLT_PRG', ctrl_buffer, AXIL_CTRL_STRB_WIDTH),
            AssertTrue(ctrl_buffer > 0),
            AssertTrue(ctrl_buffer <= rslt_len),
            *control_rd_seq('CTRL_REG_ITER_PRG', ctrl_iter_buffer, AXIL_CTRL_STRB_WIDTH),
            Assert(ctrl_iter_buffer, ctrl_buffer // RSLT_CHANNELS - 1),
            Display('-- Iteration %2d done', ctrl_iter_buffer),
            Display('-- Results done = %3d', ctrl_buffer),
            If(ctrl_buffer == rslt_len)(
                Display('-- Final iteration'),
                Wait(~fsm_clk),
                Wait(fsm_clk),
                Assert(ctrl_buffer, rslt_len),
                AssertTrue(operation_complete),
                AssertTrue(locked),
                AssertFalse(Cat(operation_error,operation_busy)),
                Wait(~fsm_clk),
                Wait(fsm_clk),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK']),
                *control_rd_seq('CTRL_REG_OPER_DNE', ctrl_buffer, 1),
                Assert(ctrl_buffer, 1),
                Display('-- Waiting Result Done'),
                Wait(rslt_done),
                Wait(~fsm_clk),
                rslt_done(0),
                *control_wr_seq('CTRL_REG_OPER_DNE', 0, 1),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL']),
                global_stage_counter.inc(),
            ).Else(
                AssertTrue(operation_busy),
                AssertFalse(Cat(operation_error,operation_complete,locked)),
                Wait(~pl2ps_intr),
                *control_rd_seq('CTRL_REG_OPER_STS', ctrl_buffer, 1),
                Assert(ctrl_buffer & (
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_IDL'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_ERR'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_LCK'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_RST']
                ),  ctrl_reg['CTRL_REG_OPER_STS_MASK_BSY'] |
                    ctrl_reg['CTRL_REG_OPER_STS_MASK_VLD']),
            ),
        ),
        Display('-- Control Test 23 complete.'),
        Display('!! ALL TEST COMPLETED !!'),
        
        Delay(20),
        Finish(),
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)
    
    os.chdir(os.path.join(TOP_DIR,'rtl'))
    
    for I,J,K in (
        # (1,1,1),
        # (1,2,1),
        # (8,1,1),
        # (1,1,3),
        (2,2,1),
        # (2,2,2),
        # (2,3,1),
        # (4,2,1),
        # (4,4,1),
        # (4,4,4),
        # (8,4,2),
    ):
        N_in, N_out = 24,24
        # N_in, N_out = J,2*I
        test = tb_KanLayer(I=I,J=J,K=K,N_in=N_in,N_out=N_out)
        fname_base = f'tb_KanLayer_{I}_{J}_{K}_{N_in}_{N_out}'
        fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'tb_kan_layer_wrapper')
        addTimeScale(fname)
        # exit()

        os.system(' '.join([
            os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
            '-v',
            '-p',
            fname_base,
        ]))

if __name__ == "__main__":
    main()
