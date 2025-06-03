#include <stdlib.h>

/********************************************
 * Local Includes
 *******************************************/

#include "xparameters.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xil_printf.h"

/**
 * build parameters
 */

#include "build_params.h"

/**
 * Memory region headers
 */

#include "dataset_data.h"
#include "dataset_grid.h"
#include "dataset_scale.h"

/**
 * DMA libs
 */

#include "xaxidma.h"
#include "xscugic.h"

/**
 * Memory libs
 */

#ifdef BRAM_INTRF
#include "xbram.h"
#endif
#include "xil_mem.h"

/********************************************
 * Local defines and typedefs
 *******************************************/

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

/**
 * Interrupt paramters
 */

#define INTC_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID // from Canonical definitions for SCU GIC. It is the ID of the Interrupt Controler (INTC)

/**
 * DMA paramteres
 */

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID                  // DMA device ID
#define RX_INTR_ID XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID // fabric IR connected to ps7_scugic_0
#define TX_INTR_ID XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID // fabric IR connected to ps7_scugic_0
#define TX_INTR_PRIORITY 0xA0                               //
#define RX_INTR_PRIORITY 0xA0                               // There are 32 priority levels (highest to lowest): 0, 8, 16, 32, 40 ..., 248
#define INTR_TRIGGER_RISING_EDGE 0x03                       // rising edge interrupts need the bits b11
#define RESET_TIMEOUT_COUNTER 10000                         // Timeout loop counter for reset (measured in ms)

// #define NUMBER_OF_TRANSFERS 10

/********************************************
 * Function decleration
 *******************************************/

int dma_init_irq(XAxiDma *hDma, XScuGic *hIntrc);

#ifdef BRAM_INTRF
int bram_init(u16 DeviceId, XBram *Bram);
#endif

// static int CheckData(int32_t *Buff, int Length, int32_t StartValue);

static void txDmaCallbackHandler(void *Callback);
static void rxDmaCallbackHandler(void *Callback);

static int intr_init(XScuGic *IntcInstancePtr, XAxiDma *AxiDmaPtr, u16 TxIntrId, u16 RxIntrId);
static void intr_disable(XScuGic *IntcInstancePtr, u16 TxIntrId, u16 RxIntrId);

/********************************************
 * Global instances
 *******************************************/

#ifdef DATA_BRAM
XBram DataBram; // data bram controller handler
#endif

#ifdef GRID_BRAM
XBram GridBram; // grid bram controller handler;
#endif

#ifdef SCALE_BRAM
XBram ScaleBram; // scale bram controller handler
#endif

static XAxiDma AxiDma; // DMA handler for DMA engine

static XScuGic Intc; // interrupt controller handler

/*
 * Flags interrupt handlers use to notify the application context the events.
 * They are updated by the attached callback functions.
 */

volatile int TxDone; // DMA transmit complete
volatile int RxDone; // DMA receive complete
volatile int Error;  // error in DMA transaction

/*****************************************************************************
 * Main function
 *
 * @return
 * - XST_SUCCESS if example finishes successfully
 *
 * - XST_FAILURE if example fails.
 */
