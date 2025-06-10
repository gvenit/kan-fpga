#include "kan_memory.h"

kan_status_t kan_mem_reg_read(uint32_t base_addr, uint32_t offset, uint32_t *value, kan_size_t size)
{
    uint32_t offset_inword = offset % WORD;
    uint32_t offset_words = offset - offset_inword;

    (*value) = *((volatile uint32_t *)(base_addr + offset_words));

    (*value) >>= offset_inword * 8;

    switch (size)
    {
    case BYTE:
        (*value) &= 0x000F;
        break;

    case HALF_WORD:
        (*value) &= 0x00FF;
        break;

    case WORD:
        break;

    default:
        return STATUS_ILLEGAL_ARG;
        break;
    }

    return STATUS_OK;
}

kan_status_t kan_mem_write_reg(uint32_t base_addr, uint32_t offset, uint32_t value, kan_size_t size)
{
    uint32_t offset_inword = offset % WORD;
    uint32_t offset_words = offset - offset_inword;

    volatile uint32_t *addr = (volatile uint32_t *)(base_addr + offset_words);

    uint32_t old_val = *((volatile uint32_t *)(base_addr + offset_words));
    uint32_t new_val = value;

    uint32_t bitmask = 0;

    switch (value)
    {
    case BYTE:
        bitmask = 0x000F;
        bitmask <<= offset_inword * 8;
        new_val <<= offset_inword * 8;
        old_val &= (~bitmask);
        new_val |= old_val;
        break;

    case HALF_WORD: // !!!!!
        bitmask = 0x00FF;
        bitmask <<= offset_inword * 8;
        new_val <<= offset_inword * 8;
        old_val &= (~bitmask);
        new_val |= old_val;
        break;

    case WORD:
        new_val = old_val;
        break;

    default:
        return STATUS_ILLEGAL_ARG;
        break;
    }

    (*addr) = new_val;

    return STATUS_OK;
}
