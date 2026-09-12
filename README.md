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
- Host OS: CachyOS

## Dependencies

NitigyaOS requires:

- GCC
- 32-bit GCC support
- NASM
- GNU Binutils
- Make
- QEMU
- ISO creation tools

### Linux Mint / Debian / Ubuntu

Install the required dependencies with:

```bash
sudo apt update
sudo apt install build-essential gcc-multilib binutils nasm qemu-system-x86 genisoimage
```

### CachyOS / Arch Linux

Install the required dependencies with:

```bash
sudo pacman -Syu --needed base-devel gcc-multilib binutils nasm qemu-desktop cdrtools
```

> On Arch-based systems, `cdrtools` provides `mkisofs`.
> The current Makefile uses `genisoimage`, so change `genisoimage` to `mkisofs` in the Makefile if necessary.

### Windows

The recommended setup is **WSL2 with Ubuntu**.

Install WSL2 from PowerShell:

```powershell
wsl --install -d Ubuntu
```

Then, inside Ubuntu, install the dependencies:

```bash
sudo apt update
sudo apt install build-essential gcc-multilib binutils nasm qemu-system-x86 genisoimage
```

## Building

From the project root:

```bash
make
```

This creates:

```text
nitigyaos.iso
```

## Running

Run NitigyaOS in QEMU:

```bash
make run
```

Serial output will appear in the terminal because QEMU is configured with:

```bash
-serial stdio
```

## Cleaning

```bash
make clean
```

## Progress

- [x] First Multiboot-compatible kernel
- [x] Boot kernel with GRUB
- [x] Run kernel in QEMU
- [x] Assembly → C
- [x] Screen output
- [x] Serial output
- [x] GDT / Segmentation
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
├── Makefile
└── .gitignore
```
