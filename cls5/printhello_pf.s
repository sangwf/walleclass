KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10
DATA_SEL   equ 0x18

bits 32 ;这是32位的指令

mov eax, DATA_SEL ;先设置数据段
mov ds, eax
mov gs, eax ;这里不赋值，后果很严重


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

;设置缺页异常，异常号0x0e
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_page_fault]
mov ax, dx

mov edx, 0x8F00 ;P DPL ...
mov ecx, 0x0e ;page fault异常号
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
;bit 1位R/W = 1
mov dword [0x00100000], 0x00101003

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

mov ebx, 0x00000000 ;P = 0
set_page_invalid:
mov [eax + ecx * 4], ebx

inc ecx
cmp ecx, 1024 ;设为无效
jne set_page_invalid



;开启分页模式
;即将CR0寄存器的第31位置1
mov eax, CR0
or eax, 0x80000000 ;最高位置1
mov CR0, eax
jmp next
next:
sti ;开中断

mov eax, 0x00200000
mov byte [eax], 'P' ;page fault

mov bl, [eax]
mov edx, 0
mov ecx, SCREEN_SEL
mov gs, ecx
mov byte [gs: edx], bl
mov byte [gs: edx + 1], 0x02

LOOP1:
    jmp LOOP1 ;程序在这里就结束了

align 4
int_ignore: ;默认的硬件中断处理函数
    iret

;缺页异常的处理函数，就是将线性地址和物理地址完全一致的映射
align 4
int_page_fault:
    push eax
    push ebx
    push ecx
    push edx
    push ds
    push es
    push gs

    mov eax, DATA_SEL ;先设置数据段
    mov ds, eax
    mov es, eax
 
    ;通过cr2可以获取到引起缺页的线性地址
    mov ecx, cr2
    shr ecx, 12 ;右移12位，获取页号

    mov ebx, cr2
    and ebx, 0xFFFFF000 ;将最后12位置0，是页内偏移，无用
    or ebx, 0x00000003 ;将最后2位置1，使R/W = 1, P = 1

    mov eax, 0x00101000 ;第0号页表的基地址
    mov [eax + ecx * 4], ebx ;将缺页的页表项设置为有效的

    pop gs
    pop es
    pop ds
    pop edx
    pop ecx
    pop ebx
    pop eax
    add esp, 4 ;去除错误码
    iret

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
