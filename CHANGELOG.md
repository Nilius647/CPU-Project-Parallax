# Parallax — Changelog

---

## V2 — in development

Datapath widened to 16 bits and instruction word to 28 bits. The ISA stays
functionally identical to V1 — same 27 instructions, same mnemonics, same
semantics — but the opcodes of the ALU block, `NOP` and `HLT` are renumbered.
Binary compatibility with V1 is not maintained.

### Fixed

- **`NOT` / `AND` opcode collision** — in the V1 table both were listed as
  `0b00100`, making one of them undecodable. With the fix, the actual
  instruction count is **27**, not 26.
- **PC / instruction memory mismatch** — the PC had 6 address bits (64
  locations) against a 32-instruction ROM, so half the address space did not
  exist. PC width and ROM depth now match.

### Changed

All of these are breaking changes.

| | V1 | V2 |
|---|---|---|
| Datapath width | 8-bit | **16-bit** |
| ALU (Hypo ALU 2) | 8-bit | **16-bit** |
| Register file | 16 × 8-bit | **16 × 16-bit** (15 physical + constant `r0`) |
| RAM | 256 × 8-bit (256 B) | **256 × 16-bit (512 B)** |
| Ports | 32 × 8-bit | **32 × 16-bit** |
| Instruction word | 20-bit | **28-bit** |
| Instruction memory | 32 instructions | **256 instructions** |
| PC | 6-bit | **8-bit** |
| Immediates (`LDI`, `ADI`) | 8-bit | **16-bit** |
| Memory address field | 8-bit | **16-bit** (8 in use) |
| Branch address field | 6-bit | **16-bit** (8 in use) |
| `BRH` `cond` field | 3-bit | **4-bit** |
| Register `r0` | general purpose | **zero register** |

Register `0000` is no longer usable storage: reads always return 0, and the
write enable is suppressed.

**Opcodes renumbered.** The numbering stays sequential with no gaps
(`0x00`–`0x1A`), but the ALU block moves to the front:

| | V1 | V2 |
|---|---|---|
| `ADD` … `DEC` (15 ALU functions) | `0x02`–`0x10` | **`0x00`–`0x0E`** |
| `NOP` | `0x00` | **`0x0F`** |
| `HLT` | `0x01` | **`0x10`** |
| `LDI` … `PLR` | `0x11`–`0x1A` | `0x11`–`0x1A` *(unchanged)* |

Rationale: with the ALU block aligned to the start of the nibble,
`opcode[3:0]` *is* the Hypo ALU function select. In V1 the ALU functions
straddled the nibble boundary, so the CU would have had to subtract 2 from the
opcode or go through a lookup.

Two consequences worth keeping in mind:

- `NOP` lands at `0x0F`, inside the ALU nibble, and presents function code 15,
  which does not exist. No exclusion logic is needed: it is enough for row
  `0x0F` of the control ROM to hold write enable and flag enable low.
- The all-zero instruction word is no longer `NOP` but `ADD r0, r0, r0`. No
  register is written (zero register), but the flags are. An uninitialised ROM
  is all zeros, so programs must be terminated with `HLT`.

### Added

- **Flag register with enable and an explicit update policy**: only the 15 ALU
  operations and `ADI` update the flags. `LDI`, `LOD`, `STR`, the port
  instructions and the branches leave them intact, so a comparison survives the
  intervening instructions all the way to the `BRH`.
- **Three formalised instruction formats**: R (three registers), I (register +
  16-bit immediate), J (condition + address).
- **Pseudo-instructions** derived from the zero register: `MOV`, `CLR`, `NEG`
  and above all `CMP` (`SUB rA, rB, r0`), which compares two registers without
  wasting one on a result nobody wants.
- **Assembler** — external Python tool: parsing, label resolution, output in
  the format accepted by the DLS ROM editor (one number per line, pasted via the
  editor's copy/paste buttons).

### Dropped

- **`LUI` (Load Upper Immediate)** — planned while the format was still 20-bit,
  to load the high byte of a register. With the 16-bit immediate of format I,
  `LDI` fills a register in a single instruction, so the instruction is
  unnecessary and will never be implemented.
- **Immediate extension** (zero-extend on `LDI`, sign-extend on `ADI`) — only
  needed while the immediate was narrower than the register. At 16 bits against
  16 bits there is nothing to extend, and `ADI` handles two's-complement
  negatives natively.

### Unchanged

- 27 instructions, mnemonics and semantics identical to V1
- 15 ALU functions
- 16 addressable registers (in V2 `r0` has no physical cell)
- 256 RAM words (the width changes, the depth does not)
- 32 ports: 16 IN, 16 OUT
- Harvard architecture, separate instruction and data memory
- The 7 flags and their codes (no flag added: see *Deferred to V3*)

### Deferred to V3

- Hardware return stack + `CAL` / `RET`
- Data stack + `PSH` / `POP`
- Indirect addressing `LDP` / `STP`
- Indirect jump `JMR` for jump tables
- `SUI`
- Sign flag (N) **and overflow flag (V), to be added together** — the 4-bit
  `cond` field already has room. V on its own would be dead hardware: its point
  is signed comparison, which is expressed as `N XOR V`
- Reserved gaps between opcode blocks (the ALU block is already aligned in V2;
  what is missing is free space between immediates, branches, memory and ports)
- Carry-lookahead adder in place of the ripple-carry

---

## V1 — complete

8-bit CPU, Harvard architecture, 27 instructions on a 20-bit word
(8 opcode bits + 3 operand nibbles).

- **ALU** — Hypo ALU 2, 15 functions, 7 flags
- **Registers** — 16 × 1 byte, DRSW (Dual Read Single Write)
- **Instruction memory** — 32 instructions of 20 bits
- **RAM** — 256 bytes, built as a 4 B → 16 B → 64 B → 256 B hierarchy
- **PC** — 6 address bits
- **Ports** — 32 total (16 IN, 16 OUT) for communication with external chips

Instructions: `NOP`, `HLT`, `ADD`, `SUB`, `NOT`, `AND`, `OR`, `XOR`, `NAND`,
`NOR`, `XNOR`, `IMPLY`, `NIMPLY`, `SHL`, `SHR`, `INC`, `DEC`, `LDI`, `ADI`,
`JMP`, `BRH`, `STR`, `LOD`, `PSM`, `PLM`, `PSR`, `PLR`.
