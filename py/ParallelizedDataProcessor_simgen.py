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
import torch

def ParallelizedDataProcessor():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/ParallelizedDataProcessor.v')
    )['ParallelizedDataProcessor'] 

def tb_ParallelizedDataProcessor(I=1,J=1,K=1,N_in=256,N_out=256):
    module = Module(f'tb_ParallelizedDataProcessor_{I}_{J}_{K}_{N_in}_{N_out}')

    dpu = ParallelizedDataProcessor()
    params = module.copy_params_as_localparams(dpu)
    ports  = module.copy_ports_as_vars(dpu)

    DATA_CHANNELS               : Localparam = params['DATA_CHANNELS']
    RSLT_CHANNELS               : Localparam = params['RSLT_CHANNELS']
    BATCH_SIZE                  : Localparam = params['BATCH_SIZE']
    SHARE_SCALE                 : Localparam = params['SHARE_SCALE']
    DATA_WIDTH                  : Localparam = params['DATA_WIDTH_DATA']
    FRACTIONAL_BITS_DATA        : Localparam = params['FRACTIONAL_BITS_DATA']
    FRACTIONAL_BITS_SCALE       : Localparam = params['FRACTIONAL_BITS_SCALE']
    FRACTIONAL_BITS_WEIGHT      : Localparam = params['FRACTIONAL_BITS_WEIGHT']
    FRACTIONAL_BITS_SCALED_DIFF : Localparam = params['FRACTIONAL_BITS_SCALED_DIFF']
    FRACTIONAL_BITS_ACT         : Localparam = params['FRACTIONAL_BITS_ACT']
    FRACTIONAL_BITS_RSLT        : Localparam = params['FRACTIONAL_BITS_RSLT']
    ROM_DATA_PATH               : Localparam = params['ROM_DATA_PATH']

    RSLT_CHANNELS.value = I
    DATA_CHANNELS.value = J
    BATCH_SIZE.value  = K

    SHARE_SCALE.value = 1
    DATA_WIDTH.value = 16
    FRACTIONAL_BITS_DATA.value = 12
    FRACTIONAL_BITS_SCALE.value = 12
    FRACTIONAL_BITS_WEIGHT.value = 12
    FRACTIONAL_BITS_SCALED_DIFF.value = 13
    FRACTIONAL_BITS_ACT.value = 16
    FRACTIONAL_BITS_RSLT.value = 12
    ROM_DATA_PATH.value = f"../data/Sech2Lutram_n_{DATA_WIDTH.value}.{FRACTIONAL_BITS_SCALED_DIFF.value}_{DATA_WIDTH.value}.{FRACTIONAL_BITS_ACT.value}.txt"
    
    os.system(' '.join([
        'python',
        '../auxiliary/Sech2Lutram.py',
        '-N',
        f'-I int{DATA_WIDTH.value}',
        f'-O uint{DATA_WIDTH.value}',
        f'-i {FRACTIONAL_BITS_SCALED_DIFF.value}',
        f'-o {FRACTIONAL_BITS_ACT.value}',
    ])
    )
    
    # print(params.keys())
    # print(ports.keys())
    
    params['DATA_WIDTH_SCALE'].value = DATA_WIDTH
    params['DATA_WIDTH_WEIGHT'].value = DATA_WIDTH
    params['DATA_WIDTH_SCALED_DIFF'].value = DATA_WIDTH
    params['DATA_WIDTH_ACT'].value = DATA_WIDTH
    params['DATA_WIDTH_RSLT'].value = DATA_WIDTH
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        dpu,
        'uut',
        params,
        ports
    )
    
    clk = ports['clk']
    rst = ports['rst']
    
    s_axis_d_tdata  = ports['s_axis_data_tdata']
    s_axis_d_tlast  = ports['s_axis_data_tlast']
    s_axis_d_tvalid = ports['s_axis_data_tvalid']
    s_axis_d_tready = ports['s_axis_data_tready']
    
    s_axis_g_tdata  = ports['s_axis_grid_tdata']
    s_axis_g_tlast  = ports['s_axis_grid_tlast']
    s_axis_g_tvalid = ports['s_axis_grid_tvalid']
    s_axis_g_tready = ports['s_axis_grid_tready']
    
    s_axis_s_tdata  = ports['s_axis_scale_tdata']
    s_axis_s_tlast  = ports['s_axis_scale_tlast']
    s_axis_s_tvalid = ports['s_axis_scale_tvalid']
    s_axis_s_tready = ports['s_axis_scale_tready']
    
    s_axis_w_tdata  = ports['s_axis_weight_tdata']
    s_axis_w_tlast  = ports['s_axis_weight_tlast']
    s_axis_w_tvalid = ports['s_axis_weight_tvalid']
    s_axis_w_tready = ports['s_axis_weight_tready']
    
    m_axis_d_tdata  = ports['m_axis_data_tdata']
    m_axis_d_tlast  = ports['m_axis_data_tlast']
    m_axis_d_tvalid = ports['m_axis_data_tvalid']
    m_axis_d_tready = ports['m_axis_data_tready']
    
    err_unalligned_data = ports['err_unalligned_data']
    core_rst = ports['core_rst']
    
    reset_stmt = []
    reset_stmt.append(reset_done(0))

    reset_stmt.append(s_axis_d_tdata(0))
    reset_stmt.append(s_axis_d_tvalid(0))
    reset_stmt.append(s_axis_d_tlast(0))

    reset_stmt.append(s_axis_g_tdata(0))
    reset_stmt.append(s_axis_g_tvalid(0))
    reset_stmt.append(s_axis_g_tlast(0))

    reset_stmt.append(s_axis_s_tdata(0))
    reset_stmt.append(s_axis_s_tlast(0))
    reset_stmt.append(s_axis_s_tvalid(0))

    reset_stmt.append(s_axis_w_tdata(0))
    reset_stmt.append(s_axis_w_tlast(0))
    reset_stmt.append(s_axis_w_tvalid(0))

    reset_stmt.append(m_axis_d_tready(0))

    vcd_name = os.path.join('..','vcd',f'tb_ParallelizedDataProcessor_{I}_{J}_{K}_{N_in}_{N_out}.vcd')
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
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s != %s",`"signal`", `"value`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        $display("---- %s = 0x%h",`"value`",value); \
        #5 \
        $finish; \
    end
    `define assertTrue(signal) \
    if (~signal) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s is not True",`"signal`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        #5 \
        $finish; \
    end
    `define abs(signal) ($signed(signal) < 0) ? -$signed(signal) : signal
    `define assertAbsDiffLE(signal0, signal1, value) \
    if ( `abs(signal0-signal1) > value) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- ABS(%s-%s) > %s",`"signal0`",`"signal1`",`"value`"); \
        $display("---- %s = 0x%h",`"signal0`",signal0); \
        $display("---- %s = 0x%h",`"signal1`",signal1); \
        $display("---- Abs Diff = 0x%h",`abs(signal0-signal1)); \
        $display("---- %s = 0x%h",`"value`",value); \
        #5 \
        $finish; \
    end
    ''')
    def Assert(signal,value):
        return EmbeddedCode(f'`assert({signal},{value})')
    def AssertTrue(signal):
        return EmbeddedCode(f'`assertTrue({signal})')
    def AssertAbsDiffLE(signal0,signal1,value):
        return EmbeddedCode(f'`assertAbsDiffLE({signal0},{signal1},{value})')

    # KAN Layer parameters
    device = torch.device('cuda') if torch.cuda.is_available() else torch.device('cpu')
    data_len = DATA_CHANNELS.value * (N_in // DATA_CHANNELS.value)
    grid_len = 8
    scale_len = (1,1,1) if SHARE_SCALE.value else (1,grid_len,data_len)
    rslt_len = RSLT_CHANNELS.value * (N_out // RSLT_CHANNELS.value)
    weight_len = data_len*grid_len
    # print(data_len,grid_len,scale_len,rslt_len,weight_len)
    
    # Create data - size = [BATCH X DATA]
    layer_data = torch.randn(K, 1, data_len, device=device)
    # Quantize data
    layer_data_q = torch.tensor((layer_data * 2 ** FRACTIONAL_BITS_DATA.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'),device=device)
    # Dequantize data
    layer_data = layer_data_qd = layer_data_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_DATA.value
    
    # Create grid - size = [GRID]
    layer_grid = torch.randn(1, grid_len, 1, device=device)
    # Quantize grid
    layer_grid_q = torch.tensor((layer_grid * 2 ** FRACTIONAL_BITS_DATA.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize grid
    layer_grid = layer_grid_qd = layer_grid_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_DATA.value
    
    # Create scale - size = [GRID X DATA] or [1] 
    layer_scle = torch.rand(*scale_len, device=device)
    # Quantize scale
    layer_scle_q = torch.tensor((layer_scle * 2 ** FRACTIONAL_BITS_SCALE.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_scle = layer_scle_qd = layer_scle_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_SCALE.value
    
    
    # Create weight - size = [WEIGHT x RESULT] or [1] 
    layer_wght = (torch.rand(weight_len, rslt_len, device=device) * 2 - 1) / weight_len * 10
    # Quantize scale
    layer_wght_q = torch.tensor((layer_wght * 2 ** FRACTIONAL_BITS_WEIGHT.value).cpu().numpy().astype(f'int{2*DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_wght = layer_wght_qd = layer_wght_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_WEIGHT.value
    
    # Create expected scaled difference - size = [BATCH X GRID X DATA]
    layer_exp_diff = (layer_scle * (layer_data - layer_grid)).abs()
    # Create scaled difference - size = [BATCH X GRID X DATA]
    layer_diff = layer_scle_qd * (layer_data_qd - layer_grid_qd)
    # Quantize scaled difference
    layer_diff_q = torch.tensor((layer_diff * 2 ** FRACTIONAL_BITS_SCALED_DIFF.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device).abs()
    # Dequantize scaled difference
    layer_diff_qd = layer_diff_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_SCALED_DIFF.value
    
    # Create expected activation data - size = [BATCH X GRID X DATA]
    layer_exp_actd = (1 - torch.tanh(layer_exp_diff)**2)
    # Reshape expected activation data - size = [BATCH X WEIGHT]
    layer_exp_actd = layer_exp_actd.reshape(-1, weight_len)
    
    # Create activation data - size = [BATCH X GRID X DATA]
    layer_actd = 1 - torch.tanh(layer_diff_qd)**2
    # Reshape activation data - size = [BATCH X WEIGHT]
    layer_actd = layer_actd.reshape(-1, weight_len)
    # Quantize activation data
    layer_actd_q = torch.tensor((layer_actd * 2 ** FRACTIONAL_BITS_ACT.value).round().cpu().numpy().astype(f'int{2*DATA_WIDTH.value}'), device=device)
    # Unit correction
    if (DATA_WIDTH.value == FRACTIONAL_BITS_ACT.value):
        layer_actd_q = torch.where(
            (layer_actd_q >> DATA_WIDTH.value) > 0,
            layer_actd_q-1,
            layer_actd_q
        )
    # Dequantize activation data
    layer_actd_qd = layer_actd_q.to(torch.float32) / 2 ** FRACTIONAL_BITS_ACT.value
    
    # Perform expected Linear Layer / Matrix-Matrix Multiplication
    layer_exp_rslt = layer_exp_actd @ layer_wght
    # Quantize expected result
    layer_exp_rslt_q = torch.tensor((layer_exp_rslt * 2 ** FRACTIONAL_BITS_RSLT.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    
    # Perform Linear Layer / Matrix-Matrix Multiplication
    layer_rslt = layer_actd_qd @ layer_wght_qd
    # Quantize result
    layer_rslt_q = torch.tensor((layer_rslt * 2 ** FRACTIONAL_BITS_RSLT.value).round().cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # # Dequantize result
    # layer_rslt_qd = layer_rslt_q.to('float32') / 2 ** FRACTIONAL_BITS_RSLT.value
    
    # Perform Linear Layer / Matrix-Matrix Multiplication -- with integers
    layer_rslt_int = torch.tensor(((layer_actd_q.cpu() @ layer_wght_q.cpu()) * 2 ** (FRACTIONAL_BITS_RSLT.value - (FRACTIONAL_BITS_WEIGHT.value + FRACTIONAL_BITS_ACT.value))).numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize result -- with integers
    layer_rslt_intd = layer_rslt_int.to(torch.float32) / 2 ** FRACTIONAL_BITS_RSLT.value
    
    layer_rslt      = layer_rslt.to(device=device, dtype=torch.float64)
    layer_rslt_intd = layer_rslt_intd.to(device=device, dtype=torch.float64)
    
    # Theoretical Device Simulation Bit Error Rate
    theo_dev_sim_ber = torch.sqrt(torch.mean(((layer_rslt_q - layer_rslt_int) ** 2).to(dtype=torch.float64))).cpu().numpy()
    print('Theoretical Device Simulation Bit Error Rate (should be zero):', theo_dev_sim_ber)
    
    # Theoretical Quantization Bit Error Rate
    theo_qber = torch.sqrt(torch.mean(((layer_exp_rslt_q - layer_rslt_int) ** 2).to(dtype=torch.float64))).cpu().numpy()
    print('Theoretical Quantization Bit Error Rate:', theo_qber)
    
    # Theoretical Quantization Error Rate
    theo_qer = torch.sqrt(torch.mean((layer_rslt - layer_rslt_intd) ** 2)).cpu().numpy()
    print('Theoretical Quantization Error Rate:', theo_qer)
    
    # Generate Variables
    chn_rslt = module.Genvar('chn_rslt')
    chn_data = module.Genvar('chn_data')
    chn_batch = module.Genvar('chn_batch')
    
    max_iterations = rslt_len // RSLT_CHANNELS.value
    
    # Data, Grid & Scale coordinator
    per_channel_j  = module.GenerateFor(chn_data(0), chn_data <DATA_CHANNELS, chn_data(chn_data+1))
    per_channel_jk = per_channel_j.GenerateFor(chn_batch(0), chn_batch <BATCH_SIZE, chn_batch(chn_batch+1))
    
    LFT_POS = per_channel_jk.Localparam('LFT_POS',chn_batch * DATA_CHANNELS + chn_data)
    
    test_data = layer_data_q.reshape(-1, BATCH_SIZE.value, DATA_CHANNELS.value).cpu().tolist()
    test_grid = layer_grid_q.squeeze().cpu().tolist()
    test_scle = layer_scle_q.squeeze(0).cpu().tolist() if SHARE_SCALE.value else layer_scle_q.reshape(-1, DATA_CHANNELS.value).cpu().tolist()
    
    # print(test_data)
    # print(layer_data_qd)
    # print(layer_data_qd.reshape(-1, BATCH_SIZE.value, DATA_CHANNELS.value))
    
    ## Data Driver
    data_slice = s_axis_d_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    i_data = per_channel_jk.Integer('i_data')
    iteration = module.Integer('iteration_data')
    
    per_channel_jk.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_d_tready[LFT_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Nominal function
        Wait(~clk),
        s_axis_d_tvalid[LFT_POS](1),
        For(iteration(0), iteration < max_iterations, iteration(iteration+1))(
            For(i_data(0), Ands(i_data < len(test_data)*len(test_grid),~core_rst), i_data(i_data+1))(
                Wait(~clk),
                Case(i_data % len(test_data))(
                    *[
                        When(i)(
                            Case(chn_batch)(
                                *[
                                    When(k)(
                                        Case(chn_data)(
                                            *[
                                                When(j)(
                                                    data_slice(test_data[i][k][j] )
                                                ) for j in range(DATA_CHANNELS.value)
                                            ],
                                            When( )(data_slice(0)),
                                        ),
                                    ) for k in range(BATCH_SIZE.value)
                                ],
                                When( )(data_slice(0)),
                            ),
                        ) for i in range(len(test_data))
                    ],
                    When( )(data_slice(0)),
                ),
                s_axis_d_tlast[LFT_POS](i_data == len(test_data)*len(test_grid)-1),
                # If((i_data + LFT_POS) % 5 == 0)(
                #     s_axis_d_tvalid[LFT_POS](0),
                #     Wait(clk),
                #     Wait(~clk),
                #     Wait(clk),
                #     Wait(~clk),
                #     s_axis_d_tvalid[LFT_POS](1),
                # ),
                While(Ands(~s_axis_d_tready[LFT_POS],~core_rst))(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
            ),
        ),
        Wait(~clk),
        s_axis_d_tvalid[LFT_POS](0),
        s_axis_d_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )

    ## Grid Driver
    data_slice = s_axis_g_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    max_grid_iter = data_len / DATA_CHANNELS.value
    i_grid = per_channel_jk.Integer('i_grid')
    grid_iter = per_channel_jk.Integer('grid_iter')
    iteration = per_channel_jk.Integer('iteration_grid')
    
    per_channel_jk.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_g_tready[LFT_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Nominal function
        Wait(~clk),
        s_axis_g_tvalid[LFT_POS](1),
        For(iteration(0), iteration < max_iterations, iteration(iteration+1))(
            For(i_grid(0), i_grid < len(test_grid), i_grid(i_grid+1))(
                For(grid_iter(0), Ands(grid_iter < max_grid_iter,~core_rst), grid_iter(grid_iter+1))(
                    Wait(~clk),
                    Case(i_grid)(
                        *[
                            When(i)(
                                data_slice(test_grid[i])
                            ) for i in range(len(test_grid))
                        ],
                        When( )(data_slice(0)),
                    ),
                    s_axis_g_tlast[LFT_POS](Ands(
                        i_grid == len(test_grid)-1,
                        grid_iter == max_grid_iter-1
                    )),
                    # If((i_grid + LFT_POS) % 5 == 0)(
                    #     s_axis_g_tvalid[LFT_POS](0),
                    #     Wait(clk),
                    #     Wait(~clk),
                    #     Wait(clk),
                    #     Wait(~clk),
                    #     s_axis_g_tvalid[LFT_POS](1),
                    # ),
                    While(Ands(~s_axis_g_tready[LFT_POS],~core_rst))(
                        Wait(clk),
                        Wait(~clk),
                    ),
                    Wait(clk),
                ),
            ),
        ),
        Wait(~clk),
        s_axis_g_tvalid[LFT_POS](0),
        s_axis_g_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )

    ## Scale Driver
    data_slice = s_axis_s_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    i_scle = per_channel_jk.Integer('i_scle')
    iteration = per_channel_jk.Integer('iteration_scale')
    
    per_channel_jk.GenerateIf(Ors(
        SHARE_SCALE == 0,
        LFT_POS == 0
    )).Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_s_tready[LFT_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Nominal function
        Wait(~clk),
        s_axis_s_tvalid[LFT_POS](1),
        For(iteration(0), iteration < max_iterations, iteration(iteration+1))(
            For(i_scle(0), Ands(i_scle < len(test_scle),~core_rst), i_scle(i_scle+1))(
                Wait(~clk),
                Case(i_scle)(
                    *[
                        When(i)(
                            Case(chn_data)(
                                *[
                                    When(j)(
                                        # Display("-- Scale[%d] : test_scle[%d][%d] = %h -- %b",LFT_POS,i,j,test_scle[i][j],i_scle == len(test_scle)-1),
                                        data_slice(test_scle[i][j])
                                    ) for j in range(len(test_scle[i]))
                                ],
                                When( )(data_slice(0)),
                            ),
                        ) for i in range(len(test_scle))
                    ],
                    When( )(data_slice(0)),
                ),
                # Display("-- Scale last[%d]: %b",LFT_POS,i_scle == len(test_scle)-1),
                s_axis_s_tlast[LFT_POS](i_scle == len(test_scle)-1),
                # If((i_scle + LFT_POS) % 5 == 0)(
                #     s_axis_d_tvalid[LFT_POS](0),
                #     Wait(clk),
                #     Wait(~clk),
                #     Wait(clk),
                #     Wait(~clk),
                #     s_axis_d_tvalid[LFT_POS](1),
                # ),
                While(Ands(~s_axis_s_tready[LFT_POS],~core_rst))(
                    Wait(clk),
                    Wait(~clk),
                ),
                Wait(clk),
            ),
        ),
        Wait(~clk),
        s_axis_s_tvalid[LFT_POS](0),
        s_axis_s_tlast[LFT_POS](0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )

    # Weight coordinator
    per_channel_i  = module.GenerateFor(chn_rslt(0), chn_rslt < RSLT_CHANNELS, chn_rslt(chn_rslt+1))
    per_channel_ij = per_channel_i.GenerateFor(chn_data(0), chn_data < DATA_CHANNELS, chn_data(chn_data+1))
    
    TOP_POS = per_channel_ij.Localparam('TOP_POS',chn_data * RSLT_CHANNELS + chn_rslt)
    
    data_slice = s_axis_w_tdata.slice(
        msb = (TOP_POS+1)*DATA_WIDTH-1,
        lsb = TOP_POS * DATA_WIDTH
    )
    test_wght = torch.stack( torch.split(torch.cat(torch.split(layer_wght_q,RSLT_CHANNELS.value,1)), DATA_CHANNELS.value,0) ).cpu().tolist()
    # print(np.array(test_wght).shape)
    # print(layer_wght_q)
    # print(layer_wght_q.reshape(-1, DATA_CHANNELS.value, RSLT_CHANNELS.value))
    hex_list = lambda x: hex(x) if isinstance(x, int) else [hex_list(_) for _ in x]
    # print()
    print(layer_wght_q.shape)
    # print(layer_wght_q)
    # print(torch.cat(torch.split(layer_wght_q,RSLT_CHANNELS.value,1)))
    # print(torch.stack( torch.split(torch.cat(torch.split(layer_wght_q,RSLT_CHANNELS.value,1)), DATA_CHANNELS.value,0) ))
    # print(hex_list(layer_wght_q.T.cpu().numpy().astype('uint16').tolist()))
    # print(hex_list(layer_wght_q.T.reshape(-1, RSLT_CHANNELS.value, DATA_CHANNELS.value).T.movedim(-1,0).cpu().numpy().astype('uint16').tolist()))
    # # print([hex(_) for _ in layer_wght_q.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # # print([hex(_) for _ in layer_actd_q.reshape(-1).cpu().numpy().astype('uint16').tolist()])

    # print()
    # print(hex_list(layer_actd_q.cpu().numpy().astype('uint32').tolist()))
    # print(hex_list(layer_actd_q.reshape(-1, BATCH_SIZE.value, DATA_CHANNELS.value).cpu().numpy().astype('uint32').tolist()))
    # exit()

    ## Weight driver
    iteration_len = len(test_wght) // (rslt_len // RSLT_CHANNELS.value)
    i_wght = per_channel_ij.Integer('i_wght')
    
    per_channel_ij.Initial(
        Wait(reset_done),
        Wait(clk),
        
        Wait(s_axis_w_tready[TOP_POS]),
        Wait(~clk),
        Wait(clk),
        
        # Test 0 : Nominal function
        For(i_wght(0), Ands(i_wght < len(test_wght)), i_wght(i_wght+1))(
            Wait(~clk),
            Case(i_wght)(
                *[
                    When(_iter)(
                        Case(chn_rslt)(
                            *[
                                When(j)(
                                    Case(chn_data)(
                                        *[
                                            When(i)(
                                                data_slice(test_wght[_iter][i][j])
                                            ) for i in range(DATA_CHANNELS.value)
                                        ],
                                        When( )(data_slice(0)),
                                    ),
                                ) for j in range(RSLT_CHANNELS.value)
                            ],
                            When( )(data_slice(0)),
                        ),
                    ) for _iter in range(len(test_wght))
                ],
                When( )(data_slice(0)),
            ),
            s_axis_w_tvalid[TOP_POS](1),
            s_axis_w_tlast[TOP_POS]((i_wght % iteration_len) == (iteration_len-1)),
            While(~s_axis_w_tready[TOP_POS])(
                Wait(clk),
                Wait(~clk),
            ),
            Wait(clk),
        ),
        Wait(~clk),
        s_axis_w_tvalid(0),
        s_axis_w_tlast(0),
        Wait(~core_rst),
        Wait(~clk),
        Wait(clk),
    )
    
    # Result coordinator
    # per_channel_i  = module.GenerateFor(chn_rslt(0), chn_rslt <RSLT_CHANNELS, chn_rslt(chn_rslt+1))
    per_channel_ik = per_channel_i.GenerateFor(chn_batch(0), chn_batch <BATCH_SIZE, chn_batch(chn_batch+1))
    
    DWN_POS = per_channel_ik.Localparam('DWN_POS',chn_batch * RSLT_CHANNELS + chn_rslt)
    i_res = per_channel_ik.Integer('i_res')
    
    data_slice = m_axis_d_tdata.slice(
        msb = (DWN_POS+1)*DATA_WIDTH-1,
        lsb = DWN_POS * DATA_WIDTH
    )
    test_rslt = layer_rslt_q.reshape(-1, BATCH_SIZE.value, RSLT_CHANNELS.value).cpu().numpy().astype(f'uint{DATA_WIDTH.value}').tolist()
    # test_rslt = layer_rslt_int.reshape(-1, BATCH_SIZE.value, RSLT_CHANNELS.value).cpu().tolist()
    # print(layer_diff_qd.squeeze().T.reshape(-1))
    # print([hex(_) for _ in layer_diff_q.T.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print(layer_actd_qd.squeeze().T.reshape(-1))
    # print([hex(_) for _ in layer_actd_q.T.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print(layer_rslt_int)
    # print([hex(_) for _ in layer_rslt_int.T.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print(hex_list(layer_rslt_int.T.reshape(-1).cpu().numpy().astype('uint16').tolist()))
    # print((layer_wght_q.T*layer_actd_q).shape,layer_wght_q.shape,layer_actd_q.shape)
    # print([hex(_) for _ in layer_diff_q.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print([hex(_) for _ in layer_actd_q.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print([hex(_) for _ in layer_wght_q.T.reshape(-1).cpu().numpy().astype('uint16').tolist()])
    # print([hex(_) for _ in (layer_actd_q * layer_wght_q.T).reshape(-1).cpu().numpy().astype('uint32').tolist()])
    # print(layer_actd_q.shape,layer_wght_q.T.shape,(layer_actd_q * layer_wght_q.T).shape)
    # x = (layer_actd_q * layer_wght_q.T).cpu().numpy().astype('int64')
    # print(hex_list([np.sum(x[:,:_iter+1],axis=-1).astype('uint32').tolist() for _iter in range(x.shape[-1])]))
    # print([hex(np.sum(x[:_iter+1]).astype('uint32')) for _iter in range(len(x))])
    # print(hex_list( (np.sum(x,axis=1).astype('int32') * 2** (FRACTIONAL_BITS_RSLT.value - (FRACTIONAL_BITS_WEIGHT.value + FRACTIONAL_BITS_ACT.value))).astype('int16').tolist() ))
    # print(hex( (np.sum(x).astype('int32') * 2** (FRACTIONAL_BITS_RSLT.value - (FRACTIONAL_BITS_WEIGHT.value + FRACTIONAL_BITS_ACT.value))).astype('int16') ))
    
    ## Result driver
    per_channel_ik.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 :Nominal function
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
                Case(chn_batch)(*[
                        When(batch)(
                            Case(chn_rslt)(*[
                                    When(rslt)(
                                        Case(i_res)(*[
                                                When(_iter)(
                                                    # Display('Time -- %0t', EmbeddedNumeric('$time')),
                                                    # Display('%d -- %h', data_slice,data_slice),
                                                    # Assert(data_slice,test_rslt[_iter][batch][rslt]),
                                                    AssertAbsDiffLE(
                                                        data_slice,
                                                        test_rslt[_iter][batch][rslt],
                                                        1
                                                    ),
                                                ) for _iter in range(len(test_rslt))
                                            ],
                                            When()(),
                                        ),
                                    ) for rslt in range(RSLT_CHANNELS.value)
                                ],
                                When()(),
                            ),
                        ) for batch in range(BATCH_SIZE.value)
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

    # module = ParallelizedDataProcessor()
    # # fname = os.path.join(TOP_DIR,'rtl/ParallelizedDataProcessor.v')
    # fname = os.path.join(TOP_DIR,'rtl/tmp.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'ParallelizedDataProcessor')
    # addTimeScale(fname)
    # exit()
    
    for I,J,K in (
        # (1,1,1),
        # (2,2,1),
        # (2,3,1),
        (8,4,2),
        # (5,5,5),
    ):
        N_in, N_out = 64,64
        # N_in, N_out = J,2*I
        test = tb_ParallelizedDataProcessor(I=I,J=J,K=K,N_in=N_in,N_out=N_out)
        fname_base = f'tb_ParallelizedDataProcessor_{I}_{J}_{K}_{N_in}_{N_out}'
        fname = os.path.join(TOP_DIR,f'tb/{fname_base}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'ParallelizedDataProcessor')
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
