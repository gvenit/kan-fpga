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

def ParallelizedLinearProcessingElement():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/ParallelizedLPEWrapper.v')
    )['ParallelizedLPEWrapper'] 

def tb_ParallelizedLinearProcessingElement(I=1,J=1,i=0,j=0):
    module = Module(f'tb_ParallelizedLinearProcessingElement_{I}_{J}_{i}_{j}')

    lpe = ParallelizedLinearProcessingElement()
    params = module.copy_params_as_localparams(lpe)
    ports  = module.copy_ports_as_vars(lpe)

    PE_NUMBER_I          : Localparam = params['PE_NUMBER_I']
    PE_NUMBER_J          : Localparam = params['PE_NUMBER_J']
    PE_POSITION_I        : Localparam = params['PE_POSITION_I']
    PE_POSITION_J        : Localparam = params['PE_POSITION_J']
    DATA_WIDTH           : Localparam = params['DATA_WIDTH_OP0']
    FRACTIONAL_BITS_OP0  : Localparam = params['FRACTIONAL_BITS_OP0']
    FRACTIONAL_BITS_OP1  : Localparam = params['FRACTIONAL_BITS_OP1']
    IS_UNSIGNED_OP0      : Localparam = params['IS_UNSIGNED_OP0']

    PE_NUMBER_I.value = I
    PE_NUMBER_J.value = J
    PE_POSITION_I.value = i
    PE_POSITION_J.value = j

    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_OP0.value = 13
    FRACTIONAL_BITS_OP1.value = 15
    IS_UNSIGNED_OP0.value = 0
    
    # print(params.keys())
    # print(ports.keys())
    
    params['DATA_WIDTH_OP1'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        lpe,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_u_tdata  = ports['s_axis_u_tdata']
    s_axis_u_tlast  = ports['s_axis_u_tlast']
    s_axis_u_tvalid = ports['s_axis_u_tvalid']
    s_axis_u_tready = ports['s_axis_u_tready']
    
    s_axis_l_tdata  = ports['s_axis_l_tdata']
    s_axis_l_tlast  = ports['s_axis_l_tlast']
    s_axis_l_tvalid = ports['s_axis_l_tvalid']
    s_axis_l_tready = ports['s_axis_l_tready']
    
    s_axis_t_tdata  = ports['s_axis_t_tdata']
    s_axis_t_tlast  = ports['s_axis_t_tlast']
    s_axis_t_tvalid = ports['s_axis_t_tvalid']
    s_axis_t_tready = ports['s_axis_t_tready']
    
    m_axis_d_tdata  = ports['m_axis_d_tdata']
    m_axis_d_tlast  = ports['m_axis_d_tlast']
    m_axis_d_tvalid = ports['m_axis_d_tvalid']
    m_axis_d_tready = ports['m_axis_d_tready']
    
    m_axis_r_tdata  = ports['m_axis_r_tdata']
    m_axis_r_tlast  = ports['m_axis_r_tlast']
    m_axis_r_tvalid = ports['m_axis_r_tvalid']
    m_axis_r_tready = ports['m_axis_r_tready']
    
    m_axis_b_tdata  = ports['m_axis_b_tdata']
    m_axis_b_tlast  = ports['m_axis_b_tlast']
    m_axis_b_tvalid = ports['m_axis_b_tvalid']
    m_axis_b_tready = ports['m_axis_b_tready']
    
    err_unalligned_data = ports['err_unalligned_data']
    
    # for key, val in params.items():
    #     print(f'Parameter {key}: {val.value}')
        
    # for key, val in ports.items():
    #     print(f'Port {key}')

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_l_tdata(0))
    reset_stmt.append(s_axis_l_tvalid(0))
    reset_stmt.append(s_axis_l_tlast(0))

    reset_stmt.append(s_axis_t_tdata(0))
    reset_stmt.append(s_axis_t_tlast(0))
    reset_stmt.append(s_axis_t_tvalid(0))

    reset_stmt.append(s_axis_u_tdata(0))
    reset_stmt.append(s_axis_u_tlast(0))
    reset_stmt.append(s_axis_u_tvalid(0))

    reset_stmt.append(m_axis_r_tready(0))
    reset_stmt.append(m_axis_b_tready(0))
    reset_stmt.append(m_axis_d_tready(0))

    vcd_name = os.path.join('..','vcd',f'tb_ParallelizedLinearProcessingElement_{I}_{J}_{i}_{j}.vcd')
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
        m_axis_b_tready(1),
        m_axis_d_tready(1),
        m_axis_r_tready(1),
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
    count_res  = module.Integer('count_res')
    count2_op0 = module.Integer('count2_op0')
    count2_op1 = module.Integer('count2_op1')
    timer_op0  = module.Integer('timer_op0')
    timer_op1  = module.Integer('timer_op1')
    i_op0 = module.TmpInteger()
    i_op1 = module.TmpInteger()
    
    rst_temp = module.TmpReg(1)
    time_limit = 4

    module.Always(Posedge(clk))(
        If(reset_done)(
            rst(rst_temp != 0),
            rst_temp(rst_temp << 1),
            If(err_unalligned_data)(
                rst_temp(rst_temp | 1),
            ),
            If(rst_temp != 0)(
                s_axis_l_tvalid(0),
                s_axis_t_tvalid(0),
                s_axis_u_tvalid(0),
            ).Else(
                i_op1(  count_op1 %  5),
                i_op0(( count_op0 // 5) % 5),
                Display(
                    'Count : %d,%d -- %X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X-%X:%X:%X', count_op0,count_op1,
                    s_axis_l_tready,s_axis_l_tvalid,s_axis_l_tlast,
                    s_axis_t_tready,s_axis_t_tvalid,s_axis_t_tlast,
                    s_axis_u_tready,s_axis_u_tvalid,s_axis_u_tlast,
                    m_axis_r_tready,m_axis_r_tvalid,m_axis_r_tlast,
                    m_axis_b_tready,m_axis_b_tvalid,m_axis_b_tlast,
                    m_axis_d_tready,m_axis_d_tvalid,m_axis_d_tlast
                ),
                If(count_res)(Display('Res: %d', count_res)),
                If(Ands(s_axis_l_tready,s_axis_l_tvalid))(
                    count_op0(count_op0+1),
                ),
                If(Ands(s_axis_t_tready,s_axis_t_tvalid))(
                    count_op1(count_op1+1),
                ),
                Case(i_op0)(
                    When(4)(s_axis_l_tdata(values[4])),
                    When(3)(s_axis_l_tdata(values[3])),
                    When(2)(s_axis_l_tdata(values[2])),
                    When(1)(s_axis_l_tdata(values[1])),
                    When( )(s_axis_l_tdata(values[0])),
                ),
                Case(i_op1)(
                    When(4)(s_axis_t_tdata(values[4])),
                    When(3)(s_axis_t_tdata(values[3])),
                    When(2)(s_axis_t_tdata(values[2])),
                    When(1)(s_axis_t_tdata(values[1])),
                    When( )(s_axis_t_tdata(values[0])),
                ),
                If(Ands(
                    Not(s_axis_l_tvalid),
                    Ors(
                        Ands(
                            count_op0 < 70,
                    ))
                ))(
                    s_axis_l_tvalid(1),
                ),
                If(Ands(
                    Not(s_axis_t_tvalid),
                    Ors(
                        Ands(
                            count_op1 < 70,
                    ))
                ))(
                    s_axis_t_tvalid(1),
                ),
                If(OrList(
                    count_op0 == 5*5 - 3, 
                    count_op0 == 60, 
                    count_op0 == 80,
                    count_op0 == 85,
                ))(
                    s_axis_l_tlast(1),
                ),
                If(OrList(
                    count_op1 == 5*5 - 1, 
                    count_op1 == 60, 
                    count_op1 == 80,
                    count_op1 == 85,
                ))(
                    s_axis_t_tlast(1),
                ),
                If(AndList(
                    ~m_axis_d_tready,
                    m_axis_d_tvalid
                ))(
                    m_axis_d_tready(1),
                ),
                If(AndList(
                    count_op0 == 81,
                    count_op1 == 81
                ))(
                    m_axis_d_tready(0),
                ),
                If(Ors(
                    # Ands(count_op0 < 1, timer),
                    Ands(s_axis_l_tready,s_axis_l_tvalid,s_axis_l_tlast),
                    count_op0 > 86,
                ))(
                    s_axis_l_tlast(0),
                    # s_axis_l_tvalid(0)
                ),
                If(Ors(
                    # Ands(count_op0 < 1, timer),
                    Ands(s_axis_t_tready,s_axis_t_tvalid,s_axis_t_tlast),
                    count_op1 > 86,
                ))(
                    s_axis_t_tlast(0),
                    # s_axis_t_tvalid(0)
                ),
                If(Ors(
                    # Ands(count_op0 < 1, timer),
                    count_op1 == 64,
                ))(
                    s_axis_t_tlast(0),
                    # s_axis_t_tvalid(0)
                ),
                If(Ors(
                    # Ands(
                    #     count_op0 == 24,
                    #     m_axis_r_tvalid,
                    # ),
                    Ands(
                        count_op0 == 5*5 + 2,
                        m_axis_r_tvalid,
                    ),
                    # Ands(
                    #     count_op0 >= 40,
                    #     count_op0 <=  41,
                    #     m_axis_r_tvalid,
                    # ),
                ))(
                    s_axis_l_tvalid(0)
                ),
                If(Ors(
                    # count_op1 == 10,
                    # Ands(
                    #     count_op1 == 24,
                    #     m_axis_r_tvalid,
                    # ),
                    Ands(
                        count_op1 == 5*5 + 2,
                        m_axis_r_tvalid,
                    ),
                    # Ands(
                    #     count_op1 >= 40,
                    #     count_op1 <=  41,
                    #     m_axis_grid_tvalid,
                    # ),
                ))(
                    s_axis_t_tvalid(0)
                ),
                If(Ands(count_op0 > 70, Not(timer_op0), Not(m_axis_r_tvalid)))(
                    Systask('finish')
                ),
                count2_op0(count_op0),
                If(Ors(
                    count_op0 == count2_op0,
                    Not(Ors(
                        s_axis_l_tvalid,
                        m_axis_r_tready
                    ))
                ))(
                    If(timer_op0)(
                        timer_op0(timer_op0-1),
                    ).Else(
                        timer_op0(time_limit)
                    ),
                ).Else(
                    timer_op0(time_limit)
                ),
                If(Ors(
                    count_op1 == count2_op1,
                    Not(Ors(
                        s_axis_t_tvalid,
                        m_axis_b_tready
                    ))
                ))(
                    If(timer_op1)(
                        timer_op1(timer_op1-1),
                    ).Else(
                        timer_op1(time_limit)
                    ),
                ).Else(
                    timer_op1(time_limit)
                ),
                If(count_op0 > 85)(
                    s_axis_l_tvalid(0),
                    s_axis_l_tlast(0),
                ),
                If(count_op1 > 85)(
                    s_axis_t_tvalid(0),
                    s_axis_t_tlast(0),
                ),
            )
        ).Else(
            count_op0(0),
            count_op1(0),
            rst_temp(0),
        )
        
    )

    if j > 0 :
        module.Always(Posedge(clk))(
            If(reset_done)(
                # Test 1
                If(Ands(
                    count_op0 > 60,
                    count_op0 < 60+5,
                    s_axis_u_tready,
                ))(
                    count_res(1),
                    If(count_res)(
                        count_res(count_res+1),
                        s_axis_u_tdata(2 ** DATA_WIDTH -s_axis_u_tdata),
                        s_axis_u_tvalid(1),
                    ),
                    If(count_res == 6)(
                        s_axis_u_tlast(1),
                        count_res(0),
                    )
                ),
                If(Ands(
                    count_op0 > 60+3,
                    count_op0 < 60+5,
                    count_res == 0,
                ))(
                    count_res(0),
                    s_axis_u_tvalid(0),
                ),
                # Test 2
                If(Ands(
                    count_op0 > 80-4,
                    count_op0 < 80+5,
                    s_axis_u_tready,
                ))(
                    count_res(1),
                    If(count_res)(
                        Display('Res: %d', count_res),
                        count_res(count_res+1),
                        s_axis_u_tdata(Signed(-s_axis_u_tdata)),
                        s_axis_u_tvalid(1),
                    ),
                    If(count_res == 6)(
                        s_axis_u_tlast(1),
                    )
                ),
                If(Ands(
                    count_op0 > 80+3,
                    count_op0 < 80+5,
                    count_res == 0,
                ))(
                    count_res(0),
                    s_axis_u_tvalid(0),
                ),
                # Test 2
                If(Ands(
                    count_op0 > 85-1,
                    count_op0 < 85+5,
                ))(
                    m_axis_d_tready(0),
                    If(s_axis_u_tready)(
                        count_res(1),
                        If(count_res)(
                            Display('Res: %d', count_res),
                            count_res(count_res+1),
                            s_axis_u_tdata(Signed(-s_axis_u_tdata)),
                            s_axis_u_tvalid(1),
                        ),
                        If(count_res == 3)(
                            s_axis_u_tlast(1),
                        )
                    )
                ),
                If(Ands(
                    count_op0 > 85+1,
                    count_op0 < 85+5,
                    count_res == 0,
                ))(
                    count_res(0),
                    s_axis_u_tvalid(0),
                    m_axis_d_tready(1),
                ),
                If(s_axis_u_tlast)(
                    s_axis_u_tlast(0),
                    s_axis_u_tvalid(0),
                    count_res(0),
                ),
            ).Else(
                count_res(0),
                s_axis_u_tdata(1),
            )
        )
    
    return module


def tb_ParallelizedLinearProcessingElement_v2(I=1,J=1,i=0,j=0):
    module = Module(f'tb_ParallelizedLinearProcessingElement_v2_{I}_{J}_{i}_{j}')

    lpe = ParallelizedLinearProcessingElement()
    params = module.copy_params_as_localparams(lpe)
    ports  = module.copy_ports_as_vars(lpe)

    PE_NUMBER_I          : Localparam = params['PE_NUMBER_I']
    PE_NUMBER_J          : Localparam = params['PE_NUMBER_J']
    PE_POSITION_I        : Localparam = params['PE_POSITION_I']
    PE_POSITION_J        : Localparam = params['PE_POSITION_J']
    DATA_WIDTH           : Localparam = params['DATA_WIDTH_OP0']
    FRACTIONAL_BITS_OP0  : Localparam = params['FRACTIONAL_BITS_OP0']
    FRACTIONAL_BITS_OP1  : Localparam = params['FRACTIONAL_BITS_OP1']
    IS_UNSIGNED_OP0      : Localparam = params['IS_UNSIGNED_OP0']

    PE_NUMBER_I.value = I
    PE_NUMBER_J.value = J
    PE_POSITION_I.value = i
    PE_POSITION_J.value = j

    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_OP0.value = 12
    FRACTIONAL_BITS_OP1.value = 12
    IS_UNSIGNED_OP0.value = 0
    
    # print(params.keys())
    # print(ports.keys())
    
    params['DATA_WIDTH_OP1'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        lpe,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_u_tdata  = ports['s_axis_u_tdata']
    s_axis_u_tlast  = ports['s_axis_u_tlast']
    s_axis_u_tvalid = ports['s_axis_u_tvalid']
    s_axis_u_tready = ports['s_axis_u_tready']
    
    s_axis_l_tdata  = ports['s_axis_l_tdata']
    s_axis_l_tlast  = ports['s_axis_l_tlast']
    s_axis_l_tvalid = ports['s_axis_l_tvalid']
    s_axis_l_tready = ports['s_axis_l_tready']
    
    s_axis_t_tdata  = ports['s_axis_t_tdata']
    s_axis_t_tlast  = ports['s_axis_t_tlast']
    s_axis_t_tvalid = ports['s_axis_t_tvalid']
    s_axis_t_tready = ports['s_axis_t_tready']
    
    m_axis_d_tdata  = ports['m_axis_d_tdata']
    m_axis_d_tlast  = ports['m_axis_d_tlast']
    m_axis_d_tvalid = ports['m_axis_d_tvalid']
    m_axis_d_tready = ports['m_axis_d_tready']
    
    m_axis_r_tdata  = ports['m_axis_r_tdata']
    m_axis_r_tlast  = ports['m_axis_r_tlast']
    m_axis_r_tvalid = ports['m_axis_r_tvalid']
    m_axis_r_tready = ports['m_axis_r_tready']
    
    m_axis_b_tdata  = ports['m_axis_b_tdata']
    m_axis_b_tlast  = ports['m_axis_b_tlast']
    m_axis_b_tvalid = ports['m_axis_b_tvalid']
    m_axis_b_tready = ports['m_axis_b_tready']
    
    # for key, val in params.items():
    #     print(f'Parameter {key}: {val.value}')
        
    # for key, val in ports.items():
    #     print(f'Port {key}')

    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_l_tdata(0))
    reset_stmt.append(s_axis_l_tvalid(0))
    reset_stmt.append(s_axis_l_tlast(0))

    reset_stmt.append(s_axis_t_tdata(0))
    reset_stmt.append(s_axis_t_tlast(0))
    reset_stmt.append(s_axis_t_tvalid(0))

    reset_stmt.append(s_axis_u_tdata(0))
    reset_stmt.append(s_axis_u_tlast(0))
    reset_stmt.append(s_axis_u_tvalid(0))

    reset_stmt.append(m_axis_r_tready(0))
    reset_stmt.append(m_axis_b_tready(0))
    reset_stmt.append(m_axis_d_tready(0))

    vcd_name = os.path.join('..','vcd','tbv2_ParallelizedLinearProcessingElement.vcd')
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
    # i_res = module.Integer('i_res')

    # Operand 0 coordinator
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_l_tready),
        Wait(~clk),
        Wait(clk),
        
        s_axis_l_tvalid(1),
        m_axis_r_tready(1),
        For(i_op0(0), i_op0 < 25, i_op0(i_op0+1))(
            Case((i_op0 % len(values)))(
                *[
                    When(i)(s_axis_l_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_l_tdata(values[0])),
            ),
            s_axis_l_tlast(i_op0 == (len(values)**2-1)),
            If(i_op0 % 10 == 0)(
                s_axis_l_tvalid(0),
                Wait(clk),
                Wait(~clk),
                s_axis_l_tvalid(1),
            ),
            Wait(~clk),
            While(~s_axis_l_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        # Back to Back frames
        For(i_op0(0), i_op0 < 25, i_op0(i_op0+1))(
            Case((i_op0 % len(values)))(
                *[
                    When(i)(s_axis_l_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_l_tdata(values[0])),
            ),
            s_axis_l_tlast(i_op0 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_l_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        s_axis_l_tvalid(0),
        s_axis_l_tlast(0),
    )

    # Operand 1 coordinator
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_t_tready),
        Wait(~clk),
        Wait(clk),
        
        s_axis_t_tvalid(1),
        m_axis_b_tready(1),
        For(i_op1(0), i_op1 < 25, i_op1(i_op1+1))(
            Case(((i_op1 / len(values)) % len(values)))(*[
                    When(i)(s_axis_t_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_t_tdata(values[0])),
            ),
            s_axis_t_tlast(i_op1 == (len(values)**2-1)),
            If(i_op1 % 5 == 0)(
                s_axis_t_tvalid(0),
                Wait(clk),
                Wait(~clk),
                s_axis_t_tvalid(1),
            ),
            Wait(~clk),
            While(~s_axis_t_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        # Back to Back frames
        For(i_op1(0), i_op1 < 25, i_op1(i_op1+1))(
            Case(((i_op1 / len(values)) % len(values)))(*[
                    When(i)(s_axis_t_tdata(values[i]))
                        for i in range(len(values))
                ],
                When( )(s_axis_t_tdata(values[0])),
            ),
            s_axis_t_tlast(i_op1 == (len(values)**2-1)),
            Wait(~clk),
            While(~s_axis_t_tready)(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        s_axis_t_tvalid(0),
        s_axis_t_tlast(0),
        
        Wait(m_axis_b_tvalid),
        Wait(~clk),
        Wait(clk),
        
        Delay(25),
        Finish()
    )
    
    # Result coordinator
    module.Initial(
        s_axis_u_tdata(0),
        Wait(reset_done),
        Wait(clk),
        
        If(PE_POSITION_J != 0)(  
            Wait(s_axis_u_tready),
            Wait(~clk),
            Wait(clk),
        ),
        Wait(m_axis_d_tvalid),
        Wait(~clk),
        Wait(clk),
        
        s_axis_u_tvalid(1),
        m_axis_d_tready(1),
        Wait(~clk),
        Wait(clk),
        
        s_axis_u_tvalid(0),
        m_axis_d_tready(0),
        
        # Back to Back frames
        If(PE_POSITION_J != 0)(
            For(i_op1(0), i_op1 < 25, i_op1(i_op1+1))(
                Case(((i_op1 / len(values)) % len(values)))(*[
                        When(i)(s_axis_u_tdata(values[i]))
                            for i in range(len(values))
                    ],
                    When( )(s_axis_u_tdata(values[0])),
                ),
                s_axis_u_tlast(i_op1 == (len(values)**2-1)),
                Wait(~clk),
                While(~s_axis_u_tready)(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
            ),
        ),
        s_axis_u_tvalid(0),
        s_axis_u_tlast(0),
        
        Wait(m_axis_d_tvalid),
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

    # module = ParallelizedLinearProcessingElement()
    # # fname = os.path.join(TOP_DIR,'rtl/ParallelizedLinearProcessingElement.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'ParallelizedLinearProcessingElement')
    # addTimeScale(fname)
    # exit()
    
    for I,J,i,j in (
        (1,1,0,0),
        (1,3,0,0),
        (1,3,0,1),
        (1,3,0,2),
    ):
        test = tb_ParallelizedLinearProcessingElement(I=I,J=J,i=i,j=j)
        fname_base=f'tb_ParallelizedLinearProcessingElement_{I}_{J}_{i}_{j}'
        fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'ParallelizedLinearProcessingElement')
        addTimeScale(fname)

        os.system(' '.join([
            os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
            '-v',
            '-p',
            fname_base,
        ]))
        
        # test = tb_ParallelizedLinearProcessingElement_v2(I=I,J=J,i=i,j=j)
        fname_base=f'tb_ParallelizedLinearProcessingElement_v2_{I}_{J}_{i}_{j}'
        # fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        # verilog_test = test.to_verilog(fname)
        # stripModule(fname, 'ParallelizedLinearProcessingElement')
        # addTimeScale(fname)

        # os.system(' '.join([
            
        #     os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
        #     '-v',
        #     '-p',
        #     fname_base,
        # ]))

if __name__ == "__main__":
    main()
