#include "kan_timer.h"

kan_status_t kan_timer_get_time(kan_timer_t *snap)
{
    (*snap) = 0;

    if (snap == NULL)
        return STATUS_NULL_POINTER_REF;

    XTime_GetTime(snap);

    return STATUS_OK;
}

kan_status_t kan_timer_elapsed_time(kan_timer_t start, kan_timer_t finish, double *time_sec)
{
    if (time_sec == NULL)
        return STATUS_NULL_POINTER_REF;

    kan_timer_t elapsed = finish - start;

    (*time_sec) = ((double)elapsed) / COUNTS_PER_SECOND;

    return STATUS_OK;
}