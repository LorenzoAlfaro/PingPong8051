WRITE_VIDEO_MEMORY:
	PUSH	0
	PUSH	1
	PUSH	2
	PUSH	3
	PUSH	ACC
	PUSH	82H		;DPL
	PUSH	83H		;PDH

	MOV	DPTR, 	#LUT_PAD
	MOV	A, 	PAD1			;USO A como OFFSET qu
	MOVC	A, 	@A+DPTR			;Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV	ADRE_PAD1A, A
	MOV	A, 	PAD2			;USO A como OFFSET qu
	MOVC	A, 	@A+DPTR			;Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV	ADRE_PAD2A, A

	MOV	DPTR, 	#LUT_PAD2
	MOV	A, 	PAD1			;use el mismo offset
	MOVC	A, 	@A+DPTR
	MOV	ADRE_PAD1B, A

	MOV	A, 	PAD2			;use el mismo offset
	MOVC	A, 	@A+DPTR
	MOV	ADRE_PAD2B, A

	MOV	DPTR, 	#LUT_BALL
	MOV	A, 	Y
	MOVC	A, 	@A+DPTR
	MOV	R2, 	A				;temporalmente lo guardo en R2
	MOV	DPTR, 	#LUT_BALL2
	MOV	A, 	Y
	MOVC	A, 	@A+DPTR
	MOV	R3, 	A				;temporalmente lo guardo en R2

	MOV	R0, 	#MEMORIAVIDEO	;uso R0 como indice
	MOV	R1, 	#MEMORIAVIDEO2

	MOV	A, 	X
	ADD	A, 	R0				;le pongo a R0 el offset de X
	MOV	R0, 	A

	MOV	A, 	X
	ADD	A, 	R1				;le pongo a R0 el offset de X
	MOV	R1, 	A

	MOV	A, 	R2
	MOV	@R0, 	A

	MOV	A, 	R3
	MOV	@R1, 	A


	POP	83H
	POP	82H
	POP	ACC
	POP	3
	POP	2
	POP	1
	POP	0

	RET

CLEAR_VIDEO_MEMORY:
	PUSH	0
	PUSH	1

	MOV	R1, 	#30
	MOV	R0, 	#MEMORIAVIDEO
BORRAR:
	MOV	@R0, 	#0
	INC	R0
	DJNZ	R1, 	BORRAR

	POP	1
	POP	0
	RET

WRITE_TO_PPI:

	PUSH	ACC
	PUSH	0
	PUSH	1
	PUSH	2
	PUSH	82H
	PUSH	83H

	MOV	R2, 	#0FH
	MOV	R0,	#MEMORIAVIDEO
	MOV	R1,	#MEMORIAVIDEO2

AA90:
	CALL 	CLEAR_PPI
	MOV	DPTR, 	#PORT_C				;mando el valor de la columna
	MOV	A,	R2
	MOVX	@DPTR, 	A

	MOV	A, 	@R0
	MOV	DPTR, 	#PORT_A				;Programo el PPI
	MOVX	@DPTR, 	A

	INC 	DPTR						;apunto a PUERT B
	INC 	R0

	MOV	A, 	@R1
	MOVX	@DPTR, 	A
	INC	R1

	DJNZ	R2,	AA90
	POP	83H
	POP	82H
	POP	2
	POP	1
	POP	0
	POP	ACC
	RET
;----------------------------------------------------------------------------
CLEAR_PPI:
	PUSH	82H
	PUSH	83H
	PUSH	ACC

	MOV	DPTR, 	#PORT_A
	CLR	A
	MOVX	@DPTR, 	A
	INC	DPTR						;APUNTA A PUERTO B
	MOVX	@DPTR, 	A

	POP	ACC
	POP	83H
	POP 	82H
	RET

;----------------------------------------------------------------------------
Delay_0_2:
	PUSH	0
	PUSH	1
	PUSH	2
	MOV	R2, 	#002h
	MOV	R1, 	#0F5h
	MOV	R0, 	#042h
	NOP
	DJNZ	R0, 	$
	DJNZ	R1, 	$-5
	DJNZ	R2, 	$-9
	MOV	R0, 	#009h
	DJNZ	R0, 	$
	NOP
	POP	2
	POP	1
	POP	0
	RET