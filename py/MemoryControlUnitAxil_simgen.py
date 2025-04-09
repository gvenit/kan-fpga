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

from py import addTimeScale, stripModule
    
def MemoryControlUnitAxil():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/MCUWrapperAxil.v')
    )['MCUWrapperAxil'] 

def AxilRegisterIfRd():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/axil_reg_if_rd_wrapper.v')
    )['axil_reg_if_rd_wrapper'] 

def DummyBRAM():
    module = Module('DummyBRAM')
    WIDTH = module.Parameter('WIDTH',8)
    
    bram_clk        = module.Input('bram_clk')
    bram_en         = module.Input('bram_en')
    bram_addr       = module.Input('bram_addr',WIDTH)
    bram_rddata     = module.Output('bram_rddata',WIDTH)
    bram_rdack      = module.Output('bram_rdack')
    
    data_reg = module.Reg('data_reg', WIDTH)
    ack_reg  = module.Reg('ack_reg')
    
    module.Initial(
        data_reg(0),
        ack_reg(0),
    )
    
    module.Always(Posedge(bram_clk))(
        If(bram_en)(
            data_reg(bram_addr)
        ),
        ack_reg(bram_en),
    )
    module.Assign(bram_rddata(data_reg))
    module.Assign(bram_rdack(ack_reg))
    return module

