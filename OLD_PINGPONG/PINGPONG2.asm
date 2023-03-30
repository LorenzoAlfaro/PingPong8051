;PROJECTO DE PING PONG POR LORENZO ALFARO y ALEJANDRO VARGAS ABRIL 2012

TAM_X		EQU	15
TAM_Y		EQU	15

PORT_A		EQU	02000H	;Direccion del puerto A en RAM Externa
PORT_B		EQU	02001H	;Para referenciar se usa MOVX
PORT_C		EQU	02002H	
Reg_Control	EQU	02003H	;Recibe palabra de control

PAD1		DATA	20H;	;Variables de posicion de objetos
PAD2		DATA	21H;
TEMP_A		DATA	22H;
TEMP_B		DATA	23H;
COL		DATA	24H;		COLUMNA

SW1_UP		EQU	P1.0
SW1_DW		EQU	P1.1

SW2_UP		EQU	P1.2
SW2_DW		EQU	P1.3
SW		EQU	P1

ORG 		0

SJMP START

ORG 		30H		;Comienzo el programa saltando 
				;los vectores
START:

;Seccion de INICIALIZACION

		MOV	A, 	#080H	; Esta palabara de control define A,B,C=outputs
		MOV	DPTR,	#REG_CONTROL	;Cargo direccion del registro de control
		MOVX	@DPTR,	A		;Programo el PPI
		MOV	PAD1,  #6		;Inicializo la posicion de las paletas
		MOV	PAD2,  #6
		MOV	COL, #0			;Inicializo en columna o
;TOMA DE DECICIONES LEYENDO P1
READ_PUERTO:
	MOV DPL,#LOW(TABLA_SALTO)  			; set start of jump table
        MOV DPH,#HIGH(TABLA_SALTO)
        MOV A,SW  					; Read input port
        ANL A,#00FH   ; Confine to 16 choices
        MOV R7,A      ; Make copy in R7 for comparisons
        MOV B,#3
        MUL AB          ; multiply by two since each AJMP is two bytes
        JMP @A+DPTR

TABLA_SALTO:
        JMP LEER				;UNAS COMBINACIONES SE REPITEN
        JMP UP1
        JMP DW1
        JMP LEER
        JMP UP2
        JMP UP2_UP1
        JMP UP2_DW1
        JMP UP2
        JMP DW2
        JMP DW2_UP1
        JMP DW2_DW1
        JMP DW2
        JMP LEER
        JMP UP1
        JMP DW1
        JMP LEER
UP1:

	DEC	PAD1
	JMP	SCAN_COLUMN
	
DW1:
	INC	PAD1
	JMP 	DW1
UP2:
	DEC	PAD2
	JMP 	up2
DW2:
	INC	PAD2
	JMP 	DW2
UP2_UP1:
	DEC 	PAD2
	DEC 	PAD1
	JMP 	UP2_UP1
UP2_DW1:
	DEC 	PAD2
	INC	PAD1
	JMP 	UP2_DW1
DW2_UP1:	
	INC	PAD2
	DEC	PAD1
	JMP 	DW2_UP1
DW2_DW1:
	INC	PAD2
	INC	PAD2
	JMP 	DW2_DW1

LEER:
	JMP READ_PUERTO



GRAFICOS:
	CALL DISPLAY1			;GUARDO EN TEMP A y TEMP B el display de la paleta 1 
	CALL	PAD_LED			;ENCARGADO DE ENCENDER LOS LEDS
	
;----------------------------------------------------------------------------------
SCAN_COLUMN:				;RUTINA que scanea las columnas
	MOV	R1, 	#TAM_X
	CLR	A
	MOV	COL,A
	CALL	CLEAR_LED
	MOV	DPTR,#PORT_C
	MOVX	@DPTR,	A				;Reseteo la columna
	
COLUMN:
	CALL	CLEAR_LED
	MOV	DPTR,	#PORT_C
	MOV	A,	COL
	MOVX	@DPTR,	A		;OJO con el valor de la columna


	MOV	R4,	COL
primera:	CJNE	R4, #0, ultima 			;esta logica es: Pruebo si la columna es 0 muestro PAD1, si la columna es la ultima
	CALL 	DISPLAY1				;muestro PAD2
	CALL	PAD_LED
	SJMP	SI_PASA
Ultima:	CJNE	R4,  #14, SI_PASA
	CALL	DISPLAY2
	CALL	PAD_LED

SI_PASA:	INC	COL
	DJNZ	R1, 	COLUMN
	SJMP	SCAN_COLUMN

;----------------------------------------------------------------------------------------------------
DISPLAY1:
	MOV DPTR, #LUT_PAD				;Cargo direccion de LUT
	MOV	A,PAD1					;USO A como OFFSET qu
	RL	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR				;compio en A, el valor de la tabla
	MOV	TEMP_A,A
	MOV	A,PAD1					;USO A como OFFSET qu
	RL	A					;Tengo que cargar el OFFSET de nuevo +1 para obtener el segundo par
	INC	A
	MOVC	A, @A+DPTR
	MOV	TEMP_B,A
	RET
	CALL	PAD_LED
;----------------------------------------------------------------------------------------------------
DISPLAY2:
	MOV DPTR, #LUT_PAD				;Cargo direccion de LUT
	MOV	A,PAD2					;USO A como OFFSET qu
	RL	A					;Lo multiplico por dos, por que la tabla esta hecha de pares
	MOVC	A, @A+DPTR				;compio en A, el valor de la tabla
	MOV	TEMP_A,A
	MOV	A,PAD2					;USO A como OFFSET qu
	RL	A					;Tengo que cargar el OFFSET de nuevo +1 para obtener el segundo par
	INC	A
	MOVC	A, @A+DPTR
	MOV	TEMP_B,A
	RET
	CALL	PAD_LED

;-------------------------------------------------------------------------------------------
PAD_LED:
	MOV	DPTR, #PORT_A
	MOV	A, TEMP_A				;cargo direccion del PUERTO A
	MOVX	@DPTR,	A
	INC	DPTR				; APUNTO A PUERTO B !!!
	MOV	A,TEMP_B
	MOVX	@DPTR,	A
	RET
	
;-------------------------------------------------------------------------------------------
CLEAR_LED:
	MOV	DPTR, #PORT_A
	MOV	A, #0H				;cargo direccion del PUERTO A
	MOVX	@DPTR,	A
	INC	DPTR				; APUNTO A PUERTO B !!!
	MOV	A,#0H
	MOVX	@DPTR,	A
	RET

;-------------------------------------------------------------------------------------------------
;Seccion de Las tablas para los graficos

ORG		1000H
LUT_BALL: DB	    80H,0H,40H,0H,20H,0H,10H,0H,8H,0H,4H,0H,2H,0H,1H,0H,0H,80H,0H,40H,0H,20H,0H,10H,0H,8H,0H,4H,0H,2H
				;Uso esta tabla para mostrar la bola en la matriz
ORG		1030H
LUT_PAD:	DB	0F0H,0H,78H,0H,3CH,0H,1EH,0H,0FH,0H,7H,80H,3H,0C0H,1H,0E0H,0H,0F0H,0H,78H,0H,3CH,0H,1EH
		
		
										

END

