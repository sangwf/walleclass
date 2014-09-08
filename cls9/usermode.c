#include "system.h"

int my_entrance()
{
    if (fork_syscall() == 0) {
        // son
        exec("print_hello");
        while(1) ;
    } else {
        // dad
        print_char('D');
        while(1) ;
    }

    return 0;
}
