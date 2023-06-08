include graphfunctions.asm
include logicfunctions.asm


; TODO: Validate pad is not in the border
PAD_M MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	mov	R2, PAD_A
	cjne R2, #LIMIT, xyz
	sjmp zyx
xyz:
	dec PAD_A
zyx:

ENDM


PAD_P MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	mov	R2, PAD_A
	cjne R2, #LIMIT, xyz
	sjmp zyx
xyz:
	inc	PAD_A
zyx:

ENDM


; PING PONG (8051) by LORENZO ALFARO
; and ALEJANDRO VARGAS, APRIL 2012

; Constant definitions:

; Number of times game is rendered
SPRITE_RENDER equ 1
PAD_SIZE equ 4
TAM_X equ 8 ; 15
; TODO TAM_X and TAM_Y should be the same!
TAM_Y equ 9 ; 16
LEFT_BORDER equ 0
RIGHT_BORDER equ TAM_X -1

LEFT_PAD_ZONE equ 1
RIGHT_PAD_ZONE equ TAM_X -2

UP_WALL_ZONE equ 1
DN_WALL_ZONE equ TAM_Y - 1

PAD_UP_LIMIT equ UP_WALL_ZONE
PAD_DN_LIMIT equ TAM_Y - PAD_SIZE

; Address definitions:

; PPI Ports addresses,
; Use movx to write/read to the PPI 8255
; PPI port addresses (use external memory mode)
PORT_A equ 02000H
PORT_B equ 02001H
PORT_C equ 02002H
; Write to this register to configure PPI
Reg_Control equ	02003H


; Variable definitions:

; Game variables
; Temp variable that holds pad position
P_T	data 1FH
PAD1 data 20H
PAD2 data 21H
; MEMORIAVIDEO offset
X data 22H
; LUT_BALL offset
Y data 23H

; OR/AND operand variables
A_O data 30H
B_O data 31H
; Element that is being compared
C_O data 32H

MEMORIAVIDEO equ 40H
MEMORIAVIDEO2 equ 50H

;MemoriaViDEOA equ 41H
;MemoriaVIDEO2A equ 51H

ADRE_PAD1A equ MEMORIAVIDEO
ADRE_PAD1B equ MEMORIAVIDEO2

; 4EH for size 15x15
ADRE_PAD2A equ ADRE_PAD1A + TAM_X - 1
; 5EH for size 15x15
ADRE_PAD2B equ ADRE_PAD1B + TAM_X - 1

SW equ P1
UP_1 equ P1.0
UP_2 equ P1.2
DOWN_1 equ P1.1
DOWN_2 equ P1.3

; RAM 0x29 stores ball direction
; Only 1 bit is on at all times
; I think there is a bug here
; UR 00000001
; UL 00000010
; DR 00000100
; DL 00001000
; UP 00010000
; DN 00100000
UR equ 48H
UL equ 49H
DR equ 4AH
DL equ 4BH
UP equ 4CH
DOWN equ 4DH

; Address 0x2A, bit 0
; 00000001
O1 equ 50H
; 00000010
O2 equ 51H
; 00000100
Result1 equ 52H
; 00001000
Result2 equ 53H


	ORG 0
	sjmp START
	; Jump interrupt vector addresses.
	ORG 30H

START:
	; Initialization
	mov	SP, #5FH
	; Define PPI ports A, B and C as outputs.
	mov	A, #080H
	; Load address of control register
	mov	DPTR, #Reg_Control
	; Configure PPI
	; Add this when using 15x15 with PPI
	; movX @DPTR, A


	; Init pad positions
	; PAD1 is Left pad
	mov	PAD1, #1 ; #7
	; max position is 12 for 15x15
	mov	PAD2, #1 ; #8

	mov	X, #3 ; #7
	mov	Y, #3 ; #7
	setb UL

; MAIN game loop
READ_PUERTO:
	; Read input port.
	mov A, SW
	; Read switch every 0.2 secs
	; call    delay_0_2

	; Apply mask 00001111b
	anl A, #0FH
	; Make copy in R7 for comparisons
	mov R7, A

; Update position of the pads according
; to switch inputs
; TODO: implement interrupts instead
; for async updating
PAD1_UP_DOWN:
	; UP_1 is the P1.0
	jb UP_1, D1
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

