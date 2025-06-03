#ifndef _KAN_BUILD_PARAMS_H_
#define _KAN_BUILD_PARAMS_H_

#include "xil_types.h"

/**
 * used datatype
 *
 * This is the datatype of a single packet internal to the design.
 * There are also defines regarding its size
 * and the memory addressing
 */
typedef uint16_t data_t; // the type of a single packet

/*==============================================================================
    Application parameters of the executions
 ==============================================================================*/

/**
 * Uncomment `DEF_VERBOSE` to activate printfs
 *
 * Comment it out for silent operation
 */
#define DEF_VERBOSE

/*==============================================================================
    Definitions to specify the internal types of RAM to sotre network data
 ==============================================================================*/

/**
 * Uncomment `DATA_BRAM` for the data to use a multi-bank BRAM
 *
 * Commentout `DATA_BRAM` if the data are stored in a single bank Axil RAM
 */
#define DEF_DATA_BRAM

/**
 * Uncomment `SCALE_IS_SHARED` for a scale RAM using an Axil interface
 *
 * Comment-out `SCALE_IS_SHARED` for a scale RAM using a Bram controller and multiple banks
 */
#define DEF_SCALE_IS_SHARED

/**
 * Uncomment `SCALE_IS_SHARED` for a scale RAM using an Axil interface
 *
 * Comment-out `SCALE_IS_SHARED` for a scale RAM using a Bram controller and multiple banks
 */
#define DEF_GRID_IS_SHARED

#endif