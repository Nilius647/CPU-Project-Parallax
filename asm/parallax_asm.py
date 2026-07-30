#!/usr/bin/env python3
"""
Parallax V2 assembler
"""

import argparse
import os
import re
import sys

HIGH_ALIGN = "right"

PORT_SHIFT = 12

MAX_INSTRUCTIONS = 256

ISA = {
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
    "NOP":    (0x0F, "none"),
    "HLT":    (0x10, "none"),
    "LDI":    (0x11, "ri"),
    "ADI":    (0x12, "ri"),
    "JMP":    (0x13, "j"),
    "BRH":    (0x14, "cj"),
    "STR":    (0x15, "ri"),
    "LOD":    (0x16, "ri"),
    "PSM":    (0x17, "pi"),
    "PLM":    (0x18, "pi"),
    "PSR":    (0x19, "rp"),
    "PLR":    (0x1A, "rp"),
}

PSEUDO = {
    "MOV": ("ADD", ["r0", "$0", "$1"]),   # MOV rS, rD   ->  rD = rS
    "CLR": ("ADD", ["r0", "r0", "$0"]),   # CLR rD       ->  rD = 0
    "NEG": ("SUB", ["r0", "$0", "$1"]),   # NEG rS, rD   ->  rD = -rS
    "CMP": ("SUB", ["$0", "$1", "r0"]),   # CMP rA, rB   ->  only flags
}

CONDITIONS = {
    "C": 0b000, "CARRY": 0b000,
    "GT": 0b001,
    "EQ": 0b010,
    "LT": 0b011,
    "Z": 0b100, "ZERO": 0b100,
    "NC": 0b101,
    "NZ": 0b110,
}

ARITY = {"rrr": 3, "rr": 2, "none": 0, "ri": 2, "j": 1, "cj": 2, "pi": 2, "rp": 2}
PSEUDO_ARITY = {"MOV": 2, "CLR": 1, "NEG": 2, "CMP": 2}


class AsmError(Exception):
    pass

def parse_register(tok):
    m = re.fullmatch(r"[rR](\d{1,2})", tok)
    if not m:
        raise AsmError(f"registro non valido: '{tok}' (attesi r0-r15)")
    n = int(m.group(1))
    if n > 15:
        raise AsmError(f"registro fuori intervallo: '{tok}' (massimo r15)")
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
        raise AsmError(f"numero non valido: '{tok}'")
    return -v if neg else v


def to_u16(v, tok):
    if -32768 <= v < 0:
        return v + 0x10000
    if 0 <= v <= 0xFFFF:
        return v
    raise AsmError(f"valore fuori intervallo a 16 bit: '{tok}'")


def parse_nibble(tok, what):
    v = parse_number(tok)
    if not 0 <= v <= 15:
        raise AsmError(f"{what} fuori intervallo: '{tok}' (attesi 0-15)")
    return v


def parse_condition(tok):
    key = tok.upper()
    if key in CONDITIONS:
        return CONDITIONS[key]
    v = parse_number(tok) if re.fullmatch(r"-?\w+", tok) else None
    if v is not None and 0 <= v <= 15:
        return v
    valid = ", ".join(sorted(set(CONDITIONS)))
    raise AsmError(f"condizione non valida: '{tok}' (valide: {valid})")


def parse_address(tok, labels):
    if tok in labels:
        return labels[tok]
    if re.fullmatch(r"[A-Za-z_]\w*", tok):
        raise AsmError(f"label non definita: '{tok}'")
    v = parse_number(tok)
    if not 0 <= v < MAX_INSTRUCTIONS:
        raise AsmError(
            f"indirizzo fuori intervallo: '{tok}' (0-{MAX_INSTRUCTIONS - 1})")
    return v

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
            f"{mnem} richiede {expected} operandi, ricevuti {len(ops)}")
    out = []
    for slot in template:
        if slot.startswith("$"):
            out.append(ops[int(slot[1:])])
        else:
            out.append(slot)
    return real, out

