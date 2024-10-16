from __future__ import absolute_import
from __future__ import print_function
import sys
import os

# import pyverilog.vparser.ast as vast
# from pyverilog.ast_code_generator.codegen import ASTCodeGenerator

from veriloggen import *
import veriloggen.core.vtypes as vtypes

TOP_DIR = os.path.dirname(  # .../kan-fpga
    os.path.dirname(
        os.path.abspath(__file__)
    )
)
sys.path.append(TOP_DIR)

from py import *

def Sech2Lutram() -> Module:
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/Sech2Lutram.v')
    )['Sech2Lutram']
    
def tb_Sech2Lutram():
    module = Module('tb_Sech2Lutram')

    Sech2Lutram_inst = Sech2Lutram()

    params = module.copy_params_as_localparams(Sech2Lutram_inst)
    ports  = module.copy_sim_ports(Sech2Lutram_inst)

    # params['CHANNELS'] = 8
    DATA_WIDTH_IN = params['DATA_WIDTH_IN']
    CHANNELS      = params['CHANNELS']
    EXTRA_CYCLE   = params['EXTRA_CYCLE']
    CHANNELS.value = 1
    EXTRA_CYCLE.value = 1

    reset_done = module.Reg('reset_done', initval=0)
    
    uut = module.Instance(
        Sech2Lutram_inst, 
        'uut',
        params = module.connect_params(Sech2Lutram_inst),
        ports = module.connect_ports(Sech2Lutram_inst)
    )
    
    clk    = ports['clk']
    rst    = ports['rst']
    s_axis_0_tdata  = ports['s_axis_0_tdata']
    s_axis_0_tlast  = ports['s_axis_0_tlast']
    s_axis_0_tvalid = ports['s_axis_0_tvalid']
    s_axis_0_tready = ports['s_axis_0_tready']
    m_axis_0_tdata  = ports['m_axis_0_tdata']
    m_axis_0_tlast  = ports['m_axis_0_tlast']
    m_axis_0_tvalid = ports['m_axis_0_tvalid']
    m_axis_0_tready = ports['m_axis_0_tready']

    reset_stmt = []
    reset_stmt.append(reset_done(0))
    reset_stmt.append(s_axis_0_tdata(0))
    reset_stmt.append(s_axis_0_tlast(0))
    reset_stmt.append(s_axis_0_tvalid(0))
    reset_stmt.append(m_axis_0_tready(0))
    
    vcd_name = os.path.join('..','vcd','tb_Sech2Lutram.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock

    clocks = 2* (2 ** DATA_WIDTH_IN) // CHANNELS
    count = module.TmpReg(
        DATA_WIDTH_IN, 
        CHANNELS, 
    )

    init.add(
        Delay(20),
        reset_done(1),
        s_axis_0_tvalid(-1),
        m_axis_0_tready(-1),
        nclk(clk),
        Delay(clocks),
        # Delay(10),
        Systask('finish'),
    )

    chn = module.Genvar('CHN')
    per_channel = module.GenerateFor(chn(0),chn < CHANNELS, chn(chn+1))

    data_reg  = per_channel.Reg('data_reg', DATA_WIDTH_IN)
    data_next = per_channel.Wire('data_next', DATA_WIDTH_IN)

    per_channel.Always()(
        s_axis_0_tdata.slice(
            DATA_WIDTH_IN * (chn+1) - 1,
            DATA_WIDTH_IN * chn
        )(data_reg)
    )
    per_channel.Assign(
        data_next(data_reg + CHANNELS)
    )
    per_channel.Always(Posedge(clk))(
        If(reset_done)(
            If(Ors(
                data_reg == 2**6+1 + chn,
                data_reg == 2**6+1 + chn + 3
            ))(
                s_axis_0_tvalid[chn](0)
            ),
            If(Not(s_axis_0_tvalid[chn]))(
                s_axis_0_tvalid[chn](1)
            ),
            If(Ors(
                data_reg == 2**6+1 + chn,
                data_reg == 2**6+1 + chn + 3
            ))(
                m_axis_0_tready[chn](0)
            ),
            If(Not(m_axis_0_tready[chn]))(
                m_axis_0_tready[chn](1)
            ),
            If(data_next % 2 ** (chn+1) == 0)(
                s_axis_0_tlast[chn](1)
            ),
            If(data_next == 2 ** (chn))(
                s_axis_0_tlast[chn](1)
            ),
            If(Ands(s_axis_0_tlast[chn],s_axis_0_tready[chn],s_axis_0_tvalid[chn]))(
                s_axis_0_tlast[chn](0)
            ),
            If(Ands(s_axis_0_tready[chn],s_axis_0_tvalid[chn]))(
                data_reg(data_next)
            ),
        ).Else(
            data_reg(2**(DATA_WIDTH_IN-1)+chn)
        )
    )
    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = Sech2Lutram()
    # fname = os.path.join(TOP_DIR,'rtl/Sech2Lutram.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'Sech2Lutram')
    # addTimeScale(fname)
    
    test = tb_Sech2Lutram()
    fname = os.path.join(TOP_DIR,'tb/tb_Sech2Lutram.v')
    verilog_test = test.to_verilog(fname)
    addTimeScale(fname)

    os.system(' '.join([
        os.path.join(TOP_DIR,'aux/run_sim.sh'),
        '-v',
        '-p',
        'Sech2Lutram',
    ]))

if __name__ == "__main__":
    main()

