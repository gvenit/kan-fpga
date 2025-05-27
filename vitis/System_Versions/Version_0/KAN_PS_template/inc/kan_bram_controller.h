#ifndef _KAN_BRAM_CONTROLLER_H_
#define _KAN_BRAM_CONTROLLER_H_

#include "xparameters.h"
#include "xbram.h"
#include "xil_mem.h"

#include "kan_defines.h"

extern struct XBram;

/**
 * @brief BRAM controller peripheral configuration and initialization
 *
 * @param bram_controller_id is the controller device ID found in `kan_defines.h`
 * @param bram_controller_handler is the bram handler
 *
 * @return XST_SUCCESS to indicate success. XST_FAILURE to indicate failure.
 */
int bram_init(u16 bram_controller_id, XBram *bram_controller_handler);

#endif