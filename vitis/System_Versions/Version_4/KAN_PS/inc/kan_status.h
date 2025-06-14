#ifndef _KAN_STATUS_H_
#define _KAN_STATUS_H_

#include "kan_defines.h"
#include "xstatus.h"

#ifdef DEF_VERBOSE
// #include "xil_printf.h"
#include "xil_printf.h"
#endif

/*===========================================================================
    Auxiliary type definitions
============================================================================*/

typedef enum
{
    IS_FALSE = 0,
    IS_TRUE = 1
} kan_bool_t;

typedef enum
{
    BYTE = 1,      // Single byte. 8-bits
    HALF_WORD = 2, // Two bytes. 16-bits
    WORD = 4       // Four bytes. 32-bits
} kan_size_t;

/*===========================================================================
    Error Handling and return status of functions
============================================================================*/

/**
 * @brief Return type for
 * the header files of this project.
 * Compatible with `xstatus.h`
 */
typedef enum Kan_Status
{
    STATUS_OK = XST_SUCCESS,
    STATUS_FAILURE = XST_FAILURE,
    STATUS_ILLEGAL_ARG,
    STATUS_NULL_POINTER_REF,
    STATUS_MALLOC_FAIL,
    STATUS_INTR_INIT_FAILURE,
    STATUS_INTR_ATTACH_FAILURE,
    STATUS_DMA_INIT_FAILURE,
    STATUS_DMA_TX_FAILURE,
    STATUS_DMA_RX_FAILURE,
    STATUS_DMA_ERROR_INTR,
    STATUS_BRAMC_INIT_FAILURE,
    STATUS_PL_ERROR
} kan_status_t;

#ifdef DEF_VERBOSE
#define kan_error_handler(code, msg)                                           \
    do                                                                         \
    {                                                                          \
        switch (code)                                                          \
        {                                                                      \
        case STATUS_FAILURE:                                                   \
            xil_printf("Call returned error: STATUS_FAILURE\r\n");             \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_ILLEGAL_ARG:                                               \
            xil_printf("Call returned error: STATUS_ILLEGAL_ARG\r\n");         \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_NULL_POINTER_REF:                                          \
            xil_printf("Call returned error: STATUS_NULL_POINTER_REF\r\n");    \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_MALLOC_FAIL:                                               \
            xil_printf("Call returned error: STATUS_MALLOC_FAIL\r\n");         \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_INTR_INIT_FAILURE:                                         \
            xil_printf("Call returned error: STATUS_INTR_INIT_FAILURE\r\n");   \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_INTR_ATTACH_FAILURE:                                       \
            xil_printf("Call returned error: STATUS_INTR_ATTACH_FAILURE\r\n"); \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_DMA_INIT_FAILURE:                                          \
            xil_printf("Call returned error: STATUS_DMA_INIT_FAILURE\r\n");    \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_DMA_TX_FAILURE:                                            \
            xil_printf("Call returned error: STATUS_DMA_TX_FAILURE\r\n");      \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_DMA_RX_FAILURE:                                            \
            xil_printf("Call returned error: STATUS_DMA_RX_FAILURE\r\n");      \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_DMA_ERROR_INTR:                                            \
            xil_printf("Call returned error: STATUS_DMA_ERROR_INTR\r\n");      \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_BRAMC_INIT_FAILURE:                                        \
            xil_printf("Call returned error: STATUS_BRAMC_INIT_FAILURE\r\n");  \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        case STATUS_PL_ERROR:                                                  \
            xil_printf("Call returned error: STATUS_PL_ERROR\r\n");            \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        default:                                                               \
            xil_printf("Unhandled error code: %d\r\n", code);                  \
            xil_printf("%s\r\n", msg);                                         \
            break;                                                             \
        }                                                                      \
        return code;                                                           \
    } while (0)
#else
#define kan_error_handler(code, msg) return code;
#endif

#endif
