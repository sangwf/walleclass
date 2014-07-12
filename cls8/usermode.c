#include "system.h"

int my_entrance()
{
    if (fork_syscall() == 0) {
        // son
        while(1) {
            print_char('S');
        }
    } else {
        // dad
        while(1) {
            print_char('D');
        }
    }
    return 0;
}
