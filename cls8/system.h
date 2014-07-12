#ifndef _SYSTEM_H
#define _SYSTEM_H

#define print_short(value) ({ \
__asm__ volatile ("int $0x82"::"d" (value) ); \
})

#define print_long(value) ({ \
__asm__ volatile ("int $0x85"::"d" (value) ); \
})


#define print_string(address) ({ \
__asm__ volatile ("int $0x84"::"d" (address) ); \
})

// 打印字符
#define print_char(character) ({ \
__asm__ volatile ("int $0x81"::"a" (character) ); \
})

#define print_return() ({ \
__asm__ volatile ("int $0x83"::); \
})

int fork_syscall();

#endif // _SYSTEM_H
