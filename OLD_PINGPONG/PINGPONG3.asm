;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 3, voy a usar una porcion de la ram como memoria de VIDEO
TAM_X		EQU	15
TAM_Y		EQU	15

PORT_A		EQU	02000H	;Direccion del puerto A en RAM Externa
PORT_B		EQU	02001H	;Para referenciar se usa MOVX
PORT_C		EQU	02002H	
Reg_Control	EQU	02003H	;Recibe palabra de control

POS_PAD1	EQU	0H
POS_PAD2 EQU	0EH


PAD1		DATA	20H;	;Variables de posicion de objetos
PAD2		DATA	21H;
BALL_X		DATA	22H;	OFFSET	para la MemoriaVIDEO
BALL_Y		DATA	23H;     OFFSET	para la LUT_BALL
COL		DATA	24H;		COLUMNA

MemoriaViDEO	EQU	40H
ADRE_PAD1A	EQU	40H
ADRE_PAD2A	EQu	5CH

ADRE_PAD1B	EQU	41H
ADRE_PAD2B	EQu	5DH


SW		EQU	P1
	
UR		EQU	48H	;Indican la direccion de la bola, SOLAMENTE puede estar uno encendido
UL		EQU	49H
DR		EQU	4AH
DL		EQU	4BH
UP		EQU	4CH
DOWN		EQU	4DH

A_O	DATA	30H		;Almacenamiento temporal para los operandos de la or de alto nivel
B_O	DATA	31H
C_O	DATA	32H		;Elemento a comparar

O1	EQU	50H		;Direccion 2A, del bit 0
O2	EQU	51H
Result1	EQU	52H		;resultado logico donde se guarda
Result2	EQU	53H

ORG 		0

SJMP START

ORG 		30H		;Comienzo el programa saltando 
				;los vectores
START:

;Seccion de INICIALIZACION

		MOV	A, 	#080H	; Esta palabara de control define A,B,C=outputs
		MOV	DPTR,	#REG_CONTROL	;Cargo direccion del registro de control
		MOVX	@DPTR,	A		;Programo el PPI
		MOV	PAD1,  #6		;Inicializo la posicion de las paletas
		MOV	PAD2,  #6
		MOV	BALL_X,#8
		MOV	BALL_Y,#7
		MOV	COL, #0			;Inicializo en columna o
	
		
;TOMA DE DECICIONES LEYENDO P1
READ_PUERTO:
	MOV DPL,#LOW(TABLA_SALTO)  			; set start of jump table
        MOV DPH,#HIGH(TABLA_SALTO)
        MOV A,SW  					; Read input port
        ANL A,#00FH   ; Confine to 16 choices
        MOV R7,A      ; Make copy in R7 for comparisons
        MOV B,#3
        MUL AB          ; multiply by two since each AJMP is two bytes
        JMP @A+DPTR

TABLA_SALTO:
        JMP LEER				;UNAS COMBINACIONES SE REPITEN
        JMP UP1
        JMP DW1
        JMP LEER
        JMP UP2
        JMP UP2_UP1
        JMP UP2_DW1
        JMP UP2
        JMP DW2
        JMP DW2_UP1
        JMP DW2_DW1
        JMP DW2
        JMP LEER
        JMP UP1
        JMP DW1
        JMP LEER
UP1:					;TODO Logica de validacion que el pad no este en el limite
	

	DEC	PAD1
	CALL	WRITE_VIDEO_MEMORY
	
DW1:
	
	INC	PAD1
	JMP 	DW1
UP2:
	DEC	PAD2
	JMP 	up2
DW2:
	INC	PAD2
	JMP 	DW2
UP2_UP1:
	DEC 	PAD2
	DEC 	PAD1
	JMP 	UP2_UP1
UP2_DW1:
	DEC 	PAD2
	INC	PAD1
	JMP 	UP2_DW1
DW2_UP1:	
	INC	PAD2
	DEC	PAD1
	JMP 	DW2_UP1
DW2_DW1:
	INC	PAD2
	INC	PAD2
	JMP 	DW2_DW1

LEER:
	JMP READ_PUERTO




