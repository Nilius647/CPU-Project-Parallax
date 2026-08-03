#!/usr/bin/env python3
"""
Assembler for the Parallax V3 CPU.

Usage:
    python3 parallax_asm.py program.asm
    python3 parallax_asm.py program.asm --format bin
    python3 parallax_asm.py program.asm -o build/

Produces two text files, one per ROM chip, with one number per line:

    rom_high.txt   ->  high ROM chip   (opcode + nibble 1)
    rom_low.txt    ->  low ROM chip    (nibbles 2-5)

Paste each into its ROM chip in Digital Logic Sim using the paste button, after
selecting the same representation used here (default: hexadecimal).

Instruction format (28 bits):
    bits 27-20  opcode
    bits 19-16  nibble 1   rA / cond / port
    bits 15-12  nibble 2
    bits 11-8   nibble 3
    bits 7-4    nibble 4
    bits 3-0    nibble 5

ROM words (bottom-aligned, see HIGH_ALIGN below):
    high = (opcode << 4) | nibble1              top 4 bits stay zero
    low  = bits 15-0 of the instruction

To inspect the encoding field by field:
    python3 parallax_asm.py program.asm --listing
"""

import argparse
import os
import re
import sys

# --------------------------------------------------------------------------
# CONFIGURATION — the only block to touch if the wiring differs
# --------------------------------------------------------------------------

# Alignment of the 12 useful bits (opcode + nibble 1) within the 16-bit word
# of the high ROM.
#
#   "left"   opcode in bits 15-8, nibble 1 in bits 7-4, bits 3-0 unused
#            LDI r1  ->  1110
#
#   "right"  bits 15-12 unused, opcode in bits 11-4, nibble 1 in bits 3-0
#            LDI r1  ->  0111
#
# If every instruction writes to r0, this is probably the wrong value: nibble 1
# is being read from a different position than the one the assembler writes to.
HIGH_ALIGN = "right"

# Position of the address field within the low word.
#
# Position of the address field within the low word.
#
# Program addresses are 8-bit and sit in nibbles 2-3 (bits 15-8), so the PC
# takes them from the top of the field. Memory addresses are a full 16 bits
# and span the whole field (bits 15-0), sharing the extraction path with the
# LDI / ADI immediate.
BRANCH_ADDR_SHIFT = 8      # JMP / BRH / CAL
MEM_ADDR_SHIFT = 0         # STR / LOD / PSM / PLM

# Position of the register and port fields in PSR / PLR.
# The spreadsheet places the register in nibble 2 and the port in nibble 3,
# leaving nibble 1 empty.
PSR_REG_SHIFT = 12
PORT_SHIFT = 8

MAX_INSTRUCTIONS = 256

# --------------------------------------------------------------------------
# Instruction set
# --------------------------------------------------------------------------

# name: (opcode, form)
#   rrr   rA, rB, rC      n1=rA   low = rB<<12 | rC<<8
#   rr    rA, rC          n1=rA   low = rC<<8            (rB unused)
#   none  no operands
#   ri    rA, imm16       n1=rA   low = imm16            (no shift)
#   ra    rA, addr        n1=rA   low = addr << MEM_ADDR_SHIFT
#   j     addr            n1=0    low = addr << BRANCH_ADDR_SHIFT
#   cj    cond, addr      n1=cond low = addr << BRANCH_ADDR_SHIFT
#   pa    port, addr      n1=port low = addr << MEM_ADDR_SHIFT
#   rp    rA, port        n1=0    low = rA<<PSR_REG_SHIFT | port<<PORT_SHIFT
#   rr2   rA, rB          n1=rA   low = rB<<12           (LDP / STP)
#   r     rA              n1=rA   low = 0                (JMR: pointer in
#                                                          nibble 1, so it comes
#                                                          out of read port A)
ISA = {
    # 0x00-0x0F  ALU — opcode[3:0] is the ALU function select
    "ADD":    (0x00, "rrr"),
    "SUB":    (0x01, "rrr"),
    "NOT":    (0x02, "rr"),
    "AND":    (0x03, "rrr"),
    "OR":     (0x04, "rrr"),
    "XOR":    (0x05, "rrr"),
    "NAND":   (0x06, "rrr"),
    "NOR":    (0x07, "rrr"),
    "XNOR":   (0x08, "rrr"),
    "IMPLY":  (0x09, "rrr"),
    "NIMPLY": (0x0A, "rrr"),
    "SHL":    (0x0B, "rr"),
    "SHR":    (0x0C, "rr"),
    "INC":    (0x0D, "rr"),
    "DEC":    (0x0E, "rr"),
    "MUL":    (0x0F, "rrr"),
    # 0x10 onwards — sequential, no gaps
    "NOP":    (0x10, "none"),
    "HLT":    (0x11, "none"),
    "LDI":    (0x12, "ri"),
    "ADI":    (0x13, "ri"),
    "JMP":    (0x14, "j"),
    "BRH":    (0x15, "cj"),
    "JMR":    (0x16, "r"),
    "STR":    (0x17, "ra"),
    "LOD":    (0x18, "ra"),
    "STP":    (0x19, "rr2"),
    "LDP":    (0x1A, "rr2"),
    "PSM":    (0x1B, "pa"),
    "PLM":    (0x1C, "pa"),
    "PSR":    (0x1D, "rp"),
    "PLR":    (0x1E, "rp"),
    "CAL":    (0x1F, "j"),
    "RET":    (0x20, "none"),
}