int main(void)
{
    /*--------------------------------------------
     Local variables
    ---------------------------------------------*/

    int status;
    int i;
    data_t *txBuff;
    data_t *rxBuff;
    data_t value;

    /*--------------------------------------------
     Initializations of BRAM and DMA
    ---------------------------------------------*/

    status = dma_init_irq(&AxiDma, &Intc);
    if (status != XST_SUCCESS)
    {
        xil_printf("Error in DMA initialization.\r\n Returned: %d\r\n", status);
        return status;
    }

#ifdef DATA_BRAM
    status = bram_init(DATA_BRAM_CONTROLLER_ID, &DataBram);
    if (status != XST_SUCCESS)
    {
        xil_printf("Error in Data BRAM initialization.\r\n Returned: %d\r\n", status);
        return status;
    }
#endif

#ifdef GRID_BRAM
    status = bram_init(GRID_BRAM_CONTROLLER_ID, &GridBram);
    if (status != XST_SUCCESS)
    {
        xil_printf("Error in Grid BRAM initialization.\r\n Returned: %d\r\n", status);
        return status;
    }
#endif

#ifdef SCALE_BRAM
    status = bram_init(SCALE_BRAM_CONTROLLER_ID, &ScaleBram);
    if (status != XST_SUCCESS)
    {
        xil_printf("Error in Scale BRAM initialization.\r\n Returned: %d\r\n", status);
        return status;
    }
#endif

    /*--------------------------------------------
     Variables and buffers initialization
    ---------------------------------------------*/

    // !!!!!!!!!!!!

    TxDone = 0;
    RxDone = 0;
    Error = 0;

    txBuff = (int32_t *)calloc(sizeof(int32_t), PKT_ELEMENTS);
    if (txBuff == NULL)
    {
        xil_printf("Memory allocation for tx buffer failed\r\n");
        return XST_FAILURE;
    }

    rxBuff = (int32_t *)calloc(sizeof(int32_t), PKT_ELEMENTS);
    if (rxBuff == NULL)
    {
        xil_printf("Memory allocation for rx buffer failed\r\n");
        return XST_FAILURE;
    }
    value = TEST_START_VALUE;

    for (i = 0; i < PKT_ELEMENTS; i++)
    {
        txBuff[i] = value;

        value = value + INCR;
    }

    xil_printf("\r\nRx Buffer before DMA:\r\n");
    for (i = 0; i < PKT_ELEMENTS; i++)
        xil_printf("Rx[%d] = %d\r\n", i, (int)(rxBuff[i]));
    xil_printf("\r\n\r\n");

    /*--------------------------------------------
     Flush the cache
    ---------------------------------------------*/

    Xil_DCacheFlushRange((UINTPTR)txBuff, sizeof(int32_t) * PKT_ELEMENTS);
    Xil_DCacheFlushRange((UINTPTR)rxBuff, sizeof(int32_t) * PKT_ELEMENTS);

    /*--------------------------------------------
     Start the DMA transfer
    ---------------------------------------------*/

    // /* Send a packet */
    // for (i = 0; i < NUMBER_OF_TRANSFERS; i++)
    // {

    status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)rxBuff, PKT_ELEMENTS * sizeof(int33_t), XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS)
    {
        xil_printf("DMA transmission failed: %d\r\n", status);
        return status;
    }

    status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)txBuff, PKT_ELEMENTS * sizeof(int32_t), XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS)
    {
        xil_printf("DMA reception failed: %d\r\n", status);
        return status;
    }

    while (!TxDone && !RxDone && !Error)
    {
        /* NOP */
    }

    if (Error)
    {
        xil_printf("Either transmit or receive failed:\r\n");
        xil_printf("receive%s done\r\n",
                   TxDone ? "" : " not",
                   RxDone ? "" : " not");
        return XST_FAILURE; // maybe this is too much - in the next iteration it might get it right
    }

    // status = CheckData(rxBuff, PKT_ELEMENTS, TEST_START_VALUE);
    // if (status != XST_SUCCESS)
    // {
    //     xil_printf("Data check failed\r\n");
    //     return status;
    // }
    // }

    // xil_printf("Successfully ran AXI DMA interrupt Example\r\n");

    xil_printf("\r\nRx Buffer after DMA:\r\n");
    for (i = 0; i < PKT_ELEMENTS; i++)
        xil_printf("Rx[%d] = %d\r\n", i, (int)(rxBuff[i]));
    xil_printf("\r\n\r\n");

    /*--------------------------------------------
     Disable DMA interrupts
    ---------------------------------------------*/

    intr_disable(&Intc, TX_INTR_ID, RX_INTR_ID);

    /*--------------------------------------------
     Memory deallocation
    ---------------------------------------------*/

    free(txBuff);
    free(rxBuff);

    xil_printf("\r\n-----------------------------------------------------------------------\r\n");
    xil_printf("\t END OF EXAMPLE \r\n");
    xil_printf("-----------------------------------------------------------------------\r\n");

    return XST_SUCCESS;
}

/*****************************************************************************
 *
 * This is the DMA TX Interrupt handler function.
 * In other words this is the callback of all the interrupts in DMA TX.
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then sets the TxDone flag
 *
 * @param	Callback is a pointer to TX channel of the DMA engine.
 */
