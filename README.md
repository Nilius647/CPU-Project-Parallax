# Parallax

A 16-bit CPU built from NAND gates up, in [Digital Logic Sim](https://sebastian.itch.io/digital-logic-sim), with [community mod](https://github.com/firecerne/Digital-Logic-Sim-Community-Edit/releases/tag/v1.2.1) version 1.2.1. Now also rewritten in verilog. Project download is in releases.

---

## What it is

Parallax is a Harvard, load-store, register-register machine with fixed-length instructions — a RISC-like 16-bit CPU. Only loads and stores touch memory; every ALU operation works on registers, with three operands and a hardwired zero register. Instructions are 28 bits in three formats, and I/O lives in a port space separate from memory.

Where it is unusual is the logic set. `IMPLY`, `NIMPLY`, `NAND`, `NOR` and `XNOR` exist as separate instructions, which no commercial ISA bothers with: they implement two or three and synthesise the rest. That is the signature of a CPU built from NAND gates up, where those functions cost almost nothing and may as well be exposed.

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

Full table in [`toolchain/v3/isa.md`](toolchain/v3/isa.md).

## Repository layout

```
verilog/            the Verilog rewrite (Parallax Silicon)
  docs/               documentation for verilog
  src/                Datapath.v, and components/ with one file per module (mux/ and demux/ inside)
  tb/                 tb_Datapath.v, and components/ with one testbench per module
  sim/                synthesis script (synth.ys); build and waveform outputs are not tracked
toolchain/          everything that depends on the ISA, not on the wiring
  v2/, v3/            instruction set reference and programming guide for each ISA version
  asm/
    assemblers/       assemblers (Python, no dependencies) — one per ISA version
    examples/         clean, commented — for reading
    tests/            test suites with expected values (0xBEEF / 0xDEAD)
```

## Assembling a program

The assembler needs Python 3 and nothing else.

```
python3 toolchain/asm/assemblers/parallax_V3_asm.py toolchain/asm/examples/sum_array.asm --format bin -o build/
```

This produces `build/rom_high.txt` and `build/rom_low.txt` — one number per line. Paste each into its ROM chip in Digital Logic Sim, after selecting the matching representation in the ROM editor.

To inspect the encoding field by field:

```
python3 toolchain/asm/assemblers/parallax_V3_asm.py toolchain/asm/examples/sum_array.asm --listing
```

```
idx   --   opcode   n1     n2   n3   n4   n5     source
  0   0000 00010010 0001     0000 0001 0000 0000     LDI  r1, 0x0100
```

## Simulating the Verilog version

You need [Icarus Verilog](https://steveicarus.github.io/iverilog/) 13.0 or newer to compile and run the testbenches, and Python 3 for the assembler. [GTKWave](https://gtkwave.sourceforge.net/) is recommended for looking at waveforms, and [Yosys](https://yosyshq.net/yosys/) is only needed for the synthesis check.

Compile and run from the `verilog/` folder: the paths inside the testbenches are relative to it. The assembler is run from the repository root.

**1. Assemble** a program into its own folder under `verilog/sim/build/`. `--format bin` writes the numbers in the form `$readmemb` reads, and `--pad` fills the rest of the 256 instructions with `NOP`, so the instruction memory never holds undefined values. From the repository root:

```
python3 toolchain/asm/assemblers/parallax_V3_asm.py toolchain/asm/tests/test_all_v3.asm --format bin --pad -o verilog/sim/build/all
python3 toolchain/asm/assemblers/parallax_V3_asm.py toolchain/asm/tests/test_call.asm --format bin --pad -o verilog/sim/build/call
```

**2. Compile** the datapath testbench. Verilog doesn't look for modules by itself, so every file is listed:

```
cd verilog
iverilog -o sim/dp tb/tb_Datapath.v src/Datapath.v src/components/*.v src/components/mux/*.v src/components/demux/*.v
```

In PowerShell the `*` is not expanded: pass the file names, or use `Get-ChildItem`.

**3. Run**, telling the testbench where the program is:

```
vvp sim/dp +rom=sim/build/all +ports
vvp sim/dp +rom=sim/build/call
```

`+rom=<folder>` is required. `+ports` also checks the input registers and the output ports, and only makes sense for `test_all_v3.asm`, the one program that uses them.

The testbench runs until `HLT` and then reads `r15`:

| Output | Meaning |
|---|---|
| `Test succesful!` | `r15 = 0xBEEF`: every check in the program passed |
| `Error: test failed!` | `r15 = 0xDEAD`: a check failed; the source comments say which |
| `Error: test didn't finish!` | no `HLT` within 10000 cycles, or `r15` holds neither value |
| `Error: output failed!` / `Error: input failed!` | with `+ports`, the output ports or the input registers hold the wrong value |

**Testing a single module.** Each module has its own testbench in `tb/components/`. Compile it together with the module and run it; it prints `Error: ...` for every failed check and `Test finished` at the end:

```
iverilog -o sim/alu tb/components/tb_ALU.v src/components/ALU.v
vvp sim/alu
```

**Waveforms.** Every testbench writes `sim/dump.vcd`. Open it with GTKWave:

```
gtkwave sim/dump.vcd
```

**Synthesis check.** To see how Yosys reads the design (inferred latches, memories, cell count):

```
yosys -s sim/synth.ys
```

## Documentation

| Document | |
|---|---|
| [`toolchain/v3/isa.md`](toolchain/v3/isa.md) | instruction set reference — the full table |
| [`toolchain/v2/assembly_V2.md`](toolchain/v2/assembly_V2.md) | writing programs: syntax, registers, arithmetic, logic, memory, ports |
| [`toolchain/v3/assembly_V3.md`](toolchain/v3/assembly_V3.md) | what V3 adds: multiply, pointers, subroutines, computed jumps |
| [`verilog/docs/differences.md`](verilog/docs/differences.md) | differences between V3 and silicon V3 |
| [`CHANGELOG.md`](CHANGELOG.md) | V1 → V2 → V3 → silicon V3|

The V3 guide is a delta: it covers only the new instructions, so the V2 guide still applies word for word for everything else.

## Versions

**V1** — 8-bit datapath, 20-bit instructions, 32 instructions of program memory.

**V2** — 16-bit datapath, 28-bit instructions, 256 instructions of program memory, zero register, latched flag register, and an assembler.

**V3** — multiplication with overflow detection, pointers (`LDP` / `STP`), computed jumps (`JMR`), subroutines (`CAL` / `RET`) on a 16-level hardware return stack, and 16-bit memory addresses. Full details in the [changelog](CHANGELOG.md).

**silicon V3** — same as V3, rewritten in verilog.

## License

_(see LICENSE)_