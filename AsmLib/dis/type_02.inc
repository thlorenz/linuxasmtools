
  [section .text]
;***********   type_02 processing ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=opcode may have prefix flag
;                                 x=??  y=process index
;              db ?         unused
;              dw name      index to opcode text (name)
;          ebx = decode_table entry
;                
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s02 - inc,dec,push,pop  with assumed register
;
; opcode  prefix  prefix 66     prefix 66
;         flag    inactive*     active
; ------  ------  -----------   -------------
; 40+ inc    p     inc REG32        inc reg16
; 48+ dec    p     dec REG32        dec reg16
; 50+ push   p     push REG32       push reg16  <-- warning with reg16
; 58+ pop    p     pop FEG32        pop reg16   <-- warning with reg16
;  *note: upper case is data provided as coded byte
;
type_s02:	;assumed register types
  xor	ebx,ebx
  mov	bl,[ebp]		;get opcode
  and	bl,07h			;convert to register code
  test	byte [state_flag],10h	;check if prefix 66h active
  mov	bh,-1			;preload code for eax.ecx,edx,etc
  jz	t02_40			;jmp if no prefix action
  mov	bh,-2			;convert eax->ax  ebx->bx
t02_20:
  cmp	byte [ebp],50h
  jb	t02_40			;jmp if not push/pop
  or	byte [warn_flag],08h
t02_40:
  call	stuff_reg		;cx=opcode index  bl=register index
  mov	al,0ah
  stosb				;terminate string
  mov	al,80h + 10h		;signal done + prefix 66h legal
  inc	ebp			;move to next instruction byte
  ret    

;------------------------------------------------------------------
