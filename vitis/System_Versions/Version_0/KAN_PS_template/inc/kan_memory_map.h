#ifndef _KAN_MEMORY_MAP_
#define _KAN_MEMORY_MAP_

#include "kan_defines.h"

/*===========================================================================
    Control Registers address mapping and masks as enums
============================================================================*/

/**
 * Control Data Transfer/Operation Status signals.
 * Nulled from PS at the end of the transaction
 *
 * @property READ-WRITE
 */

// Control Register : operation done -- 1B -- locked core in idle state awaiting nulling or soft/hard reset
#define CTRL_REG_OPER_DNE 52

// Number of Control Registers
#define NUM_CTRL_REGISTERS CTRL_REG_OPER_DNE + 1

/**
 * PS to PL
 * Configuration signals.
 * Nulled from PL at the end of the operation.
 *
 * @property READ-WRITE
 */

// Control Register : data length -- 4B -- Equals data_len / data_banks
#define CTRL_REG_DATA_LEN 0
// Control Register : grid length -- 4B -- Equals grid_len / grid_banks
#define CTRL_REG_GRID_LEN 4
// Control Register : scale lengh -- 4B -- Equals scle_len / scale_banks
#define CTRL_REG_SCLE_LEN 8
// Control Register : result length -- 4B -- Equals rslt_len
#define CTRL_REG_RSLT_LEN 12
// Control Register : packet length -- 4B -- Equals (data_len / data_banks) * (grid_len / grid_banks)
#define CTRL_REG_PCKT_LEN 16
// Control Register : batch length -- 1B
#define CTRL_REG_BTCH_LEN 20

/**
 * Control Data Transfer signals.
 * Nulled from PL at the end of the operation
 *
 * @property READ-WRITE
 */

// Control Register : data loaded -- 1B
#define CTRL_REG_DATA_LDR 21
// Control Register : grid loaded -- 1B
#define CTRL_REG_GRID_LDR 22
// Control Register : scale loaded -- 1B
#define CTRL_REG_SCLE_LDR 23
// Control Register : weights loaded -- 1B
#define CTRL_REG_WGHT_LDR 24

// Control Operation signals -- Nulled from PL at the start of the operation -- READ-WRITE
// Control Register : operation start -- 1B
#define CTRL_REG_OPER_STR 25

// Interrupt signals  -- Updated from PS when the status changes -- WRITE-ONLY
// Control Register : interrupt register -- 1B
#define CTRL_REG_INTR_REG 26

/**
 * PL to PS
 * Control Operation Status signals.
 * Updated from PL when the status changes.
 *
 * @property READ-ONLY
 */

// Control Register : operation status -- 1B
#define CTRL_REG_OPER_STS 27
// Control Register : operation progress (results produced) -- 4B
#define CTRL_REG_RSLT_PRG 28
// Control Register : operation progress (iterations complete) -- 4B
#define CTRL_REG_ITER_PRG 32
// Control Register : iteration timer -- 4B
#define CTRL_REG_ITER_TMR 36
// Control Register : iteration latency -- 4B
#define CTRL_REG_ITER_LAT 40
// Control Register : operation timer -- 4B
#define CTRL_REG_OPER_TMR 44
// Control Register : iteration latency -- 4B
#define CTRL_REG_OPER_LAT 48

/**
 * Masks as enums
 */

// PS Interrupt Register Masks

// Control Register Mask: soft interrupt / reset
#define CTRL_REG_INTR_MASK_SFT 1
// Control Register Mask: abort start
#define CTRL_REG_INTR_MASK_ABT 2
// Control Register Mask: external error
#define CTRL_REG_INTR_MASK_ERR 4

// Control Operation Status Flag Masks

// Control Register Mask: operation idle
#define CTRL_REG_OPER_STS_MASK_IDL 1
// Control Register Mask: operation busy
#define CTRL_REG_OPER_STS_MASK_BSY 2
// Control Register Mask: operation error -- locked core awaiting soft/hard reset
#define CTRL_REG_OPER_STS_MASK_ERR 4
// Control Register Mask: locked core -- Nulled from PL when the awaited action is complete
#define CTRL_REG_OPER_STS_MASK_LCK 8
// Control Register Mask: valid configuration
#define CTRL_REG_OPER_STS_MASK_VLD 16
// Control Register Mask: core reset
#define CTRL_REG_OPER_STS_MASK_RST 32

/*===========================================================================
    Data, Scale and Grid Memory Regions
============================================================================*/

/**
 * Data BRAM parameters
 */

#ifdef DATA_BRAM
#define DATA_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define DATA_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#else
#define DATA_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define DATA_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

#ifdef DATA_BRAM
#define DATA_BRAM_BASE_ADDR DATA_BRAM_CONTROLLER_BASE_ADDR
#else
#define DATA_BRAM_BASE_ADDR DATA_AXIL_BRAM_BASE_ADDR
#endif

/**
 * Grid BRAM parameters
 */

#ifdef GRID_BRAM
#define GRID_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define GRID_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#else
#define GRID_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define GRID_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

#ifdef GRID_BRAM
#define GRID_BRAM_BASE_ADDR GRID_BRAM_CONTROLLER_BASE_ADDR
#else
#define GRID_BRAM_BASE_ADDR GRID_AXIL_BRAM_BASE_ADDR
#endif

/**
 * Scale BRAM parameters
 */

#ifdef SCALE_BRAM
#define SCALE_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define SCALE_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#else
#define SCALE_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define SCALE_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

#ifdef SCALE_BRAM
#define SCALE_BRAM_BASE_ADDR SCALE_BRAM_CONTROLLER_BASE_ADDR
#else
#define SCALE_BRAM_BASE_ADDR SCALE_AXIL_BRAM_BASE_ADDR
#endif
#endif
