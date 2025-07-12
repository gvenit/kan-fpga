#include "kan_control.h"

volatile int kan_state = KAN_STATE_UNKNOWN;

kan_bool_t kan_ctrl_reg_status_idle(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_IDL, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_busy(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_BSY, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_error(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_ERR, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_locked(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_LCK, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_valid(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_VLD, BYTE);

    return bool_val;
}

kan_bool_t kan_ctrl_reg_status_reset(void)
{
    kan_bool_t bool_val = IS_FALSE;

    bool_val = kan_mem_single_bit_mask(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_OPER_STS_1B, KAN_REG_MASK_OPER_STS_RST, BYTE);

    return bool_val;
}

////////////////////////////////////////////////////////////////////////////////

kan_status_t kan_ctrl_soft_rest(void)
{
    kan_status_t status = STATUS_FAILURE;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_INTR_1B, KAN_REG_MASK_INTR_SFT_1B, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    status = kan_mem_reg_write(KAN_REG_BASE_ADDRESS, KAN_REG_OFST_INTR_1B, 0x00000000, BYTE);
    if (status != STATUS_OK)
        return STATUS_MEM_WRITE_ERROR;

    return status;
}

kan_bool_t kan_ctrl_reg_oper_done(void)
{
    uint32_t reg_rd_val = 0;

    kan_mem_reg_read(KAN_REG_BASE_ADDRESS, KAN_REG_OPER_DNE_1B, &reg_rd_val, BYTE);
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

    xil_printf("CBK : ");

    switch (kan_state)
    {
    case KAN_STATE_OPER_IDL:
        xil_printf("Core state IDLE\r\n");
        break;

    case KAN_STATE_OPER_BSY:
        xil_printf("Core state BUSY\r\n");
        break;

    case KAN_STATE_OPER_ERR:
        xil_printf("Core state ERROR\r\n");
        break;

    case KAN_STATE_OEPR_DNE:
        xil_printf("Core state DONE\r\n");
        break;

    case KAN_STATE_ITRL_ERR:
        xil_printf("Core state INTERNAL ERROR\r\n");
        break;

    case KAN_STATE_UNKNOWN:
        xil_printf("Core state UNKNOWN\r\n");
        break;

    default:
        xil_printf("Returned wrong state code\r\n");
        break;
    }
}

////////////////////////////////////////////////////////////////////////////////
