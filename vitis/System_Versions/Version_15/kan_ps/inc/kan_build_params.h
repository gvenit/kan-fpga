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
// #define DEF_DBG

/**
 * Uncomment `DEF_TIME_LAYER` to time each layer individually and print such messages
 *
 * Comment it out if you do not wish to do so
 *
 * @warning Mutually exclusive with the `DEF_TIME_NETWORK` macro
 */
#define DEF_TIME_LAYER

/**
 * Uncomment `DEF_TIME_NETWORK` to time the execution of the entire layer and print it at the end
 *
 * Comment it out if you do not wish to do so
 *
 * @warning Mutually exclusive with the `DEF_TIME_LAYER` macro
 */
#define DEF_TIME_NETWORK

/**
 * Uncomment it to execute all the inputs of the HAM10000 dataset, stored in the `dataset_data` DDR region (see linker script)
 *
 * Comment it out and it will only exexute the first image of the dataset
 */
// #define DEF_EXEC_ALL_INPUTS

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
 * @brief The number of different input datasets stored in the `dataset_data` region of the memory (see linker script)
 *
 * For the HAM10000 dataset this is the total number of used images.
 */
#define KAN_INPUT_DATA_NUM 1602

/**
 * @brief Number of result packets.
 * Define how many data the final layer produces
 */
#define KAN_RESULT_FEATURES 7

/**
 * @brief Number of result channels.
 * Internal info of the PL architecture used to update the weights
 */
#define KAN_RESULT_CHANNELS 4

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
static const uint16_t sizes_array_data[KAN_LAYERS_NUM] = {64 * 64 * 3, 1024};

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