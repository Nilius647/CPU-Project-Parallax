# Parallax — Changelog

---

## V3 — complete

Three additions on top of the V2 datapath: multiplication, pointers and
subroutines. Datapath width, register file, instruction word and instruction
memory are unchanged. Opcodes are renumbered, so V2 machine code does not run on
V3 — the source does.

Instruction count goes from 27 to **33**.

### Added

**Multiplication**

- **`MUL rA, rB, rC`** — fills the sixteenth ALU function slot, the last one
  free. The product of two 16-bit values takes 32 bits, so `MUL` returns the low
  half only.
- **`ov` flag, condition code `111`** — raised when the high half of the product
  is non-zero. The last free code in the 4-bit `cond` field, so overflow is
  testable with `BRH ov, label` and the carry keeps its single meaning.

**Pointers**

- **`LDP rA, rB`** and **`STP rA, rB`** — load and store where the address comes
  from a register instead of from the instruction. This is what makes arrays,
  strings and any data-driven code possible: the pointer is an ordinary register,
  so `INC`, `ADD` and `CMP` all work on it.
- **`JMR rA`** — computed jump, for jump tables. The register is 16-bit and the
  PC is 8-bit, so the low 8 bits are used.

**Subroutines**

- **`CAL addr`** and **`RET`** — call and return, backed by a dedicated hardware
  return stack: 16 levels, separate from main RAM, with a 4-bit up/down counter
  as stack pointer. Neither instruction touches any register.

### Changed

| | V2 | V3 |
|---|---|---|
| Instructions | 27 | **33** |
| ALU functions | 15 | **16** |
| Flags | 7 | **8** |
| Memory address field | 8-bit, nibbles 2-3 | **16-bit, nibbles 2-5** |
| Address space | 256 words | **65536 words** |
| RAM installed | 256 words (512 B) | **1024 words (2 KB)** |
| `PCaddress mux` | 3 sources, 2 select bits | **5 sources, 3 select bits** |
| RAM address source | instruction field only | **instruction field or register** |
| Opcodes | `0x00`–`0x1A` | **`0x00`–`0x20`, renumbered** |

**Opcodes renumbered.** Still sequential with no gaps. The ALU block keeps the
first sixteen slots, so `opcode[3:0]` remains the ALU function select — and with
`MUL` filling slot 15 and `NOP` moved to `0x10`, `opcode[7:4] == 0` now means
"ALU operation" with no exception at all.

**Memory addresses widened.** `STR`, `LOD`, `PSM` and `PLM` now carry a full
16-bit address across nibbles 2-5, sharing the extraction path with the
`LDI` / `ADI` immediate. Program addresses (`JMP`, `BRH`, `CAL`) stay 8-bit in
nibbles 2-3.

**Address space and installed memory are now distinct.** The ISA addresses 65536
words; the machine installs 1024 (2 KB), valid range `0x0000`–`0x03FF`. Access
beyond that wraps to the start of memory rather than raising anything. More banks
can be attached later without touching the ISA or the assembler.

### New control signals

- **RAM address mux** — one bit, set only for `LDP` and `STP`
- **Stack push / pop** — set for `CAL` and `RET` respectively

`CAL` does not add a `PCaddress mux` source: it uses the same one as `JMP`, and
additionally writes to the stack. Only `RET` reads from the stack, so only `RET`
needs a source of its own.

### Unchanged

- 16-bit datapath, 16 registers, `r0` hardwired to zero
- 28-bit instruction word, three formats
- 256 instructions of program memory, 8-bit PC
- 32 ports: 16 in, 16 out
- Harvard architecture, single-cycle, not pipelined
- Comparisons remain unsigned; no sign flag

### Tooling

- **`parallax_asm_v3.py`** — separate from the V2 assembler, since the opcodes
  are incompatible. Adds the six new mnemonics, the `ov` condition, 16-bit memory
  addresses, and labels usable as immediates (`LDI r1, routine` then `JMR r1`,
  which is what makes jump tables buildable).

### Deferred to V4

- Larger instruction memory, 16-bit program addresses
- Pointer offsets — `LDP rA, rB, imm8`
- Data stack with `PSH` / `POP`, and local variables for recursion
- `SUI`
- Sign flag and arithmetic overflow flag, to be added together
- Stack full / empty flags
- Carry-lookahead adder in place of the ripple-carry
- Pipelining

### Known limits

- The return stack wraps silently on the seventeenth nested `CAL`, and a `RET`
  without a matching `CAL` returns to an arbitrary address.
- With no data stack, there is no mechanism to save registers across a call: the
  caller must know what each subroutine clobbers.
- The zero flag after a `MUL` refers to the low 16 bits only, so it can be raised
  on a non-zero product.

---

## V2 — complete

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

### Deferred

Predictions made at the time of V2. What actually happened:

| | Outcome |
|---|---|
| Return stack + `CAL` / `RET` | done in V3 |
| Indirect addressing `LDP` / `STP` | done in V3 |
| Indirect jump `JMR` | done in V3 |
| Data stack + `PSH` / `POP` | deferred to V4 |
| `SUI` | deferred to V4 |
| Sign flag and arithmetic overflow | deferred to V4 |
| Carry-lookahead adder | deferred to V4 |
| Reserved gaps between opcode blocks | **dropped** — the ISA stays sequential |

Not predicted, and added in V3 anyway: multiplication, with its product-overflow
flag.

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
