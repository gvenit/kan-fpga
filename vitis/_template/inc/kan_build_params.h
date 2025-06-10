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

/*==============================================================================
    Definitions to specify the internal types of RAM to sotre network data
 ==============================================================================*/

/**
 * Uncomment `DATA_BRAM` for the data to use a multi-bank BRAM
 *
 * Commentout `DATA_BRAM` if the data are stored in a single bank Axil RAM
 */
#define DEF_DATA_BRAM_CTR

/**
 * Uncomment `DEF_SCALE_BRAM_CTR` for a scale RAM using a Bram controller and multiple banks
 *
 * Comment-out `DEF_SCALE_BRAM_CTR` for a scale RAM using an Axil interface
 */
// #define DEF_SCALE_BRAM_CTR

/**
 * Uncomment `DEF_GRID_BRAM_CTR` for a scale RAM using a Bram controller and multiple banks
 *
 * Comment-out `DEF_GRID_BRAM_CTR` for a scale RAM using an Axil interface
 */
// #define DEF_GRID_BRAM_CTR

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
#define KAN_LAYERS_NUM 4

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
static uint8_t sizes_array_data[KAN_LAYERS_NUM] = {2, 4, 3, 2};

/**
 * @brief the number of scale on each KAN layer
 *
 * @warning
 * - Must be explicitly defined in the `kan_build_params.h` by the user
 * and the array size must strictly match the `KAN_LAYERS_NUM`
 *
 * - They must strictly adhere to the `DEF_SCALE_BRAM_CTR` macro.
 */
static uint8_t sizes_array_scale[KAN_LAYERS_NUM] = {1, 1, 1, 1};

/**
 * @brief the number of grid on each KAN layer
 *
 * @warning
 * - Must be explicitly defined in the `kan_build_params.h` by the user
 * and the array size must strictly match the `KAN_LAYERS_NUM`
 *
 * - They must strictly adhere to the `DEF_GRID_BRAM_CTR` macro.
 */
static uint8_t sizes_array_grid[KAN_LAYERS_NUM] = {1, 1, 1, 1};

/**
 * @brief the number of weights on each KAN layer.
 * Each size is the multiple of the number of data and results
 * on the current layer.
 *
 * @warning Not initialized statically and must not be
 * done by the user. It is done automatically
 * by calls in the `kan_config.h` header
 */
static uint8_t sizes_array_weight[KAN_LAYERS_NUM];

/**
 * @brief the number of results on each KAN layer.
 * Each size is the multiple of the number of data and results
 * on the current layer.
 *
 * @warning Not initialized statically and must not be
 * done by the user. It is done automatically
 * by calls in the `kan_config.h` header
 */
static uint8_t sizes_array_result[KAN_LAYERS_NUM];

/**
 * used datatype
 *
 * This is the datatype of a single packet internal to the design.
 * There are also defines regarding its size
 * and the memory addressing in the `kan_defines.h` header
 */
typedef uint16_t data_t; // the type of a single packet

#endif