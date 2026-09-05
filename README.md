# NitigyaOS

My journey of building an x86 operating system from scratch.

## Goal

Build a small operating system while learning:

- x86 architecture
- Assembly
- C
- Bootloaders
- Memory management
- Interrupts
- Paging
- User mode
- File systems
- System calls
- Multitasking

## Reference

Based on *The Little Book about OS Development*  
by Erik Helin and Adam Renberg.

## Environment

- Architecture: x86 / IA-32
- Assembly: NASM
- Language: C
- Build system: Make
- Emulator: QEMU
- Bootloader: GRUB
- Host OS: Linux Mint

## Progress

- [x] First Multiboot-compatible kernel
- [x] Boot kernel with GRUB
- [x] Run kernel in QEMU
- [x] Assembly → C
- [ ] Screen output
- [ ] Serial output
- [ ] GDT / Segmentation
- [ ] Interrupts
- [ ] Keyboard input
- [ ] Paging
- [ ] Memory management
- [ ] User mode
- [ ] File system
- [ ] System calls
- [ ] Multitasking

## Documentation

Development notes and learning journal are available in [`docs/`](docs/).

## Project Structure

```text
NitigyaOS/
├── src/        # All OS source and build-related files
├── docs/       # Documentation and development journal
├── README.md
└── .gitignore