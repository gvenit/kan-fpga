#ifndef _KAN_DMA_H_
#define _KAN_DMA_H_

#include "xaxidma.h"
#include "xscugic.h"

#include "kan_defines.h"
#include "kan_interrupts.h"

extern struct XAxiDma;

/*
 * Flags interrupt handlers use to notify the application context the events.
 * They are updated by the attached callback functions.
 */

volatile int dma_tx_done_flag; // DMA transmit complete
volatile int dma_rx_done_flag; // DMA receive complete
volatile int dma_error_flag;   // error in DMA transaction

/**
 * @brief Initialize the AXI DMA Engine with interrupts.
 * Initializes the dma handler and then attaches interrupts
 * with callbacks that affect the
 * globally available flag variables of this header,
 * all handled internally.
 *
 * @param dma_handler a pointer to the dma handler
 * @param dma_id is the dma device ID. Usually found in the `kan_defines.h
 * header like `DMA_DEV_ID`
 * @param intr_handler is a pointer to the interrupt controller device handler
 * already initialized and configured by the functions provided by
 * `kan_interrupts.h`, also uses in this header file
 *
 * @return DMA status
 */
int kan_dma_init_irq(XAxiDma *dma_handler, uint16_t dma_id, XScuGic *intr_handler);

#endif