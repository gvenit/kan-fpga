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
import numpy as np

def ParallelizedLinearProcessingArray():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/wrapper/ParallelizedLPAWrapper.v')
    )['ParallelizedLPAWrapper'] 

def tb_ParallelizedLinearProcessingArray(I=1,J=1,K=1):
    module = Module(f'tb_ParallelizedLinearProcessingArray_{I}_{J}_{K}')

    lpa = ParallelizedLinearProcessingArray()
    params = module.copy_params_as_localparams(lpa)
    ports  = module.copy_ports_as_vars(lpa)

    PE_NUMBER_I          : Localparam = params['PE_NUMBER_I']
    PE_NUMBER_J          : Localparam = params['PE_NUMBER_J']
    BATCH_SIZE           : Localparam = params['BATCH_SIZE']
    INTERNAL_RESET       : Localparam = params['INTERNAL_RESET']
    DATA_WIDTH           : Localparam = params['OP0_WIDTH']
    OP0_FRACTIONAL_BITS  : Localparam = params['OP0_FRACTIONAL_BITS']
    OP1_FRACTIONAL_BITS  : Localparam = params['OP1_FRACTIONAL_BITS']
    RSLT_FRACTIONAL_BITS : Localparam = params['RSLT_FRACTIONAL_BITS']
    IS_UNSIGNED_OP0      : Localparam = params['IS_UNSIGNED_OP0']

    PE_NUMBER_I.value = I
    PE_NUMBER_J.value = J
    BATCH_SIZE.value  = K

    INTERNAL_RESET.value = 1
    DATA_WIDTH.value = 16
    OP0_FRACTIONAL_BITS.value = 12
    OP1_FRACTIONAL_BITS.value = 12
    RSLT_FRACTIONAL_BITS.value = 12
    IS_UNSIGNED_OP0.value = 0
    
    # print(params.keys())
    # print(ports.keys())
    
    params['OP1_WIDTH'].value = DATA_WIDTH
    params['RSLT_WIDTH'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        lpa,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
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
    
    err_unalligned_data = ports['err_unalligned_data']
    core_rst = ports['core_rst']
    
    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_l_tdata(0))
    reset_stmt.append(s_axis_l_tvalid(0))
    reset_stmt.append(s_axis_l_tlast(0))

    reset_stmt.append(s_axis_t_tdata(0))
    reset_stmt.append(s_axis_t_tlast(0))
    reset_stmt.append(s_axis_t_tvalid(0))

    reset_stmt.append(m_axis_d_tready(0))

    vcd_name = os.path.join('..','vcd',f'tb_ParallelizedLinearProcessingArray_{I}_{J}_{K}.vcd')
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
        m_axis_d_tready(1),
        Delay(5000),
        # Delay(10),
        Systask('finish'),
    )
    
    module.EmbeddedCode(
    '''`define assert(signal, value) \
    if (signal !== value) begin \
        $display("ASSERTION FAILED in %m: %s != %s",`"signal`", `"value`"); \
        $display("---- Time %0t",$time); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        $display("---- %s = 0x%h",`"value`",value); \
        $finish; \
    end
    `define assertTrue(signal) \
    if (~signal) begin \
        $display("ASSERTION FAILED in %m: %s is not True",`"signal`"); \
        $display("---- Time %0t",$time); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        $finish; \
    end
    ''')
    def Assert(signal,value):
        return EmbeddedCode(f'`assert({signal},{value})')
    def AssertTrue(signal):
        return EmbeddedCode(f'`assertTrue({signal})')

    values = [
        -4 << 11, 
        -1 << 11, 
         0,
         1 << 11, 
         4 << 11 
    ]
    chn_i = module.Genvar('CHN_I')
    chn_j = module.Genvar('CHN_J')
    chn_k = module.Genvar('CHN_K')
    
    # Operand 0 coordinator
    per_channel_j  = module.GenerateFor(chn_j(0), chn_j <PE_NUMBER_J, chn_j(chn_j+1))
    per_channel_jk = per_channel_j.GenerateFor(chn_k(0), chn_k <PE_NUMBER_J, chn_k(chn_k+1))
    
    LFT_POS = per_channel_jk.Localparam('LFT_POS',chn_k * PE_NUMBER_J + chn_j)
    i_op0 = per_channel_jk.Integer('i_op0')
    
    data_slice = s_axis_l_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )

    test3_op0 = np.array([[
            values[(k*J+j) % len(values)]
                for k in range(K)
        ] for j in range(J)
    ]).astype('float32') / 2**OP0_FRACTIONAL_BITS.value
    test4_op0 = np.array([[[
                values[((n*K+k)*J+j) % len(values)]
                    for k in range(K)
            ] for j in range(J)
        ] for n in range(len(values)**2)
    ]).astype('float32') / 2**OP0_FRACTIONAL_BITS.value
    
    per_channel_jk.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_l_tready[LFT_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Unalligned data (top -> left)
        s_axis_l_tvalid[LFT_POS](1),
        s_axis_l_tlast[LFT_POS](0),
        For(i_op0(0), Ands(i_op0 < len(values)), i_op0(i_op0+1))(
            Wait(~clk),
            Case(((i_op0+LFT_POS) % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            # If((i_op0 + LFT_POS) % 4 == 0)(
            #     s_axis_l_tvalid[LFT_POS](0),
            #     Wait(~clk),
            #     Wait(clk),
            #     s_axis_l_tvalid[LFT_POS](1),
            # ),
            While(~s_axis_l_tready[LFT_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        Wait(err_unalligned_data),
        Wait(core_rst),
        s_axis_l_tvalid[LFT_POS](0),
        s_axis_l_tlast[LFT_POS](0),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 1 : Unalligned data (left -> top)
        s_axis_l_tvalid[LFT_POS](1),
        For(i_op0(0), Ands(i_op0 < len(values)), i_op0(i_op0+1))(
            Wait(~clk),
            Case(((i_op0+LFT_POS) % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_l_tlast[LFT_POS](i_op0 == (len(values)-1)),
            # If((i_op0 + LFT_POS) % 4 == 0)(
            #     s_axis_l_tvalid[LFT_POS](0),
            #     Wait(~clk),
            #     Wait(clk),
            #     s_axis_l_tvalid[LFT_POS](1),
            # ),
            While(~s_axis_l_tready[LFT_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        Wait(err_unalligned_data),
        If(Ands(
            LFT_POS == 0,
            ~INTERNAL_RESET
        ))(
            rst(1),
            s_axis_l_tvalid[LFT_POS](0),
            s_axis_l_tlast[LFT_POS](0),
            Wait(~clk),
            Wait(clk),
            rst(0)
        ),
        Wait(core_rst),
        s_axis_l_tvalid[LFT_POS](0),
        s_axis_l_tlast[LFT_POS](0),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 2 : Back to Back single burst frames (Blocked Output)
        s_axis_l_tvalid[LFT_POS](1),
        While(~core_rst)(
            Wait(~clk),
            Case((LFT_POS % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_l_tlast(1),
            Wait(clk),
        ),
        s_axis_l_tvalid[LFT_POS](0),
        s_axis_l_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Back to Back single burst frames
        s_axis_l_tvalid[LFT_POS](1),
        While(~core_rst)(
            Wait(~clk),
            Case((LFT_POS % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_l_tlast(1),
            Wait(clk),
        ),
        s_axis_l_tvalid[LFT_POS](0),
        s_axis_l_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Nominal function
        s_axis_l_tvalid[LFT_POS](1),
        While(~core_rst)(
            For(i_op0(0), Ands(i_op0 < (len(values)**2),~core_rst), i_op0(i_op0+1))(
                Wait(~clk),
                Case(((i_op0+LFT_POS) % len(values)))(
                    *[
                        When(i)(data_slice(values[i]))
                            for i in range(len(values))
                    ],
                    When( )(data_slice(values[0])),
                ),
                s_axis_l_tlast[LFT_POS](i_op0 == (len(values)**2-1)),
                If((i_op0 + LFT_POS) % 5 == 0)(
                    s_axis_l_tvalid[LFT_POS](0),
                    Wait(clk),
                    Wait(~clk),
                    Wait(clk),
                    Wait(~clk),
                    s_axis_l_tvalid[LFT_POS](1),
                ),
                While(Ands(~s_axis_l_tready[LFT_POS],~core_rst))(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
            ),
        ),
        s_axis_l_tvalid[LFT_POS](0),
        s_axis_l_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )

    # Operand 1 coordinator
    per_channel_i  = module.GenerateFor(chn_i(0), chn_i <PE_NUMBER_I, chn_i(chn_i+1))
    per_channel_ij = per_channel_i.GenerateFor(chn_j(0), chn_j <PE_NUMBER_J, chn_j(chn_j+1))
    
    TOP_POS = per_channel_ij.Localparam('TOP_POS',chn_j * PE_NUMBER_I + chn_i)
    i_op1 = per_channel_ij.Integer('i_op1')
    
    data_slice = s_axis_t_tdata.slice(
        msb = (TOP_POS+1)*DATA_WIDTH-1,
        lsb = TOP_POS * DATA_WIDTH
    )

    test3_op1 = np.array([[
            values[(j*I+i) % len(values)]
                for j in range(J)
        ] for i in range(I)
    ]).astype('float32') / 2**OP0_FRACTIONAL_BITS.value
    test4_op1 = np.array([[[
                values[((n*K+j)*I+i) % len(values)]
                    for j in range(J)
            ] for i in range(I)
        ] for n in range(len(values)**2)
    ]).astype('float32') / 2**OP0_FRACTIONAL_BITS.value
    
    per_channel_ij.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_t_tready[TOP_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Unalligned data (top -> left)
        s_axis_t_tvalid[TOP_POS](1),
        For(i_op1(0), Ands(i_op1 < len(values)), i_op1(i_op1+1))(
            Wait(~clk),
            Case(((i_op1+TOP_POS) % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_t_tlast[TOP_POS](i_op1 == (len(values)-1)),
            While(~s_axis_t_tready[TOP_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        Wait(err_unalligned_data),
        If(Ands(
            TOP_POS == 0,
            ~INTERNAL_RESET
        ))(
            rst(1),
            s_axis_t_tvalid[TOP_POS](0),
            s_axis_t_tlast[TOP_POS](0),
            Wait(~clk),
            Wait(clk),
            rst(0),
        ),
        Wait(core_rst),
        s_axis_t_tvalid[TOP_POS](0),
        s_axis_t_tlast[TOP_POS](0),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 1 : Unalligned data (left -> top)
        s_axis_t_tvalid[TOP_POS](1),
        s_axis_t_tlast[TOP_POS](0),
        For(i_op1(0), Ands(i_op1 < len(values)), i_op1(i_op1+1))(
            Wait(~clk),
            Case(((i_op1+TOP_POS) % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            # If((i_op1 + TOP_POS) % 3 == 0)(
            #     s_axis_t_tvalid[TOP_POS](0),
            #     Wait(~clk),
            #     Wait(clk),
            #     s_axis_t_tvalid[TOP_POS](1),
            # ),
            While(~s_axis_t_tready[TOP_POS])(
                Wait(~clk),
                Wait(clk),
            ),
            Wait(clk),
        ),
        Wait(err_unalligned_data),
        Wait(core_rst),
        s_axis_t_tvalid[TOP_POS](0),
        s_axis_t_tlast[TOP_POS](0),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 2 : Back to Back single burst frames (Blocked Output)
        s_axis_t_tvalid[TOP_POS](1),
        While(~core_rst)(
            Wait(~clk),
            Case((TOP_POS % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_t_tlast(1),
            Wait(clk),
        ),
        s_axis_t_tvalid[TOP_POS](0),
        s_axis_t_tlast[TOP_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Back to Back single burst frames
        s_axis_t_tvalid[TOP_POS](1),
        While(~core_rst)(
            Wait(~clk),
            Case((TOP_POS % len(values)))(
                *[
                    When(i)(data_slice(values[i]))
                        for i in range(len(values))
                ],
                When( )(data_slice(values[0])),
            ),
            s_axis_t_tlast(1),
            Wait(clk),
        ),
        s_axis_t_tvalid[TOP_POS](0),
        s_axis_t_tlast[TOP_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Nominal function
        s_axis_t_tvalid[TOP_POS](1),
        While(~core_rst)(
            For(i_op1(0), Ands(i_op1 < (len(values)**2), ~core_rst), i_op1(i_op1+1))(
                Wait(~clk),
                Case(((i_op1+TOP_POS) % len(values)))(
                    *[
                        When(i)(data_slice(values[i]))
                            for i in range(len(values))
                    ],
                    When( )(data_slice(values[0])),
                ),
                s_axis_t_tlast[TOP_POS](i_op1 == (len(values)**2-1)),
                If((i_op1 + TOP_POS) % 3 == 0)(
                    s_axis_t_tvalid[TOP_POS](0),
                    Wait(clk),
                    Wait(~clk),
                    s_axis_t_tvalid[TOP_POS](1),
                ),
                While(Ands(~s_axis_t_tready[TOP_POS],~core_rst))(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
            ),
        ),
        s_axis_t_tvalid(0),
        s_axis_t_tlast(0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )
    
    # Result coordinator
    # per_channel_i  = module.GenerateFor(chn_i(0), chn_i <PE_NUMBER_I, chn_i(chn_i+1))
    per_channel_ik = per_channel_i.GenerateFor(chn_k(0), chn_k <BATCH_SIZE, chn_k(chn_k+1))
    
    DWN_POS = per_channel_ik.Localparam('DWN_POS',chn_k * PE_NUMBER_I + chn_i)
    i_res = per_channel_ik.Integer('i_res')
    
    data_slice = m_axis_d_tdata.slice(
        msb = (DWN_POS+1)*DATA_WIDTH-1,
        lsb = DWN_POS * DATA_WIDTH
    )
    
    test3_res = np.einsum('jk,ij->ki',test3_op0,test3_op1).reshape(-1) # np.einsum('jk,ij',test3_op0,test3_op1).reshape(-1)
    test4_res = np.einsum('njk,nij->ki',test4_op0,test4_op1).reshape(-1)
    
    print(test3_res)
    print(test4_res)
    
    test3_res = (test3_res * 2**RSLT_FRACTIONAL_BITS.value).astype(f'int{2*DATA_WIDTH.value}')
    test4_res = (test4_res * 2**RSLT_FRACTIONAL_BITS.value).astype(f'int{2*DATA_WIDTH.value}')
    
    print([hex(x) for x in test3_res])
    print([hex(x) for x in test4_res])
    
    test3_res = [f"{DATA_WIDTH.value}'h{hex(x)[-(DATA_WIDTH.value+3)//4+1:]}" for x in test3_res]
    test4_res = [f"{DATA_WIDTH.value}'h{hex(x)[-(DATA_WIDTH.value+3)//4+1:]}" for x in test4_res]
        
    print(test3_res)
    print(test4_res)

    
    per_channel_ik.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Unalligned data (top -> left)
        Wait(err_unalligned_data),
        Wait(core_rst),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 1 : Unalligned data (left -> top)
        Wait(err_unalligned_data),
        Wait(core_rst),
        Wait(~err_unalligned_data),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 2 : Back to Back single burst frames (Blocked Output)
        m_axis_d_tready[DWN_POS](0),
        Wait(m_axis_d_tvalid[DWN_POS]),
        Wait(~clk),
        For(i_res(0), i_res<10 , i_res(i_res+1))(
            Wait(clk),
            Wait(~clk),
        ),
        For(i_res(0), i_res<10 , i_res(i_res+1))(
            m_axis_d_tready[DWN_POS](~m_axis_d_tready[DWN_POS]),
            Wait(clk),
            If(m_axis_d_tready[DWN_POS])(
                Wait(m_axis_d_tvalid),
            ),
            Wait(~clk),
        ),
        m_axis_d_tready[DWN_POS](0),
        For(i_res(0), i_res<10 , i_res(i_res+1))(
            Wait(clk),
            Wait(~clk),
        ),
        Wait(clk),
        If(DWN_POS == 0)(
            rst(1),
            Wait(~clk),
            Wait(clk),
            rst(0),  
        ),
        Wait(core_rst),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Back to Back single burst frames
        For(i_res(0), i_res<PE_NUMBER_I+PE_NUMBER_J+BATCH_SIZE+10 , i_res(i_res+1))(
            Wait(~clk),
            m_axis_d_tready[DWN_POS](1),
            While(~m_axis_d_tvalid[DWN_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            AssertTrue(m_axis_d_tlast[DWN_POS]),
            Case(DWN_POS)(*[
                    When(dwn_pos)(
                        Assert(data_slice,(test3_res[dwn_pos])),
                    ) for dwn_pos in range(len(test3_res))
                ],
                When()(AssertTrue(0)),
            ),
            Wait(clk),
        ),
        Wait(~clk),
        m_axis_d_tready[DWN_POS](0),
        If(DWN_POS == 0)(
            Wait(m_axis_d_tready == 0),
            rst(1),
            Wait(clk),
            Wait(~clk),
            rst(0),  
        ),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Nominal function
        Wait(~clk),
        m_axis_d_tready[DWN_POS](1),
        For(i_res(0), i_res<2, i_res(i_res+1))(
            While(~m_axis_d_tvalid[DWN_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            If(~m_axis_d_tready[DWN_POS])(
                Wait(clk),
                m_axis_d_tready[DWN_POS](1),
                Wait(~clk),
            ),
            If(m_axis_d_tvalid[DWN_POS])(
            AssertTrue(m_axis_d_tlast[DWN_POS]),
                Case(DWN_POS)(*[
                        When(dwn_pos)(
                            Display('Time -- %0t', EmbeddedNumeric('$time')),
                            Display('%d -- %h', data_slice,data_slice),
                            Assert(data_slice,test4_res[dwn_pos]),
                        ) for dwn_pos in range(len(test4_res))
                    ],
                    When()(),
                ),
            ),
            Wait(clk),
            Wait(~clk),
            m_axis_d_tready[DWN_POS](0),
        ),
        Wait(clk),
        If(DWN_POS == 0)(
            Wait(m_axis_d_tready == 0),
            rst(1),
            Wait(~clk),
            Wait(clk),
            rst(0),  
        ),
        Wait(core_rst),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
        
        Delay(5),
        Finish()
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = ParallelizedLinearProcessingArray()
    # # fname = os.path.join(TOP_DIR,'rtl/ParallelizedLinearProcessingArray.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'ParallelizedLinearProcessingArray')
    # addTimeScale(fname)
    # exit()
    
    for I,J,K in (
        (1,1,1),
        # (5,5,5),
    ):
        test = tb_ParallelizedLinearProcessingArray(I=I,J=J,K=K)
        fname_base = f'tb_ParallelizedLinearProcessingArray_{I}_{J}_{K}'
        fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'ParallelizedLinearProcessingArray')
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
