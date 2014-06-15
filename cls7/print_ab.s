KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10
DATA_SEL   equ 0x18
LDT0_SEL   equ 0x20
TSS0_SEL   equ 0x28
TSS1_SEL   equ 0x30

LATCH equ 11931
MAX_PROC_COUNT equ 2 ;最多有两个进程

bits 32 ;这是32位的指令

mov eax, DATA_SEL ;先设置数据段
mov ds, eax
mov gs, eax

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

;系统调用0x81，打印AL字符
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_print_char]
mov ax, dx

mov edx, 0xEF00 ;P DPL ...
mov ecx, 0x81
lea edi, [idt + ecx * 8] ;中断的偏移地址放到edi
mov [edi], eax
mov [edi + 4], edx

;系统调用0x82，fork一个新进程，如果proccess_count > MAX_PROC_COUNT，则fork失败
mov eax, 0x00080000 ;段选择符0x08
lea edx, [int_fork]
mov ax, dx

mov edx, 0xEF00 ;P DPL ...
mov ecx, 0x82
lea edi, [idt + ecx * 8] ;中断的偏移地址放到edi
mov [edi], eax
mov [edi + 4], edx


;加载中断描述符表基地址/限长
lidt [lidt_opcode]
;加载GDT
lgdt [lgdt_opcode]

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

pushfd ;复位eflags中的任务嵌套标志，不用关注
and dword [esp], 0xffffbfff
popfd

mov eax, TSS0_SEL
ltr ax
mov eax, LDT0_SEL
lldt ax
mov dword [current], 0
sti ;开中断

push 0x17 ;任务0的局部数据段用于SS
push init_stack
pushfd
push 0x0f ;CS
push task0 ;EIP
iret

;程序在这里就结束了

align 4
int_ignore: ;默认的硬件中断处理函数
;    push eax

;    mov al, 'I'
;    call func_write_char
   
;    pop eax
    iret

align 4
int_timer: ;时钟中断处理函数
    push ds
    push eax    

    mov al, 0x20
    out 0x20, al
    
    mov eax, DATA_SEL
    mov ds, ax

    ;若只有一个进程，不需要切换
    mov eax, [process_count]
    cmp eax, 1
    je .switch_finish

    mov eax, 1
    cmp [current], eax
    je .switch_0
    mov dword [current], 1
    jmp TSS1_SEL: 0 ;注意，执行这句后，马上保存了当前现场，
                    ;并跳转到了任务1之前的现场去执行，也就
                    ;下次切换回来时，是执行了下一句。是在内
                    ;核态时，被切换出去了。
    jmp .switch_finish
    .switch_0:
    mov dword [current], 0
    jmp TSS0_SEL: 0
    .switch_finish:
    pop eax
    pop ds
    iret

align 4
int_fork: ;fork系统调用处理函数
    cli ;关闭中断，避免中间被打断
    push ds
    push eax 
    
    mov eax, DATA_SEL
    mov ds, ax

    mov eax, [process_count]
    cmp eax, MAX_PROC_COUNT
    je .fork_fail

    inc eax
    mov [process_count], eax
    mov eax, [SS: ESP + 8] ;EIP
    mov [task1_eip], eax
    mov dword [task1_eax], 0 ;对子进程，设置eax为0

    jmp .fork_finish
    .fork_fail:
    ;print something
    mov al, 'F'
    call func_write_char
    .fork_finish:
    pop eax
    mov eax, [process_count] ;对父进程，设置eax为process_count
    pop ds
    sti
    iret


align 4
int_print_char:
    call func_write_char
    iret

func_delay:
    jmp .mark_1
    .mark_1:
    jmp .mark_2
    .mark_2:
    ret

;write char AL
func_write_char:
    push ecx
    push ebx
    push ds
    push es

    mov ebx, DATA_SEL
    mov ds, bx

    mov ebx, SCREEN_SEL
    mov es, bx
    mov ebx, [scr_loc] ;现在的输出地址

    shl ebx, 1 ; * 2
    mov [es: ebx], al
    mov ecx, [current] ;通过进程号设置颜色
    inc ecx
    add ecx, ecx
    mov byte [es: ebx + 1], cl ;color

    shr ebx, 1 ; / 2
    add ebx, 1

    cmp ebx, 2000 ; 80 * 25
    jne .mark_update_loc

    mov ebx, 0

    .mark_update_loc:

    mov [scr_loc], ebx ;更新位置

    pop es
    pop ds
    pop ebx
    pop ecx
    ret

