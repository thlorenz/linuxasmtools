
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
  [section .text]

;***************** file view_file.asm *********************
;--------------------------------------------------------
; NAME
;>1 widget
;   view_file - display,search,scroll text  file
; INPUTS
;    ebx = pointer to file path (name)
;
;    if ebx = 0 then the following is assumed
;
;    eax = length of text buffer
;    ebx = 0
;    ecx = pointer to buffer

; OUTPUT
;   none
; NOTES
;    source file: view_file.asm
;<
;--------------------------------------------------------
; NAME
;>1 widget
;   view_buffer - display,search,scroll text
; INPUTS
;    eax = length of text buffer
;    ebx = 0
;    ecx = pointer to buffer

; OUTPUT
;   none
; NOTES
;    source file: view_file.asm
;<

browser_win_color	dd	31003334h		;bold yellow on blue
browser_menu_sp_color	dd	31003334h
browser_menu_but_color	dd	30003037h		;
match_highlight_color	dd	30003134h

;----------------------------------------------
  [section .text]

  extern read_stdin
  extern kbuf,key_decode1
  extern blk_find
  extern mmap_open_ro
  extern crt_columns,crt_rows,status_color2
  extern crt_mouse_line
  extern crt_window
  extern key_string1
  extern crt_set_color,crt_color_at
  extern mouse_line_decode
  extern file_status_name
  extern read_window_size
  extern mouse_enable
;  extern mmap_close

fb_error:
  ret
;
; input:  ebx = filename ptr
;
  global view_buffer
  global view_file
view_file:
view_buffer:
  push	eax
  push	ebx
  push	ecx
  call	read_window_size
  call	mouse_enable
  pop	ecx
  pop	ebx
  pop	eax
;  mov	ebx,data_path
  or	ebx,ebx			;check if stdin (ebx=0)
  jz	fb_setup		;jmp if stdin
  xor	ecx,ecx				;buffer size = auto
  call	mmap_open_ro		;returns eax=length ecx=data ptr
  or	eax,eax
  jns	fb_setup			;jmp if file found
  js	fb_error
fb_setup:
  mov	[file_handle],ebx
  mov	[buffer],ecx
  mov	[file_size],eax
  add	eax,ecx				;compute buffer end
  mov	[file_end_ptr],eax

;  mov	byte [eax],0ah
;  mov	byte [ecx],0ah
  mov	dword [scroll],0
  mov	al,[crt_columns]
  mov	[c_win_cols],al
  mov	al,[crt_rows]
  dec	al
  mov	[c_win_rows],al
  mov	byte [c_start_row],1
  mov	byte [c_start_col],1
  mov	byte [highlight_match],0	;clear found highlight
;
; display file
;

display_lp1:
  mov	ebp,[buffer]
  mov	[last_match_ptr],ebp
display_lp2:
  mov	[display_top],ebp

  mov	esi,in_block
  call	crt_window
;
; highlight match if present
;
  cmp	byte [highlight_match],0
  je	fb_buttons
  call	light_match
  mov	byte [highlight_match],0	;turn off highlight
;
; add buttons and search string
;
fb_buttons:
  mov	ah,[crt_rows]
  mov	[str_row],ah		;save for string entry
  mov	ecx,[browser_menu_sp_color]	;space color
  mov   edx,[browser_menu_but_color]		;button color
  mov	esi,button_row1
  call	crt_mouse_line
;
; get find string
;
fb_ignore:
  push	ebp
  mov	ebp,string_table
  call	key_string1
  pop	ebp
  mov	[str_adj],ah		;save cursor col
;
  cmp	byte [kbuf],-1		;check if mouse
  je	fb_mouse
fb_decode:
  mov	esi,key_decode_table3
  call	key_decode1
  call	eax			;returns -1 if done
  jmp	short fb_cont
