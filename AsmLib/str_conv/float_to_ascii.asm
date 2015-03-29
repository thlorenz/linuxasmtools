;--------------- file: float_to_ascii.asm ----------------------------

  extern dword_to_ascii
;------------------------------------------------------------------------
;build_mantissa - inputs: ebx = precision (1-10 number of output digits in mantissa)
;                         eax = ptr to qword floating value
build_mantissa:
  mov	[prec],ebx
	fstcw [cw]	;get control word
;;; If prec is 0 we need to round, if not we truncate
	or [cw],word 0000110000000000b ;
  	cmp [prec],dword 0 ;check prec
  	jne .trunc	;jmp if prec entered
  	and [cw],word 1111001111111111b ;prec=0 (control word ->no truncate)
.trunc:
	fldcw [cw]	;save control word
;;; Integer part
	fld qword [eax] ;move to st0
	fist dword [var] ;integer part -> var
	fxam		;examine stack top
	fstsw ax	;status word -> ax
	and ah,10b	;check sign
	jz .positive	;jmp if +
	fchs		;change sign
  mov	al,'-'
  stosb			;store minus
.positive:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This handles numbers from -2147483648 to 2147483648
	fist dword [var]	;integer part -> var
	fisub dword [var]	;integer subtract
  mov	eax,[var]	;get integer
  call	dword_to_ascii	;store integer part
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Decimal part
	mov ecx,[prec]	;get prec
	cmp ecx,0	;prec= 0
	je near .end	;jmp if prec=0
  mov	al,'.'
  stosb		;store decmal point
.loop:
	cmp [prec],dword 0 ;prec=0?
	je near .end	   ;jmp if prec=0
	cmp [prec],dword 9 ;prec=9?
	jb .doit	   ;jmp if prec 1-8
	sub [prec],dword 9 ;prec-9
	mov [prec2],dword 9 ;set prec2=9
	mov [mult],dword 1000000000 ;mult = 1000000000
	jmp short .doit2
.doit:
	push ecx	;save original prec
	mov ecx,[prec]	;get adjusted prec
	mov eax,1
.doit0:
	imul eax,10
	dec ecx		;dec precision
	jnz .doit0	;jmp if prec=0
	pop ecx
	mov [mult],eax	;save mult
	mov eax,[prec]	;get prec
	mov [prec2],eax ;save as prec2
	mov [prec],dword 0 ;prec-> 0
	and [cw],word 1111001111111111b	; Only round the last decimal
	fldcw [cw]	;set control word
.doit2:
	fimul dword [mult] ;multiply by mult
	fist dword [var]  ;integer part to var
	call .wrtint	;go write int
	fisub dword [var] ;subtract var
	jmp .loop
.end:
	ret
;--------------------------------------
.wrtint:
	mov ecx,[prec2] ;get prec2
	mov eax,[var]	;get var
	mov ebx,10	;base for decimal
.wrtint2:
  xor	edx,edx	;zero edx
  div ebx
  push edx
  dec ecx
  jnz short .wrtint2
  mov ecx,[prec2] ;get prec2
.wrtint3:
  pop eax
  or	al,'0'	;convert to ascii
  stosb		;store number char
  dec ecx		;dec prec2
  jnz short .wrtint3 ;loop till all char. stored
  ret
;---------------------------
  [section .data]
prec		dd 0 ;input precision
var		dd 0 ; ebp-4
cw		dd 0 ; ebp-12
var2		dd 0 ; ebp-20
mult		dd 0 ; ebp-24
prec2		dd 0 ; ebp-28
  [section .text]
;-------------------------------------------------------------------
;>1 str_conv
;   fdword_to_ascii - convert dword float to ascii string
; INPUTS
;    eax = ptr to dword float value
;    ebx = precision (output mantissa chars 1-10)
;    edi = storage buffer for ascii
; OUTPUT
;    edi = ptr beyond last ascii char in buf
;    st(x) all floating registers are cleared
;          using the finit instruction at exit
; NOTES
;    file float_to_ascii.asm
;<
;-----------------------------------------------
  global fdword_to_ascii
fdword_to_ascii:
  fld	dword [eax]
  jmp	short fst0_to_ascii
;-------------------------------------------------------------------
;>1 str_conv
;   fqword_to_ascii - convert qword float to ascii string
; INPUTS
;    eax = ptr to dword float value
;    ebx = precision (output mantissa chars 1-10)
;    edi = storage buffer for ascii
; OUTPUT
;    edi = ptr beyond last ascii char in buf
;    st(x) all floating registers are cleared
;          using the finit instruction at exit
; NOTES
;    file float_to_ascii.asm
;<
;-----------------------------------------------
  global fqword_to_ascii
