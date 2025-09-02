/********************************************
 * Includes
 *******************************************/

// global includes

#include <stdint.h>

// kan header files

#include "kan_build_params.h"
#include "kan_config.h"
#include "kan_defines.h"
#include "kan_dma.h"
#include "kan_interrupts.h"
#include "kan_memory.h"
#include "kan_memory_map.h"
#include "kan_status.h"
#include "kan_control.h"

// xilinx vitis sdk header files

#include "xil_cache.h"
#include "xil_printf.h"

#include "xscugic.h"

/********************************************
 * Local defines
 *******************************************/

#define LOADED_VAL 0x01
#define OPERATION_DONE_VAL 0x01 // !!!!!!!
#define NULL_VAL 0x00

/********************************************
 * Global instances
 *******************************************/

kan_network_handler_t hKan;                     // handler of the entire KAN network
kan_layer_handler_t hKanLayers[KAN_LAYERS_NUM]; // array of handlers for each of the networks layers
kan_data_buff_t data_buffer = NULL;             // buffer that will hold the data packets and the results of each layer

kan_intr_handler_t hIntrCtr; // interrupt controller handler

kan_dma_handler_t hDma; // DMA handler for DMA engine

/********************************************
 * Local functions
 *******************************************/

#ifdef DEF_DBG
uint32_t count = 0;
uint32_t countMax = 1000000;

void dbg_print_status(void);
void dbg_print_metrics(kan_layer_handler_t *hLayer);
#endif

