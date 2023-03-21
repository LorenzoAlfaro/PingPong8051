;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display

PORT_A	EQU	02000H		;Direccion del puerto A en RAM Externa
PORT_B	EQU	02001H		;Para referenciar se usa MOVX
PORT_C	EQU	02002H
Reg_Control	EQU	02003H	;Recibe palabra de control


CONTCOL	DATA	24H		;		COLUMNA


MemoriaViDEO_a	EQU	40H

MemoriaVIDEO_b	EQU	50H






	ORG	0H

	SJMP	START

	ORG	30H		;Comienzo el programa saltando 
	;los vectores
START:
	MOV	SP, #5FH


	MOV	A, #080H			; Esta palabara de control define A,B,C=outputs
	MOV	DPTR, #REG_CONTROL	;Cargo direccion del registro de control
	MOVX	@DPTR, A	

	GRAFICO:	
	CALL	WRITE_VIDEO_MEMORY1
		mov R1,#0FH
Pause1a: 	mov R2,#0FH
Pause2a:
	
	CALL	WRITE_TO_PPI  
	
	djnz R2,PAUSE2a
	djnz R1,PAUSE1a 

	CALL	WAIT

	CALL	WRITE_VIDEO_MEMORY12
		mov R1,#0FH
Pause1aa: 	mov R2,#0FH
Pause2aa:
	
	CALL	WRITE_TO_PPI  
	
	djnz R2,PAUSE2aa
	djnz R1,PAUSE1aa

	CALL	WAIT
	
	JMP	GRAFICO			
 
	

	
	
WAIT:	
	PUSH	2
	PUSH	3

	mov	R3, #08h
label2:	mov	R2, #08h
	djnz	R2, $
	djnz	R3, label2

	POP	3
	POP	2
	ret
WRITE_TO_PPI:

	PUSH	ACC
	PUSH	0
	PUSH	1
	PUSH	2
	PUSH	82H
	PUSH	83H

	MOV	R2, #0FH
	MOV	R0,#MEMORIAVIDEO_a
	MOV	R1,#MEMORIAVIDEO_b

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


WRITE_VIDEO_MEMORY12:
	PUSH	ACC
	PUSH	82H
	PUSh	83H
	PUSH	0
	PUSH	4

	CLR	A
	MOV	DPTR,#Dibujo1a
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_A
Z1002:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z1002

CLR	A
	MOV	DPTR,#dibujo1b
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_b
Z1012:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z1012

	POP	4
	POP	0
	POP	83H
	POP	82H
	POP	ACC

	RET

WRITE_VIDEO_MEMORY1:
	PUSH	ACC
	PUSH	82H
	PUSh	83H
	PUSH	0
	PUSH	4

	CLR	A
	MOV	DPTR,#dibujo2a
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_A
Z100:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z100

CLR	A
	MOV	DPTR,#dibujo2b
	
	MOV	R4, #0EH
	MOV	R0, #MEMORIAVIDEO_b
Z101:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z101

	POP	4
	POP	0
	POP	83H
	POP	82H
	POP	ACC

	RET
	
	
	
org	800H
LETRA_A1: DB	0h,0h,3h,4h,8h,10h,20h,20h,20h,10h,8h,4h,3h,0h,0h

org 	81EH
LETRA_A2: DB	0h,0h,0f8h,80h,80h,80h,80h,80h,80h,80h,80h,80h,0f8h,0h,0h

ORG	930H
dibujo1a: DB	0H, 0h, 0h, 0EH, 2H, 72H, 7FH, 72H, 2H, 0EH, 0H, 0H, 0H, 0H, 0H	

	ORG	960H
dibujo1b: DB	0h, 0H, 0H, 08H, 10H, 20H, 0C0H, 20H, 10H, 8H, 0H, 0H, 0H, 0H, 0H

ORG	980H
dibujo2a: DB	0H, 0h, 1h, 02H, 2H, 72H, 7FH, 72H, 2H, 02H, 01H, 0H, 0H, 0H, 0H	

	ORG	1000H
dibujo2b: DB	0h, 08H, 0H, 0H, 4H, 3CH, 0C0H, 3CH, 4H, 0H, 0H, 80H, 0H, 0H, 0H

	END










