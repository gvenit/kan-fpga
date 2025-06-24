#include "kan_dma.h"

volatile int dma_tx_done_flag = 0; // DMA transmit complete. If not complete it is zero
volatile int dma_rx_done_flag = 0; // DMA receive complete. If not complete it is zero
volatile int dma_error_flag = 0;   // error in DMA transaction. It is zero if no error

/**
 * This is the DMA TX Interrupt handler function.
 * In other words this is the callback of all the interrupts in DMA TX.
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then sets the dma_tx_done_flag flag
 *
 * @param dma_handler is a pointer to the initilized dma handler
 */
static void callback_dma_tx(void *dma_handler)
{
    uint32_t intr_mask; // variable to store all the DMA Transmit channel interrupts as a bitmask
    int timeout;

    kan_dma_handler_t *dma_handler_p = (kan_dma_handler_t *)dma_handler; // the arg is the DMA TX channel and need to be interpreted as such

    /**
     * Read pending interrupts
     */

    intr_mask = XAxiDma_IntrGetIrq(dma_handler_p, XAXIDMA_DMA_TO_DEVICE);

    /**
     * Acknowledge pending interrupts
     */

    XAxiDma_IntrAckIrq(dma_handler_p, intr_mask, XAXIDMA_DMA_TO_DEVICE);

    /**
     * If no interrupt is asserted, we do not do anything
     */

    if (!(intr_mask & XAXIDMA_IRQ_ALL_MASK))
        return;

    /**
     * If error interrupt is asserted:
     * - raise error flag
     * - reset the hardware to recover from the error
     * - return with no further processing
     */

    if ((intr_mask & XAXIDMA_IRQ_ERROR_MASK))
    {
        dma_error_flag = 1;

        // Reset should never fail for transmit channel
        XAxiDma_Reset(dma_handler_p);

        timeout = RESET_TIMEOUT_COUNTER;

        while (timeout)
        {
            if (XAxiDma_ResetIsDone(dma_handler_p))
                break;

            timeout -= 1;
        }

        return;
    }

    /**
     * If Completion interrupt is asserted:
     * - set the dma_tx_done_flag flag
     */

    if ((intr_mask & XAXIDMA_IRQ_IOC_MASK))
        dma_tx_done_flag = 1;
}

/**
 * This is the DMA RX interrupt handler function.
 * In other words this is the callback of all the interrupts in DMA RX.
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then it sets the dma_rx_done_flag flag.
 *
 * @param dma_handler is a pointer to the initilized dma handler
 */
static void callback_dma_rx(void *dma_handler)
{
    uint32_t intr_mask; // variable to store all the DMA Transmit channel interrupts as a bitmask
    int timeout;

    kan_dma_handler_t *dma_handler_p = (kan_dma_handler_t *)dma_handler; // the arg is the DMA TX channel and need to be interpreted as such

    /**
     * Read pending interrupts
     */

    intr_mask = XAxiDma_IntrGetIrq(dma_handler_p, XAXIDMA_DEVICE_TO_DMA);

    /**
     * Acknowledge pending interrupts
     */

    XAxiDma_IntrAckIrq(dma_handler_p, intr_mask, XAXIDMA_DEVICE_TO_DMA);

    /**
     * If no interrupt is asserted, we do not do anything
     */

    if (!(intr_mask & XAXIDMA_IRQ_ALL_MASK))
        return;

    /**
     * If error interrupt is asserted:
     * - raise error flag
     * - reset the hardware to recover from the error
     * - return with no further processing
     */

    if ((intr_mask & XAXIDMA_IRQ_ERROR_MASK))
    {
        dma_error_flag = 1;

        // Reset should never fail for transmit channel
        XAxiDma_Reset(dma_handler_p);

        timeout = RESET_TIMEOUT_COUNTER;

        while (timeout)
        {
            if (XAxiDma_ResetIsDone(dma_handler_p))
                break;

            timeout -= 1;
        }

        return;
    }

    /**
     * If Completion interrupt is asserted:
     * - set the dma_rx_done_flag flag
     */

    if ((intr_mask & XAXIDMA_IRQ_IOC_MASK))
        dma_tx_done_flag = 1;
}

kan_status_t kan_dma_init_irq(kan_dma_handler_t *dma_handler, uint16_t dma_id, XScuGic *intr_handler)
{
    kan_status_t status;

    if (dma_handler == NULL || intr_handler == NULL || (!(intr_handler->IsReady)))
        return STATUS_ILLEGAL_ARG;

    XAxiDma_Config *dma_config;

    /**
     * Find the correct config struct
     */

    dma_config = XAxiDma_LookupConfig(dma_id);
    if (dma_config == NULL)
        return STATUS_NULL_POINTER_REF;

    /**
     * Init the config struct along with the handler
     */

    status = XAxiDma_CfgInitialize(dma_handler, dma_config);
    if (status != STATUS_OK)
        return STATUS_DMA_INIT_FAILURE;

    /**
     * Make sure you have no scatter gather
     */

    if (XAxiDma_HasSg(dma_handler))
        return STATUS_DMA_INIT_FAILURE;

    /**
     * Set up Interrupt system
     *
     * @warning Must already be initialized!
     */

    status = kan_intr_attach(intr_handler, TX_INTR_ID, TX_INTR_PRIORITY, TX_INTR_TRIGGER_TYPE, (Xil_InterruptHandler)callback_dma_tx, (void *)dma_handler);
    if (status != STATUS_OK)
        return STATUS_INTR_ATTACH_FAILURE;

    status = kan_intr_attach(intr_handler, RX_INTR_ID, RX_INTR_PRIORITY, RX_INTR_TRIGGER_TYPE, (Xil_InterruptHandler)callback_dma_rx, (void *)dma_handler);
    if (status != STATUS_OK)
        return STATUS_INTR_ATTACH_FAILURE;

    /**
     * Disable and then enable all interrupts
     */

    XAxiDma_IntrDisable(dma_handler, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(dma_handler, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrEnable(dma_handler, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(dma_handler, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return STATUS_OK;
}

kan_status_t kan_dma_tx(kan_dma_handler_t *dma_handler, volatile data_t *tx_buff, size_t size)
{
    if (dma_handler == NULL || tx_buff == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status = STATUS_FAILURE;

    status = XAxiDma_SimpleTransfer(dma_handler, (UINTPTR)tx_buff, size, XAXIDMA_DEVICE_TO_DMA);

    if (status != STATUS_OK)
        return STATUS_DMA_TX_FAILURE;

    return STATUS_OK;
}

kan_status_t kan_dma_rx(kan_dma_handler_t *dma_handler, volatile data_t *rx_buff, size_t size)
{
    if (dma_handler == NULL || rx_buff == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status = STATUS_FAILURE;

    status = XAxiDma_SimpleTransfer(dma_handler, (UINTPTR)rx_buff, size, XAXIDMA_DMA_TO_DEVICE);

    if (status != STATUS_OK)
        return STATUS_DMA_TX_FAILURE;

    return STATUS_OK;
}