static void txDmaCallbackHandler(void *Callback)
{
    u32 IrqStatus; // variable to store all the DMA Transmit channel interrupts as a bitmask
    int TimeOut;

    XAxiDma *AxiDmaInst = (XAxiDma *)Callback; // the arg is the DMA TX channel and need to be interpreted as such

    /*--------------------------------------------
     Read pending interrupts
    ---------------------------------------------*/

    IrqStatus = XAxiDma_IntrGetIrq(AxiDmaInst, XAXIDMA_DMA_TO_DEVICE);

    /*--------------------------------------------
     Acknowledge pending interrupts
    ---------------------------------------------*/

    XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DMA_TO_DEVICE);

    /*--------------------------------------------
     If no interrupt is asserted, we do not do anything
    ---------------------------------------------*/
    if (!(IrqStatus & XAXIDMA_IRQ_ALL_MASK))
        return;

    /*--------------------------------------------
     If error interrupt is asserted:
     - raise error flag
     - reset the hardware to recover from the error
     - return with no further processing
    ---------------------------------------------*/
    if ((IrqStatus & XAXIDMA_IRQ_ERROR_MASK))
    {
        Error = 1;

        // Reset should never fail for transmit channel
        XAxiDma_Reset(AxiDmaInst);

        TimeOut = RESET_TIMEOUT_COUNTER;

        while (TimeOut)
        {
            if (XAxiDma_ResetIsDone(AxiDmaInst))
                break;

            TimeOut -= 1;
        }

        return;
    }

    /*--------------------------------------------
     If Completion interrupt is asserted:
     - set the TxDone flag
    ---------------------------------------------*/
    if ((IrqStatus & XAXIDMA_IRQ_IOC_MASK))
        TxDone = 1;
}

/*****************************************************************************
 *
 * This is the DMA RX interrupt handler function.
 * In other words this is the callback of all the interrupts in DMA RX.
 *
 * It gets the interrupt status from the hardware, acknowledges it, and if any
 * error happens, it resets the hardware. Otherwise, if a completion interrupt
 * is present, then it sets the RxDone flag.
 *
 * @param	Callback is a pointer to RX channel of the DMA engine.
 *
 */
static void rxDmaCallbackHandler(void *Callback)
{
    u32 IrqStatus; // variable to store all the DMA Transmit channel interrupts as a bitmask
    int TimeOut;

    XAxiDma *AxiDmaInst = (XAxiDma *)Callback; // the arg is the DMA TX channel and need to be interpreted as such

    /*--------------------------------------------
     Read pending interrupts
    ---------------------------------------------*/

    IrqStatus = XAxiDma_IntrGetIrq(AxiDmaInst, XAXIDMA_DEVICE_TO_DMA);

    /*--------------------------------------------
     Acknowledge pending interrupts
    ---------------------------------------------*/

    XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DEVICE_TO_DMA);

    /*--------------------------------------------
     If no interrupt is asserted, we do not do anything
    ---------------------------------------------*/
    if (!(IrqStatus & XAXIDMA_IRQ_ALL_MASK))
        return;

    /*--------------------------------------------
     If error interrupt is asserted:
     - raise error flag
     - reset the hardware to recover from the error
     - return with no further processing
    ---------------------------------------------*/
    if ((IrqStatus & XAXIDMA_IRQ_ERROR_MASK))
    {
        Error = 1;

        // Reset should never fail for transmit channel
        XAxiDma_Reset(AxiDmaInst);

        TimeOut = RESET_TIMEOUT_COUNTER;

        while (TimeOut)
        {
            if (XAxiDma_ResetIsDone(AxiDmaInst))
                break;

            TimeOut -= 1;
        }

        return;
    }

    /*--------------------------------------------
     If Completion interrupt is asserted:
     - set the TxDone flag
    ---------------------------------------------*/
    if ((IrqStatus & XAXIDMA_IRQ_IOC_MASK))
        TxDone = 1;
}

/*****************************************************************************
 * This function setups the interrupt system so interrupts can occur
 * It assumes INTC component exists in the hardware system.
 *
 * @param	IntcInstancePtr is a pointer to the instance of the INTC.
 * @param	IntrId is the TX channel Interrupt ID.
 * @param   IntrPriority is the priority level of the interrupt.
 *          There are 32 priority levels (highest to lowest): 0, 8, 16, 32, 40 ..., 248
 * @param   IntrTrigger is the interrupt trigger type
 *
 * @return
 * - XST_SUCCESS if successful
 *
 * - XST_FAILURE if not successful
 */
