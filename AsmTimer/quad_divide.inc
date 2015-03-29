;>1 math
;  quad_divide - divide 64 bit values
; INPUTS
;   edx,eax divided by ebx;
; OUTPUT:
;   edx,eax = result
; NOTES
;   source file: quad_divide.asm
;<
; * ----------------------------------------------
  global quad_divide:
quad_divide:
     	push	ecx
	xchg	ecx,edx
	xchg	eax,ecx
	sub	edx,edx
	cmp	edx,ebx		;added
	jnb	qd_error	;added
	div	ebx
	xchg	ecx,eax
	cmp	edx,ebx		;added
	jnb	qd_error	;added
	div	ebx
	mov	edx,ecx
qd_error:
	pop	ecx
	ret
;--------------------------------

;sample code to test for overflow
;	cmp	dx,bytes_per_sectordivide;
;	jnb	divide_err5divide
;	div	bytes_per_sector		;convert to packet countdivide
