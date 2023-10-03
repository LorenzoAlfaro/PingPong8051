include graphfunctions.asm
include logicfunctions.asm


; TODO: Validate pad is not in the border
PAD_UP_MACRO MACRO PAD_A, LIMIT
        LOCAL xyz
        LOCAL zyx
	mov	R2, PAD_A
	cjne R2, #LIMIT, xyz
	sjmp zyx
xyz:
	dec PAD_A
zyx:

ENDM


PAD_DOWN_MACRO MACRO PAD_A, LIMIT
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
PORT_A code 02000H
PORT_B code 02001H
PORT_C code 02002H
; Write to this register to configure PPI
Reg_Control code 02003H


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

ADRE_PAD1A data MEMORIAVIDEO
ADRE_PAD1B data MEMORIAVIDEO2

; 4EH for size 15x15
ADRE_PAD2A data ADRE_PAD1A + TAM_X - 1
; 5EH for size 15x15
ADRE_PAD2B data ADRE_PAD1B + TAM_X - 1

SW data P1
UP_1 bit P1.0
UP_2 bit P1.2
DOWN_1 bit P1.1
DOWN_2 bit P1.3

; RAM 0x29 (byte address) stores ball direction
; Only 1 bit is on at all times
; I think there is a bug here
; UR 00000001
; UL 00000010
; DR 00000100
; DL 00001000
; UP 00010000
; DN 00100000
UR bit 48H
UL bit 49H
DR bit 4AH
DL bit 4BH
UP bit 4CH
DOWN bit 4DH

; Address 0x2A, bit 0
; 00000001
O1 bit 50H
; 00000010
O2 bit 51H
; 00000100
Result1 bit 52H
; 00001000
Result2 bit 53H


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

RESET_:
	; Init pad positions
	; PAD1 is Left pad
	mov	PAD1, #4 ; #7
	; max position is 12 for 15x15
	mov	PAD2, #1 ; #8

	mov	X, #3 ; #7
	mov	Y, #3 ; #7
	setb DR

; MAIN game loop
READ_PORT_:
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
PAD1_UP_DOWN_:
	; UP_1 is the P1.0
	jb UP_1, D1_
	jnb DOWN_1, PAD2_UP_DOWN_
	PAD_DOWN_MACRO PAD1, PAD_DN_LIMIT
D1_:
	jb DOWN_1, PAD2_UP_DOWN_
	PAD_UP_MACRO PAD1, PAD_UP_LIMIT

PAD2_UP_DOWN_:
	jb UP_2, D2_
	jnb DOWN_2, BALL_LOGIC_
	PAD_DOWN_MACRO PAD2, PAD_DN_LIMIT
D2_:
	jb DOWN_2, BALL_LOGIC_
	PAD_UP_MACRO PAD2, PAD_UP_LIMIT

BALL_LOGIC_:

	; x = 0? OR x = 14?     Alguien perdio?
	OR_MACRO LEFT_BORDER, RIGHT_BORDER, X
	jb RESULT1, LOST_

	; x = 1? OR x = 13? La bola esta en zona de paleta?
	OR_MACRO LEFT_PAD_ZONE, RIGHT_PAD_ZONE, X
	jb RESULT1, PAD_ZONE_

	; y = 1? OR y = 15? La bola esta en una pared?
	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	jb RESULT1, WALL_BOUNCE_
	; Ball continues its course.
IGUAL:

UPDATE_BALL_POSITION_:
	; Equivalent to a switch case where
	; only one bit at a time can be set UR, UL, DR, DL
	jb UR, AUR_1_
	jb UL, AUL_1_
	jb DR, ADR_1_
	; Explicitly jump, don't waterfall.
	jb DL, ADL_1_

ADL_1_:
	dec X
	inc Y
	jmp DRAW_DISPLAY_
AUR_1_:
	; Increment X to go right in matrix
	inc X
	; Decrement Y to go up in matrix
	dec Y
	jmp DRAW_DISPLAY_
AUL_1_:
	dec X
	dec Y
	jmp DRAW_DISPLAY_
ADR_1_:
	inc X
	inc Y
	jmp DRAW_DISPLAY_ ; again, don't try to be too smart, just include this line for clarity

LOST_:
	jmp RESET_
WALL_BOUNCE_:
	; jbc clears the bit before the jump
	jbc UR, UR_1_
	jbc UL, UL_1_
	jbc DR, DR_1_
	jbc DL, DL_1_
DL_1_:
	setb UL
	jmp UPDATE_BALL_POSITION_
UR_1_:
	setb DR
	jmp UPDATE_BALL_POSITION_
