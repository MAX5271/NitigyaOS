# NitigyaOS --- x86 Registers Notes

## Why Registers Matter

Registers are tiny, very fast storage locations inside the CPU.

``` text
RAM → large storage
CPU registers → tiny, extremely fast storage
```

The CPU uses registers constantly while executing instructions.

------------------------------------------------------------------------

# General-Purpose Registers

In 32-bit x86, the main general-purpose registers are:

``` text
EAX
EBX
ECX
EDX
ESI
EDI
EBP
ESP
```

For now, the most important ones are:

``` text
EAX → general calculations / accumulator
EDX → general-purpose / I/O
ESP → stack pointer
EBP → stack-frame base
```

------------------------------------------------------------------------

# EAX

`EAX` is a 32-bit general-purpose register.

``` text
        EAX
┌────────────────────────────────┐
│            32 bits             │
└────────────────────────────────┘
              │
              ▼
             AX
       ┌──────────────┐
       │   16 bits    │
       └──────────────┘
          │        │
         AH       AL
        8-bit    8-bit
```

Therefore:

``` text
EAX → 32 bits
AX  → lower 16 bits of EAX
AH  → upper 8 bits of AX
AL  → lower 8 bits of AX
```

For example:

``` asm
mov eax, 0x12345678
```

Conceptually:

``` text
EAX = 0x12345678
 AX = 0x5678
 AH = 0x56
 AL = 0x78
```

We used `AL` in `outb()` because the `out` instruction we are using
sends an 8-bit byte.

------------------------------------------------------------------------

# EDX

`EDX` is another 32-bit general-purpose register.

``` text
EDX → 32 bits
DX  → lower 16 bits
DH  → upper 8 bits of DX
DL  → lower 8 bits of DX
```

We currently use `DX` in `outb()`:

``` asm
mov dx, [esp + 4]
out dx, al
```

Here:

``` text
DX → I/O port
AL → byte of data
```

For:

``` c
outb(0x3D4, 14);
```

we conceptually get:

``` text
DX = 0x3D4
AL = 14

out DX, AL
```

------------------------------------------------------------------------

# ESP --- Stack Pointer

`ESP` means:

``` text
Extended Stack Pointer
```

It points to the **current top of the active stack**.

We initialize it in our boot assembly:

``` asm
mov esp, stack_top
```

After that, we normally do not manually update it.

Instructions such as:

``` text
push
pop
call
ret
```

automatically modify it.

------------------------------------------------------------------------

# Our Stack

We reserve 8192 bytes:

``` asm
section .bss

stack:
    resb 8192

stack_top:
```

Conceptually:

``` text
Higher addresses
        ↑
        │
   stack_top
        │
        ▼
   ┌──────────────┐
   │              │
   │  8192 bytes  │
   │              │
   └──────────────┘
        ▲
        │
      stack
        │
        ↓
Lower addresses
```

We initially do:

``` asm
mov esp, stack_top
```

So `ESP` starts at the high-address boundary of our reserved stack.

------------------------------------------------------------------------

# The Stack Grows Downward

On 32-bit x86, the stack grows toward lower memory addresses.

Suppose:

``` text
ESP = 0x8000
```

Then:

``` asm
push eax
```

moves `ESP` down by 4 bytes because `EAX` is 32 bits:

``` text
0x8000 - 4 = 0x7FFC
```

So:

``` text
ESP = 0x7FFC
```

and the value of `EAX` is stored there.

``` text
0x8000
────────────
unused

0x7FFC ← ESP
────────────
EAX
```

Important:

> ESP points to the current top of the active stack, not necessarily the
> highest memory address.

------------------------------------------------------------------------

# `push` and `pop`

For a 32-bit value:

``` text
push → ESP decreases by 4
pop  → ESP increases by 4
```

Example:

``` asm
mov esp, 0x8000

push eax
```

Result:

``` text
ESP = 0x7FFC
```

Then:

``` asm
push ebx
```

Result:

``` text
ESP = 0x7FF8
```

Memory:

``` text
0x8000
────────────
unused

0x7FFC
────────────
EAX

0x7FF8 ← ESP
────────────
EBX
```

Therefore:

> ESP points to the most recently pushed item.

------------------------------------------------------------------------

# `call` and `ret`

Function calls also use the stack.

Conceptually:

``` asm
call function
```

does two things:

``` text
1. Put the return address on the stack
2. Jump to the function
```

Therefore `call` causes `ESP` to move downward.

When the function executes:

``` asm
ret
```

the CPU takes the return address from the stack and returns to it.

So conceptually:

``` text
call → ESP moves down
ret  → ESP moves up
```

Our loader uses:

``` asm
mov esp, stack_top
call kernel_main
```

We initialize the stack once, and `call`/`ret` handle the necessary
stack movement.

------------------------------------------------------------------------

# Function Arguments and ESP

Our C function is:

``` c
void outb(unsigned short port, unsigned char data);
```

On the 32-bit calling convention used here, the stack is conceptually
arranged like:

``` text
[ESP]     → return address
[ESP + 4] → port
[ESP + 8] → data
```

Therefore:

``` asm
mov dx, [esp + 4]
```

gets the port.

And:

``` asm
mov al, [esp + 8]
```

