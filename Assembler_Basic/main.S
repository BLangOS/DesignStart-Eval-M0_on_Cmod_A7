    .section .vectors
// Vector table start
.long               _INITIAL_STACKPOINTER                     
.long               _start+1
// Vector table end

    .thumb
    .section .text
    
_start:
    /* R2  R0, R1 zu 0 setzen */
    SUB  R0, R0, R0
    MOV  R1, R0
    MOV  R2, R0
loop:
    ADD R0, R0, #1
    ADD R1, R1, #2
    ADD R2, R2, #3
    b loop
   
.global _start
