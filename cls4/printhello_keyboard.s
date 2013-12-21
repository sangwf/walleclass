KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10
DATA_SEL   equ 0x18

bits 32 ;这是32位的指令

mov eax, DATA_SEL ;先设置数据段
mov ds, eax
mov es, eax

;初始化栈
lss esp, [init_stack]

cli ;关中断

lea edx, [int_ignore] ;将int_ignore的地址写入edx
mov eax, 0x00080000 ;eax高16位设置段选择符0x0008
mov ax, dx ;将int_ignore写入ax
           ;到此为止，eax存放了一个中断描述符的
           ;低32位：段选择符 + 偏移地址(低16位)
mov dx, 0x8E00 ;1000 1110 0000 0000
               ;P = 1, DPL = 00
               ;中断门的标记01110000
               ;最后5位无用
               ;dx用于中断门的第32~47位
               ;目前为止，edx为中断门的高32位
lea edi, [idt] ;将idt的地址写入edi
mov ecx, 256 ;一共256个中断描述符

;循环初始化所有中断门为int_ignore
rp_idt:
mov [edi], eax
mov [edi + 4], edx
add edi, 8
dec ecx
jne rp_idt

;重新初始化键盘中断0x09
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_keyboard]
mov ax, dx

mov edx, 0x8E00 ;P DPL ...
mov ecx, 0x09 ;键盘中断号
lea edi, [idt + ecx * 8] ;键盘中断的偏移地址放到esi
mov [edi], eax
mov [edi + 4], edx


;加载中断描述符表基地址/限长
lidt [lidt_opcode]

sti ;开中断

LOOP1:
    jmp LOOP1 ;程序在这里就结束了

align 4
int_ignore: ;默认的硬件中断处理函数
    push eax
    push ebx
    push ecx
    push edx
    push ds
    push es
    push gs

    mov eax, DATA_SEL
    mov ds, ax
    mov es, ax


    mov al, 'I'

    mov ebx, SCREEN_SEL
    mov gs, bx
    mov ebx, [scr_loc] ;现在的输出地址

    shl ebx, 1 ; * 2
    mov [gs: ebx], al
    mov byte [gs: ebx + 1], 0x02

    shr ebx, 1 ; / 2
    add ebx, 1
    mov [scr_loc], ebx ;更新位置
    ;end
    
    pop gs
    pop es
    pop ds
    pop edx
    pop ecx
    pop ebx
    pop eax
    iret

align 4
int_keyboard: ;键盘中断处理函数
    push eax
    push ebx
    push ecx
    push edx
    push ds
    push es
    push gs

    mov eax, DATA_SEL
    mov ds, ax
    mov es, ax

    in al, 0x60 ;读取按键的扫描码

    call key_display

    ;对键盘进行复位处理
    ;先禁用键盘，然后重新允许使用
    in al, 0x61
    nop
    nop
    or al, 0x80
    nop
    nop
    out 0x61, al
    nop
    nop
    and al, 0x7F
    out 0x61, al
    mov al, 0x20
    out 0x20, al

    pop gs
    pop es
    pop ds
    pop edx
    pop ecx
    pop ebx
    pop eax
    iret

key_display:
    ;剔除按键弹起的中断，第8位为1
    mov bl, al
    and bl, 0x80
    cmp bl, 0
;`    jne .key_ret

    and ax, 0x007f ;只用最后7位
    mov al, [key_map + eax] ;通过映射表寻找对应字符

    mov ebx, SCREEN_SEL
    mov gs, bx
    mov ebx, [scr_loc] ;现在的输出地址

    shl ebx, 1 ; * 2
    mov [gs: ebx], al
    mov byte [gs: ebx + 1], 0x02

    shr ebx, 1 ; / 2
    add ebx, 1
    mov [scr_loc], ebx ;更新位置

.key_ret:
    ret

;for my Macbook Pro keyboard
key_map:
    db 0
    db "01234567890-="
    db 0x0e ; delete key
    db " qwertyuiop[]"
    db 0
    db 0x1d ; ctrl key(left)
    db "asdfghjkl;'"
    db "  \zxcvbnm,./"
    
    times 128 db 0


scr_loc:
    dd 0 ;当前位置
;idt寄存器的加载数据
lidt_opcode:
    dw 256 * 8 - 1
    dd idt

align 8
idt:
    times 2048 db 0 ;256个，每个8 bytes

times 128 dd 0 ;栈的大小为128个4 bytes
init_stack: ;栈初始化数据
    dd init_stack ;32位偏移地址
    dw DATA_SEL ;16位段选择符
