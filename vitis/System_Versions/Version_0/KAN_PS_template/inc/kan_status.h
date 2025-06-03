#ifndef _KAN_STATUS_H_
#define _KAN_STATUS_H_

#include "kan_defines.h"

#include "xstatus.h"

#ifdef DEF_VERBOSE
#include "xil_printf.h"
#endif

/**
 * @brief Return type for
 * the header files of this project.
 * Compatible with `xstatus.h`
 */
typedef enum
{
    STATUS_OK = XST_SUCCESS,
    STATUS_FAILURE = XST_FAILURE
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