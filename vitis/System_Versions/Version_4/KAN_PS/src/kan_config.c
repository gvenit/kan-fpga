#include "kan_config.h"

// kan_status_t kan_config_init(kan_network_handler_t *kan_handler, kan_layer_handler_t *kan_layers_array, kan_data_buff_t *kan_data_buff_p)
kan_status_t kan_config_init(kan_network_handler_t *kan_handler, kan_layer_handler_t *kan_layers_array, volatile data_t **kan_data_buff_p)
{
    if (kan_handler == NULL || kan_layers_array == NULL)
        return STATUS_ILLEGAL_ARG;

    size_t grid_block_stride = 0;
    size_t scale_block_stride = 0;
    size_t weight_block_stride = 0;

    uint8_t max_data = 0;

    // general network params - kan nextwork handler

    kan_handler->layers_num = KAN_LAYERS_NUM;

    kan_handler->data_ps_base_addr = dataArray;
    kan_handler->grid_ps_base_addr = gridArray;
    kan_handler->scale_ps_base_addr = scaleArray;
    kan_handler->weight_ps_base_addr = weightArray;

    kan_handler->data_pl_base_addr = (volatile data_t *)DATA_BRAM_BASE_ADDR;
    kan_handler->grid_pl_base_addr = (volatile data_t *)GRID_BRAM_BASE_ADDR;
    kan_handler->scale_pl_base_addr = (volatile data_t *)SCALE_BRAM_BASE_ADDR;

    // for loop to initiate sizes for result, weights and the data buffer

    for (int i = 0; i < KAN_LAYERS_NUM; i++)
    {
        if (i + 1 < KAN_LAYERS_NUM)
            kan_layers_array[i].result_num = sizes_array_data[i + 1];
        else
            kan_layers_array[i].result_num = KAN_RESULT_FEATURES;

        kan_layers_array[i].weight_num = sizes_array_data[i] * sizes_array_grid[i] * kan_layers_array[i].result_num;

        if (max_data < sizes_array_data[i])
            max_data = sizes_array_data[i];
    }

    (*kan_data_buff_p) = (kan_data_buff_t)calloc(sizeof(data_t), max_data);
    if ((*kan_data_buff_p) == NULL)
        return STATUS_MALLOC_FAIL;

    // layer params - kan layer handlers

    for (int i = 0; i < KAN_LAYERS_NUM; i++)
    {
        kan_layers_array[i].layer_id = i; // !!! will type mismatch create problems?

        kan_layers_array[i].data_num = sizes_array_data[i];
        kan_layers_array[i].scale_num = sizes_array_scale[i];
        kan_layers_array[i].grid_num = sizes_array_grid[i];

        if (i == 0)
            kan_layers_array[i].data_ps_src_addr = kan_handler->data_ps_base_addr;
        else
            kan_layers_array[i].data_ps_src_addr = (data_t *)(*kan_data_buff_p);
        kan_layers_array[i].grid_ps_src_addr = (kan_handler->data_ps_base_addr) + grid_block_stride;
        kan_layers_array[i].scale_ps_src_addr = (kan_handler->data_ps_base_addr) + scale_block_stride;
        kan_layers_array[i].weight_ps_src_addr = (kan_handler->data_ps_base_addr) + weight_block_stride;
        kan_layers_array[i].result_ps_dest_addr = (*kan_data_buff_p);

        grid_block_stride += kan_layers_array[i].grid_num;
        scale_block_stride += kan_layers_array[i].scale_num;
        weight_block_stride += kan_layers_array[i].weight_num;
    }

    // final params

    kan_handler->result_ps_base_addr = (*kan_data_buff_p);

    kan_handler->kan_layers_handlers = kan_layers_array;

    return STATUS_OK;
}
