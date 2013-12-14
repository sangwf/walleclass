nasm -f bin boot.s -o boot.bin
nasm -f bin printhello_pg.s -o printhello.bin
cat boot.bin printhello.bin > system.bin
dd conv=sync if=system.bin of=helloboot.img bs=1440k count=1
rm -f boot.bin printhello.bin system.bin


