#include "kan_registers.h"

volatile int reg_status_idle_flag = 0;
volatile int reg_status_busy_flag = 0;
volatile int reg_status_error_flag = 0;
volatile int reg_status_locked_flag = 0;

kan_bool_t kan_reg_status_idle(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_IDL, BYTE);

    return bool_val;
}

kan_bool_t kan_reg_status_busy(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_BSY, BYTE);

    return bool_val;
}

kan_bool_t kan_reg_status_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_reg_status_locked(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_LCK, BYTE);

    return bool_val;
}

kan_bool_t kan_reg_status_valid(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_VLD, BYTE);

    return bool_val;
}

kan_bool_t kan_reg_status_reset(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_RST, BYTE);

    return bool_val;
}

void callback_status_reg(void *intr_handler)
{
    xil_printf("IN\r\n");

    if (kan_reg_status_idle())
        reg_status_idle_flag = 1;

    if (kan_reg_status_busy())
        reg_status_busy_flag = 1;

    if (kan_reg_status_error())
        reg_status_error_flag = 1;

    if (kan_reg_status_locked())
        reg_status_locked_flag = 1;
}
