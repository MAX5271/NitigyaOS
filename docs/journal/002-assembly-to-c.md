# 002 — Assembly → C

## Goal

Call a C function from the Assembly kernel entry point.

The purpose of this step is to make the transition from Assembly into C safely by setting up a stack, compiling the C code as 32-bit freestanding code, and linking both parts into the kernel.

---

## Current Flow

```text
GRUB
 ↓
loader.s
 ↓
set up stack
 ↓
call kernel_main()
 ↓
kernel.c
 ↓
return to loader.s
 ↓
infinite loop
```

---

## Why C?

Assembly is useful for low-level CPU operations, but writing the whole OS in Assembly would be impractical.

- **Assembly** → low-level CPU/kernel setup
- **C** → most kernel logic

The kernel can therefore use Assembly where direct CPU control is needed and C for the majority of its logic.

---

## Stack

Before calling C, we need to set up a **stack**.

The stack is a region of memory used by functions for things such as:

- function calls
- local variables
- saved information

On 32-bit x86, **ESP** is the stack pointer. It points to the current top of the stack.

Our kernel creates an 8 KiB stack:

```asm
section .bss

stack:
    resb 8192
stack_top:
```

### What does `resb 8192` mean?

`resb` means **reserve bytes**.

```asm
resb 8192
```

reserves 8192 bytes of memory for the stack.

`stack_top` marks the address immediately after that reserved space.

---

## Setting Up ESP

Before calling C:

```asm
mov esp, stack_top
```

This initializes the CPU's stack pointer.

The stack on x86 grows **downward**, so starting `ESP` at `stack_top` allows the stack to grow into the reserved 8192-byte region.

---

## Calling C

Assembly declares that `kernel_main` exists somewhere else:

```asm
extern kernel_main
```

Then the kernel entry point calls it:

```asm
loader:
    mov esp, stack_top
    call kernel_main
```

### `extern kernel_main`

Tells NASM that `kernel_main` is defined in another object file.

In our case:

```text
loader.s  →  loader.o
kernel.c  →  kernel.o
```

The linker later connects the reference to the actual C function.

### `call kernel_main`

`call` transfers execution to `kernel_main`.

The CPU also saves the return address so that the C function can return to the instruction after `call`.

---

## kernel.c

Our first C kernel function is intentionally empty:

```c
void kernel_main()
{
}
```

At this stage, the purpose is only to prove that we can successfully enter C.

There is no screen output yet.

---

## Why Does QEMU Show a Blank Screen?

After `kernel_main()` finishes, execution returns to the Assembly code:

```asm
.loop:
    jmp .loop
```

This is an infinite loop.

So the current behavior is:

```text
GRUB loads kernel
      ↓
loader runs
      ↓
stack is initialized
      ↓
kernel_main() is called
      ↓
kernel_main() returns
      ↓
CPU enters infinite loop
      ↓
blank screen
```

**The blank screen is expected.**

It does not mean the C transition failed.

---

## Compiling C

The C file is compiled as 32-bit freestanding code:

```bash
gcc -m32 -ffreestanding -c src/kernel.c -o src/kernel.o
```

Important parts:

- `-m32` → compile for 32-bit x86
- `-ffreestanding` → compile without assuming a normal hosted environment such as an operating system
- `-c` → compile/assemble into an object file without linking

Result:

```text
src/kernel.c
    ↓ gcc
src/kernel.o
```

---

## Assembling

The Assembly source is assembled as 32-bit ELF:

```bash
nasm -f elf32 src/loader.s -o src/loader.o
```

Result:

```text
src/loader.s
    ↓ NASM
src/loader.o
```

---

## Linking Assembly + C

Both object files are linked using our linker script:

```bash
ld -m elf_i386 -T src/link.ld src/loader.o src/kernel.o -o src/kernel.elf
```

Result:

```text
loader.o ──┐
           ├──→ ld + link.ld ──→ kernel.elf
kernel.o ──┘
```

The linker resolves the `kernel_main` reference from Assembly to the function implemented in `kernel.c`.

---

## Multiboot Verification

After linking, verify that GRUB recognizes the kernel:

```bash
grub-file --is-x86-multiboot src/kernel.elf
echo $?
```

Expected:

```text
0
```

A return value of `0` means the kernel is recognized as a valid Multiboot kernel.

---

## Booting with QEMU

Our ISO contains:

```text
iso/
└── boot/
    ├── kernel.elf
    └── grub/
        ├── menu.lst
        └── stage2_eltorito
```

Create the ISO:

```bash
rm -rf iso
mkdir -p iso/boot/grub

cp src/kernel.elf iso/boot/kernel.elf
cp src/stage2_eltorito iso/boot/grub/

cat > iso/boot/grub/menu.lst << 'EOF'
default 0
timeout 0

title NitigyaOS
kernel /boot/kernel.elf
EOF

genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o nitigyaos.iso iso
```

Run it:

```bash
qemu-system-i386 -cdrom nitigyaos.iso
```

### Result

QEMU successfully showed:

```text
Booting 'NitigyaOS'
kernel /boot/kernel.elf
[Multiboot-elf, ... entry=0x10000c]
```

and then the screen became blank.

This is the expected result because `kernel_main()` currently contains no output code.

---

## Current Files

```text
src/
├── loader.s
├── link.ld
├── stage2_eltorito
├── kernel.c
├── loader.o
├── kernel.o
└── kernel.elf
```

---

## Current loader.s

```asm
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

loader:
    mov esp, stack_top
    call kernel_main

.loop:
    jmp .loop

section .bss

stack:
    resb 8192
stack_top:
```

---

## Current kernel.c

```c
void kernel_main()
{
}
```

---

## What I Learned

### 1. The kernel needs a stack before entering C

```asm
mov esp, stack_top
```

### 2. Assembly can call C functions

```asm
extern kernel_main

call kernel_main
```

### 3. C can be compiled without a normal operating system

```bash
gcc -m32 -ffreestanding ...
```

### 4. The linker combines Assembly and C

```text
loader.o + kernel.o → kernel.elf
```

### 5. QEMU can run the resulting kernel

GRUB recognizes the Multiboot kernel and transfers execution to our entry point.

---

## Checklist

- [x] Create kernel stack
- [x] Set up `ESP`
- [x] Create `kernel.c`
- [x] Implement `kernel_main()`
- [x] Call `kernel_main()` from Assembly
- [x] Compile C as 32-bit code
- [x] Link Assembly + C
- [x] Verify Multiboot kernel
- [x] Boot and test in QEMU
- [x] Confirm Assembly → C transition works

---

## Key Idea

> Before entering C code, the kernel must have a valid stack.

The important achievement of this step is not visible output. It is proving that:

```text
GRUB → Assembly → stack setup → C → Assembly
```

works correctly.

---

## Next Step

The next milestone is **screen output**.

We will write directly to the VGA text framebuffer at:

```text
0xB8000
```

This will allow `kernel_main()` to display text on the screen without relying on an operating system, standard library, or terminal.

---

## Reference

Chapter 3 — Getting to C.

The book recommends progressing in small, testable steps rather than trying to build large parts of the OS at once.
