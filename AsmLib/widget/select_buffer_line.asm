
;   Copyright (C) 2007 Jeff Owens
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


  [section .text align=1]
  extern mouse_enable
  extern crt_window  
  extern crt_line
  extern key_decode1
  extern read_stdin
  extern kbuf
;----------------------
;>1 widget
;   select_buffer_line - view a buffer and select line
; INPUTS
;    esi = data block (see crt_window also)
;        dd color list
;        dd win top ptr (buffer)
;        dd buffer end
;        dd scroll
;        db columns in window
;        db rows in window
;        db starting row
;        db starting col
;        dd select line ptr
;        dd select ptr color
;
; OUTPUT
;    eax = zero if no selection was made
;        = ptr to start of selected row
; NOTES
;    file select_buffer_line.asm
;<
;  * ---------------------------------------------------
;*******
  global select_buffer_line
select_buffer_line:
  cld
  push	esi			;save block ptr
;move input block to our database
  mov	edi,in_block
  mov	ecx,in_block_end - in_block
  rep	movsb
;setup window colors
  pop	esi			;get block ptr
  mov	eax,[esi]		;get color
;  mov	[color_lst],eax	;set color 1
;  mov	[color],eax		;set color 1
  mov	eax,[c_select_color]
;  mov	[color_lst+4],eax	;set color 2
;setup window size and location
  mov	al,[c_win_rows]
  mov	[menu_line_row],al
  dec	byte [c_win_rows]	;shrink window by 1
  call	mouse_enable
  mov	ebp,[win_top_ptr]
  mov	[buffer],ebp
display_lp1:
  mov	esi,in_block
  call	crt_window
; add button line at end
fb_buttons:
  mov	ebx,color_lst
  mov	ch,[menu_line_row]
  mov	cl,[c_start_col]		;starting column
  mov	dl,[c_win_cols]
  mov	esi,button_row
  xor	edi,edi			;set scroll to 0
  call	crt_line
;highlight select bar
  call	find_bar_row		;set ch=row
  mov	ebx,color_lst+4
  mov	cl,[c_start_col]	;starting column
  mov	dl,[c_win_cols]
  dec	dl
  mov	esi,[select_bar_ptr]
  mov	edi,4   		;set scroll to 4
  call	crt_line
; get keyboard input
fb_ignore:
  call	read_stdin
  cmp	byte [kbuf],-1		;check if mouse
  je	fb_mouse
;decode key
  mov	esi,key_decode_table3
  call	key_decode1
  jmp	short fb_cont
;decode mouse click
fb_mouse:
  mov	bl,[kbuf+2]		;get mouse column
  mov	bh,[kbuf+3]		;get mouse row
  dec	bh			;convert row to zero based
  cmp	bh,[c_win_rows]		;is this the button line
  je	fb_button
  call	mouse_decode
  jmp	short fb_exit
;click was on button (menu) line
fb_button:
  xor	eax,eax			;indicate no selection
  jmp	short fb_exit
fb_cont:
  call	eax
  cmp	al,-1
  je	display_lp1
fb_exit:
  ret
;---------------------------------
; output: ch = select bar row
;
find_bar_row:
  mov	ch,[c_start_row]	;
  dec	ch
  mov	esi,[win_top_ptr]
  mov	edi,[select_bar_ptr]
  mov	cl,[c_win_rows]		;last row
fbr_lp1:
  inc	ch			;bump row
  cmp	ch,cl			;check if end of display
  je	fbr_exit		;exit if end of display
fbr_lp2:
  cmp	esi,edi
  jae	fbr_exit		;jmp if bar found
  lodsb
  cmp	al,0ah
  je	fbr_lp1			;loop if next line found
  cmp	esi,[buf_end_ptr]
  jb	fbr_lp2			;loop if still looking for line end
fbr_exit:
  ret

;---------------------------------
fb_up:
  mov	esi,[select_bar_ptr]
  cmp	esi,[win_top_ptr]
  jne	fb_up2
  cmp	esi,[buffer]
  je	fb_up_exit			;jmp if at top
  call	prev_line
  mov	[win_top_ptr],esi
fb_up2:
  mov	esi,[select_bar_ptr]
  call	prev_line
  mov	[select_bar_ptr],esi
fb_up_exit:
  mov	al,-1   
  ret

