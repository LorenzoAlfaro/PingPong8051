PAD_M MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	MOV	R2, 	PAD_A
	CJNE	R2, #LIMIT, xyz
	SJMP	zyx						;TODO Logica de validacion que el pad no este en el limite
xyz:
	DEC	PAD_A
zyx:
	;RET
ENDM

PAD_P MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	MOV	R2, PAD_A
	CJNE	R2, #LIMIT, xyz
	SJMP	zyx						;TODO Logica de validacion que el pad no este en el limite
xyz:
	INC	PAD_A
zyx:
	;RET
ENDM

OR_MACRO MACRO OR_A, OR_B, Variable
	MOV	A_O, 	#OR_A				;X=1 OR X=14    LA bola esta en zona de paleta?????
	MOV	B_O, 	#OR_B
	MOV	C_O, 	Variable
	CALL	OR_2
ENDM

;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display
TAM_X			EQU	15
TAM_Y			EQU	16

									; PPI Ports addresses
PORT_A			EQU	02000H			; Direccion del puerto A en RAM Externa
PORT_B			EQU	02001H			; Para referenciar se usa MOVX
PORT_C			EQU	02002H
Reg_Control		EQU	02003H			; Recibe palabra de control

POS_PAD1		EQU	0H				; position dela tableta en la pantalla
POS_PAD2		EQU	0EH
Y_T			DATA	1EH			;variable temporal y
P_T			DATA	1FH			;Variable temporal de paleta
PAD1			DATA	20H			;Variables de posicion de objetos
PAD2			DATA	21H			;
X			DATA	22H			;OFFSET	para la MemoriaVIDEO
Y			DATA	23H			;OFFSET	para la LUT_BALL

MemoriaViDEO		EQU	40H
MemoriaVIDEO2		EQU	50H

MemoriaViDEOA		EQU	41H
MemoriaVIDEO2A		EQU	51H

ADRE_PAD1A		EQU	40H
ADRE_PAD1B		EQU	50H

ADRE_PAD2A		EQU	4EH
ADRE_PAD2B		EQU	5EH

SW				EQU	P1
UP_1			EQU	P1.0
DOWN_1			EQU	P1.1
UP_2			EQU	P1.2
DOWN_2			EQU	P1.3

UR			EQU	48H				; 00000001 RAM 29 Indican la direccion de la bola, SOLAMENTE puede estar uno
UL			EQU	49H				; 00000010
DR			EQU	4AH				; 00000100 pg 181
DL			EQU	4BH				; 00001000
UP			EQU	4CH				; 00010000
DOWN			EQU	4DH				; 00100000

A_O			DATA 	30H			; Almacenamiento temporal para los operandos de la or de alto nivel
B_O			DATA 	31H
C_O			DATA 	32H			; Elemento a comparar

O1			EQU	50H				;Direccion 2A, del bit 0			00000001
O2			EQU	51H				;	00000010
Result1			EQU	52H				;resultado logico donde se guarda		00000100
Result2			EQU	53H				;	00001000

	ORG		0

	SJMP	START

	ORG		30H		;Comienzo el programa saltando los vectores
START:

;--------------------------------------Seccion de INICIALIZACION
	;MOV	A_O, 	#0FFH
	;MOV	B_O, 	#4
	;MOV	C_O,	#3
	;CALL	ESTA_RANGO
	MOV	SP, 	#5FH
	MOV	A, 	#080H			; Esta palabara de control define A,B,C=outputs
	MOV	DPTR, 	#REG_CONTROL	; Cargo direccion del registro de control
	MOVX	@DPTR, 	A				; Programo el PPI
	MOV	PAD1, 	#7				; Inicializo la posicion de las paletas ; LEFT PAD
	MOV	PAD2, 	#8				; maxima posicion es 12			; RIGHT PAD
	MOV	X, 	#7
	MOV	Y, 	#7
	SETB	UL
;--------------------------------------TOMA DE DECICIONES LEYENDO P1
READ_PUERTO:
	MOV	A, 	SW				; Read input port
	;CALL    delay_0_2				;lee el switch cada 0.2 segundos
	ANL	A,	#00FH
	MOV	R7, 	A				; Make copy in R7 for comparisons
	CALL	CLEAR_VIDEO_MEMORY
