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

def LinearProcessingElement():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/LinearProcessingElement.v')
    )['LinearProcessingElement'] 

def tb_LinearProcessingElement():
    module = Module('tb_LinearProcessingElement')

    lpe = LinearProcessingElement()
    params = module.copy_params_as_localparams(lpe)
    ports  = module.copy_ports_as_vars(lpe)

    PE_NUMBER_I          : Localparam = params['PE_NUMBER_I']
    PE_NUMBER_J          : Localparam = params['PE_NUMBER_J']
    PE_POSITION_I        : Localparam = params['PE_POSITION_I']
    PE_POSITION_J        : Localparam = params['PE_POSITION_J']
    DATA_WIDTH           : Localparam = params['DATA_WIDTH_OP0']
    FRACTIONAL_BITS_OP0  : Localparam = params['FRACTIONAL_BITS_OP0']
    FRACTIONAL_BITS_OP1  : Localparam = params['FRACTIONAL_BITS_OP1']
    FRACTIONAL_BITS_RSLT : Localparam = params['FRACTIONAL_BITS_RSLT']
    IS_UNSIGNED_OP0      : Localparam = params['IS_UNSIGNED_OP0']
    OP1_USER_MASK        : Localparam = params['OP1_USER_MASK']
    RSLT_USER_MASK       : Localparam = params['RSLT_USER_MASK']

    PE_NUMBER_I.value = 4
    PE_NUMBER_J.value = 4
    PE_POSITION_I.value = 1
    PE_POSITION_J.value = 1

    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_OP0.value = 13
    FRACTIONAL_BITS_OP1.value = 15
    FRACTIONAL_BITS_RSLT.value = 15
    IS_UNSIGNED_OP0.value = 0
    
    # print(params.keys())
    # print(ports.keys())
    
    params['DATA_WIDTH_OP1'].value = DATA_WIDTH
    params['DATA_WIDTH_RSLT'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        lpe,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_up_tdata  = ports['s_axis_up_tdata']
    s_axis_up_tlast  = ports['s_axis_up_tlast']
    s_axis_up_tvalid = ports['s_axis_up_tvalid']
    s_axis_up_tready = ports['s_axis_up_tready']
    s_axis_up_tuser  = ports['s_axis_up_tuser']
    
    s_axis_left_tdata  = ports['s_axis_left_tdata']
    s_axis_left_tlast  = ports['s_axis_left_tlast']
    s_axis_left_tvalid = ports['s_axis_left_tvalid']
    s_axis_left_tready = ports['s_axis_left_tready']
    
    m_axis_down_tdata  = ports['m_axis_down_tdata']
    m_axis_down_tlast  = ports['m_axis_down_tlast']
    m_axis_down_tvalid = ports['m_axis_down_tvalid']
    m_axis_down_tready = ports['m_axis_down_tready']
    m_axis_down_tuser  = ports['m_axis_down_tuser']
    
    m_axis_right_tdata  = ports['m_axis_right_tdata']
    m_axis_right_tlast  = ports['m_axis_right_tlast']
    m_axis_right_tvalid = ports['m_axis_right_tvalid']
    m_axis_right_tready = ports['m_axis_right_tready']
    
    # for key, val in params.items():
    #     print(f'Parameter {key}: {val.value}')
        
    # for key, val in ports.items():
    #     print(f'Port {key}')

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_left_tdata(0))
    reset_stmt.append(s_axis_left_tvalid(0))
    reset_stmt.append(s_axis_left_tlast(0))

    reset_stmt.append(s_axis_up_tdata(0))
    reset_stmt.append(s_axis_up_tlast(0))
    reset_stmt.append(s_axis_up_tvalid(0))

    reset_stmt.append(m_axis_down_tready(0))
    reset_stmt.append(m_axis_right_tready(0))

    vcd_name = os.path.join('..','vcd','tb_LinearProcessingElement.vcd')
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
        m_axis_down_tready(1),
        m_axis_right_tready(1),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    values = [
        -4 << 13, 
        -1 << 12, 
         0,
         1 << 12, 
         4 << 13 
    ]
    count_op0  = module.Integer('count_op0')
    count_op1  = module.Integer('count_op1')
    count2_op0 = module.Integer('count2_op0')
    count2_op1 = module.Integer('count2_op1')
    timer_op0  = module.Integer('timer_op0')
    timer_op1  = module.Integer('timer_op1')
    i_op0 = module.TmpInteger()
    i_op1 = module.TmpInteger()

    module.Always(Posedge(clk))(
        If(reset_done)(
            i_op1(  count_op1 %  5),
            i_op0(( count_op0 // 5) % 5),
            Display(
                'Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X', count_op0,count_op1,
                s_axis_left_tready,s_axis_left_tvalid,s_axis_left_tlast,
                s_axis_up_tready,s_axis_up_tvalid,s_axis_up_tlast,
                m_axis_right_tready,m_axis_right_tvalid,m_axis_right_tlast,
                m_axis_down_tready,m_axis_down_tvalid,m_axis_down_tlast
            ),
            If(Ands(s_axis_left_tready,s_axis_left_tvalid))(
                count_op0(count_op0+1),
            ),
            If(Ands(s_axis_up_tready,s_axis_up_tvalid))(
                count_op1(count_op1+1),
            ),
            Case(i_op0)(
                When(4)(s_axis_left_tdata(values[4])),
                When(3)(s_axis_left_tdata(values[3])),
                When(2)(s_axis_left_tdata(values[2])),
                When(1)(s_axis_left_tdata(values[1])),
                When( )(s_axis_left_tdata(values[0])),
            ),
            Case(i_op1)(
                When(4)(s_axis_up_tdata(values[4])),
                When(3)(s_axis_up_tdata(values[3])),
                When(2)(s_axis_up_tdata(values[2])),
                When(1)(s_axis_up_tdata(values[1])),
                When( )(s_axis_up_tdata(values[0])),
            ),
            If(Ands(
                Not(s_axis_left_tvalid),
                Ors(
                    Ands(
                        count_op0 < 70,
                ))
            ))(
                s_axis_left_tvalid(1),
            ),
            If(Ands(
                Not(s_axis_up_tvalid),
                Ors(
                    Ands(
                        count_op1 < 70,
                ))
            ))(
                s_axis_up_tvalid(1),
                s_axis_up_tuser(OP1_USER_MASK)
            ),
            If(OrList(
                count_op0 == 5*5 - 3, 
                count_op0 == 60, 
                count_op0 == 80
            ))(
                s_axis_left_tlast(1),
            ),
            If(OrList(
                count_op1 == 5*5 - 1, 
                count_op1 == 60, 
                count_op1 == 80
            ))(
                s_axis_up_tlast(1),
            ),
            If(Ors(
                # Ands(count_op0 < 1, timer),
                Ands(s_axis_left_tready,s_axis_left_tvalid,s_axis_left_tlast),
                count_op0 > 80,
            ))(
                s_axis_left_tlast(0),
                # s_axis_left_tvalid(0)
            ),
            If(Ors(
                # Ands(count_op0 < 1, timer),
                Ands(s_axis_up_tready,s_axis_up_tvalid,s_axis_up_tlast),
                count_op1 > 80,
            ))(
                s_axis_up_tlast(0),
                # s_axis_up_tvalid(0)
            ),
            If (s_axis_up_tuser | RSLT_USER_MASK)(
                s_axis_up_tuser(OP1_USER_MASK)
            ),
            If(count_op0 == 30)(
                s_axis_up_tuser(OP1_USER_MASK|RSLT_USER_MASK)
            ),
            If(Ors(
                # Ands(count_op0 < 1, timer),
                count_op1 == 64,
            ))(
                s_axis_up_tlast(0),
                # s_axis_up_tvalid(0)
                s_axis_up_tuser(RSLT_USER_MASK)
            ),
            If(Ors(
                # Ands(
                #     count_op0 == 24,
                #     m_axis_right_tvalid,
                # ),
                Ands(
                    count_op0 == 5*5 + 2,
                    m_axis_right_tvalid,
                ),
                # Ands(
                #     count_op0 >= 40,
                #     count_op0 <=  41,
                #     m_axis_right_tvalid,
                # ),
            ))(
                s_axis_left_tvalid(0)
            ),
            If(Ors(
                # count_op1 == 10,
                # Ands(
                #     count_op1 == 24,
                #     m_axis_right_tvalid,
                # ),
                Ands(
                    count_op1 == 5*5 + 2,
                    m_axis_right_tvalid,
                ),
                # Ands(
                #     count_op1 >= 40,
                #     count_op1 <=  41,
                #     m_axis_grid_tvalid,
                # ),
            ))(
                s_axis_up_tvalid(0)
            ),
            If(Ands(count_op0 > 70, Not(timer_op0), Not(m_axis_right_tvalid)))(
                Systask('finish')
            ),
            count2_op0(count_op0),
            If(Ors(
                count_op0 == count2_op0,
                Not(Ors(
                    s_axis_left_tvalid,
                    m_axis_right_tready
                ))
            ))(
                If(timer_op0)(
                    timer_op0(timer_op0-1),
                ).Else(
                    timer_op0(3)
                ),
            ).Else(
                timer_op0(3)
            ),
            If(Ors(
                count_op1 == count2_op1,
                Not(Ors(
                    s_axis_up_tvalid,
                    m_axis_down_tready
                ))
            ))(
                If(timer_op1)(
                    timer_op1(timer_op1-1),
                ).Else(
                    timer_op1(3)
                ),
            ).Else(
                timer_op1(3)
            ),
        ).Else(
            count_op0(0),
            count_op1(0),
        )
        
    )

    return module


def tbv2_LinearProcessingElement():
    module = Module('tbv2_LinearProcessingElement')

    lpe = LinearProcessingElement()
    params = module.copy_params_as_localparams(lpe)
    ports  = module.copy_ports_as_vars(lpe)

    PE_NUMBER_I          : Localparam = params['PE_NUMBER_I']
    PE_NUMBER_J          : Localparam = params['PE_NUMBER_J']
    PE_POSITION_I        : Localparam = params['PE_POSITION_I']
    PE_POSITION_J        : Localparam = params['PE_POSITION_J']
    DATA_WIDTH           : Localparam = params['DATA_WIDTH_OP0']
    FRACTIONAL_BITS_OP0  : Localparam = params['FRACTIONAL_BITS_OP0']
    FRACTIONAL_BITS_OP1  : Localparam = params['FRACTIONAL_BITS_OP1']
    FRACTIONAL_BITS_RSLT : Localparam = params['FRACTIONAL_BITS_RSLT']
    IS_UNSIGNED_OP0      : Localparam = params['IS_UNSIGNED_OP0']
    OP1_USER_MASK        : Localparam = params['OP1_USER_MASK']
    RSLT_USER_MASK       : Localparam = params['RSLT_USER_MASK']

    PE_NUMBER_I.value = 1
    PE_NUMBER_J.value = 1
    PE_POSITION_I.value = 0
    PE_POSITION_J.value = 0

    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_OP0.value = 12
    FRACTIONAL_BITS_OP1.value = 12
    FRACTIONAL_BITS_RSLT.value = 12
    IS_UNSIGNED_OP0.value = 0
    
    # print(params.keys())
    # print(ports.keys())
    
    params['DATA_WIDTH_OP1'].value = DATA_WIDTH
    params['DATA_WIDTH_RSLT'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        lpe,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_up_tdata  = ports['s_axis_up_tdata']
    s_axis_up_tlast  = ports['s_axis_up_tlast']
    s_axis_up_tuser  = ports['s_axis_up_tuser']
    s_axis_up_tvalid = ports['s_axis_up_tvalid']
    s_axis_up_tready = ports['s_axis_up_tready']
    
    s_axis_left_tdata  = ports['s_axis_left_tdata']
    s_axis_left_tlast  = ports['s_axis_left_tlast']
    s_axis_left_tvalid = ports['s_axis_left_tvalid']
    s_axis_left_tready = ports['s_axis_left_tready']
    
    m_axis_down_tdata  = ports['m_axis_down_tdata']
    m_axis_down_tlast  = ports['m_axis_down_tlast']
    m_axis_down_tvalid = ports['m_axis_down_tvalid']
    m_axis_down_tready = ports['m_axis_down_tready']
    
    m_axis_right_tdata  = ports['m_axis_right_tdata']
    m_axis_right_tlast  = ports['m_axis_right_tlast']
    m_axis_right_tvalid = ports['m_axis_right_tvalid']
    m_axis_right_tready = ports['m_axis_right_tready']
    
    # for key, val in params.items():
    #     print(f'Parameter {key}: {val.value}')
        
    # for key, val in ports.items():
    #     print(f'Port {key}')

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_left_tdata(0))
    reset_stmt.append(s_axis_left_tvalid(0))
    reset_stmt.append(s_axis_left_tlast(0))

    reset_stmt.append(s_axis_up_tdata(0))
    reset_stmt.append(s_axis_up_tlast(0))
    reset_stmt.append(s_axis_up_tvalid(0))

    reset_stmt.append(m_axis_down_tready(0))
    reset_stmt.append(m_axis_right_tready(0))

    vcd_name = os.path.join('..','vcd','tbv2_LinearProcessingElement.vcd')
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
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    values = [
        -4 << 12, 
        -1 << 12, 
         0,
         1 << 12, 
         4 << 12 
    ]
    i_op0 = module.Integer('i_op0')
    i_op1 = module.Integer('i_op1')

    # Operand 0 coordinator
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_left_tready),
        Wait(~clk),
        Wait(clk),
        
        s_axis_left_tvalid(1),
        m_axis_right_tready(1),
        For(i_op0(0), i_op0 < 25, i_op0(i_op0+1))(
            Case((i_op0 % len(values)))(
                *[
                    When(i)(s_axis_left_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_left_tdata(values[0])),
            ),
            s_axis_left_tlast(i_op0 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_left_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        # Back to Back frames
        For(i_op0(0), i_op0 < 25, i_op0(i_op0+1))(
            Case((i_op0 % len(values)))(
                *[
                    When(i)(s_axis_left_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_left_tdata(values[0])),
            ),
            s_axis_left_tlast(i_op0 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_left_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        s_axis_left_tvalid(0),
        s_axis_left_tlast(0),
    )

    # Operand 1 & Result coordinator
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_up_tready),
        Wait(~clk),
        Wait(clk),
        
        s_axis_up_tvalid(1),
        s_axis_up_tuser(OP1_USER_MASK),
        m_axis_down_tready(1),
        For(i_op1(0), i_op1 < 25, i_op1(i_op1+1))(
            Case(((i_op1 / len(values)) % len(values)))(*[
                    When(i)(s_axis_up_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_up_tdata(values[0])),
            ),
            s_axis_up_tlast(i_op1 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_up_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        # Back to Back frames
        For(i_op1(0), i_op1 < 25, i_op1(i_op1+1))(
            Case(((i_op1 / len(values)) % len(values)))(*[
                    When(i)(s_axis_up_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_up_tdata(values[0])),
            ),
            s_axis_up_tlast(i_op1 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_up_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        s_axis_up_tvalid(0),
        s_axis_up_tlast(0),
        
        Wait(m_axis_down_tvalid),
        Wait(~clk),
        Wait(clk),
        
        Delay(25),
        Finish()
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = LinearProcessingElement()
    # # fname = os.path.join(TOP_DIR,'rtl/LinearProcessingElement.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'LinearProcessingElement')
    # addTimeScale(fname)
    # exit()
    
    test = tb_LinearProcessingElement()
    fname = os.path.join(TOP_DIR,'tb/tb_LinearProcessingElement.v')
    verilog_test = test.to_verilog(fname)
    stripModule(fname, 'LinearProcessingElement')
    addTimeScale(fname)

    os.system(' '.join([
        os.path.join(TOP_DIR,'aux/run_sim.sh'),
        '-v',
        '-p',
        'LinearProcessingElement',
    ]))
    
    test = tbv2_LinearProcessingElement()
    fname = os.path.join(TOP_DIR,'tb/tbv2_LinearProcessingElement.v')
    verilog_test = test.to_verilog(fname)
    stripModule(fname, 'LinearProcessingElement')
    addTimeScale(fname)

    os.system(' '.join([
        
        os.path.join(TOP_DIR,'aux/run_sim.sh'),
        '-v',
        '-p',
        'tbv2_LinearProcessingElement',
    ]))

if __name__ == "__main__":
    main()
