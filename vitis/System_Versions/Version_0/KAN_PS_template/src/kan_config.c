#include "kan_config.h"

kan_status_t kan_config_init(kan_network_handler_t *kan_handler)
{
    if (kan_handler == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_layer_handler_t *layers_array = NULL;

    size_t data_block_stride = 0;
    size_t grid_block_stride = 0;
    size_t scale_block_stride = 0;
    size_t weight_block_stride = 0;
    size_t result_block_stride = 0;

    size_t data_block_size = 0;
    size_t grid_block_size = 0;
    size_t scale_block_size = 0;
    size_t weight_block_size = 0;
    size_t result_block_size = 0;

    kan_handler->layers_num = KAN_LAYERS_NUM;

    kan_handler->data_sizes_array = sizes_array_data;
    kan_handler->grid_sizes_array = sizes_array_grid;
    kan_handler->scale_sizes_array = sizes_array_scale;
    kan_handler->weight_sizes_array = sizes_array_weight;
    kan_handler->result_sizes_array = sizes_array_result;

    kan_handler->data_ps_base_addr = dataArray;
    kan_handler->grid_ps_base_addr = gridArray;
    kan_handler->scale_ps_base_addr = scaleArray;
    kan_handler->weight_ps_base_addr = NULL; // !!!!!!!!!!!!!! this must likely be another dataset
    kan_handler->result_ps_base_addr = NULL; // !!!!!!!!!!!!!! this must likely be configured in the for loop below

    kan_handler->data_pl_base_addr = (volatile data_t *)DATA_BRAM_BASE_ADDR;
    kan_handler->grid_pl_base_addr = (volatile data_t *)GRID_BRAM_BASE_ADDR;
    kan_handler->scale_pl_base_addr = (volatile data_t *)SCALE_BRAM_BASE_ADDR;
    kan_handler->weight_pl_base_addr = NULL; // !!!!!!!!!!!!!! something from vitis possibly
    kan_handler->result_pl_base_addr = NULL; // !!!!!!!!!!!!!! something from vitis possibly

    layers_array = (kan_layer_handler_t *)malloc(sizeof(kan_layer_handler_t) * KAN_LAYERS_NUM);
    if (layers_array == NULL)
        return STATUS_MALLOC_FAIL;

    for (int i = 0; i < KAN_LAYERS_NUM; i++)
    {
        layers_array[i].layer_id = i; // !!! will type mismatch create problems?

        layers_array[i].data_num = sizes_array_data[i];
        layers_array[i].scale_num = sizes_array_scale[i];
        layers_array[i].grid_num = sizes_array_grid[i];
        layers_array[i].weight_num = sizes_array_weight[i];
        layers_array[i].result_num = sizes_array_result[i];
    }

    kan_handler->kan_layers_handlers = layers_array;

    return STATUS_OK;
}