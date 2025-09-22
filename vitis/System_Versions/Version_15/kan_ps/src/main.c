/********************************************
 * Includes
 *******************************************/

// global includes

#include <stdint.h>
#include <stdio.h>

// kan header files

#include "kan_status.h"
#include "kan_defines.h"
#include "kan_config.h"
#include "kan_dma.h"
#include "kan_interrupts.h"
#include "kan_control.h"
#include "kan_timer.h"

// xilinx vitis sdk header files

#include "xil_cache.h"
#include "xil_printf.h"

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

int main(void)
{
    xil_printf("\r\n=============================================================\r\n");
    xil_printf("KAN PROCESSING SYSTEM BARE-METAL APPLICATION\r\n\r\n");

    /*----------------------------------------
     Local variables
    ----------------------------------------*/

    kan_status_t status = STATUS_FAILURE; // function return status

#if defined(DEF_TIME_NETWORK)
    kan_timer_t start = 0, finish = 0;
    double elapsed = 0.;

#ifdef DEF_EXEC_ALL_INPUTS
    double exec_time_total = 0., exec_time_avg = 0.;
#endif

#elif defined(DEF_TIME_LAYER)

#ifdef DEF_EXEC_ALL_INPUTS
    double exec_time_avg[KAN_LAYERS_NUM];
    double exec_time_total[KAN_LAYERS_NUM];
#else
    double exec_time[KAN_LAYERS_NUM];
#endif

#endif

    /*----------------------------------------
     Initializations
    ----------------------------------------*/

#ifdef DEF_VERBOSE
    xil_printf("Disable cache\r\n");
#endif

    Xil_DCacheDisable();

#ifdef DEF_VERBOSE
    xil_printf("Initialize network parameters\r\n");
#endif

    status = kan_config_init(&hKan, hKanLayers, input_data_base_addr, &data_buffer);
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
     Main body of execution
    ----------------------------------------*/

#ifdef DEF_EXEC_ALL_INPUTS
    for (int i = 0; i < KAN_INPUT_DATA_NUM; i++)
    {
        xil_printf("\r\n************************************************\r\n");
        xil_printf("IMAGE %lu EXECUTION\r\n", (unsigned long)i);

        kan_config_update_input(&hKan, input_data_base_addr + (hKan.kan_layers_handlers->data_num));
#else
    xil_printf("\r\n************************************************\r\n");
    xil_printf("IMAGE 0 EXECUTION\r\n");
#endif

        // reset the PL and null interrupt reg - soft reset

#ifdef DEF_VERBOSE
        xil_printf("Soft reset the core before execution\r\n");
#endif

        status = kan_ctrl_soft_reset();
        if (status != STATUS_OK)
            kan_error_handler(status, "Unable to reset the core");

        // execute the network

#ifdef DEF_TIME_NETWORK
        kan_timer_get_time(&start);
#endif

        status = kan_ctrl_run_network(&hKan, &hDma);
        if (status != STATUS_OK)
            kan_error_handler(status, "Execution of the network failed");

#ifdef DEF_TIME_NETWORK
        kan_timer_get_time(&finish);
#endif

        // Execution Results

        kan_ctrl_print_all_layer_stats(&hKan);

#ifdef DEF_EXEC_ALL_INPUTS

#if defined(DEF_TIME_NETWORK)
        kan_timer_elapsed_time(start, finish, &elapsed);
        exec_time_total += elapsed;
#elif defined(DEF_TIME_LAYER)
        for (uint8_t layer = 0; layer < KAN_LAYERS_NUM; layer++)
            exec_time_total[layer] += ((hKan.kan_layers_handlers) + layer)->execution_time;
#endif

        kan_ctrl_reset_all_layer_stats(&hKan);

        xil_printf("************************************************\r\n");
    }

#if defined(DEF_TIME_NETWORK)
    exec_time_avg = exec_time_total / KAN_INPUT_DATA_NUM;
    printf("Whole network average execution time in seconds: %lf\n", exec_time_avg);
#elif defined(DEF_TIME_LAYER)
    for (uint8_t layer = 0; layer < KAN_LAYERS_NUM; layer++)
    {
        exec_time_avg[layer] = exec_time_total[layer] / KAN_INPUT_DATA_NUM;
        printf("Layer %u average execution time in seconds: %lf\n", (unsigned)layer, exec_time_avg[layer]);
    }
#endif

#else

#if defined(DEF_TIME_NETWORK)
    kan_timer_elapsed_time(start, finish, &elapsed);
    printf("Whole network execution time in seconds: %lf\n", elapsed);
#elif defined(DEF_TIME_LAYER)
    for (uint8_t layer = 0; layer < KAN_LAYERS_NUM; layer++)
    {
        exec_time[layer] = ((hKan.kan_layers_handlers) + layer)->execution_time;
        printf("Layer %u execution time in seconds: %lf\n", (unsigned)layer, exec_time[layer]);
    }
#endif

    xil_printf("************************************************\r\n");
#endif

    /*----------------------------------------
     Deallocations and terminations
    ----------------------------------------*/

    // detach all interrupts and null their flags

    status = kan_dma_detach_irq(&hIntrCtr);
    if (status != STATUS_OK)
        kan_error_handler(status, "Could not detach interrupts from DMA engine");

    kan_state = KAN_STATE_UNKNOWN;

    status = kan_intr_detach(&hIntrCtr, INTR_PL_TOP_PS_ID);
    if (status != STATUS_OK)
        kan_error_handler(status, "Could not detach PL2PS interrupts");

    dma_rx_done_flag = 0;
    dma_tx_done_flag = 0;
    dma_error_flag = 0;

    // reset the DMA engine

    status = kan_dma_reset(&hDma);
    if (status != STATUS_OK)
        kan_error_handler(status, "Could not reset DMA engine");

    // free data buffer

    free((void *)data_buffer);

    xil_printf("Application termination\r\n");
    xil_printf("=============================================================\r\n\r\n");

    return STATUS_OK;
}
