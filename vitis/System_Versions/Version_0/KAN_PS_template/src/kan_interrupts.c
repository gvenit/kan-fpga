#include "kan_interrupts.h"

static int kan_intr_init(XScuGic *intr_handler, uint16_t intr_controller_id)
{
    int status;

    XScuGic_Config *intr_config; // pointer to a configuration struct

    /**
     * Fill-up configuration struct.
     * The define can be found in `xparameters_ps.h`
     */

    intr_config = XScuGic_LookupConfig(INTR_CONTROLLER_DEVICE_ID);
    if (NULL == intr_config)
        return XST_FAILURE;

    /**
     * Initialize the configuration
     * using the handler and the struct
     */

    status = XScuGic_CfgInitialize(intr_handler, intr_config, intr_config->CpuBaseAddress);
    if (status != XST_SUCCESS)
        return XST_FAILURE;

    /**
     * Exception handling
     * - Not sure if really necessary
     * - Cause interrupts are enabled from hardware
     * - The reason you needed `xil_exception.h`
     */

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)intr_handler);

    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

static int kan_intr_attach(XScuGic *intr_handler, uint16_t intr_id, uint8_t intr_priority, uint8_t intr_trigger, Xil_InterruptHandler intr_callback, void *intr_callback_driver)
{
    int status;

    /**
     * Set the priority of the interrupt
     */

    XScuGic_SetPriorityTriggerType(intr_handler, intr_id, intr_priority, intr_trigger);

    /**
     * Attach callbacks to interrupt
     * - The callback functions are yours
     * - They are the handlers of the interrupt
     * - Not certain but must have `void` return type
     */

    status = XScuGic_Connect(intr_handler, intr_id, intr_callback, intr_callback_driver);
    if (status != XST_SUCCESS)
        return status;

    /**
     * Enables the interrupt you just configured
     */

    XScuGic_Enable(intr_handler, intr_id);
}

static void kan_intr_detach(XScuGic *intr_handler, uint16_t intr_id)
{
    XScuGic_Disconnect(intr_handler, intr_id);
}