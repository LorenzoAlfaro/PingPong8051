WRITE_VIDEO_MEMORY:
	PUSH	0
	PUSH	1
	PUSH	2
	PUSH	3
	PUSH	ACC
	PUSH	82H		;DPL
	PUSH	83H		;PDH

	; GET PART ONE of the PAD SPRITE
	MOV	DPTR, #LUT_PAD

	MOV A, PAD1			; USO A como OFFSET qu
	MOVC A, @A+DPTR			; Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV ADRE_PAD1A, A		; Store the sprite in the 'video memory'

	MOV A, PAD2			; USO A como OFFSET qu
	MOVC A, @A+DPTR			; Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV ADRE_PAD2A, A		; Store the sprite in the 'video memory'

	MOV DPTR, #LUT_PAD2

	MOV A, PAD1			;use el mismo offset
	MOVC A, @A+DPTR
	MOV ADRE_PAD1B, A

	MOV A, PAD2			;use el mismo offset
	MOVC A,	@A+DPTR
	MOV ADRE_PAD2B, A

	MOV DPTR, #LUT_BALL

	MOV A, Y
	MOVC A, @A+DPTR
	MOV R2, A				;temporalmente guardo SPRITE en R2

	MOV R0, #MEMORIAVIDEO	;uso R0 como indice
	MOV A, X
	ADD A, R0				;le pongo a R0 el offset de X
	MOV R0, A
	; R0 = #MEMORIAVIDEO + X
	MOV A, R2
	MOV @R0, A
	; SAVE SPRITE_A in video memory


	MOV DPTR, #LUT_BALL2

	MOV A, Y
	MOVC A, @A+DPTR
	MOV R3, A				;temporalmente guardo SPRITE en R2

	MOV R1, #MEMORIAVIDEO2
	MOV A, X
	ADD A, R1				;le pongo a R1 el offset de X
	MOV R1, A
	; R1 = #MEMORIAVIDEO2 + X
	MOV A, R3
	MOV @R1, A
	; SAVE SPRITE_B in video memory

	POP 83H
	POP 82H
	POP ACC
	POP 3
	POP 2
	POP 1
	POP 0

	RET

CLEAR_VIDEO_MEMORY:
	PUSH 0
	PUSH 1

	MOV R1, #30 ; TODO clean the SPRITE memory in two loops, instead of 1, that way memory_a and memory_b doesn't have to be contingous
	MOV R0, #MEMORIAVIDEO
BORRAR:
	MOV @R0, #0
	INC R0
	DJNZ R1, BORRAR

	POP 1
	POP 0
	RET

WRITE_TO_PPI:

	PUSH ACC
	PUSH 0
	PUSH 1
	PUSH 2
	PUSH 82H
	PUSH 83H

	MOV R2, #0FH ; Start with 15, and decrement
	MOV R0, #MEMORIAVIDEO
	MOV R1, #MEMORIAVIDEO2

AA90:
	CALL CLEAR_PPI

	MOV DPTR, #PORT_C	; mando el valor de la columna
	MOV A, R2
	MOVX @DPTR, A ; TODO: move port be to last, and use INC DPTR instead of MOV	DPTR, #PORT_C
	; PORT_C = COLUMN VALUE FOR MUX

	MOV DPTR, #PORT_A

	MOV A, @R0
	MOVX @DPTR, A
	; PORT_A = SPRITE_A
	INC R0

	INC DPTR ; apunto a PUERTO B -- same as MOV DPTR, #PORT_B

	MOV A, @R1
	MOVX @DPTR, A
	; PORT_B = SPRITE_B
	INC R1

	DJNZ R2, AA90 ; REPEAT UNTIL COLUMN == 0

	POP 83H
	POP 82H
	POP 2
	POP 1
	POP 0
	POP ACC
	RET
;----------------------------------------------------------------------------
CLEAR_PPI:
	PUSH 82H
	PUSH 83H
	PUSH ACC

	MOV DPTR, #PORT_A
	CLR A
	MOVX @DPTR, A
	INC DPTR						;APUNTA A PUERTO B
	MOVX @DPTR, A

	POP ACC
	POP 83H
	POP 82H
	RET

;----------------------------------------------------------------------------
Delay_0_2:
	PUSH 0
	PUSH 1
	PUSH 2
	MOV	R2, #002h
	MOV	R1, #0F5h
	MOV	R0, #042h
	NOP
	DJNZ R0, $
	DJNZ R1, $-5
	DJNZ R2, $-9
	MOV	R0, #009h
	DJNZ R0, $
	NOP
	POP 2
	POP 1
	POP 0
	RET