fb_mouse:
  mov	bl,[kbuf+2]		;get mouse column
  mov	bh,[kbuf+3]		;get mouse row
  dec	bh			;convert row to zero based
  cmp	bh,[c_win_rows]		;is this the button line
  je	fb_button
  call	mouse_keyword
  call	find_again
  jmp	short fb_cont
fb_button:
  mov	esi,button_row1
  mov	edi,button_actions
  call	mouse_line_decode
  jecxz fb_ignore
  call	ecx			;returns al= -1 to abort
fb_cont:
  cmp	al,-1
  je	fb_exit
  cmp	al,1
  je	display_lp1		;jmp if redisplay from top of file
  jmp	display_lp2		;jmp if ebp is redisplay ptr
fb_exit:
;if mmap_ro then this close causes problems, segfaults
;in view_file?
;  mov	eax,[file_handle]
;  mov	ebx,[buffer]
;  mov	eax,[file_size]
;  call	mmap_close
  ret
;--------------------
;find:
;  push	ebp
;  mov	ebp,[file_end_ptr]
;  mov	esi,string_buf
;  mov	edi,[buffer]
;  mov	edx,1		;forward search
;  mov	ch,0dfh		;ignore case
;  call	blk_find
;  pop	ebp
;  jc	not_found
;  mov	[last_match_ptr],ebx
;
; scan to start of line
;
find1:
  mov	byte [highlight_match],1 
  call	previous_line
  call	previous_line
  mov	ebp,ebx
  mov	al,2
  jmp	find_exit
not_found:
  mov	eax,[status_color2]
  mov	bl,1		;column for msg
  mov	bh,[crt_rows]	;row for msg
  mov	ecx,not_fnd_msg
  call	crt_color_at
  call	read_stdin
  mov	al,1		;indicate not found
find_exit:
  ret
;---------------------------
previous_line:
  dec	ebx
  cmp	ebx,[buffer]
  jbe	plexit		;jmp if at top of buffer
  cmp	byte [ebx -1],0ah
  je	plexit		;jmp if at start of line
  jmp	short previous_line
plexit:
  ret
;----------------------
find_again:
  push	ebp
  mov	ebp,[file_end_ptr]
  mov	esi,string_buf
  mov	edi,[last_match_ptr]
  inc	edi		;move past last match
  mov	edx,1		;forward search
  mov	ch,0dfh		;ignore case
  call	blk_find
  pop	ebp
  jc	not_found
  mov	[last_match_ptr],ebx
  jmp	short find1
;---------------------------------
fb_up:
  mov	esi,[display_top]
  call	prev_line
  mov	ebp,esi
  mov	al,2    
  ret

;-----------------------
fb_down:
  mov	esi,[display_top]
  call	next_line
  mov	ebp,esi
  mov	al,2
  ret

;-----------------------
fb_right:
  inc	dword [scroll]
  mov	ebp,[display_top]
  mov	al,2
  ret

;-----------------------
fb_left:
  cmp	dword [scroll],0
  je	fb_left_exit
  dec	dword [scroll]
fb_left_exit:
  mov	ebp,[display_top]
  mov	al,2
  ret

;-----------------------
fb_pgup:
  xor	ecx,ecx
  mov	cl,[c_win_rows]
  mov	esi,[display_top]
fbp_lp:
  call	prev_line
  dec	ecx
  jnz	fbp_lp
  mov	ebp,esi
  mov	al,2
  ret

;-----------------------
fb_pgdn:
  xor	ecx,ecx
  mov	cl,[c_win_rows]
  mov	esi,[display_top]
fbpg_lp:
  call	next_line
  jc	at_bottom
  dec	ecx
  jnz	fbpg_lp
  jmp	fbpg_exit
at_bottom:
  call	prev_line
fbpg_exit:
  mov	ebp,esi
  mov	al,2
  ret  
;-----------------------
goto_top:
  mov	eax,[buffer]
  mov	dword [last_match_ptr],eax
  mov	al,1
  ret
