#include "kan_dma.h"

volatile int dma_tx_done_flag; // DMA transmit complete
volatile int dma_rx_done_flag; // DMA receive complete
volatile int dma_error_flag;   // error in DMA transaction

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

    XAxiDma *dma_handler_p = (XAxiDma *)dma_handler; // the arg is the DMA TX channel and need to be interpreted as such

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

    XAxiDma *dma_handler_p = (XAxiDma *)dma_handler; // the arg is the DMA TX channel and need to be interpreted as such

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

kan_status_t kan_dma_init_irq(XAxiDma *dma_handler, uint16_t dma_id, XScuGic *intr_handler)
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

kan_status_t kan_dma_tx(XAxiDma *dma_handler, data_t *tx_buff, size_t packets)
{
    if (dma_handler == NULL || tx_buff == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status = STATUS_FAILURE;

    status = XAxiDma_SimpleTransfer(dma_handler, (UINTPTR)tx_buff, packets * sizeof(data_t), XAXIDMA_DEVICE_TO_DMA);

    if (status != STATUS_OK)
        return STATUS_DMA_TX_FAILURE;

    return STATUS_OK;
}

kan_status_t kan_dma_rx(XAxiDma *dma_handler, data_t *rx_buff, size_t packets)
{
    if (dma_handler == NULL || rx_buff == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status = STATUS_FAILURE;

    status = XAxiDma_SimpleTransfer(dma_handler, (UINTPTR)rx_buff, packets * sizeof(data_t), XAXIDMA_DMA_TO_DEVICE);

    if (status != STATUS_OK)
        return STATUS_DMA_TX_FAILURE;

    return STATUS_OK;
}

#ifdef DEPRECATED

/*****************************************************************************
 * This function setups the interrupt system so interrupts can occur for the
 * DMA, it assumes INTC component exists in the hardware system.
 *
 * @param	IntcInstancePtr is a pointer to the instance of the INTC.
 * @param	AxiDmaPtr is a pointer to the instance of the DMA engine
 * @param	TxIntrId is the TX channel Interrupt ID.
 * @param	RxIntrId is the RX channel Interrupt ID.
 *
 * @return
 * - XST_SUCCESS if successful
 *
 * - XST_FAILURE if not successful
 */
static int intr_init(XScuGic *IntcInstancePtr, XAxiDma *AxiDmaPtr, u16 TxIntrId, u16 RxIntrId)
{
    int Status;

    XScuGic_Config *IntcConfig; // pointer to a configuration struct

    /*--------------------------------------------
     Fill-up configuration struct.
     The define can be found in `xparameters_ps.h`
    ---------------------------------------------*/

    IntcConfig = XScuGic_LookupConfig(INTR_CONTROLLER_DEVICE_ID);
    if (NULL == IntcConfig)
        return XST_FAILURE;

    /*--------------------------------------------
     Initialize the configuration
     using the handler and the struct
    ---------------------------------------------*/

    Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (Status != XST_SUCCESS)
        return XST_FAILURE;

    /*--------------------------------------------
     Set the priorities for the two interrupts
    ---------------------------------------------*/

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, TxIntrId, TX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);
    XScuGic_SetPriorityTriggerType(IntcInstancePtr, RxIntrId, RX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);

    /*--------------------------------------------
     Attach callbacks to interrupts
     - The callback functions are yours
     - They are the handlers of the interrupt
     - They need to be cast as `Xil_InterruptHandler`
     - Must have argument a pointer to the DMA channel
     - Not certain but must have `void` return type
    ---------------------------------------------*/

    Status = XScuGic_Connect(IntcInstancePtr, TxIntrId, (Xil_InterruptHandler)callback_dma_tx, AxiDmaPtr);
    if (Status != XST_SUCCESS)
        return Status;

    Status = XScuGic_Connect(IntcInstancePtr, RxIntrId, (Xil_InterruptHandler)callback_dma_rx, AxiDmaPtr);
    if (Status != XST_SUCCESS)
        return Status;

    /*--------------------------------------------
     Enables the interrupts you just configured
    ---------------------------------------------*/

    XScuGic_Enable(IntcInstancePtr, TxIntrId);
    XScuGic_Enable(IntcInstancePtr, RxIntrId);

    /*--------------------------------------------
     Exception handling
     - Not sure if really necessary
     - Cause interrupts are enabled from hardware
     - The reason you needed `xil_exception.h`
    ---------------------------------------------*/

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)IntcInstancePtr);

    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

/*****************************************************************************
 * Initialize the AXI DMA Engine with interrupts
 *
 * @return DMA status
 */