# Pseudo-instructions, made possible by the zero register.
# name: (real instruction, operand template where $0, $1 are the arguments)
PSEUDO = {
    "MOV": ("ADD", ["$0", "r0", "$1"]),   # MOV rS, rD   ->  rD = rS
    "CLR": ("ADD", ["r0", "r0", "$0"]),   # CLR rD       ->  rD = 0
    "NEG": ("SUB", ["r0", "$0", "$1"]),   # NEG rS, rD   ->  rD = -rS
    "CMP": ("SUB", ["$0", "$1", "r0"]),   # CMP rA, rB   ->  flags only
}

CONDITIONS = {
    "C": 0b000, "CARRY": 0b000,
    "GT": 0b001,
    "EQ": 0b010,
    "LT": 0b011,
    "Z": 0b100, "ZERO": 0b100,
    "NC": 0b101,
    "NZ": 0b110,
    "OV": 0b111, "OVERFLOW": 0b111,
}

ARITY = {"rrr": 3, "rr": 2, "none": 0, "ri": 2, "ra": 2,
         "j": 1, "cj": 2, "pa": 2, "rp": 2, "rr2": 2, "r": 1}
PSEUDO_ARITY = {"MOV": 2, "CLR": 1, "NEG": 2, "CMP": 2}


class AsmError(Exception):
    pass


# --------------------------------------------------------------------------
# Operand parsing
# --------------------------------------------------------------------------

def parse_register(tok):
    m = re.fullmatch(r"[rR](\d{1,2})", tok)
    if not m:
        raise AsmError(f"invalid register: '{tok}' (expected r0-r15)")
    n = int(m.group(1))
    if n > 15:
        raise AsmError(f"register out of range: '{tok}' (maximum r15)")
    return n


def parse_number(tok):
    t = tok.lower()
    neg = t.startswith("-")
    if neg:
        t = t[1:]
    try:
        if t.startswith("0x"):
            v = int(t[2:], 16)
        elif t.startswith("0b"):
            v = int(t[2:], 2)
        else:
            v = int(t, 10)
    except ValueError:
        raise AsmError(f"invalid number: '{tok}'")
    return -v if neg else v


def to_u16(v, tok):
    if -32768 <= v < 0:
        return v + 0x10000
    if 0 <= v <= 0xFFFF:
        return v
    raise AsmError(f"value does not fit in 16 bits: '{tok}'")


def parse_nibble(tok, what):
    v = parse_number(tok)
    if not 0 <= v <= 15:
        raise AsmError(f"{what} out of range: '{tok}' (expected 0-15)")
    return v


def parse_condition(tok):
    key = tok.upper()
    if key in CONDITIONS:
        return CONDITIONS[key]
    v = parse_number(tok) if re.fullmatch(r"-?\w+", tok) else None
    if v is not None and 0 <= v <= 15:
        return v
    valid = ", ".join(sorted(set(CONDITIONS)))
    raise AsmError(f"invalid condition: '{tok}' (valid: {valid})")


def parse_imm(tok, labels):
    """An immediate may also be a label, which resolves to its address.

    Useful with JMR and pointers: `LDI r1, routine` then `JMR r1`.
    """
    if tok in labels:
        return labels[tok]
    if re.fullmatch(r"[A-Za-z_]\w*", tok):
        raise AsmError(f"undefined label: '{tok}'")
    return parse_number(tok)


