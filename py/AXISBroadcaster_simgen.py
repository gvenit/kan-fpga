from __future__ import absolute_import
from __future__ import print_function
import sys
import os

# import pyverilog.vparser.ast as vast
# from pyverilog.ast_code_generator.codegen import ASTCodeGenerator
from veriloggen import *

import veriloggen.types.axi as axi
import veriloggen.thread as vthread

TOP_DIR = os.path.dirname(  # .../kan-fpga
    os.path.dirname(
        os.path.abspath(__file__)
    )
)
sys.path.append(TOP_DIR)

from py import *

def AXISBroadcaster() -> Module:
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/AXISBroadcaster.v')
    )['AXISBroadcaster']

def tb_AXISBroadcaster():
    module = Module('tb_AXISBroadcaster')

    splitter = AXISBroadcaster()
    params = module.copy_params_as_localparams(splitter)

    DATA_WIDTH : Localparam = params['DATA_WIDTH']
    CHANNELS   : Localparam = params['CHANNELS']
    # FIFO_DEPTH   : Localparam = params['FIFO_DEPTH']

    DATA_WIDTH.value = 16
    CHANNELS.value   = 4
    FIFO_DEPTH       = 4

    params = vthread.collections.OrderedDict((
        ('DATA_WIDTH' , DATA_WIDTH),
        ('CHANNELS'   , CHANNELS),
        # ('FIFO_DEPTH' , FIFO_DEPTH),
    ))

    clk = module.Reg('clk')
    rst = module.Reg('rst')
    s_axis_0_tdata  = module.Reg ('s_axis_0_tdata', width=DATA_WIDTH)
    s_axis_0_tvalid = module.Reg('s_axis_0_tvalid')
    s_axis_0_tready = module.Wire('s_axis_0_tready')
    s_axis_0_tlast  = module.Reg('s_axis_0_tlast') 
    m_axis_0_tdata  = module.Wire('m_axis_0_tdata', width=DATA_WIDTH*CHANNELS)
    m_axis_0_tvalid = module.Wire('m_axis_0_tvalid',width=CHANNELS)
    m_axis_0_tready = module.Reg ('m_axis_0_tready',width=CHANNELS)
    m_axis_0_tlast  = module.Wire('m_axis_0_tlast', width=CHANNELS)
    
    ports = (
        ('clk',clk),
        ('rst',rst),
        ('s_axis_0_tdata',s_axis_0_tdata) ,
        ('s_axis_0_tvalid',s_axis_0_tvalid),
        ('s_axis_0_tready',s_axis_0_tready),
        ('s_axis_0_tlast',s_axis_0_tlast) ,
        ('m_axis_0_tdata',m_axis_0_tdata) ,
        ('m_axis_0_tvalid',m_axis_0_tvalid),
        ('m_axis_0_tready',m_axis_0_tready),
        ('m_axis_0_tlast',m_axis_0_tlast) ,
    )

    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        splitter,
        'uut',
        params,
        ports
    )

    reset_stmt = []
    reset_stmt.append(reset_done(0))
    reset_stmt.append(s_axis_0_tdata(0))
    reset_stmt.append(s_axis_0_tvalid(0))
    reset_stmt.append(s_axis_0_tlast(0))
    reset_stmt.append(m_axis_0_tready(0))
    
    vcd_name = os.path.join('..','vcd','tb_AXISBroadcaster.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock

    count = module.Integer('count')
    count2 = module.Integer('count2')
    timer = module.Integer('timer')

    values = vthread.collections.UserList([
        int('BABE',base=16),
        int('CAFE',base=16),
        int('BEAF',base=16),
        int('DEAD',base=16),
    ])
    init.add(
        Delay(10),
        count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        m_axis_0_tready(-1),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    i = module.TmpInteger()

    module.Always(Posedge(clk))(
        If(reset_done)(
            Display('Count : %d -- %d:%d:%d:%X:%X:%X',count,s_axis_0_tready,s_axis_0_tvalid,s_axis_0_tlast,m_axis_0_tready,m_axis_0_tvalid,m_axis_0_tlast),
            If(Ands(s_axis_0_tready,s_axis_0_tvalid))(
                count.inc(),
            ),
            i((count)%CHANNELS),
            Case(i)(
                When(3)(
                    s_axis_0_tdata(
                        values[3]
                    )
                ),
                When(2)(
                    s_axis_0_tdata(
                        values[2]
                    )
                ),
                When(1)(
                    s_axis_0_tdata(
                        values[1]
                    )
                ),
                When()(
                    s_axis_0_tdata(
                        values[0]
                    )
                ),
            ),
            If(Ands(
                Not(s_axis_0_tvalid),
                Ors(
                    Ands(
                        count < 60,
                ))
            ))(
                s_axis_0_tvalid(1),
            ),
            If(OrList(count == 20+FIFO_DEPTH, count == 60-2*FIFO_DEPTH, count == 80-FIFO_DEPTH))(
                s_axis_0_tlast(1),
            ),
            If(Ors(
                # Ands(count < 1, timer),
                Ands(s_axis_0_tready,s_axis_0_tlast),
                count > 80+FIFO_DEPTH,
            ))(
                s_axis_0_tlast(0),
                s_axis_0_tvalid(0)
            ),
            If(Ands(
                count == 20+FIFO_DEPTH+1,
                m_axis_0_tvalid,
                # timer
            ))(
                s_axis_0_tvalid(0)
            ),
            If(Ands(count > 80+FIFO_DEPTH, Not(timer)))(
                Systask('finish')
            ),
            count2(count),
            If(Ors(
                count == count2,
                Not(Ors(
                    s_axis_0_tvalid,
                    m_axis_0_tready
                ))
            ))(
                If(timer)(
                    timer.dec(),
                ).Else(
                    timer(FIFO_DEPTH-1)
                ),
            ).Else(
                timer(FIFO_DEPTH-1)
            ),
        )
    )
    chn = module.Genvar('CHN')
    per_channel = module.GenerateFor(chn(0),chn < CHANNELS, chn(chn+1))
    per_channel.Always(Posedge(clk))(
        If(reset_done)(
            If(OrList(
                AndList(
                    count >= 21+chn,
                    count <  21+chn+2,
                    timer
                ),
                AndList(
                    count >= 80-FIFO_DEPTH-chn,
                    count <  80-chn ,
                    timer
                ),
                count > 80 + FIFO_DEPTH
            ))(
                m_axis_0_tready[chn](0)
            ).Else(
                m_axis_0_tready[chn](1)
            ),
        )
    ) 
    return module

def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # AXISBroadcaster().to_verilog(os.path.join(TOP_DIR,'rtl/tmp.v'))

    test = tb_AXISBroadcaster()
    fname = os.path.join(TOP_DIR,'tb/tb_AXISBroadcaster.v')
    verilog_test = test.to_verilog(fname)
    addTimeScale(fname)

    sim = simulation.Simulator(test)
    rslt = sim.run(
        libdir=os.path.join(TOP_DIR,'rtl'),
        outputfile=os.path.join(TOP_DIR,'out/tb_AXISBroadcaster.out'),
    )
    print(rslt)

if __name__ == "__main__":
    main()
