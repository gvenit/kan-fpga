#include "file_utils.h"

/********************************************
 * Function Definitions
 ********************************************/

int array_to_raw(const char *filename, data_t *array, size_t size)
{
    int fd = open(filename, O_WRONLY | O_CREAT | O_TRUNC, 0666);
    if (fd < 0)
    {
        perror("[ERROR] On opening output file");
        return 1;
    }

    if (array == NULL)
    {
        perror("[ERROR] Array not allocated");
        return 2;
    }

    write(fd, array, size * sizeof(data_t));

    close(fd);

    return 0;
}

int raw_to_array(const char *filename, data_t *array, size_t size)
{
    int fd = open(filename, O_RDONLY);
    if (fd < 0)
    {
        perror("[ERROR] On opening input file");
        return 1;
    }

    if (array == NULL)
    {
        perror("[ERROR] Array not allocated");
        return 2;
    }

    read(fd, array, size * sizeof(data_t));

    close(fd);

    return 0;
}
