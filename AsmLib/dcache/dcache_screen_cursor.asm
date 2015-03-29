;---------------------------------------------------
;>1 dcache
;dcache_screen_cursor - set buffer cursor and display cursor
; INPUT
;   al=column 1+  ah=row 1+
; OUTPUT
;
; NOTE
;<
;--------------------------------------------------

  extern dcache_buf_cursor
  extern dcache_fd

  global dcache_screen_cursor
dcache_screen_cursor:
  push	eax
  call	move_cursor
  pop	eax
  call	dcache_buf_cursor
  ret

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
  mov	ebx,[dcache_fd]
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
  db	'H'
vt100_end:
  
 [section .text]