; Update position of the ball
BALL_LOGIC:
	; DEBUG: Save X value
	mov A, X
	; DEBUG: Print in port 3
	mov P3, A

	; x = 0? OR x = 14?     Alguien perdio?
	OR_MACRO LEFT_BORDER, RIGHT_BORDER, X
	jb RESULT1, LOST

	; x = 1? OR x = 13? La bola esta en zona de paleta?
	OR_MACRO LEFT_PAD_ZONE, RIGHT_PAD_ZONE, X
	jb RESULT1, ZONA_PALETA

	; y = 1? OR y = 15? La bola esta en una pared?
	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	jb RESULT1, CHOQUE_PARED
	; La bola sigue su curso
IGUAL:

ACTION:
	; Equivalent to a switch case where
	; only one bit at a time can be set UR, UL, DR, DL
	jb UR, AUR_1
	jb UL, AUL_1
	jb DR, ADR_1
	; Explicitly jump, don't waterfall.
	jb DL, ADL_1

ADL_1:
	dec X
	inc Y
	;jmp	READ_PUERTO ; SKIP GRAPH LOGIC
	jmp GRAFICO
AUR_1:
	; Increment X to go right in matrix
	inc X
	; Decrement Y to go up in matrix
	dec Y
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

; Ramas de la logica
LOST:
	jmp START
CHOQUE_PARED:
	jbc UR, UR_1
	jbc UL, UL_1
	jbc DR, DR_1
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
	; La logica mas compleja es la de la bola
	mov R2, X
	; Cual es la paleta en cuestion?
	cjne R2, #LEFT_PAD_ZONE, PALETA_2
	mov P_T, PAD1
	sjmp A70
PALETA_2:
	mov P_T, PAD2
A70:
	mov A, P_T
	subb A, #1
	; R2 es mi P_minimo
	mov R2, A
	mov A_O, R2
	; A_0 = P_T -1
	add A, #5
	; R3 es mi P_maximo
	mov R3, A
	mov B_O, R3
	; B_0 = A_0 + 5
	mov C_O, Y
	call ESTA_RANGO
	; Si no esta en el rango continuo sin rebotar.
	jnb RESULT2, ACTION
	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	; Es un caso especial?
	; Si, entonces rebote en la esquina.
	jb RESULT1, A50
	mov C, DL
	orl C, DR
	; La bola baja o BIT 00100000 29H
	mov DOWN, C
	mov C, UL
	orl C, UR
	; o sube BIT 00010000 29H
	mov UP, C
	mov A, R2
	cjne A, Y, B90
	setb RESULT1
	sjmp B80
B90:
	clr RESULT1
B80:
	mov C, RESULT1
	; y == Pmin? AND  DOWN == 1?
	anl C, DOWN
	; Condicion 1 se cumplio?
	mov RESULT1, C
	mov A, R3
	cjne A, Y, B70
	setb RESULT2
	sjmp B60
B70:
	clr RESULT2
B60:
	mov C, RESULT2
	; y == Pmax? AND  UP == 1?
	anl C, UP
	; Condicion 2 se cumplio?
	mov RESULT2, C
	mov C, RESULT1
	orl C, RESULT2
	; si las dos condiciones se cumplen
	; pego en la esquina de la paleta
	jc A50
	; Si no, pego en plano
	jmp REBOTE_PALETA
A50:
	jmp REBOTE_ESQUINA

REBOTE_ESQUINA:
	jbc UR, UR_11
	jbc UL, UL_11
	jbc DR, DR_11
	jbc DL, DL_11
DL_11:
	; not necessary now because using jbc DL, DL_11 clears it
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
	jbc DL, DL_12
DL_12:
	clr DL
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

GRAFICO:
    call CLEAR_VIDEO_MEMORY
	; This is a 8 x 8 loop of wrtting to PPI
	call WRITE_VIDEO_MEMORY
	mov R1, #SPRITE_RENDER
Pause1a:
	mov R2, #SPRITE_RENDER
Pause2a:
	call WRITE_TO_PPI
	djnz R2, PAUSE2a
	djnz R1, PAUSE1a
	;call	DELAY_0_2

	; This complete the game loop
	jmp READ_PUERTO


	ORG 800H
	; 'Sprites' of the ball
LUT_BALL:
	DB 0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H, 1H, 0H, 0H, 0H, 0H, 0H, 0H, 0H

	ORG 81EH
LUT_BALL2:
	DB 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 0H, 80H, 40H, 20H, 10H, 8H, 4H, 2H

	; 'Sprites' of the pads
	ORG 900H
LUT_PAD:
	DB 0H, 0F0H, 78H, 3CH, 1EH, 0FH, 7H, 3H, 1H, 0H, 0H, 0H, 0H

	ORG 91EH
LUT_PAD2:
	DB 0H, 0H, 0H, 0H, 0H, 0H, 80H, 0C0H, 0E0H, 0F0H, 78H, 3CH, 1EH

FIN:
	END