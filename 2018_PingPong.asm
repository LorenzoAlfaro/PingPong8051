incLUDE graphfunctions.asm
incLUDE logicfunctions.asm

PAD_M MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	mov	R2, PAD_A
	cjne R2, #LIMIT, xyz
	sjmp zyx
xyz:
	dec PAD_A
zyx:
	;RET
ENDM
; TODO: Validate pad is not in the border

PAD_P MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	mov	R2, PAD_A
	cjne R2, #LIMIT, xyz
	sjmp zyx						
xyz:
	inc	PAD_A
zyx:
	;RET
ENDM


;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display
SPRITE_RENDER equ 1 ; times the sprite
PAD_SIZE equ 4
TAM_X equ	8 ; 15
TAM_Y equ	9 ; 16
LEFT_BORDER equ 0
RIGHT_BORDER equ TAM_X -1

LEFT_PAD_ZONE equ 1
RIGHT_PAD_ZONE equ TAM_X -2

UP_WALL_ZONE equ 1
DN_WALL_ZONE equ TAM_Y - 1

PAD_UP_LIMIT equ UP_WALL_ZONE
PAD_DN_LIMIT equ TAM_Y - PAD_SIZE

; PPI Ports addresses
PORT_A equ	02000H			; Direccion del puerto A en RAM Externa
PORT_B equ	02001H			; Para referenciar se usa movX
PORT_C equ	02002H
Reg_Control equ	02003H			; Recibe palabra de control

;;POS_PAD1	equ	0H				; position dela tableta en la pantalla
;;POS_PAD2	equ	0EH
;;Y_T	data	1EH			;variable temporal y
P_T	data 1FH			;Variable temporal de paleta
PAD1 data 20H			;Variables de posicion de objetos
PAD2 data 21H			;
X data 22H			;OFFSET	para la MEMORIAVIDEO
Y data 23H			;OFFSET	para la LUT_BALL

A_O data 30H			; Almacenamiento temporal para los operandos de la or de alto nivel
B_O data 31H
C_O data 32H			; Elemento a comparar

MEMORIAVIDEO equ 40H
MEMORIAVIDEO2 equ 50H

;MemoriaViDEOA equ 41H
;MemoriaVIDEO2A equ 51H

ADRE_PAD1A equ MEMORIAVIDEO
ADRE_PAD1B equ MEMORIAVIDEO2

ADRE_PAD2A equ ADRE_PAD1A + TAM_X -1; 4EH for size 15x15
ADRE_PAD2B equ ADRE_PAD1B + TAM_X -1; 5EH for size 15x15

SW equ P1
UP_1 equ P1.0
DOWN_1 equ P1.1
UP_2 equ P1.2
DOWN_2 equ P1.3

UR equ 48H				; 00000001 RAM 29 Indican la direccion de la bola, SOLAMENTE puede estar uno
UL equ 49H				; 00000010
DR equ 4AH				; 00000100 pg 181
DL equ 4BH				; 00001000
UP equ 4CH				; 00010000
DOWN equ 4DH				; 00100000

O1 equ 50H				;Direccion 2A, del bit 0			00000001
O2 equ 51H				;	00000010
Result1 equ 52H				;resultado logico donde se guarda		00000100
Result2 equ 53H				;	00001000

	ORG 0
	sjmp START
	ORG 30H		;Comienzo el programa saltando los vectores
START:

;--------------------------------------Seccion de INICIALIZACION
	mov	SP, #5FH
	mov	A, #080H			; Esta palabara de control define A,B,C=outputs
	mov	DPTR, #REG_CONTROL	; Cargo direccion del registro de control
	;movX @DPTR, A				; Programo el PPI ; add this when using 15x15 with PPI
	mov	PAD1, #1				; 7 Inicializo la posicion de las paletas ; LEFT PAD
	mov	PAD2, #1				; 8 maxima posicion es 12			; RIGHT PAD
	mov	X, #3 ; 7 for 15x15
	mov	Y, #3 ; 7 for 15x15
	setb UL
;--------------------------------------TOMA DE decICIONES LEYENDO P1
READ_PUERTO:
	mov A, SW				; Read input port
	;call    delay_0_2		; lee el switch cada 0.2 segundos
	anl A, #0FH ; Apply Mask 00001111
	mov R7, A	; Make copy in R7 for comparisons
	;call	CLEAR_VIDEO_MEMORY
;--------------------------------------LOGICA DE LAS TABLETAS-----------------------------
;Logica para  SUBE O BAJA PAD
PAD1_UP_DOWN:
	jb UP_1, D1    ;UP_1 is the P1.0
	jnb DOWN_1, PAD2_UP_DOWN
	PAD_P PAD1, PAD_DN_LIMIT
D1:
	jb DOWN_1, PAD2_UP_DOWN
	PAD_M PAD1, PAD_UP_LIMIT

PAD2_UP_DOWN:
	jb UP_2, D2
	jnb DOWN_2, BALL_LOGIC
	PAD_P PAD2, PAD_DN_LIMIT
D2:
	jb DOWN_2, BALL_LOGIC
	PAD_M PAD2, PAD_UP_LIMIT
