#include "kan_memory.h"

kan_status_t kan_mem_reg_read(uint32_t base_addr, uint32_t offset, uint32_t *value, kan_size_t size)
{
    uint32_t offset_inword = offset % WORD;
    uint32_t offset_words = offset - offset_inword;

    (*value) = 0;
    (*value) = *((volatile uint32_t *)(base_addr + offset_words));

    (*value) >>= offset_inword * 8;

    switch (size)
    {
    case BYTE:
        (*value) &= 0x000000FF;
        break;

    case HALF_WORD:
        (*value) &= 0x0000FFFF;
        break;

    case WORD:
        break;

    default:
        return STATUS_ILLEGAL_ARG;
        break;
    }

    return STATUS_OK;
}

kan_status_t kan_mem_reg_write(uint32_t base_addr, uint32_t offset, uint32_t value, kan_size_t size)
{
    uint32_t offset_inword = offset % WORD;
    uint32_t offset_words = offset - offset_inword;

    volatile uint32_t *addr = (volatile uint32_t *)(base_addr + offset_words);

    uint32_t old_val = *((volatile uint32_t *)(base_addr + offset_words));
    uint32_t new_val = value;

    uint32_t bitmask = 0;

    switch (size)
    {
    case BYTE: // !!!!!
        bitmask = 0x000000FF;
        bitmask <<= offset_inword * 8;
        new_val <<= offset_inword * 8;
        old_val &= (~bitmask);
        new_val |= old_val;
        break;

    case HALF_WORD: // !!!!!
        bitmask = 0x0000FFFF;
        bitmask <<= offset_inword * 8;
        new_val <<= offset_inword * 8;
        old_val &= (~bitmask);
        new_val |= old_val;
        break;

    case WORD:
        break;

    default:
        return STATUS_ILLEGAL_ARG;
        break;
    }

    (*addr) = new_val;

    return STATUS_OK;
}

kan_bool_t kan_mem_single_bit_mask(uint32_t base_addr, uint32_t offset, uint32_t mask, kan_size_t size)
{
    uint32_t offset_inword = offset % WORD;
    uint32_t offset_words = offset - offset_inword;
    uint32_t value = 0;

    value = *((volatile uint32_t *)(base_addr + offset_words));

    value >>= offset_inword * 8;

    switch (size)
    {
    case BYTE:
        value &= 0x000000FF;
        mask &= 0x000000FF;
        value &= mask;
        break;

    case HALF_WORD:
        value &= 0x0000FFFF;
        mask &= 0x0000FFFF;
        value &= mask;
        break;

    case WORD:
        value &= mask;
        break;

    default:
        return STATUS_ILLEGAL_ARG;
        break;
    }

    if (value != 0)
        return IS_TRUE;
    else
        return IS_FALSE;
}

kan_status_t kan_mem_cpy(void *src, const void *dest, uint32_t size)
{
    if (src == NULL || dest == NULL || size == 0)
        return STATUS_ILLEGAL_ARG;

    const uint8_t *s = (const uint8_t *)src;
    uint8_t *d = (uint8_t *)dest;
    uint8_t val = 0;

    while (size--)
    {
        // *d++ = *s++;
        val = *s;
        (*d) = val;
        s++;
        d++;
    }

    return STATUS_OK;
}
