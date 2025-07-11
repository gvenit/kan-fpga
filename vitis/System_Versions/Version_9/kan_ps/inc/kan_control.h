#ifndef _KAN_CONTROL_H_
#define _KAN_CONTROL_H_

#include "kan_status.h"
#include "kan_memory_map.h"
#include "kan_memory.h"

#include "xil_printf.h"

/**
 * Flags updated by the PL to PS interrupt
 */

extern volatile kan_state_t kan_state; // the state of the core, based on the contents of the control status register

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

/////////////////////////////////////////////

kan_status_t kan_ctrl_soft_rest(void);

kan_bool_t kan_ctrl_reg_oper_done(void);

kan_state_t kan_ctrl_get_state(void);

void callback_status_reg(void *intr_handler);

/////////////////////////////////////////////

#endif