;-----------------------
fb_down:
  call	find_bar_row
  cmp	ch,[c_win_rows]
  jb	fb_down1
  mov	esi,[win_top_ptr]
  call	next_line
  mov	[win_top_ptr],esi
fb_down1:
  mov	esi,[select_bar_ptr]
  call	next_line
  mov	[select_bar_ptr],esi
  mov	al,-1
  ret

;-----------------------
fb_pgup:
  xor	ecx,ecx
  mov	cl,[c_win_rows]
  mov	esi,[win_top_ptr]
fbp_lp:
  call	prev_line
  dec	ecx
  jnz	fbp_lp
  mov	[win_top_ptr],esi
  mov	[select_bar_ptr],esi
  mov	al,-1
  ret

;-----------------------
fb_pgdn:
  xor	ecx,ecx
  mov	cl,[c_win_rows]
  mov	esi,[win_top_ptr]
fbpg_lp:
  call	next_line
  jc	at_bottom
  dec	ecx
  jnz	fbpg_lp
  jmp	fbpg_exit
at_bottom:
  call	prev_line
fbpg_exit:
  mov	[win_top_ptr],esi
  mov	[select_bar_ptr],esi
  mov	al,-1
  ret  
;-----------------------
enter_key:
  mov	eax,[select_bar_ptr]
  ret
;-----------------------
quit:
  xor	eax,eax
  ret
;-----------------------
unknown_key:
  mov	al,-1
  ret
;----------------------------------------------
; input: esi = ptr to line start
; output: esi = ptr to next line
;         carry = at top now
;        no-carry = not at top
;
prev_line:
  cmp	esi,[buffer]
  jbe	pl_top
  dec	esi
  cmp	esi,[buffer]
  je	pl_top
  cmp	byte [esi -1],0ah
  jne	prev_line
  clc
  jmp	short pl_exit
pl_top:
  stc
pl_exit:
  ret
  
;----------------------------------------------
; input: esi = ptr to current line start
; output: esi = ptr to next line
;         carry = at bottom 
next_line:
  cmp	esi,[buf_end_ptr]
  jae	nl_end		;jmp if at end
  lodsb
  cmp	al,0ah
  jne	next_line
  clc
  jmp	short nl_exit
nl_end:
  stc	
nl_exit:
  ret

;----------------------------------------------
;find text at mouse click
;
; input; ebp=top of display
;        bh=row 0 based
;        [c_win_rows] = row with button line, zero based
; output: eax = start of line where click occured
;               else zero if click elsewhere
;
mouse_decode:
  mov	esi,[win_top_ptr]
  inc	bh			;make row 1 based
md_loop1:
  dec	bh			;decrement row
  jz	mk_got			;jmp if click row found
md_loop2:
  lodsb
  cmp	al,0ah
  je	md_loop1		;jmp if end of line
  cmp	esi,[buf_end_ptr]
  jb	md_loop2		;loop if more data
  xor	eax,eax
  jmp	short mk_end
mk_got:
  mov	eax,esi
mk_end:
  ret  
;----------------------------------------------

button_row:
 db 1,' move select ptr and select with <click> or ',2,'Enter',1,' ',2,'ESC=cancel',1,0


key_decode_table3:
  dd	unknown_key	;alpha key

  db 1bh,5bh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd fb_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd fb_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd fb_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd fb_down

  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd fb_pgup

  db 1bh,4fh,79h,0		;16 pad_pgup
  dd fb_pgup

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd fb_pgdn

  db 1bh,4fh,73h,0		;21 pad_pgdn
  dd fb_pgdn

  db 1bh,0			;ESC
  dd quit

  db 0dh,0			;enter key
  dd enter_key

  db 0ah,0			;enter key
  dd enter_key

  db 0		;enc of table
  dd unknown_key ;unknown key trap

  
;----------------------------------------------
  [section .data]

in_block:				;inputs for crt_window
color		dd	30003734h
win_top_ptr	dd	0	;current window top line ptr
buf_end_ptr	dd	0
scroll		dd	0
c_win_cols	db	0	;win columns
c_win_rows	db	0	;win rows
c_start_row	db	0
c_start_col	db	0
select_bar_ptr	dd	0	;ptr to select bar line
c_select_color  dd	0	;color for select line
in_block_end:

buffer		dd	0


color_lst:
 dd	30003634h	;1
 dd	30003436h	;2
 dd	31003037h	;3

menu_line_row	db	0
;----------------------------------------------
  [section .text]

