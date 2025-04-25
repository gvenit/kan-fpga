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

def LinearProcessingArray():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/wrapper/LPArray_wrapper.v')
    )['LPArray_wrapper'] 

def tb_LinearProcessingArray():
    module = Module('tb_LinearProcessingArray')

    # lpu = LinearProcessingArray()
    # params = module.copy_params_as_localparams(lpu)
    # ports  = module.copy_ports_as_vars(lpu)

    PE_NUMBER_I          = module.Localparam('PE_NUMBER_I', 1)
    PE_NUMBER_J          = module.Localparam('PE_NUMBER_J', 1)
    DATA_WIDTH           = module.Localparam('DATA_WIDTH', 16)
    OP0_FRACTIONAL_BITS  = module.Localparam('OP0_FRACTIONAL_BITS', 13)
    OP1_FRACTIONAL_BITS  = module.Localparam('OP1_FRACTIONAL_BITS', 15)
    RSLT_FRACTIONAL_BITS = module.Localparam('RSLT_FRACTIONAL_BITS', 13)
    IS_UNSIGNED_OP0      = module.Localparam('IS_UNSIGNED_OP0', 1)
    INTERNAL_RESET       = module.Localparam('INTERNAL_RESET', 0)
    USER_WIDTH           = module.Localparam('USER_WIDTH', 1)

    clk = module.Reg('clk')
    rst = module.Reg('rst')
    
    s_axis_up_tdata  = module.Reg('s_axis_up_tdata', DATA_WIDTH* PE_NUMBER_I)
    s_axis_up_tlast  = module.Reg('s_axis_up_tlast', PE_NUMBER_I)
    s_axis_up_tvalid = module.Reg('s_axis_up_tvalid', PE_NUMBER_I)
    s_axis_up_tready = module.Wire('s_axis_up_tready', PE_NUMBER_I)
    s_axis_up_tuser  = module.Reg('s_axis_up_tuser', USER_WIDTH* PE_NUMBER_I)
    # s_axis_up_tid    = module.Reg('s_axis_up_tid', 1, PE_NUMBER_I)
    # s_axis_up_tdest  = module.Reg('s_axis_up_tdest', 1, PE_NUMBER_I)
    
    s_axis_left_tdata  = module.Reg('s_axis_left_tdata', DATA_WIDTH* PE_NUMBER_J)
    s_axis_left_tlast  = module.Reg('s_axis_left_tlast', PE_NUMBER_J)
    s_axis_left_tvalid = module.Reg('s_axis_left_tvalid', PE_NUMBER_J)
    s_axis_left_tready = module.Wire('s_axis_left_tready', PE_NUMBER_J)
    
    m_axis_down_tdata  = module.Wire('m_axis_down_tdata', DATA_WIDTH* PE_NUMBER_I)
    m_axis_down_tlast  = module.Wire('m_axis_down_tlast', PE_NUMBER_I)
    m_axis_down_tvalid = module.Wire('m_axis_down_tvalid', PE_NUMBER_I)
    m_axis_down_tready = module.Reg('m_axis_down_tready', PE_NUMBER_I)
    m_axis_down_tuser  = module.Wire('m_axis_down_tuser', USER_WIDTH* PE_NUMBER_I)
    # m_axis_down_tid    = module.Wire('m_axis_down_tid')
    # m_axis_down_tdest  = module.Wire('m_axis_down_tdest')
    
    err_unalligned_data = module.Wire('err_unalligned_data')
    err_user_flag       = module.Wire('err_user_flag')
    
    core_rst            = module.Wire('core_rst')
    
    reset_done = module.Reg('reset_done', initval=0)

    # uut = module.Instance(
    #     lpu,
    #     'uut',
    #     params,
    #     ports
    # )
    
    module.EmbeddedCode('''LinearProcessingArray #(
  .PE_NUMBER_I(PE_NUMBER_I),
  .PE_NUMBER_J(PE_NUMBER_J),
  .INTERNAL_RESET(INTERNAL_RESET),
  .OP0_WIDTH(DATA_WIDTH),
  .OP0_FRACTIONAL_BITS(OP0_FRACTIONAL_BITS),
  .IS_UNSIGNED_OP0(IS_UNSIGNED_OP0),
  .OP1_WIDTH(DATA_WIDTH),
  // .IS_UNSIGNED_OP1(IS_UNSIGNED_OP1),
  .OP1_FRACTIONAL_BITS(OP1_FRACTIONAL_BITS),
  .RSLT_WIDTH(DATA_WIDTH),
  .RSLT_FRACTIONAL_BITS(RSLT_FRACTIONAL_BITS),
  .ID_ENABLE(0),
  // .ID_WIDTH(ID_WIDTH),
  .DEST_ENABLE(0),
  // .DEST_WIDTH(DEST_WIDTH),
  .USER_ENABLE(USER_WIDTH>1),
  .USER_WIDTH(USER_WIDTH)
  // .OUTPUT_DEST(OUTPUT_DEST),
  // .OUTPUT_ID(OUTPUT_ID),
  // .U_D_WIDTH(U_D_WIDTH),
  // .L_R_WIDTH(L_R_WIDTH)  
) ''')
    uut = module.EmbeddedCode('uut')
    module.EmbeddedCode(''' (
  .clk(clk),
  .rst(rst),
  .s_axis_up_tdata(s_axis_up_tdata),
  .s_axis_up_tvalid(s_axis_up_tvalid),
  .s_axis_up_tready(s_axis_up_tready),
  .s_axis_up_tlast(s_axis_up_tlast),
  // .s_axis_up_tid(s_axis_up_tid),
  // .s_axis_up_tdest(s_axis_up_tdest),
  .s_axis_up_tuser(s_axis_up_tuser),
  .s_axis_left_tdata(s_axis_left_tdata),
  .s_axis_left_tvalid(s_axis_left_tvalid),
  .s_axis_left_tready(s_axis_left_tready),
  .s_axis_left_tlast(s_axis_left_tlast),
  // .s_axis_left_tid(s_axis_left_tid),
  // .s_axis_left_tdest(s_axis_left_tdest),
  // .s_axis_left_tuser(s_axis_left_tuser),
  .m_axis_down_tdata(m_axis_down_tdata),
  .m_axis_down_tvalid(m_axis_down_tvalid),
  .m_axis_down_tready(m_axis_down_tready),
  .m_axis_down_tlast(m_axis_down_tlast),
  // .m_axis_down_tid(m_axis_down_tid),
  // .m_axis_down_tdest(m_axis_down_tdest),
  .m_axis_down_tuser(m_axis_down_tuser),
  .err_unalligned_data(err_unalligned_data),
  .err_user_flag(err_user_flag),
  .core_rst(core_rst)
);''')
    
    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_left_tdata(0))
    reset_stmt.append(s_axis_left_tvalid(0))
    reset_stmt.append(s_axis_left_tlast(0))

    reset_stmt.append(s_axis_up_tdata(0))
    reset_stmt.append(s_axis_up_tlast(0))
    reset_stmt.append(s_axis_up_tvalid(0))

    reset_stmt.append(m_axis_down_tready(0))

    vcd_name = os.path.join('..','vcd','tb_LinearProcessingArray.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock
    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        If(USER_WIDTH > 1)(
            s_axis_up_tuser(int('DEADBEEFCAFEBABE', base=16)),
        ),
        nclk(clk),
        # s_axis_up_tdest(1),
        # s_axis_up_tid(0),
        Delay(500),
        # Delay(10),
        Systask('finish'),
    )

    values = [
        -4 << 13, 
        -1 << 12, 
         1,
         1 << 12, 
         4 << 13 
    ]
    chn = module.Genvar('CHN')
    per_channel = module.GenerateFor(chn(0), chn <PE_NUMBER_I+PE_NUMBER_J, chn(chn+1))

    # count_op0  = module.Integer('count_op0')
    # count_op1  = module.Integer('count_op1')
    # count2_op0 = module.Integer('count2_op0')
    # count2_op1 = module.Integer('count2_op1')
    # timer_op0  = module.Integer('timer_op0')
    # timer_op1  = module.Integer('timer_op1')
    i_op0      = per_channel.TmpInteger()
    i_op1      = per_channel.TmpInteger()
    frame_op0  = per_channel.Integer('frame_op0')
    frame_op1  = per_channel.Integer('frame_op1')

    per_channel.Initial(
        Wait(reset_done),
        If(chn < PE_NUMBER_J)(
            Wait(s_axis_left_tready == EmbeddedNumeric(r"{PE_NUMBER_J{1'b1}}"))
        ),
        If(chn < PE_NUMBER_I)(
            Wait(s_axis_up_tready == EmbeddedNumeric(r"{PE_NUMBER_I{1'b1}}"))
        ),
        
        # Add delay to channels
        For(i_op0(0), i_op0 < chn, i_op0(i_op0+1))(
            Wait(Not(clk)),
            Wait(clk),
        ),
        # Start data streaming
        If(chn < PE_NUMBER_I)(
            s_axis_up_tvalid[chn](1),
            m_axis_down_tready[chn](0),
        ),
        If(chn < PE_NUMBER_J)(
            s_axis_left_tvalid[chn](1),
        ),
        For(i_op0(chn), i_op0 < chn + 25, i_op0(i_op0+1))(
            If(chn < PE_NUMBER_J)(
                Case(i_op0 % 5)(
                    When(4)(s_axis_left_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[4])),
                    When(3)(s_axis_left_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[3])),
                    When(2)(s_axis_left_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[2])),
                    When(1)(s_axis_left_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[1])),
                    When( )(s_axis_left_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[0])),
            )),
            If(chn < PE_NUMBER_I)(
                Case((i_op0 // 5) % 5)(
                    When(4)(s_axis_up_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[4])),
                    When(3)(s_axis_up_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[3])),
                    When(2)(s_axis_up_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[2])),
                    When(1)(s_axis_up_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[1])),
                    When( )(s_axis_up_tdata.slice(
                        msb=(chn+1)*DATA_WIDTH-1,
                        lsb=chn*DATA_WIDTH
                    )(values[0])),
                ),
                m_axis_down_tready[chn](Not(m_axis_down_tready[chn])),
            ),
            Wait(Not(clk)),
            Wait(clk),
        ),
        # Set asynchronized TLAST signals
        s_axis_left_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[4]),
        s_axis_up_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[4]),
        s_axis_up_tlast[chn](1),
        Wait(Not(clk)),
        Wait(clk),
        
        s_axis_left_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[0]),
        s_axis_up_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[0]),
        s_axis_up_tlast[chn](0),
        Wait(Not(clk)),
        Wait(clk),
        
        s_axis_left_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[0]),
        s_axis_up_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[1]),
        s_axis_left_tlast[chn](1),
        Wait(Not(clk)),
        Wait(clk),
        
        s_axis_left_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[0]),
        s_axis_up_tdata.slice(
            msb=(chn+1)*DATA_WIDTH-1,
            lsb=chn*DATA_WIDTH
        )(values[2]),
        s_axis_left_tlast[chn](0),
        Wait(Not(clk)),
        Wait(clk),
        
        s_axis_up_tvalid[chn](0),
        s_axis_left_tvalid[chn](0),
        m_axis_down_tready[chn](0),
        If(Ands(~INTERNAL_RESET, ~core_rst))(
            rst(1),
            # For(i_op0(0), i_op0 < 5, i_op0(i_op0+1))(
                Wait(Not(clk)),
                Wait(clk),
                Wait(Not(clk)),
                Wait(clk),
            # ),
            rst(0),
        ),
        
        s_axis_up_tvalid[chn](0),
        s_axis_left_tvalid[chn](0),
        m_axis_down_tready[chn](0),
        Wait(~core_rst),
        
        If(chn < PE_NUMBER_J)(
            Wait(s_axis_left_tready == EmbeddedNumeric(r"{PE_NUMBER_J{1'b1}}"))
        ),
        If(chn < PE_NUMBER_I)(
            Wait(s_axis_up_tready == EmbeddedNumeric(r"{PE_NUMBER_I{1'b1}}"))
        ),
        # # Add delay to channels
        
        # Restart data streaming
        # s_axis_up_tvalid[chn](1),
        # s_axis_left_tvalid[chn](1),
        # m_axis_down_tready[chn](1),
        
        i_op0(chn),
        i_op1(chn),
        frame_op0(0),
        frame_op1(0),
        While(~Ands(frame_op0, frame_op1)) (
            # If(Ors(chn < PE_NUMBER_J, chn < PE_NUMBER_J))(
            #     Display(
            #         "Channel %1d - %2d:%2d -- %1d:%1d -> %1d", chn, i_op0, i_op1, frame_op0, frame_op1, ~Ands(frame_op0, frame_op1)
            #     ),
            # ),
            If(chn < PE_NUMBER_J)(
                If(i_op0 > chn + 10) (
                    s_axis_left_tlast[chn](0),
                    s_axis_left_tvalid[chn](0),
                ).Elif(i_op0 == chn + 10)(
                    s_axis_left_tlast[chn](1),
                    s_axis_left_tvalid[chn](1),
                    frame_op0(1),
                ).Else(
                    s_axis_left_tlast[chn](0),
                    s_axis_left_tvalid[chn](1),
                ),
                s_axis_left_tdata.slice(
                    msb=(chn+1)*DATA_WIDTH-1,
                    lsb=chn*DATA_WIDTH
                )( (i_op0 ** (chn+1)) << OP0_FRACTIONAL_BITS-3 ),
            ),
            If(chn < PE_NUMBER_I)(
                If(i_op1 > chn + 10) (
                    s_axis_up_tlast[chn](0),
                    s_axis_up_tvalid[chn](0),
                ).Elif(i_op1 == chn + 10)(
                    s_axis_up_tlast[chn](1),
                    s_axis_up_tvalid[chn](1),
                    frame_op1(1),
                ).Else(
                    s_axis_up_tlast[chn](0),
                    s_axis_up_tvalid[chn](1),
                ),
                s_axis_up_tdata.slice(
                    msb=(chn+1)*DATA_WIDTH-1,
                    lsb=chn*DATA_WIDTH
                )( ((i_op1-5) ** (chn+1)) << OP1_FRACTIONAL_BITS-4 ),
                m_axis_down_tready[chn](Not(m_axis_down_tready[chn])),
                # m_axis_down_tready[chn](1),
            ),
            Wait(Not(clk)),
            Wait(clk),
            If(s_axis_left_tready[chn])(i_op0(i_op0+1)),
            If(s_axis_up_tready[chn])(i_op1(i_op1+1)),
        ),
        If(chn < PE_NUMBER_I)(
            s_axis_up_tvalid[chn](0),
            s_axis_up_tlast[chn](0),
            m_axis_down_tready[chn](0),
        ),
        If(chn < PE_NUMBER_J)(
            s_axis_left_tvalid[chn](0),
            s_axis_left_tlast[chn](0),
        ),
        
        # Test Master Axis
        For(i_op0(0), i_op0 < PE_NUMBER_I + 2 - chn, i_op0(i_op0+1))(
            Wait(Not(clk)),
            Wait(clk),
        ),
        m_axis_down_tready[chn](1),
        For(i_op0(0), i_op0 < PE_NUMBER_I, i_op0(i_op0+1))(
            Wait(Not(clk)),
            Wait(clk),
        ),
        Delay(20),
        If (chn == 0)(Systask('finish')),
    )

    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = LinearProcessingArray()
    # # fname = os.path.join(TOP_DIR,'rtl/LinearProcessingArray.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'LinearProcessingArray')
    # addTimeScale(fname)
    # exit()
    
    test = tb_LinearProcessingArray()
    fname = os.path.join(TOP_DIR,'tb/tb_LinearProcessingArray.v')
    verilog_test = test.to_verilog(fname)
    stripModule(fname, 'LinearProcessingArray')
    addTimeScale(fname)
    # exit()

    os.system(' '.join([
        os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
        '-v',
        '-p',
        'LinearProcessingArray',
    ]))

if __name__ == "__main__":
    main()
