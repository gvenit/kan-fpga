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

#ifdef BRAM_CTR
#include "kan_bram_controller.h"
#endif

// xilinx vitis sdk header files

#include "xil_cache.h"

#ifdef DEF_VERBOSE
#include "xil_printf.h"
#endif

/********************************************
 * Local defines
 *******************************************/

#define LOADED_VAL 0x01
#define OPERATION_DONE_VAL 0x01

/********************************************
 * Global instances
 *******************************************/

kan_network_handler_t hKan;                     // handler of the entire KAN network
kan_layer_handler_t hKanLayers[KAN_LAYERS_NUM]; // array of handlers for each of the networks layers
kan_data_buff_t data_buffer = NULL;             // buffer that will hold the data packets and the results of each layer

XScuGic hIntrCtr; // interrupt controller handler

XAxiDma hDma; // DMA handler for DMA engine

#ifdef DATA_BRAM
XBram hDataBramCtr; // data bram controller handler
#endif
#ifdef GRID_BRAM
XBram hGridBramCtr; // grid bram controller handler;
#endif
#ifdef SCALE_BRAM
XBram hScaleBramCtr; // scale bram controller handler
#endif

int main(void)
{

#ifdef DEF_VERBOSE
    xil_printf("=============================================================\r\n");
    xil_printf("KAN Processing System Bare-Metal Application\r\n");
#endif

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
    xil_printf("Initialize dma engine\r\n");
#endif

    status = kan_dma_init_irq(&hDma, DMA_DEV_ID, &hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "DMA with interrupts initialization failed");

#ifdef DATA_BRAM
#ifdef DEF_VERBOSE
    xil_printf("Initialize data bram controller\r\n");
#endif

    status = kan_bram_ctr_init(DATA_BRAM_CONTROLLER_ID, &hDataBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "BRAM controller initialization failed");
#endif
#ifdef GRID_BRAM
#ifdef DEF_VERBOSE
    xil_printf("Initialize grid bram controller\r\n");
#endif

    status = bram_init(GRID_BRAM_CONTROLLER_ID, &hGridBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "");
#endif
#ifdef SCALE_BRAM
#ifdef DEF_VERBOSE
    xil_printf("Initialize scale bram controller\r\n");
#endif

    status = bram_init(SCALE_BRAM_CONTROLLER_ID, &hScaleBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "");
#endif

    /*----------------------------------------
     Downloading data to layer
    ----------------------------------------*/

    // reset the PL - soft reset

#ifdef DEF_VERBOSE
    xil_printf("Soft reset the core before execution\r\n");
#endif

    kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, CTRL_REG_MASK_INTR_SFT_1B, BYTE);

    // iterating over all layers

    for (uint8_t layer = 0; layer < hKan.layers_num; layer++)
    {
#ifdef DEF_VERBOSE
        xil_printf("---\r\n");
        xil_printf("Layer %d\r\n", (int)layer);
#endif

        // configuring PL registers

#ifdef DEF_VERBOSE
        xil_printf("Configure PL registers\r\n");
#endif

        hLayer_p = (hKan.kan_layers_handlers + layer);

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_DATA_LEN_4B, (uint32_t)(hLayer_p->data_num), WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_GRID_LEN_4B, (uint32_t)(hLayer_p->grid_num), WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_SCLE_LEN_4B, (uint32_t)(hLayer_p->scale_num), WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_RSLT_LEN_4B, (uint32_t)(hLayer_p->result_num), WORD);

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_PCKT_LEN_4B, (uint32_t)(hLayer_p->data_num * hLayer_p->grid_num), WORD);
        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_BTCH_LEN_1B, 0xFFFFFFFF, BYTE); // !!!!!!!! not sure what goes here

        kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);
        if (reg_rd_val != CTRL_REG_MASK_OPER_STS_VLD)
            kan_error_handler(STATUS_PL_ERROR, "The configuration was rejected by the PL");

        // dwonloading data, grid and scale

#ifdef DEF_VERBOSE
        xil_printf("Download data, grid and scale\r\n");
#endif

        kan_mem_cpy((void *)(hLayer_p->data_ps_src_addr), (void *)(hKan.data_pl_base_addr), (hLayer_p->data_num) * sizeof(data_t));
        do
        {
            kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_DATA_LDR_1B, &reg_rd_val, BYTE);
        } while (reg_rd_val != LOADED_VAL);

        kan_mem_cpy((void *)(hLayer_p->grid_ps_src_addr), (void *)(hKan.grid_pl_base_addr), (hLayer_p->grid_num) * sizeof(data_t));
        do
        {
            kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_GRID_LDR_1B, &reg_rd_val, BYTE);
        } while (reg_rd_val != LOADED_VAL);

        kan_mem_cpy((void *)(hLayer_p->scale_ps_src_addr), (void *)(hKan.scale_pl_base_addr), (hLayer_p->scale_num) * sizeof(data_t));
        do
        {
            kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_SCLE_LDR_1B, &reg_rd_val, BYTE);
        } while (reg_rd_val != LOADED_VAL);

        // strating the DMA transfer of weights (RX) and results (TX)

#ifdef DEF_VERBOSE
        xil_printf("Start DMA transfer of weights and results\r\n");
#endif

        status = kan_dma_rx(&hDma, data_buffer, (hLayer_p->result_num) * sizeof(data_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA rx process of results failed");

        status = kan_dma_tx(&hDma, data_buffer, (hLayer_p->weight_num) * sizeof(data_t));
        if (status != STATUS_OK)
            kan_error_handler(status, "DMA tx process of weights failed");

        // monitoring the PL and the DMA

#ifdef DEF_VERBOSE
        xil_printf("Monitor the core...\r\n");
#endif

        while (!dma_rx_done_flag && !dma_rx_done_flag)
        {
            if (dma_error_flag)
                kan_error_handler(STATUS_DMA_ERROR_INTR, "DMA interrupt error flag was raised");

            kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, &reg_rd_val, BYTE);

            switch (reg_rd_val)
            {
            case CTRL_REG_MASK_OPER_STS_IDL:
                break;

            case CTRL_REG_MASK_OPER_STS_BSY:
                break;

            case CTRL_REG_MASK_OPER_STS_LCK:
                break;

            case CTRL_REG_MASK_OPER_STS_VLD:
                break;

            case CTRL_REG_MASK_OPER_STS_ERR:
                kan_error_handler(STATUS_PL_ERROR, "Operation error. locked core awaiting soft/hard reset");
                break;

            case CTRL_REG_MASK_OPER_STS_RST:
                kan_error_handler(STATUS_PL_ERROR, "PL reset on its own");
                break;

            default:
                kan_error_handler(reg_rd_val, "Unkown value ont the operation status register. It is the one returned above");
                break;
            }
        }

        kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OPER_DNE, &reg_rd_val, BYTE);
        if (reg_rd_val != OPERATION_DONE_VAL)
            kan_error_handler(STATUS_PL_ERROR, "DMA transfer complete but the core is not ready");

        // report metrics

        // null the core after completion

#ifdef DEF_VERBOSE
        xil_printf("Layer done, resetting core\r\n");
#endif

        kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, CTRL_REG_MASK_INTR_SFT_1B, BYTE);
    }

    // deallocation and ternimation

#ifdef DEF_VERBOSE
    xil_printf("---\r\n");
    xil_printf("Application termination\r\n");
    xil_printf("=============================================================\r\n");
#endif

    return STATUS_OK;
}
