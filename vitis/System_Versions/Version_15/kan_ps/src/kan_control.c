#include "kan_control.h"

#ifdef DEF_DBG
uint32_t count = 0;
uint32_t countMax = 1000000;
#endif

volatile int kan_state = KAN_STATE_UNKNOWN;

kan_status_t kan_ctrl_soft_reset(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_INTR_1B, KAN_REG_MASK_INTR_SFT_1B, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_INTR_1B, 0x00000000, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_status_t kan_ctrl_start_core(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STR_1B, IS_TRUE, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_state_t kan_ctrl_get_state(void)
{
    uint32_t reg_rd_val;

    kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);

    uint8_t val = (uint8_t)reg_rd_val;

    if (val & KAN_REG_MASK_OPER_STS_BSY)
        return KAN_STATE_OPER_BSY;
    else if (val & KAN_REG_MASK_OPER_STS_ERR)
        return KAN_STATE_OPER_ERR;
    else if (val & KAN_REG_MASK_OPER_STS_IDL)
    {
        if (kan_ctrl_reg_oper_done())
            return KAN_STATE_OPER_DNE;
        else
            return KAN_STATE_OPER_IDL;
    }
    else
        return KAN_STATE_ITRL_ERR;
}

kan_status_t kan_ctrl_update_layer_stats(kan_layer_handler_t *layer_handler)
{
    kan_status_t status = STATUS_FAILURE;
    uint32_t reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_RSLT_PRG_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->result_progress = reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_ITER_PRG_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->iteration_progress = reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_ITER_TMR_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->iteration_timer = reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_ITER_LAT_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->iteration_latency = reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_TMR_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->operation_timer = reg_rd_val;

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_LAT_4B, &reg_rd_val, WORD);
    if (status != STATUS_OK)
        return STATUS_MEM_READ_ERROR;
    else
        layer_handler->operation_latency = reg_rd_val;

    return status;
}

kan_status_t kan_ctrl_reset_all_layer_stats(kan_network_handler_t *kan_handler)
{
    if (kan_handler == NULL)
        return STATUS_NULL_POINTER_REF;

    kan_layer_handler_t *kan_layer_handler_p = NULL;

    for (int i = 0; i < KAN_LAYERS_NUM; i++)
    {
        kan_layer_handler_p = (kan_handler->kan_layers_handlers + i);

        kan_layer_handler_p->result_progress = 0;
        kan_layer_handler_p->iteration_progress = 0;
        kan_layer_handler_p->iteration_timer = 0;
        kan_layer_handler_p->iteration_latency = 0;
        kan_layer_handler_p->operation_timer = 0;
        kan_layer_handler_p->operation_latency = 0;
    }

    return STATUS_OK;
}

kan_status_t kan_ctrl_print_all_layer_stats(kan_network_handler_t *kan_handler)
{
    if (kan_handler == NULL)
        return STATUS_NULL_POINTER_REF;

    kan_layer_handler_t *kan_layer_handler_p = NULL;

    xil_printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r\n");
    xil_printf("HARDWARE STATUS RESULTS\r\n");

    for (int i = 0; i < KAN_LAYERS_NUM; i++)
    {
        kan_layer_handler_p = (kan_handler->kan_layers_handlers + i);

        xil_printf("~~~~~~~~\r\n");
        xil_printf("LAYER 0\r\n");
        xil_printf("Layer %d : Result Progress    : %lu\r\n", i, kan_layer_handler_p->result_progress);
        xil_printf("Layer %d : Iteration Progress : %lu\r\n", i, kan_layer_handler_p->iteration_progress);
        xil_printf("Layer %d : Iteration Timer    : %lu\r\n", i, kan_layer_handler_p->iteration_timer);
        xil_printf("Layer %d : Iteration Latency  : %lu\r\n", i, kan_layer_handler_p->iteration_latency);
        xil_printf("Layer %d : Operation Timer    : %lu\r\n", i, kan_layer_handler_p->operation_timer);
        xil_printf("Layer %d : Operation Latency  : %lu\r\n", i, kan_layer_handler_p->operation_latency);
    }
    xil_printf("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r\n");

    return STATUS_OK;
}

