INCLUDE graphfunctions.asm
INCLUDE logicfunctions.asm

PAD_M MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	MOV	R2, PAD_A
	CJNE R2, #LIMIT, xyz
	SJMP zyx						;TODO Logica de validacion que el pad no este en el limite
xyz:
	DEC PAD_A
zyx:
	;RET
ENDM

PAD_P MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	MOV	R2, PAD_A
	CJNE R2, #LIMIT, xyz
	SJMP zyx						;TODO Logica de validacion que el pad no este en el limite
xyz:
	INC	PAD_A
zyx:
	;RET
ENDM


;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display
PAD_SIZE EQU 4
TAM_X EQU	15
TAM_Y EQU	16
LEFT_BORDER EQU 0
RIGHT_BORDER EQU TAM_X -1

LEFT_PAD_ZONE EQU 1
RIGHT_PAD_ZONE EQU TAM_X -2

UP_WALL_ZONE EQU 1
DN_WALL_ZONE EQU TAM_Y - 1

PAD_UP_LIMIT EQU UP_WALL_ZONE
PAD_DN_LIMIT EQU TAM_Y - PAD_SIZE

; PPI Ports addresses
PORT_A EQU	02000H			; Direccion del puerto A en RAM Externa
PORT_B EQU	02001H			; Para referenciar se usa MOVX
PORT_C EQU	02002H
Reg_Control EQU	02003H			; Recibe palabra de control

;;POS_PAD1	EQU	0H				; position dela tableta en la pantalla
;;POS_PAD2	EQU	0EH
;;Y_T	DATA	1EH			;variable temporal y
P_T	DATA 1FH			;Variable temporal de paleta
PAD1 DATA 20H			;Variables de posicion de objetos
PAD2 DATA 21H			;
X DATA 22H			;OFFSET	para la MemoriaVIDEO
Y DATA 23H			;OFFSET	para la LUT_BALL

A_O DATA 30H			; Almacenamiento temporal para los operandos de la or de alto nivel
B_O DATA 31H
C_O DATA 32H			; Elemento a comparar

MemoriaViDEO EQU 40H
MemoriaVIDEO2 EQU 50H

MemoriaViDEOA EQU 41H
MemoriaVIDEO2A EQU 51H

ADRE_PAD1A EQU 40H
ADRE_PAD1B EQU 50H

ADRE_PAD2A EQU 4EH
ADRE_PAD2B EQU 5EH

SW EQU P1
UP_1 EQU P1.0
DOWN_1 EQU P1.1
UP_2 EQU P1.2
DOWN_2 EQU P1.3

UR EQU 48H				; 00000001 RAM 29 Indican la direccion de la bola, SOLAMENTE puede estar uno
UL EQU 49H				; 00000010
DR EQU 4AH				; 00000100 pg 181
DL EQU 4BH				; 00001000
UP EQU 4CH				; 00010000
DOWN EQU 4DH				; 00100000

O1 EQU 50H				;Direccion 2A, del bit 0			00000001
O2 EQU 51H				;	00000010
Result1 EQU 52H				;resultado logico donde se guarda		00000100
Result2 EQU 53H				;	00001000

	ORG 0
	SJMP START
	ORG 30H		;Comienzo el programa saltando los vectores
START:

;--------------------------------------Seccion de INICIALIZACION
	MOV	SP, #5FH
	MOV	A, #080H			; Esta palabara de control define A,B,C=outputs
	MOV	DPTR, #REG_CONTROL	; Cargo direccion del registro de control
	MOVX @DPTR, A				; Programo el PPI
	MOV	PAD1, #7				; Inicializo la posicion de las paletas ; LEFT PAD
	MOV	PAD2, #8				; maxima posicion es 12			; RIGHT PAD
	MOV	X, #7
	MOV	Y, #7
	SETB UL
;--------------------------------------TOMA DE DECICIONES LEYENDO P1
READ_PUERTO:
	MOV A, SW				; Read input port
	;CALL    delay_0_2		; lee el switch cada 0.2 segundos
	ANL A, #0FH ; Apply Mask 00001111
	MOV R7, A	; Make copy in R7 for comparisons
	;CALL	CLEAR_VIDEO_MEMORY
;--------------------------------------LOGICA DE LAS TABLETAS-----------------------------
;Logica para  SUBE O BAJA PAD
PAD1_UP_DOWN:
	JB UP_1, D1    ;UP_1 is the P1.0
	JNB DOWN_1, PAD2_UP_DOWN
	PAD_P PAD1, PAD_DN_LIMIT
D1:
	JB DOWN_1, PAD2_UP_DOWN
	PAD_M PAD1, PAD_UP_LIMIT

PAD2_UP_DOWN:
	JB UP_2, D2
	JNB DOWN_2, BALL_LOGIC
	PAD_P PAD2, PAD_DN_LIMIT
D2:
	JB DOWN_2, BALL_LOGIC
	PAD_M PAD2, PAD_UP_LIMIT
;--------------------------------------INICIA LOGICA de la bola-------------------------------------------------
BALL_LOGIC:
	MOV A, X				; DEBUG: Save X value
	MOV P3, A				; DEBUG: Print in port 3

	OR_MACRO LEFT_BORDER, RIGHT_BORDER, X    ;X=0 OR X=14     ALGUIEN PERDIO?????
	JB RESULT1, LOST

	OR_MACRO LEFT_PAD_ZONE, RIGHT_PAD_ZONE, X    ;X=1 OR X=13    LA bola esta en zona de paleta?????
	JB RESULT1, ZONA_PALETA

	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y    ;y=1 OR y=15	LA bola esta en una pared???????????
	JB RESULT1, CHOQUE_PARED
	;La bola sigue su curso--------------
