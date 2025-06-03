#ifndef _KAN_CONFIG_H_
#define _KAN_CONFIG_H_

#include "kan_build_params.h"
#include "kan_status.h"
#include "kan_memory_map.h"

#include "dataset_data.h"
#include "dataset_grid.h"
#include "dataset_scale.h"

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

struct Kan_Network_Config_Struct
{
    // general parameters

    uint8_t layers_num;

    // pointers to arrays of sizes

    uint8_t *data_sizes_array;
    uint8_t *grid_sizes_array;
    uint8_t *scale_sizes_array;
    uint8_t *weight_sizes_array;
    uint8_t *result_sizes_array;

    // pointers to target base addresses in PS memory space

    data_t *data_ps_base_addr;
    data_t *grid_ps_base_addr;
    data_t *scale_ps_base_addr;
    data_t *weight_ps_base_addr;
    data_t *result_ps_base_addr;

    // pointers to target base addresses in PL memory space

    volatile data_t *data_pl_base_addr;
    volatile data_t *grid_pl_base_addr;
    volatile data_t *scale_pl_base_addr;
    volatile data_t *weight_pl_base_addr;
    volatile data_t *result_pl_base_addr;

    // pointer to the address of array of layer configuration handler structs

    kan_layer_handler_t *kan_layers_handlers;
};

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

struct Kan_Layer_Config_Struct
{
    // layer ID (min is 0 max is the number of layers minus 1)

    uint8_t layer_id;

    // numbers of packets in the network

    uint8_t data_num;
    uint8_t grid_num;
    uint8_t scale_num;
    uint8_t weight_num;
    uint8_t result_num;

    // pointers to target addresses in PS memory space

    data_t *data_ps_src_addr;
    data_t *grid_ps_src_addr;
    data_t *scale_ps_src_addr;
    data_t *weight_ps_src_addr;
    data_t *result_ps_dest_addr;

    // pointers to target base addresses in PL memory space

    data_t *data_pl_dest_addr;
    data_t *grid_pl_dest_addr;
    data_t *scale_pl_dest_addr;
    data_t *weight_pl_dest_addr;
    data_t *result_pl_src_addr;
};

#ifdef DEF_DEPRECATED
/*===========================================================================
    Global variables of the network and layer handlers
 ===========================================================================*/

static kan_network_handler_t kan_handler;

static kan_layer_handler_t kan_layer_handlers_array[KAN_LAYERS_NUM];
#endif

/*===========================================================================
    Function prototypes of the header
 ===========================================================================*/

kan_status_t kan_config_init(kan_network_handler_t *kan_handler);

#endif