;--------------------------------------INICIA LOGICA de la bola-------------------------------------------------
BALL_LOGIC:
	mov A, X				; DEBUG: Save X value
	mov P3, A				; DEBUG: Print in port 3

	OR_MACRO LEFT_BORDER, RIGHT_BORDER, X    ;X=0 OR X=14     ALGUIEN PERDIO?????
	jb RESULT1, LOST

	OR_MACRO LEFT_PAD_ZONE, RIGHT_PAD_ZONE, X    ;X=1 OR X=13    LA bola esta en zona de paleta?????
	jb RESULT1, ZONA_PALETA

	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y    ;y=1 OR y=15	LA bola esta en una pared???????????
	jb RESULT1, CHOQUE_PARED
	;La bola sigue su curso--------------
IGUAL:

ACTION:
	; equivalent to a switch case where only at a time bit can be set UR, UL, DR, DL
	jb UR, AUR_1
	jb UL, AUL_1
	jb DR, ADR_1
	jb DL, ADL_1	; trying to be smart, you just create unreadable code, this line could be commented out, but makes more sense
ADL_1:
	dec X
	inc Y
	;jmp	READ_PUERTO ; SKIP GRAPH LOGIC
	jmp GRAFICO
AUR_1:
	inc X						;Lo incremento para ir a la derecha
	dec Y						;Lo decremento para  SUBIR
	;jmp	READ_PUERTO ; SKIP GRAPH LOGIC
	jmp GRAFICO
AUL_1:
	dec X
	dec Y
	;jmp	READ_PUERTO ; SKIP GRAPH LOGIC
	jmp GRAFICO
ADR_1:
	inc X
	inc Y
	;jmp	READ_PUERTO ; SKIP GRAPH LOGIC
	jmp GRAFICO ; again, don't try to be too smart, just include this line for clarity

;--------------------------------------Ramas de la logica-------------------------
LOST:
	jmp START
CHOQUE_PARED:
	jbc UR, UR_1
	jbc UL, UL_1
	jbc DR, DR_1	; again, don't try to be too smart, just include this line, intead "falling" to the next part
	jbc DL, DL_1
DL_1:
	clr DL
	setb UL
	jmp ACTION
UR_1:
	setb DR
	jmp ACTION
UL_1:
	setb DL
	jmp ACTION
DR_1:
	setb UR
	jmp ACTION

ZONA_PALETA:
	;la logica mas compleja es la de la bola
	mov R2, X
	cjne R2, #LEFT_PAD_ZONE, PALETA_2	;cual es la paleta en cuestion
	mov P_T, PAD1
	sjmp A70
PALETA_2:
	mov P_T, PAD2
A70:
	;-------------
	mov A, P_T
	subb A, #1
	mov R2, A				;R2 es mi P_minimo
	mov A_O, R2
	; A_0 = P_T -1
	add A, #5
	mov R3, A				;R3 es mi P_maximo
	mov B_O, R3
	; B_0 = A_0 + 5
	mov C_O, Y
	call ESTA_RANGO
	jnb RESULT2, ACTION			;si no esta en el rango, continuo sin rebotar
	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	jb RESULT1, A50			;es un caso especial?? Si, entonces rebote en la esquina
	mov C, DL
	orl C, DR
	mov DOWN, C				;la bola baja o	BIT	00100000			29H
	mov C, UL
	orl C, UR
	mov UP, C				;o sube			BIT 00010000		29H
	mov A, R2
	cjne A, Y, B90
	setb RESULT1
	sjmp B80
B90:
	clr RESULT1
B80:
	mov C, RESULT1
	anl C, DOWN			; y==Pmin AND  DOWN=1  ??
	mov RESULT1, C				;condicion 1 se cumplio ?
	mov A, R3
	cjne A, Y, B70
	setb RESULT2
	sjmp B60
B70:
	clr RESULT2
B60:
	mov C, RESULT2
	anl C, UP				;y==Pmax AND  Up=1  ??
	mov RESULT2, C				;condicion 2 se cumplio ?
	mov C, RESULT1
	orl C, RESULT2
	jc A50						;si las dos condiciones se cumplen, pego en la esquina de la paleta
	jmp REBOTE_PALETA			;si no pego en plano
A50:
	jmp REBOTE_ESQUINA

REBOTE_ESQUINA:
	jbc UR, UR_11
	jbc UL, UL_11
	jbc DR, DR_11
	jbc DL, DL_11	; again, don't try to be too smart, just include this line, intead "falling" to the next part
DL_11:
	clr DL
	setb UR
	jmp ACTION
UR_11:
	setb DL
	jmp ACTION
UL_11:
	setb DR
	jmp ACTION
DR_11:
	setb UL
	jmp ACTION

REBOTE_PALETA:
	jbc UR, UR_12
	jbc UL, UL_12
	jbc DR, DR_12
	jbc DL, DL_12		; again, don't try to be too smart, just include this line, intead "falling" to the next part
DL_12:
	clr DL	; why only this one gets cleared? seems like a bug?
	setb DR
	jmp ACTION
UR_12:
	setb UL
	jmp ACTION
UL_12:
	setb UR
	jmp ACTION
DR_12:
	setb DL
	jmp ACTION

;--------------------------------------Paso a graficar-------------------
GRAFICO:
    call CLEAR_VIDEO_MEMORY
	; This is a 8 x 8 loop, of just display
	call WRITE_VIDEO_MEMORY
	mov R1, #SPRITE_RENDER
Pause1a:
	mov R2, #SPRITE_RENDER
Pause2a:
	call WRITE_TO_PPI
	djnz R2, PAUSE2a
	djnz R1, PAUSE1a
	;call	DELAY_0_2
	jmp READ_PUERTO    ; This complete the game loop
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