;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display
TAM_X	EQU	15
TAM_Y	EQU	16

PORT_A	EQU	02000H		;Direccion del puerto A en RAM Externa
PORT_B	EQU	02001H		;Para referenciar se usa MOVX
PORT_C	EQU	02002H
Reg_Control	EQU	02003H	;Recibe palabra de control

POS_PAD1	EQU	0H	;position dela tableta en la pantalla
POS_PAD2	EQU	0EH
Y_T	DATA	1EH		;	variable temporal y
P_T	DATA	1FH		;	Variable temporal de paleta
PAD1	DATA	20H		;	;Variables de posicion de objetos
PAD2	DATA	21H		;
X	DATA	22H		;	OFFSET	para la MemoriaVIDEO
Y	DATA	23H		;     OFFSET	para la LUT_BALL




MemoriaViDEO	EQU	40H
MemoriaVIDEO2	EQU	50H

MemoriaViDEOA	EQU	41H
MemoriaVIDEO2A	EQU	51H




ADRE_PAD1A	EQU	40H
ADRE_PAD1B	EQU	50H

ADRE_PAD2A	EQu	4EH
ADRE_PAD2B	EQu	5EH


SW	EQU	P1
UP_1	EQU	P1.0
DOWN_1	EQU	P1.1
UP_2	EQU	P1.2
DOWN_2	EQU	P1.3





UR	EQU	48H		; RAM 29 Indican la direccion de la bola, SOLAMENTE puede estar uno 	00000001
UL	EQU	49H		;	00000010
DR	EQU	4AH		;pg 181								00000100
DL	EQU	4BH		;	00001000
UP	EQU	4CH		;	00010000
DOWN	EQU	4DH		;	00100000

A_O	DATA	30H		;Almacenamiento temporal para los operandos de la or de alto nivel
B_O	DATA	31H
C_O	DATA	32H		;Elemento a comparar

O1	EQU	50H		;Direccion 2A, del bit 0			00000001
O2	EQU	51H		;	00000010
Result1	EQU	52H		;resultado logico donde se guarda		00000100
Result2	EQU	53H		;	00001000

	ORG	0

	SJMP	START

	ORG	30H		;Comienzo el programa saltando 
	;los vectores
START:

;Seccion de INICIALIZACION

GRAFICO2:
	MOV	DPTR,#D
	CALL	WRITE_VIDEO_MEMORY11
		mov R1,#08H
Pause1a1: 	mov R2,#08H
Pause2a1:
	
	CALL	WRITE_TO_PPI  
	
	djnz R2,PAUSE2a1
	djnz R1,PAUSE1a1 

	CALL	DELAY_0_2

CALL	WRITE_VIDEO_MEMORY
		mov R1,#08H
Pause1a1: 	mov R2,#08H
Pause2a1:
	
	CALL	WRITE_TO_PPI  
	
	djnz R2,PAUSE2a1
	djnz R1,PAUSE1a1 

	JMP	GRAFICO2

	MOV	SP, #5FH
	MOV	A, #080H	; Esta palabara de control define A,B,C=outputs
	MOV	DPTR, #REG_CONTROL	;Cargo direccion del registro de control
	MOVX	@DPTR, A	;Programo el PPI
	MOV	PAD1, #7	;Inicializo la posicion de las paletas
	MOV	PAD2, #8	;maxima posicion es 12
	MOV	X, #7
	MOV	Y, #7
	
	SETB	UL

;TOMA DE DECICIONES LEYENDO P1
READ_PUERTO:

	MOV	A, SW		; Read input port
	;CALL    delay_0_2	;lee el switch cada 0.2 segundos
	ANL	A, #00FH	;
	MOV	R7, A		; Make copy in R7 for comparisons


	CALL	CLEAR_VIDEO_MEMORY


;---------------------------------------------------------------LOGICA DE LAS TABLETAS-----------------------------
;Logica para  SUBE O BAJA PAD
PAD1_UP_DOWN:

	JB	UP_1, D1
	JNB	DOWN_1, PAD2_UP_DOWN
	CALL	DW1
D1:	JB	DOWN_1, PAD2_UP_DOWN
	CALL	UP1

PAD2_UP_DOWN:

	JB	UP_2, D2
	JNB	DOWN_2, BALL_LOGIC
	CALL	DW2
D2:	JB	DOWN_2, BALL_LOGIC
	CALL	UP2
;---------------------------------------------------------INICIA LOGICA de la bola-------------------------------------------------

