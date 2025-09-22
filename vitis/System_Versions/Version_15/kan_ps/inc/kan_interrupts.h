#ifndef _KAN_INTERRUPTS_H_
#define _KAN_INTERRUPTS_H_

#include <stdint.h>

#include "kan_defines.h"
#include "kan_status.h"

#include "xscugic.h"

typedef XScuGic kan_intr_handler_t;
typedef Xil_InterruptHandler kan_intr_callback_t;

/**
 * @brief This function setups the interrupt system so interrupts can occur.
 * It wraps functions from `xscugic.h` which must be included in the project
 * to use its interrupt handler.
 *
 * @param intr_handler is a pointer to the interrupt controller handler
 * @param intr_controller_id is the interrupt controller device ID. Better use a define
 * from `kan_defines.h` like `INTR_CONTROLLER_DEVICE_ID`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_intr_init(kan_intr_handler_t *intr_handler, uint16_t intr_controller_id);

/**
 * @brief This function attaches interrupts and callbacks
 * to an already initialized interrupt handler.
 * It wraps up functions from the `xscugic.h` header which must
 * be included in the project.
 *
 * @warning
 * - The interrupt handler must be initialized by the `kan_intr_int` function
 * - The user has full control of attaching the callbacks and interrupts.
 * If too many are attached some might be overriden
 *
 * @param intr_handler is a pointer to the interrupt controller handler
 * @param intr_id is the interrupt source ID. Usually found in a define in `kan_defines.h`
 * @param intr_priority is the priority level of the interrupt.
 * @param intr_trigger is the trigger type for the interrupt.
 * @param intr_callback is the callback function attached to the interrupt.
 * They must return `void` and take a pointer to the attached device handler as an argument
 * cast to `void *`. In this function pass the name of the callback function
 * cast as `kan_intr_callback_t`
 * @param intr_callback_driver is the callback reference, usually the instance
 * pointer of the connecting driver. Cast it to `void *`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_intr_attach(kan_intr_handler_t *intr_handler, uint16_t intr_id, uint8_t intr_priority, uint8_t intr_trigger, kan_intr_callback_t intr_callback, void *intr_callback_driver);

/**
 * This function disables specific interrupts
 *
 * @warning It is is assumed the interrupts where initialized and atached in the first place.
 *
 * @param intr_handler is a pointer to the interrupt controller handler
 * @param intr_id is the interrupt's source device ID
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_intr_detach(kan_intr_handler_t *intr_handler, uint16_t intr_id);

#endif