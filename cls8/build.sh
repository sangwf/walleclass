nasm -f bin boot.s -o boot.bin
nasm -f bin print_ab.s -o print_ab.bin
i586-pc-linux-gcc -c usermode.c system.c
i586-pc-linux-ld -Ttext=2200 -emy_entrance usermode.o system.o -o usermode
i586-pc-linux-objcopy -O binary usermode usermode.bin

cat boot.bin print_ab.bin usermode.bin > system.bin
dd conv=sync if=system.bin of=print_ab.img bs=1440k count=1

rm -f boot.bin print_ab.bin system.bin usermode.o system.o
