#ifndef _KAN_BUILD_DEFINES_H_
#define _KAN_BUILD_DEFINES_H_

#include "xparameters.h"

#include "kan_build_params.h"

/*===========================================================================
    USED DATATYPE AND SIZE DEFINITIONS
============================================================================*/

#define DATUM_SIZE sizeof(data_t)                     // number if bytes for each datum
#define DATA_PER_WORD (sizeof(uint32_t) / DATUM_SIZE) // every word is 32 bits and this calculates how many bytes it fits
#define BYTE_OFFSET 0x04                              // offset of a 32-bit word in memory
#define HALD_WORD_OFFSET 0x02                         // offset of a 16-bit word in memory
#define WORD_OFFSET 0x01                              // offset of a 8-bit word in memory

/*===========================================================================
    FABRIC AND OTHER INTERRUPTS
============================================================================*/

#define INTR_CONTROLLER_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID // from Canonical definitions for SCU GIC. It is the ID of the Interrupt Controler (INTC)

/**
 * @note About the interrupt trigger types.
 * Each bit pair describes the configuration for an INT_ID.
 *
 * - SFI : Read Only with `b10` always
 *
 * - PPI : Read Only and depending on how the PPIs are configured.
 * `b01` is active HIGH level sensitive.
 * `b11` is rising edge sensitive.
 *
 * - SPI : LSB is read only.
 * `b01` is active HIGH level sensitive.
 * `b11` is rising edge sensitive.
 */
#define INTR_TRIGGER_RISING_EDGE 0x03

/**
 * @note About the interrupt priority levels.
 * There are 32 priority levels.
 * Highest to lowest: `0, 8, 16, 32, 40 ..., 248`
 */
#define INTR_DEFAULT_PRIORITY 0xA0

/*===========================================================================
    MEMORY DEFINITIONS
============================================================================*/

#ifdef DEF_DATA_BRAM
#define DATA_BRAM
#else
#define DATA_AXIL
#endif

#ifdef DEF_SCALE_IS_SHARED
#define SCALE_AXIL
#else
#define SCALE_BRAM
#endif

#ifdef DEF_GRID_IS_SHARED
#define GRID_AXIL
#else
#define GRID_BRAM
#endif

#if defined(DATA_BRAM) || defined(SCALE_BRAM) || defined(GRID_BRAM)
#define BRAM_INTRF
#endif

/**
 * xparameter.h xst automatic defines
 */

#ifdef DATA_BRAM
#define DATA_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define DATA_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#define DATA_BRAM_CONTROLLER_ID 0xFFFF
#else
#define DATA_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define DATA_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

#ifdef GRID_BRAM
#define GRID_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define GRID_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#define GRID_BRAM_CONTROLLER_ID 0xFFFF
#else
#define GRID_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define GRID_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

#ifdef SCALE_BRAM
#define SCALE_BRAM_CONTROLLER_BASE_ADDR 0xFFFFFFFF
#define SCALE_BRAM_CONTROLLER_HIGH_ADDR 0xFFFFFFFF
#define SCALE_BRAM_CONTROLLER_ID 0xFFFF
#else
#define SCALE_AXIL_BRAM_BASE_ADDR 0xFFFFFFFF
#define SCALE_AXIL_BRAM_HIGH_ADDR 0xFFFFFFFF
#endif

/**
 * Data BRAM parameters
 */

#ifdef DATA_BRAM
#define DATA_BRAM_BASE_ADDR DATA_BRAM_CONTROLLER_BASE_ADDR
#else
#define DATA_BRAM_BASE_ADDR DATA_AXIL_BRAM_BASE_ADDR
#endif

/**
 * Grid BRAM parameters
 */

#ifdef GRID_BRAM
#define GRID_BRAM_BASE_ADDR GRID_BRAM_CONTROLLER_BASE_ADDR
#else
#define GRID_BRAM_BASE_ADDR GRID_AXIL_BRAM_BASE_ADDR
#endif

/**
 * Scale BRAM parameters
 */

#ifdef SCALE_BRAM
#define SCALE_BRAM_BASE_ADDR SCALE_BRAM_CONTROLLER_BASE_ADDR
#else
#define SCALE_BRAM_BASE_ADDR SCALE_AXIL_BRAM_BASE_ADDR
#endif

/*===========================================================================
    DMA DEFINITIONS AND PARAMETERS
============================================================================*/

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID // DMA device ID

#define RX_INTR_ID XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID // fabric IR connected to ps7_scugic_0
#define RX_INTR_PRIORITY INTR_DEFAULT_PRIORITY
#define RX_INTR_TRIGGER_TYPE INTR_TRIGGER_RISING_EDGE

#define TX_INTR_ID XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID // fabric IR connected to ps7_scugic_0
#define TX_INTR_PRIORITY INTR_DEFAULT_PRIORITY
#define TX_INTR_TRIGGER_TYPE INTR_TRIGGER_RISING_EDGE

#define RESET_TIMEOUT_COUNTER 10000 // Timeout loop counter for reset (measured in ms)
// #define NUMBER_OF_TRANSFERS 10

#endif