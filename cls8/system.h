#ifndef _SYSTEM_H
#define _SYSTEM_H

// 打印字符
#define print_char(character) ({ \
__asm__ volatile ("int $0x81"::"a" (character) ); \
})

int fork_syscall();

#endif // _SYSTEM_H
