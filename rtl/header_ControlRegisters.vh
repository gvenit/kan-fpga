/*
  This file contains the position of the registers shared between the PS and PL.
  In the comments, it is specified if each register is a read-only, write-only or
  a read-write register from the perspective of the PS.

  When a write collision occurs, the PL value is dropped and the PS value is
  preserved. 
*/
 `include "header_utils.vh"
  // PS to PL
  // Configuration signals -- Nulled from PL at the end of the operation -- READ-WRITE
  // Control Register : data length -- 4B -- Equals data_len / data_banks
  parameter CTRL_REG_DATA_LEN = 0,
  // Control Register : grid length -- 4B -- Equals grid_len / grid_banks
  parameter CTRL_REG_GRID_LEN = 4,
  // Control Register : scale lengh -- 4B -- Equals scle_len / scale_banks
  parameter CTRL_REG_SCLE_LEN = 8,
  // Control Register : result length -- 4B -- Equals rslt_len
  parameter CTRL_REG_RSLT_LEN = 12,
  // Control Register : packet length -- 4B -- Equals (data_len / data_banks) * (grid_len / grid_banks)
  parameter CTRL_REG_PCKT_LEN = 16,
  // Control Register : batch length -- 1B
  parameter CTRL_REG_BTCH_LEN = 20,

  // Control Data Transfer signals -- Nulled from PL at the end of the operation -- READ-WRITE
  // Control Register : data loaded -- 1B
  parameter CTRL_REG_DATA_LDR = 21,
  // Control Register : grid loaded -- 1B
  parameter CTRL_REG_GRID_LDR = 22,
  // Control Register : scale loaded -- 1B
  parameter CTRL_REG_SCLE_LDR = 23,
  // Control Register : weights loaded -- 1B
  parameter CTRL_REG_WGHT_LDR = 24,
  
  // Control Operation signals -- Nulled from PL at the start of the operation -- READ-WRITE
  // Control Register : operation start -- 1B
  parameter CTRL_REG_OPER_STR = 25,

  // Interrupt signals  -- Updated from PS when the status changes -- WRITE-ONLY
  // Control Register : interrupt register -- 1B
  parameter CTRL_REG_INTR_REG = 26,

  // PL to PS
  // Control Operation Status signals -- Updated from PL when the status changes-- READ-ONLY
  // Control Register : operation status -- 1B
  parameter CTRL_REG_OPER_STS = 27,
  // Control Register : operation progress (results produced) -- 4B
  parameter CTRL_REG_RSLT_PRG = 28,
  // Control Register : operation progress (iterations complete) -- 4B
  parameter CTRL_REG_ITER_PRG = 32,
  // Control Register : iteration timer -- 4B
  parameter CTRL_REG_ITER_TMR = 36,
  // Control Register : iteration latency -- 4B
  parameter CTRL_REG_ITER_LAT = 40,
  // Control Register : operation timer -- 4B
  parameter CTRL_REG_OPER_TMR = 44,
  // Control Register : iteration latency -- 4B
  parameter CTRL_REG_OPER_LAT = 48,

  // Control Data Transfer/Operation Status signals -- Nulled from PS at the end of the transaction -- READ-WRITE
  // Control Register : operation done -- 1B -- locked core in idle state awaiting nulling or soft/hard reset
  parameter CTRL_REG_OPER_DNE = 52,

  // Number of Control Registers
  parameter NUM_CTRL_REGISTERS = CTRL_REG_OPER_DNE + 1,
  // Address Width of Control Register RAM
  parameter CTLR_ADDR = `LOG2( NUM_CTRL_REGISTERS ),

  // Masks

  // PS Interrupt Register Masks
  // Control Register Mask: soft interrupt / reset
  parameter CTRL_REG_INTR_MASK_SFT = 1,
  // Control Register Mask: abort start
  parameter CTRL_REG_INTR_MASK_ABT = 2,
  // Control Register Mask: external error
  parameter CTRL_REG_INTR_MASK_ERR = 4,

  // Control Operation Status Flag Masks
  // Control Register Mask: operation idle
  parameter CTRL_REG_OPER_STS_MASK_IDL = 1,
  // Control Register Mask: operation busy
  parameter CTRL_REG_OPER_STS_MASK_BSY = 2,
  // Control Register Mask: operation error -- locked core awaiting soft/hard reset
  parameter CTRL_REG_OPER_STS_MASK_ERR = 4,
  // Control Register Mask: locked core -- Nulled from PL when the awaited action is complete
  parameter CTRL_REG_OPER_STS_MASK_LCK = 8,
  // Control Register Mask: valid configuration
  parameter CTRL_REG_OPER_STS_MASK_VLD = 16,