BALL_LOGIC:

	MOV	A_O, #0		;X=0 OR X=14     ALGUIEN PERDIO?????
	MOV	B_O, #14
	MOV	C_O, X
	CALL	OR_2
	JB	RESULT1, LOST

	MOV	A_O, #1		;X=1 OR X=14    LA bola esta en zona de paleta?????
	MOV	B_O, #13
	MOV	C_O, X
	CALL	OR_2
	JB	RESULT1, ZONA_PALETA

	MOV	A_O, #1		;y=0 OR y=14	LA bola esta en una pared???????????
	MOV	B_O, #15
	MOV	C_O, Y
	CALL	OR_2
	JB	RESULT1, CHOQUE_PARED


	;La bola sigue su curso--------------
IGUAL:

ACTION:
	JB	UR, AUR_1
	JB	UL, AUL_1
	JB	DR, ADR_1
ADL_1:	CALL	DWN_LEFT
	SJMP	GRAFICO
AUR_1:	CALL	UP_RIGHT
	SJMP	GRAFICO
AUL_1:	CALL	UP_LEFT
	SJMP	GRAFICO
ADR_1:	CALL	DWN_RIGHT
;---------------------------------------------------------Paso a graficar-------------------

GRAFICO:	
	CALL	WRITE_VIDEO_MEMORY
		mov R1,#08H
Pause1a: 	mov R2,#08H
Pause2a:
	
	CALL	WRITE_TO_PPI  
	
	djnz R2,PAUSE2a
	djnz R1,PAUSE1a 

	;CALL	DELAY_0_2
	
	JMP	READ_PUERTO
;--------------------------------------------------------------------------------------------
;-------------------------------------------------Ramas de la logica-------------------------
Lost:
	JMP	START

CHOQUE_PARED:
	CALL	REBOTE_PARED
	JMP	ACTION

ZONA_PALETA:
	CALL	REBOTARA_PALETA
	JMP	ACTION

;*****************************************************************************************************************

REBOTARA_PALETA:		;la logica mas compleja es la de la bola
	MOV	R2, X
	CJNE	R2, #1, PALETA_2	;cual es la paleta en cuestion
	MOV	P_T, PAD1
	SJMP	A70
PALETA_2:
	MOV	P_T, PAD2
A70:

	MOV	A, P_T
	SUBB	A, #1
	MOV	R2, A		;R2 es mi P_minimo
	MOV	A_O, R2
	ADD	A, #5
	MOV	R3, A		;R3 es mi P_maximo
	MOV	B_O, R3
	MOV	C_O, Y
	CALL	ESTA_RANGO
	JNB	RESULT2, A60	;si no esta en el rango, continuo sin rebotar

	MOV	A_O, #1
	MOV	B_O, #15
	;MOV	C_O, Y				;no es necesario
	CALL	OR_2
	JB	RESULT1, A50	;es un caso especial?? Si, entonces rebote en la esquina

	MOV	C, DL
	ORL	C, DR
	MOV	DOWN, C		;la bola baja o	BIT	00100000			29H
	MOV	C, UL
	ORL	C, UR
	MOV	UP, C		;o sube			BIT 00010000		29H

	MOV	A, R2
	CJNE	A, Y, B90
	SETB	RESULT1
	SJMP	B80
B90:	CLR	RESULT1
B80:	MOV	C, RESULT1
	ANL	C, DOWN		; y==Pmin AND  DOWN=1  ??
	MOV	RESULT1, C	;condicion 1 se cumplio ?

	MOV	A, R3
	CJNE	A, Y, B70
	SETB	RESULT2
	SJMP	B60
B70:	CLR	RESULT2
B60:	MOV	C, RESULT2
	ANL	C, UP		;y==Pmax AND  Up=1  ??
	MOV	RESULT2, C	;condicion 2 se cumplio ?

	MOV	C, RESULT1
	ORL	C, RESULT2

	JC	A50		;si las dos condiciones se cumplen, pego en la esquina de la paleta
	CALL	REBOTE_PALETA	;si no pego en plano
	SJMP	A60

A50:	CALL	REBOTE_ESQUINA
A60:
	RET

	;REGRESO



;***********************************************************************************


