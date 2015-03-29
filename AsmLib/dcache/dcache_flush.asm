;---------------------------------------------------
;>1 dcache
;dcache_flush - write screen buffer to display
; INPUT
;   none
; OUTPUT
;   all image data not on screen is displayed.
; NOTE
;   source file = dcache_flush.asm
;<
;----------------------------------------------
  extern sys_write
  extern lib_buf
;  extern on_screen_cursor_index
  extern image
;  extern on_screen_color
  extern index_to_rowcol
  extern dcache_fd
  extern color_byte_expand
;
; register usage: ecx = buffer index (cursor)
;                 edx = screen index (screen cursor)
;                 esi = image buffer
;                 edi = stuff buffer ptr
;                 ebp = stuff buffer stop point
;
  global dcache_flush
dcache_flush:
  xor	ecx,ecx		;start index at 0
  mov	edx,-1		;[on_screen_cursor_index]
  mov	[on_screen_color],byte -1 ;set illegal color
  mov	esi,[image]
  mov	edi,lib_buf
  mov	ebp,lib_buf+700-14-10
;main loop
df_main_loop:
  mov	ax,[esi+ecx*2]
  or	al,al
  jz	df_flush_exit	;exit if end of image
;the data sign bit is set if data or color change
  jns	df_next_index	;skip if no changes
  or	ah,ah
  jns	df_stuff	;jmp if no color change
;stuff color
df_color_change:
  and	ah,7fh		;remove flag bit
  cmp	ah,[on_screen_color]
  je	df_stuff	;skip color update if ok
  mov	[on_screen_color],ah ;set new color
  push	eax
  push	esi
  push	ecx
  call	color_byte_expand	;only eax set (modified)
  mov	esi,eax
  mov	ecx,14
  rep	movsb
  pop	ecx
  pop	esi
  pop	eax 
;stuff char
df_stuff:
  cmp	ecx,edx		;is buf cursor = screen cursor?
  je	df_stuff2
;move cursor
  push	eax
  mov	eax,ecx
  call	index_to_rowcol
  push	esi
  push	edx
  push	ecx
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
  mov	esi,vt100_cursor
  mov	ecx,10
  pop	edi
  rep	movsb
  pop	ecx
  pop	edx
  pop	esi
  pop	eax
  mov	edx,ecx		;set on screen cursor
df_stuff2:
  and	al,7fh
  stosb			;store it
  inc	edx		;bump on screen cursor
;check if end of stuff buffer
  cmp	edi,ebp
  jb	df_reset_flags
  call	write_out_buf
  mov	edi,lib_buf ;restart stuff
;reset flags
df_reset_flags:
  and	[esi+ecx*2],word ~8080h  ;reset flags
df_next_index:
  inc	ecx
  jmp	df_main_loop
df_flush_exit:
  call	write_out_buf
;  mov	[on_screen_cursor_index],edx
  ret
;---------------------------------------------------
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
  db	0		;end of string
  
 [section .text]
;---------------------------------------------------
write_out_buf:
  push  ecx
  push	edx
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx		;compute accumulations
  mov	ebx,[dcache_fd]
  call	sys_write
  pop	edx
  pop	ecx
  ret

;----------------
  [section .data]
;set impossible values to force program action
;on_screen_cursor_index	dd -1
on_screen_color		dd -1
  [section .text]
