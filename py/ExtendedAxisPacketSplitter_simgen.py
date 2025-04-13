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
    
def ExtendedAxisPacketSplitter():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/wrapper/ExtendedAxisPacketSplitterWrapper.v')
    )['ExtendedAxisPacketSplitterWrapper'] 
    
def tb_ExtendedAxisPacketSplitter(channels=1):
    module = Module(f'tb_ExtendedAxisPacketSplitter_{channels}')
    
    eaps = ExtendedAxisPacketSplitter()
    params = module.copy_params_as_localparams(eaps)
    ports  = module.copy_ports_as_vars(eaps)

    DATA_WIDTH              : Localparam = params['DATA_WIDTH']
    CHANNELS                : Localparam = params['CHANNELS']
    RAISE_NON_DIVISIBLE     : Localparam = params['RAISE_NON_DIVISIBLE']

    CHANNELS.value = channels
    DATA_WIDTH.value  = 8
    
    CONGESTION_LEVEL = module.Localparam('CONGESTION_LEVEL', 5)
    
    reset_done = module.Reg('reset_done', initval=0)
    
    clk = ports['clk']
    rst = ports['rst']
    
    operation_start         = ports['operation_start']
    pckt_size             = ports['pckt_size']
    
    external_error          = ports['external_error']
    
    operation_busy          = ports['operation_busy']
    operation_complete      = ports['operation_complete']
    operation_error         = ports['operation_error']
    
    s_axis_tdata          = ports['s_axis_tdata']
    s_axis_tlast          = ports['s_axis_tlast']
    s_axis_tvalid         = ports['s_axis_tvalid']
    s_axis_tready         = ports['s_axis_tready']
    
    m_axis_tdata          = ports['m_axis_tdata']
    m_axis_tlast          = ports['m_axis_tlast']
    m_axis_tvalid         = ports['m_axis_tvalid']
    m_axis_tready         = ports['m_axis_tready']

    uut = module.Instance(
        eaps,
        'uut',
        params,
        ports
    )
    reset_stmt = []
    reset_stmt.append(reset_done(0))
    reset_stmt.append(operation_start(0))
    reset_stmt.append(pckt_size(0))
    reset_stmt.append(external_error(0))
    
    reset_stmt.append(m_axis_tready(0))

    vcd_name = os.path.join(TOP_DIR,'vcd',f'tb_ExtendedAxisPacketSplitter_{channels}.vcd')
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
        Delay(5000),
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
    `define assertFalse(signal) \
    if (signal) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s is not False",`"signal`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
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
    
    max_pkt_len = 12
    pkt_len_0 = 5
    pkt_len_1 = 3
    pkt_len_2 = 6
    pkt_len_3 = 2
    
    cong_counter = module.Integer('glo_cong_counter')
    
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        operation_start(0),
        pckt_size(0),
        Wait(clk),
        
        For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter.inc())(
            Wait(~clk),
            AssertFalse(operation_busy),
            AssertFalse(operation_complete),
            AssertFalse(operation_error),
            Wait(clk),
        ),
        Wait(~clk),
        external_error(1),
        Wait(clk),
        Wait(~clk),
        external_error(0),
        Wait(operation_error),
        AssertFalse(operation_busy),
        AssertFalse(operation_complete),
        Wait(~operation_error),
        Wait(~clk),
        
        # Test 1 : Non divisible packet
        Wait(~clk),
        operation_start(1),
        pckt_size(pkt_len_0),
        Wait(clk),
        Wait(~clk),
        
        operation_start(1),
        pckt_size(pkt_len_1),
        AssertTrue(operation_busy),
        AssertFalse(operation_complete),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        pckt_size(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        Assert(operation_error,RAISE_NON_DIVISIBLE),
        Assert(operation_complete,RAISE_NON_DIVISIBLE < 1),
        If(RAISE_NON_DIVISIBLE)(
            Wait(~operation_error),
        ).Else(
            Wait(~operation_complete),
        ),
        
        # Test 2 : Divisible packet with congestion
        Wait(~clk),
        operation_start(1),
        pckt_size(pkt_len_1),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        pckt_size(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        Wait(~operation_complete),
        
        # Test 3 : Divisible packet (different packet size) with data sparcity
        Wait(~clk),
        operation_start(1),
        pckt_size(pkt_len_2),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        pckt_size(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        
        # Test 4 : Divisible packet (different packet size) with max throughput
        Wait(~clk),
        operation_start(1),
        pckt_size(pkt_len_3),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        pckt_size(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        Wait(~operation_complete),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        
        Delay(10),
        Finish(),
    )

    # Generate Variables
    chn = module.Genvar('CHN')
    
    # Data Axi-Stream instances
    per_chn = module.GenerateFor(chn(0), chn < CHANNELS, chn.inc())
    
    # Data Axi-Stream Input Controller
    data_counter = per_chn.Integer('data_counter_in')
    cong_counter = per_chn.Integer('cong_counter_in')
    data_slice = s_axis_tdata.slice(
        msb = (chn+1)*DATA_WIDTH-1,
        lsb = chn * DATA_WIDTH
    )
    per_chn.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        s_axis_tvalid[chn](1),
        s_axis_tlast[chn](0),
        While(~operation_error)(
            AssertFalse(s_axis_tready[chn]),
            Wait(~clk),
            Wait(clk),
        ),
        s_axis_tvalid[chn](0),
        s_axis_tlast[chn](0),
        Wait(~operation_error),
        Wait(~clk),
        Wait(clk),
        
        # Test 1 : Non divisible packet
        Wait(~clk),
        s_axis_tvalid[chn](1),
        s_axis_tlast[chn](0),
        For(data_counter(0), Ors(data_counter < max_pkt_len, operation_error), data_counter.inc())(
            Wait(~clk),
            While(~Ors(s_axis_tready[chn],operation_error))(
                Wait(clk),
                Wait(~clk),
            ),
            data_slice(data_counter*(chn+1)),
            s_axis_tlast[chn](data_counter == max_pkt_len-1),
            Wait(clk),
        ),
        Wait(~clk),
        s_axis_tvalid[chn](0),
        s_axis_tlast[chn](0),
        Wait(clk),
        
        # Test 2 : Divisible packet with congestion
        Wait(~clk),
        For(data_counter(0), Ors(data_counter < max_pkt_len, operation_error), data_counter.inc())(
            s_axis_tvalid[chn](1),
            While(~Ors(s_axis_tready[chn],operation_error))(
                Wait(clk),
                Wait(~clk),
            ),
            data_slice(data_counter*(chn+1)),
            s_axis_tlast[chn](data_counter == max_pkt_len-1),
            Wait(clk),
            Wait(~clk),
        ),
        s_axis_tvalid[chn](0),
        s_axis_tlast[chn](0),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Divisible packet (different packet size) with data sparcity
        Wait(~clk),
        For(data_counter(0), Ors(data_counter < max_pkt_len, operation_error), data_counter.inc())(
            s_axis_tvalid[chn](0),
            For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter.inc())(
                While(~Ors(s_axis_tready[chn],operation_error))(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
                Wait(~clk),
            ),
            s_axis_tvalid[chn](1),
            data_slice(data_counter*(chn+1)),
            s_axis_tlast[chn](data_counter == max_pkt_len-1),
            Wait(clk),
            Wait(~clk),
        ),
        s_axis_tvalid[chn](0),
        s_axis_tlast[chn](0),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Divisible packet (different packet size) with max throughput
        Wait(~clk),
        s_axis_tvalid[chn](1),
        For(data_counter(0), Ors(data_counter < max_pkt_len, operation_error), data_counter.inc())(
            While(~Ors(s_axis_tready[chn],operation_error))(
                Wait(clk),
                Wait(~clk),
            ),
            data_slice(data_counter*(chn+1)),
            s_axis_tlast[chn](data_counter == max_pkt_len-1),
            Wait(clk),
            Wait(~clk),
        ),
        s_axis_tvalid[chn](0),
        s_axis_tlast[chn](0),
        Wait(~clk),
        Wait(clk),
    )
    
    # Data Axi-Stream Output Controller
    data_counter = per_chn.Integer('data_counter_out')
    cong_counter = per_chn.Integer('cong_counter_out')
    data_slice = m_axis_tdata.slice(
        msb = (chn+1)*DATA_WIDTH-1,
        lsb = chn * DATA_WIDTH
    )
    per_chn.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        m_axis_tready[chn](1),
        While(~operation_error)(
            AssertFalse(m_axis_tvalid[chn]),
            Wait(~clk),
            Wait(clk),
        ),
        m_axis_tready[chn](0),
        Wait(~operation_error),
        Wait(~clk),
        Wait(clk),
        
        # Test 1 : Non divisible packet
        Wait(~clk),
        m_axis_tready[chn](1),
        For(data_counter(0), data_counter < max_pkt_len, data_counter(data_counter+1))(
            m_axis_tready[chn](0),
            While(~m_axis_tvalid[chn])(
                Wait(clk),
                Wait(~clk),
            ),
            m_axis_tready[chn](1),
            Assert(data_slice, data_counter*(chn+1)),
            Assert(m_axis_tlast[chn], Ors(data_counter%pkt_len_0 == pkt_len_0-1, data_counter == max_pkt_len-1)),
            Wait(clk),
            Wait(~clk),
        ),
        m_axis_tready[chn](0),
        Wait(~clk),
        Wait(clk),
        
        # Test 2 : Divisible packet with congestion
        Wait(~clk),
        For(data_counter(0), data_counter < max_pkt_len, data_counter(data_counter+1))(
            m_axis_tready[chn](0),
            For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter(cong_counter+1))(
                While(~m_axis_tvalid[chn])(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
                Wait(~clk),
            ),
            m_axis_tready[chn](1),
            Assert(data_slice, data_counter*(chn+1)),
            Assert(m_axis_tlast[chn], data_counter%pkt_len_1 == pkt_len_1-1),
            Wait(clk),
            Wait(~clk),
        ),
        m_axis_tready[chn](0),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Divisible packet (different packet size) with data sparcity
        Wait(~clk),
        m_axis_tready[chn](1),
        For(data_counter(0), data_counter < max_pkt_len, data_counter(data_counter+1))(
            m_axis_tready[chn](0),
            While(~m_axis_tvalid[chn])(
                Wait(clk),
                Wait(~clk),
            ),
            m_axis_tready[chn](1),
            Assert(data_slice, data_counter*(chn+1)),
            Assert(m_axis_tlast[chn], data_counter%pkt_len_2 == pkt_len_2-1),
            Wait(clk),
            Wait(~clk),
        ),
        m_axis_tready[chn](0),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Divisible packet (different packet size) with max throughput
        Wait(~clk),
        m_axis_tready[chn](1),
        For(data_counter(0), data_counter < max_pkt_len, data_counter(data_counter+1))(
            m_axis_tready[chn](0),
            While(~m_axis_tvalid[chn])(
                Wait(clk),
                Wait(~clk),
            ),
            m_axis_tready[chn](1),
            Assert(data_slice, data_counter*(chn+1)),
            Assert(m_axis_tlast[chn], data_counter%pkt_len_3 == pkt_len_3-1),
            Wait(clk),
            Wait(~clk),
        ),
        m_axis_tready[chn](0),
        Wait(~clk),
        Wait(clk),
    )
    
    return module

def main():
    os.chdir(TOP_DIR)
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module : Module = ExtendedAxisPacketSplitter()
    # # fname = os.path.join(TOP_DIR,'rtl/MemoryControlUnit.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'MCUWrapperBram')
    # addTimeScale(fname)
    # exit()
    
    for channels in (
        1,
        4,
    ):
        test = tb_ExtendedAxisPacketSplitter(channels)
        fname_base = f'tb_ExtendedAxisPacketSplitter_{channels}'
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
