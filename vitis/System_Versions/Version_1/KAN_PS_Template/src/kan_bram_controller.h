#ifndef _KAN_BRAM_CONTROLLER_H_
#define _KAN_BRAM_CONTROLLER_H_

#include <stdint.h>

#include "kan_defines.h"
#include "kan_status.h"

#include "xbram.h"
#include "xparameters.h"
#include "xil_mem.h"

// #include "../../KAN_SoC/ps7_cortexa9_0/standalone_ps7_cortexa9_0/bsp/ps7_cortexa9_0/libsrc/bram_v4_8/src/xbram.h"

extern struct XBram;

/**
 * @brief BRAM controller peripheral configuration and initialization
 *
 * @param bram_controller_id is the controller device ID found in `kan_defines.h`
 * @param bram_controller_handler is the bram handler
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_bram_ctr_init(uint16_t bram_controller_id, XBram *bram_controller_handler);

#endif