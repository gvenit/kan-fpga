#ifndef _KAN_STATUS_H_
#define _KAN_STATUS_H_

#include "kan_defines.h"

#include "xstatus.h"

#ifdef DEF_VERBOSE
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
    STATUS_INTR_ATTACH_FAILURE
} kan_status_t;

#ifdef DEF_VERBOSE
#define kan_error_handler(code, msg)                              \
    do                                                            \
    {                                                             \
        switch (code)                                             \
        {                                                         \
        case STATUS_OK:                                           \
            xil_printf("Call returned error: %d\r\n", STATUS_OK); \
            xil_printf("%s\r\n", msg);                            \
            break;                                                \
        default:                                                  \
            xil_printf("Unhandled error code: %d\r\n", code);     \
            xil_printf("%s\r\n", msg);                            \
            break;                                                \
        }                                                         \
        return code;                                              \
    } while (0)
#else
#define kan_error_handler(code, msg) return code;
#endif

#endif