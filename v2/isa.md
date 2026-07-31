# Parallax V2 — Instruction set

27 instructions, 28-bit fixed-length word, sequential opcodes `0x00`–`0x1A`.

## Instruction formats

```
Format R (ALU)          [ opcode 8 ][ rA 4 ][ rB 4 ][ rC 4 ][ ---- 8 ]
Format I (immediate)    [ opcode 8 ][ rA 4 ][      imm16       ]
Format J (branch)       [ opcode 8 ][ cond 4 ][ addr 8 ][ ---- 8 ]
```

Addresses occupy bits 15-8; immediates occupy all sixteen.

| Instructions | Field | Bits | Nibbles |
|---|---|---|---|
| `LDI`, `ADI` | 16-bit immediate | 15-0 | 2, 3, 4, 5 |
| `JMP`, `BRH` | 8-bit program address | 15-8 | 2, 3 |
| `STR`, `LOD`, `PSM`, `PLM` | 8-bit memory address | 15-8 | 2, 3 |

Both the PC and RAM have 256 locations, so eight bits are enough: nibbles 4 and
5 stay empty in address-carrying instructions.

| Field | Bits |
|---|---|
| opcode | 27–20 |
| nibble 1 | 19–16 |
| nibble 2 | 15–12 |
| nibble 3 | 11–8 |
| nibble 4 | 7–4 |
| nibble 5 | 3–0 |

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
| `0x0F` | NOP | — | — | no operation |
| `0x10` | HLT | — | — | stop the clock |
| `0x11` | LDI | I | rA, imm16 | rA = imm16 |
| `0x12` | ADI | I | rA, imm16 | rA = rA + imm16 |
| `0x13` | JMP | J | addr | PC = addr |
| `0x14` | BRH | J | cond, addr | PC = addr if cond holds |
| `0x15` | STR | I | rA, addr | MEM[addr] = rA |
| `0x16` | LOD | I | rA, addr | rA = MEM[addr] |
| `0x17` | PSM | I | port, addr | OUT[port] = MEM[addr] |
| `0x18` | PLM | I | port, addr | MEM[addr] = IN[port] |
| `0x19` | PSR | R | rA, port | OUT[port] = rA |
| `0x1A` | PLR | R | rA, port | rA = IN[port] |

The low nibble of the opcode is the ALU function select: the 15 ALU functions
occupy `0x00`–`0x0E` in the same order the ALU selects them, so `opcode[3:0]`
drives the function input directly with no decoding.

`PSM` / `PLM` place a 4-bit port field in nibble 1, followed by the 16-bit
address. `PSR` / `PLR` use two 4-bit fields: register in nibble 1, port in
nibble 2.

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

The `cond` field is 4 bits wide, leaving room for sign and overflow flags in V3
without changing the instruction format.

Only the 15 ALU operations and `ADI` update the flags. Everything else leaves
them untouched.

## Pseudo-instructions

Assembler-level only — no hardware exists for these. They work because `r0` is
hardwired to zero.

| Written | Expands to | Effect |
|---|---|---|
| `MOV rS, rD` | `ADD r0, rS, rD` | rD = rS |
| `CLR rD` | `ADD r0, r0, rD` | rD = 0 |
| `NEG rS, rD` | `SUB r0, rS, rD` | rD = −rS |
| `CMP rA, rB` | `SUB rA, rB, r0` | flags only, no write |

## Registers

16 addressable registers, `r0`–`r15`, 16 bits each. `r0` reads as zero and
discards writes; it has no physical storage cell, so the register file contains
15 registers.
