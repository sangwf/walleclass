mov ax, cs ;将cs寄存器的值保存到al
mov al, ah ;先获取cs的高8位
add al, 48 ;48是字符0的asc码，这样便于显示
mov ah, 0x0E ;ah用于bios字符显示中断的类型选择
             ;0x0e表示显示一个字符
int 0x10

mov ax, cs ;获取cs的值，主要是低8位
add al, 48
mov ah, 0x0E
int 0x10

hlt ; 让CPU停止运行

times 510 - ($ - $$) db 0 ;填充一堆的0
                        ;$表示当前位置，$$表示文件头部
db 0x55
db 0xAA ;上面两行用于设置引导扇区的标识
