
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

;------------------------------
;****f* widget/edit_text_in_box *
; NAME
;>1 widget
;   edit_text_in_box - edit supplied string in a box
; INPUTS
;    ecx = buffer end ptr
;    esi = pointer to structure below
;    - dd window color (see notes)
;    - dd data pointer. ptr to start of string
;    - dd end of data ptr, beyond last display char.
;    -    (a nl will be stored here by edit_text_in_box)
;    - dd initial scroll left/right position
;    - db columns inside box
;    - db rows inside box
;    - db starting row (upper left corner row)
;    - db starting column (upper left corner column)
;    - dd outline box color (see notes)
;    -    (set to zero to disable outline)
;    lib_buf is used to build display lines
;    keyboard is assumed to be in "raw" mode, see: crt_open
;    -
;    example: 
;    -   call	crt_open
;    -   mov	ecx,buf_end	;file buffer size
;    -   mov	esi,boxplus     ;parameter block
;    -   call	edit_file_in_box
;    -   call	crt_close
;    -   mov	eax,1
;    -   int	80h
;    - 
;    -   [section .data]
;    - filename: db 'local_file',0
;    - 
;    - boxplus:
;    - 	dd	30003436h	;window color
;    - 	dd	box_msg		;edit data pointer
;    - 	dd	box_msg_end	;end of edit data
;    - 	dd	0		;scroll right/left (usually zero)
;    - 	db	50		;columns
;    - 	db	10		;rows
;    - 	db	3		;starting row
;    - 	db	3		;starting column
;    - 	dd	30003131h	;color for outline box
;    -
;    - box_msg: db 'hi there im a box',0ah
;    - box_msg_end: db 0ah
;    -   db 0,0
;    - buf_end:	db	0ah
;    - 
; OUTPUT
;   eax = negative system error# or positive if success
;   ebx = end of data ptr
; NOTES
;    source file edit_text_in_box.asm
;    -
;    usage: keys are up,down,right,left,enter
;    -      The tab,pgup,pgdn keys are ignored
;    -      All other keys pop up a menu
;    -
;    The current window width is not checked, edit_text_in_box
;    will attempth display even if window size too small.
;    -
;    Tabs are not handled and should not be used.
;    - 
;    color = aaxxffbb aa-attr ff-foreground  bb-background
;    30-blk 31-red 32-grn 33-brn 34-blu 35-purple 36-cyan 37-gry
;    attributes 30-normal 31-bold 34-underscore 37-inverse
;<
;  * ---------------------------------------------------
;*******
  extern crt_window
  extern read_stdin
  extern key_decode1
  extern kbuf
  extern crt_char_at
  extern blk_insert_bytes
  extern blk_del_bytes
  extern make_box
  extern move_cursor
  extern message_box

  global top_ptr
  global end_ptr

  global edit_text_in_box
edit_text_in_box:
  mov	[buffer_end_ptr],ecx	;store buffer end
;save input data block
  mov	edi,window_def
  mov	ecx,window_def_end - window_def
  rep	movsb

  mov	eax,[display_ptr]	;get start of string ptr
  mov	[top_ptr],eax
  mov	[cursor_ptr],eax
  
  mov	eax,[end_ptr]
  mov	byte [eax],0ah	;put 0ah at end of data
  mov	word [zb_row],0	;set zero based row & column to zero

;check if window needs outlining
  cmp	dword [outline_color],0
  je	ef_15		;jmp if no box outline needed
;outline box
  mov	esi,win_columns
  call	make_box
ef_15:
  mov	esi,window_def
  call	crt_window
  call	show_cursor
  call	read_stdin
  mov	al,[kbuf]	;get key
  cmp	al,-1		;check if mouse
  je	ef_15		;ignore the mouse
;  call	is_alpha
;  je	alpha_keypress	;jmp if alpha
  mov	esi,key_table
  call	key_decode1
  call	eax
  cmp	eax,0
  je	ef_15		;loop if normal return

ef_exit:
;do we want to remove padded blanks at end of lines?
  mov	ebx,[end_ptr]
  ret
;---------------
show_cursor:
  mov	ah,[zb_row]
  add	ah,[start_row]
  mov	al,[zb_column]
  add	al,[start_col]
  call	move_cursor
  ret
;---------------
alpha_keypress:
  mov	edi,[cursor_ptr]
  mov	ebp,[end_ptr]
  cmp	edi,[buffer_end_ptr]
  jae	ak_exit			;exit if cursor at end of buffer
  cmp	ebp,[buffer_end_ptr]
  jb	ak_20			;jmp if buffer not full
;buffer is full
  dec	ebp			;avoid buffer overflow
ak_20:
  mov	eax,1
  mov	esi,kbuf
  call	blk_insert_bytes
  mov	[end_ptr],ebp
