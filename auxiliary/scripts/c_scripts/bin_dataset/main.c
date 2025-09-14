#include <stdio.h>
#include <stdlib.h>

#include "file_utils.h"

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(stderr, "[ERROR] Usage: %s <outputfile.raw> <size>\n", argv[0]);
        return 1;
    }

    const char *rawfile = argv[1];
    const size_t size = atol(argv[2]);

    /*********************************
     * Writing to a file
     * the values one to a specified max
     ********************************/

    data_t *dataBuff = (data_t *)calloc(sizeof(data_t), size);
    if (dataBuff == NULL)
    {
        printf("Failed to allocate memory\n");
        return 2;
    }

    for (size_t i = 0; i < size; i++)
        dataBuff[i] = i;

    int ret = array_to_raw(rawfile, dataBuff, size);
    if (ret != 0)
    {
        printf("File write failed with error code: %d\n", ret);
        return 3;
    }

    free(dataBuff);

    return 0;
}