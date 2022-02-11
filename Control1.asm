;http://www.mytutorialcafe.com/index%20Tutorial.htm
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
INPORT  EQU   P3

; Output connected to LED bank.
OUTPORT EQU   P1

NUM1L	DATA	020H


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



SweepingEyeBegin:

	CALL LETRAA
        
        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ SweepingEyeEnd

        

SweepingEyeEnd:
        JMP Begin


;


MeterBegin:
        CALL LETRAL

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ MeterEnd

        

MeterEnd:
        JMP Begin




CounterBegin:

       	CALL LETRAF
       

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ CounterEnd

        
CounterEnd:
        JMP Begin

;
; Marquis Pattern
; 
; The pattern of lights moves left or right depending on
; Switch C (INPORT bit 2) and the pattern wraps in both directions
;

MarquisBegin:
        CALL LETRAO

        MOV A,INPORT   ; branch to beginning if config inputs change
        ANL A,#003H
        XRL A,R7
        JNZ MarquisEnd

        
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

LetraA:	mov R1,#255
Pause1: 	mov R2,#255
Pause2:  
	MOV	P1, #77H
	MOV	P1,#0BAH
	MOV	P1,#0DAH
	MOV	P1,#0E7H
	djnz R2,PAUSE2
	djnz R1,PAUSE1
	RET

LetraL:	mov R1,#255
Pause11: 	mov R2,#255
Pause21:  
	MOV	P1, #7FH
	MOV	P1,#0B1H
	MOV	P1,#0D1H
	MOV	P1,#0E0H
	djnz R2,PAUSE21
	djnz R1,PAUSE11
	RET

LetraF:	mov R1,#255
Pause1a: 	mov R2,#255
Pause2a:  
	MOV	P1,#07FH
	MOV	P1,#0BAH
	MOV	P1,#0D8H
	MOV	P1,#0E0H
	djnz R2,PAUSE2a
	djnz R1,PAUSE1a
	RET
LetraO:	mov R1,#255
Pause1O: 	mov R2,#255
Pause2O:  
	MOV	P1,#076H
	MOV	P1,#0B9H
	MOV	P1,#0D9H
	MOV	P1,#0E6H
	djnz R2,PAUSE2O
	djnz R1,PAUSE1O
	RET

END

