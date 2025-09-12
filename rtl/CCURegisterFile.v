`resetall
`timescale 1ns/1ps
`default_nettype none

/* 
 * CCURegisterFile : Register File for the CentralControlUnit.
 * 
 */

module CCURegisterFile #(
  `include "header_ControlRegisters.vh"
  parameter ADDR_WIDTH = CTLR_ADDR,
  parameter PIPELINE_OUTPUT = 0
) (
  input  wire                   clk,
  input  wire                   rst,

  // Input PL control signals
  input  wire                   rw_op_str_reg_en,
  input  wire                   rw_op_dne_reg_en,
  input  wire                   wo_reg_en, // tlast_transmitted
  input  wire                   wo_reg_rst, // fsm_state == FSM_STR

  // Read-Write Registers (PS -> PL) 
  output wire [31:0]            data_size_rd,
  output wire [31:0]            grid_size_rd,
  output wire [31:0]            scle_size_rd,
  output wire [31:0]            rslt_size_rd,
  output wire [31:0]            pckt_size_rd,
  output wire [ 7:0]            btch_size_rd,

  input  wire [31:0]            data_size_wr,
  input  wire [31:0]            grid_size_wr,
  input  wire [31:0]            scle_size_wr,
  input  wire [31:0]            rslt_size_wr,
  input  wire [31:0]            pckt_size_wr,
  input  wire [ 7:0]            btch_size_wr,

  output wire                   data_loaded_rd,
  output wire                   grid_loaded_rd,
  output wire                   scle_loaded_rd,
  output wire                   wght_loaded_rd,

  input  wire                   data_loaded_wr,
  input  wire                   grid_loaded_wr,
  input  wire                   scle_loaded_wr,
  input  wire                   wght_loaded_wr,

  output wire                   operation_start_rd,
  input  wire                   operation_start_wr,

  // Read-Only Registers (PS -> PL)
  output wire                   interrupt_soft,
  output wire                   interrupt_abort,
  output wire                   interrupt_error,

  // Read-Write Registers (PL -> PS)
  output wire                   operation_done_rd,
  input  wire                   operation_done_wr,
  
  // Write-Only Registers (PL -> PS)
  input  wire                   operation_status_idle_wr,
  input  wire                   operation_status_busy_wr,
  input  wire                   operation_status_error_wr,
  input  wire                   operation_status_locked_wr,
  input  wire                   operation_status_valid_wr,
  input  wire                   operation_status_reset_wr,
  input  wire                   operation_status_error_aps_wr,
  // input  wire                   operation_status_error_mcu_wr,
  input  wire                   operation_status_error_dpu_wr,

  input  wire [31:0]            operation_progress_rslt_wr,
  input  wire [31:0]            operation_progress_iter_wr,
  input  wire [31:0]            iteration_timer_wr,
  input  wire [31:0]            iteration_latency_wr,
  input  wire [31:0]            operation_timer_wr,
  input  wire [31:0]            operation_latency_wr,

  /*
   * AXI-Lite Control
   */
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWADDR" *)
  (* X_INTERFACE_PARAMETER = "READ_WRITE_MODE READ_WRITE,ADDR_WIDTH CTLR_ADDR,PROTOCOL AXI4LITE,DATA_WIDTH 32" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWPROT" *)
  input  wire [2:0]             s_axil_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWVALID" *)
  input  wire                   s_axil_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil AWREADY" *)
  output wire                   s_axil_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WDATA" *)
  input  wire [31:0]            s_axil_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WSTRB" *)
  input  wire [3:0]             s_axil_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WVALID" *)
  input  wire                   s_axil_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil WREADY" *)
  output wire                   s_axil_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BRESP" *)
  output wire [1:0]             s_axil_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BVALID" *)
  output wire                   s_axil_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil BREADY" *)
  input  wire                   s_axil_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARADDR" *)
  input  wire [CTLR_ADDR-1:0]   s_axil_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARPROT" *)
  input  wire [2:0]             s_axil_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARVALID" *)
  input  wire                   s_axil_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil ARREADY" *)
  output wire                   s_axil_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RDATA" *)
  output wire [31:0]            s_axil_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RRESP" *)
  output wire [1:0]             s_axil_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RVALID" *)
  output wire                   s_axil_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axil RREADY" *)
  input  wire                   s_axil_rready
);
  // AXI-Lite Control interface -- modified version of https://github.com/alexforencich/verilog-axi/blob/master/rtl/axil_ram.v
  /*
    Copyright (c) 2018 Alex Forencich

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
  */
  localparam DATA_WIDTH = 32;
  localparam STRB_WIDTH = (DATA_WIDTH/8);
  localparam VALID_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
  localparam WORD_WIDTH = STRB_WIDTH;
  localparam WORD_SIZE  = DATA_WIDTH/WORD_WIDTH;

  reg mem_wr_en;
  reg mem_rd_en;

  reg s_axil_awready_reg = 1'b0, s_axil_awready_next;
  reg s_axil_wready_reg = 1'b0, s_axil_wready_next;
  reg s_axil_bvalid_reg = 1'b0, s_axil_bvalid_next;
  reg s_axil_arready_reg = 1'b0, s_axil_arready_next;
  reg [DATA_WIDTH-1:0] s_axil_rdata_reg = {DATA_WIDTH{1'b0}}, s_axil_rdata_next;
  reg s_axil_rvalid_reg = 1'b0, s_axil_rvalid_next;
  reg [DATA_WIDTH-1:0] s_axil_rdata_pipe_reg = {DATA_WIDTH{1'b0}};
  reg s_axil_rvalid_pipe_reg = 1'b0;

  // (* RAM_STYLE="BLOCK" *)
  reg [DATA_WIDTH-1:0] mem[(2**VALID_ADDR_WIDTH)-1:0];

  wire [VALID_ADDR_WIDTH-1:0] s_axil_awaddr_valid = s_axil_awaddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);
  wire [VALID_ADDR_WIDTH-1:0] s_axil_araddr_valid = s_axil_araddr >> (ADDR_WIDTH - VALID_ADDR_WIDTH);

  assign s_axil_awready = s_axil_awready_reg;
  assign s_axil_wready = s_axil_wready_reg;
  assign s_axil_bresp = 2'b00;
  assign s_axil_bvalid = s_axil_bvalid_reg;
  assign s_axil_arready = s_axil_arready_reg;
  assign s_axil_rdata = PIPELINE_OUTPUT ? s_axil_rdata_pipe_reg : s_axil_rdata_reg;
  assign s_axil_rresp = 2'b00;
  assign s_axil_rvalid = PIPELINE_OUTPUT ? s_axil_rvalid_pipe_reg : s_axil_rvalid_reg;

  integer i, j;

  initial begin
    // two nested loops for smaller number of iterations per loop
    // workaround for synthesizer complaints about large loop counts
    for (i = 0; i < 2**VALID_ADDR_WIDTH; i = i + 2**(VALID_ADDR_WIDTH/2)) begin
      for (j = i; j < i + 2**(VALID_ADDR_WIDTH/2); j = j + 1) begin
        mem[j] = 0;
      end
    end
  end

  // Write-Protection Macro
  `define PL_WRITE_MEM(mem,REG,value,VALUE_WIDTH) \
    if (s_axil_awaddr_valid != (REG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)) || ~(mem_wr_en && s_axil_wstrb[REG % WORD_WIDTH])) begin \
      mem[REG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(REG % WORD_WIDTH) * WORD_SIZE +: VALUE_WIDTH] = value; \
    end

  // Read-Write Registers (PS -> PL) 
  assign data_size_rd   = mem[CTRL_REG_DATA_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)];
  assign grid_size_rd   = mem[CTRL_REG_GRID_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)];
  assign scle_size_rd   = mem[CTRL_REG_SCLE_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)];
  assign rslt_size_rd   = mem[CTRL_REG_RSLT_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)];
  assign pckt_size_rd   = mem[CTRL_REG_PCKT_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)];
  assign btch_size_rd   = mem[CTRL_REG_BTCH_LEN >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_BTCH_LEN % WORD_WIDTH) * WORD_SIZE +: WORD_SIZE];

  assign data_loaded_rd = mem[CTRL_REG_DATA_LDR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_DATA_LDR % WORD_WIDTH) * WORD_SIZE];
  assign grid_loaded_rd = mem[CTRL_REG_GRID_LDR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_GRID_LDR % WORD_WIDTH) * WORD_SIZE];
  assign scle_loaded_rd = mem[CTRL_REG_SCLE_LDR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_SCLE_LDR % WORD_WIDTH) * WORD_SIZE];
  assign wght_loaded_rd = mem[CTRL_REG_WGHT_LDR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_WGHT_LDR % WORD_WIDTH) * WORD_SIZE];

  assign operation_start_rd = mem[CTRL_REG_OPER_STR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_OPER_STR % WORD_WIDTH) * WORD_SIZE];

  // Read-Only Registers (PS -> PL)
  wire [WORD_SIZE-1:0]  interrupt_register = mem[CTRL_REG_INTR_REG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_INTR_REG % WORD_WIDTH) * WORD_SIZE +: WORD_SIZE];
  
  assign interrupt_soft  = |(interrupt_register & CTRL_REG_INTR_MASK_SFT);
  assign interrupt_abort = |(interrupt_register & CTRL_REG_INTR_MASK_ABT);
  assign interrupt_error = |(interrupt_register & CTRL_REG_INTR_MASK_ERR);

  // Read-Write Registers (PL -> PS)
  assign operation_done_rd = mem[CTRL_REG_OPER_DNE >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_OPER_DNE % WORD_WIDTH) * WORD_SIZE];

  // Write-Only Registers (PL -> PS)
  wire [WORD_SIZE-1:0]  operation_status_wr;

  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_IDL)] = operation_status_idle_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_BSY)] = operation_status_busy_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_ERR)] = operation_status_error_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_LCK)] = operation_status_locked_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_VLD)] = operation_status_valid_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_RST)] = operation_status_reset_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_ERR_MCU)] = operation_status_error_aps_wr;
  // assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_ERR_MCU)] = operation_status_error_mcu_wr;
  assign operation_status_wr[`RLOG2(CTRL_REG_OPER_STS_MASK_ERR_DPU)] = operation_status_error_dpu_wr;
  // assign operation_status_wr[WORD_SIZE-1:`RLOG2(CTRL_REG_OPER_STS_MASK_ERR_DPU)+1] = {WORD_SIZE-`RLOG2(CTRL_REG_OPER_STS_MASK_ERR_DPU){1'b0}};

  always @* begin
    mem_wr_en = 1'b0;

    s_axil_awready_next = 1'b0;
    s_axil_wready_next = 1'b0;
    s_axil_bvalid_next = s_axil_bvalid_reg && !s_axil_bready;

    if (s_axil_awvalid && s_axil_wvalid && (!s_axil_bvalid || s_axil_bready) && (!s_axil_awready && !s_axil_wready)) begin
      s_axil_awready_next = 1'b1;
      s_axil_wready_next = 1'b1;
      s_axil_bvalid_next = 1'b1;

      mem_wr_en = 1'b1;
    end
  end

  always @(posedge clk) begin
    if (rw_op_str_reg_en) begin 
      `PL_WRITE_MEM(mem,CTRL_REG_OPER_STR,operation_start_wr,1)
    end
    if (rw_op_dne_reg_en) begin 
      // Read-Write Registers (PS->PL)
      `PL_WRITE_MEM(mem,CTRL_REG_DATA_LEN,data_size_wr,DATA_WIDTH)
      `PL_WRITE_MEM(mem,CTRL_REG_GRID_LEN,grid_size_wr,DATA_WIDTH)
      `PL_WRITE_MEM(mem,CTRL_REG_SCLE_LEN,scle_size_wr,DATA_WIDTH)
      `PL_WRITE_MEM(mem,CTRL_REG_RSLT_LEN,rslt_size_wr,DATA_WIDTH)
      `PL_WRITE_MEM(mem,CTRL_REG_PCKT_LEN,pckt_size_wr,DATA_WIDTH)
      `PL_WRITE_MEM(mem,CTRL_REG_BTCH_LEN,btch_size_wr,WORD_SIZE)
      `PL_WRITE_MEM(mem,CTRL_REG_DATA_LDR,data_loaded_wr,1)
      `PL_WRITE_MEM(mem,CTRL_REG_GRID_LDR,grid_loaded_wr,1)
      `PL_WRITE_MEM(mem,CTRL_REG_SCLE_LDR,scle_loaded_wr,1)
      `PL_WRITE_MEM(mem,CTRL_REG_WGHT_LDR,wght_loaded_wr,1)
      // Read-Write Registers (PL->PS)
      `PL_WRITE_MEM(mem,CTRL_REG_OPER_DNE,operation_done_wr,1)
    end

    s_axil_awready_reg <= s_axil_awready_next;
    s_axil_wready_reg <= s_axil_wready_next;
    s_axil_bvalid_reg <= s_axil_bvalid_next;

    for (i = 0; i < WORD_WIDTH; i = i + 1) begin
      if (mem_wr_en && s_axil_wstrb[i]) begin
        mem[s_axil_awaddr_valid][WORD_SIZE*i +: WORD_SIZE] <= s_axil_wdata[WORD_SIZE*i +: WORD_SIZE];
      end
    end

    if (rst) begin
      s_axil_awready_reg <= 1'b0;
      s_axil_wready_reg <= 1'b0;
      s_axil_bvalid_reg <= 1'b0;
    end

    // Write Only Registers
    if (rst || wo_reg_rst) begin
      mem[CTRL_REG_RSLT_PRG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
      mem[CTRL_REG_ITER_PRG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
      mem[CTRL_REG_ITER_TMR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
      mem[CTRL_REG_ITER_LAT >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
      mem[CTRL_REG_OPER_TMR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
      mem[CTRL_REG_OPER_LAT >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = {DATA_WIDTH{1'b0}};
    end else if (wo_reg_en) begin
      mem[CTRL_REG_RSLT_PRG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = operation_progress_rslt_wr;
      mem[CTRL_REG_ITER_PRG >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = operation_progress_iter_wr;
      mem[CTRL_REG_ITER_TMR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = iteration_timer_wr;
      mem[CTRL_REG_ITER_LAT >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = iteration_latency_wr;
      mem[CTRL_REG_OPER_TMR >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = operation_timer_wr;
      mem[CTRL_REG_OPER_LAT >> (ADDR_WIDTH - VALID_ADDR_WIDTH)] = operation_latency_wr;
    end
    mem[CTRL_REG_OPER_STS >> (ADDR_WIDTH - VALID_ADDR_WIDTH)][(CTRL_REG_OPER_STS % WORD_WIDTH) * WORD_SIZE +: WORD_SIZE] = operation_status_wr;
  end

  always @* begin
    mem_rd_en = 1'b0;

    s_axil_arready_next = 1'b0;
    s_axil_rvalid_next = s_axil_rvalid_reg && !(s_axil_rready || (PIPELINE_OUTPUT && !s_axil_rvalid_pipe_reg));

    if (s_axil_arvalid && (!s_axil_rvalid || s_axil_rready || (PIPELINE_OUTPUT && !s_axil_rvalid_pipe_reg)) && (!s_axil_arready)) begin
      s_axil_arready_next = 1'b1;
      s_axil_rvalid_next = 1'b1;

      mem_rd_en = 1'b1;
    end
  end

  always @(posedge clk) begin
    s_axil_arready_reg <= s_axil_arready_next;
    s_axil_rvalid_reg <= s_axil_rvalid_next;

    if (mem_rd_en) begin
      s_axil_rdata_reg <= mem[s_axil_araddr_valid];
    end

    if (!s_axil_rvalid_pipe_reg || s_axil_rready) begin
      s_axil_rdata_pipe_reg <= s_axil_rdata_reg;
      s_axil_rvalid_pipe_reg <= s_axil_rvalid_reg;
    end

    if (rst) begin
      s_axil_arready_reg <= 1'b0;
      s_axil_rvalid_reg <= 1'b0;
      s_axil_rvalid_pipe_reg <= 1'b0;
    end
  end

endmodule

`resetall