int dma_init_irq(XAxiDma *hDma, XScuGic *intr_handler)
{
    int Status;
    XAxiDma_Config *Config;

    /*--------------------------------------------
     Fill-up configuration struct
     - the define can be found in:
        + xparameters.h
        + "Hardware Platform Specification" GUI
    ---------------------------------------------*/

    Config = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!Config)
    {
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
        return XST_FAILURE;
    }

    /*--------------------------------------------
     Initialize the DMA Engine with
     the configuration struct
    ---------------------------------------------*/

    Status = XAxiDma_CfgInitialize(hDma, Config);

    if (Status != XST_SUCCESS)
    {
        xil_printf("Initialization failed %d\r\n", Status);
        return XST_FAILURE;
    }

    /*--------------------------------------------
     Make sure you have no scatter gather
    ---------------------------------------------*/

    if (XAxiDma_HasSg(hDma))
    {
        xil_printf("Device configured as SG mode \r\n");
        return XST_FAILURE;
    }

    /*--------------------------------------------
     Set up Interrupt system
    ---------------------------------------------*/

    Status = intr_init(intr_handler, hDma, TX_INTR_ID, RX_INTR_ID);
    if (Status != XST_SUCCESS)
    {
        xil_printf("Failed intr setup\r\n");
        return XST_FAILURE;
    }

    /*--------------------------------------------
     Disable and then enable all interrupts
    ---------------------------------------------*/

    XAxiDma_IntrDisable(hDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrDisable(hDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    XAxiDma_IntrEnable(hDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(hDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

/*****************************************************************************
 * This function setups the interrupt system so interrupts can occur for the
 * DMA, it assumes INTC component exists in the hardware system.
 *
 * @param	IntcInstancePtr is a pointer to the instance of the INTC.
 * @param	AxiDmaPtr is a pointer to the instance of the DMA engine
 * @param	TxIntrId is the TX channel Interrupt ID.
 * @param	RxIntrId is the RX channel Interrupt ID.
 *
 * @return
 * - XST_SUCCESS if successful
 *
 * - XST_FAILURE if not successful
 */
static int dma_intr_init(XScuGic *IntcInstancePtr, XAxiDma *AxiDmaPtr, u16 TxIntrId, u16 RxIntrId)
{
    int status;

    XScuGic_Config *IntcConfig; // pointer to a configuration struct

    /*--------------------------------------------
     Fill-up configuration struct.
     The define can be found in `xparameters_ps.h`
    ---------------------------------------------*/

    IntcConfig = XScuGic_LookupConfig(INTR_CONTROLLER_DEVICE_ID);
    if (NULL == IntcConfig)
        return XST_FAILURE;

    /*--------------------------------------------
     Initialize the configuration
     using the handler and the struct
    ---------------------------------------------*/

    status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    /*--------------------------------------------
     Set the priorities for the two interrupts
    ---------------------------------------------*/

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, TxIntrId, TX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);
    XScuGic_SetPriorityTriggerType(IntcInstancePtr, RxIntrId, RX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);

    /*--------------------------------------------
     Attach callbacks to interrupts
     - The callback functions are yours
     - They are the handlers of the interrupt
     - They need to be cast as `Xil_InterruptHandler`
     - Must have argument a pointer to the DMA channel
     - Not certain but must have `void` return type
    ---------------------------------------------*/

    status = XScuGic_Connect(IntcInstancePtr, TxIntrId, (Xil_InterruptHandler)callback_dma_tx, AxiDmaPtr);
    if (status != XST_SUCCESS)
        return status;

    status = XScuGic_Connect(IntcInstancePtr, RxIntrId, (Xil_InterruptHandler)callback_dma_rx, AxiDmaPtr);
    if (status != XST_SUCCESS)
        return status;

    /*--------------------------------------------
     Enables the interrupts you just configured
    ---------------------------------------------*/

    XScuGic_Enable(IntcInstancePtr, TxIntrId);
    XScuGic_Enable(IntcInstancePtr, RxIntrId);

    /*--------------------------------------------
     Exception handling
     - Not sure if really necessary
     - Cause interrupts are enabled from hardware
     - The reason you needed `xil_exception.h`
    ---------------------------------------------*/

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)IntcInstancePtr);

    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

/*****************************************************************************
 * This function disables the interrupts for DMA engine.
 *
 * @param	IntcInstancePtr is the pointer to the INTC component instance
 * @param	TxIntrId is interrupt ID associated w/ DMA TX channel
 * @param	RxIntrId is interrupt ID associated w/ DMA RX channel
 */
static void intr_disable(XScuGic *IntcInstancePtr, u16 TxIntrId, u16 RxIntrId)
{

    /*--------------------------------------------
     Detattach callbacks from interrupts
    ---------------------------------------------*/
    XScuGic_Disconnect(IntcInstancePtr, TxIntrId);
    XScuGic_Disconnect(IntcInstancePtr, RxIntrId);
}

#endif
