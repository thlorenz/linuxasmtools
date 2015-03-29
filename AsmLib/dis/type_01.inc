
  [section .text]
;***********    prefix processing type_01   ****************
;
;  input:  ebp = current opcode ptr
;          edi = stuff ptr
;          edx = ptr to decode_table entry
;              db zxyyyyyy  where z=opcode may have prefix flag
;                                 x=??  y=process index
;              db ?         bit for state_flag
;              dw name      index to opcode text (name)
;          ebx= decode_table entry loaded as dword
;  output: al = legal prefix's (prefix_flag) if done high bit is set
;------------------------------------------------------------------

;------------------------------------------------------------------
;type s01 - prefix
;         26h=es oper=20h->state_flag  02->warn_flag name -> last_prefix_name 
;         2eh=cs oper=20h                                    _xxx - registers
;         36h=ss 
;         3eh=ds 
;         64h=fs
;         65h=gs oper=20h->state_flag  02->warn_flag 
; opsize  66h    oper=10h 
; adrsize 67h    oper=08h->state_flag  08->>error_flag?
; escape  0fh    oper=40h 
; rep     f3h    oper=02h              (write rep to buffer)
; repne   f2h    oper=04h->state_flag  (write repne to buffer)
;
; Note: the lock prefix is not handled here, it is treated as
;       a single byte instruction.  Type_03
; lock    f0h    oper=01h->state_flag  (write lock to buffer)
type_s01:	;prefix register processing (no checking for legality)
;;  mov	bl,[edx+1]	;get flag
;check if this is a duplicate prefix
  test	byte [state_flag],bh
  jnz	t01_45		;jmp if duplicate (error)
;check if this prefix is in order
  cmp	bh,[state_flag]
  jb	t01_45		;jmp if prefix out of order
;check if prefix conflict with another prefix
  cmp	bh,4		;is this a rep prefix
  ja	t01_6		;jmp if not rep
  cmp	byte [state_flag],2 ;does state_flag have another rep?
  ja	t01_45		;jmp if two rep prefixes, (error)

;check if this is a segment override prefix
t01_6:
  mov	bl,[edx+2]	;get name index
  or	[state_flag],bh
  test	bh,20h		;segment prefix
  jz	t01_10		;jmp if not segment prefix
  mov	[last_prefix_name],bl
  mov	byte [warn_flag],02h	;set warning
  jmp	short t01_40
t01_10:
  cmp	bh,4
  ja	t01_40		;jmp if name not stored now
;move prefix name to buffer --
  xor	ecx,ecx
  mov	cl,bl
  add	ecx,names    	;compute string address
  mov	esi,ecx
  call	str_move
  mov	al,09h		;put tab after name
  stosb
t01_40:
  jmp	short t01_50
t01_45:
  or	byte [error_flag],08h
t01_50:
  xor	eax,eax		;set continuation flag
  ret

;------------------------------------------------------------------
