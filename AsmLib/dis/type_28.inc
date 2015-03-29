  [section .text]
;*********** type28 ****************
;
;inputs:
; [edx] = ptr to decode_table entry
; [ebp]= ptr to opcode d8 -> df
;   [ebp+1] mod/rm   xx,yyy,zzz
;          xx=mod yyy=opcode extension  zzz=register eax+
;          if mod/rm > bf then special cases
; edi = stuff ptr

;output: al 80h = done flag
;        al 7fh = legal prefixs 
;------------------------------------------------------------------

;------------------------------------------------------------------

;type s28 (s12)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   de    000       fiadd   word  s0e,0
;   de    001       fimul   word  s0e,1
;   de    010       ficom   word
;   de    011       ficomp  word
;   de    100       fisub   word
;   de    101       fisubr
;   de    110       fidiv   word
;   de    111       fidivr  word
;
;         c0-ff
;         mod/rm
;         ------
;   de    c0-c7     faddp st0-st7
;   de    c8-cf     fmulp st0-st7
;   de    d0-d7     -
;        
;   de    d9        fcomp

;   de    e0-e7     fsubrp st0-st7
;   de    e8-ef     fsubp st0-st7
;   de    f0-f7     fdivrp st0-st7
;   de    f8-ff     fdivp st0-st7

type_s28:		;( s12)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t18_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  mov	byte [skip_size_flag],4	;default state is word
;  test  byte [edx+1],10h	;is this frstor,fsave,fstsw
;  jz	t18_10			;jmp if not frstor...
;  mov	byte [skip_size_flag],1 ;turn off size stuff
t18_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t18_done
;handle opcodes with mod/rm in range c0-ff
t18_special:
  mov	edi,inst+1		;; this fails if lock infront
;check for stx style instructions
  mov	esi,_faddp
  cmp	bl,0c8h
  jb	t18_stuff		;jmp if ffree
  mov	esi,_fmulp
  cmp	bl,0d0h
  jb	t18_stuff
  cmp	bl,0d8h
  jb	t18_error
  mov	esi,_fstp
  cmp	bl,0d9h
  je	t18_fcompp
  cmp	bl,0e0h
  jb	t18_error
  mov	esi,_fsubrp
  cmp	bl,0e8h
  jb	t18_stuff
  mov	esi,_fsubp
  cmp	bl,0f0h
  jb	t18_stuff
  mov	esi,_fdivrp
  cmp	bl,0f8h
  jb	t18_stuff
  mov	esi,_fdivp

;stuff opcode name
t18_stuff:
  call	str_move
  mov	al,9
  stosb				;put tab after name

  mov	ax,'st'
  stosw				;store part of reg
  and	bl,7			;isolate register
  or	bl,'0'			;convert to ascii
  mov	al,bl
  stosb				;complete register code
;  mov	eax,',st0'
;  stosd
  add	ebp,2			;instruction size = 2
  jmp	t18_done

t18_fcompp:
  mov	esi,_fcompp
  call	str_move
  add	ebp,2
  jmp	short t18_done

t18_error:
  or	byte [error_flag],1
  inc	ebp  

t18_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  


