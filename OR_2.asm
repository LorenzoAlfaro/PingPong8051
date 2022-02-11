;OR DE ALTO NIVEL que compara dos condiciones



A_OR	DATA	30H		;Almacenamiento temporal para los operandos de la or de alto nivel
B_OR	DATA	31H
C_OR	DATA	32H		;Elemento a comparar

OR1	EQU	50H		;Direccion 2A, del bit 0
OR2	EQU	51H
Result	EQU	52H		;resultado logico donde se guarda

ORG 0H


MOV	A, #0
SUBB	A, #10
ADD	A, #12


MOV	A_OR, #06

MOV	B_OR,#06

MOV	C_OR,#06		;El seis se sustituye por una variable que genera el programa




;Empiezo la logica de OR
MOV	A, C_OR

CJNE	A,A_OR, seg_operando


SETB	OR1


seg_operando:


CJNE	A,B_OR, OPERACION_OR	; tiene que usar A, si va a compararlo con el dato de la memoria, #B_OR es la DIREECCION

setb	OR2

Operacion_OR:

MOV	C, OR1
ORL	C,OR2
MOV	RESULT,C


;------------------------------------Logica externa del programa

JBC	RESULT, Funciono
MOV	A, #88

FUNCIONO:
MOV	R1,#11

END