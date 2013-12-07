KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x18

bits 32 ;这是32位的指令
mov eax, SCREEN_SEL
mov ds, eax

mov eax, 0
mov byte [eax], 'H'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'e'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'l'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'l'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'o'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], ','
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], ' '
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'w'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'o'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'r'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'l'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], 'd'
mov byte [eax + 1], 0x02 ;color
add eax, 2
mov byte [eax], '!'
mov byte [eax + 1], 0x02 ;color

LOOP1:
    jmp LOOP1
    
gdt:
    dw 0, 0, 0, 0 ;第0个描述符，不使用

    ;第一个描述符(0x08)，表示代码段
    dw 0x07FF ;段限长低16位，则段限长为：
              ;(0x07FF + 1) * 4KB = 8MB
    dw 0x0000 ;基地址低16位0，所以基地址为0
    dw 0x9A00 ;0x9A = 1001 1010
              ;高4位分别表示P = 1段在内存中
              ;DPL = 0，最高权限
              ;S = 1，非系统段
              ;且TYPE的bit 3为1，表示代码段
              ;低8位表示基地址23~16为0
    dw 0x00C0 ;高8位表示基地址31~24为0
              ;G标志(bit 7) = 1，表示颗粒度为4KB
              ;注意：保护模式下颗粒度一般都设4KB
              ;最后4位为0，表示段限长19~16位是0

    ;第2个段描述符（0x10），表示数据段
    dw 0x07FF
    dw 0x0000
    dw 0x9200 ;与代码段的差异就是TYPE字段
    dw 0x00C0

    ;第3个段描述符（0x18），表示显卡内存
    ;显卡默认在CGA模式，字符彩屏
    ;映射在内存地址0xb8000~0xc8000，共16K
    ;我们只用前面的4K
    ;所以颗粒度G = 1，且段限长Limit = 0
    dw 0x0002
    dw 0x8000
    dw 0x920B ;0x92 = 1001 0010
              ;S = 1且TYPE(bit 3)为0，表示数据段
              ;DPL = 0
              ;E = 0，表示地址是从小往大增长
              ;W = 1表示可写入
    dw 0x00C0
end_gdt:

gdt_48:
    dw (end_gdt - gdt) - 1 ;gdt的限长
                           ;- 1的作用和段描述符的Limit类似
                           ;都是表示最后一个有效的地址(<=)
    dw gdt ;gdt的起始地址
    dw 0