UL_1_:
	setb DL
	jmp UPDATE_BALL_POSITION_
DR_1_:
	setb UR
	jmp UPDATE_BALL_POSITION_

PAD_ZONE_:
	mov R2, X
	cjne R2, #LEFT_PAD_ZONE, PALETA_2_
	mov P_T, PAD1
	sjmp A70_
PALETA_2_:
	mov P_T, PAD2

	; if ball_x == LEFT_PAD_ZONE
	;	P_T = PAD1_Y
	; else
	;	P_T = PAD2_Y
A70_:
	mov A, P_T
	subb A, #1 ; this is why Y starts with 1, not 0, to not deal with negative numbers
	mov R2, A
	mov A_O, R2
	add A, #5
	mov R3, A
	mov B_O, R3
	mov C_O, Y
	call ESTA_RANGO
	jnb RESULT2, UPDATE_BALL_POSITION_
	; R2 es mi Pad_Y0
	; R3 es mi Pad_Y1
	;
	; A_O = P_T - 1
	; B_O = A_0 + 5
	; if Y > P_maximo or Y < P_minimo
	;	goto UPDATE_BALL_POSITION_ // No bounce needs to be calculate

	OR_MACRO UP_WALL_ZONE, DN_WALL_ZONE, Y
	jb RESULT1, A50_
	; if Y == TOP or Y == BOTTOM
	;	goto corner_bounce

	; ORL does a bitwise "OR" operation between operand1 and operand2,
	; leaving the resulting value in operand1.

	mov C, DL
	orl C, DR
	mov DOWN, C

	mov C, UL
	orl C, UR
	mov UP, C

	; set UP/DOWN flags, only should be true
	; if ball going up-right or up-down?
	; 	UP = 1;
	; if ball going down-right or down-down?
	; 	DOWN = 1;

	; BUG: I'm not clearing UP or DOWN after each run


	; ANL does a bitwise "AND" operation between operand1 and operand2,
	; leaving the resulting value in operand1.

; Calculate flag1
	mov A, R2
	cjne A, Y, B90_
	setb RESULT1
	sjmp B80_
B90_:
	clr RESULT1
B80_:
	; if Y == Pad_Y0 and DOWN == 1
	;	set flag1
	; else
	;	clear flag1
	mov C, RESULT1
	anl C, DOWN
	mov RESULT1, C
; Calculate flag2
	mov A, R3
	cjne A, Y, B70_
	setb RESULT2
	sjmp B60_
B70_:
	clr RESULT2
B60_:
	; if Y == Pad_Y1 and UP == 1
	;	set flag2
	; else
	;	clear flag2
	mov C, RESULT2
	anl C, UP
	mov RESULT2, C

; or both flags

	mov C, RESULT1
	orl C, RESULT2
	jc A50_

	jmp PAD_BOUNCE_
A50_:
	jmp CORNER_BOUNCE_

	; if flag1 or flag2
	; 	goto CORNER_BOUNCE
	; else
	;	goto PAD_BOUNCE

CORNER_BOUNCE_:
	jbc UR, UR_11_
	jbc UL, UL_11_
	jbc DR, DR_11_
	jbc DL, DL_11_
DL_11_:
	; not necessary now because using jbc DL, DL_11_ clears it
	setb UR
	jmp UPDATE_BALL_POSITION_
UR_11_:
	setb DL
	jmp UPDATE_BALL_POSITION_
UL_11_:
	setb DR
	jmp UPDATE_BALL_POSITION_
DR_11_:
	setb UL
	jmp UPDATE_BALL_POSITION_


PAD_BOUNCE_:
	jbc UR, UR_12_
	jbc UL, UL_12_
	jbc DR, DR_12_
	jbc DL, DL_12_
	; jbc clears the bit before the jump
DL_12_:
	setb DR
	jmp UPDATE_BALL_POSITION_
UR_12_:
	setb UL
	jmp UPDATE_BALL_POSITION_
UL_12_:
	setb UR
	jmp UPDATE_BALL_POSITION_
DR_12_:
	setb DL
	jmp UPDATE_BALL_POSITION_

DRAW_DISPLAY_:
    call CLEAR_VIDEO_MEMORY
	; This is a 8 x 8 loop of wrtting to PPI
	call WRITE_VIDEO_MEMORY
	mov R1, #SPRITE_RENDER
PAUSE1a_:
	mov R2, #SPRITE_RENDER
PAUSE2a_:
	call WRITE_TO_PPI
	djnz R2, PAUSE2a_
	djnz R1, PAUSE1a_
	;call	DELAY_0_2

	; This complete the game loop
	jmp READ_PORT_


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