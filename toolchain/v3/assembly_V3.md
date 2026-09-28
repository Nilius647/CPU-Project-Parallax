# Parallax V3 — Assembly guide

Reference for writing programs to be assembled with `parallax_asm_v3.py`.

---

## What changes from V2

| New | Effect on your code |
|---|---|
| `MUL` | multiplying no longer needs a loop |
| `CAL` / `RET` | repeated code is written once |
| `LDP` / `STP` | arrays and data structures become possible |
| `JMR` | jump tables and computed jumps |
| 16-bit addresses | memory no longer stops at 256 words |
| `ov` flag | product overflow detection |

Syntax, registers and pseudo-instructions are identical to V2. **Opcodes are
renumbered**, so V2 machine code does not run on V3 — the source does.

This guide covers **only what is new**. For arithmetic, logic, shifts, `LDI`,
constant-address memory, ports and pseudo-instructions, the V2 guide still
applies — with four exceptions, where V3 supersedes it:

| In the V2 guide | In V3 |
|---|---|
| "256 RAM words, `0x0000`–`0x00FF`" | 1024 words, `0x0000`–`0x03FF` |
| "no arrays, no pointers" | `LDP` / `STP` (§5) |
| "no subroutines" | `CAL` / `RET` (§4) |
| "no `MUL`, build it with loops" | `MUL` in a single instruction (§3) |

Everything else in the V2 guide holds unchanged.

---

## 1. File structure

One instruction per line.

```
; comment
loop:
        DEC  r1, r1
        BRH  nz, loop
        HLT
```

- **Comments**: `;`, `//` or `#`
- **Labels**: a name followed by a colon. They cannot share a name with a
  mnemonic: `sub:` is an error, because `SUB` is an instruction
