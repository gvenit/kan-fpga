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
    SCALE_SHARE                 : Localparam = params['SCALE_SHARE']
    GRID_SHARE                  : Localparam = params['GRID_SHARE']
    DATA_WIDTH                  : Localparam = params['DATA_WIDTH']
    DATA_FRACTIONAL_BITS        : Localparam = params['DATA_FRACTIONAL_BITS']
    SCALE_FRACTIONAL_BITS       : Localparam = params['SCALE_FRACTIONAL_BITS']
    WEIGHT_FRACTIONAL_BITS      : Localparam = params['WEIGHT_FRACTIONAL_BITS']
    SCALED_DIFF_FRACTIONAL_BITS : Localparam = params['SCALED_DIFF_FRACTIONAL_BITS']
    ACT_FRACTIONAL_BITS         : Localparam = params['ACT_FRACTIONAL_BITS']
    RSLT_FRACTIONAL_BITS        : Localparam = params['RSLT_FRACTIONAL_BITS']
    ROM_DATA_PATH               : Localparam = params['ROM_DATA_PATH']
    FIFO_DEPTH                  : Localparam = params['FIFO_DEPTH']
    PIPELINE_LEVEL              : Localparam = params['PIPELINE_LEVEL']

    RSLT_CHANNELS.value = I
    DATA_CHANNELS.value = J
    BATCH_SIZE.value  = K

    # SCALE_SHARE.value = 1
    # GRID_SHARE.value = 1
    # DATA_WIDTH.value = 16
    # DATA_FRACTIONAL_BITS.value = 15
    # SCALE_FRACTIONAL_BITS.value = 12
    # WEIGHT_FRACTIONAL_BITS.value = 16
    # SCALED_DIFF_FRACTIONAL_BITS.value = 13
    # ACT_FRACTIONAL_BITS.value = 16
    # RSLT_FRACTIONAL_BITS.value = 15
    # ROM_DATA_PATH.value = f"../data/Sech2Lutram_n_{DATA_WIDTH.value}.{SCALED_DIFF_FRACTIONAL_BITS.value}_{DATA_WIDTH.value}.{ACT_FRACTIONAL_BITS.value}.txt"
    # FIFO_DEPTH.value = 0
    # PIPELINE_LEVEL.value = 2
    SCALE_SHARE.value = 1
    GRID_SHARE.value = 1
    DATA_WIDTH.value = 16
    DATA_FRACTIONAL_BITS.value = DATA_WIDTH.value-1
    SCALE_FRACTIONAL_BITS.value = DATA_WIDTH.value-2
    WEIGHT_FRACTIONAL_BITS.value = DATA_WIDTH.value
    SCALED_DIFF_FRACTIONAL_BITS.value = DATA_WIDTH.value-3
    ACT_FRACTIONAL_BITS.value = DATA_WIDTH.value
    RSLT_FRACTIONAL_BITS.value = DATA_WIDTH.value-1
    ROM_DATA_PATH.value = f"../data/Sech2Lutram_n_{DATA_WIDTH.value}.{SCALED_DIFF_FRACTIONAL_BITS.value}_{DATA_WIDTH.value}.{ACT_FRACTIONAL_BITS.value}.txt"
    FIFO_DEPTH.value = 0
    PIPELINE_LEVEL.value = 2
    
    os.system(' '.join([
        'python',
        '../auxiliary/Sech2Lutram.py',
        '-N',
        f'-I int{DATA_WIDTH.value}',
        f'-O uint{DATA_WIDTH.value}',
        f'-i {SCALED_DIFF_FRACTIONAL_BITS.value}',
        f'-o {ACT_FRACTIONAL_BITS.value}',
    ])
    )
    
    # print(params.keys())
    # print(ports.keys())
    
    params['SCALE_WIDTH'].value = DATA_WIDTH
    params['WEIGHT_WIDTH'].value = DATA_WIDTH
    params['SCALED_DIFF_WIDTH'].value = DATA_WIDTH
    params['ACT_WIDTH'].value = DATA_WIDTH
    params['RSLT_WIDTH'].value = DATA_WIDTH
    
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
    
    s_axis_s_tdata  = ports['s_axis_scle_tdata']
    s_axis_s_tlast  = ports['s_axis_scle_tlast']
    s_axis_s_tvalid = ports['s_axis_scle_tvalid']
    s_axis_s_tready = ports['s_axis_scle_tready']
    
    s_axis_w_tdata  = ports['s_axis_wght_tdata']
    s_axis_w_tlast  = ports['s_axis_wght_tlast']
    s_axis_w_tvalid = ports['s_axis_wght_tvalid']
    s_axis_w_tready = ports['s_axis_wght_tready']
    
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
    '''
    `include "header_utils.vh"
    `define assert(signal, value) \
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
    `define assertAbsDiffLE(signal0, signal1, value) \
      if ( `ABS(signal0-signal1) > value) begin \
          $display("ASSERTION FAILED in %m:"); \
          $display("---- Time %0t",$time); \
          $display("---- ABS(%s-%s) > %s",`"signal0`",`"signal1`",`"value`"); \
          $display("---- %s = 0x%h",`"signal0`",signal0); \
          $display("---- %s = 0x%h",`"signal1`",signal1); \
          $display("---- Abs Diff = 0x%h",`ABS(signal0-signal1)); \
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
    data_len = DATA_CHANNELS.value * max(N_in // DATA_CHANNELS.value, 1)
    grid_len = 8
    scale_len = (1,1,1) if SCALE_SHARE.value else (1,data_len,grid_len)
    rslt_len = RSLT_CHANNELS.value * max(N_out // RSLT_CHANNELS.value, 1)
    weight_len = data_len*grid_len
    adder_size = 64
    # pckt_len = (data_len // DATA_CHANNELS.value) * (grid_len // (1 if GRID_SHARE.value else DATA_CHANNELS.value))
    # print(data_len,grid_len,scale_len,rslt_len,weight_len)
    
    # Create data - size = [BATCH X DATA X 1]
    layer_data = torch.randn(K, data_len, 1, device=device)
    # Quantize data
    layer_data_q = torch.tensor((layer_data * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'),device=device)
    # Dequantize data
    layer_data = layer_data_qd = layer_data_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create grid - size = [1 X 1 X GRID]
    layer_grid = torch.randn(1, 1, grid_len, device=device)
    # Quantize grid
    layer_grid_q = torch.tensor((layer_grid * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize grid
    layer_grid = layer_grid_qd = layer_grid_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create scale - size = [1 X DATA X GRID] or [1] 
    layer_scle = torch.rand(*scale_len, device=device) * 2
    # Quantize scale
    layer_scle_q = torch.tensor((layer_scle * 2 ** SCALE_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_scle = layer_scle_qd = layer_scle_q.to(torch.float32) / 2 ** SCALE_FRACTIONAL_BITS.value
    
    
    # Create weight - size = [WEIGHT x RESULT] or [1] 
    layer_wght = (torch.rand(weight_len, rslt_len, device=device) * 2 - 1)

    # Create expected scaled difference - size = [BATCH X GRID X DATA]
    layer_exp_sdff = (layer_scle * (layer_data - layer_grid)).abs()
    # Create expected activation data - size = [BATCH X GRID X DATA]
    layer_exp_actd = torch.tensor((1 - np.tanh(layer_exp_sdff.cpu().numpy().astype('float128'))**2).astype('float32'), device=device)
    # Reshape expected activation data - size = [BATCH X WEIGHT]
    layer_exp_actd = layer_exp_actd.reshape(-1, weight_len)

    if True:
        # Perform expected Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
        layer_exp_rslt = layer_exp_actd @ layer_wght
        
        # Normalize weights
        weight_scale = layer_exp_rslt.abs().max()
    
    
    # Normalize weight - size = [WEIGHT x RESULT] or [1] 
    layer_wght = layer_wght / weight_scale
    # Quantize scale
    layer_wght_q = torch.tensor((layer_wght * 2 ** WEIGHT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{2*DATA_WIDTH.value}'), device=device)
    # Dequantize scale
    layer_wght = layer_wght_qd = layer_wght_q.to(torch.float32) / 2 ** WEIGHT_FRACTIONAL_BITS.value
    # print(layer_wght_q,layer_wght)
    # exit()
    
    
    # Create scaled difference - size = [BATCH X GRID X DATA]
    layer_diff = (layer_data_qd - layer_grid_qd)
    # Quantize scaled difference
    layer_diff_q = torch.tensor((layer_diff * 2 ** DATA_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device).abs()
    # Dequantize scaled difference
    layer_diff_qd = layer_diff_q.to(torch.float32) / 2 ** DATA_FRACTIONAL_BITS.value
    
    # Create scaled difference - size = [BATCH X GRID X DATA]
    layer_sdff = (layer_scle_qd * layer_diff_qd).abs()
    # Quantize scaled difference
    layer_sdff_q = torch.tensor((layer_sdff * 2 ** SCALED_DIFF_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{adder_size}'), device=device).abs()
    # Dequantize scaled difference
    layer_sdff_qd = layer_sdff_q.cpu().numpy().astype('float128') / 2 ** SCALED_DIFF_FRACTIONAL_BITS.value
    
    # Create activation data - size = [BATCH X WEIGHT]
    layer_actd = 1 - np.tanh(layer_sdff_qd)**2
    # Quantize activation data
    layer_actd_q = torch.tensor((layer_actd * 2 ** ACT_FRACTIONAL_BITS.value).astype(f'int{2*DATA_WIDTH.value}'), device=device)
    # Unit correction
    if (DATA_WIDTH.value == ACT_FRACTIONAL_BITS.value):
        layer_actd_q = torch.where(
            layer_actd_q > 2 ** ACT_FRACTIONAL_BITS.value -1,
            2 ** ACT_FRACTIONAL_BITS.value - 1,
            layer_actd_q
        )
    # Reshape activation data - size = [BATCH X WEIGHT]
    layer_actd_q = layer_actd_q.movedim(-1,-2).reshape(-1, weight_len)
    # Dequantize activation data - size = [BATCH X WEIGHT]
    layer_actd_qd = layer_actd_q.to(torch.float32) / 2 ** ACT_FRACTIONAL_BITS.value
    
    # Perform expected Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
    layer_exp_rslt = layer_exp_actd @ layer_wght
    # Quantize expected result
    layer_exp_rslt_q = torch.tensor((layer_exp_rslt * 2 ** RSLT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    
    # Perform Linear Layer / Matrix-Matrix Multiplication - size = [BATCH X RESULT]
    layer_rslt = layer_actd_qd @ layer_wght_qd
    # Quantize result
    layer_rslt_q = torch.tensor((layer_rslt * 2 ** RSLT_FRACTIONAL_BITS.value).cpu().numpy().astype(f'int{DATA_WIDTH.value}'), device=device)
    # # Dequantize result
    # layer_rslt_qd = layer_rslt_q.to('float32') / 2 ** RSLT_FRACTIONAL_BITS.value
    
    # Perform Linear Layer / Matrix-Matrix Multiplication -- with integers - size = [BATCH X RESULT]
    layer_rslt_int = torch.einsum("bw,wr->wbr", layer_actd_q, layer_wght_q).cpu().numpy().astype('int64')
    layer_rslt_int = torch.tensor(np.right_shift(np.sum(layer_rslt_int,axis=0).astype('int64'), -(RSLT_FRACTIONAL_BITS.value - (WEIGHT_FRACTIONAL_BITS.value + ACT_FRACTIONAL_BITS.value))).astype(f'int{DATA_WIDTH.value}'), device=device)
    # Dequantize result -- with integers
    layer_rslt_intd = layer_rslt_int.to(torch.float32) / 2 ** RSLT_FRACTIONAL_BITS.value
    
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
    # exit()
    
    # Generate Variables
    chn_rslt = module.Genvar('chn_rslt')
    chn_data = module.Genvar('chn_data')
    chn_batch = module.Genvar('chn_batch')
    
    max_iterations = rslt_len // RSLT_CHANNELS.value
    
    # Data, Grid & Scale coordinator
    per_channel_j  = module.GenerateFor(chn_data(0), chn_data <DATA_CHANNELS, chn_data(chn_data+1))
    per_channel_jk = per_channel_j.GenerateFor(chn_batch(0), chn_batch <BATCH_SIZE, chn_batch(chn_batch+1))
    
    LFT_POS = per_channel_jk.Localparam('LFT_POS',chn_batch * DATA_CHANNELS + chn_data)
    
    test_data = torch.stack(layer_data_q.squeeze(dim=1).split(DATA_CHANNELS.value,-1)).cpu().to(torch.uint16).tolist()
    test_grid = layer_grid_q.squeeze().cpu().tolist()
    test_scle = layer_scle_q.squeeze(0).cpu().tolist() if SCALE_SHARE.value else \
                torch.stack(layer_data_q.reshape(-1).split(DATA_CHANNELS.value,-1)).cpu().to(torch.uint16).tolist()
    
    hex_list = lambda x: hex(x) if isinstance(x, int) else [hex_list(_) for _ in x]
    # print('Test data:', np.array(test_data).shape)
    # print(np.array(hex_list(test_data)).squeeze())
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
    
    per_channel_jk.GenerateIf(Ors(
        GRID_SHARE == 0,
        LFT_POS == 0
    )).Initial(
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
        SCALE_SHARE == 0,
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
    test_rslt = torch.stack(layer_rslt_int.split(RSLT_CHANNELS.value,-1)).cpu().to(torch.uint16).tolist()
    # print('Test layer_data_q:', layer_data_q.shape)
    # print(np.array(hex_list(layer_data_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_grid_q:', layer_grid_q.shape)
    # print(np.array(hex_list(layer_grid_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_scle_q:', layer_scle_q.shape)
    # print(np.array(hex_list(layer_scle_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_diff_q:', layer_diff_q.shape)
    # print(np.array(hex_list(layer_diff_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_sdff_q:', layer_sdff_q.shape)
    # print(np.array(hex_list(layer_sdff_q.cpu().numpy().astype('uint16').tolist())))
    # x = torch.einsum("bw,wr->wbr", layer_actd_q, layer_wght_q).cpu().numpy().astype('int64')
    # print('Test layer_actd_q:', layer_actd_q.shape)
    # print(np.array(hex_list(layer_actd_q.cpu().numpy().astype('uint16').tolist())))
    # print('Test layer_wght_q:', layer_wght_q.shape)
    # print(np.array(hex_list(layer_wght_q.T.cpu().numpy().astype('uint16').tolist())))
    # print('Test psum')
    # print(*hex_list([np.sum(x[:_iter+1],axis=0).astype('uint64').tolist() for _iter in range(x.shape[0])]), sep ='\n')
    # print('Test rslt')
    # print(hex_list( np.right_shift(np.sum(x,axis=0).astype('int64'), -(RSLT_FRACTIONAL_BITS.value - (WEIGHT_FRACTIONAL_BITS.value + ACT_FRACTIONAL_BITS.value))).astype('uint16').tolist() ))

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
                                                        0
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
        (1,1,1),
        # (1,1,2),
        # (2,2,1),
        (2,2,2),
        # (2,3,1),
        # (8,4,2),
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
