  [section .text]
;*********** type25 ****************
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

;type s25 (s0f)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   db    000       fild 
;   db    001       -   
;   db    010       fist
;   db    011       fistp
;   db    100       -    
;   db    101       fld  
;   db    110       -   
;   db    111       fstp 
;
;         c0-ff
;         mod/rm
;         ------
;   db    c0-c7     fcmovnb st0-st7
;   db    c8-cf     fcmovne st0-st7
;   db    d0-d7     fcmovnbe st0-st7
;   db    d8-df     fcmovnu st0-st7

;   db    e2        fclex stx
;   db    e3        finit stx

;   db    e8-ef     fucomi st0-st7
;   db    f0-f7     -
;   db    f8-ff     -

type_s25:		;( s0f)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t15_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  test  byte [edx+1],10h	;is this fldenv,fldcw,fnstenv,fnstcw?
  jz	t15_10			;jmp if not fldenv...
  mov	byte [skip_size_flag],2 ;turn on "tword" stuff
t15_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t15_done
;handle opcodes with mod/rm in range c0-ff
t15_special:
  mov	edi,inst+1		;; this fails if lock infront
  cmp	bl,0e2h
  je	t15_fnclex
  cmp	bl,0e3h
  je	t15_fninit
;check for stx style instructions
  mov	esi,_fcmovnb
  cmp	bl,0c8h
  jb	t15_stuff		;jmp if fcmovu
  mov	esi,_fcmovne
  cmp	bl,0d0h
  jb	t15_stuff
  mov	esi,_fcmovnbe
  cmp	bl,0d8h
  jb	t15_stuff
  mov	esi,_fcmovnu
  cmp	bl,0e0h
  jb	t15_stuff

  cmp	bl,0f8h
  jae	t15_error
  mov	esi,_fcomi
  cmp	bl,0f0h
  jae	t15_stuff
  mov	esi,_fucomi
  cmp	bl,0e8h
  jb	t15_error

;stuff opcode name
t15_stuff:
  call	str_move
  mov	al,9
  stosb				;put tab after name

  mov	ax,'st'
  stosw				;store part of reg
  and	bl,7			;isolate register
  or	bl,'0'			;convert to ascii
  mov	al,bl
  stosb				;complete register code
  add	ebp,2			;instruction size = 2
  jmp	t15_done
;handle "fucompp"
t15_fnclex:
  mov	esi,_fnclex
  jmp	short t15_sstuff
t15_fninit:
  mov	esi,_fninit
t15_sstuff:
  call	str_move
  mov	al,9
  stosb
  add	ebp,2
  jmp	t15_done
t15_error:
  or	byte [error_flag],1
  inc	ebp  

t15_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  


