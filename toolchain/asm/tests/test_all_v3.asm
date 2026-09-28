; Parallax V3 — collaudo (test suite)
; Exercises all 33 instructions plus the pseudo-instructions.
; Run single-step, watching the register file.
;
; Before starting, set by hand:  IN[0] = 0x1234   IN[1] = 0x5678

; ---- immediate loads ------------------------------------------------
        LDI  r1, 0x00FF         ; r1 = 255
        LDI  r2, 0x0001         ; r2 = 1
        LDI  r3, 0xF0F0         ; r3 = 61680
        LDI  r4, 0x0F0F         ; r4 = 3855

; ---- arithmetic -------------------------------------------------------
        ADD  r1, r2, r5         ; r5 = 256
        SUB  r1, r2, r6         ; r6 = 254
        INC  r1, r7             ; r7 = 256
        DEC  r1, r8             ; r8 = 254
        ADI  r2, 0x0010         ; r2 = 17
        ADI  r2, -1             ; r2 = 16   (negative immediate)

; ---- bitwise logic ------------------------------------------------------
        NOT  r3, r9             ; r9  = 0x0F0F
        AND  r3, r4, r10        ; r10 = 0x0000
        OR   r3, r4, r11        ; r11 = 0xFFFF
        XOR  r3, r4, r12        ; r12 = 0xFFFF
        NAND r3, r4, r13        ; r13 = 0xFFFF
        NOR  r3, r4, r14        ; r14 = 0x0000
        XNOR r3, r4, r15        ; r15 = 0x0000
        IMPLY  r3, r4, r5       ; r5 = (NOT r3) OR r4
        NIMPLY r3, r4, r6       ; r6 = r3 AND (NOT r4)

; ---- shifts -----------------------------------------------------------
        SHL  r2, r7             ; r7 = 32
        SHR  r2, r8             ; r8 = 8

; ---- multiplication -----------------------------------------------------
        LDI  r1, 0x000C
        LDI  r2, 0x000C
        MUL  r1, r2, r3         ; r3 = 144, no overflow
        BRH  ov, error

        LDI  r1, 0xFFFF
        LDI  r2, 0xFFFF
        MUL  r1, r2, r3         ; r3 = 0x0001, overflow expected
        BRH  ov, mul_ok
        JMP  error              ; overflow was not detected
mul_ok:

; ---- pseudo-instructions (zero register) -------------------------------
        LDI  r1, 0x00FF
        MOV  r1, r9             ; r9 = r1
        CLR  r10                ; r10 = 0
        NEG  r2, r11            ; r11 = -r2
        CMP  r1, r2             ; flags only, no write

; ---- memory, constant address ------------------------------------------
        STR  r1, 0x0000         ; MEM[0] = r1
        STR  r2, 0x0001         ; MEM[1] = r2
        LOD  r12, 0x0000        ; r12 = MEM[0]
        LOD  r13, 0x0001        ; r13 = MEM[1]

; ---- memory, pointers ---------------------------------------------------
        LDI  r1, 0x0200         ; pointer
        LDI  r2, 0xBEEF         ; data
        STP  r2, r1             ; MEM[0x0200] = 0xBEEF
        LDP  r3, r1             ; r3 = 0xBEEF
        LOD  r4, 0x0200         ; r4 = 0xBEEF  <- cross-check
        INC  r1, r1
        STP  r2, r1             ; MEM[0x0201]
        LOD  r5, 0x0201         ; r5 = 0xBEEF

; ---- ports --------------------------------------------------------------
; IN and OUT are separate spaces: whatever is written to OUT[n] cannot be
; read back from IN[n].
        LDI  r1, 0x00FF
        PSR  r1, 0              ; OUT[0] = 0x00FF
        PLR  r14, 0             ; r14 = IN[0]     -> expected: 1234
        PSM  1, 0x0000          ; OUT[1] = MEM[0]
        PLM  1, 0x0002          ; MEM[2] = IN[1]
        LOD  r13, 0x0002        ; r13 = MEM[2]    -> expected: 5678

; ---- subroutines --------------------------------------------------------
        LDI  r1, 10
        CAL  double             ; r1 = 20
        CAL  double             ; r1 = 40
        CAL  outer              ; checks nesting -> r1 = 160

; ---- computed jump --------------------------------------------------------
        LDI  r1, forward
        JMR  r1                 ; jump to 'forward'
        JMP  error              ; must not be reached
forward:

; ---- branches and conditions --------------------------------------------
        LDI  r1, 0x0005         ; counter
loop:
        DEC  r1, r1
        BRH  nz, loop           ; repeat while r1 != 0

        CMP  r2, r2
        BRH  eq, equal
        JMP  error
equal:
        NOP
        LDI  r15, 0xBEEF        ; success marker
        HLT

error:
        LDI  r15, 0xDEAD        ; failure marker
        HLT

; ---- subroutines --------------------------------------------------------
; double: r1 = r1 * 2
; clobbers: nothing
double:
        SHL  r1, r1
        RET

; outer: r1 = r1 * 4, by calling double twice
; clobbers: nothing — checks the stack at two levels of nesting
outer:
        CAL  double
        CAL  double
        RET