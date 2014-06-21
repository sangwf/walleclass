#include <stdio.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
    if (fork() == 0) {
        printf("I'm son.\n");
    } else {
        printf("I'm dad.\n");
    }
    return 0;
}
