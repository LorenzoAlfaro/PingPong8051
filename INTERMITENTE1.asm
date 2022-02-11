
	ORG	0h
	clr	A
	mov	P1, A
Start:	setb	90h
	acall	WAIT
	clr	90h
	setb	91h
	acall	WAIT
	clr	91h
	setb	92h
	acall	WAIT
	clr	92h
	setb	93h
	acall	WAIT
	clr	93h
	setb	94h
	acall	WAIT
	clr	94h
	setb	95h
	acall	WAIT
	clr	95h
	setb	96h
	acall	WAIT
	clr	96h
	setb	97h
	acall	WAIT
	clr	97h
	setb	0h
	acall	WAIT
	setb	97h
	acall	WAIT
	clr	97h
	setb	96h
	acall	WAIT
	clr	96h
	setb	95h
	acall	WAIT
	clr	95h
	setb	94h
	acall	WAIT
	clr	94h
	setb	93h
	acall	WAIT
	clr	93h
	setb	92h
	acall	WAIT
	clr	92h
	setb	91h
	acall	WAIT
	clr	91h
	setb	90h
	acall	WAIT
	clr	90h
	ajmp	Start
	
WAIT:	mov	R1, #0FFh
label2:	mov	R2, #0FFh
	djnz	R2, $
	djnz	R1, label2
	ret

	END