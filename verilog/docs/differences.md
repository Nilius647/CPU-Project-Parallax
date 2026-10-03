# Parallax Silicon V3 - Differences from DLS

This file contains every difference between Parallax V3 (in DLS) and Parallax Silicon V3 (in verilog).

The ISA is the same (`toolchain/v3/isa.md`) and so is the contract: `test_all_v3.asm` and `test_call.asm` both end with `r15 = 0xBEEF`. What differs is how each piece is built.

| Component | In DLS | In verilog | Why |
|---|---|---|---|
| Program Counter | The clock stops with an AND gate between the clock and a signal toggled by a flip-flop | The clock doesn't stop, but the PC doesn't change the address stored in the register | Cutting the clock with a gate can produce glitches and skew on real hardware. A synchronous enable avoids both and needs no extra flip-flop |
| Flags and Flag Verifier | Flags are stored in the ALU | Flags are stored in the Flag Verifier | The ALU is more efficient by being only combinational |
| `BRH` selection | The flag checker drives one bit of the `PAM` selector directly; three independent CU outputs build the 3 selector bits | The CU always outputs `010` for `BRH`; the Datapath replaces it with `000` when the condition is false | The CU only sees the opcode, so it can't know the condition. The decision belongs where the flag checker's output is available |
| Reset | Everything starts at zero on power-up | Every register has an explicit `rst`: PC, return stack, register file, flag verifier and output ports | Verilog registers start as `x`, not zero |
| Instruction ROM | Two 16-bit ROM chips (high and low) | One 256 x 28-bit array | The split in DLS comes from the available chips. The testbench joins the two assembler files into the single word |
| Ports | 16 different 16 bit registers for input and 16 more for output | `in` and `out` are 256-bit buses, 16 ports of 16 bits. `out` is a register, written only when the CU raises `ports`; `in` is read combinationally | In verilog a port is a 16-bit slice of a bus, picked with an index, instead of a separate register. Only `out` needs memory: `in` comes from outside the CPU, so it is read when needed and only kept by the destination of `PLR` / `PLM` |
| Mux unused inputs | Some inputs are left empty (the fourth `RWM` input, `PAM` selectors `101` to `111`) | Every mux has a `default` and unused inputs are tied to a constant (`4'h0` on the fourth `RWM` input) | An undriven input is `x`, not zero, and propagates |

## Why, in more detail

### Stopping the clock

`HLT` raises `stop_clock` in the CU. In DLS that signal closed the clock's and gate. In verilog it goes straight to a `halt` input on the PC. The clock keeps running everywhere, but while `halt` is high the PC keeps its address.

No extra flip-flop is needed: the PC stays on the `HLT` instruction, the instruction memory keeps returning the same opcode, and the CU keeps `stop_clock` high on its own. Every other instruction-driven signal stays at zero for `HLT`, so the register file, RAM and stack never write. `rst` has priority over `halt`, so a reset always gets the CPU out of a `HLT`.

### Where the flags live

The ALU only computes: it has no memory. When `enable_flags` is off it outputs all-zero flags. The Flag Verifier holds the register and updates it only when the incoming flags are non-zero. That works because, when the flags are enabled, one of every pair (carry / not carry, zero / not zero) is always lit, so "non-zero" means "an ALU operation just ran".

`BRH` is a non-ALU instruction: the ALU outputs zero flags, the register keeps the previous values, and the branch reads those.

### The `BRH` selector

DLS drove one selector bit from the condition. Here the CU is combinational on the opcode alone, so it sends the fixed selector. The Datapath takes that selector and the verifier's `condition_true`: if the CU asked for the `BRH` source and the condition is false, the selector becomes `000`, so the PC advances normally. Any other selector goes through unchanged.
