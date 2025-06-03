`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * CentralControlUnit : The high level Controller for KanLayer.
 *    The module consists of an FSM that handles requests and interrupts
 *        from both the Processing System and the Programmable Logic.
 *        The core also updates the PS with the core status and 
 *        some statistics about the data processing time and latency.
 * 
 *    Signals :
 *        fsm_clk -- The FSM Clock domain. It is expected to be the 
 *            slowest clock of the KanLayer
 *        fsm_rst -- The reset signal assosiated with the fsm_clk
 *        operation_start -- An internal control signal for peripheral
 *            initialization and for signaling the start of 
 *            data processing throughout the core's submodules.
 *            Synchronous to fsm_clk.
 *        data_size, grid_size, scle_size, pckt_size -- System parameters.
 *            Synchronous to fsm_clk. Valid when operation_start is True.
 *        peripheral_operation_busy -- Status BUSY signal from peripherals.
 *            Signal may have different clock domains than the module.
 *        peripheral_operation_complete -- Status COMPLETE signal from peripherals.
 *            Signal may have different clock domains than the module.
 *        peripheral_operation_error -- Status ERROR signal from peripherals.
 *            Signal may have different clock domains than the module.
 *        operation_busy -- Status BUSY signal for KanLayer in general.
 *            Signal operates on the FSM clock domain.
 *        operation_complete -- Status COMPLETE signal for KanLayer in general.
 *            Signal operates on the FSM clock domain.
 *        operation_error -- Status ERROR signal for KanLayer in general.
 *            Signal operates on the FSM clock domain.
 *        internal_operation_error -- Status ERROR signal for KanLayer in general.
 *            Signal operates on the FSM clock domain. For KanLayer internal use only.
 *        locked -- Core is locked and awaiting actions from PS. Signal operates  
 *            on the FSM clock domain.
 *        pl2ps_intr -- Interrupt signal for PS. Signals PS for register updates
 *            from the PL side. Signal operates on the FSM clock domain.
 *        s_axil -- AXI-Lite interface for PS-PL communication
 * 
 */
`include "header_utils.vh"