;-----------------------
quit:
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
  cmp	esi,[file_end_ptr]
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
;        bl=column 1 based
;        bh=row 0 based
;        [c_win_rows] = row with button line, zero based
; output: string_buf filled with match string
;         str_adj - set to size of match + 11
;
mouse_keyword:
  inc	bh			;make click row 1 based
  mov	esi,ebp			;setup scan start point
  mov	ch,1			;row 1
mk_restart_column:
  mov	cl,1			;column 1
mk_lp1:
  lodsb
  cmp	al,0ah			;blank line,eol
  je	mk_bump_line
  cmp	al,09h			;tab?
  jne	mk_data			;jmp if text
mk_tab:
  inc	cl
  test	cl,7
  jnz	mk_tab
  jmp	short mk_lp1  
mk_data:
  cmp	cx,bx			;are we at match point
  jae	mk_at_click		;jmp if at click
  inc	cl			;move to next column
  jmp	short mk_lp1		;continue scanning forward
mk_bump_line:
  inc	ch
  jmp	short mk_restart_column
;
; the seek position is at or beyond the click point,
; look for a match word here.  esi=click point.
;
mk_at_click:
  dec	esi
  cmp	byte [esi],' '
  je	mk_at_front		;jmp if front of match found
  cmp	esi,[buffer]		;at front of buffer
  je	mk_at_front
  cmp	byte [esi],0ah
  je	mk_at_front		;jmp if at front of match
  cmp	byte [esi],09h
  jne	mk_at_click		;loop till front of keyword found
;
; we have found the front of a key word at esi+1
;
mk_at_front:
  inc	esi			;move to start fo keyword
  push	esi
;
; scan to end of keyword
;
mk_end_scan:
  cmp	esi,[file_end_ptr]
  je	mk_end_scan
  lodsb
  cmp	al,' '
  je	mk_end_found
  cmp	al,09h
  je	mk_end_found
  cmp	al,0ah
  jne	mk_end_scan		;loop back till end of keyword
;
; we have found the end of a keyword
;
mk_end_found:
  mov	ebx,esi			;move end ot ebx
  pop	esi			;restore start
  cmp	esi,ebx
  je	mk_end			;exit if zero lenght keyword
;
; move the keyword to string buf, esi=start  ebx=end of keyword
;
  mov	ecx,0			;string length counter
  mov	edi,string_buf
  cld
  dec	ebx			;;
mk_move:
  movsb
  inc	ecx
  cmp	esi,ebx 
  jb	mk_move
  add	cl,11
  mov	[str_adj],cl		;store string end column
;
; fill the rest of string_buf with zeros
;
  sub	cl,10
  mov	al,0
mk_clear:
  stosb
  inc	cl
  cmp	cl,byte [max_string_len]
  jb	mk_clear

;move ebp to start of next line
  mov	ebp,ebx			;point at end of string
mk_fwd:
  cmp	ebp,[file_end_ptr]
  je	mk_fwd_done		;jmp if end
  cmp	byte [ebp-1],0ah
  je	mk_fwd_done
  inc	ebp
  jmp	short mk_fwd
mk_fwd_done:
  mov	[last_match_ptr],ebp  
mk_end:
  ret  
;----------------------------------------------
light_match:
  mov	edi,[last_match_ptr]
  mov	esi,[display_top]
  xor	ebx,ebx
  mov	bh,1		;starting row
lm_next_row:
  mov	bl,[c_start_col]
  add	ebx,[scroll]
lm_lp:
  cmp	esi,edi
  je	lm_found
  lodsb
  cmp	al,9		;check for tab
  jne	lm_20		;jmp if not tab
lm_tab:
  inc	ebx
  test	bl,7
  jnz	lm_tab
  jmp	lm_lp  
lm_20:
  cmp	ebx,[file_end_ptr]
  je	unknown_key	;get out if error
  inc	ebx
  cmp	al,0ah		;is this a eol
  jne	lm_lp		;continue if not
  inc	bh
  jmp	lm_next_row
lm_found:
  sub	ebx,[scroll]		;remove scroll count
  mov	eax,[match_highlight_color]
