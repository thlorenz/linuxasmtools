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

;type s26  (s10)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   dc    000       fadd qword   ;s10,0
;   dc    001       fmul
;   dc    010       fcom
;   dc    011       fcomp
;   dc    100       fsub
;   dc    101       fsubr
;   dc    110       fdiv
;   dc    111       fdivr
;
;         c0-ff
;         mod/rm
;         ------
;   dc    c0-c7     fadd st0-st7,st0
;   dc    c8-cf     fmul st0-st7,st0
;   dc    d0-d7     -
;   dc    d8-df     -
;   dc    e0-e7     fsubr st0-st7,st0
;   dc    e8-ef     fsub  st0-st7,st0
;   dc    f0-f7     fdivr st0-st7,st0
;   dc    f8-ff     fdiv  st0-st7,st0

type_s26:		;( s10)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t16_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  mov	byte [skip_size_flag],3 ;turn on "qword" stuff
t16_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t16_done
;handle opcodes with mod/rm in range c0-ff
t16_special:
  mov	edi,inst+1		;; this fails if lock infront !!
;check for stx style instructions
  mov	esi,_fadd
  cmp	bl,0c8h
  jb	t16_stuff		;jmp if fcmovu
  mov	esi,_fmul
  cmp	bl,0d0h
  jb	t16_stuff
  cmp	bl,0e0h
  jb	t16_error
  mov	esi,_fsubr
  cmp	bl,0e8h
  jb	t16_stuff
  mov	esi,_fsub
  cmp	bl,0f0h
  jb	t16_stuff
  mov	esi,_fdivr
  cmp	bl,0f8h
  jb	t16_stuff
  mov	esi,_fdiv

;stuff opcode name
t16_stuff:
  call	str_move
  mov	al,9
  stosb				;put tab after name

  mov	ax,'st'
  stosw				;store part of reg
  and	bl,7			;isolate register
  or	bl,'0'			;convert to ascii
  mov	al,bl
  stosb				;complete register code
  mov	eax,',st0'
  stosd
  add	ebp,2			;instruction size = 2
  jmp	t16_done
t16_error:
  or	byte [error_flag],1
  inc	ebp  

t16_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  
