# Parallax V2 — Assembly guide

Reference for writing programs to be assembled with `parallax_asm.py`.

---

## 1. File structure

One instruction per line. Labels sit on their own line or at the start of one.

```
; this is a comment
        LDI  r1, 10         ; end-of-line comment
loop:
        DEC  r1, r1
        BRH  nz, loop
        HLT
```

- **Comments**: `;`, `//` or `#`, to end of line
- **Labels**: a name followed by a colon. They stand for the address of the
  instruction that follows, not for a value
- **Case**: irrelevant. `ldi`, `LDI` and `Ldi` are the same
- **Separators**: commas or spaces, both accepted. `ADD r1, r2, r3` and
  `ADD r1 r2 r3` are identical
- **Indentation**: free, ignored

### Numbers

| Form | Example | Value |
|---|---|---|
| Decimal | `255` | 255 |
| Hexadecimal | `0xFF` | 255 |
| Binary | `0b11111111` | 255 |
| Negative | `-1` | `0xFFFF` in two's complement |

---

## 2. Operand order

The destination is not always in the same position — it depends on the instruction format.

| Type | Syntax | Where the result goes |
|---|---|---|
| Two-source ALU | `ADD rA, rB, rC` | **last** — `rC = rA + rB` |
| One-source ALU | `NOT rA, rC` | **last** — `rC = ¬rA` |
| Load immediate | `LDI rA, imm` | **first** — `rA = imm` |
| Memory read | `LOD rA, addr` | **first** — `rA = MEM[addr]` |
| Memory write | `STR rA, addr` | none — `rA` is the source |

Rule of thumb: in ALU operations the destination comes last; everywhere else the
first register named is the one that changes — except `STR`, where it is the
source.

---

## 3. Registers

Sixteen registers, `r0` through `r15`, 16 bits each.

**`r0` is always zero.** It holds nothing: reading it yields 0, writing to it has
no effect.

The other fifteen are free. With no subroutines there is no calling convention to
follow, so use them as you like — but keep a comment at the top of the program
saying what holds what, because fifteen unnamed registers get confusing fast.

---

## 4. The instructions

### Arithmetic

```
        ADD  r1, r2, r3     ; r3 = r1 + r2
        SUB  r1, r2, r3     ; r3 = r1 - r2
        INC  r1, r2         ; r2 = r1 + 1
        DEC  r1, r2         ; r2 = r1 - 1
        ADI  r1, 100        ; r1 = r1 + 100   (the immediate may be negative)
```

`ADI` is the only instruction that adds an immediate to a register. There is no
`SUI`: to subtract a constant, use `ADI` with a negative value.

```
        ADI  r1, -5         ; r1 = r1 - 5
```

### Bitwise logic

```
        NOT    r1, r2           ; r2 = NOT r1
        AND    r1, r2, r3       ; r3 = r1 AND r2
        OR     r1, r2, r3
        XOR    r1, r2, r3
        NAND   r1, r2, r3
        NOR    r1, r2, r3
        XNOR   r1, r2, r3
        IMPLY  r1, r2, r3       ; r3 = (NOT r1) OR r2
        NIMPLY r1, r2, r3       ; r3 = r1 AND (NOT r2)
```

### Shifts

```
        SHL  r1, r2         ; r2 = r1 * 2
        SHR  r1, r2         ; r2 = r1 / 2  (integer division)
```

One position per instruction. Shifting by n positions takes n instructions.

### Load immediate

```
        LDI  r1, 0x1234     ; r1 = 4660
        LDI  r2, 0b1010     ; r2 = 10
```

The immediate is a full 16 bits: one `LDI` loads any value in a single
instruction.

### Memory

```
        STR  r1, 0x0010     ; MEM[16] = r1
        LOD  r2, 0x0010     ; r2 = MEM[16]
```

The address is always a **constant**. There is no `LOD r1, [r2]`.

### Ports

```
        PSR  r1, 3          ; OUT[3] = r1
        PLR  r1, 3          ; r1 = IN[3]
        PSM  3, 0x0010      ; OUT[3] = MEM[16]
        PLM  3, 0x0010      ; MEM[16] = IN[3]
```

Inputs and outputs are separate spaces: `OUT[3]` and `IN[3]` are physically
different ports. What you write cannot be read back.

### Branches

```
        JMP  label          ; unconditional
        BRH  z, label       ; taken if the condition holds (conditions listed below)
```

### Control

```
        NOP                 ; does nothing, advances the PC
        HLT                 ; stops the clock
```

**Always end programs with `HLT`.** Unused ROM cells read as zero, and zero is
`ADD r0, r0, r0`: without `HLT` the CPU runs on through empty memory until the PC
wraps and the program restarts.

---

## 5. Pseudo-instructions

These do not exist in hardware — the assembler expands them using `r0`.

