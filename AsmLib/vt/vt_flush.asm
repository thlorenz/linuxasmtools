;---------------------------------------------------
;>1 vt
;vt_flush - write screen buffer to display
; INPUT
;   none
; OUTPUT
;   all image data not on screen is displayed.
; NOTE
;   source file = vt_flush.asm
;<
;----------------------------------------------
  [section .text align=1]

  extern sys_write
  extern lib_buf
  extern crt_columns
  extern vt_top_left_col
  extern vt_image
  extern vt_top_row
  extern vt_fd
  extern color_byte_expand
  extern quick_ascii
  extern vt_columns
  extern vt_stuff_col,vt_stuff_row
;
; register usage: ecx = buffer row(ah) column(al) 1+
;                 edx = screen row(ah) column(al) 1+
;                 esi = vt_image buffer
;                 edi = stuff buffer ptr
;                 ebp = stuff buffer stop point
;
  global vt_flush
vt_flush:
  mov	al,[crt_columns]
  sub	al,[vt_top_left_col]	;compute rel end col
  mov	[end_column],al

  mov	[vt_on_screen_color],byte 0 ;illegal color to force setting
  xor	edx,edx		;start at illegal row/col or 0/0
  mov	ecx,dword 0101h	;start at row(ah)=1 column(al)=1
  mov	esi,[vt_image]
  mov	edi,lib_buf
  mov	ebp,lib_buf+700-14-10
;main loop
df_main_loop:
  lodsw			;get buffer data
  or	al,al
  jz	df_flush_exit	;exit if end of vt_image
  or	ah,ah
;the data sign bit is set if data or color change
  jns	df_next_index	;skip if no changes
;;  or	ah,ah
;;  jns	df_stuff	;jmp if no color change
;color change check
df_color_change:
  and	ah,7fh		;remove flag bit
  cmp	ah,[vt_on_screen_color]
  je	df_stuff	;skip color update if ok
  mov	[vt_on_screen_color],ah ;set new color
;set new color
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
;cursor location check
df_stuff:
  cmp	ecx,edx		;is cursor at correct row/col?
  je	df_stuff2
;move cursor -start-
  push	eax
  push	esi
  push	edx
  push	ecx
  push	edi
  mov	word [vtrow],'00'
  mov	word [vtcolumn],'00'
  mov	edi,vtcolumn+2
  mov	eax,ecx		;get col
  add	al,[vt_top_left_col]	;adjust window
  push	ecx		;save row/col
  call	quick_ascii
  pop	eax		;get row/col
  xchg	ah,al
  add	al,[vt_top_row]	;adjust window
  mov	edi,vtrow+2
  call	quick_ascii
  mov	esi,vt_100_cursor
  mov	ecx,10
  pop	edi
  rep	movsb
  pop	ecx
  pop	edx
  pop	esi
  pop	eax
  mov	edx,ecx		;set on screen cursor
;move cursor -end-
df_stuff2:
  cmp	cl,[end_column]
  ja	df_skip		;jmp if beyond right edge   
  stosb			;store it
  inc	edx		;bump on screen cursor (col may overflow here)
df_skip:
;check if end of stuff buffer
  cmp	edi,ebp
  jb	df_reset_flags
  call	write_out_buf
  js	vf_exit
  mov	edi,lib_buf ;restart stuff
;reset flags
df_reset_flags:
  and	[esi-2],word ~8000h  ;reset flags
df_next_index:
  inc	cl		;bump column 
  cmp	cl,[vt_columns]	;end of column?
  jbe	df_main_loop	;jmp if column ok
  mov	cl,1		;go to column 1
  inc	ch		;bump row
  jmp	df_main_loop
df_flush_exit:
;move cursor to correct screen location

;  push	edx
;  push	ecx
  push	edi
  mov	word [vtrow],'00'
  mov	word [vtcolumn],'00'
  mov	edi,vtcolumn+2
  mov	al,[vt_stuff_col]	;get col
  add	al,[vt_top_left_col]	;adjust window
  call	quick_ascii
  mov	al,[vt_stuff_row]
  add	al,[vt_top_row]	;adjust window
  mov	edi,vtrow+2
  call	quick_ascii
  mov	esi,vt_100_cursor
  mov	ecx,10
  pop	edi
  rep	movsb
;  pop	ecx
;  pop	edx

  call	write_out_buf
vf_exit:
  ret
;---------------------------------------------
  [section .data]
vt_100_cursor:
  db	1bh,'['
vtrow:
  db	'000'		;row
  db	';'
vtcolumn:
  db	'000'		;column
  db	'H'
vt_100_end:
  db	0		;end of string
  
 [section .text]
;---------------------------------------------------
write_out_buf:
  push  ecx
  push	edx
  mov	ecx,lib_buf
  mov	edx,edi
  sub	edx,ecx		;compute accumulations
  mov	ebx,[vt_fd]
  call	sys_write
  pop	edx
  pop	ecx
  ret

  [section .data]
vt_on_screen_color	db 0
end_column	db	0
  [section .text]


