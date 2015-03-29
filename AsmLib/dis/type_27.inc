  [section .text]
;*********** type_27 ****************
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

;type s27 (s11)
;
;         0-bf
; opcode  mod/rm
;         nnn bits
; ------  ------
;   dd    000       fld      qword 
;   dd    001       -   
;   dd    010       fst      qword 
;   dd    011       fstp     qword 
;   dd    100       frstor   98-108 bytes
;   dd    101       -    
;   dd    110       fsave    98-108 bytes
;   dd    111       fstsw    2 bytes
;
;         c0-ff
;         mod/rm
;         ------
;   dd    c0-c7     ffree st0-st7
;   dd    c8-cf     -
;   dd    d0-d7     fst st0-st7
;   dd    d8-df     fstp st0-st7
;   dd    e0-e7     fucom st0-st7
;   dd    e8-ef     fucomp st0-st7
;   dd    f0-f7     -
;   dd    f8-ff     -

type_s27:		;( s11)
  mov	bl,byte [ebp+1]		;get mod/rm byte
  cmp	bl,0c0h			;check mod/rm value
  jae	t17_special		;jmp if special processing
;handle all opcode with mod/rm in range 0-bf
  mov	byte [skip_size_flag],3	;default state is qword
  test  byte [edx+1],10h	;is this frstor,fsave,fstsw
  jz	t17_10			;jmp if not frstor...
  mov	byte [skip_size_flag],1 ;turn off size stuff
t17_10:
  call	decode_rm		;go decode mod rm
  mov	byte [skip_size_flag],0	;enable stuff of size in decode_rm
  jmp	t17_done
;handle opcodes with mod/rm in range c0-ff
t17_special:
  mov	edi,inst+1		;; this fails if lock
;check for stx style instructions
  mov	esi,_ffree
  cmp	bl,0c8h
  jb	t17_stuff		;jmp if ffree
  cmp	bl,0d0h
  jb	t17_error
  mov	esi,_fst
  cmp	bl,0d8h
  jb	t17_stuff
  mov	esi,_fstp
  cmp	bl,0e0h
  jb	t17_stuff
  mov	esi,_fucom
  cmp	bl,0e8h
  jb	t17_stuff
  mov	esi,_fucomp
  cmp	bl,0f0h
  jae	t17_error

;stuff opcode name
t17_stuff:
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
  jmp	t17_done
t17_error:
  or	byte [error_flag],1
  inc	ebp  

t17_done:
  mov	al,0ah
  stosb
  mov	al,80h			;get done code
  ret  