int main(void)
{

    xil_printf("\r\n=============================================================\r\n");
    xil_printf("KAN PROCESSING SYSTEM BARE-METAL APPLICATION\r\n\r\n");

    /*----------------------------------------
     Local variables
    ----------------------------------------*/

    kan_status_t status = STATUS_FAILURE; // function return status

    kan_layer_handler_t *hLayer_p = NULL;

    // uint32_t reg_rd_val = 0;

    /*----------------------------------------
     Disable cache - only data
    ----------------------------------------*/

#ifdef DEF_VERBOSE
    xil_printf("Disable cache\r\n");
#endif

    Xil_DCacheDisable();

    /*----------------------------------------
     Initializations
    ----------------------------------------*/

#ifdef DEF_VERBOSE
    xil_printf("Initialize network parameters\r\n");
#endif

    status = kan_config_init(&hKan, hKanLayers, &data_buffer);
    if (status != STATUS_OK)
        kan_error_handler(status, "Network configuration failed");

#ifdef DEF_VERBOSE
    xil_printf("Initialize interrupts\r\n");
#endif

    status = kan_intr_init(&hIntrCtr, INTR_CONTROLLER_DEVICE_ID);
    if (status != STATUS_OK)
        kan_error_handler(status, "Interrupts configuration failed");

#ifdef DEF_VERBOSE
    xil_printf("Initialize DMA engine\r\n");
#endif

    status = kan_dma_init(&hDma, DMA_DEV_ID);
    if (status != STATUS_OK)
        kan_error_handler(status, "DMA initialization failed");

    /*----------------------------------------
     Interrupt attachments
    ----------------------------------------*/

#ifdef DEF_VERBOSE
    xil_printf("Attach DMA engine interrupts\r\n");
#endif

    status = kan_dma_attach_irq(&hDma, &hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "DMA interrupts attach failed");

#ifdef DEF_VERBOSE
    xil_printf("Attach PL to PS interrupts\r\n");
#endif

    status = kan_intr_attach(&hIntrCtr, INTR_PL_TOP_PS_ID, INTR_DEFAULT_PRIORITY, INTR_TRIGGER_RISING_EDGE, (kan_intr_callback_t)callback_status_reg, (void *)&hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "Failed to attach PL to PS interrupts");

    /*----------------------------------------
     Downloading data to layer
    ----------------------------------------*/

    // reset the PL and null interrupt reg - soft reset

#ifdef DEF_VERBOSE
    xil_printf("Soft reset the core before execution\r\n");
#endif

    status = kan_ctrl_soft_rest();
    if (status != STATUS_OK)
        kan_error_handler(status, "Unable to reset the core");

    // iterating over all layers

    for (uint8_t layer = 0; layer < hKan.layers_num; layer++)
    {
#ifdef DEF_VERBOSE
        xil_printf("---\r\n");
        xil_printf("Layer %d\r\n", (int)layer);
#endif

        // downloading data, grid and scale

#ifdef DEF_VERBOSE
        xil_printf("Download data, grid and scale\r\n");
#endif

        hLayer_p = (hKan.kan_layers_handlers + layer);

#ifdef DEF_DBG
        dbg_print_metrics(hLayer_p);
#endif

        kan_mem_cpy((void *)(hLayer_p->data_ps_src_addr), (void *)(hKan.data_pl_base_addr), (hLayer_p->data_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->grid_ps_src_addr), (void *)(hKan.grid_pl_base_addr), (hLayer_p->grid_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->scale_ps_src_addr), (void *)(hKan.scale_pl_base_addr), (hLayer_p->scale_num) * sizeof(data_t));

        // configuring PL registers

#ifdef DEF_VERBOSE
        xil_printf("Configure PL registers\r\n");
#endif
        status = kan_config_download2pl(hLayer_p);
        if (status != STATUS_OK)
            kan_error_handler(status, "Configuration download to PL failed");

        kan_config_data_loaded();
        kan_config_grid_loaded();
        kan_config_scale_loaded();

        // starting the DMA transfer of weights (RX) and results (TX)

#ifdef DEF_VERBOSE
        xil_printf("Start DMA transfer of weights and results\r\n");
#endif
        status = kan_dma_rx(&hDma, (hLayer_p->result_ps_dest_addr), (hLayer_p->result_num) * sizeof(data_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA rx process of results failed");

        status = kan_dma_tx(&hDma, (hLayer_p->weight_ps_src_addr), (hLayer_p->weight_num) * sizeof(weight_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA tx process of weights failed");

        kan_config_weight_loaded();

        if (!kan_ctrl_reg_status_valid())
            kan_error_handler(STATUS_PL_ERROR, "The configuration was rejected by the PL");

        // strating the core

#ifdef DEF_VERBOSE
        xil_printf("Start the core\r\n");
#endif

        status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STR_1B, IS_TRUE, BYTE);
        if (status != STATUS_OK)
            kan_error_handler(status, "Unable to start the core");

        // monitoring the core state

#ifdef DEF_VERBOSE
        xil_printf("Monitor the core state\r\n");
#endif

        if (dma_error_flag == 0)
        {
            while (kan_state == KAN_STATE_OPER_BSY)
            {
                if (kan_ctrl_get_state() == KAN_STATE_OPER_ERR)
                    kan_error_handler(STATUS_PL_ERROR, "Operation Error in the PL");

                if (kan_ctrl_get_state() == KAN_STATE_ITRL_ERR)
                    kan_error_handler(STATUS_PL_ERROR, "Internal Error in the PL");

                if (kan_ctrl_get_state() == KAN_STATE_UNKNOWN)
                    kan_error_handler(STATUS_PL_ERROR, "The core does nothting");

                if (dma_error_flag)
                    kan_error_handler(STATUS_DMA_ERROR_INTR, "DMA error flag reaised before monitoring the core");

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
            kan_error_handler(STATUS_DMA_ERROR_INTR, "DMA error flag reaised before monitoring the core");

#ifdef DEF_DBG
        dbg_print_status();
#endif

        // THIS MUST BE COMPLETELY WRONG - YOU DO NOT READ THAT YOU WRITE IT
        if (!kan_ctrl_reg_oper_done())
            kan_error_handler(STATUS_PL_ERROR, "DMA transfer complete and the core is not busy anymore but still not done");

        // monitoring the DMA

#ifdef DEF_VERBOSE
        xil_printf("Monitor the DMA transfer\r\n");
#endif

        if ((kan_state != KAN_STATE_ITRL_ERR) && (kan_state != KAN_STATE_OPER_ERR))
        {
            while ((dma_rx_done_flag == 0) || (dma_tx_done_flag == 0))
            {
                if (dma_error_flag)
                    kan_error_handler(STATUS_DMA_ERROR_INTR, "DMA interrupt error flag was raised");

                if (kan_state == KAN_STATE_OPER_ERR)
                    kan_error_handler(STATUS_PL_ERROR, "Operation Error in the PL");

                if (kan_state == KAN_STATE_ITRL_ERR)
                    kan_error_handler(STATUS_PL_ERROR, "Internal Error in the PL");
            }
            dma_rx_done_flag = 0;
            dma_tx_done_flag = 0;
            dma_error_flag = 0;
        }
        else
            kan_error_handler(STATUS_PL_ERROR, "Core in error before monitoring the DMA");

        // report metrics

        status = kan_ctrl_update_layer_stats(hLayer_p);
        if (status != STATUS_OK)
            kan_error_handler(status, "Error in updating KAN statistics");

#ifdef DEF_DBG
        dbg_print_metrics(hLayer_p);
#endif

        // null the core after completion (soft reset and null operation done reg)

#ifdef DEF_VERBOSE
        xil_printf("Layer done, resetting core\r\n");
#endif

        status = kan_ctrl_soft_rest();
        if (status != STATUS_OK)
            kan_error_handler(status, "Unable to reset the core");
        kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OPER_DNE_1B, NULL_VAL, BYTE);

        // detach all interrupts and null their flags

        // status = kan_dma_detach_irq(&hIntrCtr);
        // if (status != STATUS_OK)
        //     kan_error_handler(status, "Could not detach interrupts from DMA engine");

        dma_rx_done_flag = 0;
        dma_tx_done_flag = 0;
        dma_error_flag = 0;

        // status = kan_intr_detach(&hIntrCtr, INTR_PL_TOP_PS_ID);
        // if (status != STATUS_OK)
        //     kan_error_handler(status, "Could not detach PL2PS interrupts");
        // kan_state = KAN_STATE_UNKNOWN;

        // // reset the DMA engine

        // status = kan_dma_reset(&hDma);
        // if (status != STATUS_OK)
        //     kan_error_handler(status, "Could not reset DMA engine");
    }
    xil_printf("---\r\n");

    // deallocation and ternimation

    xil_printf("DBG : Final results:\r\n");
    for (int j = 0; j < KAN_RESULT_FEATURES / DATA_PER_WORD; j++)
        xil_printf("DBG : %x\r\n", (void *)(*(((uint32_t *)data_buffer) + j)));

    xil_printf("Application termination\r\n");
    xil_printf("=============================================================\r\n\r\n");

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
