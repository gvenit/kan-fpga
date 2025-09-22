#ifndef _KAN_MEMORY_H_
#define _KAN_MEMORY_H_

#include <stdint.h>

#include "kan_defines.h"
#include "kan_status.h"

/**
 * @brief Reads the value of a 32 bit register, usually from the memory mapped devices.
 * Even though it reads an entire 32 bit register,
 * it can read parts of it, byte or half word,
 * by specifying an offset that is not a mutliple of 4
 * and the size.
 *
 * @param base_addr the base register address. Must be a multiple of 4 (word addressable)
 * @param offset from the base address. Non multiple of four implies read of half-word or byte.
 * @param value pointer to a user initialized 32-bit value. Even if you intend to read a byte or half-word this must be a 32-bit value.
 * It is safe to cast it later.
 * @param size the size of the read. Better use the `kan_size_t` enum from `kan_status.h`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 *
 * @warning
 * the pointer to the value is zeroed in the beginning of the call
 */
kan_status_t kan_mem_reg_read(uint32_t base_addr, uint32_t offset, uint32_t *value, kan_size_t size);

/**
 * @brief Writes a value to the 32 bit register, usually from the memory mapped devices.
 * It can write parts of the register, byte or half word,
 * by specifying an offset that is not a mutliple of 4
 * and the size.
 *
 * @param base_addr the base register address. Must be a multiple of 4 (word addressable)
 * @param offset from the base address. Non multiple of four implies write of half-word or byte.
 * @param value to write. Even if you intend to write a byte or half-word this must be a 32-bit value.
 * It will not affect neighbouting register regions.
 * @param size the size of the read. Better use the `kan_size_t` enum from `kan_status.h`
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_mem_reg_write(uint32_t base_addr, uint32_t offset, uint32_t value, kan_size_t size);

/**
 * @brief Function that returns a boolean depending on the state of a single bit.
 * By spoecifying an address and a bitmask (a value strictly a power of two),
 * as well as the size of the mapped register,
 * it returns `IS_TRUE` if the bit is '1' and `IS_FALSE` if the bit is '0'.
 *
 * @param base_addr the base register address. Must be a multiple of 4 (word addressable)
 * @param offset from the base address. Non multiple of four implies write of half-word or byte.
 * @param mask a single bit mask. If it is an integer it has to be a power of two
 * @param size the size of the read. Better use the `kan_size_t` enum from `kan_status.h`
 *
 * @return
 * `IS_TRUE == 1` if the bit is '1' and `IS_FALSE == 0` if the bit is zero
 */
kan_bool_t kan_mem_single_bit_mask(uint32_t base_addr, uint32_t offset, uint32_t mask, kan_size_t size);

/**
 * @brief Copy a contiguous chunk of memory from a source pointer to a destination pointer
 *
 * @param src pointer to the memory source to be copied
 * @param dest pointer to the destination memory location
 * @param size the size of the chunk measured in bytes
 *
 * @return
 * A suitable error code from the `enum Kan_Status` in `kan_status.h`.
 */
kan_status_t kan_mem_cpy(void *src, const void *dest, uint32_t size);

#endif
