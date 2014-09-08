#!/bin/sh
nasm -f bin boot.s -o boot.bin
nasm -f bin print_ab.s -o print_ab.bin
i586-pc-linux-gcc -c system.c
i586-pc-linux-gcc -c usermode.c
i586-pc-linux-ld -Ttext=2000 -emy_entrance usermode.o system.o -o usermode.elf
i586-pc-linux-objcopy -O binary usermode.elf usermode.bin

i586-pc-linux-gcc -c print_hello.c
i586-pc-linux-ld -Ttext=2500 -emy_entrance print_hello.o system.o -o print_hello.elf
i586-pc-linux-objcopy -O binary print_hello.elf print_hello.bin

i586-pc-linux-gcc -c print_world.c
i586-pc-linux-ld -Ttext=2500 -emy_entrance print_world.o system.o -o print_world.elf
i586-pc-linux-objcopy -O binary print_world.elf print_world.bin

cat boot.bin print_ab.bin usermode.bin > system.bin
dd conv=sync if=system.bin of=system.inter bs=0x2800 count=1

# write print_hello at 0x2800
cat system.inter print_hello.bin > sys_hello.bin
dd conv=sync if=sys_hello.bin of=sys_hello.inter bs=0x2C00 count=1

# write print_world at 0x2C00
cat sys_hello.inter print_world.bin > sys_world.bin
dd conv=sync if=sys_world.bin of=print_ab.img bs=1440k count=1

rm -f *.bin *.o *.elf *.inter
