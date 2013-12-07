KERNEL_SEL equ 0x08
SCREEN_SEL equ 0x10

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
