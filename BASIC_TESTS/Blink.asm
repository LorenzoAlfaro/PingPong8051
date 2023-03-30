;
; MCU Co-Sim Test Program Suite
; Blinking Lights
; Copyright 2005 Electronics Workbench Inc.
;$MOD51

;$TITLE(BLINKING LIGHTS TEST)

;
; Variables
;

; Input port for mode control switches
; Switches A (bit-0), B (bit-1), and C (bit-2)
; B=0,A=0  Sweeping Eye pattern
; B=0,A=1  Meter pattern
; B=1,A=0  8-bit Counter (switch C controls increment or decrement)
; B=1,A=1  Marquis pattern (switch C controls left or right direction)
INPORT  EQU   P1

; Output connected to LED bank.
OUTPORT EQU   P2


; Program Code Start

; MCU Reset
; MCU Initialization Code
Reset:
        ; move stack pointer past register banks
        MOV SP, #20H

Begin:
Dispatch:
        ; The dispatch section reads switches A and B and
        ; runs the corresponding display pattern.
        ; R7 holds the (A,B) selection so that a change in
        ; the switches can be detected easily and generically.
        ; The A/B bits are used to index into the jump table.
        ; 
        MOV DPL,#LOW(DispatchJumpTable)  ; set start of jump table
        MOV DPH,#HIGH(DispatchJumpTable)
        MOV A,INPORT  ; Read input port
        ANL A,#003H   ; Confine to 4 choices
        MOV R7,A      ; Make copy in R7 for comparisons
        RL A          ; multiply by two since each AJMP is two bytes
        JMP @A+DPTR

DispatchJumpTable:
        AJMP SweepingEyeBegin
        AJMP MeterBegin
        AJMP CounterBegin
        AJMP MarquisBegin

;
; Sweeping Eye Pattern
; 
; A small block of lights sweep left across the LED bank and
; then sweep back right
;

SweepingEyeBegin:
        MOV R0,#00DH
        MOV R3,#0F0H
        MOV R4,#000H

LeftSweepLoop:
        CALL delay
        MOV A,R4 ; copy R4 to output
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A

        CLR C
        MOV A,R3
        RLC A
        MOV R3,A
        MOV A,R4
        RLC A
        MOV R4,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ SweepingEyeEnd

        DJNZ R0, LeftSweepLoop

        ; Setup values for sweep right
        MOV R0,#00DH
        MOV R4,#000H
        MOV R3,#00FH

RightSweepLoop:
        CALL delay
        MOV A,R4 ; copy R4 to output
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A

        ; do shift work
        CLR C
        MOV A,R3
        RRC A
        MOV R3,A
        MOV A,R4
        RRC A
        MOV R4,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ SweepingEyeEnd

        DJNZ R0, RightSweepLoop

SweepingEyeEnd:
        JMP Begin


;
; Meter Pattern
; 
; A lighted bar of LEDs grows and shrinks like
; an LED meter display
;

MeterBegin:
        MOV R0,#009H
        MOV R4,#000H

FwdMeterLoop:
        CALL delay
        MOV A,R4 ; copy R4 to output
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A

        SETB C
        MOV A,R4
        RLC A
        MOV R4,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ MeterEnd

        DJNZ R0,FwdMeterLoop

        ; Setup for reverse (shrinking) meter pattern
        MOV R0,#009H
        MOV R4,#0FFH

RevMeterLoop:
        CALL delay
        MOV A,R4 ; copy R4 to output
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A

        ; do shift work
        CLR C
        MOV A,R4
        RRC A
        MOV R4,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ MeterEnd

        DJNZ R0, RevMeterLoop

MeterEnd:
        JMP Begin

;
; 8-bit Counter Pattern
; 
; The bar of LEDs directly shows the counter value
; Switch C (INPORT bit 2) controls the increment or
; decrement direction
;

CounterBegin:
        MOV R0,#000H
CounterLoop:
        CALL delay
        MOV A,R0
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A
        CPL A

        ; Handle direction
        JB  INPORT.2,FwdCounter
        DEC A
        DEC A ; extra DEC to cancel INC
FwdCounter:
        INC A
        MOV R0,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ CounterEnd

        JMP CounterLoop
CounterEnd:
        JMP Begin

;
; Marquis Pattern
; 
; The pattern of lights moves left or right depending on
; Switch C (INPORT bit 2) and the pattern wraps in both directions
;

MarquisBegin:
        MOV R0,#0E2H
MarquisLoop:
        CALL delay
        MOV A,R0
        CPL A    ; Complement bits since LEDs driven by low signals
        MOV OUTPORT,A
        CPL A

        ; Handle direction
        JB  INPORT.2,FwdMarquis
        RRC A
        RRC A ; 
FwdMarquis:
        RLC A

        MOV R0,A

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ MarquisEnd

        JMP MarquisLoop
MarquisEnd:
        JMP Begin


;
; Delay Subroutine to slow down sequences to human speed
; 
delay:
        PUSH ACC
        MOV A, R5
        PUSH ACC
        MOV A, R6
        PUSH ACC
        MOV R5, #50  ; number of innerdelay's to call
        CLR A

outerdelay:
        MOV R6, A
        CALL innerdelay
        DJNZ R5, outerdelay

        POP ACC
        MOV R6, A
        POP ACC
        MOV R5, A
        POP ACC
delayend:
        RET

; innerdelay can be called directly for short delays
innerdelay:
        NOP
        NOP
        NOP
        NOP
        NOP
        DJNZ R6, innerdelay
        RET

END
