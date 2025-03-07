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

def SubMult() -> Module:
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/SubMult.v')
    )['SubMult']

def tb_SubMult():
    module = Module('tb_SubMult')

    subMult = SubMult()
    params = module.copy_params_as_localparams(subMult)
    ports  = module.copy_ports_as_vars(subMult)

    DATA_WIDTH            : Localparam = params['DATA_WIDTH_DATA']
    FRACTIONAL_BITS_DATA  : Localparam = params['FRACTIONAL_BITS_DATA']
    FRACTIONAL_BITS_SCALE : Localparam = params['FRACTIONAL_BITS_SCALE']
    FRACTIONAL_BITS_RSLT  : Localparam = params['FRACTIONAL_BITS_RSLT']

    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_DATA.value = 12
    FRACTIONAL_BITS_SCALE.value = 12
    FRACTIONAL_BITS_RSLT.value = 12

    reset_done = module.Reg('reset_done', initval=0)
    
    # with open(os.path.join(TOP_DIR,'rtl/SubMult.v'),'r') as f:
    #     subMult_str = ''.join(f.readlines())
    
    params['DATA_WIDTH_SCALE'].value = DATA_WIDTH
    params['DATA_WIDTH_RSLT'].value = DATA_WIDTH

    uut = module.Instance(
        subMult,
        'uut',
        params,
        # module.copy_sim_ports(subMult)
        ports
    )
    # print(ports)
    clk = ports['clk']
    rst = ports['rst']

    s_axis_data_tdata   = ports['s_axis_data_tdata']
    s_axis_data_tlast   = ports['s_axis_data_tlast']
    s_axis_data_tvalid  = ports['s_axis_data_tvalid']
    s_axis_data_tready  = ports['s_axis_data_tready']

    s_axis_grid_tdata   = ports['s_axis_grid_tdata']
    s_axis_grid_tlast   = ports['s_axis_grid_tlast']
    s_axis_grid_tvalid  = ports['s_axis_grid_tvalid']
    s_axis_grid_tready  = ports['s_axis_grid_tready']

    s_axis_scale_tdata  = ports['s_axis_scale_tdata']
    s_axis_scale_tlast  = ports['s_axis_scale_tlast']
    s_axis_scale_tvalid = ports['s_axis_scale_tvalid']
    s_axis_scale_tready = ports['s_axis_scale_tready']

    m_axis_data_tdata   = ports['m_axis_data_tdata']
    m_axis_data_tlast   = ports['m_axis_data_tlast']
    m_axis_data_tvalid  = ports['m_axis_data_tvalid']
    m_axis_data_tready  = ports['m_axis_data_tready']

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_data_tdata(0))
    reset_stmt.append(s_axis_data_tlast(0))
    reset_stmt.append(s_axis_data_tvalid(0))

    reset_stmt.append(s_axis_grid_tdata(0))
    reset_stmt.append(s_axis_grid_tlast(0))
    reset_stmt.append(s_axis_grid_tvalid(0))

    reset_stmt.append(s_axis_scale_tdata(0))
    reset_stmt.append(s_axis_scale_tlast(0))
    reset_stmt.append(s_axis_scale_tvalid(0))

    reset_stmt.append(m_axis_data_tready(0))

    vcd_name = os.path.join('..','vcd','tb_SubMult.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock

    values = [
        -4 << FRACTIONAL_BITS_DATA, 
        -1 << FRACTIONAL_BITS_DATA-1, 
         0,
         1 << FRACTIONAL_BITS_DATA-1, 
         4 << FRACTIONAL_BITS_DATA 
    ]

    count_data  = module.Integer('count_data')
    count_grid  = module.Integer('count_grid')
    count2_data = module.Integer('count2_data')
    count2_grid = module.Integer('count2_grid')
    timer_data  = module.Integer('timer_data')
    timer_grid  = module.Integer('timer_grid')
    i_data = module.TmpInteger()
    i_grid = module.TmpInteger()

    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        # s_axis_0_tvalid(-1),
        m_axis_data_tready(1),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    module.Always(Posedge(clk))(
        If(reset_done)(
            i_grid(count_grid % 5),
            i_data((count_data // 5) % 5),
            Display(
                'Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X', count_data,count_grid,
                s_axis_data_tready,s_axis_data_tvalid,s_axis_data_tlast,
                s_axis_grid_tready,s_axis_grid_tvalid,s_axis_grid_tlast,
                s_axis_scale_tready,s_axis_scale_tvalid,s_axis_scale_tlast,
                m_axis_data_tready,m_axis_data_tvalid,m_axis_data_tlast
            ),
            If(Ands(s_axis_data_tready,s_axis_data_tvalid))(
                count_data(count_data+1),
            ),
            If(Ands(s_axis_grid_tready,s_axis_grid_tvalid))(
                count_grid(count_grid+1),
            ),
            If(Ands(
                count_data == 0,
            ))(
                s_axis_scale_tdata(1 << FRACTIONAL_BITS_SCALE),
                s_axis_scale_tlast(1),
                s_axis_scale_tvalid(1),
            ),
            If(Ands(
                count_data != 0,
                count_data < 25,
            ))(
                s_axis_scale_tdata(5 << FRACTIONAL_BITS_SCALE),
            ),
            If(Ands(
                count_data == 25,
            ))(
                s_axis_scale_tdata(1 << FRACTIONAL_BITS_SCALE-1),
                s_axis_scale_tlast(0),
                s_axis_scale_tvalid(0),
            ),
            If(Ands(
                count_data > 25,
                count_data < 50,
            ))(
                s_axis_scale_tdata(s_axis_scale_tdata + 8),
            ),
            Case(i_data)(
                When(4)(s_axis_data_tdata(values[4])),
                When(3)(s_axis_data_tdata(values[3])),
                When(2)(s_axis_data_tdata(values[2])),
                When(1)(s_axis_data_tdata(values[1])),
                When( )(s_axis_data_tdata(values[0])),
            ),
            Case(i_grid)(
                When(4)(s_axis_grid_tdata(values[4])),
                When(3)(s_axis_grid_tdata(values[3])),
                When(2)(s_axis_grid_tdata(values[2])),
                When(1)(s_axis_grid_tdata(values[1])),
                When( )(s_axis_grid_tdata(values[0])),
            ),
            If(Ands(
                Not(s_axis_data_tvalid),
                Ors(
                    Ands(
                        count_data < 70,
                ))
            ))(
                s_axis_data_tvalid(1),
            ),
            If(Ands(
                Not(s_axis_grid_tvalid),
                Ors(
                    Ands(
                        count_grid < 70,
                ))
            ))(
                s_axis_grid_tvalid(1),
            ),
            If(OrList(
                count_data == 24, 
                count_data == 60, 
                count_data == 80
            ))(
                s_axis_data_tlast(1),
            ),
            If(OrList(
                count_grid == 24, 
                count_grid == 60, 
                count_grid == 80
            ))(
                s_axis_grid_tlast(1),
            ),
            If(Ors(
                # Ands(count_data < 1, timer),
                Ands(s_axis_data_tready,s_axis_data_tvalid,s_axis_data_tlast),
                count_data > 80,
            ))(
                s_axis_data_tlast(0),
                # s_axis_data_tvalid(0)
            ),
            If(Ors(
                # Ands(count_data < 1, timer),
                Ands(s_axis_grid_tready,s_axis_grid_tvalid,s_axis_grid_tlast),
                count_grid > 80,
            ))(
                s_axis_grid_tlast(0),
                # s_axis_grid_tvalid(0)
            ),
            If(Ors(
                Ands(
                    count_data == 24,
                    m_axis_data_tvalid,
                ),
                Ands(
                    count_data == 27,
                    m_axis_data_tvalid,
                ),
                # Ands(
                #     count_data >= 40,
                #     count_data <=  41,
                #     m_axis_data_tvalid,
                # ),
            ))(
                s_axis_data_tvalid(0)
            ),
            If(Ors(
                # count_grid == 10,
                Ands(
                    count_grid == 24,
                    m_axis_data_tvalid,
                ),
                Ands(
                    count_grid == 27,
                    m_axis_data_tvalid,
                ),
                # Ands(
                #     count_grid >= 40,
                #     count_grid <=  41,
                #     m_axis_grid_tvalid,
                # ),
            ))(
                s_axis_grid_tvalid(0)
            ),
            If(Ors(
                # count_grid == 10,
                Ands(
                    count_data == 27,
                    m_axis_data_tvalid,
                ),
                # Ands(
                #     count_grid >= 40,
                #     count_grid <=  41,
                #     m_axis_grid_tvalid,
                # ),
            ))(
                s_axis_scale_tvalid(1)
            ),
            If(Ors(
                # count_grid == 10,
                Ands(
                    count_data == 30,
                    m_axis_data_tvalid,
                ),
                # Ands(
                #     count_grid >= 40,
                #     count_grid <=  41,
                #     m_axis_grid_tvalid,
                # ),
            ))(
                s_axis_scale_tvalid(0)
            ),
            If(Ands(count_data > 70, Not(timer_data), Not(m_axis_data_tvalid)))(
                Systask('finish')
            ),
            count2_data(count_data),
            If(Ors(
                count_data == count2_data,
                Not(Ors(
                    s_axis_data_tvalid,
                    m_axis_data_tready
                ))
            ))(
                If(timer_data)(
                    timer_data(timer_data-1),
                ).Else(
                    timer_data(3)
                ),
            ).Else(
                timer_data(3)
            ),
            If(Ors(
                count_grid == count2_grid,
                Not(Ors(
                    s_axis_grid_tvalid,
                    m_axis_data_tready
                ))
            ))(
                If(timer_grid)(
                    timer_grid(timer_grid-1),
                ).Else(
                    timer_grid(3)
                ),
            ).Else(
                timer_grid(3)
            ),
        ).Else(
            count_data(0),
            count_grid(0),
        )
        
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    SubMult().to_verilog(os.path.join(TOP_DIR,'rtl/tmp.v'))

    test = tb_SubMult()
    fname = os.path.join(TOP_DIR,'tb/tb_SubMult.v')
    verilog_test = test.to_verilog(fname)
    
    stripModule(fname, 'tb_SubMult')
    addTimeScale(fname)

    # sim = simulation.Simulator(test)
    # rslt = sim.run(
    #     libdir=[
    #         os.path.join(TOP_DIR,'rtl'),
    #         os.path.join(TOP_DIR,'lib/*/rtl')
    #     ],
    #     outputfile=os.path.join(TOP_DIR,'out/tb_SubMult.out'),
    # )
    # print(rslt)
    
    # launch waveform viewer (GTKwave)
    # sim.view_waveform() # background=False
    # sim.view_waveform(background=True)
    
    os.system(' '.join([
        os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
        '-v',
        '-p',
        'SubMult',
    ]))

if __name__ == "__main__":
    main()
