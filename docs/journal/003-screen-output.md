# 003 — Screen Output

## Goal

Make NitigyaOS display text directly on the screen from C.

---

## VGA Text Buffer

In the VGA text mode used by the book, the screen is represented by a memory region starting at:

```text
0xB8000
```

The screen has:

```text
80 columns × 25 rows
```

Writing to this memory changes what is displayed on the screen.

---

## Character Format

Each screen position uses **2 bytes**:

```text
┌─────────────┬─────────────┐
│  character  │    color    │
│   1 byte    │   1 byte    │
└─────────────┴─────────────┘
```

For example:

```text
'H'  0x07
```

means:

- `'H'` → character to display
- `0x07` → color/attribute

Therefore the first screen position uses:

```text
0xB8000 → character
0xB8001 → color
```

The next position uses:

```text
0xB8002 → character
0xB8003 → color
```

So the memory pattern is:

```text
character → color → character → color → ...
```

---

## Accessing Video Memory in C

We use:

```c
char* video_memory = (char*) 0xB8000;
```

This has two important parts.

### `char* video_memory`

`video_memory` is a **pointer to char**.

It stores a memory address rather than a character itself.

### `(char*) 0xB8000`

This is an **explicit type conversion (cast)**.

`0xB8000` is an integer value representing an address.

The cast tells C:

> Treat `0xB8000` as an address pointing to `char`.

So:

```text
0xB8000
   ↓
(char*)
   ↓
pointer to char
```

---

## First Screen Output

Our first implementation was:

```c
void kernel_main()
{
    char* video_memory = (char*) 0xB8000;

    video_memory[0] = 'H';
    video_memory[1] = 0x07;
}
```

This writes:

```text
0xB8000 → 'H'
0xB8001 → 0x07
```

and produces:

```text
H
```

at the top-left of the screen.

---

## Printing Multiple Characters

To print `HI`:

```c
video_memory[0] = 'H';
video_memory[1] = 0x07;

video_memory[2] = 'I';
video_memory[3] = 0x07;
```

Memory looks like:

```text
Address   Value
0xB8000   'H'
0xB8001   0x07
0xB8002   'I'
0xB8003   0x07
```

Result:

```text
HI
```

---

## Why the Characters Appear at the Top-Left

The first screen cell corresponds to the beginning of the VGA text buffer:

```text
0xB8000
```

Therefore:

```c
video_memory[0]
```

writes the character in the first cell.

---

## Important Concept

We are **not calling a display API**.

There is no:

```c
printf()
```

There is no terminal.

There is no operating system underneath us providing screen functions.

We are directly writing to the hardware's text buffer through memory.

```text
C code
  ↓
video_memory
  ↓
0xB8000
  ↓
VGA text buffer
  ↓
screen
```

This is one of the first examples of kernel code interacting directly with hardware.

---

## Current Achievement

- [x] Access VGA text memory
- [x] Understand `char*`
- [x] Understand explicit pointer cast `(char*)`
- [x] Write a character to the screen
- [x] Write multiple characters
- [x] Boot and verify output in QEMU

NitigyaOS successfully displayed:

```text
HI
```

---

## What We Learned

### Pointer

```c
char* video_memory;
```

A pointer stores an address.

### Explicit Cast

```c
(char*) 0xB8000
```

Treat the integer address `0xB8000` as a pointer to `char`.

### Array Indexing

```c
video_memory[0]
video_memory[1]
video_memory[2]
```

Accesses consecutive bytes in memory.

### Hardware Through Memory

Writing to a special memory region can directly affect hardware behavior.

---

## Current Flow

```text
GRUB
 ↓
loader.s
 ↓
stack setup
 ↓
kernel_main()
 ↓
video_memory = 0xB8000
 ↓
write character + color
 ↓
VGA text buffer
 ↓
screen
```

---

## Next Step

Writing every character manually is obviously inconvenient.

We want to be able to write something like:

```c
print("Hello, NitigyaOS!");
```

To do that, we will create a small **print function** that:

1. Takes a string.
2. Loops through its characters.
3. Places each character in the correct VGA buffer position.
4. Adds the color byte for each character.

The next concept will therefore be **strings and loops in C**, combined with VGA memory addressing.

---

## Reference

Chapter 4 — Output.

The book introduces VGA text output using the video memory at `0xB8000`. The screen is treated as an 80×25 text grid, with two bytes used for each character position.