gets the data byte.

For:

``` c
outb(0x3D4, 14);
```

we get:

``` text
DX = 0x3D4
AL = 14
```

------------------------------------------------------------------------

# Why `+4` and `+8`?

A 32-bit stack slot occupies 4 bytes.

Conceptually:

``` text
[ESP]
────────────
return address
────────────
[ESP + 4]
────────────
port
────────────
[ESP + 8]
────────────
data
────────────
```

So we move through the stack in 4-byte increments.

------------------------------------------------------------------------

# EBP

`EBP` means:

``` text
Extended Base Pointer
```

It is commonly used as a reference point for a function's stack frame.

Conceptually:

``` text
EBP
 ↓
┌──────────────┐
│ old EBP      │
├──────────────┤
│ return addr  │
├──────────────┤
│ argument     │
├──────────────┤
│ local var    │
└──────────────┘
```

Modern compilers do not always use `EBP` this way, but it is important
to recognize it when studying stack frames and function calls.

------------------------------------------------------------------------

# EIP --- Instruction Pointer

`EIP` means:

``` text
Extended Instruction Pointer
```

It keeps track of the instruction location being executed.

Conceptually:

``` text
EIP
 ↓
mov eax, 10
        ↓
mov ebx, 20
        ↓
add eax, ebx
```

This becomes especially important when we study:

-   interrupts
-   exceptions
-   context switching
-   multitasking
-   system calls

------------------------------------------------------------------------

# EFLAGS

`EFLAGS` stores CPU status and control flags.

Examples:

``` text
ZF → Zero Flag
CF → Carry Flag
SF → Sign Flag
OF → Overflow Flag
IF → Interrupt Flag
```

For now:

> EFLAGS describes aspects of CPU state and controls certain CPU
> behavior.

We will study individual flags when they become relevant.

------------------------------------------------------------------------

# Segment Registers

x86 also has segment registers:

``` text
CS
DS
ES
FS
GS
SS
```

Important ones to recognize:

``` text
CS → Code Segment
SS → Stack Segment
```

These become relevant when we study GDT and segmentation.

For now, recognition is enough.

------------------------------------------------------------------------

# Control Registers

Later we will encounter:

``` text
CR0
CR2
CR3
CR4
```

One particularly important register when we reach paging is:

``` text
CR3
 ↓
used with paging structures
```

These will make much more sense when we reach virtual memory and paging.

------------------------------------------------------------------------

# CPU Registers vs Hardware Registers

This distinction is extremely important.

## CPU Registers

These belong to the CPU:

``` text
EAX
EBX
ECX
EDX
ESP
EBP
EIP
EFLAGS
```

## VGA Hardware Registers

These belong to the VGA controller.

For our cursor:

``` text
VGA register 14 → cursor high byte
VGA register 15 → cursor low byte
```

We select these VGA registers through:

``` text
0x3D4 → command/index port
0x3D5 → data port
```

So:

``` c
#define FB_HIGH_BYTE_COMMAND 14
#define FB_LOW_BYTE_COMMAND 15
```

does **not** refer to CPU registers.

It refers to registers inside the VGA controller.

------------------------------------------------------------------------

# The Complete Picture

``` text
                         CPU
        ┌────────────────────────────────┐
        │                                │
        │ EAX  EBX  ECX  EDX             │
        │ ESP  EBP  EIP                  │
        │ EFLAGS                         │
        │                                │
        └───────────────┬────────────────┘
                        │
                  CPU instructions
                        │
             ┌──────────┴──────────┐
             │                     │
           Memory               I/O Ports
          0xB8000                 0x3D4
             │                     │
             ▼                     ▼
       VGA text buffer       VGA controller
                                   │
                              ┌────┴────┐
                              │         │
                         Register 14  Register 15
                              │         │
                         Cursor HIGH  Cursor LOW
```

------------------------------------------------------------------------

# Registers to Know Right Now

## Must Know

``` text
EAX → general-purpose / accumulator
EDX → general-purpose / I/O
ESP → stack pointer
EIP → instruction pointer
```

## Should Recognize

``` text
EBX
ECX
ESI
EDI
EBP
EFLAGS
```

## Later

``` text
CS DS ES FS GS SS
CR0 CR2 CR3 CR4
```

Remember:

``` text
EAX → AX → AH / AL
EDX → DX → DH / DL
```

------------------------------------------------------------------------

# Key Takeaways

### 1. ESP is initialized by us

``` asm
mov esp, stack_top
```

### 2. ESP is then moved automatically

``` text
push → ESP down
pop  → ESP up
call → ESP down
ret  → ESP up
```

### 3. The stack grows downward

``` text
HIGH ADDRESS
     │
     │ initial ESP
     ▼
     │
     │ stack grows ↓
     ▼
LOW ADDRESS
```

### 4. ESP points to the current top of the active stack

Not necessarily the highest memory address.

### 5. CPU registers and hardware registers are different

``` text
EAX / ESP / EIP
      ↓
CPU registers

VGA register 14 / 15
      ↓
VGA hardware registers
```

### 6. Learn registers as they become relevant

``` text
encounter → understand → use → remember
```

That is more useful for OS development than memorizing a giant list of
registers.
