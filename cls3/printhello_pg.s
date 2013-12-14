KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10
DATA_SEL   equ 0x18

bits 32 ;这是32位的指令
;设置页目录表基址
;即给CR3赋值，将将页目录表起始地址的高20位
;写入CR3的高20位，其中低12位是保留字段，无用
mov eax, 0x00100000 ;我们放到物理地址1M的地方
mov CR3, eax

;只给页目录表的第0项赋值
;即真正有效的地址为4M
;赋值为物理地址1M+4K的高20位
mov eax, DATA_SEL ;先设置数据段
mov ds, eax

;0x00101001的高20位表示页桢地址0x00101
;低12位中的bit 0位P = 1，表示该项有效
;bit 1位R/W = 0，表示只能读，不能写
mov dword [0x00100000], 0x00101001

;给第0项页表赋值
;页表中的每一项，都和实际物理地址一致
;即页表的第0项的页桢为0x00000
;第1项为0x00001...以此类推
;P设置为1，R/W设置为1
mov ecx, 0
mov eax, 0x00101000
mov ebx, 0x00000003

set_page:
mov [eax + ecx * 4], ebx
add ebx, 0x00001000 ;页桢号++

inc ecx
cmp ecx, 1024 ;共有1024项
jne set_page


;开启分页模式
;即将CR0寄存器的第31位置1
mov eax, CR0
or eax, 0x80000000 ;最高位置1
mov CR0, eax

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
