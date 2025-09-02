#ifndef _KAN_DMA_H_
#define _KAN_DMA_H_

#include <stdint.h>

#include "kan_defines.h"
#include "kan_interrupts.h"

#include "xaxidma.h"
#include "xscugic.h"

#include "xil_printf.h"

typedef XAxiDma kan_dma_handler_t;

/*
 * Flags interrupt handlers use to notify the application context the events.
 * They are updated by the attached callback functions.
 */

extern volatile int dma_tx_done_flag; // DMA transmit complete
extern volatile int dma_rx_done_flag; // DMA receive complete
extern volatile int dma_error_flag;   // error in DMA transaction

/**
 * @brief Initialize the AXI DMA Engine
 * by initializing the dma handler.
 *
 * @param dma_handler a pointer to the dma handler
 * @param dma_id is the dma device ID. Usually found in the `kan_defines.h
 * header like `DMA_DEV_ID`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_dma_init(kan_dma_handler_t *dma_handler, uint16_t dma_id);

//////////////////////////////////////////////////////////////////////////////////////
kan_status_t kan_dma_reset(kan_dma_handler_t *dma_handler);
//////////////////////////////////////////////////////////////////////////////////////

/**
 * @brief Attaches interrupts
 * with DMA-specific callbacks that affect the
 * globally available flag variables of this header,
 * all handled internally.
 *
 * @param dma_handler a pointer to the dma handler
 * @param intr_handler is a pointer to the interrupt controller device handler
 * already initialized and configured by the functions provided by
 * `kan_interrupts.h`, also uses in this header file
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_dma_attach_irq(kan_dma_handler_t *dma_handler, kan_intr_handler_t *intr_handler);

/**
 * @brief Disables the interrupts attached to the DMA engie
 *
 * @param intr_handler is a pointer to the interrupt controller device handler
 * already initialized and configured by the functions provided by
 * `kan_interrupts.h`, which was used in the call of `kan_dma_init_irq`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_dma_detach_irq(kan_intr_handler_t *intr_handler);

/**
 * @brief Begin a dma transmission from the PL to the PS.
 * Non-blocking call. It initiates the transfer and returns
 * without waiting to end.
 * It uses the transfer function and macros from the `xaxidma.h`
 * xilinx vitis header.
 *
 * @warning this targets the current architecture in which the dma
 * is only used for sending weight values to the PL.
 * Therefore the data type is `weight_t`
 *
 * @param dma_handler pointer to the dma handler struct that
 * must have been initialized by a call to `kan_dma_init_irq`
 * @param tx_buff the transmit buffer that contains the packets to be trasmitted
 * @param size the size in bytes of the packets to be transmittede
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_dma_tx(kan_dma_handler_t *dma_handler, volatile weight_t *tx_buff, size_t size);

/**
 * @brief Begin a dma transmission from the PS to the PL.
 * Non-blocking call. It initiates the transfer and returns
 * without waiting to end.
 * It uses the transfer function and macros from the `xaxidma.h`
 * xilinx vitis header.
 *
 * @param dma_handler pointer to the dma handler struct that
 * must have been initialized by a call to `kan_dma_init_irq`
 * @param rx_buff the receive buffer that will store the packets coming from the PL
 * @param size the size in bytes of the packets to be transmitted
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_dma_rx(kan_dma_handler_t *dma_handler, volatile data_t *rx_buff, size_t size);

#endif