| You write | Becomes | Effect |
|---|---|---|
| `MOV r1, r2` | `ADD r0, r1, r2` | `r2 = r1` |
| `CLR r1` | `ADD r0, r0, r1` | `r1 = 0` |
| `NEG r1, r2` | `SUB r0, r1, r2` | `r2 = -r1` |
| `CMP r1, r2` | `SUB r1, r2, r0` | updates flags, writes nothing |

`CMP` compares two registers without wasting one on a result you do not want.

---

## 6. Flags and conditions

Conditions available to `BRH`:

| Name | True when |
|---|---|
| `c` or `carry` | a carry came out |
| `nc` | no carry came out |
| `z` or `zero` | the result was zero |
| `nz` | the result was not zero |
| `eq` | the two operands were equal |
| `lt` | the first was less than the second |
| `gt` | the first was greater than the second |

**Comparisons are unsigned.** `lt` and `gt` treat registers as values from 0 to
65535. If you are working with values you think of as negative, `0xFFFF` compares
as *greater* than 1, not less.

**Only ALU operations and `ADI` update the flags.** `LDI`, `LOD`, `STR`, the port
instructions and the branches leave them untouched. This is useful — a comparison
survives intervening instructions — but it imposes one rule:

> The instruction that sets the flags must be the last ALU operation before the
> `BRH`. Any other ALU operation in between overwrites them.

---

## 7. Idioms

### Counted loop

The body goes **before** the decrement, so the flags reach the `BRH` intact.

```
        LDI  r1, 10         ; counter
loop:
        ; ---- loop body ----
        ADI  r2, 1
        ; ---- end body ----
        DEC  r1, r1         ; last ALU op before the branch
        BRH  nz, loop
```

Careful: if the counter starts at 0, the loop runs 65536 times.

### Conditional

```
        CMP  r1, r2
        BRH  eq, same
        ; "different" case
        JMP  after
same:
        ; "equal" case
after:
```

### While loop

```
loop:
        CMP  r1, r2
        BRH  eq, done       ; exit once they become equal
        ; body
        INC  r1, r1
        JMP  loop
done:
```

Here the `CMP` is at the top, so the body may contain anything: the comparison is
redone every iteration.

### Multiplication

There is no `MUL`. Use repeated addition.

```
; r5 = r1 * r2
        CLR  r5
        MOV  r2, r6         ; copy: the counter gets destroyed
        CMP  r6, r0
        BRH  eq, mul_done   ; guard: if r2 = 0 the result is 0
mul:
        ADD  r5, r1, r5     ; r5 += r1
        DEC  r6, r6
        BRH  nz, mul
mul_done:
```

The guard is not optional: without it, `r2 = 0` runs 65536 iterations.

### Multi-position shift

```
; r2 = r1 * 8
        SHL  r1, r2
        SHL  r2, r2
        SHL  r2, r2
```

### Writing a sequence to memory

**This is V2's most annoying limitation.** With no indirect addressing you cannot
walk an array: every address must be a constant written into the instruction.

```
        STR  r1, 0x0000
        STR  r2, 0x0001
        STR  r3, 0x0002     ; ... one per location
```

Storing twenty values costs twenty of your 256 instructions. This is why `LDP` /
`STP` sit at the top of the V3 list.

### Repeated code

There are no subroutines — `CAL` and `RET` arrive in V3. A block needed in three
places must be written three times. With 256 instructions total, this is the
constraint that decides how large a program can be.

---

## 8. Limits to keep in mind

| Limit | Consequence |
|---|---|
| 256 instructions | the assembler rejects longer programs |
| 256 RAM words | addresses `0x0000` to `0x00FF` |
| Constant addresses | no arrays, no pointers |
| No subroutines | repeated code must be duplicated |
| Unsigned comparisons | watch out above `0x7FFF` |
| No `MUL` / `DIV` | build them with loops |
| One-position shifts | n positions = n instructions |
| Word-addressed memory | you address 16-bit words, not bytes |

---

## 9. Complete example

Fibonacci: ten iterations, result in `r2` and stored to `MEM[0]`.

```
; Fibonacci — Parallax V2
;   r1 = previous term
;   r2 = current term
;   r3 = counter
;   r4 = scratch

        LDI  r1, 0
        LDI  r2, 1
        LDI  r3, 10

loop:
        ADD  r1, r2, r4     ; r4 = r1 + r2
        MOV  r2, r1         ; r1 = r2
        MOV  r4, r2         ; r2 = r4
        DEC  r3, r3         ; last ALU op before the branch
        BRH  nz, loop

        STR  r2, 0x0000     ; MEM[0] = result
        HLT
```

Ten instructions, result 89.

---

## 10. Assembling

```
python3 parallax_asm.py program.asm --format bin -o build/
```

Produces `build/rom_high.txt` and `build/rom_low.txt`, to be pasted into the
matching ROM chips after selecting binary representation in the editor.

To check the encoding field by field:

```
python3 parallax_asm.py program.asm --listing
```
