#include "dataset_weight.h"

/**
 * @warning Normally based on the sizes and the linker script
 * this array should have 42008576 (42.008.576) elements which makes
 * everything EXTREMELY slow. I would not push such thing on the repo
 */
__attribute__((section(".dataset_weight"), aligned(4), used))
data_t weightArray[] = {
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42,
    42};