;  mov	bh,1			;assume match on row 1
  mov	ecx,string_buf
  call	crt_color_at
unknown_key:
  ret  
;----------------------------------------------

button_row1:
 db 1,' find ->                              ',2,'(f1)find-again',2,'(f2)goto-top',2,'(esc)exit',3,'click in window',1,0
button_actions:
 dd  find_again, find_again, goto_top,  quit, 0

not_fnd_msg:
  db ' ** String not found **  press any key to continue                      ',0

key_decode_table3:
  dd	unknown_key	;alpha key

  db 1bh,5bh,5bh,41h,0		;127 F1
  dd find_again

  db 1bh,5bh,5bh,42h,0		;128 f2
  dd goto_top

  db 1bh,4fh,50h,0		;123 F1
  dd find_again

  db 1bh,4fh,51h,0		;123 F2
  dd goto_top

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

  db 1bh,5bh,43h,0		;18 pad_right
  dd fb_right

  db 1bh,4fh,43h,0		;18 pad_right
  dd fb_right

  db 1bh,4fh,76h,0		;18 pad_right
  dd fb_right

  db 1bh,5bh,44h,0		;17 pad_left
  dd fb_left

  db 1bh,4fh,44h,0		;17 pad_left
  dd fb_left

  db 1bh,4fh,74h,0		;17 pad_left
  dd fb_left

  db 1bh,5bh,35h,7eh,0		;16 pad_pgup
  dd fb_pgup

  db 1bh,4fh,79h,0		;16 pad_pgup
  dd fb_pgup

  db 1bh,5bh,36h,7eh,0		;21 pad_pgdn
  dd fb_pgdn

  db 1bh,4fh,73h,0		;21 pad_pgdn
  dd fb_pgdn

  db 1bh,5bh,32h,31h,7eh,0	;11 f10
  dd quit

  db 1bh,0			;ESC
  dd quit

  db 0dh,0			;enter key
  dd find_again

  db 0ah,0			;enter key
  dd find_again

  db 0		;enc of table
  dd unknown_key ;unknown key trap

  
;----------------------------------------------
  [section .data]

in_block:				;inputs for crt_window
color		dd	30003734h
display_top	dd	0
file_end_ptr	dd	0
scroll		dd	0
c_win_cols	db	0	;win columns
c_win_rows	db	0	;win rows
c_start_row	db	0
c_start_col	db	0

string_table:
  dd	string_buf	;ptr to string buffer
max_string_len:
  dd	30		;max string len
  dd	browser_menu_but_color
str_row:
  db	0		;row
  db	11		;column
  db	0		;flag 1=allow 0a in string
str_adj:
  db	11		;initial cursor column

string_buf:  times 32 db 0

;----------------------------------------------
  [section .data]
env_ptrs	dd	0
exit_flag	db	0	;1=exit program

file_handle	dd	0
file_size	dd	0
buffer		dd	0
highlight_match db	0	;0=no match 1=highlight match
last_match_ptr	dd	0	;last find ptr

  [section .text]

%ifdef DEBUG

  global main,_start
main:
_start:
  mov	eax,help_end - help
  xor	ebx,ebx
  mov	ecx,help
  call	view_file
  mov	eax,1
  int	80h

;---------
  [section .data]
help:
  db 0ah
  db 'this is a help file',0ah
  db 'show me'
  db 0ah,0ah,0ah,0ah,0ah,0ah,0ah
  db 'inserted line',0ah
  db 'press escape to exit',0ah
  db 0ah,0ah,0ah,0ah,0ah,0ah,0ah
  db 'inserted line',0ah
  db 'press escape to exit',0ah
  db 0ah,0ah,0ah,0ah,0ah,0ah,0ah
  db 'inserted line',0ah
  db 'press escape to exit',0ah
  db 0ah,0ah,0ah,0ah,0ah,0ah,0ah
  db 'inserted line',0ah
  db 'press escape to exit',0ah
help_end
%endif
