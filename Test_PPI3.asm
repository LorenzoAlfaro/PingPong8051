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
	MOVX	@DPTR, A	

	MOV	DPTR, #PORT_C		;Programo el PPI
	CLR	A
	MOVX 	@DPTR, A			;columna 0		
	
	AGAIN: 	

;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#1H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*******************************************************************************************

		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#2H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#3H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#4H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#5H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#6H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#7H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#8H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#9H
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#0AH
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#0BH
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#0CH
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#0DH
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		MOV 	DPTR, #PORT_C ;AUMENTO COLUMNA
		MOV	A,#0EH
		MOVX 	@DPTR,A ;toggle PB bits
		ACALL Wait ;wait
;*****************************************************************************************
		MOV 	DPTR,#PORT_A ;PA address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PA bits

		MOV 	DPTR, #PORT_B ;PB address
		MOV	A,#0H
		MOVX 	@DPTR,A ;toggle PB bits

		CALL 	CLEAR_PPI

		

		

		AJMP AGAIN ;continue
	
	
	


	
WAIT:	mov	R1, #0FFh
label2:	mov	R2, #0FFh
	djnz	R2, $
	djnz	R1, label2
	ret
CLEAR_PPI:
	MOV	DPTR, #PORT_A
	CLR	A
	MOVX	@DPTR, A
	INC	DPTR		;APUTNA A PUERTO B
	MOVX	@DPTR, A
	
	RET


	END