def pack_addr(value, shift, tok):
    """Place an address in the low word according to the configured shift."""
    limit = 0xFFFF >> shift
    if not 0 <= value <= limit:
        raise AsmError(f"address out of range: '{tok}' (0-{limit})")
    return value << shift


def parse_address(tok, labels):
    if tok in labels:
        return labels[tok]
    if re.fullmatch(r"[A-Za-z_]\w*", tok):
        raise AsmError(f"undefined label: '{tok}'")
    v = parse_number(tok)
    if not 0 <= v < MAX_INSTRUCTIONS:
        raise AsmError(
            f"address out of range: '{tok}' (0-{MAX_INSTRUCTIONS - 1})")
    return v


# --------------------------------------------------------------------------
# Tokenising
# --------------------------------------------------------------------------

def strip_comment(line):
    for marker in (";", "//", "#"):
        idx = line.find(marker)
        if idx != -1:
            line = line[:idx]
    return line.strip()


def split_operands(rest):
    if not rest:
        return []
    return [t for t in re.split(r"[,\s]+", rest) if t]


def expand_pseudo(mnem, ops):
    real, template = PSEUDO[mnem]
    expected = PSEUDO_ARITY[mnem]
    if len(ops) != expected:
        raise AsmError(
            f"{mnem} takes {expected} operand(s), got {len(ops)}")
    out = []
    for slot in template:
        if slot.startswith("$"):
            out.append(ops[int(slot[1:])])
        else:
            out.append(slot)
    return real, out


# --------------------------------------------------------------------------
# Encoding
# --------------------------------------------------------------------------

def pack_high(opcode, n1):
    """Build the high ROM word according to the configured alignment."""
    if HIGH_ALIGN == "left":
        return (opcode << 8) | (n1 << 4)
    if HIGH_ALIGN == "right":
        return (opcode << 4) | n1
    raise AsmError(f"invalid HIGH_ALIGN: '{HIGH_ALIGN}' (use 'left' or 'right')")


def encode(mnem, ops, labels):
    opcode, form = ISA[mnem]
    expected = ARITY[form]
    if len(ops) != expected:
        raise AsmError(f"{mnem} takes {expected} operand(s), got {len(ops)}")

    n1, low = 0, 0

    if form == "rrr":
        n1 = parse_register(ops[0])
        low = (parse_register(ops[1]) << 12) | (parse_register(ops[2]) << 8)
    elif form == "rr":
        n1 = parse_register(ops[0])
        low = parse_register(ops[1]) << 8
    elif form == "none":
        pass
    elif form == "ri":
        n1 = parse_register(ops[0])
        low = to_u16(parse_imm(ops[1], labels), ops[1])
    elif form == "ra":
        n1 = parse_register(ops[0])
        low = pack_addr(parse_imm(ops[1], labels), MEM_ADDR_SHIFT, ops[1])
    elif form == "j":
        low = pack_addr(parse_address(ops[0], labels), BRANCH_ADDR_SHIFT, ops[0])
    elif form == "cj":
        n1 = parse_condition(ops[0])
        low = pack_addr(parse_address(ops[1], labels), BRANCH_ADDR_SHIFT, ops[1])
    elif form == "pa":
        n1 = parse_nibble(ops[0], "port")
        low = pack_addr(parse_number(ops[1]), MEM_ADDR_SHIFT, ops[1])
    elif form == "rp":
        low = ((parse_register(ops[0]) << PSR_REG_SHIFT)
               | (parse_nibble(ops[1], "port") << PORT_SHIFT))
    elif form == "rr2":
        n1 = parse_register(ops[0])
        low = parse_register(ops[1]) << 12
    elif form == "r":
        n1 = parse_register(ops[0])

    high = pack_high(opcode, n1)
    return high, low


# --------------------------------------------------------------------------
# Passes
# --------------------------------------------------------------------------

