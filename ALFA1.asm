;Codigo para representar Alfa



ORG	0h
	clr	A
	mov	P1, A

	jmp MAIN

ORG 100H
MAIN: 


	CALL LETRAA
	CALL LETRAL
	CALL LETRAF
	CALL LETRAA
	CALL DELAY
	;CALL LETRAL
	;CALL LETRAF
	ajmp	MAIN

LetraA:	mov R1,#255
Pause1: 	mov R2,#255
Pause2:  
	MOV	P1, #77H
	MOV	P1,#0BAH
	MOV	P1,#0DAH
	MOV	P1,#0E7H
	djnz R2,PAUSE2
	djnz R1,PAUSE1
	RET

LetraL:	mov R1,#255
Pause11: 	mov R2,#255
Pause21:  
	MOV	P1, #7FH
	MOV	P1,#0B1H
	MOV	P1,#0D1H
	MOV	P1,#0E0H
	djnz R2,PAUSE21
	djnz R1,PAUSE11
	RET

LetraF:	mov R1,#255
Pause1a: 	mov R2,#255
Pause2a:  
	MOV	P1,#07FH
	MOV	P1,#0BAH
	MOV	P1,#0D8H
	MOV	P1,#0E0H
	djnz R2,PAUSE2a
	djnz R1,PAUSE1a
	RET


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
