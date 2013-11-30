BOOTSEG equ 0x07C0 ;宏定义，用于初始化ES

mov ax, HelloMsg ;不支持直接将HelloMsg赋值给bp
mov bp, ax
mov ax, BOOTSEG
mov es, ax      ;es:bp = 字符串地址
                ;HelloMsg只是段内的偏移地址
                ;而代码被加载到0x7C00，故设置段地址
                ;即es * 16 + bp为实际内存地址
mov cx, 13 ;串的长度
mov ax, 0x1301 ;AH = 0x13，表示串打印
               ;AL = 0x01，表示打印后光标移动
mov bx, 0x000C ;BH = 0x00，表示页码
               ;BL = 0x0C，表示红色
mov dx, 0x0000 ;第0行0列开始
int 0x10

loop1:
    jmp BOOTSEG: loop1 ;之所以带上段选择符，道理同HelloMsg

HelloMsg:
    db "Hello, world!" ;共13个字符

times 510 - ($ - $$) db 0 ;填充一堆的0
                        ;$表示当前位置，$$表示文件头部
db 0x55
db 0xAA ;上面两行用于设置引导扇区的标识
