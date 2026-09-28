; First check: immediate loads only.
; Verifies the chain PC -> ROM -> splitter -> decoder -> register file.
; Values chosen to be recognisable at a glance.

        LDI  r1, 0x00FF         ; low byte full
        LDI  r2, 0x0001         ; single bit
        LDI  r3, 0xF0F0         ; alternating, high byte
        LDI  r4, 0x0F0F         ; alternating, low byte
        HLT