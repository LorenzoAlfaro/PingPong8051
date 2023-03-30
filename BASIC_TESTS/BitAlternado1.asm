
org 0h
clr A
MOV P1,A

start:  Clr P1.0  ; send '0' to P0.0
		Setb P1.1 ; send '1' to P0.0
		Clr P1.2  ; send '0' to P0.0
		Setb P1.3 ; send '1' to P0.0
		Clr P1.4  ; send '0' to P0.0
		Setb P1.5 ; send '1' to P0.0
		Clr P1.6  ; send '0' to P0.0
		Setb P1.7 ; send '1' to P0.0
sjmp start; loooooop forever to start
		
end