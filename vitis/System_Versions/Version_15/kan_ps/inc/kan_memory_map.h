#ifndef _KAN_MEMORY_MAP_
#define _KAN_MEMORY_MAP_

#include "kan_defines.h"
#include "xparameters.h"

/*===========================================================================
    Control Registers address mapping and masks
============================================================================*/

#define APPERATUS_BASE_ADDRESS (XPAR_KANACCELERATOR_BASEADDR - 0x200000)

/**
 * @brief Axi-Lite Control Register File base address.
 * This is used as base address and later in this section
 * offsets are specified.
 *
 * The naming convention is that
 * control register gets `KAN_REG` in the macro beggining
 * and for the offsets that is `KAN_REG_OFST`
 * while in the end the number of bytes are specified.
 * For the masks the macro begins with `KAN_REG_MASK`
 * and usually the same name as the control register it reads
 * while there is again the number of bytes in the end.
 *
 * @warning
 * You have to find it from Hardware Platform Specification GUI
 * in Vitis, or in address editor in Vivado
 */
#define KAN_REG_BASE_ADDRESS XPAR_KANACCELERATOR_BASEADDR

/**
 * @brief Control Data Transfer/Operation Status signals.
 * Nulled from PS at the end of the transaction.
 *
 * @property READ-WRITE
 */

#define KAN_REG_OPER_DNE_1B 52 // operation done. 1B. locked core in idle state awaiting nulling or soft/hard reset

#define NUM_KAN_REGISTERS KAN_REG_OPER_DNE + 1 // Number of Control Registers

/**
 * @brief Configuration signals.
 * Nulled from PL at the end of the operation.
 * PS to PL
 *
 * @property READ-WRITE
 */

#define KAN_REG_OFST_DATA_LEN_4B 0  // Data length. 4B. Equals data_len
#define KAN_REG_OFST_GRID_LEN_4B 4  // Grid length. 4B. Equals grid_len
#define KAN_REG_OFST_SCLE_LEN_4B 8  // Scale lengh. 4B. Equals scle_len
#define KAN_REG_OFST_RSLT_LEN_4B 12 // Result length. 4B. Equals rslt_len
#define KAN_REG_OFST_PCKT_LEN_4B 16 // Packet length. 4B. Equals data_len * grid_len
#define KAN_REG_OFST_BTCH_LEN_1B 20 // Batch length. 1B

/**
 * @brief Control Data Transfer signals.
 * Nulled from PL at the end of the operation
 * PS to PL
 *
 * @property READ-WRITE
 */

#define KAN_REG_OFST_DATA_LDR_1B 21 // Data loaded. 1B
#define KAN_REG_OFST_GRID_LDR_1B 22 // Grid loaded. 1B
#define KAN_REG_OFST_SCLE_LDR_1B 23 // Scale loaded. 1B
#define KAN_REG_OFST_WGHT_LDR_1B 24 // Weights loaded. 1B

/**
 * @brief Control Operation signals.
 * Nulled from PL at the start of the operation
 *
 * @property READ-WRITE
 */

#define KAN_REG_OFST_OPER_STR_1B 25 // Operation start. 1B

/**
 * @brief Interrupt signals.
 * Register offset and register values.
 * Updated from PS when the status changes.
 *
 * @property WRITE-ONLY
 */

#define KAN_REG_OFST_INTR_1B 26 // Interrupt register. 1B

#define KAN_REG_MASK_INTR_SFT_1B 0x01 // Soft interrupt / reset
#define KAN_REG_MASK_INTR_ABT_1B 0x02 // Abort start
#define KAN_REG_MASK_INTR_ERR_1B 0x04 // External error

/**
 * @brief Control Operation Status signals.
 * Updated from PL when the status changes.
 * For the operation status register the masks are laid out too.
 * PL to PS
 *
 * @warning These registers trigger the PL interrupt
 *
 * @property READ-ONLY
 */

#define KAN_REG_OFST_OPER_STS_1B 27 // Operation status. 1B
#define KAN_REG_OFST_RSLT_PRG_4B 28 // Operation progress (results produced). 4B
#define KAN_REG_OFST_ITER_PRG_4B 32 // Operation progress (iterations complete). 4B
#define KAN_REG_OFST_ITER_TMR_4B 36 // Iteration timer. 4B
#define KAN_REG_OFST_ITER_LAT_4B 40 // Iteration latency. 4B
#define KAN_REG_OFST_OPER_TMR_4B 44 // Operation timer. 4B
#define KAN_REG_OFST_OPER_LAT_4B 48 // Iteration latency. 4B

#define KAN_REG_MASK_OPER_STS_IDL 0x01     // Operation idle
#define KAN_REG_MASK_OPER_STS_BSY 0x02     // Operation busy
#define KAN_REG_MASK_OPER_STS_ERR 0x04     // Operation error. locked core awaiting soft/hard reset
#define KAN_REG_MASK_OPER_STS_LCK 0x08     // Locked core. Nulled from PL when the awaited action is complete
#define KAN_REG_MASK_OPER_STS_VLD 0x10     // Valid configuration
#define KAN_REG_MASK_OPER_STS_RST 0x20     // Core reset
#define KAN_REG_MASK_OPER_STS_MCU_ERR 0x24 // MCU Error
#define KAN_REG_MASK_OPER_STS_DPU_ERR 0x28 // DPU Error

/*===========================================================================
    Data, Scale and Grid Memory Regions
============================================================================*/

/**
 * Data BRAM parameters
 *
 * @warning
 * If they are DATA_AXIL you have to find
 * its value from Hardware Platform Specification GUI
 * in Vitis, or in address editor in Vivado
 */

#define DATA_AXIL_BRAM_BASE_ADDR (APPERATUS_BASE_ADDRESS + 0x0)
#define DATA_BRAM_BASE_ADDR DATA_AXIL_BRAM_BASE_ADDR

/**
 * Grid BRAM parameters
 */

#define GRID_AXIL_BRAM_BASE_ADDR (DATA_AXIL_BRAM_BASE_ADDR + 0x8000)
#define GRID_BRAM_BASE_ADDR GRID_AXIL_BRAM_BASE_ADDR

/**
 * Scale BRAM parameters
 */

#define SCALE_AXIL_BRAM_BASE_ADDR (GRID_AXIL_BRAM_BASE_ADDR + 0x400)
#define SCALE_BRAM_BASE_ADDR SCALE_AXIL_BRAM_BASE_ADDR

#endif