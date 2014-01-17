nasm -f bin boot.s -o boot.bin
nasm -f bin print_timer.s -o print_timer.bin
cat boot.bin print_timer.bin > system.bin
dd conv=sync if=system.bin of=boot_timer.img bs=1440k count=1
rm -f boot.bin print_timer.bin system.bin


