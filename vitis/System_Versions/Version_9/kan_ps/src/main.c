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
#include "kan_registers.h"

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
void dbg_print_pl_status_regs(void);
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

    uint32_t reg_rd_val = 0;

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
    xil_printf("Attach PL to PS interrupts\r\n");
#endif

#ifdef DEF_DBG
    dbg_print_pl_status_regs();
#endif
    status = kan_intr_attach(&hIntrCtr, INTR_PL_TOP_PS_ID, INTR_DEFAULT_PRIORITY, INTR_TRIGGER_RISING_EDGE, (kan_intr_callback_t)callback_status_reg, (void *)&hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "Failed to attach PL to PS interrupts");
#ifdef DEF_DBG
    dbg_print_pl_status_regs();
#endif

#ifdef DEF_VERBOSE
    xil_printf("Initialize DMA engine\r\n");
#endif

    status = kan_dma_init(&hDma, DMA_DEV_ID);
    if (status != STATUS_OK)
        kan_error_handler(status, "DMA initialization failed");

    /*----------------------------------------
     Downloading data to layer
    ----------------------------------------*/

    // reset the PL - soft reset

#ifdef DEF_VERBOSE
    xil_printf("Soft reset the core before execution\r\n");
#endif

    kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, CTRL_REG_MASK_INTR_SFT_1B, BYTE);
    kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, NULL_VAL, BYTE);

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

        kan_mem_cpy((void *)(hLayer_p->data_ps_src_addr), (void *)(hKan.data_pl_base_addr), (hLayer_p->data_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->grid_ps_src_addr), (void *)(hKan.grid_pl_base_addr), (hLayer_p->grid_num) * sizeof(data_t));
        kan_mem_cpy((void *)(hLayer_p->scale_ps_src_addr), (void *)(hKan.scale_pl_base_addr), (hLayer_p->scale_num) * sizeof(data_t));

        // configuring PL registers

#ifdef DEF_VERBOSE
        xil_printf("Configure PL registers\r\n");
#endif

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_DATA_LEN_4B, (uint32_t)(hLayer_p->data_num) / KAN_CHANNELS_DATA, WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_GRID_LEN_4B, (uint32_t)(hLayer_p->grid_num) / KAN_CHANNELS_GRID, WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_SCLE_LEN_4B, (uint32_t)(hLayer_p->scale_num) / KAN_CHANNELS_SCALE, WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_RSLT_LEN_4B, (uint32_t)(hLayer_p->result_num), WORD);

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_PCKT_LEN_4B, (uint32_t)(((hLayer_p->data_num) / (KAN_CHANNELS_DATA)) * ((hLayer_p->grid_num) / (KAN_CHANNELS_GRID))), WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_BTCH_LEN_1B, 0x00000001, BYTE);

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_DATA_LDR_1B, IS_TRUE, BYTE);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_GRID_LDR_1B, IS_TRUE, BYTE);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_SCLE_LDR_1B, IS_TRUE, BYTE);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_WGHT_LDR_1B, IS_TRUE, BYTE);

        if (!kan_reg_status_valid())
            kan_error_handler(STATUS_PL_ERROR, "The configuration was rejected by the PL");

        // strating the DMA transfer of weights (RX) and results (TX)

#ifdef DEF_VERBOSE
        xil_printf("Start DMA transfer of weights and results\r\n");
#endif

        status = kan_dma_attach_irq(&hDma, &hIntrCtr);
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA interrupts attach failed");

        status = kan_dma_rx(&hDma, (hLayer_p->result_ps_dest_addr), (hLayer_p->result_num) * sizeof(data_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA rx process of results failed");

        status = kan_dma_tx(&hDma, (hLayer_p->weight_ps_src_addr), (hLayer_p->weight_num) * sizeof(weight_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA tx process of weights failed");

        // strating the core

#ifdef DEF_VERBOSE
        xil_printf("Start the core\r\n");
#endif

        status = kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STR_1B, IS_TRUE, BYTE);
        if (status != STATUS_OK)
            kan_error_handler(status, "Unable to start the core");

        // monitoring the PL and the DMA

#ifdef DEF_VERBOSE
        xil_printf("Monitor the core...\r\n");
#endif

#ifdef DEF_DBG
        dbg_print_pl_status_regs();
#endif

        while (!dma_rx_done_flag && !dma_tx_done_flag)
        {
            if (dma_error_flag)
                kan_error_handler(STATUS_DMA_ERROR_INTR, "DMA interrupt error flag was raised");

            if (kan_reg_status_error())
                kan_error_handler(STATUS_PL_ERROR, "Operation error. locked core awaiting soft/hard reset");

            if (kan_reg_status_reset())
                kan_error_handler(STATUS_PL_ERROR, "PL reset on its own");

            if (kan_reg_status_locked())
            {
                kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OPER_DNE, &reg_rd_val, BYTE);
                if (reg_rd_val != OPERATION_DONE_VAL)
                    kan_error_handler(STATUS_PL_ERROR, "Core locked but operation not done");
                else
                    continue;
            }
            else if (kan_reg_status_busy() || kan_reg_status_idle() || kan_reg_status_valid())
                continue;
            else
            {
                kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);
                kan_error_handler(reg_rd_val, "Unkown value on the operation status register. It is the one returned above");
            }
        }

        dma_rx_done_flag = 0;
        dma_tx_done_flag = 0;

#ifdef DEF_DBG
        dbg_print_pl_status_regs();
#endif

        kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OPER_DNE, &reg_rd_val, BYTE);
        if (reg_rd_val != IS_TRUE)
            kan_error_handler(STATUS_PL_ERROR, "DMA transfer complete but the core is not ready");

        // report metrics

        // null the core after completion (soft reset and null operation done reg)

#ifdef DEF_VERBOSE
        xil_printf("Layer done, resetting core\r\n");
#endif

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, CTRL_REG_MASK_INTR_SFT_1B, BYTE);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OPER_DNE, NULL_VAL, BYTE);

        status = kan_dma_detach_irq(&hIntrCtr);
        if (status != STATUS_OK)
            kan_error_handler(status, "Could not detach interrupts from DMA engine");
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
void dbg_print_pl_status_regs(void)
{
    kan_status_t status = STATUS_FAILURE;
    uint32_t reg_rd_val = 0xFFFFFFFF;

    xil_printf("DBG : status reg value : ");

    status = kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);

    if (status != STATUS_OK)
        xil_printf("Debugger function could not read PL reg\r\n");
    else
        xil_printf("Operation status register: %x\r\n", (void *)reg_rd_val);
}
#endif
