#ifndef __FILE_UTILS_H__
#define __FILE_UTILS_H__

/********************************************
 * Lihbrary includes
 ********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>

/********************************************
 * Parameter defines / customs
 ********************************************/

// the user specifies here which datatype they use
typedef uint16_t data_t;

/********************************************
 * Function Declarations
 ********************************************/

/**
 * Save the values of a data buffer
 * into a raw binary file
 *
 * @warning the array must be initiallized
 * and the correct size passed as argument
 *
 * @param filename the name of the file (preferably a .raw file that already exists)
 * @param array the data buffer containing the data
 * @param size the number of elements in the buffer
 *
 * @returns 0 if all ran correctly
 */
int array_to_raw(const char *filename, data_t *array, size_t size);

/**
 * Save the value of a raw binary file
 * into a data buffer,
 * interpreted as `data_t` types
 *
 * @warning the array must be initiallized
 * and the correct size passed as argument
 *
 * @param filename the name of the file (preferably a .raw file that must already exists)
 * @param array the data buffer containing the data
 * @param size the number of elements in the buffer
 *
 * @returns 0 if all ran correctly
 */
int raw_to_array(const char *filename, data_t *array, size_t size);

#endif
