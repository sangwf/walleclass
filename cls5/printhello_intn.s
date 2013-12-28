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

;二进制打印中断
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_print_binary_16]
mov ax, dx

mov edx, 0xef00 ;P DPL ...
mov ecx, 0x81 ;
lea edi, [idt + ecx * 8]
mov [edi], eax
mov [edi + 4], edx



;加载中断描述符表基地址/限长
lidt [lidt_opcode]

;设置页目录表基址
;即给CR3赋值，将将页目录表起始地址的高20位
;写入CR3的高20位，其中低12位是保留字段，无用
mov eax, 0x00100000 ;我们放到物理地址1M的地方
mov CR3, eax

;只给页目录表的第0项赋值
;赋值为物理地址*的高20位
;低12位中的bit 0位P = 1，表示该项有效
;bit 1位R/W = 0，表示只能读，不能写
mov dword [0x00100000], 0x00101001

;给第0项页表赋值，全部置0，表示页面不存在
;第一次访问一个页，会产生异常
mov ecx, 0
mov eax, 0x00101000
mov ebx, 0x00000003

set_page:
mov [eax + ecx * 4], ebx
add ebx, 0x00001000

inc ecx
cmp ecx, 512 ;设为有效
jne set_page

;开启分页模式
;即将CR0寄存器的第31位置1
mov eax, CR0
or eax, 0x80000000 ;最高位置1
mov CR0, eax

sti ;开中断

;mov eax, 0x00200000
;mov byte [eax], 0 ;page fault

mov ax, 0x1234
mov bh, 20
mov bl, 10
mov ch, 0x02
int 0x81

LOOP1:
    jmp LOOP1 ;程序在这里就结束了

align 4
int_ignore: ;默认的硬件中断处理函数
    iret

align 4
int_print_binary_16:
    call print_binary
    iret

;打印一个整数ax到bh行，bl列, 颜色信息存放在ch
print_binary:
    push eax
    push ebx
    push ecx
    push edx
    push gs
    push si
    push di

    ;备份
    mov di, ax    
    mov edx, SCREEN_SEL
    mov gs, dx

    mov si, 0 ;共16位，从左向右打印
repeat_pos:
    mov ax, di ;还原ax

    mov dx, si
    mov cl, dl
    shl ax, cl
    shr ax, 15 ;移到最右侧1位

    ;计算屏幕位置，bh*80+bl+si
    push eax
    push ebx

    mov al, 80
    mul bh
    mov dx, ax

    mov bh, 0    
    add dx, bx ; add bl
    add dx, si ; dx存放位置

    pop ebx
    pop eax

    ;print
    shl edx, 1
    add al, '0';加上asc偏移
    mov [gs: edx], al
    mov [gs: edx + 1], ch


    inc si
    cmp si, 16
    jb repeat_pos

    pop di
    pop si
    pop gs
    pop edx
    pop ecx
    pop ebx
    pop eax
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

times 128 dd 0 ;栈的大小为128个4 bytes
init_stack: ;栈初始化数据
    dd init_stack ;32位偏移地址
    dw DATA_SEL ;16位段选择符
