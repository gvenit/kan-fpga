#ifndef _KAN_BRAM_CONTROLLER_H_
#define _KAN_BRAM_CONTROLLER_H_

#include "xparameters.h"
#include "xbram.h"
#include "xil_mem.h"

#include "kan_defines.h"

/**
 * BRAM peripheral configuration and initialization
 * Taken from the provided Xilinx BRAM example
 *
 * @param DeviceId is the XPAR_<BRAM_instance>_DEVICE_ID value from xparameters.h
 * @param Bram is the bram handler
 *
 * @return XST_SUCCESS to indicate success. XST_FAILURE to indicate failure.
 */
int bram_init(u16 DeviceId, XBram *Bram);

#endif