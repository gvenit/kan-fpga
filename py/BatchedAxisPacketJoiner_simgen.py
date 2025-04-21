from __future__ import absolute_import
from __future__ import print_function
import sys
import os
import numpy as np

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

def BatchedAxisPacketJoiner():
    return verilog.from_verilog.read_verilog_module(
        os.path.join(TOP_DIR,'rtl/wrapper/BAPJWrapper.v')
    )['BAPJWrapper'] 

def tb_BatchedAxisPacketJoiner(channels=1, batch_size=1):
    module = Module('tb_BatchedAxisPacketJoiner')

    apj = BatchedAxisPacketJoiner()
    params = module.copy_params_as_localparams(apj)
    ports  = module.copy_ports_as_vars(apj)

    DATA_WIDTH      : Localparam = params['DATA_WIDTH']
    CHANNELS        : Localparam = params['CHANNELS']
    BATCH_SIZE      : Localparam = params['BATCH_SIZE']
    
    CONGESTION_LEVEL = module.Localparam('CONGESTION_LEVEL', 3)

    DATA_WIDTH.value = 8
    CHANNELS.value = channels
    BATCH_SIZE.value = batch_size
    
    clk = ports['clk']
    rst = ports['rst']
    
    operation_start     = ports['operation_start']
    use_channels        = ports['use_channels']
    use_batch           = ports['use_batch']
    
    operation_busy      = ports['operation_busy']
    operation_complete  = ports['operation_complete']
    operation_error     = ports['operation_error']
    transmission        = ports['transmission']
    
    # lock                = ports['lock']
    interrupt           = ports['interrupt']
    
    s_axis_tdata        = ports['s_axis_tdata']
    s_axis_tkeep        = ports['s_axis_tkeep']
    s_axis_tvalid       = ports['s_axis_tvalid']
    s_axis_tready       = ports['s_axis_tready']
    s_axis_tlast        = ports['s_axis_tlast']
    s_axis_tid          = ports['s_axis_tid']
    s_axis_tdest        = ports['s_axis_tdest']
    s_axis_tuser        = ports['s_axis_tuser']

    m_axis_tdata        = ports['m_axis_tdata']
    m_axis_tkeep        = ports['m_axis_tkeep']
    m_axis_tvalid       = ports['m_axis_tvalid']
    m_axis_tready       = ports['m_axis_tready']
    m_axis_tlast        = ports['m_axis_tlast']
    m_axis_tid          = ports['m_axis_tid']
    
    reset_done = module.Reg('reset_done', initval=0)

    uut = module.Instance(
        apj,
        'uut',
        params,
        ports
    )

    reset_stmt = []
    reset_stmt.append(reset_done(0))
    
    reset_stmt.append(operation_start(0))
    reset_stmt.append(use_channels(0))
    reset_stmt.append(use_batch(0))
    
    # reset_stmt.append(lock(0))
    reset_stmt.append(interrupt(0))
    
    reset_stmt.append(s_axis_tdata(0))
    reset_stmt.append(s_axis_tkeep(0))
    reset_stmt.append(s_axis_tvalid(0))
    reset_stmt.append(m_axis_tready(0))
    reset_stmt.append(s_axis_tlast(0))
    reset_stmt.append(s_axis_tid(0))
    reset_stmt.append(s_axis_tdest(0))
    reset_stmt.append(s_axis_tuser(0))

    vcd_name = os.path.join('..','vcd',f'tb_BatchedAxisPacketJoiner_{channels}_{batch_size}.vcd')
    simulation.setup_waveform(module, uut, dumpfile=vcd_name)
    simulation.setup_clock(module, clk, hperiod=1)
    init = simulation.setup_reset(module, rst, reset_stmt, period=10)

    nclk = simulation.next_clock
    
    module.EmbeddedCode(
    '''
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
    `define assertFalse(signal) \
    if (signal) begin \
        $display("ASSERTION FAILED in %m:"); \
        $display("---- Time %0t",$time); \
        $display("---- %s is not False",`"signal`"); \
        $display("---- %s = 0x%h",`"signal`",signal); \
        #5 \
        $finish; \
    end
    
    function automatic [31:0] find_next_chn;
        input [CHANNELS-1:0] use_channels;
        input integer signed current_channel;
        if (current_channel >= CHANNELS) begin
            find_next_chn = CHANNELS;
        end else if ((use_channels >> (($signed(current_channel)>=0) ? (current_channel + 1): 0)) == 0) begin
            find_next_chn = CHANNELS;
        end else if (~use_channels[($signed(current_channel)>=0) ? (current_channel + 1): 0]) begin
            find_next_chn = find_next_chn(use_channels,($signed(current_channel)>=0) ? (current_channel + 1): 0);
        end else
            find_next_chn = (($signed(current_channel)>=0) ? (current_channel + 1): 0);
    endfunction
    ''')
    
    init.add(
        Delay(10),
        # count(0),
        reset_done(1),
        # Systask('finish'),
        nclk(clk),
        Delay(50000),
        # Delay(10),
        Systask('finish'),
    )
    
    def Assert(signal,value):
        return EmbeddedCode(f'`assert({signal},{value})')
    def AssertTrue(signal):
        return EmbeddedCode(f'`assertTrue({signal})')
    def AssertFalse(signal):
        return EmbeddedCode(f'`assertFalse({signal})')
    
    def use_rand_channels(length):
        lst = [False]
        while np.sum(lst) < 1:
            lst = [bool(np.random.randint(2)) for _ in range(length)]
        return lst       
    
    def to_use_channels(lst):
        num = ','.join(["1'b1" if chn else "1'b0" for chn in lst[::-1]])
        return EmbeddedCode("{" f"{num}" "}")
    
    def find_next_chn(lst : EmbeddedCode, current_channel = -1):
        return EmbeddedCode(f'find_next_chn({lst.code},{current_channel})')
    
    def check_rand(channels, packet_length):
        if isinstance(channels,list) and isinstance(packet_length,list):
            return [check_rand(chn_i,pckt_i) for chn_i,pckt_i in zip(channels,packet_length)]
        else :
            return packet_length if channels else 0
    
    
    cong_counter = module.Integer('glo_cong_counter')
    max_pckt_len = 5
    repeatitions = 5
    
    use_channels_2 = [True  for _ in range(CHANNELS.value)]
    use_channels_3 = [True  for _ in range(CHANNELS.value)]
    use_channels_4 = use_rand_channels(CHANNELS.value)
    use_channels_5 = [use_rand_channels(CHANNELS.value) for _ in range(repeatitions)]
    use_channels_6 = [use_rand_channels(CHANNELS.value) for _ in range(repeatitions)]
    
    use_batch_2 = [True for _ in range(BATCH_SIZE.value)]
    use_batch_3 = [True for _ in range(BATCH_SIZE.value)]
    use_batch_4 =  use_rand_channels(BATCH_SIZE.value)
    use_batch_5 = [use_rand_channels(BATCH_SIZE.value) for _ in range(repeatitions)]
    use_batch_6 = [use_rand_channels(BATCH_SIZE.value) for _ in range(repeatitions)]
        
    rand_pckt_len_5= check_rand(
        use_channels_5,[[
        np.random.randint(1,max_pckt_len) 
            for _ in range(CHANNELS.value)
        ] for _ in range(repeatitions)
    ])
    
    # Configuration driver
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        operation_start(0),
        use_channels(0),
        use_batch(0),
        Wait(clk),
        
        For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter.inc())(
            Wait(~clk),
            AssertFalse(operation_busy),
            AssertFalse(operation_complete),
            AssertFalse(operation_error),
            Wait(clk),
        ),
        Wait(~clk),
        interrupt(1),
        Wait(clk),
        Wait(~clk),
        interrupt(0),
        Wait(~clk),
        Wait(clk),
        
        # # Test 1 : Locking core when no operation in progress
        # Wait(~clk),
        # operation_start(0),
        # use_channels(0),
        # use_batch(0),
        # lock(1),
        # Wait(clk),
        
        # Wait(~clk),
        # operation_start(1),
        # use_channels(to_use_channels(use_channels_2)),
        # Wait(clk),
        
        # For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter.inc())(
        #     Wait(~clk),
        #     AssertFalse(operation_busy),
        #     AssertFalse(operation_complete),
        #     AssertFalse(operation_error),
        #     Wait(clk),
        # ),
        
        # Wait(~clk),
        # operation_start(0),
        # use_channels(0),
        # use_batch(0),
        # lock(0),
        # Wait(clk),
        
        # Wait(~clk),
        # interrupt(1),
        # Wait(clk),
        # Wait(~clk),
        # interrupt(0),
        # Wait(~clk),
        
        # Test 2 : Invalid Configuration
        
        For(cong_counter(0), cong_counter < 3, cong_counter.inc())(
            Wait(~clk),
            AssertFalse(operation_busy),
            AssertFalse(operation_complete),
            AssertFalse(operation_error),
            Wait(clk),
        ),
        Wait(~clk),
        operation_start(1),
        use_channels(0),
        use_batch(0),
        Wait(clk),
        
        Wait(~clk),
        operation_start(0),
        use_channels(0),
        use_batch(0),
        AssertFalse(operation_busy),
        AssertFalse(operation_complete),
        AssertTrue(operation_error),
        Wait(clk),
        
        Wait(~clk),
        interrupt(1),
        Wait(clk),
        Wait(~clk),
        interrupt(0),
        Wait(~clk),
        Wait(clk),
        
        # Test 3 : Nominal mode with congestion
        Wait(~clk),
        operation_start(1),
        use_channels(to_use_channels(use_channels_3)),
        use_batch(to_use_channels(use_batch_3)),
        Wait(clk),
        
        Wait(~clk),
        operation_start(1),
        use_channels(0),
        use_batch(0),
        AssertTrue(operation_busy),
        AssertFalse(operation_complete),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        use_channels(0),
        use_batch(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_busy),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        
        # Wait(Ands(m_axis_tlast, m_axis_tready, m_axis_tvalid)),
        
        # Test 4 : Nominal mode with data sparcity
        Wait(~clk),
        operation_start(1),
        use_channels(to_use_channels(use_channels_4)),
        use_batch(to_use_channels(use_batch_4)),
        Wait(clk),
        Wait(~clk),
        
        operation_start(0),
        use_channels(0),
        use_batch(0),
        Wait(operation_busy),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        Wait(~operation_complete),
        # Wait(Ands(m_axis_tlast, m_axis_tready, m_axis_tvalid)),
        
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        interrupt(1),
        Wait(clk),
        Wait(~clk),
        While(s_axis_tvalid)(
            Wait(clk),
            Wait(~clk),
        ),
        interrupt(0),
        Wait(clk),
        Wait(~clk),
        
        # Test 5 : Nominal mode with max throughput (random packet sizes per channel)
        Wait(~clk),
        operation_start(1),
        use_channels(to_use_channels(use_channels_5[0])),
        use_batch(to_use_channels(use_batch_5[0])),
        Wait(clk),
        Wait(~clk),
        While(~operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        For(cong_counter(1), cong_counter < repeatitions, cong_counter.inc())(
            Case(cong_counter)(
                *[
                    When(_iter)(
                        use_channels(to_use_channels(use_channels_5_iter)),
                        use_batch(to_use_channels(use_batch_5_iter)),
                    ) for _iter, (use_channels_5_iter, use_batch_5_iter) in enumerate(zip(use_channels_5,use_batch_5))
                ]
            ),
            Wait(clk),
            Wait(~clk),
            While(operation_busy)(
                AssertFalse(operation_error),
                AssertFalse(operation_complete),
                Wait(clk),
                Wait(~clk),
            ),
            AssertFalse(operation_error),
            AssertTrue(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        operation_start(0),
        use_channels(0),
        use_batch(0),
        Wait(clk),
        Wait(~clk),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        interrupt(1),
        Wait(clk),
        Wait(~clk),
        While(s_axis_tvalid)(
            Wait(clk),
            Wait(~clk),
        ),
        interrupt(0),
        Wait(clk),
        Wait(~clk),
        
        # Test 6 : Nominal mode with max throughput (single word packets per channel)
        Wait(~clk),
        operation_start(1),
        use_channels(to_use_channels(use_channels_6[0])),
        use_batch(to_use_channels(use_batch_6[0])),
        Wait(clk),
        Wait(~clk),
        While(~operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        For(cong_counter(1), cong_counter < repeatitions, cong_counter.inc())(
            Case(cong_counter)(
                *[
                    When(_iter)(
                        use_channels(to_use_channels(use_channels_6_iter)),
                        use_batch(to_use_channels(use_batch_6_iter)),
                    ) for _iter, (use_channels_6_iter,use_batch_6_iter) in enumerate(zip(use_channels_6,use_batch_6))
                ]
            ),
            Wait(clk),
            Wait(~clk),
            While(operation_busy)(
                AssertFalse(operation_error),
                AssertFalse(operation_complete),
                Wait(clk),
                Wait(~clk),
            ),
            AssertFalse(operation_error),
            AssertTrue(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        While(operation_busy)(
            AssertFalse(operation_error),
            AssertFalse(operation_complete),
            Wait(clk),
            Wait(~clk),
        ),
        AssertFalse(operation_error),
        AssertTrue(operation_complete),
        
    )

    # Generate Variables
    chn = module.Genvar('CHN')
    batch = module.Genvar('BATCH')
    
    # Data Axi-Stream instances
    per_chn = module.GenerateFor(batch(0),batch < batch_size, batch.inc())
    per_chn = per_chn.GenerateFor(chn(0), chn < CHANNELS, chn.inc())
    LFT_POS = per_chn.Localparam('LFT_POS',batch*CHANNELS+chn)
    
    # Data Axi-Stream Input Controller
    data_counter = per_chn.Integer('data_counter_in')
    cong_counter = per_chn.Integer('cong_counter_in')
    data_slice = s_axis_tdata.slice(
        msb = (LFT_POS+1)*DATA_WIDTH-1,
        lsb = LFT_POS * DATA_WIDTH
    )
    pckt_len_i  = per_chn.Integer('pckt_len_i')
    batch_i     = per_chn.Integer('batch_i')
    per_chn.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        data_counter(chn),
        s_axis_tvalid[LFT_POS](1),
        s_axis_tlast[LFT_POS](0),
        While(~interrupt)(
            AssertFalse(s_axis_tready[LFT_POS]),
            Wait(~clk),
            Wait(clk),
        ),
        s_axis_tvalid[LFT_POS](0),
        s_axis_tlast[LFT_POS](0),
        Wait(~clk),
        Wait(clk),
        
        # # Test 1 : Locking core when no operation in progress
        # Wait(~clk),
        # s_axis_tvalid[LFT_POS](1),
        # s_axis_tlast[LFT_POS](1),
        # data_slice(CHANNELS+chn),
        # Wait(lock),
        # While(~lock)(
        #     AssertFalse(s_axis_tready[LFT_POS]),
        #     Wait(~clk),
        #     Wait(clk),
        # ),
        # s_axis_tvalid[LFT_POS](0),
        # s_axis_tlast[LFT_POS](0),
        # Wait(~clk),
        # Wait(clk),
        
        # Test 2 : Invalid Configuration
        Wait(~clk),
        s_axis_tvalid[LFT_POS](1),
        data_slice((batch+1)*(chn+1)),
        s_axis_tlast[LFT_POS](1),
        Wait(operation_error),
        Wait(~clk),
        s_axis_tvalid[LFT_POS](0),
        data_slice(0),
        s_axis_tlast[LFT_POS](0),
        Wait(~operation_error),
        
        # Test 3 : Nominal mode with congestion
        Wait(~clk),
        For(data_counter(0), Ands(data_counter < max_pckt_len, ~operation_error), data_counter.inc())(
            s_axis_tvalid[LFT_POS](1),
            data_slice(data_counter*(chn+1)),
            While(~Ors(s_axis_tready[LFT_POS],operation_error))(
                Wait(clk),
                Wait(~clk),
            ),
            s_axis_tlast[LFT_POS](data_counter == max_pckt_len-1),
            Wait(clk),
            Wait(~clk),
        ),
        # s_axis_tvalid[LFT_POS](0),
        s_axis_tlast[LFT_POS](0),
        Wait(~clk),
        Wait(clk),
        Wait(operation_start),
        Wait(~clk),
        s_axis_tvalid[LFT_POS](0),
        
        # Test 4 : Nominal mode with data sparcity
        Wait(~clk),
        For(data_counter(0), Ands(data_counter < max_pckt_len, ~interrupt), data_counter.inc())(
            s_axis_tvalid[LFT_POS](0),
            For(cong_counter(0), Ands(cong_counter < CONGESTION_LEVEL, ~interrupt), cong_counter.inc())(

                Wait(clk),
                Wait(~clk),
            ),
            s_axis_tvalid[LFT_POS](1),
            data_slice(data_counter*(chn+1)),
            s_axis_tlast[LFT_POS](data_counter == max_pckt_len-1),
            While(~Ors(s_axis_tready[LFT_POS],interrupt))(
                    Wait(clk),
                    Wait(~clk),
                ),
            Wait(clk),
            Wait(~clk),
        ),
        s_axis_tvalid[LFT_POS](0),
        s_axis_tlast[LFT_POS](0),
        Wait(interrupt),
        Wait(~interrupt),
        
        # Test 5 : Nominal mode with max throughput (random packet sizes per channel)
        *[
            If(1)(
                Wait(clk),
                Case(chn)(*[
                    When(i)(
                        pckt_len_i(rand_pckt_len_i[i])
                    ) for i in range(CHANNELS.value)
                ],
                    When()(
                        pckt_len_i(max_pckt_len)
                    )
                ),
                batch_i(to_use_channels(use_batch_5_i)),
                Wait(~clk),
                s_axis_tvalid[LFT_POS](1),
                If(Ands(pckt_len_i,batch_i[batch]))(
                    For(data_counter(0), Ands(data_counter < pckt_len_i, ~interrupt), data_counter.inc())(
                        Wait(~clk),
                        data_slice(data_counter*(chn+1)),
                        s_axis_tlast[LFT_POS](data_counter == pckt_len_i-1),
                        While(~Ors(s_axis_tready[LFT_POS],interrupt))(
                            Wait(clk),
                            Wait(~clk),
                        ),
                        Wait(clk),
                    )
                ).Else(
                    data_slice(EmbeddedNumeric(f"{DATA_WIDTH.value}'bX")),
                    While(~operation_complete)(
                        Wait(clk),
                        Wait(~clk),
                    )
                )
            ) for rand_pckt_len_i, use_batch_5_i in zip(rand_pckt_len_5, use_batch_5)
        ],
        Wait(~clk),
        s_axis_tvalid[LFT_POS](0),
        Wait(interrupt),
        Wait(clk),
        Wait(~clk),
        Wait(~interrupt),
        Wait(~clk),
        
        # Test 6 : Nominal mode with max throughput (single word packets per channel)
        *[
            If(1)(
                batch_i(to_use_channels(use_batch_6_i)),
                s_axis_tvalid[LFT_POS](1),
                s_axis_tlast[LFT_POS](1),
                If(batch_i[batch])(
                    data_slice(chn+1),
                    While(~s_axis_tready[LFT_POS])(
                        Wait(~clk),
                        Wait(clk),
                    ),
                    s_axis_tvalid[LFT_POS](0),
                ).Else(
                    data_slice(0),
                    Wait(operation_busy),
                    While(operation_busy)(
                        Wait(~clk),
                        Wait(clk),
                    ),
                ),
                Wait(~clk),
            ) 
            for use_batch_6_i in use_batch_6
        ]
    )
    
    # Data Axi-Stream Output Controller
    batch_counter = module.Integer('batch_counter_out')
    chn_counter  = module.Integer('chn_counter_out')
    data_counter = module.Integer('data_counter_out')
    cong_counter = module.Integer('cong_counter_out')
    # batch_is_used = module.Reg('glo_batch_is_used',1)
    
    data_slice   = m_axis_tdata
    pckt_len_i   = module.Integer('glo_pckt_len_i')
    module.Initial(
        Wait(reset_done),
        Wait(clk),
        
        # Test 0 : Blocking data stream when no operation in progress
        Wait(~clk),
        m_axis_tready(1),
        While(~interrupt)(
            AssertFalse(m_axis_tvalid),
            Wait(~clk),
            Wait(clk),
        ),
        m_axis_tready(0),
        Wait(~clk),
        Wait(clk),
        
        # # Test 1 : Locking core when no operation in progress
        # Wait(~clk),
        # m_axis_tready(1),
        # While(~lock)(
        #     AssertFalse(m_axis_tvalid),
        #     Wait(clk),
        #     Wait(~clk),
        # ),
        # While(lock)(
        #     AssertFalse(m_axis_tvalid),
        #     Wait(clk),
        #     Wait(~clk),
        # ),
        # m_axis_tready(0),
        # Wait(clk),
        
        # Test 2 : Invalid Configuration
        Wait(operation_error),
        Wait(~operation_error),
        
        # Test 3 : Nominal mode with congestion
        Wait(~clk),
        For(batch_counter(-1), batch_counter < BATCH_SIZE, batch_counter(find_next_chn(to_use_channels(use_batch_3),batch_counter)))(
            For(chn_counter(-1), chn_counter < CHANNELS, chn_counter(find_next_chn(to_use_channels(use_channels_3),chn_counter)))(
                If(Ands(chn_counter >= 0,chn_counter < CHANNELS, batch_counter >= 0,batch_counter < BATCH_SIZE))(
                    Display("Test3 : batch %d channel %d", batch_counter, chn_counter),
                    For(data_counter(0), data_counter < max_pckt_len, data_counter.inc())(
                        m_axis_tready(0),
                        For(cong_counter(0), cong_counter < CONGESTION_LEVEL, cong_counter(cong_counter+1))(
                            While(~m_axis_tvalid)(
                                Wait(clk),
                                Wait(~clk),
                            ),
                            Wait(clk),
                            Wait(~clk),
                        ),
                        m_axis_tready(1),
                        Assert(data_slice, data_counter*(chn_counter+1)),
                        Assert(m_axis_tlast, Ands(data_counter == max_pckt_len-1, chn_counter == CHANNELS-1-int(np.argmax(use_channels_3[::-1])))),
                        Assert(m_axis_tid, batch_counter),
                        Wait(clk),
                        Wait(~clk),
                    ),
                ),
            ),
        ),
        m_axis_tready(0),
        Wait(~clk),
        Wait(clk),
        
        # Test 4 : Nominal mode with data sparcity
        Wait(~clk),
        m_axis_tready(1),
        For(batch_counter(-1), batch_counter < BATCH_SIZE, batch_counter(find_next_chn(to_use_channels(use_batch_4),batch_counter)))(
            For(chn_counter(-1), chn_counter < CHANNELS, chn_counter(find_next_chn(to_use_channels(use_channels_4),chn_counter)))(
                If(Ands(chn_counter >= 0,chn_counter < CHANNELS, batch_counter >= 0,batch_counter < BATCH_SIZE))(
                    Display("Test4 : batch %d channel %d", batch_counter, chn_counter),
                    For(data_counter(0), data_counter < max_pckt_len, data_counter.inc())(
                        While(~m_axis_tvalid)(
                            Wait(clk),
                            Wait(~clk),
                        ),
                        Assert(data_slice, data_counter*(chn_counter+1)),
                        Assert(m_axis_tlast, Ands(data_counter == max_pckt_len-1, chn_counter == CHANNELS-1-int(np.argmax(use_channels_4[::-1])))),
                        Assert(m_axis_tid, batch_counter),
                        Wait(clk),
                        Wait(~clk),
                    ),
                ),
            ),
        ),
        Wait(clk),
        
        # Test 5 : Nominal mode with max throughput (random packet sizes per channel)
        *[
            For(batch_counter(-1), batch_counter < BATCH_SIZE, batch_counter(find_next_chn(to_use_channels(use_batch_5_i),batch_counter)))(
                For(chn_counter(-1), chn_counter < CHANNELS, chn_counter(find_next_chn(to_use_channels(use_channels_5_i),chn_counter)))(
                    If(Ands(chn_counter >= 0,chn_counter < CHANNELS, batch_counter >= 0,batch_counter < BATCH_SIZE))(
                        Case(chn_counter)(*[
                            When(i)(
                                pckt_len_i(rand_pckt_len_5_i[i])
                            ) for i in range(CHANNELS.value)
                        ],
                            When()(
                                pckt_len_i(max_pckt_len)
                            )
                        ),
                        Display(f"Test5 : repeatition {_iter} batch %d channel %d channels %b batches %b pckt_len %d ", batch_counter, chn_counter, to_use_channels(use_channels_5_i), to_use_channels(use_batch_5_i),pckt_len_i),
                        For(data_counter(0), data_counter < pckt_len_i, data_counter.inc())(
                            Wait(~clk),
                            m_axis_tready(1),
                            While(~m_axis_tvalid)(
                                Wait(clk),
                                Wait(~clk),
                            ),
                            Assert(data_slice, data_counter*(chn_counter+1)),
                            Assert(m_axis_tlast, Ands(data_counter == pckt_len_i-1, chn_counter == CHANNELS-1-int(np.argmax(use_channels_5_i[::-1])))),
                            Assert(m_axis_tid, batch_counter),
                            Wait(clk),
                        ),
                    ),
                ),
            ) for _iter, (use_batch_5_i,use_channels_5_i,rand_pckt_len_5_i) in enumerate(zip(use_batch_5,use_channels_5,rand_pckt_len_5))
        ],
        m_axis_tready(0),
        Wait(clk),
        Wait(interrupt),
        
        # Test 6 : Nominal mode with max throughput (single word packets per channel)
        Wait(~clk),
        m_axis_tready(1),
        *[
            For(batch_counter(-1), batch_counter < BATCH_SIZE, batch_counter(find_next_chn(to_use_channels(use_batch_6_i),batch_counter)))(
                For(chn_counter(-1), chn_counter < CHANNELS, chn_counter(find_next_chn(to_use_channels(use_channels_6_i),chn_counter)))(
                    If(Ands(chn_counter >= 0,chn_counter < CHANNELS, batch_counter >= 0,batch_counter < BATCH_SIZE))(
                        Display(f"Test6 : repeatition {_iter} batch %d channel %d channels %b  batches %b", batch_counter, chn_counter, to_use_channels(use_channels_6_i), to_use_channels(use_batch_6_i)),
                        While(~m_axis_tvalid)(
                            Wait(clk),
                            Wait(~clk),
                        ),
                        Assert(data_slice, chn_counter+1),
                        Assert(m_axis_tlast, chn_counter == CHANNELS-1-int(np.argmax(use_channels_6_i[::-1]))),
                        Assert(m_axis_tid, batch_counter),
                        Wait(clk),
                        Wait(~clk),
                    ),
                ),
            ) for _iter, (use_batch_6_i, use_channels_6_i) in enumerate(zip(use_batch_6,use_channels_6))
        ],
        
        m_axis_tready(0),
        Wait(~clk),
        Wait(clk),
        
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        Wait(~clk),
        Wait(clk),
        
        Delay(10),
        Finish(),
    )

    return module

def main():
    os.makedirs(os.path.join(TOP_DIR,'rtl'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'tb'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'vcd'), exist_ok=True)
    os.makedirs(os.path.join(TOP_DIR,'out'), exist_ok=True)
    
    os.chdir(os.path.join(TOP_DIR,'rtl'))

    # module = BatchedAxisPacketJoiner()
    # fname = os.path.join(TOP_DIR,'rtl/BatchedAxisPacketJoiner.v')
    # verilog = module.to_verilog(fname)
    # stripModule(fname, 'BatchedAxisPacketJoiner')
    # addTimeScale(fname)
    
    for channels, batch in (
        # (2,1),
        # (2,2),
        # (4,1),
        (4,4),
    ):
        test = tb_BatchedAxisPacketJoiner(channels=channels,batch_size=batch)
        fname = os.path.join(TOP_DIR,f'tb/tb_BatchedAxisPacketJoiner_{channels}_{batch}.v')
        verilog_test = test.to_verilog(fname)
        stripModule(fname, 'BatchedAxisPacketJoiner')
        addTimeScale(fname)

        os.system(' '.join([
            os.path.join(TOP_DIR,'auxiliary/run_sim.sh'),
            '-v',
            '-p',
            f'tb_BatchedAxisPacketJoiner_{channels}_{batch}',
        ]))

if __name__ == "__main__":
    main()
