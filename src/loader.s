extern kernel_main
MAGIC_NUMBER equ 0x1BADB002
FLAGS        equ 0
CHECKSUM     equ -(MAGIC_NUMBER + FLAGS)

section .text

align 4
dd MAGIC_NUMBER
dd FLAGS
dd CHECKSUM

global loader

loader:
    mov esp, stack_top
    call kernel_main

.loop:
    jmp .loop

section .bss

stack:
    resb 8192
stack_top: