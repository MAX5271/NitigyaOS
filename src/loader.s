MAGIC_NUMBER equ 0x1BADB002
FLAGS        equ 0
CHECKSUM     equ -(MAGIC_NUMBER + FLAGS)

section .text

align 4
dd MAGIC_NUMBER
dd FLAGS
dd CHECKSUM

global loader
extern kernel_main

; -------------------------
; GDT
; -------------------------

gdt_start:

    ; Null descriptor
    dq 0

    ; Kernel Code
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00

    ; Kernel Data
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

loader:
    lgdt [gdt_descriptor]

    ; Load Kernel Code segment
    jmp 0x08:reload_segments

reload_segments:
    ; Load Kernel Data segment
    mov ax, 0x10

    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Set up stack
    mov esp, stack_top

    ; Enter C
    call kernel_main

.loop:
    jmp .loop

; -------------------------
; Port I/O
; -------------------------

global outb

outb:
    mov al, [esp + 8]
    mov dx, [esp + 4]
    out dx, al
    ret

; -------------------------
; Stack
; -------------------------

section .bss

stack:
    resb 8192

stack_top: