#include "kan_interrupts.h"

kan_status_t kan_intr_init(kan_intr_handler_t *intr_handler, uint16_t intr_controller_id)
{
    if (intr_handler == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status;

    XScuGic_Config *intr_config; // pointer to a configuration struct

    /**
     * Fill-up configuration struct.
     * The define can be found in `xparameters_ps.h`
     */

    intr_config = XScuGic_LookupConfig(INTR_CONTROLLER_DEVICE_ID);
    if (NULL == intr_config)
        return STATUS_NULL_POINTER_REF;

    /**
     * Initialize the configuration
     * using the handler and the struct
     */

    status = XScuGic_CfgInitialize(intr_handler, intr_config, intr_config->CpuBaseAddress);
    if ((status != STATUS_OK) || (!(intr_handler->IsReady)))
        return STATUS_INTR_INIT_FAILURE;

    /**
     * Setup the Interrupt System
     *
     * In the case of ARM thisn is exception handling
     * - Not sure if really necessary
     * - Cause interrupts are enabled from hardware
     * - The reason you needed `xil_exception.h`
     */

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, (void *)intr_handler);

    Xil_ExceptionEnable();

    return STATUS_OK;
}

kan_status_t kan_intr_attach(kan_intr_handler_t *intr_handler, uint16_t intr_id, uint8_t intr_priority, uint8_t intr_trigger, kan_intr_callback_t intr_callback, void *intr_callback_driver)
{
    if ((intr_handler == NULL) || (!(intr_handler->IsReady)))
        return STATUS_ILLEGAL_ARG;

    if (intr_callback_driver == NULL)
        return STATUS_ILLEGAL_ARG;

    if (intr_priority > 248)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status;

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
    if (status != STATUS_OK)
        return STATUS_INTR_ATTACH_FAILURE;

    /**
     * Enables the interrupt you just configured
     */

    XScuGic_Enable(intr_handler, intr_id);

    return STATUS_OK;
}

kan_status_t kan_intr_detach(kan_intr_handler_t *intr_handler, uint16_t intr_id)
{
    if ((intr_handler == NULL) || (!(intr_handler->IsReady)))
        return STATUS_ILLEGAL_ARG;

    XScuGic_Disconnect(intr_handler, intr_id);

    return STATUS_OK;
}