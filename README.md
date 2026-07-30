# Parallax

A 16-bit CPU built from NAND gates up, in [Digital Logic Sim](https://sebastian.itch.io/digital-logic-sim), version 2.1.6, with [community mod](https://github.com/firecerne/Digital-Logic-Sim-Community-Edit/releases/tag/v1.2.1) version 1.2.1 

---

## What it is

Parallax is a Harvard, load-store, register-register machine with fixed-length
instructions — a RISC-like 16-bit CPU. Only `LOD` and `STR` touch memory; every
ALU operation works on registers, with three operands and a hardwired zero
register in the MIPS/RISC-V tradition. Instructions are 28 bits in three
formats, and I/O lives in a port space separate from memory, the way `IN`/`OUT`
work on x86.

Where it is unusual is the logic set. `IMPLY`, `NIMPLY`, `NAND`, `NOR` and
`XNOR` exist as separate instructions, which no commercial ISA bothers with:
they implement two or three and synthesise the rest. That is the signature of a
CPU built from NAND gates up, where those functions cost almost nothing and may
as well be exposed.

## Specifications

| | |
|---|---|
| Data width | 16-bit |
| Instruction word | 28-bit, fixed length |
| Instructions | 27 |
| Registers | 16 × 16-bit (`r0` hardwired to zero) |
| ALU | 15 functions, 7 flags |
| Instruction memory | 256 × 28-bit (two 256 × 16 ROM chips in parallel) |
| RAM | 256 × 16-bit words (512 bytes) |
| I/O | 32 ports — 16 in, 16 out, 16-bit |
| Architecture | Harvard, load-store, single-cycle, not pipelined |

## Instruction set

Full table in [`docs/isa.md`](docs/isa.md).

## Repository layout

```
docs/           specification, assembly guide, ISA reference
asm/            assembler (Python, no dependencies)
programs/       example and test programs
circuits/       Digital Logic Sim project folders (v1, v2)
spreadsheet/    ISA and control ROM working sheet
```

## Assembling a program

The assembler needs Python 3 and nothing else.

```
python3 asm/parallax_asm.py programs/[FILE NAME] --format bin -o build/
```

This produces `build/rom_high.txt` and `build/rom_low.txt` — one number per
line. Paste each into its ROM chip in Digital Logic Sim, after selecting the
matching representation in the ROM editor.

## Documentation

| Document | |
|---|---|
| [`docs/isa.md`](docs/isa.md) | instruction set reference |
| [`docs/assembly.md`](docs/assembly.md) | writing programs — syntax, idioms, gotchas |
| [`CHANGELOG.md`](CHANGELOG.md) | V1 → V2 |

## Versions

**V1** — 8-bit datapath, 20-bit instructions, 32 instructions of program memory.

**V2** — 16-bit datapath, 28-bit instructions, 256 instructions of program
memory, zero register, latched flag register, and an assembler. Full details in
the [changelog](CHANGELOG.md).

## Roadmap — V3

The two limits you feel first when writing real programs:

- **No indirect addressing.** Every memory address is a constant baked into the
  instruction, so there is no way to walk an array. `LDP` / `STP` fix this.
- **No subroutines.** A block needed in three places must be written three
  times, against a 256-instruction budget. `CAL` / `RET` with a hardware return
  stack fix this.

Also planned: a data stack with `PSH` / `POP`, indirect jumps (`JMR`) for jump
tables, `SUI`, sign and overflow flags for signed comparison, and a
carry-lookahead adder to replace the ripple-carry.

## License

_(see LICENSE)_