IGUAL:

ACTION:
	; equivalent to a switch case where only at a time bit can be set UR, UL, DR, DL
	JB UR, AUR_1
	JB UL, AUL_1
	JB DR, ADR_1
	JB DL, ADL_1	; trying to be smart, you just create unreadable code, this line could be commented out, but makes more sense
ADL_1:
	DEC X
	INC Y
	;JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	JMP GRAFICO
AUR_1:
	INC X						;Lo incremento para ir a la derecha
	DEC Y						;Lo decremento para  SUBIR
	;JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	JMP GRAFICO
AUL_1:
	DEC X
	DEC Y
	;JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	JMP GRAFICO
ADR_1:
	INC X
	INC Y
	;JMP	READ_PUERTO ; SKIP GRAPH LOGIC
	JMP GRAFICO ; again, don't try to be too smart, just include this line for clarity

;--------------------------------------Ramas de la logica-------------------------
LOST:
	JMP START
CHOQUE_PARED:
	JBC UR, UR_1
	JBC UL, UL_1
	JBC DR, DR_1	; again, don't try to be too smart, just include this line, intead "falling" to the next part
	JBC DL, DL_1
DL_1:
	CLR DL
	SETB UL
	JMP ACTION
UR_1:
	SETB DR
	JMP ACTION
UL_1:
	SETB DL
	JMP ACTION
DR_1:
	SETB UR
	JMP ACTION

ZONA_PALETA:
	;la logica mas compleja es la de la bola
	MOV R2, X
	CJNE R2, #LEFT_PAD_ZONE, PALETA_2	;cual es la paleta en cuestion
	MOV P_T, PAD1
	SJMP A70
PALETA_2:
	MOV P_T, PAD2
A70:
	;-------------
	MOV A, P_T
	SUBB A, #1
	MOV R2, A				;R2 es mi P_minimo
	MOV A_O, R2
	; A_0 = P_T -1
	ADD A, #5
	MOV R3, A				;R3 es mi P_maximo
	MOV B_O, R3
	; B_0 = A_0 + 5
	MOV C_O, Y
	CALL ESTA_RANGO
	JNB RESULT2, ACTION			;si no esta en el rango, continuo sin rebotar
	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	JB RESULT1, A50			;es un caso especial?? Si, entonces rebote en la esquina
	MOV C, DL
	ORL C, DR
	MOV DOWN, C				;la bola baja o	BIT	00100000			29H
	MOV C, UL
	ORL C, UR
	MOV UP, C				;o sube			BIT 00010000		29H
	MOV A, R2
	CJNE A, Y, B90
	SETB RESULT1
	SJMP B80
B90:
	CLR RESULT1
B80:
	MOV C, RESULT1
	ANL C, DOWN			; y==Pmin AND  DOWN=1  ??
	MOV RESULT1, C				;condicion 1 se cumplio ?
	MOV A, R3
	CJNE A, Y, B70
	SETB RESULT2
	SJMP B60
B70:
	CLR RESULT2
B60:
	MOV C, RESULT2
	ANL C, UP				;y==Pmax AND  Up=1  ??
	MOV RESULT2, C				;condicion 2 se cumplio ?
	MOV C, RESULT1
	ORL C, RESULT2
	JC A50						;si las dos condiciones se cumplen, pego en la esquina de la paleta
	JMP REBOTE_PALETA			;si no pego en plano
A50:
	JMP REBOTE_ESQUINA

REBOTE_ESQUINA:
	JBC UR, UR_11
	JBC UL, UL_11
	JBC DR, DR_11
	JBC DL, DL_11	; again, don't try to be too smart, just include this line, intead "falling" to the next part
DL_11:
	CLR DL
	SETB UR
	JMP ACTION
UR_11:
	SETB DL
	JMP ACTION
UL_11:
	SETB DR
	JMP ACTION
DR_11:
	SETB UL
	JMP ACTION

REBOTE_PALETA:
	JBC UR, UR_12
	JBC UL, UL_12
	JBC DR, DR_12
	JBC DL, DL_12		; again, don't try to be too smart, just include this line, intead "falling" to the next part
DL_12:
	CLR DL	; why only this one gets cleared? seems like a bug?
	SETB DR
	JMP ACTION
UR_12:
	SETB UL
	JMP ACTION
UL_12:
	SETB UR
	JMP ACTION
DR_12:
	SETB DL
	JMP ACTION

;--------------------------------------Paso a graficar-------------------
GRAFICO:
    CALL CLEAR_VIDEO_MEMORY
	; This is a 8 x 8 loop, of just display
	CALL WRITE_VIDEO_MEMORY
	MOV R1, #04H
Pause1a:
	MOV R2, #04H
Pause2a:
	CALL WRITE_TO_PPI
	DJNZ R2, PAUSE2a
	DJNZ R1, PAUSE1a
	;CALL	DELAY_0_2
	JMP READ_PUERTO    ; This complete the game loop
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------

;----------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

	ORG 800H
LUT_BALL:
	DB 0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H, 1H, 0H, 0H, 0H, 0H, 0H, 0H, 0H

	ORG 81EH
LUT_BALL2:
	DB 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H
	;Uso esta tabla para mostrar la bola en la matriz

	ORG 900H
LUT_PAD:
	DB 0H, 0F0H, 78H, 3CH, 1EH, 0FH, 7H, 3H, 1H, 0H, 0H, 0H, 0H

	ORG 91EH
LUT_PAD2:
	DB 0H, 0H, 0H, 0H, 0H, 0H, 80H, 0C0H, 0E0H, 0F0H, 78H, 3CH, 1EH

FIN:
	END