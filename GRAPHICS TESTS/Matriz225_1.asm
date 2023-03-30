;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012
;Version 6, Uso un delays para el display

PORT_A	EQU	02000H		;Direccion del puerto A en RAM Externa
PORT_B	EQU	02001H		;Para referenciar se usa MOVX
PORT_C	EQU	02002H
Reg_Control	EQU	02003H	;Recibe palabra de control


COL	DATA	24H		;		COLUMNA


MemoriaViDEO	EQU	40H
ADRE_PAD1A	EQU	40H
ADRE_PAD2A	EQu	5CH
ADRE_PAD1B	EQU	41H
ADRE_PAD2B	EQu	5DH




	ORG	0H

	SJMP	START

	ORG	30H		;Comienzo el programa saltando 
	;los vectores
START:



	MOV	A, #080H			; Esta palabara de control define A,B,C=outputs
	MOV	DPTR, #REG_CONTROL	;Cargo direccion del registro de control
	MOVX	@DPTR, A			;Programo el PPI

	MOV	COL, #0			;Inicializo en columna o


	MOV	DPTR, #LETRA_A
	CALL	WRITE_VIDEO_MEMORY1

GRAFICO:
	mov	R1, #255
Pause1:	mov	R2, #255
Pause2:
	CALL	WRITE_TO_PPI
	djnz	R2, PAUSE2
	djnz	R1, PAUSE1



	AJMP	GRAFICO


;**********************************************************************************************************
;**********************************************************************************************************

WRITE_VIDEO_MEMORY1:


	CLR	A

	MOV	R4, #30
	MOV	R0, #MEMORIAVIDEO
Z100:	MOVC	A, @A+DPTR
	MOV	@R0, A
	INC	R0
	INC	DPTR
	CLR	A
	DJNZ	R4, Z100


	RET

;**********************************************************************************************************
;**********************************************************************************************************
WRITE_TO_PPI:

	MOV	R1, #0EH
	
	MOV	R0, #MEMORIAVIDEO
C90:
	CALL	CLEAR_PPI
	MOV	DPTR, #PORT_C
	MOV	A, R1

	MOVX	@DPTR, A	;CARGO FILA

	MOV	DPTR, #PORT_A

	MOV	A, @R0
	MOVX	@DPTR, A

	INC	DPTR		;apunta a PUERTO B
	INC	R0		;segundo byte dela columna de led

	MOV	A, @R0
	MOVX	@DPTR, A

	INC	R0
	INC	COL


	DJNZ	R1, C90

	RET
;**********************************************************************************************************
;**********************************************************************************************************
CLEAR_PPI:
	MOV	DPTR, #PORT_A
	CLR	A
	MOVX	@DPTR, A
	INC	DPTR		;APUTNA A PUERTO B
	MOVX	@DPTR, A
	INC	DPTR		;APUTNA A PUERTO B
	MOVX	@DPTR, A
	RET
;**********************************************************************************************************
;**********************************************************************************************************

Delay_0_2:

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
	RET
;**********************************************************************************************************
;**********************************************************************************************************
CLEAR_VIDEO_MEMORY:


	MOV	R1, #30
	MOV	R0, #MEMORIAVIDEO
BORRAR:	MOV	@R0, #0
	INC	R0
	DJNZ	R1, BORRAR
	RET
;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

	ORG	800H
Letra_A:	DB	0H, 0H, 0H, 0H, 3H, 0F8H, 4H, 80H, 8H, 80H, 10H, 80H, 20H, 80H, 20H, 80H, 20H, 80H, 10H, 80H, 8H, 80H, 4H, 80H, 3H, 0F8H, 0H, 0H, 0H, 0H



	END







