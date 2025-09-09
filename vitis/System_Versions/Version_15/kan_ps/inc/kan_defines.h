#ifndef SRC_KAN_DEFINES_H_
#define SRC_KAN_DEFINES_H_

#include <stdint.h>

#include "kan_build_params.h"
#include "xparameters.h"

/*===========================================================================
    Used datatype and size definitions
============================================================================*/

#define DATUM_SIZE sizeof(data_t)                     // number if bytes for each datum
#define DATA_PER_WORD (sizeof(uint32_t) / DATUM_SIZE) // every word is 32 bits and this calculates how many bytes it fits

/*===========================================================================
    Fabric and other interrupts
============================================================================*/

#define INTR_CONTROLLER_DEVICE_ID XPAR_SCUGIC_0_DEVICE_ID            // from Canonical definitions for SCU GIC. It is the ID of the Interrupt Controler (INTC)
#define INTR_PL_TOP_PS_ID XPAR_FABRIC_KANACCELERATOR_PL2PS_INTR_INTR // the ID of the PL to PS interrupt
// #define INTR_PL_TOP_PS_ID XPAR_FABRIC_KANACCELERATOR_PL2PS_INTR_INTR // the ID of the PL to PS interrupt

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
    DMA definitions and parameters
============================================================================*/

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID // DMA device ID

#define RX_INTR_ID XPAR_FABRIC_AXI_WEIGHT_DMA_S2MM_INTROUT_INTR
#define RX_INTR_PRIORITY INTR_DEFAULT_PRIORITY
#define RX_INTR_TRIGGER_TYPE INTR_TRIGGER_RISING_EDGE

#define TX_INTR_ID XPAR_FABRIC_AXI_WEIGHT_DMA_MM2S_INTROUT_INTR
#define TX_INTR_PRIORITY INTR_DEFAULT_PRIORITY
#define TX_INTR_TRIGGER_TYPE INTR_TRIGGER_RISING_EDGE

#define RESET_TIMEOUT_COUNTER 10000 // Timeout loop counter for reset (measured in ms)
// #define NUMBER_OF_TRANSFERS 10

#define DMA_MIN_ALIGNMENT 0x20 // minimum alignment of dma - found in `xaxidma_hw.h` as `XAXIDMA_MICROMODE_MIN_BUF_ALIGN`, or the debugger

#define DMA_ALIGNMENT DMA_MIN_ALIGNMENT // the dma page boundary since there is no scatter gather or Data Realignment Engine (DRE)

#endif
