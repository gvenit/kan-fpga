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

def DataSplitter():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/DataSplitter.v')
    )['DataSplitter'] 

def tb_DataSplitter():
    module = Module('tb_DataSplitter')

    dataSplitter = DataSplitter()
    params = module.copy_params_as_localparams(dataSplitter)
    ports  = module.copy_ports_as_vars(dataSplitter)

    DATA_WIDTH      : Localparam = params['OUTPUT_DATA_WIDTH']
    CHANNELS        : Localparam = params['CHANNELS']
    EXTRA_CYCLE     : Localparam = params['EXTRA_CYCLE']

    DATA_WIDTH.value = 8
    CHANNELS.value = 6
    EXTRA_CYCLE.value = 1
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_tdata    = ports['s_axis_tdata']
    s_axis_tkeep    = ports['s_axis_tkeep']
    s_axis_tvalid   = ports['s_axis_tvalid']
    s_axis_tready   = ports['s_axis_tready']
    s_axis_tlast    = ports['s_axis_tlast']
    s_axis_tid      = ports['s_axis_tid']
    s_axis_tdest    = ports['s_axis_tdest']
    s_axis_tuser    = ports['s_axis_tuser']
    
    m_axis_tdata    = ports['m_axis_tdata']
    m_axis_tkeep    = ports['m_axis_tkeep']
    m_axis_tvalid   = ports['m_axis_tvalid']
    m_axis_tready   = ports['m_axis_tready']
    m_axis_tlast    = ports['m_axis_tlast']
    m_axis_tid      = ports['m_axis_tid']
    m_axis_tdest    = ports['m_axis_tdest']
    m_axis_tuser    = ports['m_axis_tuser']
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        dataSplitter,
        'uut',
        params,
        ports
    )

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_tdata(0))
    reset_stmt.append(s_axis_tkeep(0))
    reset_stmt.append(s_axis_tvalid(0))
    reset_stmt.append(m_axis_tready(0))
    reset_stmt.append(s_axis_tlast(0))
    reset_stmt.append(s_axis_tid(0))
    reset_stmt.append(s_axis_tdest(0))
    reset_stmt.append(s_axis_tuser(0))

    vcd_name = os.path.join('..','vcd','tb_DataSplitter.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock
    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        s_axis_tvalid(1),
        s_axis_tkeep(-1),
        s_axis_tdata(EmbeddedNumeric(f"{CHANNELS.value*DATA_WIDTH.value}'hAABBCCDDEEFF")),
        m_axis_tready(-1),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )
    
    # chn = module.Genvar('CHN')
    # per_channel = module.GenerateFor(chn(0), chn < CHANNELS, chn(chn+1))
    
    counter = module.Integer('counter', initval=0)
    tmp = module.TmpReg(DATA_WIDTH)
    tmp2 = module.TmpReg(1)

    module.Always(Posedge(clk))(
        If(reset_done)(
            If(Ands(s_axis_tready, s_axis_tvalid)) (
                counter(counter+1),
                Cat(s_axis_tdata,tmp)(
                    Cat(s_axis_tdata.slice(msb=DATA_WIDTH, lsb=0), s_axis_tdata)
                ),
                s_axis_tkeep(Cat(EmbeddedNumeric("1'b1"),s_axis_tkeep) >> 1),
                Cat(tmp2,m_axis_tready)(Cat(m_axis_tready,EmbeddedNumeric("1'b1"),)),
                s_axis_tlast(~s_axis_tlast),
                # Display('Counter up: %d', counter),
            ),
            If(counter == CHANNELS) (
                s_axis_tkeep[CHANNELS-1](0),
            ),
            If(counter == 3 * CHANNELS) (
                m_axis_tready[0](0),
            ),
            If(counter == 7 * CHANNELS) (
                s_axis_tkeep[CHANNELS-1](0),
                m_axis_tready[0](0),
            ),
            If(counter == 9 * CHANNELS) (
                Finish(),
            ),
        ).Else(
            counter(0),
        )
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = DataSplitter()
    # fname = os.path.join(TOP_DIR,'rtl/DataSplitter.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'DataSplitter')
    # addTimeScale(fname)
    
    test = tb_DataSplitter()
    fname = os.path.join(TOP_DIR,'tb/tb_DataSplitter.v')
    verilog_test = test.to_verilog(fname)
    stripModule(fname, 'DataSplitter')
    addTimeScale(fname)

    os.system(' '.join([
        os.path.join(TOP_DIR,'../auxiliary/run_sim.sh'),
        '-v',
        '-p',
        'DataSplitter',
    ]))

if __name__ == "__main__":
    main()
