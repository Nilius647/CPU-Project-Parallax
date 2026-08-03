# Parallax

A 16-bit CPU built from NAND gates up, in [Digital Logic Sim](https://sebastian.itch.io/digital-logic-sim), with [community mod](https://github.com/firecerne/Digital-Logic-Sim-Community-Edit/releases/tag/v1.2.1) version 1.2.1. Project download is in releases.

---

## What it is

Parallax is a Harvard, load-store, register-register machine with fixed-length
instructions — a RISC-like 16-bit CPU. Only loads and stores touch memory; every
ALU operation works on registers, with three operands and a hardwired zero
register in the MIPS/RISC-V tradition. Instructions are 28 bits in three
formats, and I/O lives in a port space separate from memory, the way `IN`/`OUT`
work on x86.

Where it is unusual is the logic set. `IMPLY`, `NIMPLY`, `NAND`, `NOR` and
`XNOR` exist as separate instructions, which no commercial ISA bothers with:
they implement two or three and synthesise the rest.

## Specifications

| | |
|---|---|
| Data width | 16-bit |
| Instruction word | 28-bit, fixed length |
| Instructions | 33 |
| Registers | 16 × 16-bit (`r0` hardwired to zero) |
| ALU | 16 functions incl. multiply, 8 flags |
| Instruction memory | 256 × 28-bit (two 256 × 16 ROM chips in parallel) |
| RAM | 1024 × 16-bit words (2 KB), 16-bit address space |
| Return stack | 16 levels, dedicated hardware |
| I/O | 32 ports — 16 in, 16 out, 16-bit |
| Architecture | Harvard, load-store, single-cycle, not pipelined |

## Instruction set

Full table in [`v3/isa.md`](v3/isa.md).

## Repository layout

```
docs/           specification, assembly guide, ISA reference
asm/            assemblers (Python, no dependencies) — one per ISA version
```

## Assembling a program

The assembler needs Python 3 and nothing else.

```
python3 asm/parallax_asm_v3.py (FILE NAME) --format bin -o build/
```

This produces `build/rom_high.txt` and `build/rom_low.txt` — one number per
line. Paste each into its ROM chip in Digital Logic Sim, after selecting the
matching representation in the ROM editor.

To inspect the encoding field by field:

```
python3 asm/parallax_asm_v3.py (FILE NAME) --listing
```

## Documentation

| Document | |
|---|---|
| [`v3/isa.md`](v3/isa.md) | instruction set reference — the full table |
| [`v2/assembly-v2.md`](v2/assembly-v2.md) | writing programs: syntax, registers, arithmetic, logic, memory, ports |
| [`v3/assembly-v3.md`](v3/assembly-v3.md) | what V3 adds: multiply, pointers, subroutines, computed jumps |
| [`CHANGELOG.md`](CHANGELOG.md) | V1 → V2 → V3 |

The V3 guide is a delta: it covers only the new instructions, so the V2 guide
still applies word for word for everything else.

## Versions

**V1** — 8-bit datapath, 20-bit instructions, 32 instructions of program memory.

**V2** — 16-bit datapath, 28-bit instructions, 256 instructions of program
memory, zero register, latched flag register, and an assembler.

**V3** — multiplication with overflow detection, pointers (`LDP` / `STP`),
computed jumps (`JMR`), subroutines (`CAL` / `RET`) on a 16-level hardware
return stack, and 16-bit memory addresses. Full details in the
[changelog](CHANGELOG.md).

## Roadmap — V4

- **Data stack** with `PSH` / `POP`, so registers can be saved across calls and
  recursion can have local variables
- **Pointer offsets** — `LDP rA, rB, imm8`, for struct fields without computing
  the address first
- **Signed arithmetic** — sign and overflow flags, added together, for signed
  comparison (`N XOR V`)
- **Larger instruction memory** with 16-bit program addresses; the encoding is
  already in place
- `SUI`, and `MULH` for the high half of a product
- Carry-lookahead adder to replace the ripple-carry, and eventually pipelining

## License

_(see LICENSE)_
