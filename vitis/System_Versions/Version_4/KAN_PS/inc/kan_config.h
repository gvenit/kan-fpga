#ifndef _KAN_CONFIG_H_
#define _KAN_CONFIG_H_

#include <stdint.h>
#include <stdlib.h>

#include "dataset_data.h"
#include "dataset_grid.h"
#include "dataset_scale.h"
#include "dataset_weight.h"
#include "kan_build_params.h"
#include "kan_memory_map.h"
#include "kan_status.h"

/*===========================================================================
    Type definition of handler and struct declaration
 ===========================================================================*/

/**
 * @brief KAN whole network handler struct.
 *
 * Contains general information on the network:
 *
 * - general parameters
 *
 * - pointers to arrays of sizes
 *
 * - pointers to target base addresses in PS memory space
 *
 * - pointers to target base addresses in PL memory space
 *
 * - pointer to the address of array of layer configuration handler structs
 *
 * @warning
 * - Not iniitalized before a call to `kan_config_init`
 *
 * - user must not mess with its values and treat it as read only.
 * The functions of this header update them
 */
typedef struct Kan_Network_Config_Struct kan_network_handler_t;

/**
 * @brief KAN single layer handler struct.
 *
 * Contains information on a specific layer:
 *
 * - layer ID (min is 0 max is the number of layers minus 1)
 *
 * - numbers of packets in the network
 *
 * - pointers to target addresses in PS memory space
 *
 * - pointers to target base addresses in PL memory space
 *
 * @warning
 * - Not iniitalized before a call to `kan_config_init`
 *
 * - user must not mess with its values and treat it as read only.
 * The functions of this header update them
 */
typedef struct Kan_Layer_Config_Struct kan_layer_handler_t;

/**
 * @brief Buffer to hold the data and results of its layer.
 * The user must declare one such variable and pass it
 * in the `kan_config_init` function to be initialized as
 * a buffer withe size of the layer that has the most data
 */
typedef volatile data_t *kan_data_buff_t;

struct Kan_Network_Config_Struct
{
    // general parameters

    uint8_t layers_num;

    // pointers to target base addresses in PS memory space

    data_t *data_ps_base_addr;
    data_t *grid_ps_base_addr;
    data_t *scale_ps_base_addr;
    data_t *weight_ps_base_addr;
    kan_data_buff_t result_ps_base_addr;

    // pointers to target base addresses in PL memory space

    volatile data_t *data_pl_base_addr;
    volatile data_t *grid_pl_base_addr;
    volatile data_t *scale_pl_base_addr;

    // pointer to the address of array of layer configuration handler structs

    kan_layer_handler_t *kan_layers_handlers;
};

struct Kan_Layer_Config_Struct
{
    // layer ID (min is 0 max is the number of layers minus 1)

    uint8_t layer_id;

    // numbers of packets in the network

    uint16_t data_num;
    uint16_t grid_num;
    uint16_t scale_num;
    uint16_t weight_num;
    uint16_t result_num;

    // pointers to target addresses in PS memory space

    data_t *data_ps_src_addr;
    data_t *grid_ps_src_addr;
    data_t *scale_ps_src_addr;
    data_t *weight_ps_src_addr;
    kan_data_buff_t result_ps_dest_addr;
};

/*===========================================================================
    Function prototypes of the header
 ===========================================================================*/

kan_status_t kan_config_init(kan_network_handler_t *kan_handler, kan_layer_handler_t *kan_layers_array, volatile data_t **kan_data_buff_p);

#endif