def first_pass(lines):
    """Collect labels and the instruction list, keeping source line numbers."""
    labels = {}
    program = []
    errors = []

    for lineno, raw in enumerate(lines, 1):
        text = strip_comment(raw)
        while text:
            m = re.match(r"([A-Za-z_]\w*)\s*:", text)
            if not m:
                break
            name = m.group(1)
            if name in labels:
                errors.append(f"line {lineno}: duplicate label '{name}'")
            elif name.upper() in ISA or name.upper() in PSEUDO:
                errors.append(
                    f"line {lineno}: '{name}' is a mnemonic, cannot be a label")
            else:
                labels[name] = len(program)
            text = text[m.end():].strip()

        if not text:
            continue

        parts = text.split(None, 1)
        mnem = parts[0].upper()
        ops = split_operands(parts[1] if len(parts) > 1 else "")

        if mnem not in ISA and mnem not in PSEUDO:
            errors.append(f"line {lineno}: unknown instruction '{parts[0]}'")
            continue

        program.append((lineno, mnem, ops, text))

    if len(program) > MAX_INSTRUCTIONS:
        errors.append(
            f"program too long: {len(program)} instructions, "
            f"the maximum is {MAX_INSTRUCTIONS}")

    return labels, program, errors


def second_pass(program, labels):
    words = []
    errors = []
    for lineno, mnem, ops, _src in program:
        try:
            if mnem in PSEUDO:
                mnem, ops = expand_pseudo(mnem, ops)
            words.append(encode(mnem, ops, labels))
        except AsmError as e:
            errors.append(f"line {lineno}: {e}")
            words.append((0, 0))
    return words, errors


# --------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------

def listing(words, program):
    """Print the fields separated, to check the wiring at a glance."""
    def b(v, n):
        return format(v, f"0{n}b")

    if HIGH_ALIGN == "left":
        head = "idx   opcode   n1   --     n2   n3   n4   n5     source"
    else:
        head = "idx   --   opcode   n1     n2   n3   n4   n5     source"
    print(head)
    print("-" * len(head))

    for i, ((high, low), (_ln, _m, _o, src)) in enumerate(zip(words, program)):
        if HIGH_ALIGN == "left":
            hi = f"{b(high >> 8, 8)} {b((high >> 4) & 0xF, 4)} {b(high & 0xF, 4)}"
        else:
            hi = f"{b(high >> 12, 4)} {b((high >> 4) & 0xFF, 8)} {b(high & 0xF, 4)}"
        lo = " ".join(b((low >> sh) & 0xF, 4) for sh in (12, 8, 4, 0))
        print(f"{i:3d}   {hi}     {lo}     {src}")


def render(value, fmt):
    if fmt == "hex":
        return f"{value:04X}"
    if fmt == "dec":
        return str(value)
    return f"{value:016b}"


def main():
    ap = argparse.ArgumentParser(description="Parallax V3 assembler")
    ap.add_argument("source", help="source .asm file")
    ap.add_argument("-o", "--outdir", default=".", help="output directory")
    ap.add_argument("--format", choices=["hex", "dec", "bin"], default="hex",
                    help="number representation (default: hex)")
    ap.add_argument("--listing", action="store_true",
                    help="print instruction fields separated, in binary")
    ap.add_argument("--pad", action="store_true",
                    help="pad to 256 lines with NOP")
    args = ap.parse_args()

    try:
        with open(args.source, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        print(f"error: cannot read {args.source}: {e}", file=sys.stderr)
        return 1

    labels, program, errors = first_pass(lines)
    words, more_errors = second_pass(program, labels)
    errors += more_errors

    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        print(f"\n{len(errors)} error(s), no files written.", file=sys.stderr)
        return 1

    if args.listing:
        listing(words, program)
        print()

    if args.pad:
        nop_high = pack_high(ISA["NOP"][0], 0)
        while len(words) < MAX_INSTRUCTIONS:
            words.append((nop_high, 0))

    os.makedirs(args.outdir, exist_ok=True)
    high_path = os.path.join(args.outdir, "rom_high.txt")
    low_path = os.path.join(args.outdir, "rom_low.txt")

    with open(high_path, "w", encoding="utf-8") as f:
        f.write("\n".join(render(h, args.format) for h, _ in words) + "\n")
    with open(low_path, "w", encoding="utf-8") as f:
        f.write("\n".join(render(l, args.format) for _, l in words) + "\n")

    print(f"{len(words)} instructions assembled ({args.format}).")
    print(f"  {high_path}   -> high ROM chip")
    print(f"  {low_path}    -> low ROM chip")
    if labels:
        print("\nLabels:")
        for name, addr in sorted(labels.items(), key=lambda kv: kv[1]):
            print(f"  {addr:3d}  {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
