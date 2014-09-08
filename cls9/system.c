#include "system.h"

int fork_syscall()
{
    int ret = -1;
    __asm__ volatile ("int $0x82": "=a" (ret): );
    
    return ret;
}

int exec_syscall(int file_offset, int file_size)
{
    int ret = -1;
    __asm__ volatile ("int $0x83": "=a" (ret): "a"(file_offset), "c"(file_size));
    
    return ret;
}

int strncmp(char *str1, char *str2, int size)
{    
    while (--size && *str1 && *str1 == *str2) {
        str1++;
        str2++;
    }

    return (*str1 - *str2);
}

int exec(char *filename)
{    
    int ret = -1;
    if (strncmp(filename, "print_hello", 11) == 0) {
        ret = exec_syscall(0x2600, 0x200); // 制作映像文件时，将print_hello被拷贝到了0x2600处
    } else {
        ret = exec_syscall(0x2A00, 0x200); // print_world
    }

    return ret;
}