;write AL by hex, eg: 'A' = 61
func_write_hex:
    push eax
    push ebx
    push ecx
    push ds

    mov ecx, DATA_SEL
    mov ds, cx

    xor ebx, ebx ;clear

    mov ah, al ;save
    shr al, 4 ;print high 4 bits
    mov bl, al
    mov al, [hex_map + ebx]
    call func_write_char
    mov al, ah
    shl al, 4 ;clear high 4 bits
    shr al, 4 ;print low 4 bits
    mov bl, al
    mov al, [hex_map + ebx]
    call func_write_char

    pop ds
    pop ecx
    pop ebx
    pop eax
    ret

hex_map:
    db '0123456789ABCDEF'
    db 0

current:
    dd 0 ;当前的任务号
         ;注意dword表示double word
         ;而dw表示single word
         ;曾因为在这里用dw，而导致scr_loc被赋值
process_count:
    dd 1 ;当前用户进程数，初始化有task0，即1个进程
scr_loc:
    dd 0 ;当前位置
;idt寄存器的加载数据
lidt_opcode:
    dw 256 * 8 - 1
    dd idt

align 8
idt:
    times 2048 db 0 ;256个，每个8 bytes

;注意：以下GDT的设置一定要对照格式图表
gdt:
    dw 0, 0, 0, 0 ;第0个描述符，不使用

    ;第1个描述符(0x08)，表示代码段
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
    
    ;第2个段描述符（0x10），表示显卡内存
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

    ;第3个描述符(0x18)，表示数据段
    dw 0x07FF ;段限长低16位，则段限长为：
              ;(0x07FF + 1) * 4KB = 8MB
    dw 0x0000 ;基地址低16位0，所以基地址为0
    dw 0x9200 ;0x92 = 1001 0010
              ;高4位分别表示P = 1段在内存中
              ;DPL = 0，最高权限
              ;S = 1，非系统段
              ;且TYPE的bit 3为0，表示数据段
              ;低8位表示基地址23~16为0
    dw 0x00C0 ;高8位表示基地址31~24为0
              ;G标志(bit 7) = 1，表示颗粒度为4KB
              ;注意：保护模式下颗粒度一般都设4KB
              ;最后4位为0，表示段限长19~16位是0

    ;第4个描述符（0x20），LDT0
    dw 0x40
    dw ldt0
    dw 0xe200
    dw 0x0

    ;第4个描述符（0x28），TSS0
    dw 0x68
    dw tss0
    dw 0xe900
    dw 0x0

    ;第6个描述符（0x30），TSS1
    dw 0x68
    dw tss1
    dw 0xe900
    dw 0x0
    
end_gdt:

lgdt_opcode:
    dw (end_gdt - gdt) - 1 ;gdt的限长
                           ;- 1的作用和段描述符的Limit类似
                           ;都是表示最后一个有效的地址(<=)
    dw gdt ;gdt的起始地址
    dw 0


times 256 dd 0 ;栈的大小为256个4 bytes
init_stack: ;栈初始化数据
    dd init_stack ;32位偏移地址
    dw DATA_SEL ;16位段选择符

align 8
tss0:
    dd 0
    dd krn_stk0, DATA_SEL ; 第1个dd是内核栈
    dd 0, 0, 0, 0, 0
    dd 0, 0, 0, 0, 0
    dd 0
    dd 0, 0, 0, 0 ; 第14个dd是用户栈
    dd 0, 0, 0, 0x17, 0, 0
    dd LDT0_SEL, 0x80000000

times 128 dd 0
krn_stk0:

align 8
ldt0:
    dw 0, 0, 0, 0
    dw 0x03ff, 0x0000, 0xfa00, 0x00c0
    dw 0x03ff, 0x0000, 0xf200, 0x00c0

align 8
tss1:
    dd 0
    dd krn_stk1, DATA_SEL ; 第1个dd是内核栈
    dd 0, 0, 0, 0, 0
task1_eip: ;用于设置eip时好找偏移
    dd task0, 0x200 ;eip, eflags
task1_eax: ;用于设置eax时好找偏移
    dd 0, 0, 0, 0
    dd usr_stk1, 0, 0, 0 ; 第14个dd是用户栈
    dd 0x17, 0x0f, 0x17, 0x17, 0x17, 0x17
    dd LDT0_SEL, 0x80000000

times 128 dd 0
krn_stk1:
times 128 dd 0
usr_stk1:

task0:
    int 0x82 ;fork
    cmp eax, 0 ;eax存放fork的返回值，为0时表示子进程，非0时表示父进程
    je .do_son
    .do_father:
    mov al, 'A'
    int 0x81
    mov ecx, 0x1fffff
    .t0:
    loop .t0
    jmp .do_father
    .do_son:
    mov al, 'B'
    int 0x81
    mov ecx, 0x1fffff
    .t1:
    loop .t1
    jmp .do_son
    jmp task0 ;never arrived
