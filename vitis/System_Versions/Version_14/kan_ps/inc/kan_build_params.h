#ifndef _KAN_BUILD_PARAMS_H_
#define _KAN_BUILD_PARAMS_H_

#include <stdint.h>

/*==============================================================================
    Application parameters of the executions
 ==============================================================================*/

/**
 * Uncomment `DEF_VERBOSE` to activate printfs
 *
 * Comment it out for silent operation
 */
#define DEF_VERBOSE

/**
 * Uncomment `DEF_DBG` to activate code sections for debug purposes
 *
 * Comment it out for release execution
 */
#define DEF_DBG

/*==============================================================================
    Network parameters and type definitions
 ==============================================================================*/

/**
 * @brief Number of layers in the KAN.
 *
 * For each layer:
 *
 * - a different number of different values for grid and scale
 * are defined and downloaded
 *
 * - a number of data and number of results are specified.
 * The data of each layer are the results of the other.
 *
 * - Different weight number of seperate weight values are specified
 * and downloaded to the core
 */
#define KAN_LAYERS_NUM 2

/**
 * @brief Number of result packets.
 * Define how many data the final layer produces
 */
#define KAN_RESULT_FEATURES 8

/**
 * @brief the number of data on each KAN layer
 *
 * @warning
 * - Must be explicitly defined in the `kan_build_params.h` by the user
 * and the array size must strictly match the `KAN_LAYERS_NUM`
 *
 * - They also define the size of results. Every layers result
 * are the data of the next one
 *
 * - They must strictly adhere to the `DEF_DATA_BRAM_CTR` macro.
 */
static const uint16_t sizes_array_data[KAN_LAYERS_NUM] = {4, 4};

/**
 * @brief the number of scale on each KAN layer
 *
 * @warning
 * - Must be explicitly defined in the `kan_build_params.h` by the user
 * and the array size must strictly match the `KAN_LAYERS_NUM`
 *
 * - They must strictly adhere to the `DEF_SCALE_BRAM_CTR` macro.
 */
static const uint16_t sizes_array_scale[KAN_LAYERS_NUM] = {1, 1};

/**
 * @brief the number of grid on each KAN layer
 *
 * @warning
 * - Must be explicitly defined in the `kan_build_params.h` by the user
 * and the array size must strictly match the `KAN_LAYERS_NUM`
 *
 * - They must strictly adhere to the `DEF_GRID_BRAM_CTR` macro.
 */
static const uint16_t sizes_array_grid[KAN_LAYERS_NUM] = {4, 4};

/**
 * @brief used datatype for data, scale and grid
 */
typedef uint16_t data_t; // the type of a single packet

/**
 * @brief used datatype for weights
 */
typedef uint8_t weight_t; // the type of a single packet

#endif