ak_exit2:
  cmp	byte [edi],0ah		;was 0ah entered?
  jne	ak_exit3		;jmp if normal alpha
  call	down_arrow
  jmp	short ak_exit
ak_exit3:
  call	right_arrow
ak_exit:
  xor	eax,eax			;set return
  ret
;--------------
delete_key:
  mov	edi,[cursor_ptr]	;ptr to deleted byte
  mov	ebp,[end_ptr]		;current end of data

  cmp	edi,ebp
  jne	dkk_10			;jmp if not equal
  jmp	left_arrow		;we are beyond end of file, try left arrow
dkk_10:
  mov	eax,[top_ptr]		;check if empty file
  inc	eax
  cmp	eax,ebp
  je	dkk_exit		;exit if empty file  

  mov	eax,1			;delete one byte
  call	blk_del_bytes
  mov	[end_ptr],ebp
dkk_exit:
ignore_key:			;entry point for pgup,pgdn keys
  xor	eax,eax
  ret

;--------------
rubout_key:
  cmp	byte [zb_column],0
  jne	rk_rub			;jmp if normal rubout
  cmp	dword [scroll_count],0
  je	rk_exit			;exit if can't rubout char
rk_rub:
  call	left_arrow
  call	delete_key
rk_exit:
  xor	eax,eax
  ret

;--------------
;note: if "up" ends up beyond end of line, pad to cursor
up_arrow:
  cmp	byte [zb_row],0		;at top?
  je	ua_50			;jmp if at top
;not at top, we can move up one line
  call	cursor_up		;move cursor up one
  dec	byte [zb_row]
  mov	[cursor_ptr],esi	;store new cursor
  mov	byte [zb_column],0	;force column 0
  mov	dword [scroll_count],0
  jmp	short ua_exit
;we are at top, need to scroll data
;find start of current line
ua_50:
  mov	esi,[cursor_ptr]
  inc	esi			;check for special case, blank file
  cmp	esi,[end_ptr]
  jae	ua_exit			;exit if empty file
;now look for start of line
ua_lp1:
  dec	esi
  cmp	esi,[top_ptr]
  je	ua_exit		;exit if line at top of file
  cmp	byte [esi],0ah
  jne	ua_lp1
;we are not at start of previous line
  dec	esi
  cmp	byte [esi],0ah		;check if 0ah
  je	ua_save
ua_lp2:
  dec	esi
  cmp	esi,[top_ptr]
  je	ua_save
  cmp	byte [esi],0ah
  jne	ua_lp2
  inc	esi
ua_save:
  mov	[cursor_ptr],esi	;new cursor_ptr
  mov	[display_ptr],esi	;new top of page  
  mov	byte [zb_column],0	;force column 0
  mov	dword [scroll_count],0
ua_exit:
  xor	eax,eax
  ret
;--------------
; output: esi = new cursor
cursor_up:
  mov	esi,[cursor_ptr]
  cmp	esi,[end_ptr]		;special case, beyond end of file
  jne	cu_lp1			;continue if not special case
  dec	esi
;not at end of file here
cu_lp1:
  dec	esi
  cmp	esi,[top_ptr]		;check if at start of file
  je	cu_done			;exit if at start
  cmp	byte [esi],0ah
  jne	cu_lp1			;loop till start
;we are now at end of previous line
cu_lp2:
  dec	esi
  cmp	esi,[top_ptr]		;check if at start of file
  je	cu_done			;exit if at start
  cmp	byte [esi],0ah
  jne	cu_lp2			;loop till start
  inc	esi			;move to start of line
cu_done:
  ret  
;--------------
down_arrow:
  mov	esi,[cursor_ptr]
da_lp1:
  lodsb
  cmp	esi,[end_ptr]
  jae	da_exit		;exit if at end of data
  cmp	al,0ah
  jne	da_lp1		;loop if not end of line	
  mov	[cursor_ptr],esi
  mov	byte [zb_column],0
  mov	dword [scroll_count],0
; check if at end of screen
  mov	al,[zb_row]
  inc	al
  cmp	al,[win_rows]	;check if room to move down
  jb	da_room		;jmp if normal move down
;at end of window, move top screen ptr down one
  mov	esi,[display_ptr]
da_lp2:
  lodsb
  cmp	al,0ah
  jne	da_lp2		;loop till next line found
  mov	[display_ptr],esi ;set new top line
  jmp	short da_exit
da_room:
  inc	byte [zb_row]
da_exit:
  xor	eax,eax
  ret


;--------------
;note: cursor does not wrap, it stops at start of line
;note: if scroll count not zero, then left edge arrow will scroll
left_arrow:
  cmp	byte [zb_column],0	;are we at left edge
  jne	la_10			;jmp if not at left edge
  cmp	dword [scroll_count],0	;can we scroll left
  je	la_exit			;jmp if no scroll
  dec	dword [scroll_count]
  jmp	short la_20
