# NitigyaOS --- 004: Hardware Cursor

## Goal

After implementing `print()`, the next step is to control the **hardware
text cursor**.

Our `print()` function writes characters directly into VGA text memory,
but it does not yet tell the VGA hardware where the cursor should
appear.

------------------------------------------------------------------------

## VGA Hardware Cursor

The VGA text-mode cursor is controlled through **I/O ports**.

``` text
0x3D4 → Command / index port
0x3D5 → Data port
```

A useful mental model is:

``` text
0x3D4 → "Which VGA register do I want to access?"
0x3D5 → "What value should I put there?"
```

The cursor position is represented as a **16-bit number**.

Because the screen has 80 columns:

``` text
position = row × 80 + column
```

Examples:

``` text
0   → row 0, column 0
1   → row 0, column 1
79  → row 0, column 79
80  → row 1, column 0
81  → row 1, column 1
```

The VGA controller uses two registers for the cursor position:

``` text
14 → cursor high byte
15 → cursor low byte
```

So we have to send the two halves of the position separately.

------------------------------------------------------------------------

## I/O Ports vs Memory-Mapped I/O

We have now encountered two different ways of communicating with
hardware.

### VGA text memory

``` text
0xB8000
```

We access it like normal memory:

``` c
char* video_memory = (char*)0xB8000;
video_memory[0] = 'H';
```

### VGA I/O ports

``` text
0x3D4
0x3D5
```

These are accessed using x86 I/O instructions such as `out`.

``` text
Memory access
    ↓
write to memory address

Port I/O
    ↓
use x86 I/O instructions
```

This distinction becomes important as we interact with more hardware.

------------------------------------------------------------------------

## `outb()`

C cannot directly execute the x86 `out` instruction, so we create a
small assembly wrapper.

``` asm
global outb

outb:
    mov al, [esp + 8]
    mov dx, [esp + 4]
    out dx, al
    ret
```

C declaration:

``` c
void outb(unsigned short port, unsigned char data);
```

### What does `outb` mean?

`outb` means:

> **output a byte to an I/O port**

It takes:

``` text
port → 16-bit value
data → 8-bit value
```

The x86 `out` instruction then sends the byte in `AL` to the I/O port
stored in `DX`.

------------------------------------------------------------------------

## Understanding `AL` and `DX`

Registers are small, fast storage locations inside the CPU.

`EAX` is a 32-bit register:

``` text
EAX
┌────────────────────────────────┐
│             32 bits             │
└────────────────────────────────┘
              │
              ▼
             AX
       ┌──────────────┐
       │   16 bits     │
       └──────────────┘
          │        │
         AH       AL
        8-bit    8-bit
```

Similarly:

``` text
EDX
┌────────────────────────────────┐
│             32 bits             │
└────────────────────────────────┘
              │
              ▼
             DX
       ┌──────────────┐
       │   16 bits     │
       └──────────────┘
          │        │
         DH       DL
        8-bit    8-bit
```

For `outb()`:

``` text
DX → I/O port
AL → byte of data
```

So:

``` asm
mov al, [esp + 8]
```

loads the data byte into `AL`.

``` asm
mov dx, [esp + 4]
```

loads the port into `DX`.

Then:

``` asm
out dx, al
```

sends that byte to the hardware port.

------------------------------------------------------------------------

## Why `[esp + 4]` and `[esp + 8]`?

Our C function is:

``` c
void outb(unsigned short port, unsigned char data);
```

On 32-bit x86, the function arguments are passed on the stack using the
calling convention we are using.

Conceptually:

``` text
[ESP]     → return address
[ESP + 4] → port
[ESP + 8] → data
```

Therefore:

``` asm
mov dx, [esp + 4]
```

gets `port`.

And:

``` asm
mov al, [esp + 8]
```

gets `data`.

Then `ret` returns execution to the C code that called `outb()`.

------------------------------------------------------------------------

## `fb_move_cursor()`

Now we can use `outb()` to communicate with the VGA controller.

``` c
#define FB_COMMAND_PORT 0x3D4
#define FB_DATA_PORT 0x3D5

#define FB_HIGH_BYTE_COMMAND 14
#define FB_LOW_BYTE_COMMAND 15

void fb_move_cursor(unsigned short pos)
{
    outb(FB_COMMAND_PORT, FB_HIGH_BYTE_COMMAND);
    outb(FB_DATA_PORT, (pos >> 8) & 0x00FF);

    outb(FB_COMMAND_PORT, FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT, pos & 0x00FF);
}
```

The sequence is:

``` text
1. Select high-byte cursor register
2. Send high byte
3. Select low-byte cursor register
4. Send low byte
```

The book uses this same two-port mechanism for controlling the cursor.

------------------------------------------------------------------------

## Splitting the 16-bit Cursor Position

`pos` is a 16-bit value:

``` text
xxxxxxxx xxxxxxxx
   HIGH     LOW
```

We need to extract the two 8-bit halves.

### High byte

``` c
(pos >> 8) & 0x00FF
```

`>> 8` shifts the high byte down into the low-byte position.

The `& 0x00FF` keeps only the lowest 8 bits.

### Low byte

``` c
pos & 0x00FF
```

This keeps only the lowest 8 bits.

So the VGA controller receives:

``` text
16-bit cursor position
        │
        ├── high 8 bits → register 14
        │
        └── low 8 bits  → register 15
```

------------------------------------------------------------------------

## Testing the Cursor

In `kernel_main()`:

``` c
void kernel_main()
{
    print("Hello, NitigyaOS!");
    fb_move_cursor(80);
}
```

Since:

``` text
80 = 1 × 80 + 0
```

the cursor is moved to:

``` text
row 1
column 0
```

After booting in QEMU, the blinking cursor should appear at the
beginning of the second row.

------------------------------------------------------------------------

## Current Flow

``` text
kernel_main()
      │
      ├── print()
      │      │
      │      └── writes to VGA memory at 0xB8000
      │
      └── fb_move_cursor(80)
             │
             └── outb()
                    │
                    └── x86 `out`
                           │
                           ├── 0x3D4
                           └── 0x3D5
                                  │
                                  ▼
                            VGA controller
                                  │
                                  ▼
                            Hardware cursor
```

------------------------------------------------------------------------

## Current Achievement

-   [x] Write directly to VGA memory
-   [x] Implement `print()`
-   [x] Understand VGA text cells
-   [x] Understand I/O ports
-   [x] Implement `outb()`
-   [x] Understand `AL` and `DX`
-   [x] Implement `fb_move_cursor()`
-   [x] Successfully move and see the blinking hardware cursor

------------------------------------------------------------------------

## Key Idea

We now have two ways of interacting with the VGA hardware:

``` text
0xB8000
   ↓
VGA text memory
   ↓
write characters

0x3D4 / 0x3D5
   ↓
VGA I/O ports
   ↓
control the hardware cursor
```

The important concept is not memorizing the port numbers yet.

The important concept is understanding the path:

``` text
C
 ↓
assembly wrapper
 ↓
CPU instruction
 ↓
hardware I/O port
 ↓
VGA hardware
```

------------------------------------------------------------------------

## Next Step

Our `print()` function currently always starts writing from the
beginning of the screen.

The next step is to make it **track the current cursor position**, so
multiple calls such as:

``` c
print("Hello");
print(" NitigyaOS!");
```

continue writing instead of overwriting the previous text.

This will move our simple `print()` function toward an actual
text-output driver.
