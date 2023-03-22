OR_MACRO MACRO OR_A, OR_B, Variable
	MOV	A_O, 	#OR_A				;X=1 OR X=14    LA bola esta en zona de paleta?????
	MOV	B_O, 	#OR_B
	MOV	C_O, 	Variable
	CALL	OR_2
ENDM
;--------------------------------------RUTINAS DE LOGICA-----------------------------------------------
OR_2:
;Empiezo la logica de OR
	PUSH	ACC
	CLR	O1						;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT1
	MOV	A, 	C_O
	CJNE	A, A_O, seg_operando
	SETB	O1
seg_operando:
	CJNE	A, B_O, OPERACION_OR	;tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIRECCION
	SETB	O2
Operacion_OR:
	MOV	C, 	O1
	ORL	C, 	O2
	MOV	RESULT1, C
	POP	ACC
	RET
;--------------------------------------
AND_2:
;Empiezo la logica de AND
	PUSH	ACC
	CLR	O1						;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT2
	MOV	A, 	C_O
	CJNE	A, A_O, seg_operando2
	SETB	O1
seg_operando2:
	CJNE	A, B_O, OPERACION_AND	;tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIRECCION
	SETB	O2
Operacion_AND:
	MOV	C, 	O1
	ANL	C, 	O2
	MOV	RESULT2, 	C
	POP	ACC
	RET
;--------------------------------------
ESTA_RANGO:
	;Funcion logica para saber si un numero esta en un rango 1 < X  < 3
	PUSH	ACC
	CLR	O1							;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT2
	MOV	A, 	C_O

	CJNE	A, A_O, NOT_EQUAL
	SETB	O1
	SJMP	NEXT						;EQUAL A_O = C_O
;--------------------------------------
NOT_EQUAL:
	JC	NEXT						;jump if C_O < A_0
	SETB	O1							;C_O > A_O
;----------------------------------------------------------------------------
NEXT:
	CJNE	A, B_O, NOT_EQUAL2
	SETB	O2							;EQUAL	B_0 = C_O
	SJMP	A80
;----------------------------------------------------------------------------
NOT_EQUAL2:
	JNC	A80								;jump if C_O  > A_O
	SETB	O2
A80:
	MOV	C, 	O1
	ANL	C,	O2
	MOV	RESULT2, C
	POP	ACC
	RET