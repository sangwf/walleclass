KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10
DATA_SEL   equ 0x18

LATCH equ 11931

bits 32 ;这是32位的指令

mov eax, DATA_SEL ;先设置数据段
mov ds, eax
mov gs, eax ;这里不赋值，后果很严重，原因未知

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

;重新初始化时钟中断0x08
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_timer]
mov ax, dx

mov edx, 0x8E00 ;P DPL ...
mov ecx, 0x08 ;时钟中断号
lea edi, [idt + ecx * 8] ;中断的偏移地址放到edi
mov [edi], eax
mov [edi + 4], edx


;加载中断描述符表基地址/限长
lidt [lidt_opcode]

;中断屏蔽管理
mov al, 0xFE ;只放开时钟中断
out 0x21, al
mov al, 0xFF
out 0xA1, al

;设置时钟中断频率
mov al, 0x36
out 0x43, al

mov eax, LATCH
out 0x40, al
mov al, ah
out 0x40, al

sti ;开中断

LOOP1:
    call func_delay
    jmp LOOP1 ;程序在这里就结束了

align 4
int_ignore: ;默认的硬件中断处理函数
;    push eax

;   mov al, 'I'
;   call func_write_char
   
;   pop eax
    iret

align 4
int_timer: ;时钟中断处理函数
    push eax    

    mov al, 0x20
    out 0x20, al

    mov al, 'T'
    call func_write_char

    pop eax
    iret

func_delay:
    jmp .mark_1
    .mark_1:
    jmp .mark_2
    .mark_2:
    ret

;write char AL
func_write_char:
    push ebx
    push ds
    push gs

    mov ebx, DATA_SEL
    mov ds, bx

    mov ebx, SCREEN_SEL
    mov gs, bx
    mov ebx, [scr_loc] ;现在的输出地址

    shl ebx, 1 ; * 2
    mov [gs: ebx], al
    mov byte [gs: ebx + 1], 0x02 ;color

    shr ebx, 1 ; / 2
    add ebx, 1

    cmp ebx, 2000 ; 80 * 25
    jne .mark_update_loc

    mov ebx, 0

    .mark_update_loc:

    mov [scr_loc], ebx ;更新位置

    pop gs
    pop ds
    pop ebx
    ret
 
scr_loc:
    dd 0 ;当前位置
;idt寄存器的加载数据
lidt_opcode:
    dw 256 * 8 - 1
    dd idt

align 8
idt:
    times 2048 db 0 ;256个，每个8 bytes

times 256 dd 0 ;栈的大小为256个4 bytes
init_stack: ;栈初始化数据
    dd init_stack ;32位偏移地址
    dw DATA_SEL ;16位段选择符
