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

def AXISFIFO() -> Module:
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/AXISFifo.v')
    )['AXISFifo']

def tb_AXISFIFO():
    module = Module('tb_AXISFIFO')

    fifo = AXISFIFO()
    params = module.copy_params_as_localparams(fifo)

    DATA_WIDTH : Localparam = params['DATA_WIDTH']
    ADDRESS_WIDTH   : Localparam = params['ADDRESS_WIDTH']

    DATA_WIDTH.value = 16
    ADDRESS_WIDTH.value = 2
    FIFO_DEPTH = 2**ADDRESS_WIDTH

    params = vthread.collections.OrderedDict((
        ('DATA_WIDTH' , DATA_WIDTH),
        ('ADDRESS_WIDTH' , ADDRESS_WIDTH),
    ))

    clk = module.Reg('clk')
    rst = module.Reg('rst')
    s_axis_0_tdata  = module.Reg ('s_axis_0_tdata', width=DATA_WIDTH)
    s_axis_0_tvalid = module.Reg('s_axis_0_tvalid')
    s_axis_0_tready = module.Wire('s_axis_0_tready')
    s_axis_0_tlast  = module.Reg('s_axis_0_tlast') 
    m_axis_0_tdata  = module.Wire('m_axis_0_tdata', width=DATA_WIDTH)
    m_axis_0_tvalid = module.Wire('m_axis_0_tvalid')
    m_axis_0_tready = module.Reg ('m_axis_0_tready')
    m_axis_0_tlast  = module.Wire('m_axis_0_tlast')
    
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
        fifo,
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
    
    vcd_name = os.path.join('..','vcd','tb_AXISFifo.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock

    # chn = module.Integer('chn')
    count = module.Integer('count')
    count2 = module.Integer('count2')
    timer = module.Integer('timer')

    values = vthread.collections.UserList([
        int('DEAD',base=16),
        int('BEAF',base=16),
        int('CAFE',base=16),
        int('BABE',base=16)
    ])
    init.add(
        Delay(10),
        count(0),
        reset_done(1),
        s_axis_0_tdata(-1),
        m_axis_0_tready(1),
        timer(FIFO_DEPTH-1),
        nclk(clk),
        # Delay(200),
        # Delay(10),
        # Systask('finish'), 
    )

    module.Always(Posedge(clk))(
        If(reset_done)(
            Display('Count : %d -- %d:%d:%d:%X:%X:%X',count-1,s_axis_0_tready,s_axis_0_tvalid,s_axis_0_tlast,m_axis_0_tready,m_axis_0_tvalid,m_axis_0_tlast),
            If(Ands(s_axis_0_tready,s_axis_0_tvalid))(
                count.inc(),
            ),
            If(Ands(Not(s_axis_0_tvalid), count < 44))(
                s_axis_0_tvalid(1),
            ),
            If(OrList(count == 20+FIFO_DEPTH, count == 40))(
                s_axis_0_tlast(1),
            ),
            If(Ors(
                Ands(count < 1, timer),
                Ands(s_axis_0_tready,s_axis_0_tlast),
                count > 40
            ))(
                s_axis_0_tlast(0),
                s_axis_0_tvalid(0)
            ),
            If(Ands(count > 40, Not(timer)))(
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
            ),
        )
    )
    i = module.TmpInteger()
    module.Always(Posedge(clk))(
        If(reset_done)(
            i(count%4),
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
            If(OrList(
                AndList(
                    count >= 21 ,
                    count <= 21+FIFO_DEPTH+1,
                    timer
                ),
                AndList(
                    count >= 40-FIFO_DEPTH,
                    count <  40 ,
                    timer
                ),
                count > 44
            ))(
                m_axis_0_tready(0)
            ).Elif(Not(m_axis_0_tready))(
                m_axis_0_tready(1)
            )
        )
    ) 
    return module

def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = RSWAFFuction()
    # module = AXISSplitter()
    # verilog = module.to_verilog(os.path.join(TOP_DIR,'rtl/RSWAFFuction.v'))
    test = tb_AXISFIFO()
    fname = os.path.join(TOP_DIR,'tb/tb_AXISFifo.v')
    verilog_test = test.to_verilog(fname)
    addTimeScale(fname)

    sim = simulation.Simulator(test)
    rslt = sim.run(
        libdir=os.path.join(TOP_DIR,'rtl'),
        outputfile=os.path.join(TOP_DIR,'out/tb_AXISFifo.out'),
    )
    print(rslt)

if __name__ == "__main__":
    main()
