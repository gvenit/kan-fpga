from __future__ import absolute_import
from __future__ import print_function
import numpy as np
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

def DataProcessor():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/DataProcessor.v')
    )['DataProcessor'] 

def tb_DataProcessor():
    module = Module('tb_DataProcessor')
    
    DATA_WIDTH                  = module.Localparam('DATA_WIDTH', 16)
    FRACTIONAL_BITS_DATA        = module.Localparam('FRACTIONAL_BITS_DATA', 12)
    FRACTIONAL_BITS_SCALE       = module.Localparam('FRACTIONAL_BITS_SCALE', 15)
    FRACTIONAL_BITS_SCALED_DIFF = module.Localparam('FRACTIONAL_BITS_SCALED_DIFF', 13)
    FRACTIONAL_BITS_ACT         = module.Localparam('FRACTIONAL_BITS_ACT', 16)
    FRACTIONAL_BITS_WEIGHT      = module.Localparam('FRACTIONAL_BITS_WEIGHT', 16)
    FRACTIONAL_BITS_RSLT        = module.Localparam('FRACTIONAL_BITS_RSLT', 12)
    IS_UNSIGNED_OP0             = module.Localparam('IS_UNSIGNED_OP0', 1)
    INTERNAL_RESET              = module.Localparam('INTERNAL_RESET', 0)
    USER_WIDTH                  = module.Localparam('USER_WIDTH', 1)

    DATA_CHANNELS               = module.Localparam('DATA_CHANNELS', 1)
    WEIGHT_CHANNELS             = module.Localparam('WEIGHT_CHANNELS', 1)
    SHARE_SCALE                 = module.Localparam('SHARE_SCALE', 1)
    ROM_DATA_PATH               = module.Localparam('ROM_DATA_PATH', f"../data/Sech2Lutram_n_{DATA_WIDTH.value}.{FRACTIONAL_BITS_SCALED_DIFF.value}_{DATA_WIDTH.value}.{FRACTIONAL_BITS_ACT.value}.txt")
    
    clk = module.Reg('clk')
    rst = module.Reg('rst')
    
    s_axis_data_tdata  = module.Reg('s_axis_data_tdata', DATA_WIDTH* DATA_CHANNELS)
    s_axis_data_tlast  = module.Reg('s_axis_data_tlast', DATA_CHANNELS)
    s_axis_data_tvalid = module.Reg('s_axis_data_tvalid', DATA_CHANNELS)
    s_axis_data_tready = module.Wire('s_axis_data_tready', DATA_CHANNELS)
    s_axis_data_tuser  = module.Reg('s_axis_data_tuser', USER_WIDTH* DATA_CHANNELS)
    
    s_axis_grid_tdata  = module.Reg('s_axis_grid_tdata', DATA_WIDTH* DATA_CHANNELS)
    s_axis_grid_tlast  = module.Reg('s_axis_grid_tlast', DATA_CHANNELS)
    s_axis_grid_tvalid = module.Reg('s_axis_grid_tvalid', DATA_CHANNELS)
    s_axis_grid_tready = module.Wire('s_axis_grid_tready', DATA_CHANNELS)
    s_axis_grid_tuser  = module.Reg('s_axis_grid_tuser', USER_WIDTH* DATA_CHANNELS)
    
    s_axis_scale_tdata  = module.Reg('s_axis_scale_tdata', DATA_WIDTH )
    s_axis_scale_tlast  = module.Reg('s_axis_scale_tlast')
    s_axis_scale_tvalid = module.Reg('s_axis_scale_tvalid')
    s_axis_scale_tready = module.Wire('s_axis_scale_tready')
    s_axis_scale_tuser  = module.Reg('s_axis_scale_tuser', USER_WIDTH)
    
    s_axis_weight_tdata  = module.Reg('s_axis_weight_tdata', DATA_WIDTH* WEIGHT_CHANNELS)
    s_axis_weight_tlast  = module.Reg('s_axis_weight_tlast', WEIGHT_CHANNELS)
    s_axis_weight_tvalid = module.Reg('s_axis_weight_tvalid', WEIGHT_CHANNELS)
    s_axis_weight_tready = module.Wire('s_axis_weight_tready', WEIGHT_CHANNELS)
    
    m_axis_data_tdata  = module.Wire('m_axis_data_tdata', DATA_WIDTH* WEIGHT_CHANNELS)
    m_axis_data_tlast  = module.Wire('m_axis_data_tlast', WEIGHT_CHANNELS)
    m_axis_data_tvalid = module.Wire('m_axis_data_tvalid', WEIGHT_CHANNELS)
    m_axis_data_tready = module.Reg('m_axis_data_tready', WEIGHT_CHANNELS)
    m_axis_data_tuser  = module.Wire('m_axis_data_tuser', USER_WIDTH* WEIGHT_CHANNELS)
    # m_axis_data_tid    = module.Wire('m_axis_data_tid')
    # m_axis_data_tdest  = module.Wire('m_axis_data_tdest')
    
    err_unalligned_data = module.Wire('err_unalligned_data')
    err_user_flag       = module.Wire('err_user_flag')
    
    core_rst            = module.Wire('core_rst')
    
    reset_done = module.Reg('reset_done', initval=0)
    
    module.EmbeddedCode('''DataProcessor #(
  // Width of AXI stream Input Data & Grid interfaces in bits
  .DATA_WIDTH_DATA(DATA_WIDTH),
  // Fractional bits of input data & grid
  .FRACTIONAL_BITS_DATA(FRACTIONAL_BITS_DATA),
  // Width of AXI stream Scale interface in bits
  .DATA_WIDTH_SCALE(DATA_WIDTH),
  // Fractional bits of input scale
  .FRACTIONAL_BITS_SCALE(FRACTIONAL_BITS_SCALE),
  // Width of AXI stream Input Weight interface in bits
  .DATA_WIDTH_WEIGHT(DATA_WIDTH),
  // Fractional bits of output data
  .FRACTIONAL_BITS_WEIGHT(FRACTIONAL_BITS_WEIGHT),
  // Width of Scaled Data in bits
  .DATA_WIDTH_SCALED_DIFF(DATA_WIDTH),
  // Fractional bits of Scaled Data
  .FRACTIONAL_BITS_SCALED_DIFF(FRACTIONAL_BITS_SCALED_DIFF),
  // Width of AXI stream Activation Function Data interface in bits
  .DATA_WIDTH_ACT(DATA_WIDTH),
  // Fractional bits of Activation Function Data
  .FRACTIONAL_BITS_ACT(FRACTIONAL_BITS_ACT),
  // Width of AXI stream Output Data interface in bits
  .DATA_WIDTH_RSLT(DATA_WIDTH),
  // Fractional bits of output data
  .FRACTIONAL_BITS_RSLT(FRACTIONAL_BITS_RSLT),
  // Propagate tkeep signal
  .KEEP_ENABLE(0),
  // tkeep signal width (words per cycle)
  .KEEP_WIDTH(1),
  // Propagate tid signal
  .ID_ENABLE(0),
  // tid signal width
  .ID_WIDTH(1),
  // Propagate tdest signal
  .DEST_ENABLE(0),
  // tdest signal width
  .DEST_WIDTH(1),
  // Propagate tuser signal
  .USER_ENABLE(0),
  // tuser signal width
  .USER_WIDTH(1),
  // Number of Independent AXI-Stream Data Channels
  .DATA_CHANNELS(DATA_CHANNELS),
  // Number of Independent AXI-Stream Weight Channels
  .WEIGHT_CHANNELS(WEIGHT_CHANNELS),
  // Use Common Share Channel 
  .SHARE_SCALE(SHARE_SCALE),
  // Path to ROM Data
  .ROM_DATA_PATH(ROM_DATA_PATH),
  // Output Destination 
  .OUTPUT_DEST(0),
  // Output Thread ID 
  .OUTPUT_ID(1)
) ''')
    uut = module.EmbeddedCode('uut')
    module.EmbeddedCode(''' (
  .clk(clk),
  .rst(rst),
  .s_axis_data_tdata(s_axis_data_tdata),
  .s_axis_data_tvalid(s_axis_data_tvalid),
  .s_axis_data_tready(s_axis_data_tready),
  .s_axis_data_tlast(s_axis_data_tlast),
  // .s_axis_data_tid(s_axis_data_tid),
  // .s_axis_data_tdest(s_axis_data_tdest),
  .s_axis_data_tuser(s_axis_data_tuser),
  .s_axis_grid_tdata(s_axis_grid_tdata),
  .s_axis_grid_tvalid(s_axis_grid_tvalid),
  .s_axis_grid_tready(s_axis_grid_tready),
  .s_axis_grid_tlast(s_axis_grid_tlast),
  // .s_axis_grid_tid(s_axis_grid_tid),
  // .s_axis_grid_tdest(s_axis_grid_tdest),
  .s_axis_grid_tuser(s_axis_grid_tuser),
  .s_axis_scale_tdata(s_axis_scale_tdata),
  .s_axis_scale_tvalid(s_axis_scale_tvalid),
  .s_axis_scale_tready(s_axis_scale_tready),
  .s_axis_scale_tlast(s_axis_scale_tlast),
  // .s_axis_scale_tid(s_axis_scale_tid),
  // .s_axis_scale_tdest(s_axis_scale_tdest),
  .s_axis_scale_tuser(s_axis_scale_tuser),
  .s_axis_weight_tdata(s_axis_weight_tdata),
  .s_axis_weight_tvalid(s_axis_weight_tvalid),
  .s_axis_weight_tready(s_axis_weight_tready),
  .s_axis_weight_tlast(s_axis_weight_tlast),
  // .s_axis_weight_tid(s_axis_weight_tid),
  // .s_axis_weight_tdest(s_axis_weight_tdest),
  // .s_axis_weight_tuser(s_axis_weight_tuser),
  .m_axis_data_tdata(m_axis_data_tdata),
  .m_axis_data_tvalid(m_axis_data_tvalid),
  .m_axis_data_tready(m_axis_data_tready),
  .m_axis_data_tlast(m_axis_data_tlast),
  // .m_axis_data_tid(m_axis_data_tid),
  // .m_axis_data_tdest(m_axis_data_tdest),
  .m_axis_data_tuser(m_axis_data_tuser),
  .err_unalligned_data(err_unalligned_data),
  .err_user_flag(err_user_flag),
  .core_rst(core_rst)
);''')
    
    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_data_tlast(0))
    reset_stmt.append(s_axis_data_tvalid(0))
    
    reset_stmt.append(s_axis_grid_tlast(0))
    reset_stmt.append(s_axis_grid_tvalid(0))
    
    reset_stmt.append(s_axis_scale_tlast(0))
    reset_stmt.append(s_axis_scale_tvalid(0))
    
    reset_stmt.append(s_axis_weight_tvalid(0))
    reset_stmt.append(s_axis_weight_tlast(0))

    reset_stmt.append(m_axis_data_tready(0))

    vcd_name = os.path.join('..','vcd','tb_DataProcessor.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock
    
    init.add(
        Delay(10),
        reset_done(1),
        nclk(clk),
        # Delay(500),
        # Delay(10),
        # Finish(),
    )
    
    batch_size = DATA_CHANNELS.value
    input_layer_size = 5
    grid_size = 5
    output_layer_size = WEIGHT_CHANNELS.value
    
    np.random.seed(123)

    x               = np.random.randn(batch_size,input_layer_size)
    grid            = np.linspace(-1,1,num=grid_size).reshape(1,-1)
    scale           = np.array(0.25)
    weights         = 0.5-np.random.rand(input_layer_size * grid_size, output_layer_size)
    diff            = x.reshape((batch_size,-1,1)) - np.array([grid for _ in range(batch_size)]).reshape((batch_size,1,-1))
    
    scaled_diff     = scale * diff.reshape(-1, weights.shape[0])
    act_func_data   = 1-np.tanh(scaled_diff)**2
    y               = act_func_data@weights
    
    x_int           = (x       * 2 ** FRACTIONAL_BITS_DATA.value).astype('int16').astype('uint16').T.reshape(-1)
    grid_int        = (grid    * 2 ** FRACTIONAL_BITS_DATA.value).astype('int16').astype('uint16').reshape(-1)
    scale_int       = (scale   * 2 ** FRACTIONAL_BITS_SCALE.value).astype('int16').astype('uint16')
    weights_int     = (weights * 2 ** FRACTIONAL_BITS_WEIGHT.value).astype('int16').astype('uint16').T.reshape(-1)
    y_int           = (y       * 2 ** FRACTIONAL_BITS_RSLT.value).astype('int16').astype('uint16').reshape(-1)
    
    x_int = [hex(x_i)[2:] for x_i in x_int]
    grid_int = [hex(x_i)[2:] for x_i in grid_int]
    weights_int = [hex(x_i)[2:] for x_i in weights_int]
    y_int = [hex(x_i)[2:] for x_i in y_int]
    
    x_int.reverse()
    grid_int.reverse()
    # weights_int.reverse()
    y_int.reverse()
    
    print('Expected output :')
    # print(x.shape, grid.shape, weights.shape, diff.shape, scaled_diff.shape, act_func_data.shape, y.shape)
    # print(x_int[:10])
    print(*y_int)
    
    data_array = module.Reg(
        'data_array', 
        input_layer_size*DATA_CHANNELS*DATA_WIDTH, 
    )
    grid_array = module.Reg(
        'grid_array', 
        grid_size*DATA_WIDTH, 
    )
    # weight_array = module.Reg(
    #     'weight_array', 
    #     input_layer_size*WEIGHT_CHANNELS*DATA_WIDTH,
    # )
    
    # Array Initialization
    # tmp = module.TmpInteger()
    module.Initial(
        data_array(Cat(*[EmbeddedNumeric(f"{DATA_WIDTH.value}'h{x_i}") for x_i in x_int])),
        grid_array(Cat(*[EmbeddedNumeric(f"{DATA_WIDTH.value}'h{x_i}") for x_i in grid_int])),
        # weight_array(Cat(*[EmbeddedNumeric(f"{DATA_WIDTH.value}'h{x_i}") for x_i in weights_int])),
    )
    
    
    # Scale coordinator
    module.Initial(
        Display('Data: %x', data_array),
        Display('%x', data_array.slice(15,0)),
        Display('Grid: %x', grid_array),
        # Display('Weight: %x', weight_array),
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_scale_tready),
        Wait(~clk),
        Wait(clk),
        
        s_axis_scale_tdata(int(scale_int)),
        s_axis_scale_tvalid(1),
        s_axis_scale_tlast(1),
        Wait(~clk),
        While(~s_axis_data_tready)(
            Wait(clk), 
            Wait(~clk),
        ),
        Wait(clk),
        Wait(~clk),
        
        s_axis_scale_tvalid(0),
        s_axis_scale_tlast(0),
    )

    data_chn = module.Genvar('data_chn')
    per_data_channel = module.GenerateFor(data_chn(0), data_chn < DATA_CHANNELS,data_chn(data_chn+1))
    i_data   = per_data_channel.Integer('i_data')
    i_grid   = per_data_channel.Integer('i_grid')
    
    # Input Data coordinator

    per_data_channel.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_data_tready[data_chn]),
        Wait(~clk),
        # Wait(clk),
        
        s_axis_data_tvalid[data_chn](1),
        For(i_data(0), i_data < input_layer_size * grid_size, i_data(i_data+1))(
            Case(i_data / grid_size)(
                *[When(i)(s_axis_data_tdata.slice(
                    msb = (data_chn+1)*DATA_WIDTH-1,
                    lsb = data_chn * DATA_WIDTH
                )(
                    data_array.slice(
                        msb = (i*DATA_CHANNELS+data_chn+1)*DATA_WIDTH-1,
                        lsb = (i*DATA_CHANNELS+data_chn) * DATA_WIDTH
                    )
                )) for i in range(input_layer_size)],
                When( )(s_axis_data_tdata.slice(
                    msb = (data_chn+1)*DATA_WIDTH-1,
                    lsb = data_chn * DATA_WIDTH
                )(0))
            ),
            s_axis_data_tlast[data_chn](i_data == (input_layer_size * grid_size-1)),
            Wait(clk),
            While(~s_axis_data_tready[data_chn])(
                Wait(~clk),
                Wait(clk),
            ),
            Wait(~clk),
        ),
        s_axis_data_tvalid[data_chn](0),
        s_axis_data_tlast[data_chn](0),
    )
    
    # Input Grid coordinator
    per_data_channel.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_grid_tready[data_chn]),
        Wait(~clk),
        # Wait(clk),
        
        s_axis_grid_tvalid[data_chn](1),
        For(i_grid(0), i_grid < input_layer_size * grid_size, i_grid(i_grid+1))(
            Case(i_grid % grid_size)(
                *[When(i)(s_axis_grid_tdata.slice(
                    msb = (data_chn+1)*DATA_WIDTH-1,
                    lsb = data_chn * DATA_WIDTH
                )(
                    grid_array[i]
                )) for i in range(grid_size)],
                When( )(s_axis_grid_tdata.slice(
                    msb = (data_chn+1)*DATA_WIDTH-1,
                    lsb = data_chn * DATA_WIDTH
                )(0))
            ),
            s_axis_grid_tlast[data_chn](i_grid == (input_layer_size * grid_size-1)),
            Wait(clk),
            While(~s_axis_grid_tready[data_chn])(
                Wait(~clk),
                Wait(clk),
            ),
            Wait(~clk),
        ),
        s_axis_grid_tvalid[data_chn](0),
        s_axis_grid_tlast[data_chn](0),
    )

    weight_chn = module.Genvar('weight_chn')
    per_weight_channel = module.GenerateFor(weight_chn(0), weight_chn < DATA_CHANNELS,weight_chn(weight_chn+1))
    i_weight = per_weight_channel.Integer('i_weight')
    
    # Weights coordinator
    per_weight_channel.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_weight_tready[weight_chn]),
        Wait(~clk),
        # Wait(clk),
        
        s_axis_weight_tvalid(1),
        For(i_weight(0), i_weight < len(weights_int), i_weight(i_weight+1))(
            Case(i_weight)(
                *[
                    When(i)( s_axis_weight_tdata.slice(
                        msb = (weight_chn+1)*DATA_WIDTH-1,
                        lsb = weight_chn * DATA_WIDTH
                    )(
                        # weight_array.slice(
                        #     msb = (i*WEIGHT_CHANNELS+weight_chn+1)*DATA_WIDTH-1,
                        #     lsb = (i*WEIGHT_CHANNELS+weight_chn) * DATA_WIDTH
                        # )
                        EmbeddedNumeric(f"{DATA_WIDTH.value}'h{x_i}")
                    )) 
                    for i, x_i in enumerate(weights_int)
                    # for i in range(len(weights_int))
                ],
                When( )(s_axis_weight_tdata.slice(
                    msb = (weight_chn+1)*DATA_WIDTH-1,
                    lsb = weight_chn * DATA_WIDTH
                )(0))
            ),
            s_axis_weight_tlast[weight_chn](i_weight == (len(weights_int)-1)),
            Wait(clk),
            While(~s_axis_weight_tready[weight_chn])(
                Wait(~clk),
                Wait(clk),
            ),
            Wait(~clk),
        ),
        s_axis_weight_tvalid[weight_chn](0),
        s_axis_weight_tlast[weight_chn](0),
    )
    
    finished = module.Reg('finished',WEIGHT_CHANNELS, initval=0)
    
    # Output coordinator
    per_weight_channel.Initial(
        Wait(reset_done),
        
        Wait(m_axis_data_tvalid[weight_chn]),
        Wait(clk),
        m_axis_data_tready[weight_chn](1),
        
        Wait(~m_axis_data_tvalid[weight_chn]),
        Wait(clk),
        m_axis_data_tready[weight_chn](0),
        finished[weight_chn](1),
        
        If(weight_chn == 0)(
            Wait(EmbeddedNumeric('&finished')),
            Delay(25),
            Finish()
        )
    )
    
    return module


def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)

    # module = DataProcessor()
    # # fname = os.path.join(TOP_DIR,'rtl/DataProcessor.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'DataProcessor')
    # addTimeScale(fname)
    # exit()
    
    test = tb_DataProcessor()
    fname = os.path.join(TOP_DIR,'tb/tb_DataProcessor.v')
    verilog_test = test.to_verilog(fname)
    stripModule(fname, 'DataProcessor')
    addTimeScale(fname)
    # exit()

    os.system(' '.join([
        os.path.join(TOP_DIR,'aux/run_sim.sh'),
        '-v',
        '-p',
        'DataProcessor',
    ]))

if __name__ == "__main__":
    main()