- **Case**: irrelevant
- **Separators**: commas or spaces
- **Numbers**: `255`, `0xFF`, `0b11111111`, `-1` (two's complement)

---

## 2. Operand order

Unchanged from V2, but it now covers more instructions.

| Type | Syntax | Where the result goes |
|---|---|---|
| Two-source ALU | `ADD rA, rB, rC` | **last** |
| One-source ALU | `NOT rA, rC` | **last** |
| Load immediate | `LDI rA, imm` | **first** |
| Memory read | `LOD rA, addr` | **first** |
| Indirect read | `LDP rA, rB` | **first** — `rB` is the pointer |
| Memory write | `STR rA, addr` | none — `rA` is the source |
| Indirect write | `STP rA, rB` | none — `rA` the data, `rB` the pointer |

For `LDP` and `STP` the rule is: **the first operand is always the data, the
second always the pointer.** The mnemonic supplies the direction.

---

## 3. Multiplication

```asm
        MUL  r1, r2, r3     ; r3 = (r1 * r2) truncated to 16 bits
```

The full product of two 16-bit values takes 32 bits. `MUL` returns **the low 16
bits only**.

### Checking for overflow

```asm
        MUL  r1, r2, r3
        BRH  ov, too_big
```

The `ov` flag is raised when the high half of the product is non-zero — that is,
when the result does not fit in 16 bits.

### A trap

> **`BRH z` after a `MUL` does not mean "the product is zero".**

It means the *low* 16 bits are zero. `0x0100 × 0x0100` gives `0x00010000`: the
low half is empty, so `z` is raised, but the product is 65536. To find out
whether the product is really zero you need both conditions:

```asm
        MUL  r1, r2, r3
        BRH  ov, not_zero
        BRH  z, is_zero
```

---

## 4. Subroutines

```asm
        LDI  r1, 10
        CAL  double
        ; r1 is now 20
        HLT

double:
        SHL  r1, r1
        RET
```

`CAL` saves the return address on a dedicated hardware stack and jumps. `RET`
retrieves it. Neither instruction touches any register by itself.

### Document what gets clobbered

`CAL` leaves registers alone, but **the body of the subroutine does not**. At the
call site you cannot see what is inside, so write it down:

```asm
; double: r1 = r1 * 2
; clobbers: nothing
double:
        SHL  r1, r1
        RET
```

With nested subroutines you need the clobber set of the whole tree: if `A` calls
`B`, the comment on `A` must include whatever `B` destroys.

### Sixteen levels, and no warning

The return stack is 16 deep. The seventeenth nested `CAL` overwrites the first
saved address and the program will return to the wrong place — with no error at
all. The same goes for a `RET` without a matching `CAL`.

With recursion, remember there are no local variables: every level shares the
same registers.

### Flags do not survive a call

```asm
        CMP  r1, r2
        CAL  something      ; the body contains ALU operations
        BRH  eq, ...        ; condition already destroyed
```

The V2 rule still holds — the instruction that sets the flags must be the last
ALU operation before the `BRH` — but subroutines make it far easier to break
without noticing, because the code that destroys them is not in front of you.

---

## 5. Pointers

A pointer is an ordinary register holding an address.

```asm
        LDI  r1, 0x0100     ; r1 points at MEM[0x0100]
        LDP  r2, r1         ; r2 = MEM[0x0100]
        INC  r1, r1         ; advance
        LDP  r3, r1         ; r3 = MEM[0x0101]
```

No special instruction is needed to advance a pointer: ALU operations and ADI all work,
because it is a register like any other.

### The two instructions

| | Constant address | Address from a register |
|---|---|---|
| Read | `LOD rA, addr` | **`LDP rA, rB`** |
| Write | `STR rA, addr` | **`STP rA, rB`** |

The mnemonics follow the V1 logic: `LOD` and `STR` become `LDP` and `STP` when
the address comes from a register instead of from the instruction.

In both, **the first operand is the data and the second is the pointer.** That
does not flip with direction — the mnemonic is what says which way the bits go:

```asm
        LDI  r1, 0x0200     ; pointer
        LDI  r2, 0x00FF     ; value to write

        STP  r2, r1         ; MEM[0x0200] = r2
        INC  r1, r1
        STP  r2, r1         ; MEM[0x0201] = r2

        LDI  r1, 0x0200     ; back to the start
        LDP  r3, r1         ; r3 = MEM[0x0200]
```

Mind the order: `STP r2, r1` reads "store r2 where r1 points", not "store into r2".

### Erasing a block of memory

```asm
; zero r2 words starting at r1
        LDI r1 0x0200  ; address to start with
        LDI r2 3       ; number of addresses to erase
        CLR  r3
zero_loop:
        STP  r3, r1    ; loads zero in the starting address
        INC  r1, r1
        DEC  r2, r2
        BRH  nz, zero_loop
```

### Summing an array

The idiom V2 could not express:

```asm
; sum MEM[0x0100 .. 0x010F] into r3
        LDI  r1, 0x0100     ; pointer
        LDI  r2, 16         ; counter
        CLR  r3             ; accumulator
loop:
        LDP  r4, r1
        ADD  r3, r4, r3
        INC  r1, r1
        DEC  r2, r2         ; last ALU op before the branch
        BRH  nz, loop
```

Eight instructions, and it works for any length: change the counter, not the
code. V2 needed two instructions per element.

### No offset

`LDP rA, rB` reads from exactly `rB`, with no displacement. For the third field
of a structure, compute the address first:

```asm
        MOV  r1, r5
        ADI  r5, 2          ; r5 = base + 2
        LDP  r6, r5
```

---

## 6. Computed jumps

```asm
        JMR  r1             ; Program counter = r1
```

The register is 16 bits, the PC is 8: `JMR` uses **only the low 8 bits**.

### Jump table

The table lives **in memory**, not in the code: it holds program addresses to be
loaded into a register and used with `JMR`.

```asm
; build the table in MEM[0x0200 .. 0x0203]
        LDI  r4, case_zero
        STR  r4, 0x0200
        LDI  r4, case_one
        STR  r4, 0x0201
        ; ... and so on

; jump to the case selected by r1 (0-3)
        LDI  r2, 0x0200     ; table base
        ADD  r2, r1, r2     ; address of the entry
        LDP  r3, r2         ; read the destination
        JMR  r3
```

**A label can be used as an immediate**, not only as a branch target:
`LDI r4, case_zero` loads the address of the labelled instruction into `r4`.
That is what makes building the table possible.

---

## 7. Flags and conditions

| Name | True when |
|---|---|
| `c` or `carry` | a carry came out |
| `nc` | no carry came out |
| `z` or `zero` | the result was zero |
| `nz` | the result was not zero |
| `eq` | the operands were equal |
| `lt` | the first was less than the second (unsigned) |
| `gt` | the first was greater than the second (unsigned) |
| `ov` or `overflow` | **new** — the product does not fit in 16 bits |

Comparisons remain **unsigned**: `0xFFFF` is greater than 1, not less.

Flags are updated by the **16 ALU operations** (`MUL` included) and `ADI`. Not
touched by: `NOP`, `HLT`, `CAL`, `RET`, `LDI`, branches, memory, ports.

---

## 8. Idioms

### Counted loop

The body goes before the decrement, so the flags reach the branch intact.

```asm
        LDI  r1, 10
loop:
        ; body
        DEC  r1, r1
        BRH  nz, loop
```

### Conditional (if, else)

```asm
        CMP  r1, r2
        BRH  eq, same
        JMP  after
same:
after:
```

### Copying a block of memory

```asm
; copy r3 words from r1 to r2
copy:
        LDP  r4, r1
        STP  r4, r2
        INC  r1, r1      ; pointer + 1
        INC  r2, r2      ; destination + 1
        DEC  r3, r3      ; one less element to copy
        BRH  nz, copy
        RET
```

Six instructions for a routine reusable anywhere — pointers plus subroutines are
what make code like this possible.

### Squaring

```asm
        MUL  r1, r1, r2     ; r2 = r1^2
```

---

## 9. Limits to keep in mind

| Limit | Consequence |
|---|---|
| 256 instructions | the assembler rejects longer programs |
| 16-level return stack | wraps silently on the seventeenth |
| No data stack | no way to save registers across calls |
| No pointer offsets | the address must be computed first |
| `MUL` truncates to 16 bits | check `ov` when the values are large |
| Unsigned comparisons | watch out above `0x7FFF` |
| One-position shifts | n positions = n instructions |
| Word-addressed memory | you address 16-bit words, not bytes |

The address space is 65536 words, but the RAM installed is **1024 words (2 KB)**:
valid addresses run from `0x0000` to `0x03FF`. Writing beyond that raises no
error — the access wraps to the start of memory, so `0x0400` lands on `0x0000`.

---

## 10. Complete example

Sum of squares of eight values, with an overflow check.

```asm
; Sum of squares — Parallax V3
;   r1 = pointer    r2 = counter   r3 = accumulator
;   r4 = element    r5 = square

        LDI  r1, 0x0100     ; start of array
        LDI  r2, 8
        CLR  r3

loop:
        LDP  r4, r1         ; read the element
        MUL  r4, r4, r5     ; square it
        BRH  ov, overflow   ; the square did not fit
        ADD  r3, r5, r3     ; accumulate
        INC  r1, r1
        DEC  r2, r2         ; last ALU op before the branch
        BRH  nz, loop

        STR  r3, 0x0000     ; result in MEM[0]
        HLT

overflow:
        LDI  r3, 0xFFFF     ; error marker
        STR  r3, 0x0000
        HLT
```

---

## 11. Assembling

```
python3 parallax_asm_v3.py (FILE NAME) --format bin -o build/
```

Produces `build/rom_high.txt` and `build/rom_low.txt`, to be pasted into the
matching ROM chips after selecting binary representation in the editor.

To check the encoding field by field:

```
python3 parallax_asm_v3.py (FILE NAME) --listing
```