def tb_MemoryControlUnitAxil(J=1,K=1):
    module = Module(f'tb_MemoryControlUnitAxil_{J}_{K}')
    
    
    module.EmbeddedCode('`define DATA_IF_IS_AXIL')
    module.EmbeddedCode('`define GRID_IF_IS_AXIL')
    module.EmbeddedCode('`define SCALE_IF_IS_AXIL')

    mcu = MemoryControlUnitAxil()
    params = module.copy_params_as_localparams(mcu)
    ports  = module.copy_ports_as_vars(mcu)

    DATA_WIDTH      : Localparam = params['DATA_WIDTH_DATA']
    DATA_CHANNELS   : Localparam = params['DATA_CHANNELS']
    BATCH_SIZE      : Localparam = params['BATCH_SIZE']
    SHARE_GRID      : Localparam = params['SHARE_GRID']
    SHARE_SCALE     : Localparam = params['SHARE_SCALE']
    ADDR_WIDTH      : Localparam = DATA_WIDTH

    DATA_CHANNELS.value = J
    BATCH_SIZE.value  = K

    SHARE_SCALE.value = 1
    SHARE_GRID.value  = 1
    DATA_WIDTH.value  = 8
    
    params['DATA_WIDTH_SCALE'].value = DATA_WIDTH
    params['ADDR_WIDTH_DATA'].value  = DATA_WIDTH
    params['ADDR_WIDTH_GRID'].value  = DATA_WIDTH
    params['ADDR_WIDTH_SCALE'].value = DATA_WIDTH
    WIDTH = module.LocalparamLike(DATA_WIDTH, 'WIDTH')
    
    CONGESTION_LEVEL = module.Localparam('CONGESTION_LEVEL', 5)
    
    reset_done = module.Reg('reset_done', initval=0)
    
    clk = ports['fsm_clk']
    rst = ports['rst']
    
    operation_start         = ports['operation_start']
    data_size               = ports['data_size']
    grid_size               = ports['grid_size']
    scle_size               = ports['scle_size']
    
    operation_busy          = ports['operation_busy']
    operation_complete      = ports['operation_complete']
    operation_error         = ports['operation_error']
    
    m_axil_d_aclk           = ports['m_axil_data_aclk']
    m_axil_d_araddr         = ports['m_axil_data_araddr']
    m_axil_d_arprot         = ports['m_axil_data_arprot']
    m_axil_d_arvalid        = ports['m_axil_data_arvalid']
    m_axil_d_arready        = module.WireLike(ports['m_axil_data_arready'], 'm_axil_data_arready_wire')
    m_axil_d_rdata          = module.WireLike(ports['m_axil_data_rdata'], 'm_axil_data_rdata_wire')
    m_axil_d_rresp          = module.WireLike(ports['m_axil_data_rresp'], 'm_axil_data_rresp_wire')
    m_axil_d_rvalid         = module.WireLike(ports['m_axil_data_rvalid'], 'm_axil_data_rvalid_wire')
    m_axil_d_rready         = ports['m_axil_data_rready']
    
    ports['m_axil_data_arready'] = m_axil_d_arready
    ports['m_axil_data_rdata']   = m_axil_d_rdata
    ports['m_axil_data_rresp']   = m_axil_d_rresp
    ports['m_axil_data_rvalid']  = m_axil_d_rvalid
    
    m_axil_g_aclk           = ports['m_axil_grid_aclk']
    m_axil_g_araddr         = ports['m_axil_grid_araddr']
    m_axil_g_arprot         = ports['m_axil_grid_arprot']
    m_axil_g_arvalid        = ports['m_axil_grid_arvalid']
    m_axil_g_arready        = module.WireLike(ports['m_axil_grid_arready'], 'm_axil_grid_arready_wire')
    m_axil_g_rdata          = module.WireLike(ports['m_axil_grid_rdata'], 'm_axil_grid_rdata_wire')
    m_axil_g_rresp          = module.WireLike(ports['m_axil_grid_rresp'], 'm_axil_grid_rresp_wire')
    m_axil_g_rvalid         = module.WireLike(ports['m_axil_grid_rvalid'], 'm_axil_grid_rvalid_wire')
    m_axil_g_rready         = ports['m_axil_grid_rready']
    
    ports['m_axil_grid_arready'] = m_axil_g_arready
    ports['m_axil_grid_rdata']   = m_axil_g_rdata
    ports['m_axil_grid_rresp']   = m_axil_g_rresp
    ports['m_axil_grid_rvalid']  = m_axil_g_rvalid
    
    m_axil_s_aclk           = ports['m_axil_scle_aclk']
    m_axil_s_araddr         = ports['m_axil_scle_araddr']
    m_axil_s_arprot         = ports['m_axil_scle_arprot']
    m_axil_s_arvalid        = ports['m_axil_scle_arvalid']
    m_axil_s_arready        = module.WireLike(ports['m_axil_scle_arready'], 'm_axil_scle_arready_wire')
    m_axil_s_rdata          = module.WireLike(ports['m_axil_scle_rdata'], 'm_axil_scle_rdata_wire')
    m_axil_s_rresp          = module.WireLike(ports['m_axil_scle_rresp'], 'm_axil_scle_rresp_wire')
    m_axil_s_rvalid         = module.WireLike(ports['m_axil_scle_rvalid'], 'm_axil_scle_rvalid_wire')
    m_axil_s_rready         = ports['m_axil_scle_rready']
    
    ports['m_axil_scle_arready'] = m_axil_s_arready
    ports['m_axil_scle_rdata']   = m_axil_s_rdata
    ports['m_axil_scle_rresp']   = m_axil_s_rresp
    ports['m_axil_scle_rvalid']  = m_axil_s_rvalid
    
    m_axis_d_aclk           = ports['m_axis_data_aclk']
    m_axis_d_tdata          = ports['m_axis_data_tdata']
    m_axis_d_tlast          = ports['m_axis_data_tlast']
    m_axis_d_tvalid         = ports['m_axis_data_tvalid']
    m_axis_d_tready         = ports['m_axis_data_tready']

    m_axis_g_aclk           = ports['m_axis_grid_aclk']
    m_axis_g_tdata          = ports['m_axis_grid_tdata']
    m_axis_g_tlast          = ports['m_axis_grid_tlast']
    m_axis_g_tvalid         = ports['m_axis_grid_tvalid']
    m_axis_g_tready         = ports['m_axis_grid_tready']

    m_axis_s_aclk           = ports['m_axis_scle_aclk']
    m_axis_s_tdata          = ports['m_axis_scle_tdata']
    m_axis_s_tlast          = ports['m_axis_scle_tlast']
    m_axis_s_tvalid         = ports['m_axis_scle_tvalid']
    m_axis_s_tready         = ports['m_axis_scle_tready']
    
    uut = module.Instance(
        mcu,
        'uut',
        params,
        ports
    )
    reset_stmt = []
    reset_stmt.append(reset_done(0))
    reset_stmt.append(operation_start(0))
    reset_stmt.append(data_size(0))
    reset_stmt.append(grid_size(0))
    reset_stmt.append(scle_size(0))
    
    reset_stmt.append(m_axis_d_tready(0))
    reset_stmt.append(m_axis_s_tready(0))
    reset_stmt.append(m_axis_g_tready(0))

    vcd_name = os.path.join(TOP_DIR,'vcd',f'tb_MemoryControlUnitAxil_{J}_{K}.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=10)
    init = simulation.setup_reset(module, rst, reset_stmt, period=40)

    nclk = simulation.next_clock
    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        m_axis_d_tready(1),
        Delay(50000),
        # Delay(10),
        Systask('finish'),
    )
    
    module.EmbeddedCode(
    '''`define assert(signal, value) \
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
    `define abs(signal) ($signed(signal) < 0) ? -$signed(signal) : signal
    `define assertAbsDiffLE(signal0, signal1, value) \
    if ( `abs(signal0-signal1) > value) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- ABS(%s-%s) > %s",`"signal0`",`"signal1`",`"value`"); \
        $display("---- %s = 0x%h",`"signal0`",signal0); \
        $display("---- %s = 0x%h",`"signal1`",signal1); \
        $display("---- Abs Diff = 0x%h",`abs(signal0-signal1)); \
        $display("---- %s = 0x%h",`"value`",value); \
        #5 \
        $finish; \
    end
    ''')
    def Assert(signal,value):
        return EmbeddedCode(f'`assert({signal},{value})')
    def AssertTrue(signal):
        return EmbeddedCode(f'`assertTrue({signal})')
    def AssertAbsDiffLE(signal0,signal1,value):
        return EmbeddedCode(f'`assertAbsDiffLE({signal0},{signal1},{value})')
    
    max_data_len = 4
    max_grid_len = 8
    max_scle_len = 1
    
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0.0 : Invalid data size (0)
        Wait(~clk),
        operation_start(1),
        data_size(0),
        grid_size(1),
        scle_size(1),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        # Test 0.1 : Invalid data size (max+1)
        Wait(~clk),
        operation_start(1),
        data_size(2**ADDR_WIDTH+1),
        grid_size(1),
        scle_size(1),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        
        # Test 1.0 : Invalid grid size (0)
        Wait(~clk),
        operation_start(1),
        data_size(1),
        grid_size(0),
        scle_size(1),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        # Test 1.1 : Invalid grid size (max+1)
        Wait(~clk),
        operation_start(1),
        data_size(1),
        grid_size(2**ADDR_WIDTH+1),
        scle_size(1),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        # Test 2.0 : Invalid scale size (0)
        Wait(~clk),
        operation_start(1),
        data_size(1),
        grid_size(1),
        scle_size(0),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        # Test 2.1 : Invalid scale size (max+1)
        Wait(~clk),
        operation_start(1),
        data_size(1),
        grid_size(1),
        scle_size(2**ADDR_WIDTH+1),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_error),
        While(operation_error)(
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_complete),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Nominal Operation with conjestion (all streams)
        Wait(~clk),
        operation_start(1),
        data_size(max_data_len),
        grid_size(max_grid_len),
        scle_size(max_scle_len),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_busy),
        Wait(~clk),
        While(operation_busy)(
            AssertTrue(~operation_error),
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_error),
        AssertTrue(operation_complete),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Nominal Operation with conjestion (single stream)
        Wait(~clk),
        operation_start(1),
        data_size(max_data_len),
        grid_size(max_grid_len),
        scle_size(max_scle_len),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_busy),
        Wait(~clk),
        While(operation_busy)(
            AssertTrue(~operation_error),
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_error),
        AssertTrue(operation_complete),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        
        
        # Test 5 : Nominal Operation with no conjestion
        Wait(~clk),
        operation_start(1),
        data_size(max_data_len),
        grid_size(max_grid_len),
        scle_size(max_scle_len),
        Wait(clk),
        Wait(~clk),
        operation_start(0),
        data_size(0),
        grid_size(0),
        scle_size(0),
        
        Wait(operation_busy),
        Wait(~clk),
        While(operation_busy)(
            AssertTrue(~operation_error),
            AssertTrue(~operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertTrue(~operation_error),
        AssertTrue(operation_complete),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        
        Delay(10),
        Finish(),
    )

    # Generate Variables
    chn_data = module.Genvar('chn_data')
    chn_batch = module.Genvar('chn_batch')
    
    # Data Bram instances
    per_chn_data = module.GenerateFor(chn_data(0), chn_data < DATA_CHANNELS, chn_data(chn_data+1))
    per_chn_data_batch = per_chn_data.GenerateFor(chn_batch(0), chn_batch < BATCH_SIZE, chn_batch(chn_batch+1))
    LFT_POS = per_chn_data_batch.Localparam('LFT_POS', chn_batch * DATA_CHANNELS + chn_data)
    
    conj_counter = per_chn_data_batch.Integer('conj_counter')
    data_counter = per_chn_data_batch.Integer('data_counter')
    iter_counter = per_chn_data_batch.Integer('iter_counter')
    
    ## Data Clock Driver
    loc_clk = m_axil_d_aclk[LFT_POS]
    simulation.setup_clock(per_chn_data_batch, loc_clk, hperiod=10 / (LFT_POS+2))
    
    ## Data Axi-Lite Bram Controller
    addr_slice = m_axil_d_araddr.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    prot_slice = m_axil_d_arprot.slice(
        msb = (LFT_POS+1)*3-1,
        lsb = LFT_POS * 3
    )
    data_slice = m_axil_d_rdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    resp_slice = m_axil_d_rresp.slice(
        msb = (LFT_POS+1)*2-1,
        lsb = LFT_POS * 2
    )
    axil_reg = AxilRegisterIfRd()
    axil_reg_params = per_chn_data_batch.copy_params_as_localparams(axil_reg,'per_chn_data_batch_')
    axil_reg_params = per_chn_data_batch.connect_params(axil_reg,'per_chn_data_batch_')
    axil_reg_params['DATA_WIDTH'].value = axil_reg_params['ADDR_WIDTH'].value = DATA_WIDTH
    axil_reg_ports = per_chn_data_batch.copy_ports_as_vars(axil_reg,'per_chn_data_batch_',exclude=['clk','rst'],use_wire=True)
    
    ### Data Axi-Lite Bram Controller Axi-Lite Interface
    axil_reg_ports['per_chn_data_batch_s_axil_araddr'].connect(addr_slice)
    axil_reg_ports['per_chn_data_batch_s_axil_arprot'].connect(prot_slice)
    axil_reg_ports['per_chn_data_batch_s_axil_arvalid'].connect(m_axil_d_arvalid[LFT_POS])
    axil_reg_ports['per_chn_data_batch_s_axil_rready'].connect(m_axil_d_rready[LFT_POS])
    
    per_chn_data_batch.Assign(m_axil_d_arready[LFT_POS](axil_reg_ports['per_chn_data_batch_s_axil_arready']))
    per_chn_data_batch.Assign(data_slice(axil_reg_ports['per_chn_data_batch_s_axil_rdata']))
    per_chn_data_batch.Assign(resp_slice(axil_reg_ports['per_chn_data_batch_s_axil_rresp']))
    per_chn_data_batch.Assign(m_axil_d_rvalid[LFT_POS](axil_reg_ports['per_chn_data_batch_s_axil_rvalid']))
    
    axil_reg_ports['per_chn_data_batch_reg_rd_wait'].connect(0)
    
    per_chn_data_batch.Instance(
        axil_reg,
        'data_axil_reg_if_rd_inst',
        { 'DATA_WIDTH' : DATA_WIDTH, 'ADDR_WIDTH' : ADDR_WIDTH },
        [loc_clk, rst, *axil_reg_ports.values()]
    )
    
    ## Data Bram 
    bram = DummyBRAM()
    bram_ports = per_chn_data_batch.copy_ports_as_vars(bram,use_wire=True)
    
    ### Data Bram Controller Interface
    bram_ports['bram_clk'].connect(loc_clk)
    bram_ports['bram_en'].connect(axil_reg_ports['per_chn_data_batch_reg_rd_en'])
    bram_ports['bram_addr'].connect(axil_reg_ports['per_chn_data_batch_reg_rd_addr'])
    axil_reg_ports['per_chn_data_batch_reg_rd_data'].connect(bram_ports['bram_rddata'])
    axil_reg_ports['per_chn_data_batch_reg_rd_ack'].connect(bram_ports['bram_rdack'])

    per_chn_data_batch.Instance(
        bram,
        'data_bram_inst',
        { 'WIDTH' : WIDTH },
        bram_ports
    )
    
    # Data Axi-Stream Controller
    loc_clk = m_axis_d_aclk[LFT_POS]
    data_slice = m_axis_d_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    per_chn_data_batch.Initial(
        Wait(reset_done),
        Wait(loc_clk),
        
        # Test 0.0 : Invalid data size (0)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 0.1 : Invalid data size (max+1)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.0 : Invalid grid size (0)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.1 : Invalid grid size (max+1)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.0 : Invalid scale size (0)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.1 : Invalid scale size (max+1)
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 3 : Nominal Operation with conjestion (all streams)
        Wait(~loc_clk),
        For(iter_counter(0), iter_counter < max_grid_len, iter_counter(iter_counter+1))(
            For(data_counter(0), data_counter < max_data_len, data_counter(data_counter+1))(
                m_axis_d_tready[LFT_POS](0),
                For(conj_counter(0), conj_counter < CONGESTION_LEVEL, conj_counter(conj_counter+1))(
                    While(~m_axis_d_tvalid[LFT_POS])(
                        Wait(loc_clk),
                        Wait(~loc_clk),
                    ),
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                m_axis_d_tready[LFT_POS](1),
                Assert(data_slice, data_counter),
                Assert(m_axis_d_tlast[LFT_POS], Ands(data_counter == max_data_len-1, iter_counter == max_grid_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_d_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 4 : Nominal Operation with conjestion (single stream)
        #       -- No conjestion for data
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](1),
        For(iter_counter(0), iter_counter < max_grid_len, iter_counter(iter_counter+1))(
            For(data_counter(0), data_counter < max_data_len, data_counter(data_counter+1))(
                While(~m_axis_d_tvalid[LFT_POS])(
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                Assert(data_slice, data_counter),
                Assert(m_axis_d_tlast[LFT_POS], Ands(data_counter == max_data_len-1, iter_counter == max_grid_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_d_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 5 : Nominal Operation with no conjestion
        Wait(~loc_clk),
        m_axis_d_tready[LFT_POS](1),
        For(iter_counter(0), iter_counter < max_grid_len, iter_counter(iter_counter+1))(
            For(data_counter(0), data_counter < max_data_len, data_counter(data_counter+1))(
                While(~m_axis_d_tvalid[LFT_POS])(
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                Assert(data_slice, data_counter),
                Assert(m_axis_d_tlast[LFT_POS], Ands(data_counter == max_data_len-1, iter_counter == max_grid_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_d_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
    )
    
    # Grid Bram instances
    if_grid = per_chn_data.GenerateIf(Ors(~SHARE_GRID, chn_data == 0))
    LFT_POS = if_grid.Localparam('LFT_POS',chn_data)
    
    conj_counter = if_grid.Integer('conj_counter')
    data_counter = if_grid.Integer('data_counter')
    iter_counter = if_grid.Integer('iter_counter')
    
    loc_clk = m_axil_g_aclk[LFT_POS]
    simulation.setup_clock(if_grid, loc_clk, hperiod=10 / (LFT_POS+2))
    
    ## Grid Axi-Lite Bram Controller
    addr_slice = m_axil_g_araddr.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    prot_slice = m_axil_g_arprot.slice(
        msb = (LFT_POS+1)*3-1,
        lsb = LFT_POS * 3
    )
    data_slice = m_axil_g_rdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    resp_slice = m_axil_g_rresp.slice(
        msb = (LFT_POS+1)*2-1,
        lsb = LFT_POS * 2
    )
    axil_reg = AxilRegisterIfRd()
    axil_reg_params = if_grid.copy_params_as_localparams(axil_reg,'if_grid_')
    axil_reg_params = if_grid.connect_params(axil_reg,'if_grid_')
    axil_reg_params['DATA_WIDTH'].value = axil_reg_params['ADDR_WIDTH'].value = DATA_WIDTH
    axil_reg_ports = if_grid.copy_ports_as_vars(axil_reg,'if_grid_',exclude=['clk','rst'],use_wire=True)
    
    ### Grid Axi-Lite Bram Controller Axi-Lite Interface
    axil_reg_ports['if_grid_s_axil_araddr'].connect(addr_slice)
    axil_reg_ports['if_grid_s_axil_arprot'].connect(prot_slice)
    axil_reg_ports['if_grid_s_axil_arvalid'].connect(m_axil_g_arvalid[LFT_POS])
    axil_reg_ports['if_grid_s_axil_rready'].connect(m_axil_g_rready[LFT_POS])
    
    if_grid.Assign(m_axil_g_arready[LFT_POS](axil_reg_ports['if_grid_s_axil_arready']))
    if_grid.Assign(data_slice(axil_reg_ports['if_grid_s_axil_rdata']))
    if_grid.Assign(resp_slice(axil_reg_ports['if_grid_s_axil_rresp']))
    if_grid.Assign(m_axil_g_rvalid[LFT_POS](axil_reg_ports['if_grid_s_axil_rvalid']))
    
    axil_reg_ports['if_grid_reg_rd_wait'].connect(0)
    
    if_grid.Instance(
        axil_reg,
        'grid_axil_reg_if_rd_inst',
        { 'DATA_WIDTH' : DATA_WIDTH, 'ADDR_WIDTH' : ADDR_WIDTH },
        [loc_clk, rst, *axil_reg_ports.values()]
    )
    
    ## Grid Bram 
    bram = DummyBRAM()
    bram_ports = if_grid.copy_ports_as_vars(bram,use_wire=True)

    ### Grid Bram Controller Interface
    bram_ports['bram_clk'].connect(loc_clk)
    bram_ports['bram_en'].connect(axil_reg_ports['if_grid_reg_rd_en'])
    bram_ports['bram_addr'].connect(axil_reg_ports['if_grid_reg_rd_addr'])
    axil_reg_ports['if_grid_reg_rd_data'].connect(bram_ports['bram_rddata'])
    axil_reg_ports['if_grid_reg_rd_ack'].connect(bram_ports['bram_rdack'])

    if_grid.Instance(
        bram,
        'grid_bram_inst',
        { 'WIDTH' : WIDTH },
        bram_ports
    )
    
    # Grid Axi-Stream Controller
    loc_clk = m_axis_g_aclk[LFT_POS]
    data_slice = m_axis_g_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    if_grid.Initial(
        Wait(reset_done),
        Wait(loc_clk),
        
        # Test 0.0 : Invalid data size (0)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 0.1 : Invalid data size (max+1)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.0 : Invalid grid size (0)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.1 : Invalid grid size (max+1)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.0 : Invalid scale size (0)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.1 : Invalid scale size (max+1)
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 3 : Nominal Operation with conjestion (all streams)
        Wait(~loc_clk),
        For(data_counter(0), data_counter < max_grid_len, data_counter(data_counter+1))(
            For(iter_counter(0), iter_counter < max_data_len, iter_counter(iter_counter+1))(
                m_axis_g_tready[LFT_POS](0),
                For(conj_counter(0), conj_counter < CONGESTION_LEVEL, conj_counter(conj_counter+1))(
                    While(~m_axis_g_tvalid[LFT_POS])(
                        Wait(loc_clk),
                        Wait(~loc_clk),
                    ),
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                m_axis_g_tready[LFT_POS](1),
                Assert(data_slice, data_counter),
                Assert(m_axis_g_tlast[LFT_POS], Ands(data_counter == max_grid_len-1,iter_counter == max_data_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_g_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 4 : Nominal Operation with conjestion (single stream)
        #       -- No conjestion for grid
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](1),
        For(data_counter(0), data_counter < max_grid_len, data_counter(data_counter+1))(
            For(iter_counter(0), iter_counter < max_data_len, iter_counter(iter_counter+1))(
                While(~m_axis_g_tvalid[LFT_POS])(
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                Assert(data_slice, data_counter),
                Assert(m_axis_g_tlast[LFT_POS], Ands(data_counter == max_grid_len-1,iter_counter == max_data_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_g_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 5 : Nominal Operation with no conjestion
        Wait(~loc_clk),
        m_axis_g_tready[LFT_POS](1),
        For(data_counter(0), data_counter < max_grid_len, data_counter(data_counter+1))(
            For(iter_counter(0), iter_counter < max_data_len, iter_counter(iter_counter+1))(
                While(~m_axis_g_tvalid[LFT_POS])(
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                Assert(data_slice, data_counter),
                Assert(m_axis_g_tlast[LFT_POS], Ands(data_counter == max_grid_len-1,iter_counter == max_data_len-1)),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
        ),
        m_axis_g_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
    )
    
    # Scale Bram instances
    if_scle = per_chn_data.GenerateIf(Ors(~SHARE_SCALE, chn_data == 0))
    LFT_POS = if_scle.Localparam('LFT_POS',chn_data)
    
    conj_counter = if_scle.Integer('conj_counter')
    data_counter = if_scle.Integer('data_counter')
    
    loc_clk    = m_axil_s_aclk[LFT_POS]
    simulation.setup_clock(if_scle, loc_clk, hperiod=10 / (LFT_POS+2))
    
    ## Scale Axi-Lite Bram Controller
    addr_slice = m_axil_s_araddr.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    prot_slice = m_axil_s_arprot.slice(
        msb = (LFT_POS+1)*3-1,
        lsb = LFT_POS * 3
    )
    data_slice = m_axil_s_rdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    resp_slice = m_axil_s_rresp.slice(
        msb = (LFT_POS+1)*2-1,
        lsb = LFT_POS * 2
    )
    axil_reg = AxilRegisterIfRd()
    axil_reg_params = if_scle.copy_params_as_localparams(axil_reg,'if_scle_')
    axil_reg_params = if_scle.connect_params(axil_reg,'if_scle_')
    axil_reg_params['DATA_WIDTH'].value = axil_reg_params['ADDR_WIDTH'].value = DATA_WIDTH
    axil_reg_ports = if_scle.copy_ports_as_vars(axil_reg,'if_scle_',exclude=['clk','rst'],use_wire=True)
    
    ### Scale Axi-Lite Bram Controller Axi-Lite Interface
    axil_reg_ports['if_scle_s_axil_araddr'].connect(addr_slice)
    axil_reg_ports['if_scle_s_axil_arprot'].connect(prot_slice)
    axil_reg_ports['if_scle_s_axil_arvalid'].connect(m_axil_s_arvalid[LFT_POS])
    axil_reg_ports['if_scle_s_axil_rready'].connect(m_axil_s_rready[LFT_POS])
    
    if_scle.Assign(m_axil_s_arready[LFT_POS](axil_reg_ports['if_scle_s_axil_arready']))
    if_scle.Assign(data_slice(axil_reg_ports['if_scle_s_axil_rdata']))
    if_scle.Assign(resp_slice(axil_reg_ports['if_scle_s_axil_rresp']))
    if_scle.Assign(m_axil_s_rvalid[LFT_POS](axil_reg_ports['if_scle_s_axil_rvalid']))
    
    axil_reg_ports['if_scle_reg_rd_wait'].connect(0)
    
    if_scle.Instance(
        axil_reg,
        'scle_axil_reg_if_rd_inst',
        axil_reg_params,
        [loc_clk, rst, *axil_reg_ports.values()]
    )
    
    ## Scale Bram 
    bram = DummyBRAM()
    bram_ports = if_scle.copy_ports_as_vars(bram,use_wire=True)

    ### Scale Bram Controller Interface
    bram_ports['bram_clk'].connect(loc_clk)
    bram_ports['bram_en'].connect(axil_reg_ports['if_scle_reg_rd_en'])
    bram_ports['bram_addr'].connect(axil_reg_ports['if_scle_reg_rd_addr'])
    axil_reg_ports['if_scle_reg_rd_data'].connect(bram_ports['bram_rddata'])
    axil_reg_ports['if_scle_reg_rd_ack'].connect(bram_ports['bram_rdack'])

    if_scle.Instance(
        bram,
        'scle_bram_inst',
        { 'WIDTH' : WIDTH },
        bram_ports
    )
    
    # Scale Axi-Stream Controller
    loc_clk = m_axis_s_aclk[LFT_POS]
    data_slice = m_axis_s_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    if_scle.Initial(
        Wait(reset_done),
        Wait(loc_clk),
        
        # Test 0.0 : Invalid data size (0)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 0.1 : Invalid data size (max+1)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.0 : Invalid grid size (0)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 1.1 : Invalid grid size (max+1)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.0 : Invalid scale size (0)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 2.1 : Invalid scale size (max+1)
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        Wait(operation_error),
        Wait(~operation_error),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 3 : Nominal Operation with conjestion (all streams)
        Wait(~loc_clk),
        For(data_counter(0), data_counter < max_scle_len, data_counter(data_counter+1))(
            m_axis_s_tready[LFT_POS](0),
            For(conj_counter(0), conj_counter < CONGESTION_LEVEL, conj_counter(conj_counter+1))(
                While(~m_axis_s_tvalid[LFT_POS])(
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
            Wait(~loc_clk),
            m_axis_s_tready[LFT_POS](1),
            Assert(data_slice, data_counter),
            Assert(m_axis_s_tlast[LFT_POS], data_counter == max_scle_len-1),
            Wait(loc_clk),
            Wait(~loc_clk),
        ),
        m_axis_s_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 4 : Nominal Operation with conjestion (single stream)
        #       -- Conjestion for scale LFT_POS == 0
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](0),
        For(data_counter(0), data_counter < max_scle_len, data_counter(data_counter+1))(
            If(LFT_POS == 0)(
                m_axis_s_tready[LFT_POS](0),
                For(conj_counter(0), conj_counter < CONGESTION_LEVEL, conj_counter(conj_counter+1))(
                    While(~m_axis_s_tvalid[LFT_POS])(
                        Wait(loc_clk),
                        Wait(~loc_clk),
                    ),
                    Wait(loc_clk),
                    Wait(~loc_clk),
                ),
            ),
            m_axis_s_tready[LFT_POS](1),
            While(~m_axis_s_tvalid[LFT_POS])(
                Wait(~loc_clk),
                Wait(loc_clk),
            ),
            Assert(data_slice, data_counter),
            Assert(m_axis_s_tlast[LFT_POS], data_counter == max_scle_len-1),
            Wait(loc_clk),
            Wait(~loc_clk),
        ),
        m_axis_s_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
        
        # Test 5 : Nominal Operation with no conjestion
        Wait(~loc_clk),
        m_axis_s_tready[LFT_POS](1),
        For(data_counter(0), data_counter < max_scle_len, data_counter(data_counter+1))(
            While(~m_axis_s_tvalid[LFT_POS])(
                Wait(loc_clk),
                Wait(~loc_clk),
            ),
            Assert(data_slice, data_counter),
            Assert(m_axis_s_tlast[LFT_POS], data_counter == max_scle_len-1),
            Wait(loc_clk),
            Wait(~loc_clk),
        ),
        m_axis_s_tready[LFT_POS](0),
        Wait(~loc_clk),
        Wait(loc_clk),
    )
    
    return module

def main():
    os.chdir(TOP_DIR)
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    module : Module = DummyBRAM()
    fname = os.path.join(TOP_DIR,'rtl/DummyBRAM.v')
    verilog = module.to_verilog(fname)
    stripModule(fname, 'DummyBRAM')
    addTimeScale(fname)

    # module : Module = MemoryControlUnitAxil()
    # # fname = os.path.join(TOP_DIR,'rtl/MemoryControlUnit.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'MCUWrapperBram')
    # addTimeScale(fname)
    # exit()
    
    # module : Module = MemoryControlUnitAxil()
    # # fname = os.path.join(TOP_DIR,'rtl/MemoryControlUnit.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'MCUWrapperAxil')
    # addTimeScale(fname)
    # exit()
    
    for J,K in (
        (1,1),
        # (4,2),
    ):
        test = tb_MemoryControlUnitAxil(J=J,K=K)
        fname_base = f'tb_MemoryControlUnitAxil_{J}_{K}'
        fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'MemoryControlUnit')
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
