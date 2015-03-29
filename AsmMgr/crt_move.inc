
;****f* crt/move_cursor *
; NAME
;>1 crt
;  move_cursor - move cursor
; INPUTS
;     al = column (1-xx)
;     ah = row    (1-xx)
; OUTPUT
;    cursor placed on screen
; NOTES
;    source file crt_move.asm
;    This function moves the cursor by sending vt100
;    escape commands to crt.
;<
;  * ----------------------------------------------
;*******
  global move_cursor
move_cursor:
  push	edi
  push	eax
  mov	word [vt_row],'00'
  mov	word [vt_column],'00'
  mov	edi,vt_column+2
  call	quick_ascii
  pop	eax
  xchg	ah,al
  mov	edi,vt_row+2
  call	quick_ascii
  mov	ecx,vt100_cursor
  mov	eax,4
  mov	edx,vt100_end - vt100_cursor
  mov	ebx,1		;stdout
  int	byte 80h
  pop	edi
  ret
;-------------------------------------
; input: al=ascii
;        edi=stuff end point
quick_ascii:
  push	byte 10
  pop	ecx
  and	eax,0ffh		;isolate al
to_entry:
  xor	edx,edx
  div	ecx
  or	dl,30h
  mov	byte [edi],dl
  dec	edi  
  or	eax,eax
  jnz	to_entry
  ret
;---------------------------------------------
  [section .data]
vt100_cursor:
  db	1bh,'['
vt_row:
  db	'000'		;row
  db	';'
vt_column:
  db	'000'		;column
  db	'H',0
vt100_end:
  
 [section .text]

%ifdef DEBUG
  global _start
_start:
  mov	al,100		;column
  mov	ah,1		;row
  call	move_cursor
  mov	eax,1
  int	80h
%endif
	