; Isolated test: subroutine nesting.
;
; Verifies that the stack pointer really rises and falls, instead of
; always rewriting the same cell.
;
; Expected, in order:
;   after the first block    r1 = 20    (one level)
;   after the second         r2 = 40    (two levels)
;   after the third          r3 = 80    (three levels)
;   at the end               r15 = 0xBEEF
;
; If it hangs in a loop, check the stack pointer: it should read
; 1, 2 and 3 respectively inside the three levels.

; ---- one level ----------------------------------------------------
        LDI  r1, 10
        CAL  double             ; r1 = 20
        LDI  r15, 0x0001        ; marker: one level passed

; ---- two levels -----------------------------------------------------
        LDI  r1, 10
        CAL  quadruple          ; calls double twice -> r1 = 40
        MOV  r1, r2
        LDI  r15, 0x0002        ; marker: two levels passed

; ---- three levels -----------------------------------------------------
        LDI  r1, 10
        CAL  octuple            ; -> quadruple -> double
        MOV  r1, r3             ; r3 = 80
        LDI  r15, 0x0003        ; marker: three levels passed

; ---- calls in sequence ----------------------------------------------
; Three calls in a row at the same level: checks that the stack really
; comes back down after each RET instead of accumulating.
        LDI  r1, 1
        CAL  double             ; r1 = 2
        CAL  double             ; r1 = 4
        CAL  double             ; r1 = 8

        LDI  r15, 0xBEEF        ; everything passed
        HLT

; ---- subroutines --------------------------------------------------------
; double: r1 = r1 * 2      level 1
double:
        SHL  r1, r1
        RET

; quadruple: r1 = r1 * 4   level 2
quadruple:
        CAL  double
        CAL  double
        RET

; octuple: r1 = r1 * 8     level 3
octuple:
        CAL  quadruple
        CAL  double
        RET