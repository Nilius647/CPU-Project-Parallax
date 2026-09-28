# Parallax V3 — Instruction set

33 instructions, 28-bit fixed-length word, sequential opcodes `0x00`–`0x20`.

## Instruction formats

```
Format R (ALU)          [ opcode 8 ][ rA 4 ][ rB 4 ][ rC 4 ][ ---- 8 ]
Format I (immediate)    [ opcode 8 ][ rA 4 ][      imm16       ]
Format J (branch)       [ opcode 8 ][ cond 4 ][ addr 8 ][ ---- 8 ]
```

| Field | Bits |
|---|---|
| opcode | 27–20 |
| nibble 1 | 19–16 |
| nibble 2 | 15–12 |
| nibble 3 | 11–8 |
| nibble 4 | 7–4 |
| nibble 5 | 3–0 |

Immediates and memory addresses span bits 15–0 (nibbles 2–5). Program addresses
are 8-bit and sit in nibbles 2–3.

## Instructions

| Opcode | Mnem. | Fmt | Operands | Semantics |
|---|---|---|---|---|
| `0x00` | ADD | R | rA, rB, rC | rC = rA + rB |
| `0x01` | SUB | R | rA, rB, rC | rC = rA − rB |
| `0x02` | NOT | R | rA, —, rC | rC = ¬rA |
| `0x03` | AND | R | rA, rB, rC | rC = rA ∧ rB |
| `0x04` | OR | R | rA, rB, rC | rC = rA ∨ rB |
| `0x05` | XOR | R | rA, rB, rC | rC = rA ⊕ rB |
| `0x06` | NAND | R | rA, rB, rC | rC = ¬(rA ∧ rB) |
| `0x07` | NOR | R | rA, rB, rC | rC = ¬(rA ∨ rB) |
| `0x08` | XNOR | R | rA, rB, rC | rC = ¬(rA ⊕ rB) |
| `0x09` | IMPLY | R | rA, rB, rC | rC = ¬rA ∨ rB |
| `0x0A` | NIMPLY | R | rA, rB, rC | rC = rA ∧ ¬rB |
| `0x0B` | SHL | R | rA, —, rC | rC = rA × 2 |
| `0x0C` | SHR | R | rA, —, rC | rC = rA ÷ 2 |
| `0x0D` | INC | R | rA, —, rC | rC = rA + 1 |
| `0x0E` | DEC | R | rA, —, rC | rC = rA − 1 |
| `0x0F` | MUL | R | rA, rB, rC | rC = (rA × rB) truncated to 16 bits |
| `0x10` | NOP | — | — | no operation |
| `0x11` | HLT | — | — | stop the clock |
| `0x12` | LDI | I | rA, imm16 | rA = imm16 |
| `0x13` | ADI | I | rA, imm16 | rA = rA + imm16 |
| `0x14` | JMP | J | addr | PC = addr |
| `0x15` | BRH | J | cond, addr | PC = addr if cond holds |
| `0x16` | JMR | R | rA | PC = rA, low 8 bits |
| `0x17` | STR | I | rA, addr | MEM[addr] = rA |
| `0x18` | LOD | I | rA, addr | rA = MEM[addr] |
| `0x19` | STP | R | rA, rB | MEM[rB] = rA |
| `0x1A` | LDP | R | rA, rB | rA = MEM[rB] |
| `0x1B` | PSM | I | port, addr | OUT[port] = MEM[addr] |
| `0x1C` | PLM | I | port, addr | MEM[addr] = IN[port] |
| `0x1D` | PSR | R | rA, port | OUT[port] = rA |
| `0x1E` | PLR | R | rA, port | rA = IN[port] |
| `0x1F` | CAL | J | addr | push PC+1, PC = addr |
| `0x20` | RET | — | — | PC = pop |

The low nibble of the opcode is the ALU function select: the 16 ALU functions
occupy `0x00`–`0x0F` in the same order the ALU selects them, so `opcode[3:0]`
drives the function input directly and `opcode[7:4] == 0` identifies an ALU
operation with no exception.

`STP` and `LDP` place `rA` in nibble 1 and the pointer `rB` in nibble 2. `JMR`
places the pointer in nibble 1, so it comes out of read port A. `PSM` / `PLM`
place a 4-bit port field in nibble 1 followed by the address. `PSR` / `PLR`
leave nibble 1 empty and use register in nibble 2, port in nibble 3.

Input and output ports are separate spaces — `IN[3]` and `OUT[3]` are different
physical ports.

## Condition codes

| Code | Flag |
|---|---|
| `000` | Carry out |
| `001` | A > B (unsigned) |
| `010` | A = B |
| `011` | A < B (unsigned) |
| `100` | Zero |
| `101` | not Carry |
| `110` | not Zero |
| `111` | Overflow — high half of a product is non-zero |

The `cond` field is 4 bits wide, leaving eight combinations free for the sign
and arithmetic-overflow flags in V4.

Only the 16 ALU operations and `ADI` update the flags — 17 rows of the control
ROM. Everything else leaves them untouched.

**After a `MUL`, the zero flag refers to the low 16 bits only.** `0x0100 ×
0x0100` gives `0x00010000`: the low half is empty, so `z` is raised although the
product is 65536. Testing both `ov` and `z` tells whether a product is really
zero.

## Pseudo-instructions

Assembler-level only — no hardware exists for these. They work because `r0` is
hardwired to zero.

| Written | Expands to | Effect |
|---|---|---|
| `MOV rS, rD` | `ADD rS, r0, rD` | rD = rS |
| `CLR rD` | `ADD r0, r0, rD` | rD = 0 |
| `NEG rS, rD` | `SUB r0, rS, rD` | rD = −rS |
| `CMP rA, rB` | `SUB rA, rB, r0` | flags only, no write |

## Registers

16 addressable registers, `r0`–`r15`, 16 bits each. `r0` reads as zero and
discards writes; it has no physical storage cell, so the register file contains
15 registers.

## Memory

Address space is 65536 words; the machine installs **1024 words (2 KB)**, valid
range `0x0000`–`0x03FF`. Access beyond that wraps to the start of memory.

Program memory is separate (Harvard): 256 instructions of 28 bits, 8-bit PC.

## Return stack

Dedicated hardware, 16 levels deep, separate from main RAM. `CAL` pushes `PC+1`,
`RET` pops. Neither touches any register. The stack wraps silently on the
seventeenth nested call.