static int intr_init(XScuGic *IntcInstancePtr, u16 IntrId, uint8_t IntrPriority, uint8_t IntrTrigger, void *CallbackHandler)
{
    int status;

    XScuGic_Config *IntcConfig; // pointer to a configuration struct

    /**
     * Fill-up configuration struct.
     * The define can be found in `xparameters_ps.h`
     */

    IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (NULL == IntcConfig)
        return XST_FAILURE;

    /**
     * Initialize the configuration
     * using the handler and the struct
     */

    status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    /**
     * Set the priorities for the two interrupts
     */

    XScuGic_SetPriorityTriggerType(IntcInstancePtr, IntrId, IntrPriority, IntrTrigger);

    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! up here it is modded

    /**
     * Attach callbacks to interrupts
     * - The callback functions are yours
     * - They are the handlers of the interrupt
     * - They need to be cast as `Xil_InterruptHandler`
     * - Must have argument a pointer to the DMA channel
     * - Not certain but must have `void` return type
     */

    status = XScuGic_Connect(IntcInstancePtr, IntrId, (Xil_InterruptHandler)CallbackHandler, AxiDmaPtr);
    if (status != XST_SUCCESS)
        return status;

    status = XScuGic_Connect(IntcInstancePtr, RxIntrId, (Xil_InterruptHandler)rxDmaCallbackHandler, AxiDmaPtr);
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

// /*****************************************************************************
//  * This function setups the interrupt system so interrupts can occur for the
//  * DMA, it assumes INTC component exists in the hardware system.
//  *
//  * @param	IntcInstancePtr is a pointer to the instance of the INTC.
//  * @param	AxiDmaPtr is a pointer to the instance of the DMA engine
//  * @param	TxIntrId is the TX channel Interrupt ID.
//  * @param	RxIntrId is the RX channel Interrupt ID.
//  *
//  * @return
//  * - XST_SUCCESS if successful
//  *
//  * - XST_FAILURE if not successful
//  */
// static int intr_init(XScuGic *IntcInstancePtr, XAxiDma *AxiDmaPtr, u16 TxIntrId, u16 RxIntrId)
// {
//     int status;

//     XScuGic_Config *IntcConfig; // pointer to a configuration struct

//     /*--------------------------------------------
//      Fill-up configuration struct.
//      The define can be found in `xparameters_ps.h`
//     ---------------------------------------------*/

//     IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
//     if (NULL == IntcConfig)
//         return XST_FAILURE;

//     /*--------------------------------------------
//      Initialize the configuration
//      using the handler and the struct
//     ---------------------------------------------*/

//     status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig, IntcConfig->CpuBaseAddress);
//     if (status != XST_SUCCESS)
//         return XST_FAILURE;

//     /*--------------------------------------------
//      Set the priorities for the two interrupts
//     ---------------------------------------------*/

//     XScuGic_SetPriorityTriggerType(IntcInstancePtr, TxIntrId, TX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);
//     XScuGic_SetPriorityTriggerType(IntcInstancePtr, RxIntrId, RX_INTR_PRIORITY, INTR_TRIGGER_RISING_EDGE);

//     /*--------------------------------------------
//      Attach callbacks to interrupts
//      - The callback functions are yours
//      - They are the handlers of the interrupt
//      - They need to be cast as `Xil_InterruptHandler`
//      - Must have argument a pointer to the DMA channel
//      - Not certain but must have `void` return type
//     ---------------------------------------------*/

//     status = XScuGic_Connect(IntcInstancePtr, TxIntrId, (Xil_InterruptHandler)txDmaCallbackHandler, AxiDmaPtr);
//     if (status != XST_SUCCESS)
//         return status;

//     status = XScuGic_Connect(IntcInstancePtr, RxIntrId, (Xil_InterruptHandler)rxDmaCallbackHandler, AxiDmaPtr);
//     if (status != XST_SUCCESS)
//         return status;

//     /*--------------------------------------------
//      Enables the interrupts you just configured
//     ---------------------------------------------*/

//     XScuGic_Enable(IntcInstancePtr, TxIntrId);
//     XScuGic_Enable(IntcInstancePtr, RxIntrId);

//     /*--------------------------------------------
//      Exception handling
//      - Not sure if really necessary
//      - Cause interrupts are enabled from hardware
//      - The reason you needed `xil_exception.h`
//     ---------------------------------------------*/

//     Xil_ExceptionInit();

//     Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)IntcInstancePtr);

//     Xil_ExceptionEnable();

//     return XST_SUCCESS;
// }

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

/*****************************************************************************
 * Initialize the AXI DMA Engine with interrupts
 *
 * @return DMA status
 */
int dma_init_irq(XAxiDma *hDma, XScuGic *hIntrc)
{
    int status;
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

    status = XAxiDma_CfgInitialize(hDma, Config);

    if (status != XST_SUCCESS)
    {
        xil_printf("Initialization failed %d\r\n", status);
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

    status = intr_init(hIntrc, hDma, TX_INTR_ID, RX_INTR_ID);
    if (status != XST_SUCCESS)
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