;--------------------------------------LOGICA DE LAS TABLETAS-----------------------------
;Logica para  SUBE O BAJA PAD
PAD1_UP_DOWN:
	JB	UP_1, 	D1    ;UP_1 is the P1.0
	JNB	DOWN_1, PAD2_UP_DOWN
	PAD_P    PAD1, 12
D1:
	JB	DOWN_1, PAD2_UP_DOWN
	PAD_M    PAD1, 1

PAD2_UP_DOWN:
	JB	UP_2, 	D2
	JNB	DOWN_2, BALL_LOGIC
	PAD_P    PAD2, 12
D2:
	JB	DOWN_2, BALL_LOGIC
	PAD_M    PAD2, 1
;--------------------------------------INICIA LOGICA de la bola-------------------------------------------------
BALL_LOGIC:
	MOV 	A, 	X				; DEBUG: Save X value
	MOV	P3, 	A				; DEBUG: Print in port 3

	OR_MACRO #0, #14, X    ;X=0 OR X=14     ALGUIEN PERDIO?????
	JB	RESULT1, LOST

	OR_MACRO #1, #13, X    ;X=1 OR X=13    LA bola esta en zona de paleta?????
	JB	RESULT1, ZONA_PALETA

	OR_MACRO #1, #15, Y    ;y=0 OR y=14	LA bola esta en una pared???????????
	JB	RESULT1, CHOQUE_PARED
	;La bola sigue su curso--------------
IGUAL:

ACTION:
	; equivalent to a switch case where only at a time bit can be set UR, UL, DR, DL
	JB	UR, AUR_1
	JB	UL, AUL_1
	JB	DR, ADR_1
	JB 	DL, ADL_1	; trying to be smart, you just create unreadable code, this line could be commented out, but makes more sense
ADL_1:
	DEC	X
	INC	Y
	JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	;SJMP	GRAFICO
AUR_1:
	INC	X						;Lo incremento para ir a la derecha
	DEC	Y						;Lo decremento para  SUBIR
	JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	;SJMP	GRAFICO
AUL_1:
	DEC	X
	DEC	Y
	JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	;SJMP	GRAFICO
ADR_1:
	INC	X
	INC	Y
	JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	;SJMP	GRAFICO ; again, don't try to be too smart, just include this line for clarity

;--------------------------------------Paso a graficar-------------------
GRAFICO:
	; This is a 8 x 8 loop, of just display
	CALL	WRITE_VIDEO_MEMORY
	MOV 	R1,	#04H
Pause1a:
	MOV 	R2,	#04H
Pause2a:
	CALL	WRITE_TO_PPI
	DJNZ 	R2,	PAUSE2a
	DJNZ 	R1,	PAUSE1a
	;CALL	DELAY_0_2
	JMP	READ_PUERTO    ; This complete the game loop
;--------------------------------------Ramas de la logica-------------------------
LOST:
	JMP	START
CHOQUE_PARED:
	;CALL	REBOTE_PARED
    ;--------------------------------------Rebotes de la bola------------------------------------------
;Rebote_Pared:
	JBC	UR, UR_1
	JBC	UL, UL_1
	JBC	DR, DR_1	; again, don't try to be too smart, just include this line, intead "falling" to the next part
	JBC	DL,	DL_1
	JMP	ACTION
;----------------------------------------------------------------------------
DL_1:
	CLR	DL
	SETB	UL
	RET
;----------------------------------------------------------------------------
UR_1:
	SETB	DR
	RET
;----------------------------------------------------------------------------
UL_1:
	SETB	DL
	RET
;----------------------------------------------------------------------------
DR_1:
	SETB	UR
	RET	
	
ZONA_PALETA:
;	CALL	REBOTARA_PALETA
;REBOTARA_PALETA:
	;la logica mas compleja es la de la bola
	MOV	R2, 	X
	CJNE	R2, #1, PALETA_2	;cual es la paleta en cuestion
	MOV	P_T,	PAD1
	SJMP	A70
PALETA_2:
	MOV	P_T, 	PAD2