fqword_to_ascii:
  fld	qword [eax]
  jmp	short fst0_to_ascii
;-------------------------------------------------------------------
;>1 str_conv
;   ftword_to_ascii - convert tword float to ascii string
; INPUTS
;    eax = ptr to dword float value
;    ebx = precision (output mantissa chars 1-10)
;    edi = storage buffer for ascii
; OUTPUT
;    edi = ptr beyond last ascii char in buf
;    st(x) all floating registers are cleared
;          using the finit instruction at exit
; NOTES
;    file float_to_ascii.asm
;<
;-----------------------------------------------
  global ftword_to_ascii
ftword_to_ascii:
  fld	tword [eax]
;-------------------------------------------------------------------
;>1 str_conv
;   fst0_to_ascii - convert fst0 to ascii string
; INPUTS
;    ebx = precision (output mantissa chars 1-10)
;    edi = storage buffer for ascii
; OUTPUT
;    edi = ptr beyond last ascii char in buf
;    st(x) all floating registers are cleared
;          using the finit instruction at exit
; NOTES
;    file float_to_ascii.asm
;<
;-----------------------------------------------

;;; Remember: loga(u) = loga(b) * logb(u)      :: log10(x) = log10(2) * log2(x)
;;; and: x^r = (a^loga(x))^r = a^(r * loga(x)) :: 10^x = 2^(x*log2(10))
;--------------------
  global fst0_to_ascii
fst0_to_ascii:
  mov	[_prec],ebx
;;; w +/-?
;;; -:	set _flag, x=neg w
	mov [_flag],dword 0  ;set flag=0
	fxam	;examine stack
	fstsw ax	;get control word
	and ah,10b	;_reg positive
	jz .positive	;jmp if _reg +
	mov [_flag],dword 1 ;set negative flag
	fchs	;change sign
.positive:
	fld st0	;set st0
;;; y=rount(log10(x))
	fldlg2		;log10
	fxch st1	;log10
	fyl2x		;log10

	frndint		;round integer
	fist dword [_var] ;integer -> _var

;;; z=x/(10^y)
;;;* m_exp10: Compute st0 = 10^st0
;;;*
;;;*  x^r = (a^loga(x))^r = a^(r * loga(x))
;;;*  10^x = 2^(x*log2(10))
;;;*
	fldl2t	;start st0=10^st0
	fmulp st1
	fld st0
	frndint
	fsub st1,st0
	fxch st1
	f2xm1
	fld1
	faddp st1
	fscale
	fstp st1	;end st0=10^st0

	fdivp st1	;divide st1

;;; if _flag, neg z
	cmp [_flag],dword 1 ;negative?
	jne .pos	;jmp if +
	fchs		;change sign
.pos:

;;; WriteFloat (_prec) z
	fstp qword [_var2]	;ingeger -> _var2
	lea eax,[_var2]		;get adr of _var2

  mov	ebx,[_prec]
  call	build_mantissa

;;; Write e
  mov	al,'E'
  stosb		;store E
;;; WriteInt y
	mov eax,dword [_var] ;get _var
	cmp eax,0
	jnl .wrty	;jmp if +
	neg eax	;adjust sign
	push eax
  mov	al,'-'
  stosb	;store sign -
	pop eax
.wrty:
;       ;write eax ???
;	WriteInt dword [_fd], eax
  call	dword_to_ascii
.end:
  finit
	ret
;---------------------------------------------------
  [section .data]
_var		dd 0	;variable
_var2		dq 0	;variable2
_flag		dd 0	;sign flag
_prec		dd 0	;precision

%ifdef TEST
;----------------------------------------------------
  [section .data]
test_value1 dq 1234.5678
test_value2 dq -0.000012345678
test_dword  dd	1234.1234
test_qword  dq  4321.4321
test_tword  dt	1111.2222
  [section .text]
;------------------
  extern lib_buf

  global main,_start

_start:
main:
  lea	eax,[test_dword]
  mov	ebx,8
  mov	edi,lib_buf
  call	fdword_to_ascii

  lea	eax,[test_qword]
  mov	ebx,8
  mov	edi,lib_buf
  call	fqword_to_ascii

  lea	eax,[test_tword]
  mov	ebx,8
  mov	edi,lib_buf
  call	ftword_to_ascii

  fld	qword [test_value1]
  mov	ebx,8	;precision
  mov	edi,lib_buf ;storage buffer
  call	fst0_to_ascii

  fld	qword [test_value2]
  mov	ebx,8	;precision
  mov	edi,lib_buf ;storage buffer
  call	fst0_to_ascii

  mov	eax,dword 1
  int	80h

%endif