def pack_high(opcode, n1):
    """Compone la parola della ROM alta secondo l'allineamento configurato."""
    if HIGH_ALIGN == "left":
        return (opcode << 8) | (n1 << 4)
    if HIGH_ALIGN == "right":
        return (opcode << 4) | n1
    raise AsmError(f"HIGH_ALIGN non valido: '{HIGH_ALIGN}' (usa 'left' o 'right')")


def encode(mnem, ops, labels):
    opcode, form = ISA[mnem]
    expected = ARITY[form]
    if len(ops) != expected:
        raise AsmError(
            f"{mnem} richiede {expected} operandi, ricevuti {len(ops)}")

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
        low = to_u16(parse_number(ops[1]), ops[1])
    elif form == "j":
        low = parse_address(ops[0], labels)
    elif form == "cj":
        n1 = parse_condition(ops[0])
        low = parse_address(ops[1], labels)
    elif form == "pi":
        n1 = parse_nibble(ops[0], "porta")
        low = to_u16(parse_number(ops[1]), ops[1])
    elif form == "rp":
        n1 = parse_register(ops[0])
        low = parse_nibble(ops[1], "porta") << PORT_SHIFT

    high = pack_high(opcode, n1)
    return high, low

def first_pass(lines):
    """Raccoglie le label e la lista delle istruzioni con il numero di riga."""
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
                errors.append(f"riga {lineno}: label duplicata '{name}'")
            elif name.upper() in ISA or name.upper() in PSEUDO:
                errors.append(
                    f"riga {lineno}: '{name}' e' un mnemonico, non usarlo come label")
            else:
                labels[name] = len(program)
            text = text[m.end():].strip()

        if not text:
            continue

        parts = text.split(None, 1)
        mnem = parts[0].upper()
        ops = split_operands(parts[1] if len(parts) > 1 else "")

        if mnem not in ISA and mnem not in PSEUDO:
            errors.append(f"riga {lineno}: istruzione sconosciuta '{parts[0]}'")
            continue

        program.append((lineno, mnem, ops, text))

    if len(program) > MAX_INSTRUCTIONS:
        errors.append(
            f"programma troppo lungo: {len(program)} istruzioni, "
            f"il massimo e' {MAX_INSTRUCTIONS}")

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
            errors.append(f"riga {lineno}: {e}")
            words.append((0, 0))
    return words, errors

def listing(words, program):
    """Stampa i campi separati, per controllare il cablaggio a colpo d'occhio."""
    def b(v, n):
        return format(v, f"0{n}b")

    if HIGH_ALIGN == "left":
        head = "ind   opcode   n1   --     n2   n3   n4   n5     sorgente"
    else:
        head = "ind   --   opcode   n1     n2   n3   n4   n5     sorgente"
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
    ap = argparse.ArgumentParser(description="Assemblatore Parallax V2")
    ap.add_argument("source", help="file sorgente .asm")
    ap.add_argument("-o", "--outdir", default=".", help="cartella di output")
    ap.add_argument("--format", choices=["hex", "dec", "bin"], default="hex",
                    help="rappresentazione dei numeri (default: hex)")
    ap.add_argument("--listing", action="store_true",
                    help="stampa i campi dell'istruzione separati in binario")
    ap.add_argument("--pad", action="store_true",
                    help="riempi fino a 256 righe con NOP")
    args = ap.parse_args()

    try:
        with open(args.source, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        print(f"errore: impossibile leggere {args.source}: {e}", file=sys.stderr)
        return 1

    labels, program, errors = first_pass(lines)
    words, more_errors = second_pass(program, labels)
    errors += more_errors

    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        print(f"\n{len(errors)} errore/i, nessun file prodotto.", file=sys.stderr)
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

    print(f"{len(words)} istruzioni assemblate ({args.format}).")
    print(f"  {high_path}   -> chip ROM alta")
    print(f"  {low_path}    -> chip ROM bassa")
    if labels:
        print("\nLabel:")
        for name, addr in sorted(labels.items(), key=lambda kv: kv[1]):
            print(f"  {addr:3d}  {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