la_10:
  dec	byte [zb_column]
la_20:
  dec	dword [cursor_ptr]
la_exit:
  xor	eax,eax
  ret
;--------------
;note: edge of screen causes screen scroll
right_arrow:
  mov	eax,[cursor_ptr]
;  inc	eax
  cmp	eax,[end_ptr]
  je	ra_exit			;exit if at end of data
  cmp	byte [eax],0ah
  je	ra_exit			;jmp if at end of line
ra_move:
  inc	dword [cursor_ptr]
  mov	al,[win_columns]
  dec	al			;convert to zero based
  cmp	[zb_column],al
  jne	ra_10			;jmp if inside window
  inc	dword [scroll_count]	;scroll whole window if at right edge
  jmp	short ra_exit		;exit 
ra_10:
  inc	byte [zb_column]
ra_exit:
  xor	eax,eax
  ret
;--------------
enter_key:
  mov	byte [kbuf],0ah
  jmp	alpha_keypress
;--------------
unknown_key:
  mov	eax,[win_columns]
  mov	[ewin_columns],eax
  mov	esi,exit_window
  call	message_box
  mov	al,[kbuf]
  cmp	al,'c'			;continue?
  jne	uk_exit2		;no continue, jmp to exit
  xor	eax,eax			;set continue flag
  jmp	short uk_exit3
uk_exit2:
  mov	eax,-1			;set abort flag
uk_exit3:
  ret

;---------------
  [section .data]
top_ptr:	dd	0	;top of file
cursor_ptr:	dd	0	;ptr to cursor
zb_row		db	0	;zero based virtual row
zb_column	db	0	;zero based virtual column

buffer_end_ptr	dd	0	

;window structure
window_def:
page_color:	dd	0	;window color
display_ptr:	dd	0	;top of display page
end_ptr:	dd	0	;end of file
scroll_count	dd	0	;right/left window scroll count
win_columns	db	0	;window columns (1 based)
win_rows	db	0	;window rows (1 based)
start_row	db	0	;starting window row (1 based)
start_col	db	0	;starting window column (1 based)
outline_color	dd	0
window_def_end:

key_table:
  dd	alpha_keypress	;alpha handler is always first entry in table

    db	1bh,5bh,44h,0	;left arrow
  dd	left_arrow	;left arrow process

    db	1bh,4fh,44h,0	;left arrow
  dd	left_arrow	;left arrow process

    db	1bh,4fh,74h,0	;left arrow
  dd	left_arrow	;left arrow process

    db 1bh,5bh,43h,0		;pad_right
  dd	right_arrow

    db 1bh,4fh,43h,0		;pad_right
  dd	right_arrow

    db 1bh,4fh,76h,0		;pad_right
  dd	right_arrow

    db 1bh,5bh,41h,0		;pad_up
  dd	up_arrow

    db 1bh,4fh,41h,0		;pad_up
  dd	up_arrow

    db 1bh,4fh,78h,0		;pad_up
  dd	up_arrow

    db 1bh,5bh,42h,0		;pad_down
  dd	down_arrow

    db 1bh,4fh,42h,0		;pad_down
  dd	down_arrow

    db 1bh,4fh,72h,0		;pad_down
  dd	down_arrow

    db 1bh,5bh,33h,7eh,0	;pad_del
  dd	delete_key

    db 1bh,4fh,6eh,0		;pad_del
  dd	delete_key

    db 7fh,0			;backspace
  dd	rubout_key

    db 0dh,0			;enter
  dd	enter_key

    db 0ah,0			;enter
  dd	enter_key

    db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd	ignore_key

    db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd	ignore_key

    db  09,0			;tab
  dd	ignore_key

    db	0		;end of table
  dd	unknown_key	;unknown key handler is always last entry


exit_window:
exit_color:	dd	31003330h	;window color
exit_msg:	dd	done_msg	;top of display page
end_exit_msg:	dd	end_done_msg	;end of file
escroll_count	dd	0	;right/left window scroll count
ewin_columns	db	0	;window columns (1 based)
ewin_rows	db	0	;window rows (1 based)
estart_row	db	0	;starting window row (1 based)
estart_col	db	0	;starting window column (1 based)
		dd	0	;no box outline

done_msg:
  db 'press <enter> to continue',0ah
  db 'press <esc> to exit and save',0ah
  db 0ah
  db ' editor usage:',0ah
  db '  movement: right,left,up,down arrows',0ah
  db '  delete: del,rubout',0ah
  db '  insert: any alpha character, or <return>',0ah
end_done_msg:	db	0
