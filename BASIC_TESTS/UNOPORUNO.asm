;Codigo para representar Alfa



ORG	0h
	clr	A
	mov	P1, A

	jmp MAIN

ORG 100H
MAIN: 

	MOV	P1, #71H
	CALL	delay
	
	MOV	P1, #0B1H
	CALL	delay
	MOV	P1, #0D1H
	CALL	delay
	MOV	P1, #0E1H
	CALL	delay
	MOV	P1, #072H
	CALL	delay
	MOV	P1, #0B2H
	CALL	delay
	MOV	P1, #0D2H
	CALL	delay
	MOV	P1, #0E2H
	CALL	delay
	MOV	P1, #074H
	CALL	delay
	MOV	P1, #0B4H
	CALL	delay
	MOV	P1, #0D4H
	CALL	delay
	MOV	P1, #0E4H
	CALL	delay
	MOV	P1, #078H
	CALL	delay
	MOV	P1, #0B8H
	CALL	delay
	MOV	P1, #0D8H
	CALL	delay
	MOV	P1, #0E8H
	CALL	delay
	ajmp	MAIN


start:

;=============================================
;subroutine delay created to rise delay time
;=============================================
delay: mov R1,#255
del1:  mov R2,#255
del2:  djnz R2,del2
       djnz R1,del1
       ret
end

