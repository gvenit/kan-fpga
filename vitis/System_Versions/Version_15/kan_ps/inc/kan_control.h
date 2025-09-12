#ifndef _KAN_CONTROL_H_
#define _KAN_CONTROL_H_

#include "kan_status.h"
#include "kan_memory_map.h"
#include "kan_memory.h"
#include "kan_config.h"
#include "kan_defines.h"

#include "xil_printf.h"

/**
 * Flags updated by the PL to PS interrupt
 */

extern volatile int kan_state; // the state of the core, based on the contents of the control status register

/**
 * @brief performs a software reset on the PL core
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_ctrl_soft_reset(void);

/**
 * @brief Starts the PL core
 *
 * @warning Calling this function without configuring the core first
 * using the functions in `kan_config.h` will result in a core error state
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_ctrl_start_core(void);

/**
 * @brief returns the core state by reading status registers
 *
 * @returns
 * a value of the `kan_state_t` enum in `kan_status.h`
 * that represents the state of the core
 */
kan_state_t kan_ctrl_get_state(void);

/**
 * @brief Returns a boolean if
 * the core is idle
 *
 * @returns `IS_TRUE == 1` if the core is idle
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_idle(void);

/**
 * @brief Returns a boolean if
 * the core is busy
 *
 * @returns `IS_TRUE == 1` if the core is busy
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_busy(void);

/**
 * @brief Returns a boolean if
 * the core is in error
 *
 * @returns `IS_TRUE == 1` if the core is in error
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_error(void);

/**
 * @brief Returns a boolean if
 * the core is locked
 *
 * @returns `IS_TRUE == 1` if the core is locked
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_locked(void);

/**
 * @brief Returns a boolean if
 * the core configuration is valid
 *
 * @returns `IS_TRUE == 1` if the core is valid
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_valid(void);

/**
 * @brief Returns a boolean if
 * the core is reset
 *
 * @returns `IS_TRUE == 1` if the core is reset
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_status_reset(void);

/**
 * @brief Reads the operation-done register
 *
 * @warning this register must be nulled at completion
 * but this function does not do that
 *
 * @returns `IS_TRUE == 1` if the core operation is done
 * or else `IS_FALSE == 0`
 */
kan_bool_t kan_ctrl_reg_oper_done(void);

/**
 * @brief Updates the layer stattistics on the layer struct
 *
 * The layer struct is the `Kan_Layer_Config_Struct` defined in `kan_config.h`
 * for which the user must allocate memory in main function
 *
 * @param layer_handler a pointer to the layer handler (pointer to pointer)
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_ctrl_update_layer_stats(kan_layer_handler_t *layer_handler);

/**
 * @brief Callback function for the PL2PS interrupt
 *
 * This callback function is called whenever the PL generates an interrupt.
 * This occurs whenever the status registers change state.
 * This fuction updates the global `kan_state` flag-variable with the changed core state.
 *
 * @warning For this callback to fire with the interrupt one must first call
 * the `kan_intr_init` function from `kan_interrupts.h` and then attach the callback
 * to the used interrupt handler by calling `kan_intr_attach`
 *
 * @param intr_handler the interrupt handler responsible to monitor the PL2PS interrupt.
 */
void callback_status_reg(void *intr_handler);

#endif