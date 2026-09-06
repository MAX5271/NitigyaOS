# 005 — Framebuffer Driver and Source Organization

## Goal

Separate hardware-specific framebuffer code from the kernel and organize the source tree into subsystems.

This phase also updated the Makefile so the complete OS can be built into a bootable GRUB ISO and launched with QEMU.

---

## 1. Why Separate the Driver?

Previously, `kernel.c` contained both:

- Kernel logic
- VGA framebuffer implementation

This works for a tiny kernel, but it does not scale.

As the OS grows, `kernel.c` could become filled with code for:

- Framebuffer
- Keyboard
- Serial port
- Interrupts
- Memory management
- File systems
- etc.

Instead, hardware-specific functionality should be placed inside drivers.

The kernel should use the driver's interface without knowing how the hardware works.

The architecture is now:

    kernel.c
        |
        | fb_write()
        v
    framebuffer.c
        |
        | outb()
        v
    loader.s
        |
        v
    Hardware

---

## 2. New Project Structure

The source tree was reorganized:

    NitigyaOS/
    ├── src/
    │   ├── kernel/
    │   │   └── kernel.c
    │   │
    │   ├── drivers/
    │   │   └── framebuffer/
    │   │       ├── framebuffer.c
    │   │       └── framebuffer.h
    │   │
    │   ├── loader.s
    │   ├── io.h
    │   └── link.ld
    │
    ├── docs/
    │   └── journal/
    │
    ├── Makefile
    ├── README.md
    └── .gitignore

The `src/` directory contains OS source and build-related files.

The `docs/` directory contains documentation and the development journal.

---

## 3. Framebuffer Driver

The framebuffer driver is responsible for communicating with the VGA text framebuffer.

The VGA text buffer begins at:

    0xB8000

The screen is:

    80 columns × 25 rows

Each screen cell uses two bytes:

    [character][attribute]

For example:

    0xB8000 → character
    0xB8001 → color
    0xB8002 → next character
    0xB8003 → next color

Therefore, the position of a character in the framebuffer is:

    cursor_pos * 2

---

## 4. framebuffer.h

The header exposes the public interface of the framebuffer driver:

    int fb_write(char* buf, unsigned int len);

The kernel does not need to know about VGA ports, framebuffer addresses, or cursor registers.

It only needs to know how to request a write.

---

## 5. framebuffer.c

The framebuffer implementation contains:

- VGA port definitions
- Cursor state
- Cursor movement
- Writing characters to video memory

The cursor position is now private to the driver:

    static unsigned int cursor_pos = 80;

Starting at position 80 means the kernel begins writing on the second row of the VGA text screen.

This was done temporarily because GRUB had already written information on the first row.

The cursor movement function is also private:

    static void fb_move_cursor(...)

Using `static` at file scope prevents other source files from directly accessing these implementation details.

---

## 6. Writing to the Framebuffer

The framebuffer driver provides:

    int fb_write(char* buf, unsigned int len)

`buf` points to the data that should be written.

`len` specifies exactly how many bytes should be written.

For every character:

    video_memory[cursor_pos * 2] = buf[i];

The character is written to the framebuffer.

The attribute byte is written separately:

    video_memory[cursor_pos * 2 + 1] = 0x07;

`0x07` represents the default light-grey-on-black VGA text attribute being used by NitigyaOS.

After writing, the cursor position is updated and the hardware cursor is moved.

The function returns `len` because all requested bytes were written.

---

## 7. Why Does fb_write() Need len?

A string normally ends with:

    '\0'

However, a driver should not assume that all data is a null-terminated string.

For example:

    char data[] = {'A', 'B', 'C', 'D'};

There is no `'\0'` at the end.

Calling:

    fb_write(data, 4);

tells the driver exactly how much data to process.

Therefore:

    len = amount of data to write

rather than being specifically related to the cursor position.

---

## 8. kernel.c

The kernel is now much simpler:

    #include "drivers/framebuffer/framebuffer.h"

    void kernel_main()
    {
        fb_write("Hello, NitigyaOS!", 17);
    }

The kernel only uses the framebuffer driver's public interface.

This gives us a separation between:

    High-level kernel code

and

    Hardware-specific driver code

---

## 9. Build System

The Makefile was updated to compile multiple C source files.

The build process is now:

    loader.s
        ↓
    loader.o

    kernel.c
        ↓
    kernel.o

    framebuffer.c
        ↓
    framebuffer.o

    loader.o + kernel.o + framebuffer.o
        ↓
    kernel.elf
        ↓
    GRUB ISO
        ↓
    nitigyaos.iso
        ↓
    QEMU

---

## 10. Building the ISO

The Makefile creates a temporary ISO directory:

    iso/
    ├── boot/
    │   ├── kernel.elf
    │   └── grub/
    │       ├── stage2_eltorito
    │       └── menu.lst

The kernel is copied into:

    iso/boot/kernel.elf

The GRUB bootloader file is copied into:

    iso/boot/grub/stage2_eltorito

A GRUB menu is generated containing the NitigyaOS kernel entry.

`genisoimage` then packages everything into:

    nitigyaos.iso

---

## 11. Make Commands

Build everything:

    make

Clean generated files:

    make clean

Build the ISO and launch QEMU:

    make run

The `run` target depends on the ISO target, so the ISO is rebuilt automatically when necessary.

---

## 12. Important Concepts Learned

### Driver abstraction

A driver provides an interface between the kernel and hardware.

Instead of directly manipulating hardware everywhere:

    kernel → hardware

we use:

    kernel → driver → hardware

This makes the kernel easier to organize and extend.

### Header files

A `.h` file exposes an interface.

A `.c` file contains the implementation.

For the framebuffer:

    framebuffer.h
        → public interface

    framebuffer.c
        → implementation

### static functions and variables

A file-level `static` symbol is private to that source file.

This allows the framebuffer driver to hide implementation details such as:

    cursor_pos
    fb_move_cursor()

### Linking

Every `.c` file is compiled independently into an object file.

The linker combines them:

    kernel.o
    framebuffer.o
    loader.o
        ↓
    kernel.elf

### ISO generation

The kernel ELF is not itself the bootable CD image.

The ISO contains the bootloader and kernel in the structure expected by GRUB.

---

## Result

NitigyaOS now has:

- A separated framebuffer driver
- A cleaner kernel
- A basic driver abstraction
- Multiple source files
- A structured source tree
- A Makefile capable of building the complete OS
- Automatic GRUB ISO generation
- QEMU execution through `make run`

The kernel can still display:

    Hello, NitigyaOS!

but the implementation is now organized so that more hardware drivers can be added without bloating `kernel.c`.