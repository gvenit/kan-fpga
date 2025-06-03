#ifndef _BUILD_PARAMS_H_
#define _BUILD_PARAMS_H_

/**
 * used datatype
 *
 * This is the datatype of a single packet internal to the design.
 * There are also defines regarding its size
 * and the memory addressing
 */

typedef uint16_t data_t; // the type of a single packet

#define DATUM_SIZE sizeof(data_t)                     // number if bytes for each datum
#define DATA_PER_WORD (sizeof(uint32_t) / DATUM_SIZE) // every word is 32 bits and this calculates how many bytes it fits
#define BYTE_OFFSET 0x04                              // offset of a 32-bit word in memory
#define HALD_WORD_OFFSET 0x02                         // offset of a 16-bit word in memory
#define WORD_OFFSET 0x01                              // offset of a 8-bit word in memory

/**
 * uncomment for BRAM interfaces - else it uses axil
 *
 * WARNING : it has to match with the platform or you will get errors
 */

#define DATA_BRAM
#define SCALE_BRAM
#define GRID_BRAM

#ifndef DATA_BRAM
#define DATA_AXIL
#else
#endif

#ifndef SCALE_BRAM
#define SCALE_AXIL
#endif

#ifndef GRID_BRAM
#define GRID_AXIL
#endif

#if defined(DATA_BRAM) || defined(SCALE_BRAM) || defined(GRID_BRAM)
#define BRAM_INTRF
#endif

#endif