WRITE_VIDEO_MEMORY:

	PUSH	0
	PUSH	1
	PUSH	2
	PUSH	3
	PUSH	ACC
	PUSH	82H		;DPL
	PUSH	83H		;PDH

	MOV	DPTR, #LUT_PAD
	MOV	A, PAD1		;USO A como OFFSET qu
	MOVC	A, @A+DPTR	;Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV	ADRE_PAD1A, A

	
	MOV	A, PAD2		;USO A como OFFSET qu
	MOVC	A, @A+DPTR	;Copio lo que esta en el LUT, y A proporciona el OFFSET
	MOV	ADRE_PAD2A, A

	MOV	DPTR, #LUT_PAD2
	MOV	A, PAD1		;use el mismo offset
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD1B, A

	MOV	A, PAD2		;use el mismo offset
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD2B, A

	

	MOV	DPTR, #LUT_BALL
	MOV	A, Y
	MOVC	A, @A+DPTR
	MOV	R2, A			;temporalmente lo guardo en R2
	MOV	DPTR, #LUT_BALL2
	MOV	A, Y
	MOVC	A, @A+DPTR
	MOV	R3, A			;temporalmente lo guardo en R2


	MOV	R0, #MEMORIAVIDEO		;uso R0 como indice
	MOV	R1, #MEMORIAVIDEO2

	MOV	A, X
	ADD	A, R0			;le pongo a R0 el offset de X
	MOV	R0, A

	MOV	A, X
	ADD	A, R1			;le pongo a R0 el offset de X
	MOV	R1, A

	MOV	A, R2
	MOV	@R0, A

	MOV	A, R3
	MOV	@R1, A


	POP	83H
	POP	82H
	POP	ACC
	POP	3
	POP	2
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

	MOV	R2, #0FH
	MOV	R0,#MEMORIAVIDEO
	MOV	R1,#MEMORIAVIDEO2

AA90:	
	CALL 	CLEAR_PPI
	MOV	DPTR, #PORT_C		;mando el valor de la columna
	MOV	A,R2
	MOVX	@DPTR, A	

	MOV	A, @R0	
	MOV	DPTR, #PORT_A		;Programo el PPI
	MOVX	@DPTR, A	

	INC DPTR			;apunto a PUERT B
	INC R0

	MOV	A, @R1	
	MOVX	@DPTR, A
	INC	R1

	

	DJNZ	R2,AA90

	POP	83H
	POP	82H
	POP	2
	POP	1
	POP	0
	POP	ACC
	RET

CLEAR_PPI:
	PUSH	82H
	PUSH	83H
	PUSH	ACC
	
	MOV	DPTR, #PORT_A
	CLR	A
	MOVX	@DPTR, A
	INC	DPTR		;APUTNA A PUERTO B
	MOVX	@DPTR, A
	


	POP	ACC
	POP	83H
	POP 	82H
	RET

;------------------------------------Movimientos de la tableta
UP1:
	MOV	R2, PAD1
	CJNE	R2, #1, U90
	SJMP	U100		;TODO Logica de validacion que el pad no este en el limite
U90:	DEC	PAD1
U100:	RET

DW1:
	MOV	R2, PAD1
	CJNE	R2, #12, U70
	SJMP	U80
U70:	INC	PAD1
U80:	RET

UP2:
	MOV	R2, PAD2
	CJNE	R2, #1, U50
	SJMP	U60
U50:	DEC	PAD2
U60:	RET

DW2:
	MOV	R2, PAD2
	CJNE	R2, #12, U30
	SJMP	U40
U30:	INC	PAD2
U40:	RET

;---------------------------------Movimientos de la bola-------------------------------------------
UP_RIGHT:
	INC	X		;Lo incremento para ir a la derecha
	DEC	Y		;Lo decremento para  SUBIR
	RET
UP_LEFT:
	DEC	X
	DEC	Y
	RET
DWN_RIGHT:
	INC	X
	INC	Y
	RET
DWN_LEFT:
	DEC	X
	INC	Y
	RET
;------------------------------------Rebotes de la bola------------------------------------------
;********************************************************
Rebote_Pared:
	JBC	UR, UR_1
	JBC	UL, UL_1
	JBC	DR, DR_1
DL_1:	CLR	DL
	SETB	UL
	JMP	Back1
UR_1:
	SETB	DR
	JMP	Back1
UL_1:
	SETB	DL
	JMP	Back1
DR_1:
	SETB	UR
	JMP	Back1
BACK1:
	RET
;****************************************************
Rebote_Esquina:
	JBC	UR, UR_11
	JBC	UL, UL_11
	JBC	DR, DR_11
DL_11:	CLR	DL
	SETB	UR
	JMP	Back11
UR_11:
	SETB	DL
	JMP	Back11
UL_11:
	SETB	DR
	JMP	Back11
DR_11:
	SETB	UL
	JMP	Back11
BACK11:
	RET
;********************************************************
Rebote_Paleta:
	JBC	UR, UR_12
	JBC	UL, UL_12
	JBC	DR, DR_12
DL_12:	CLR	DL
	SETB	DR
	JMP	Back12
UR_12:
	SETB	UL
	JMP	Back12
UL_12:
	SETB	UR
	JMP	Back12
DR_12:
	SETB	DL
	JMP	Back12
BACK12:
	RET
;*************************************************************************

CHOQUE_CON_PALETA:



;--------------------------------------RUTINAS DE LOGICA-----------------------------------------------

OR_2:

;Empiezo la logica de OR
	PUSH	ACC
	CLR	O1		;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT1
	MOV	A, C_O
	CJNE	A, A_O, seg_operando
	SETB	O1