A70:
	MOV	A, 	P_T
	SUBB	A, 	#1
	MOV	R2, 	A				;R2 es mi P_minimo
	MOV	A_O, 	R2
	ADD	A, 	#5
	MOV	R3, 	A				;R3 es mi P_maximo
	MOV	B_O, 	R3
	MOV	C_O, 	Y
	CALL	ESTA_RANGO
	JNB	RESULT2, A60			;si no esta en el rango, continuo sin rebotar	
	OR_MACRO #1, #15, Y
	JB	RESULT1, A50			;es un caso especial?? Si, entonces rebote en la esquina
	MOV	C, 	DL
	ORL	C, 	DR
	MOV	DOWN, 	C				;la bola baja o	BIT	00100000			29H
	MOV	C, 	UL
	ORL	C, 	UR
	MOV	UP, 	C				;o sube			BIT 00010000		29H
	MOV	A, 	R2
	CJNE	A, Y, B90
	SETB	RESULT1
	SJMP	B80
B90:
	CLR	RESULT1
B80:
	MOV	C,	RESULT1
	ANL	C, 	DOWN			; y==Pmin AND  DOWN=1  ??
	MOV	RESULT1, C				;condicion 1 se cumplio ?
	MOV	A, 	R3
	CJNE	A, Y, B70
	SETB	RESULT2
	SJMP	B60
B70:
	CLR	RESULT2
B60:
	MOV	C, 	RESULT2
	ANL	C, 	UP				;y==Pmax AND  Up=1  ??
	MOV	RESULT2, C				;condicion 2 se cumplio ?
	MOV	C, 	RESULT1
	ORL	C, 	RESULT2
	JC	A50						;si las dos condiciones se cumplen, pego en la esquina de la paleta
	CALL	REBOTE_PALETA			;si no pego en plano
	SJMP	A60
A50:
	CALL	REBOTE_ESQUINA
A60:
	;RET			;REGRESO
	JMP	ACTION
;----------------------------------------------------------------------------
;--------------------------------------
Rebote_Esquina:
	JBC	UR, 	UR_11
	JBC	UL, 	UL_11
	JBC	DR, 	DR_11
	JBC	DL, 	DL_11	; again, don't try to be too smart, just include this line, intead "falling" to the next part
;----------------------------------------------------------------------------
DL_11:
	CLR	DL
	SETB	UR
	RET
;----------------------------------------------------------------------------
UR_11:
	SETB	DL
	RET
;----------------------------------------------------------------------------
UL_11:
	SETB	DR
	RET
;----------------------------------------------------------------------------
DR_11:
	SETB	UL
	RET
;--------------------------------------
Rebote_Paleta:
	JBC	UR, 	UR_12
	JBC	UL, 	UL_12
	JBC	DR, 	DR_12
	JBC	DL,	DL_12		; again, don't try to be too smart, just include this line, intead "falling" to the next part
;----------------------------------------------------------------------------
DL_12:
	CLR	DL	; why only this one gets cleared? seems like a bug?
	SETB	DR
	RET
;----------------------------------------------------------------------------
UR_12:
	SETB	UL
	RET
;----------------------------------------------------------------------------
UL_12:
	SETB	UR
	RET
;----------------------------------------------------------------------------
DR_12:
	SETB	DL
	RET
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
;----------------------------------------------------------------------------
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
;----------------------------------------------------------------------------
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
;----------------------------------------------------------------------------
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

;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

	ORG	800H
LUT_BALL:
	DB	0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H, 1H, 0H, 0H, 0H, 0H, 0H, 0H, 0H

	ORG	81EH
LUT_BALL2:
	DB	0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H
	;Uso esta tabla para mostrar la bola en la matriz

	ORG	900H
LUT_PAD:
	DB	0H, 0F0H, 78H, 3CH, 1EH, 0FH, 7H, 3H, 1H, 0H, 0H, 0H, 0H

	ORG 	91EH
LUT_PAD2:
	DB 	0H, 0H, 0H, 0H, 0H, 0H, 80H, 0C0H, 0E0H, 0F0H, 78H, 3CH, 1EH

FIN:
	END