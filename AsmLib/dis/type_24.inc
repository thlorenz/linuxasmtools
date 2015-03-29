  [section .text]
;*********** type24 ****************
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

;type s24 (s0e)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   da    000       fiadd dword immediate
;   da    001       fimul
;   da    010       ficom
;   da    011       ficomp
;   da    100       fisub
;   da    101       fisubr
;   da    110       fidiv
;   da    111       fidivr
;
;         c0-ff
;         mod/rm
;         ------
;   da    c0-c7     fcmovb st0-st7
;   da    c8-cf     fcmove st0-st7
;   da    d0-d7     fcmovbe st0-st7
;   da    d8-df     fcmovu st0-st7

;   da    e1        fucompp

type_s24:		;( s0e)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t14_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  call	decode_rm		;go decode mod rm
  jmp	t14_done
;handle opcodes with mod/rm in range c0-ff
t14_special:
  mov	edi,inst+1		;; this fails if lock infront !!
  cmp	bl,0e0h
  jae	t14_singles		;jmp if single instructions
;check for fcmovu
  mov	esi,_fcmovu
  cmp	bl,0d8h			;check if fld
  jae	t14_stuff		;jmp if fcmovu
  mov	esi,_fcmovbe
  cmp	bl,0d0h
  jae	t14_stuff
  mov	esi,_fcmove
  cmp	bl,0c8h
  jae	t14_stuff
  mov	esi,_fcmovb
;stuff opcode name
t14_stuff:
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
  jmp	t14_done
;handle "fucompp"
t14_singles:
  cmp	bl,0e9h			;check for fucompp
  jne	t14_error		;jmp if not fucompp
  mov	esi,_fucompp
  call	str_move
  mov	al,9
  stosb
  add	ebp,2
  jmp	t14_done
t14_error:
  or	byte [error_flag],1
  inc	ebp  

t14_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  
;------------------------------------------------------------------