seg_operando:
	CJNE	A, B_O, OPERACION_OR	; tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIREECCION
	SETB	O2
Operacion_OR:
	MOV	C, O1
	ORL	C, O2
	MOV	RESULT1, C
	POP	ACC
	RET

AND_2:

;Empiezo la logica de AND

	PUSH	ACC
	CLR	O1		;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT2
	MOV	A, C_O
	CJNE	A, A_O, seg_operando2
	SETB	O1
seg_operando2:
	CJNE	A, B_O, OPERACION_AND	; tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIREECCION
	SETB	O2
Operacion_AND:
	MOV	C, O1
	ANL	C, O2
	MOV	RESULT2, C
	POP	ACC
	RET


ESTA_RANGO:
	PUSH	ACC

			;Funcion logica    para saber si un numero esta en un rango 		1 < X  < 3 
	CLR	O1		;Limpio los bits del resultado anterior
	CLR	O2
	CLR	RESULT2
	MOV	A, C_O

	CJNE	A, A_O, NOT_EQUAL
	SETB	O1
	SJMP	NEXT		;EQUAL A_O = C_O
NOT_EQUAL:
	JC	NEXT		;jump if C_O < A_0
	SETB	O1		;  C_o > A_O
NEXT:

	CJNE	A, B_O, NOT_EQUAL2
	SETB	O2		;EQUAL	B_0 = C_O
	SJMP	A80
NOT_EQUAL2:
	JNC	A80		;jump if C_O  > A_O
	SETB	O2
A80:	MOV	C, O1
	ANL	C, O2
	MOV	RESULT2, C

	POP	ACC
	RET

Delay_0_2:

PUSH	0
PUSH	1
PUSH	2

MOV	R2, #002h
	MOV	R1, #0F5h
	MOV	R0, #042h
	NOP
	DJNZ	R0, $
	DJNZ	R1, $-5
	DJNZ	R2, $-9
	MOV	R0, #009h
	DJNZ	R0, $
	NOP

	POP	2
	POP	1
	POP	0
RET

CLEAR_VIDEO_MEMORY:
	PUSH	0
	PUSH	1

	MOV	R1, #30
	MOV	R0, #MEMORIAVIDEO
BORRAR:	MOV	@R0, #0
	INC	R0
	DJNZ	R1, BORRAR

	POP	1
	POP	0
	RET


WRITE_VIDEO_MEMORY11:
	PUSH	ACC
	PUSH	82H
	PUSh	83H
	PUSH	0
	PUSH	4

	CLR	A
	;MOV	DPTR,#Letra_a1
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_A
Z100:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z100

	POP	4
	POP	0
	POP	83H
	POP	82H
	POP	ACC

	RET
WRITE_VIDEO_MEMORY22:
	PUSH	ACC
	PUSH	82H
	PUSh	83H
	PUSH	0
	PUSH	4
CLR	A
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_b
Z1011:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z1011

	POP	4
	POP	0
	POP	83H
	POP	82H
	POP	ACC

	RET
;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

	ORG	800H
LUT_BALL:	DB	0H,  80H,  40H, 20H,  10H,  8H,  4H,  2H,  1H,  0H,  0H,  0H,  0H,  0H,  0H,  0H

	ORG	81EH
LUT_BALL2:	DB	0H, 0H,    0H,  0H,  0H,    0H,  0H,  0H,  0H, 80H,  40H, 20H,  10H,  8H,  4H,  2H  
	;Uso esta tabla para mostrar la bola en la matriz
	ORG	900H
LUT_PAD:	DB	0H,  0F0H,  78H,  3CH,  1EH,  0FH,  7H,  3H,  1H,  0H,  0H,  0H,  0H
	ORG 	91EH
LUT_PAD2: DB 	0H, 0H, 0H, 0H, 0H, 0H, 80H, 0C0H, 0E0H, 0F0H, 78H,  3CH, 1EH

	ORG	930H
dibujo1a: DB	0H, 0h, 0h, 0EH, 2H, 72H, 7FH, 72H, 2H, 0EH, 0H, 0H, 0H, 0H, 0H	

	ORG	960H
dibujo1b: DB	0h, 0H, 0H, 08H, 10H, 20H, 0C0H, 20H, 10H, 8H, 0H, 0H, 0H, 0H, 0H

ORG	980H
dibujo2a: DB	0H, 0h, 1h, 02H, 2H, 72H, 7FH, 72H, 2H, 02H, 01H, 0H, 0H, 0H, 0H	

	ORG	1000H
dibujo2b: DB	0h, 08H, 0H, 0H, 4H, 3CH, 0C0H, 3CH, 4H, 0H, 0H, 80H, 0H, 0H, 0H
FIN:
	END








