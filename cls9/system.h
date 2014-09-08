#ifndef _SYSTEM_H
#define _SYSTEM_H

// 打印字符
#define print_char(character) ({ \
__asm__ volatile ("int $0x81"::"a" (character) ); \
})

// 打印字符串
// void print_string(char *str);
#define print_string(string) ({ \
__asm__ volatile ("int $0x84"::"d" (string) ); \
})



// 创建子进程
int fork_syscall();

// 执行应用程序，binary格式
int exec(char *filename);

#endif // _SYSTEM_H
