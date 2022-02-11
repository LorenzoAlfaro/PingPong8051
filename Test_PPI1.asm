;test ppi 1





PORT_A	EQU	02000H		;Direccion del puerto A en RAM Externa
PORT_B	EQU	02001H		;Para referenciar se usa MOVX
PORT_C	EQU	02002H
Reg_Control	EQU	02003H	;Recibe palabra de control

org 000H

MOV A,#80H ;control word
;(ports output)
MOV DPTR,#reg_control ;load control reg 
;port address
MOVX @DPTR,A ;issue control word
MOV A,#55H ;A = 55H
AGAIN: MOV DPTR,#PORT_A ;PA address
MOVX @DPTR,A ;toggle PA bits
INC DPTR ;PB address
MOVX @DPTR,A ;toggle PB bits
INC DPTR ;PC address
MOVX @DPTR,A ;toggle PC bits
CPL A ;toggle bit in reg A
ACALL Wait ;wait
SJMP AGAIN ;continue


WAIT:	mov	R1, #0FFh
label2:	mov	R2, #0FFh
	djnz	R2, $
	djnz	R1, label2
	ret

END