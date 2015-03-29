  [section .text]
;*********** type12_19 opcode groups (types) ****************
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

;type s29 (s13)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   df    000       fidd  word   s13,0
;   df    001       -
;   df    010       fist  word   s13,2
;   df    011       fistp word   s13,3
;   df    100       fbld  bcd    s13,4
;   df    101       fild  qword  s13,5
;   df    110       fbstp bcd    s13,6
;   df    111       fistp qword  s13,7
;
;         c0-ff
;         mod/rm
;         ------
;   df    c0-c7     -
;   df    c8-cf     -
;   df    d0-d7     -
;   df    d8-df     -
;   df    e0        fstsw ax    
;   df    e8-ef     fucomip st0-st7
;   df    f0-f7     fcomip st0-st7
;   df    f8-ff     -

type_s29:		;( s13)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t19_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  mov	byte [skip_size_flag],4	;default state is word
  test  byte [edx+1],10h	;is this frstor,fsave,fstsw
  jz	t19_10			;jmp if not frstor...
  mov	byte [skip_size_flag],1 ;turn off size stuff
  test	byte [edx+1],4
  jz	t19_10			;jmp if no size
  mov	byte [skip_size_flag],3 ;force qword  
t19_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t19_done
;handle opcodes with mod/rm in range c0-ff
t19_special:
  mov	edi,inst+1		;; this fails if lock prefix
;check for stx style instructions
  mov	esi,_fnstsw
  cmp	bl,0e0h
  jne	t19_20			;jmp if not   fstsw
  call	str_move
  mov	eax,' ax '
  stosd
  add	ebp,2
  jmp	t19_done

t19_20:
  cmp	bl,0e8h
  jb	t19_error
  mov	esi,_fucomip
  cmp	bl,0f0h
  jb	t19_stuff
  mov	esi,_fcomip
  cmp	bl,0f8h
  jae	t19_error

;stuff opcode name
t19_stuff:
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
  jmp	t19_done

t19_error:
  or	byte [error_flag],1
  inc	ebp  

t19_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  


;------------------------------------------------------------------

