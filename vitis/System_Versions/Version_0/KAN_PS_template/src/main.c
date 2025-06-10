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

#ifdef DEF_VERBOSE
#include "../../KAN_SoC/ps7_cortexa9_0/standalone_ps7_cortexa9_0/bsp/ps7_cortexa9_0/include/xil_printf.h"
#endif

/********************************************
 * Function decleration
 *******************************************/

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

    /*----------------------------------------
     Initializations
    ----------------------------------------*/

    status = kan_config_init(&hKan, hKanLayers, &data_buffer);
    if (status != STATUS_OK)
        kan_error_handler(status, "Network configuration failed");

    status = kan_intr_init(&hIntrCtr, INTR_CONTROLLER_DEVICE_ID);
    if (status != STATUS_OK)
        kan_error_handler(status, "Interrupts configuration failed");

    status = kan_dma_init_irq(&hDma, DMA_DEV_ID, &hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "DMA with interrupts initialization failed");

#ifdef DATA_BRAM
    status = kan_bram_ctr_init(DATA_BRAM_CONTROLLER_ID, &hDataBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "BRAM controller initialization failed");
#endif
#ifdef GRID_BRAM
    status = bram_init(GRID_BRAM_CONTROLLER_ID, &hGridBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "");
#endif
#ifdef SCALE_BRAM
    status = bram_init(SCALE_BRAM_CONTROLLER_ID, &hScaleBramCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "");
#endif

    //     /*--------------------------------------------
    //      Variables and buffers initialization
    //     ---------------------------------------------*/

    //     // !!!!!!!!!!!!

    //     TxDone = 0;
    //     dma_rx_done_flag = 0;
    //     dma_error_flag = 0;

    //     txBuff = (int32_t *)calloc(sizeof(int32_t), PKT_ELEMENTS);
    //     if (txBuff == NULL)
    //     {
    //         xil_printf("Memory allocation for tx buffer failed\r\n");
    //         return XST_FAILURE;
    //     }

    //     rxBuff = (int32_t *)calloc(sizeof(int32_t), PKT_ELEMENTS);
    //     if (rxBuff == NULL)
    //     {
    //         xil_printf("Memory allocation for rx buffer failed\r\n");
    //         return XST_FAILURE;
    //     }
    //     value = TEST_START_VALUE;

    //     for (i = 0; i < PKT_ELEMENTS; i++)
    //     {
    //         txBuff[i] = value;

    //         value = value + INCR;
    //     }

    //     xil_printf("\r\nRx Buffer before DMA:\r\n");
    //     for (i = 0; i < PKT_ELEMENTS; i++)
    //         xil_printf("Rx[%d] = %d\r\n", i, (int)(rxBuff[i]));
    //     xil_printf("\r\n\r\n");

    //     /*--------------------------------------------
    //      Flush the cache
    //     ---------------------------------------------*/

    //     Xil_DCacheFlushRange((UINTPTR)txBuff, sizeof(int32_t) * PKT_ELEMENTS);
    //     Xil_DCacheFlushRange((UINTPTR)rxBuff, sizeof(int32_t) * PKT_ELEMENTS);

    //     /*--------------------------------------------
    //      Start the DMA transfer
    //     ---------------------------------------------*/

    //     // /* Send a packet */
    //     // for (i = 0; i < NUMBER_OF_TRANSFERS; i++)
    //     // {

    //     status = XAxiDma_SimpleTransfer(&hDma, (UINTPTR)rxBuff, PKT_ELEMENTS * sizeof(int33_t), XAXIDMA_DEVICE_TO_DMA);
    //     if (status != XST_SUCCESS)
    //     {
    //         xil_printf("DMA transmission failed: %d\r\n", status);
    //         return status;
    //     }

    //     status = XAxiDma_SimpleTransfer(&hDma, (UINTPTR)txBuff, PKT_ELEMENTS * sizeof(int32_t), XAXIDMA_DMA_TO_DEVICE);
    //     if (status != XST_SUCCESS)
    //     {
    //         xil_printf("DMA reception failed: %d\r\n", status);
    //         return status;
    //     }

    //     while (!TxDone && !dma_rx_done_flag && !dma_error_flag)
    //     {
    //         /* NOP */
    //     }

    //     if (dma_error_flag)
    //     {
    //         xil_printf("Either transmit or receive failed:\r\n");
    //         xil_printf("receive%s done\r\n",
    //                    TxDone ? "" : " not",
    //                    dma_rx_done_flag ? "" : " not");
    //         return XST_FAILURE; // maybe this is too much - in the next iteration it might get it right
    //     }

    //     // status = CheckData(rxBuff, PKT_ELEMENTS, TEST_START_VALUE);
    //     // if (status != XST_SUCCESS)
    //     // {
    //     //     xil_printf("Data check failed\r\n");
    //     //     return status;
    //     // }
    //     // }

    //     // xil_printf("Successfully ran AXI DMA interrupt Example\r\n");

    //     xil_printf("\r\nRx Buffer after DMA:\r\n");
    //     for (i = 0; i < PKT_ELEMENTS; i++)
    //         xil_printf("Rx[%d] = %d\r\n", i, (int)(rxBuff[i]));
    //     xil_printf("\r\n\r\n");

    //     /*--------------------------------------------
    //      Disable DMA interrupts
    //     ---------------------------------------------*/

    //     intr_disable(&hIntrCtr, TX_INTR_ID, RX_INTR_ID);

    //     /*--------------------------------------------
    //      Memory deallocation
    //     ---------------------------------------------*/

    //     free(txBuff);
    //     free(rxBuff);

    //     xil_printf("\r\n-----------------------------------------------------------------------\r\n");
    //     xil_printf("\t END OF EXAMPLE \r\n");
    //     xil_printf("-----------------------------------------------------------------------\r\n");

    return STATUS_OK;
}
