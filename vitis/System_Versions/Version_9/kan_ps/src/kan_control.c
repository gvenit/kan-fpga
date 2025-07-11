#include "kan_control.h"

volatile kan_state_t kan_state = KAN_STATE_UNKNOWN;

kan_bool_t kan_ctrl_reg_status_idle(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_IDL, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_busy(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_BSY, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_locked(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_LCK, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_valid(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_VLD, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_reset(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_OPER_STS_1B, CTRL_REG_MASK_OPER_STS_RST, BYTE);

    return bool_val;
}

////////////////////////////////////////////////////////////////////////////////

kan_status_t kan_ctrl_soft_rest(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, CTRL_REG_MASK_INTR_SFT_1B, BYTE);
    if (status != STATUS_OK)
        return status;

    status = kan_mem_reg_write(CTRL_REG_BASE_ADDRESS, CTRL_REG_OFST_INTR_1B, 0x00000000, BYTE);

    return status;
}

kan_bool_t kan_ctrl_reg_oper_done(void)
{
    uint32_t reg_rd_val = 0;

    kan_mem_reg_read(CTRL_REG_BASE_ADDRESS, CTRL_REG_OPER_DNE, &reg_rd_val, BYTE);
    if (reg_rd_val == 1)
        return IS_TRUE;
    else
        return IS_FALSE;
}

kan_state_t kan_ctrl_get_state(void)
{
    if (kan_ctrl_reg_status_busy())
        return KAN_STATE_OPER_BSY;
    else if (kan_ctrl_reg_status_error())
        return KAN_STATE_OPER_ERR;
    else if (kan_ctrl_reg_status_idle())
    {
        if (kan_ctrl_reg_oper_done())
            return KAN_STATE_OEPR_DNE;
        else
            return KAN_STATE_OPER_IDL;
    }
    else
        return KAN_STATE_ITRL_ERR;
}

void callback_status_reg(void *intr_handler)
{
    kan_state = kan_ctrl_get_state();
}

////////////////////////////////////////////////////////////////////////////////