kan_bool_t kan_ctrl_reg_status_idle(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_IDL, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_busy(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_BSY, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_locked(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_LCK, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_valid(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_VLD, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_reset(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_RST, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_mcu_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_MCU_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_dcu_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_DPU_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_oper_done(void)
{
    uint32_t reg_rd_val = 0;

    kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OPER_DNE_1B, &reg_rd_val, BYTE);
    if (reg_rd_val == 1)
        return IS_TRUE;
    else
        return IS_FALSE;
}

void callback_status_reg(void *intr_handler)
{
    kan_state = kan_ctrl_get_state();

#ifdef DEF_DBG
    xil_printf("CBK : ");

    switch (kan_state)
    {
    case KAN_STATE_OPER_IDL:
        xil_printf("Core state IDLE\r\n");
        break;

    case KAN_STATE_OPER_BSY:
        xil_printf("Core state BUSY\r\n");
        break;

    case KAN_STATE_OPER_ERR:
        xil_printf("Core state ERROR\r\n");
        break;

    case KAN_STATE_OPER_DNE:
        xil_printf("Core state DONE\r\n");
        break;

    case KAN_STATE_ITRL_ERR:
        xil_printf("Core state INTERNAL ERROR\r\n");
        break;

    case KAN_STATE_UNKNOWN:
        xil_printf("Core state UNKNOWN\r\n");
        break;

    default:
        xil_printf("Returned wrong state code\r\n");
        break;
    }
#endif
}

////////////////////////////////////////

kan_status_t kan_ctrl_run_network(kan_network_handler_t *kan_handler, kan_dma_handler_t *dma_handler)
{
    kan_status_t status = STATUS_FAILURE; // function return status

    kan_layer_handler_t *hLayer_p = NULL;

#ifdef DEF_TIME_LAYER
    kan_timer_t start = 0, finish = 0; // used for timing
    double elapsed = 0.;               // used for timing
#endif

    for (uint8_t layer = 0; layer < kan_handler->layers_num; layer++)
    {
#ifdef DEF_TIME_LAYER
        start = 0;
        finish = 0;
        elapsed = 0.;
        kan_timer_get_time(&start);
#endif

#ifdef DEF_VERBOSE
        xil_printf("---\r\n");
        xil_printf("Layer %d\r\n", (int)layer);
#endif

        // downloading data, grid and scale

#ifdef DEF_VERBOSE
        xil_printf("Download data, grid and scale\r\n");
#endif

        hLayer_p = (kan_handler->kan_layers_handlers + layer);

#ifdef DEF_DBG
        dbg_print_metrics(hLayer_p);
#endif

        kan_mem_cpy((void *)(hLayer_p->data_ps_src_addr), (void *)(kan_handler->data_pl_base_addr), (hLayer_p->data_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->grid_ps_src_addr), (void *)(kan_handler->grid_pl_base_addr), (hLayer_p->grid_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->scale_ps_src_addr), (void *)(kan_handler->scale_pl_base_addr), (hLayer_p->scale_num) * sizeof(data_t));

        // configuring PL registers

#ifdef DEF_VERBOSE
        xil_printf("Configure PL registers\r\n");
#endif
        status = kan_config_download2pl(hLayer_p);
        if (status != STATUS_OK)
            return STATUS_EXEC_CONFIC_DOWNLOAD_FAILED;

        kan_config_data_loaded();
        kan_config_grid_loaded();
        kan_config_scale_loaded();

        // starting the DMA transfer of results (RX)

#ifdef DEF_VERBOSE
        xil_printf("Start DMA transfer of results (RX)\r\n");
#endif
        kan_config_weight_loaded(); // !!!!!!!! MIGHT BE WRONG

        status = kan_dma_rx(dma_handler, (hLayer_p->result_ps_dest_addr), (hLayer_p->result_num) * sizeof(data_t));
        if (status != STATUS_OK)
            return STATUS_DMA_RX_FAILURE;

        if (!kan_ctrl_reg_status_valid())
            return STATUS_PL_ERROR;

        // starting the core

#ifdef DEF_VERBOSE
        xil_printf("Start the core\r\n");
#endif

        status = kan_ctrl_start_core();
        if (status != STATUS_OK)
            return STATUS_EXEC_CORE_ERROR;

        if (kan_state == KAN_STATE_OPER_ERR)
            return STATUS_EXEC_CORE_ERROR;

        // starting the DMA transfer of weights (TX)

#ifdef DEF_VERBOSE
        xil_printf("Start DMA transfer of weights (TX)\r\n");
#endif
        status = kan_dma_tx(dma_handler, (hLayer_p->weight_ps_src_addr), (hLayer_p->weight_num) * sizeof(weight_t));
        if (status != STATUS_OK)
            return STATUS_DMA_TX_FAILURE;

        // monitoring the core state

#ifdef DEF_VERBOSE
        xil_printf("Monitor the core state\r\n");
#endif

        if (dma_error_flag == 0)
        {
            while (kan_state == KAN_STATE_OPER_BSY)
            {
                if (kan_ctrl_get_state() == KAN_STATE_OPER_ERR)
                    return STATUS_PL_ERROR;

                if (kan_ctrl_get_state() == KAN_STATE_OPER_IDL)
                    break;

                if (kan_ctrl_get_state() == KAN_STATE_ITRL_ERR)
                    return STATUS_PL_ERROR;

                if (kan_ctrl_get_state() == KAN_STATE_UNKNOWN)
                    return STATUS_PL_ERROR;

                if (dma_error_flag)
                    return STATUS_DMA_ERROR_INTR;

#ifdef DEF_DBG
                count++;
                if (count == countMax)
                {
                    count = 0;
                    dbg_print_metrics(hLayer_p);
                }
#endif
            }
        }
        else
            return STATUS_DMA_ERROR_INTR;

#ifdef DEF_DBG
        dbg_print_status();
#endif

        if (!kan_ctrl_reg_oper_done())
            return STATUS_PL_ERROR;

        // monitoring the DMA

#ifdef DEF_VERBOSE
        xil_printf("Monitor the DMA transfer\r\n");
#endif

        if ((kan_state != KAN_STATE_ITRL_ERR) && (kan_state != KAN_STATE_OPER_ERR))
        {
            while ((dma_rx_done_flag == 0) || (dma_tx_done_flag == 0))
            {
                if (dma_error_flag)
                    return STATUS_DMA_ERROR_INTR;

                if (kan_state == KAN_STATE_OPER_ERR)
                    return STATUS_PL_ERROR;

                if (kan_state == KAN_STATE_ITRL_ERR)
                    return STATUS_PL_ERROR;
            }
            dma_rx_done_flag = 0;
            dma_tx_done_flag = 0;
            dma_error_flag = 0;
        }
        else
            return STATUS_PL_ERROR;

        // report metrics

        status = kan_ctrl_update_layer_stats(hLayer_p);
        if (status != STATUS_OK)
            return STATUS_MEM_READ_ERROR;

#ifdef DEF_DBG
        dbg_print_metrics(hLayer_p);
#endif

        // null the core after completion (soft reset and null operation done reg)

#ifdef DEF_VERBOSE
        xil_printf("Layer done, resetting core\r\n");
#endif

        status = kan_ctrl_soft_reset();
        if (status != STATUS_OK)
            return STATUS_MEM_WRITE_ERROR;

        status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OPER_DNE_1B, NULL_VAL, BYTE);
        if (status != STATUS_OK)
            return STATUS_MEM_WRITE_ERROR;

        // reset interrupt flags

        dma_rx_done_flag = 0;
        dma_tx_done_flag = 0;
        dma_error_flag = 0;
        kan_state = KAN_STATE_UNKNOWN;

#ifdef DEF_TIME_LAYER
        kan_timer_get_time(&finish);
        kan_timer_elapsed_time(start, finish, &elapsed);
        hLayer_p->execution_time = elapsed;
        printf("Layer %u execution time in seconds: %lf\n", (unsigned)layer, elapsed);
#endif
    }

#ifdef DEF_VERBOSE
    xil_printf("---\r\n");
#endif

    return STATUS_OK;
}

#ifdef DEF_DBG
void dbg_print_status(void)
{
    xil_printf("***\r\n");

    kan_status_t status = STATUS_FAILURE;
    kan_state_t state = KAN_STATE_UNKNOWN;
    uint32_t reg_rd_val = 0xFFFFFFFF;

    // read status register value

    xil_printf("DBG : Status Register : ");

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);

    if (status != STATUS_OK)
        xil_printf("Debugger function could not read PL reg\r\n");
    else
        xil_printf("%x\r\n", (void *)reg_rd_val);

    // read operation done register

    xil_printf("DBG : Operation Done Register : ");

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OPER_DNE_1B, &reg_rd_val, BYTE);

    if (status != STATUS_OK)
        xil_printf("Debugger function could not read PL reg\r\n");
    else
        xil_printf("%x\r\n", (void *)reg_rd_val);

    // read interrupt register

    xil_printf("DBG : Interrupt Register : ");

    status = kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_INTR_1B, &reg_rd_val, BYTE);

    if (status != STATUS_OK)
        xil_printf("Debugger function could not read PL reg\r\n");
    else
        xil_printf("%x\r\n", (void *)reg_rd_val);

    // get core state

    state = kan_ctrl_get_state();

    xil_printf("DBG : ");

    switch (state)
    {
    case KAN_STATE_OPER_IDL:
        xil_printf("Core state : IDLE\r\n");
        break;

    case KAN_STATE_OPER_BSY:
        xil_printf("Core state : BUSY\r\n");
        break;

    case KAN_STATE_OPER_ERR:
        xil_printf("Core state : ERROR\r\n");
        break;

    case KAN_STATE_OPER_DNE:
        xil_printf("Core state : DONE\r\n");
        break;

    case KAN_STATE_ITRL_ERR:
        xil_printf("Core state : INTERNAL ERROR\r\n");
        break;

    case KAN_STATE_UNKNOWN:
        xil_printf("Core state : UNKNOWN\r\n");
        break;

    default:
        xil_printf("Returned wrong state code\r\n");
        break;
    }

    // check for mismatch in the state flag

    if (kan_state != kan_ctrl_get_state())
        xil_printf("DBG : mismatch in the state flag and the register state\r\n");

    xil_printf("***\r\n");
}

void dbg_print_metrics(kan_layer_handler_t *hLayer)
{
    xil_printf("***\r\n");
    xil_printf("DBG : Result progress: %lu\r\n", hLayer->result_progress);
    xil_printf("DBG : Iteration progress: %lu\r\n", hLayer->iteration_progress);
    xil_printf("DBG : Iteration timer: %lu\r\n", hLayer->iteration_timer);
    xil_printf("DBG : Iteration latency: %lu\r\n", hLayer->iteration_latency);
    xil_printf("DBG : Operation timer: %lu\r\n", hLayer->operation_timer);
    xil_printf("DBG : Operation latency: %lu\r\n", hLayer->operation_latency);
    xil_printf("***\r\n");
}
#endif