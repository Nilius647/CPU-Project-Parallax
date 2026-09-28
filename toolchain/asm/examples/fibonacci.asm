; Fibonacci — Parallax V2
; Ten iterations. Result (89) ends up in r2 and MEM[0].
;
;   r1 = previous term
;   r2 = current term
;   r3 = counter
;   r4 = scratch

        LDI  r1, 0
        LDI  r2, 1
        LDI  r3, 10

loop:
        ADD  r1, r2, r4     ; r4 = r1 + r2
        MOV  r2, r1         ; r1 = r2
        MOV  r4, r2         ; r2 = r4
        DEC  r3, r3         ; last ALU op before the branch
        BRH  nz, loop

        STR  r2, 0x0000     ; MEM[0] = result
        HLT