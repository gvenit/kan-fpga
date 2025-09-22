#ifndef _KAN_TIMER_H_
#define _KAN_TIMER_H_

#include <xtime_l.h>

#include "kan_status.h"

/**
 * @brief timer variable pointer type
 */
typedef XTime kan_timer_t;

/**
 * @brief Takes a snap of time
 */
kan_status_t kan_timer_get_time(kan_timer_t *snap);

/**
 * @brief Calculates elapsed time in seconds
 */
kan_status_t kan_timer_elapsed_time(kan_timer_t start, kan_timer_t finish, double *time_sec);

#endif