# NitigyaOS — 001: First Boot

## Boot Flow

```text
BIOS → GRUB → NitigyaOS Kernel → CPU
```

## Tools

- **NASM** → assembles `loader.s` → `loader.o`
- **ld** → links `loader.o` using `link.ld` → `kernel.elf`
- **GRUB** → loads the kernel
- **QEMU** → runs NitigyaOS

## Multiboot

```asm
MAGIC_NUMBER equ 0x1BADB002
```

- Multiboot header lets GRUB recognize our kernel.
- `grub-file --is-x86-multiboot kernel.elf`
- Return value `0` → valid Multiboot kernel.

## Entry Point

```asm
loader:
    mov eax, 0xCAFEBABE
```

- `loader` → kernel entry point.
- `EAX` → x86 CPU register.
- `0xCAFEBABE` → test value only.

```asm
.loop:
    jmp .loop
```

- Infinite loop.
- Blank QEMU screen is expected.

## Linker Script

```ld
ENTRY(loader)
```

- Tells the linker that `loader` is the entry point.

```ld
. = 0x00100000;
```

- Kernel is linked at `0x00100000` (1 MiB).

## Build Pipeline

```text
loader.s
   ↓ NASM
loader.o
   ↓ ld + link.ld
kernel.elf
   ↓ GRUB
NitigyaOS
```

## Current Achievement

- [x] Created a Multiboot-compatible kernel
- [x] GRUB recognizes it
- [x] GRUB loads it in QEMU
- [x] CPU reaches our kernel

