nasm -f bin checkcs.s -o checkcs.bin
dd conv=sync if=checkcs.bin of=boot.img bs=1440k count=1
rm -f checkcs.bin

nasm -f bin checkss.s -o checkss.bin
dd conv=sync if=checkss.bin of=boot.img bs=1440k count=1
rm -f checkss.bin


nasm -f bin printhello.s -o printhello.bin
dd conv=sync if=printhello.bin of=helloboot.img bs=1440k count=1
rm -f printhello.bin