module CentralControlUnit #(
  `include "header_ControlRegisters.vh"
  `include "header_Peripherals.vh"
  // Number of PEs in Processing Array k axis -- Number of batches per run
  parameter BATCH_SIZE = 1,
  // Number of Independent AXI-Stream Data Channels
  parameter DATA_CHANNELS = 1,
  // Number of Independent AXI-Stream Result Channels per Batch
  parameter RSLT_CHANNELS = 1,
  // Data Width of address bus in bits
  parameter DATA_ADDR = 32,
  // Grid Width of address bus in bits
  parameter GRID_ADDR = 32,
  // Scale Width of address bus in bits
  parameter SCALE_ADDR = 32,
  // Width of Packet size bus in bits
  parameter PCKT_SIZE_WIDTH = DATA_ADDR + GRID_ADDR,
  // Set to true if fsm_clk and core_clk are driven by different clocks
  parameter IS_ASYNCHRONOUS = 1
) (
  input  wire                             fsm_clk,
  input  wire                             fsm_rst,

  input  wire                             core_clk,
  input  wire                             core_rst,

  /*
   * Control signals -- Corresponding clock : fsm_clk
   */
  output reg                              operation_start,
  output reg  [DATA_ADDR:0]               data_size,
  output reg  [GRID_ADDR:0]               grid_size,
  output reg  [SCALE_ADDR:0]              scle_size,
  output reg  [PCKT_SIZE_WIDTH-1:0]       pckt_size,

  output reg                              iteration_start,
  output reg  [RSLT_CHANNELS-1:0]         use_channels,
  output reg  [BATCH_SIZE-1:0]            use_batch,
  
  /*
   * Input Interrupt signals -- Corresponding clock : Any
   */
  input  wire [NUM_PERIPHERALS-1:0]       peripheral_operation_busy,
  input  wire [NUM_PERIPHERALS-1:0]       peripheral_operation_complete,
  input  wire [NUM_PERIPHERALS-1:0]       peripheral_operation_error,
  input  wire [NUM_PERIPHERALS-1:0]       peripheral_transmission,
  input  wire                             rslt_tlast,

  /*
   * Output Interrupt signals -- Corresponding clock : fsm_clk
   */
  output reg                              operation_busy,
  output reg                              operation_complete,
  output reg                              operation_error,
  output reg                              internal_operation_error,
  output reg                              locked,
  output reg                              pl2ps_intr,

  /*
   * AXI-Lite Control -- Corresponding clock : fsm_clk
   */
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWADDR" *)
  (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,ADDR_WIDTH CTLR_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH 32" *)
  input  wire [CTLR_ADDR-1:0]             s_axil_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWPROT" *)
  input  wire [2:0]                       s_axil_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWVALID" *)
  input  wire                             s_axil_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWREADY" *)
  output wire                             s_axil_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WDATA" *)
  input  wire [31:0]                      s_axil_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WSTRB" *)
  input  wire [3:0]                       s_axil_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WVALID" *)
  input  wire                             s_axil_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WREADY" *)
  output wire                             s_axil_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BRESP" *)
  output wire [1:0]                       s_axil_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BVALID" *)
  output wire                             s_axil_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BREADY" *)
  input  wire                             s_axil_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARADDR" *)
  input  wire [CTLR_ADDR-1:0]             s_axil_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARPROT" *)
  input  wire [2:0]                       s_axil_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARVALID" *)
  input  wire                             s_axil_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARREADY" *)
  output wire                             s_axil_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RDATA" *)
  output wire [31:0]                      s_axil_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RRESP" *)
  output wire [1:0]                       s_axil_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RVALID" *)
  output wire                             s_axil_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RREADY" *)
  input  wire                             s_axil_rready
);
  // Local Parameters
  localparam MAX_DATA_SIZE = 2 ** DATA_ADDR;
  localparam MAX_GRID_SIZE = 2 ** GRID_ADDR;
  localparam MAX_SCLE_SIZE = 2 ** SCALE_ADDR;
  localparam MAX_PCKT_SIZE = 2 ** PCKT_SIZE_WIDTH;

  // FSM States
  localparam FSM_WIDTH = 3;
  localparam FSM_ST0 = 0;
  localparam FSM_STR = 1;
  localparam FSM_OPE = 2;
  localparam FSM_ERR = 3;
  localparam FSM_END = 4;
  localparam FSM_ITR = 5;

  // FSM output states
  reg  [FSM_WIDTH-1:0] fsm_state, fsm_state_next;
  
  // Peripheral sampler
  wire  [NUM_PERIPHERALS-1:0] peripheral_operation_busy_sampled;
  wire  [NUM_PERIPHERALS-1:0] peripheral_operation_complete_sampled;
  wire  [NUM_PERIPHERALS-1:0] peripheral_operation_error_sampled;
  wire                        rslt_tlast_sampled;

  // Capture interrupts -- Reset every clock tick
 generate
  if (IS_ASYNCHRONOUS) begin
    genvar peripheral;
    for (peripheral = 0; peripheral < NUM_PERIPHERALS; peripheral = peripheral + 1) begin : peripheral_samplers_genblock 
      Sampler #(
      ) sampler_peripheral_op_busy_inst (
        .signal_clk       (core_clk),
        .sampler_clk      (fsm_clk),
        .signal           (peripheral_operation_busy[peripheral]),
        .sampled_signal   (peripheral_operation_busy_sampled[peripheral])
      );
      Sampler #(
      ) sampler_peripheral_op_complete_inst (
        .signal_clk       (core_clk),
        .sampler_clk      (fsm_clk),
        .signal           (peripheral_operation_complete[peripheral]),
        .sampled_signal   (peripheral_operation_complete_sampled[peripheral])
      );
      Sampler #(
      ) sampler_peripheral_op_error_inst (
        .signal_clk       (core_clk),
        .sampler_clk      (fsm_clk),
        .signal           (peripheral_operation_error[peripheral]),
        .sampled_signal   (peripheral_operation_error_sampled[peripheral])
      );
    end
    Sampler #(
    ) sampler_rslt_tlast_inst (
      .signal_clk       (core_clk),
      .sampler_clk      (fsm_clk),
      .signal           (rslt_tlast),
      .sampled_signal   (rslt_tlast_sampled)
    );
  end else begin
    always @(*) begin
      peripheral_operation_busy_sampled     <= peripheral_operation_busy;
      peripheral_operation_complete_sampled <= peripheral_operation_complete;
      peripheral_operation_error_sampled    <= peripheral_operation_error;
      rslt_tlast_sampled                    <= rslt_tlast;
    end
  end
 endgenerate

  // Input PL control signals
  reg         rw_op_str_reg_en;
  reg         rw_op_dne_reg_en;
  wire        wo_reg_en  = rslt_tlast_sampled == 1'b1; 
  wire        wo_reg_rst = (fsm_state == FSM_STR || fsm_state == FSM_ITR);

  // Read-Write Registers (PS -> PL) 
  wire [31:0] data_size_rd; 
  wire [31:0] grid_size_rd; 
  wire [31:0] scle_size_rd; 
  wire [31:0] rslt_size_rd; 
  wire [31:0] pckt_size_rd; 
  wire [ 7:0] btch_size_rd; 

  wire [31:0] data_size_wr = 0;
  wire [31:0] grid_size_wr = 0;
  wire [31:0] scle_size_wr = 0;
  wire [31:0] rslt_size_wr = 0;
  wire [31:0] pckt_size_wr = 0;
  wire [ 7:0] btch_size_wr = 0;

  wire        data_loaded_rd;
  wire        grid_loaded_rd;
  wire        scle_loaded_rd;
  wire        wght_loaded_rd;

  wire        data_loaded_wr = 1'b0;
  wire        grid_loaded_wr = 1'b0;
  wire        scle_loaded_wr = 1'b0;
  wire        wght_loaded_wr = 1'b0;

  wire        operation_start_rd;
  wire        operation_start_wr = 1'b0;

  // Read-Only Registers (PS -> PL)
  wire        interrupt_soft;
  wire        interrupt_abort;
  wire        interrupt_error;

  // Read-Write Registers (PL -> PS)
  wire        operation_done_rd;
  wire        operation_done_wr = (fsm_state_next == FSM_END);
  
  // Write-Only Registers (PL -> PS)
  wire        operation_status_idle_wr = ~(operation_busy || operation_error);
  wire        operation_status_busy_wr = operation_busy;
  wire        operation_status_error_wr = operation_error;
  wire        operation_status_locked_wr;
  wire        operation_status_valid_wr;
  wire        operation_status_reset_wr = core_rst;

  wire [31:0] operation_progress_rslt_wr;
  wire [31:0] operation_progress_iter_wr;
  wire [31:0] iteration_timer_wr = -1;
  wire [31:0] iteration_latency_wr = -1;
  wire [31:0] operation_timer_wr = -1;
  wire [31:0] operation_latency_wr = -1;

  CCURegisterFile #(
  ) register_file (
    .clk                        (fsm_clk),
    .rst                        (fsm_rst),
    .rw_op_str_reg_en           (rw_op_str_reg_en),
    .rw_op_dne_reg_en           (rw_op_dne_reg_en),
    .wo_reg_en                  (wo_reg_en),
    .wo_reg_rst                 (wo_reg_rst),
    .data_size_rd               (data_size_rd),
    .grid_size_rd               (grid_size_rd),
    .scle_size_rd               (scle_size_rd),
    .rslt_size_rd               (rslt_size_rd),
    .pckt_size_rd               (pckt_size_rd),
    .btch_size_rd               (btch_size_rd),
    .data_size_wr               (data_size_wr),
    .grid_size_wr               (grid_size_wr),
    .scle_size_wr               (scle_size_wr),
    .rslt_size_wr               (rslt_size_wr),
    .pckt_size_wr               (pckt_size_wr),
    .btch_size_wr               (btch_size_wr),
    .data_loaded_rd             (data_loaded_rd),
    .grid_loaded_rd             (grid_loaded_rd),
    .scle_loaded_rd             (scle_loaded_rd),
    .wght_loaded_rd             (wght_loaded_rd),
    .data_loaded_wr             (data_loaded_wr),
    .grid_loaded_wr             (grid_loaded_wr),
    .scle_loaded_wr             (scle_loaded_wr),
    .wght_loaded_wr             (wght_loaded_wr),
    .operation_start_rd         (operation_start_rd),
    .operation_start_wr         (operation_start_wr),
    .interrupt_soft             (interrupt_soft),
    .interrupt_abort            (interrupt_abort),
    .interrupt_error            (interrupt_error),
    .operation_done_rd          (operation_done_rd),
    .operation_done_wr          (operation_done_wr),
    .operation_status_idle_wr   (operation_status_idle_wr),
    .operation_status_busy_wr   (operation_status_busy_wr),
    .operation_status_error_wr  (operation_status_error_wr),
    .operation_status_locked_wr (operation_status_locked_wr),
    .operation_status_valid_wr  (operation_status_valid_wr),
    .operation_status_reset_wr  (operation_status_reset_wr),
    .operation_progress_rslt_wr (operation_progress_rslt_wr),
    .operation_progress_iter_wr (operation_progress_iter_wr),
    .iteration_timer_wr         (iteration_timer_wr),
    .iteration_latency_wr       (iteration_latency_wr),
    .operation_timer_wr         (operation_timer_wr),
    .operation_latency_wr       (operation_latency_wr),
    .s_axil_awaddr              (s_axil_awaddr),
    .s_axil_awprot              (s_axil_awprot),
    .s_axil_awvalid             (s_axil_awvalid),
    .s_axil_awready             (s_axil_awready),
    .s_axil_wdata               (s_axil_wdata),
    .s_axil_wstrb               (s_axil_wstrb),
    .s_axil_wvalid              (s_axil_wvalid),
    .s_axil_wready              (s_axil_wready),
    .s_axil_bresp               (s_axil_bresp),
    .s_axil_bvalid              (s_axil_bvalid),
    .s_axil_bready              (s_axil_bready),
    .s_axil_araddr              (s_axil_araddr),
    .s_axil_arprot              (s_axil_arprot),
    .s_axil_arvalid             (s_axil_arvalid),
    .s_axil_arready             (s_axil_arready),
    .s_axil_rdata               (s_axil_rdata),
    .s_axil_rresp               (s_axil_rresp),
    .s_axil_rvalid              (s_axil_rvalid),
    .s_axil_rready              (s_axil_rready)
  );

  // Check if operation is valid
  wire operation_valid = &{
    data_loaded_rd, |data_size_rd, data_size_rd <= MAX_DATA_SIZE,
    grid_loaded_rd, |grid_size_rd, grid_size_rd <= MAX_GRID_SIZE,
    scle_loaded_rd, |scle_size_rd, scle_size_rd <= MAX_SCLE_SIZE,
    wght_loaded_rd, |pckt_size_rd, pckt_size_rd <= MAX_PCKT_SIZE,
     |rslt_size_rd, |btch_size_rd, btch_size_rd <= BATCH_SIZE
  };
  wire operation_valid_int = &{
    data_loaded_rd, |data_size_rd, data_size_rd <= MAX_DATA_SIZE,
    grid_loaded_rd, |grid_size_rd, grid_size_rd <= MAX_GRID_SIZE,
    scle_loaded_rd, |scle_size_rd, scle_size_rd <= MAX_SCLE_SIZE,
    wght_loaded_rd, |pckt_size_rd, pckt_size_rd <= MAX_PCKT_SIZE,
     |rslt_size_rd, |btch_size_rd, btch_size_rd <= BATCH_SIZE
  };
  assign operation_status_valid_wr = operation_valid;

  // Check if operation is error
  reg  interrupt_soft_reg, interrupt_soft_reg_early, interrupt_error_reg;
  wire internal_error = |peripheral_operation_error_sampled;
  wire external_error = interrupt_error || interrupt_abort || interrupt_soft_reg;

  // Check if core is locked
  reg  locked_next_error, locked_next_rslt_done;
  wire locked_next = locked_next_error || locked_next_rslt_done;

  assign operation_status_locked_wr = locked_next;

  // Check results exported -- Contain information about the next iteration
  reg  [31:0] results_left_reg;
  reg  [31:0] results_exported_reg;

  wire [31:0] results_iter_size         = (results_left_reg > RSLT_CHANNELS) ? RSLT_CHANNELS : results_left_reg;
  wire [31:0] results_left_reg_next     = results_left_reg - results_iter_size;
  wire [31:0] results_exported_reg_next = results_exported_reg + results_iter_size;

  wire [RSLT_CHANNELS-1:0] use_channels_next;
  wire [BATCH_SIZE-1:0]    use_batch_next;

  generate
    genvar CHN;
    for (CHN=0; CHN<RSLT_CHANNELS; CHN=CHN+1) begin : use_channels_genblock
      assign use_channels_next[CHN] = CHN < results_iter_size;
    end
    genvar BATCH;
    for (BATCH=0; BATCH<BATCH_SIZE; BATCH=BATCH+1) begin : use_batch_genblock
      assign use_batch_next[BATCH] = BATCH < btch_size_rd;
    end
  endgenerate

  assign operation_progress_rslt_wr = results_exported_reg;

  // Check iteration
  reg  [31:0] iteration_reg;
  wire [31:0] iteration_reg_next = iteration_reg + 1;

  assign operation_progress_iter_wr = iteration_reg;

  // Check if last iteration
  wire last_iteration = (results_left_reg == 0);

  // Check if all components are in error state
  reg  internal_error_asserted;

  // Global FSM state logic
  always @(posedge fsm_clk ) begin
    if (fsm_rst) begin
      fsm_state <= FSM_ST0;

      operation_start <= 1'b0;
      data_size       <= {DATA_ADDR{1'b0}};
      grid_size       <= {GRID_ADDR{1'b0}};
      scle_size       <= {SCALE_ADDR{1'b0}};
      pckt_size       <= {PCKT_SIZE_WIDTH{1'b0}};

      iteration_start <= 1'b0;
      use_channels    <= {RSLT_CHANNELS{1'b0}};
      use_batch       <= {BATCH_SIZE{1'b0}};

      operation_start       <= 1'b0;
      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

      results_left_reg      <= {32{1'b0}};
      results_exported_reg  <= {32{1'b0}};

      locked      <= 1'b0;
      pl2ps_intr  <= 1'b0;

      interrupt_soft_reg        <= 1'b0;
      interrupt_soft_reg_early  <= 1'b0;
      internal_operation_error  <= 1'b0;

      internal_error_asserted   <= 1'b0;

    end else begin
      fsm_state <= fsm_state_next;

      operation_start <= 1'b0;

      iteration_start <= 1'b0;

      results_left_reg      <= results_left_reg;
      results_exported_reg  <= results_exported_reg;

      iteration_reg         <= iteration_reg;

      operation_start       <= 1'b0;
      operation_busy        <= 1'b0;
      operation_complete    <= 1'b0;
      operation_error       <= 1'b0;

      locked      <= locked_next;
      pl2ps_intr  <= 1'b0;

      // Soft Interrupts -- Capture soft interrupts, activate at the end of an iteration
      interrupt_soft_reg        <= interrupt_soft_reg;
      interrupt_soft_reg_early  <= interrupt_soft_reg_early || interrupt_soft;
      internal_operation_error  <= 1'b0;

      case (fsm_state_next)
        FSM_ST0: begin
          results_left_reg      <= {32{1'b0}};
          results_exported_reg  <= {32{1'b0}};

          interrupt_soft_reg        <= 1'b0;
          interrupt_soft_reg_early  <= 1'b0;

          internal_error_asserted   <= 1'b0;
        end
        FSM_STR: begin
          data_size       <= data_size_rd[DATA_ADDR :0];
          grid_size       <= grid_size_rd[GRID_ADDR :0];
          scle_size       <= scle_size_rd[SCALE_ADDR:0];
          pckt_size       <= pckt_size_rd[PCKT_SIZE_WIDTH :0];

          use_channels    <= use_channels_next;
          use_batch       <= use_batch_next;

          results_left_reg      <= rslt_size_rd;
          results_exported_reg  <= {32{1'b0}};

          iteration_reg         <= {32{1'b0}};

          operation_busy  <= 1'b1;

          pl2ps_intr  <= 1'b1;
        end
        FSM_OPE: begin
          if (fsm_state == FSM_STR)
            operation_start <= 1'b1;

          operation_busy  <= 1'b1;

          iteration_start <= 1'b1;
          use_channels    <= use_channels_next;
          use_batch       <= use_batch_next;

          if (rslt_tlast_sampled || fsm_state == FSM_STR) begin
            results_left_reg      <= results_left_reg_next;
            results_exported_reg  <= results_exported_reg_next;
          end
          if (rslt_tlast_sampled) begin
            iteration_reg             <= iteration_reg_next;
            interrupt_soft_reg        <= interrupt_soft_reg_early || interrupt_soft;
            interrupt_soft_reg_early  <= 1'b0;

            operation_start <= ~(interrupt_soft_reg_early || interrupt_soft);
            pl2ps_intr  <= 1'b1;
          end
        end
        FSM_END: begin
          operation_complete <= 1'b1;
          pl2ps_intr  <= 1'b1;
        end
        FSM_ERR: begin
          internal_operation_error  <= ~(internal_error_asserted || core_rst);
          operation_error           <= 1'b1;
          interrupt_soft_reg        <= interrupt_soft_reg_early || interrupt_soft;
          pl2ps_intr                <= 1'b1;
          internal_error_asserted   <= internal_error_asserted || core_rst;
        end
        FSM_ITR: begin
          internal_operation_error  <= ~(internal_error_asserted || core_rst);
          operation_error           <= interrupt_error_reg;
          interrupt_soft_reg        <= 1'b0;
          interrupt_soft_reg_early  <= 1'b0;

          internal_error_asserted   <= internal_error_asserted || core_rst;
        end
        default: begin
        end 
      endcase
    end
  end

  // Global FSM next state logic
  always @(*) begin
    fsm_state_next        <= FSM_ST0;
    locked_next_error     <= 1'b0;
    locked_next_rslt_done <= 1'b0;
    rw_op_str_reg_en      <= 1'b0;
    rw_op_dne_reg_en      <= 1'b0;
    interrupt_error_reg   <= 1'b0;

    case (fsm_state)
      FSM_ST0: begin
        if (operation_start_rd) begin 
          if (operation_valid) begin 
            fsm_state_next      <= FSM_STR; 
          end else begin 
            fsm_state_next      <= FSM_ERR; 
            locked_next_error   <= 1'b1;
          end
        end else begin 
          fsm_state_next <= FSM_ST0; 
        end 
      end
      FSM_STR: begin
        fsm_state_next <= FSM_OPE;
        rw_op_str_reg_en <= 1'b1;
      end
      FSM_OPE: begin
        fsm_state_next <= FSM_OPE;
        if (last_iteration && rslt_tlast_sampled) begin
          fsm_state_next <= FSM_END;
          rw_op_dne_reg_en <= 1'b1;
        end
      end
      FSM_END: begin
        // Lock core until RSLT_LOADED is acknowledged (nulled) from PS
        if (operation_done_rd) begin
          fsm_state_next        <= FSM_END;
          locked_next_rslt_done <= 1'b1;
        end
      end
      FSM_ERR: begin
        // Lock core until external error occures
        locked_next_error <= 1'b1;
        rw_op_str_reg_en  <= 1'b1;
        fsm_state_next    <= FSM_ERR;
      end
      default: begin
      end 
    endcase
    if (internal_error) begin
      fsm_state_next        <= FSM_ERR;
      locked_next_error     <= 1'b1;
    end
    if (external_error) begin
      fsm_state_next        <= FSM_ITR;
      locked_next_error     <= 1'b0;
      locked_next_rslt_done <= 1'b0;
      interrupt_error_reg   <= interrupt_error;
      rw_op_dne_reg_en      <= interrupt_error;
    end
    if (fsm_rst) begin
      fsm_state_next <= FSM_ST0;
    end
  end

endmodule

`resetall
