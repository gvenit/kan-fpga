#include "kan_config.h"

#ifdef DEF_DEPRECATED
void *aligned_malloc(size_t size, size_t alignment)
{
    uintptr_t raw = (uintptr_t)malloc(size + alignment - 1 + sizeof(void *));
    if (!raw)
        return NULL;
    uintptr_t aligned = (raw + sizeof(void *) + alignment - 1) & ~(alignment - 1);
    ((void **)aligned)[-1] = (void *)raw;
    return (void *)aligned;
}
#endif

// kan_status_t kan_config_init(kan_network_handler_t *kan_handler, kan_layer_handler_t *kan_layers_array, kan_data_buff_t *kan_data_buff_p)
kan_status_t kan_config_init(kan_network_handler_t *kan_handler, kan_layer_handler_t *kan_layers_array, volatile data_t **kan_data_buff_p)
{
    if (kan_handler == NULL || kan_layers_array == NULL)
        return STATUS_ILLEGAL_ARG;

    size_t grid_block_stride = 0;
    size_t scale_block_stride = 0;
    size_t weight_block_stride = 0;

    uint16_t max_data = 0;

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
        kan_layers_array[i].weight_num = sizes_array_data[i] * sizes_array_grid[i] * (uint32_t)((kan_layers_array[i].result_num + KAN_RESULT_CHANNELS - 1) / KAN_RESULT_CHANNELS) * KAN_RESULT_CHANNELS;

        if (max_data < kan_layers_array[i].result_num)
            max_data = kan_layers_array[i].result_num;
    }

    size_t buffer_bytes = sizeof(data_t) * max_data;

    if (buffer_bytes % DMA_ALIGNMENT != 0)
        buffer_bytes += DMA_ALIGNMENT - (buffer_bytes % DMA_ALIGNMENT);

    (*kan_data_buff_p) = (kan_data_buff_t)aligned_alloc(DMA_ALIGNMENT, buffer_bytes);
    if ((*kan_data_buff_p) == NULL)
        return STATUS_MALLOC_FAIL;

    if (((uintptr_t)(*kan_data_buff_p)) % DMA_ALIGNMENT != 0)
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
        kan_layers_array[i].grid_ps_src_addr = (kan_handler->grid_ps_base_addr) + grid_block_stride;
        kan_layers_array[i].scale_ps_src_addr = (kan_handler->scale_ps_base_addr) + scale_block_stride;
        kan_layers_array[i].weight_ps_src_addr = (kan_handler->weight_ps_base_addr) + weight_block_stride;
        kan_layers_array[i].result_ps_dest_addr = (*kan_data_buff_p);

        grid_block_stride += kan_layers_array[i].grid_num;
        scale_block_stride += kan_layers_array[i].scale_num;
        weight_block_stride += kan_layers_array[i].weight_num;

        kan_layers_array[i].result_progress = 0;
        kan_layers_array[i].iteration_progress = 0;
        kan_layers_array[i].iteration_timer = 0;
        kan_layers_array[i].iteration_latency = 0;
        kan_layers_array[i].operation_timer = 0;
        kan_layers_array[i].operation_latency = 0;
    }

    // final params

    kan_handler->result_ps_base_addr = (*kan_data_buff_p);

    kan_handler->kan_layers_handlers = kan_layers_array;

    return STATUS_OK;
}

/////////////////////////////////////////////////////////////////////////////////////////////

kan_status_t kan_config_download2pl(kan_layer_handler_t *layer_handler)
{
    if (layer_handler == NULL)
        return STATUS_ILLEGAL_ARG;

    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_DATA_LEN_4B, (uint32_t)(layer_handler->data_num), WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_GRID_LEN_4B, (uint32_t)(layer_handler->grid_num), WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_SCLE_LEN_4B, (uint32_t)(layer_handler->scale_num), WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_RSLT_LEN_4B, (uint32_t)(layer_handler->result_num), WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_PCKT_LEN_4B, (uint32_t)(layer_handler->data_num) * (uint32_t)(layer_handler->grid_num), WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_BTCH_LEN_1B, 0x00000001, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_status_t kan_config_data_loaded(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_DATA_LDR_1B, 0x00000001, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_status_t kan_config_grid_loaded(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_GRID_LDR_1B, 0x00000001, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_status_t kan_config_scale_loaded(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_SCLE_LDR_1B, 0x00000001, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_status_t kan_config_weight_loaded(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_WGHT_LDR_1B, 0x00000001, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}
