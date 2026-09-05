# 004 — Make

## Goal

Automate the NitigyaOS build process so we do not have to manually compile, link, create the ISO, and launch QEMU every time.

---

## Why Make?

Our build has multiple steps and dependencies:

```text
loader.s
   ↓ NASM
loader.o
        ↘
          ld → kernel.elf
        ↗
kernel.o
   ↑
kernel.c
```

After linking, the kernel is placed into an ISO that GRUB can boot.

Doing all of this manually after every change becomes repetitive.

**Make** lets us describe the build dependencies once and then use:

```bash
make
```

to build the project.

---

## Makefile Basics

A Make rule has the general form:

```make
target: prerequisites
	command
```

There are three important parts:

### Target

The file or action we want to create.

Example:

```make
src/kernel.o
```

### Prerequisites

The files needed to create the target.

Example:

```make
src/kernel.o: src/kernel.c
```

This means:

```text
kernel.c → kernel.o
```

### Recipe

The command used to create the target.

```make
src/kernel.o: src/kernel.c
	gcc -m32 -ffreestanding -c src/kernel.c -o src/kernel.o
```

The recipe line must begin with a **TAB**.

---

## Dependency Tree

Our Makefile describes this relationship:

```text
                 src/kernel.elf
                  /          \
                 /            \
        src/loader.o       src/kernel.o
             ↑                  ↑
        src/loader.s        src/kernel.c
```

Make uses this dependency tree to determine what needs to be rebuilt.

---

## Current Makefile

```make
all: iso

src/kernel.o: src/kernel.c
	gcc -m32 -ffreestanding -c src/kernel.c -o src/kernel.o

src/loader.o: src/loader.s
	nasm -f elf32 src/loader.s -o src/loader.o

src/kernel.elf: src/loader.o src/kernel.o
	ld -m elf_i386 -T src/link.ld src/loader.o src/kernel.o -o src/kernel.elf

iso: src/kernel.elf
	rm -rf iso
	mkdir -p iso/boot/grub
	cp src/kernel.elf iso/boot/kernel.elf
	cp src/stage2_eltorito iso/boot/grub/
	printf "default 0\ntimeout 0\n\ntitle NitigyaOS\nkernel /boot/kernel.elf\n" > iso/boot/grub/menu.lst
	genisoimage -R -b boot/grub/stage2_eltorito \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-o nitigyaos.iso iso

run: iso
	qemu-system-i386 -cdrom nitigyaos.iso
```

---

## `all`

```make
all: iso
```

`all` is the default target.

Running:

```bash
make
```

therefore asks Make to build:

```text
all
 ↓
iso
```

---

## How Make Decides What to Rebuild

Make checks the timestamps of targets and their prerequisites.

For example:

```text
kernel.c
   ↓
kernel.o
   ↓
kernel.elf
```

If `kernel.c` changes:

```text
kernel.c changed
      ↓
kernel.o must be rebuilt
      ↓
kernel.elf must be rebuilt
```

But if `loader.s` has not changed, Make does not need to rebuild `loader.o`.

This means Make avoids unnecessary work.

---

## Testing Make's Dependency System

We tested this using:

```bash
touch src/kernel.c
```

Then:

```bash
make
```

Make detected that `kernel.c` had a newer timestamp and rebuilt the affected files.

This demonstrated that Make is actually following the dependency graph rather than blindly executing every command.

---

## Building the ISO

The `iso` target depends on:

```make
iso: src/kernel.elf
```

It:

1. Removes the old ISO directory.
2. Creates the required GRUB directories.
3. Copies `kernel.elf`.
4. Copies `stage2_eltorito`.
5. Creates `menu.lst`.
6. Uses `genisoimage` to create `nitigyaos.iso`.

The resulting structure is:

```text
iso/
└── boot/
    ├── kernel.elf
    └── grub/
        ├── menu.lst
        └── stage2_eltorito
```

---

## Running the OS

We added:

```make
run: iso
	qemu-system-i386 -cdrom nitigyaos.iso
```

Now:

```bash
make run
```

means:

```text
make run
   ↓
build ISO if necessary
   ↓
launch QEMU
   ↓
boot NitigyaOS
```

Our current development loop is therefore:

```text
edit code
   ↓
make run
   ↓
test NitigyaOS
   ↓
edit code
   ↓
make run
   ↓
...
```

---

## Important Make Concept

Make is not simply a list of commands.

It describes **relationships between files**.

For example:

```make
src/kernel.elf: src/loader.o src/kernel.o
```

means:

> `kernel.elf` depends on `loader.o` and `kernel.o`.

This dependency information is what allows Make to determine what needs rebuilding.

---

## Current Achievement

- [x] Understand target
- [x] Understand prerequisite
- [x] Understand recipe
- [x] Create a Makefile
- [x] Automate C compilation
- [x] Automate Assembly compilation
- [x] Automate linking
- [x] Automate ISO creation
- [x] Add QEMU run target
- [x] Test Make's dependency checking

---

## Current Build Flow

```text
                    ┌──→ loader.o ──┐
                    │               │
src/loader.s ──→ NASM               │
                                    ├──→ kernel.elf
src/kernel.c ──→ GCC ──→ kernel.o ──┘
                                    ↓
                              GRUB ISO
                                    ↓
                                  QEMU
```

---

## Useful Commands

Build:

```bash
make
```

Build and run:

```bash
make run
```

Force a source file's timestamp to change without modifying its contents:

```bash
touch src/kernel.c
```

---

## Key Idea

> **Make describes dependencies so that only the parts affected by a change need to be rebuilt.**

Instead of manually remembering the entire build process, we can now use:

```bash
make run
```

---

## Next Step

Return to kernel development and build a proper `print()` function.

We will combine:

- C strings
- loops
- VGA memory
- screen positions

to move from manually writing:

```c
video_memory[0] = 'H';
video_memory[1] = 0x07;
```

to something like:

```c
print("Hello, NitigyaOS!");
```

---

## Reference

Chapter 2 — The Tools.

The book introduces Make as one of the tools used to automate the OS development build process.
