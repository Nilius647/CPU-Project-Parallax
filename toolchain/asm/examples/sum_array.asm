; Sum an array of 16 words, using a pointer and a subroutine.
; Demonstrates LDP and CAL/RET.
;
; Result: r3 = sum of MEM[0x0100 .. 0x010F]

        LDI  r1, 0x0100     ; pointer to the start of the array
        LDI  r2, 16         ; how many words
        CAL  sum_array      ; result lands in r3
        STR  r3, 0x0000     ; MEM[0] = result
        HLT

; sum_array: r3 = sum of r2 words starting at r1
; clobbers: r1, r2, r4
sum_array:
        CLR  r3
loop:
        LDP  r4, r1         ; r4 = MEM[r1]
        ADD  r3, r4, r3     ; accumulate
        INC  r1, r1         ; advance the pointer
        DEC  r2, r2         ; last ALU op before the branch
        BRH  nz, loop
        RET