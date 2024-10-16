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

from py import addTimeScale, stripModule

def RSWAFFuction():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/RSWAFFunction.v')
    )['RSWAFFunction'] 

def tb_RSWAFFuction():
    module = Module('tb_RSWAFFuction')

    RSWAFF = RSWAFFuction()
    params = module.copy_params_as_localparams(RSWAFF)

    DATA_WIDTH_IN       : Localparam = params['DATA_WIDTH_IN']
    DATA_WIDTH_OUT      : Localparam = params['DATA_WIDTH_OUT']
    FRACTIONAL_BITS_IN  : Localparam = params['FRACTIONAL_BITS_IN']
    FRACTIONAL_BITS_OUT : Localparam = params['FRACTIONAL_BITS_OUT']
    CHANNELS            : Localparam = params['CHANNELS']
    SHARE_SCALE         : Localparam = params['SHARE_SCALE']
    EXTRA_CYCLE         : Localparam = params['EXTRA_CYCLE']

    DATA_WIDTH_IN.value = 16
    DATA_WIDTH_OUT.value = 16
    FRACTIONAL_BITS_IN.value = 12
    FRACTIONAL_BITS_OUT.value = 16
    CHANNELS.value = 2
    SHARE_SCALE.value = 1
    EXTRA_CYCLE.value = 1

    params = vthread.collections.OrderedDict((
        ('DATA_WIDTH_IN',DATA_WIDTH_IN),
        ('DATA_WIDTH_OUT',DATA_WIDTH_OUT),
        ('FRACTIONAL_BITS_IN',FRACTIONAL_BITS_IN),
        ('FRACTIONAL_BITS_OUT',FRACTIONAL_BITS_OUT),
        ('CHANNELS',CHANNELS),
        ('SHARE_SCALE',SHARE_SCALE),
        ('EXTRA_CYCLE',EXTRA_CYCLE),
    ))

    clk = module.Reg('clk')
    rst = module.Reg('rst')

    s_axis_data_tdata  = module.Reg ('s_axis_data_tdata', width=DATA_WIDTH_IN*CHANNELS)
    s_axis_data_tkeep  = module.Reg ('s_axis_data_tkeep', width=CHANNELS)
    s_axis_data_tlast  = module.Reg ('s_axis_data_tlast') 
    s_axis_data_tvalid = module.Reg ('s_axis_data_tvalid')
    s_axis_data_tready = module.Wire('s_axis_data_tready')

    s_axis_grid_tdata  = module.Reg ('s_axis_grid_tdata', width=DATA_WIDTH_IN*CHANNELS)
    s_axis_grid_tkeep  = module.Reg ('s_axis_grid_tkeep', width=CHANNELS)
    s_axis_grid_tlast  = module.Reg ('s_axis_grid_tlast') 
    s_axis_grid_tvalid = module.Reg ('s_axis_grid_tvalid')
    s_axis_grid_tready = module.Wire('s_axis_grid_tready')

    s_axis_scale_tdata  = module.Reg ('s_axis_scale_tdata', width=DATA_WIDTH_IN)
    # s_axis_scale_tkeep  = module.Reg ('s_axis_scale_tkeep', width=CHANNELS)
    s_axis_scale_tlast  = module.Reg ('s_axis_scale_tlast') 
    s_axis_scale_tvalid = module.Reg ('s_axis_scale_tvalid')
    s_axis_scale_tready = module.Wire('s_axis_scale_tready')

    m_axis_0_tdata  = module.Wire('m_axis_0_tdata', width=DATA_WIDTH_OUT*CHANNELS)
    m_axis_0_tkeep  = module.Wire('m_axis_0_tkeep', width=CHANNELS)
    m_axis_0_tlast  = module.Wire('m_axis_0_tlast')
    m_axis_0_tvalid = module.Wire('m_axis_0_tvalid')
    m_axis_0_tready = module.Reg ('m_axis_0_tready')
    
    ports = (
        ('clk',clk),
        ('rst',rst),

        ('s_axis_data_tdata',s_axis_data_tdata),
        ('s_axis_data_tkeep',s_axis_data_tkeep),
        ('s_axis_data_tlast',s_axis_data_tlast),
        ('s_axis_data_tvalid',s_axis_data_tvalid),
        ('s_axis_data_tready',s_axis_data_tready),

        ('s_axis_grid_tdata',s_axis_grid_tdata),
        ('s_axis_grid_tkeep',s_axis_grid_tkeep),
        ('s_axis_grid_tlast',s_axis_grid_tlast),
        ('s_axis_grid_tvalid',s_axis_grid_tvalid),
        ('s_axis_grid_tready',s_axis_grid_tready),

        ('s_axis_scale_tdata',s_axis_scale_tdata),
        ('s_axis_scale_tlast',s_axis_scale_tlast),
        ('s_axis_scale_tvalid',s_axis_scale_tvalid),
        ('s_axis_scale_tready',s_axis_scale_tready),

        ('m_axis_0_tdata',m_axis_0_tdata) ,
        ('m_axis_0_tkeep',m_axis_0_tkeep) ,
        ('m_axis_0_tlast',m_axis_0_tlast) ,
        ('m_axis_0_tvalid',m_axis_0_tvalid),
        ('m_axis_0_tready',m_axis_0_tready),
    )
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        RSWAFF,
        'uut',
        params,
        module.copy_sim_ports(RSWAFF)
        # ports
    )

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_data_tdata(0))
    reset_stmt.append(s_axis_data_tvalid(0))
    reset_stmt.append(s_axis_data_tlast(0))
    reset_stmt.append(s_axis_data_tkeep(0))

    reset_stmt.append(s_axis_grid_tdata(0))
    reset_stmt.append(s_axis_grid_tkeep(0))
    reset_stmt.append(s_axis_grid_tlast(0))
    reset_stmt.append(s_axis_grid_tvalid(0))

    reset_stmt.append(s_axis_scale_tdata(0))
    reset_stmt.append(s_axis_scale_tlast(0))
    reset_stmt.append(s_axis_scale_tvalid(0))

    reset_stmt.append(m_axis_0_tready(0))

    vcd_name = os.path.join('..','vcd','tb_AXISCombiner.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock
    
    values = vthread.collections.UserList([
        int('BABE',base=16),
        int('CAFE',base=16),
        int('BEAF',base=16),
        int('DEAD',base=16),
    ])
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        # s_axis_0_tvalid(-1),
        m_axis_0_tready(1),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    module = RSWAFFuction()
    verilog = module.to_verilog(os.path.join(TOP_DIR,'rtl/RSWAFFuction.v'))
    # test = tb_RSWAFFuction()
    # verilog_test = test.to_verilog(os.path.join(TOP_DIR,'tb/tb_RSWAFFuction.v'))

    # sim = v.simulation.Simulator(test)
    # rslt = sim.run(
    #     # top = 'tb_sech2_lutram',
    #     # libdir= 'tb',
    #     # libdir= ['tb', 'rtl', ],
    #     outputfile=os.path.join(TOP_DIR,'out/tb_sech2_lutram.out'),
    # )
    # print(rslt)

if __name__ == "__main__":
    main()