WRITE_VIDEO_MEMORY:
	MOV DPTR, #LUT_PAD
	MOV	A,PAD1					;USO A como OFFSET qu
	RL	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD1A,A
	MOV	A,PAD1					;copio en A, el valor de la tabla
	RL	A
	INC 	A
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD1B,A

	MOV DPTR, #LUT_PAD
	MOV	A,PAD2					;USO A como OFFSET qu
	RL	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD2A,A
	MOV	A,PAD2					;copio en A, el valor de la tabla
	RL	A
	INC 	A
	MOVC	A, @A+DPTR
	MOV	ADRE_PAD2B,A

	MOV DPTR, #LUT_BALL
	MOV	A,BALL_Y
	RL	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR
	MOV	R2,A
	MOV	R0, #MEMORIAVIDEO
	MOV	A,BALL_X
	RL	A
	ADD	A,R0
	MOV	R0,A
	MOV	A,R2
	MOV	@R0,A
	
	MOV DPTR, #LUT_BALL
	MOV	A,BALL_Y
	RL	A
	INC	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR
	MOV	R2,A
	MOV	R0, #MEMORIAVIDEO
	MOV	A,BALL_X
	RL	A
	INC	A
	ADD	A,R0
	MOV	R0,A
	MOV	A,R2
	MOV	@R0,A
	
	RET

;---------------------------------Movimientos de la bola-------------------------------------------
UP_RIGHT:
	INC	BALL_X					;Lo incremento para ir a la derecha
	DEC	BALL_Y					;Lo decremento para  SUBIR
	RET

UP_LEFT:
	DEC	BALL_X
	DEC	BALL_Y
	RET
DWN_RIGHT:
	INC	BALL_X
	INC	BALL_Y
	RET
DWN_LEFT:
	DEC	BALL_X
	INC	BALL_Y
	RET
;------------------------------------Rebotes de la bola

Rebote_Pared:
JBC UR, UR_1
JBC UL, UL_1
JBC DR, DR_1
DL_1:
	SETB UL
	JMP Back1
UR_1:
	SETB DR 
	JMP Back1
UL_1:
	SETB DL 
	JMP Back1
DR_1:
	SETB UR 
	JMP Back1
BACK1:
RET

Rebote_Esquina:
JBC UR, UR_11
JBC UL, UL_11
JBC DR, DR_11
DL_11:
	SETB UR
	JMP Back11
UR_11:
	SETB DL 
	JMP Back11
UL_11:
	SETB DR 
	JMP Back11
DR_11:
	SETB UL 
	JMP Back11
BACK11:
RET

Rebote_Paleta:
JBC UR, UR_12
JBC UL, UL_12
JBC DR, DR_12
DL_12:
	SETB DR
	JMP Back12
UR_12:
	SETB UL 
	JMP Back12
UL_12:
	SETB UR 
	JMP Back12
DR_12:
	SETB DL 
	JMP Back12
BACK12:
RET


;--------------------------------------RUTINAS DE LOGICA-----------------------------------------------

OR_2:

;Empiezo la logica de OR
CLR	O1				;Limpio los bits del resultado anterior
CLR	O2
CLR	RESULT1
MOV	A, C_O
CJNE	A,A_O, seg_operando
SETB	O1
seg_operando:
CJNE	A,B_O, OPERACION_OR	; tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIREECCION
SETB	O2
Operacion_OR:
MOV	C, O1
ORL	C,O2
MOV	RESULT1,C
RET		

AND_2:

;Empiezo la logica de OR
CLR	O1				;Limpio los bits del resultado anterior
CLR	O2
CLR	RESULT2
MOV	A, C_O
CJNE	A,A_O, seg_operando2
SETB	O1
seg_operando2:
CJNE	A,B_O, OPERACION_AND	; tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIREECCION
SETB	O2
Operacion_AND:
MOV	C, O1
ANL	C,O2
MOV	RESULT2,C
RET

;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

ORG		800H
LUT_BALL: DB	    80H,0H,40H,0H,20H,0H,10H,0H,8H,0H,4H,0H,2H,0H,1H,0H,0H,80H,0H,40H,0H,20H,0H,10H,0H,8H,0H,4H,0H,2H
				;Uso esta tabla para mostrar la bola en la matriz
ORG		900H
LUT_PAD:	DB	0F0H,0H,78H,0H,3CH,0H,1EH,0H,0FH,0H,7H,80H,3H,0C0H,1H,0E0H,0H,0F0H,0H,78H,0H,3CH,0H,1EH
		
		
										

END


