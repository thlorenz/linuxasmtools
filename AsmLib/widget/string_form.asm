
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

  extern get_text
  extern lib_buf
  extern kbuf
  extern move_cursor
  extern crt_str
  extern crt_rows,crt_columns
  extern read_window_size
  extern mov_color
  extern crt_write
  extern key_decode1

;****f* widget/form *
; NAME
;>1 widget
;  string_form - get string data for form
; INPUTS
;    ebp = ptr to info block
;          note: info block must be in writable
;                data section.  Text data must
;                also be writable.
;          note: string_form input can continue
;                by calling with same input block
;
;          info block is defined as follows:
;
;          struc in_block
;           .iendrow resb 1 ;rows in window
;           .iendcol resb 1 ;ending column
;           .istart_row resb 1 ;starting row
;           .istart_col resb 1 ;startng column
;           .icursor resd 1 ;ptr to string block with active cursor
;           .icolor1 resd 1 ;body color
;           .icolor2 resd 1 ;highlight/string color
;           .itext  resd 1 ;ptr to text
;          endstruc
;
;          the text pointed at by .itext has normal text and
;          imbedded string using the following format:
;
;          struc str_def
;           .srow  resb 1 ;row
;           .scol  resb 1 ;col
;           .scur  resb 1 ;cursor column
;           .scroll  resb 1 ;scroll counter
;           .wsize  resb 1 ;columns in string window
;           .bsize  resd 1 ;size of buffer, (max=127)
;          endstruc
;
;          the text can also have areas highlighted with .icolor2
;          by enclosing them with "<" and ">".
; 
; OUTPUT
;    kbuf = non recognized key
; NOTES
;   source file: string_form.asm
;   see also form.asm for a more complex form function.
;<
; * ----------------------------------------------

struc in_block
.iendrow	resb 1	;rows in window
.iendcol	resb 1	;ending column
.istart_row	resb 1	;starting row
.istart_col	resb 1	;startng column
.icursor	resd 1	;ptr to string block with active cursor
.icolor1	resd 1	;body color
.icolor2	resd 1	;highlight/string color
.itext		resd 1	;ptr to text
endstruc

struc str_def
.srow		resb 1	;row
.scol		resb 1	;col
.scur		resb 1	;cursor column
.scroll		resb 1	;scroll counter
.wsize		resb 1	;columns in string window
.bsize		resd 1	;size of buffer, (max=127)
endstruc

;*******
  [section .text]
  global string_form
string_form:
  cmp	byte [crt_rows],0
  jne	form_setup
  call	read_window_size
form_setup:
form_lp1:
  call	display_form
form_lp2:
  push	ebp			;save in_block ptr
  call	get_string_setup	;returns ebp -> str_block
  call	get_text		;output 0=unknown key typed  1=mouse click
  pop	ebp			;restore in_block ptr
  cmp	byte [kbuf],-1		;verify this was a mouse event
  jne	key_hit			;jmp if not mouse event
  call	handle_mouse		;returns ecx=processing
  jmp	el_process
key_hit:    
  mov	esi,key_decode_table
  call	key_decode1		;returns process to call in eax
  mov	ecx,eax
el_process:
  jecxz	ml_end2
  call	ecx			;call keyboard or mouse process !!!!
ml_end2:
  or	al,al
  jz	form_lp1		;loop if continue mode
  ret				;return code in -al-

;-----------------
  [section .data]
key_decode_table:
  dd	exit_key		;exit if any alpha key pressed

  db 1bh,5bh,41h,0		;15 pad_up
  dd arrow_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd arrow_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd arrow_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd arrow_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd arrow_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd arrow_down

  db 0		;end of table
  dd exit_key ;unknown key trap

  [section .text]
;------------------------------------------------
exit_key:
  mov	al,1		;exit code
  ret
;------------------------------------------------
; keyboard only process, selects next string.
; input: ebp=in_block ptr
arrow_up:
  mov	esi,[ebp+in_block.icursor]	;get ptr to cursor string
  mov	ecx,[ebp+in_block.itext]	;get start of text data
au_lp:
  dec	esi
  cmp	esi,ecx
  je	au_exit				;exit if no "up" string found
  cmp	byte [esi],-1			;check if string here
  jne	au_lp				;jmp to keep looking
;we have found another string
  mov	[ebp+in_block.icursor],esi
au_exit:
  xor	eax,eax			;set exit code to continue
  ret

;------------------------------------------------
; keyboard only process, selectes previous string.
; input: ebp=in_block ptr
arrow_down:
  mov	esi,[ebp+in_block.icursor]	;get ptr to cursor string
  add	esi,byte 11			;move past str_def entry
  mov	ecx,[ebp+in_block.itext]	;get start of text data
ad_lp:
  lodsb
  or	al,al
  jz	ad_exit				;exit if no "up" string found
  cmp	al,-1				;check if string here
  jne	ad_lp				;jmp to keep looking
  dec	esi
;we have found another string
  mov	[ebp+in_block.icursor],esi
ad_exit:
  xor	eax,eax			;set exit code to continue
  ret
;------------------------------------------------
; mouse only process, selects string block
; ebp = ptr to in_block
;
handle_mouse:
  mov	al,[kbuf +1 ]		;get mouse button
  mov	[edit_click_button],al	;save mouse button
  mov	cl,[kbuf + 2]		;get mouse column
  mov	ch,[kbuf + 3]		;get mouse row
  mov	[edit_click_column],cl
  mov	[edit_click_row],ch
;scan for click row
  mov	esi,[ebp+in_block.itext]
pm_lp:
  lodsb
  or	al,al			;check if at end
  jz	pm_exit1		;jmp if unknown click row
  cmp	al,-1			;check if string start
  jne	pm_lp			;jmp to keep looking
;we have found string, check if row matches
  mov	al,[esi+str_def.srow]
  cmp	al,ch
  je	pm_found_row
  add	esi,byte 8		;move over this str_def
  jmp	short pm_lp		;jmp if wrong row
;we have found click on string row
pm_found_row:
  cmp	cl,[esi+str_def.scol]	;check column
  jb	pm_set_ptr
  mov	ah,[esi+str_def.scol]
  add	ah,[esi+str_def.wsize]	;compute end of window
  cmp	cl,ah
  ja	pm_set_ptr		;jmp if past window
  mov	[esi+str_def.scur],cl	;set new cursor position
pm_set_ptr:
  dec	esi
  mov	[ebp+in_block.icursor],esi
  mov	ecx,continue		;
  jmp	short pm_exit2
pm_exit1:
  mov	ecx,exit_key			;return key to caller
pm_exit2:
  ret
;------------
continue:
  xor	eax,eax
  ret
;------------------------------------------------
get_string_setup:
  lea	eax,[ebp+in_block.icolor2]
  mov	[color_ptr_],eax

  mov	ebp,[ebp+in_block.icursor]
  inc	ebp			;move past initial '-1' to str_def
  lea	eax,[ebp + 10]		;move to string buffer
  mov	[data_buf_ptr],eax
  mov	eax,[ebp+str_def.bsize]	;buffer size
;  dec	al			;set buffer size -1
  mov	[buf_size],eax
  mov	al,[ebp+str_def.srow]	;row
  mov	[window_row],al
  mov	al,[ebp+str_def.scol]	;column
  mov	[window_column],al
  mov	al,[ebp+str_def.scur]	;current cursor col
  mov	[cursor_colmn],al
  mov	al,[ebp+str_def.wsize]	;window size
  mov	[win_size],al

  mov	al,[ebp+str_def.scroll]
  mov	[scroll_],al

  mov	ebp,str_block
  ret

  [section .data]
str_block:
data_buf_ptr    dd 0 ;+0    cleared or preload with text
buf_size        dd 5 ;+4    buffer size -1 
color_ptr_          dd 0 ;+8    (see file crt_data.asm)
window_row        db   1 ;+12   ;row (1-x)
window_column     db   1 ;+13   ;column (1-x)
cursor_colmn db   1 ;+15   ;must be within data area
win_size        dd   3 ;+16   bytes in window
scroll_            dd   0

  [section .text]
;------------------------------------------------
; display the contents table
;  inputs:  esi = ptr to table
;
display_form:
  mov	esi,[ebp+in_block.itext]
  mov	cl,[ebp+in_block.istart_row]
df_next_line:
  push	ecx
  call	display_line
  pop	ecx
  inc	cl 
  or	al,al
  jnz	df_tail
  dec	esi			;move back to zero
  jmp	short df_next_line
df_tail:
  jns	df_next_line		;jmp if more lines in window
  ret
;---------------------------------------------------------
; display_line
;  inputs: ebp = input block ptr
;          esi = line text ptr, ends with 0ah, or 0
;                can have string blocks or <xx> highlight areas
;          cl  = current row
; output:  ebp = unchanged
;          esi = end or line
;          al  = 0 if end of text found
;                0ah if end of line
;                -1 if end of window
;
display_line:
  mov	edi,lib_buf			;setup stuff ptr
  cmp	cl,[crt_rows]
  ja	dl_10				;jmp if not at end
  cmp	cl,[ebp+in_block.iendrow]
  jbe	dl_20
dl_10:
  xor	eax,eax
  dec	eax
  jmp	dl_exit				;exit
dl_20:
  mov	ah,cl		;get current row
  mov	al,[ebp+in_block.istart_col]	;display from column 1
  push	ecx
  call	move_cursor
  mov	eax,[ebp+in_block.icolor1]
  call	mov_color			;set initial color
  pop	ecx
  mov	dl,[ebp+in_block.iendcol]	;setup ending col
  mov	dh,[crt_columns]		;setup end of  screen
  mov	cl,[ebp+in_block.istart_col]
dl_lp1:
  cmp	cl,dl			;at end of window
  ja	dl_to_end
  cmp	cl,dh
  ja	dl_to_end		;at end of screen
  lodsb				;get next char
  cmp	al,0ah			;end of line
  je	dl_eol
  cmp	al,0
  je	dl_end_of_text
  cmp	al,'<'
  je	dl_highlight_on
  cmp	al,'>'
  je	dl_highlight_off
  or	al,al
  js	dl_string
  stosb				;store alpha
dl_tail:
  inc	cl			;move to next column
  jmp	short dl_lp1		;continue
;scan to end of text line, then display buffer
dl_to_end:
  lodsb
  or	al,al
  jz	dl_end1			;jmp if at end
  cmp	al,0ah
  jne	dl_to_end		;loop to end of line
dl_end1:
  jmp	dl_show_line
;fill to end of window with blanks
dl_eol:
dl_end_of_text:
  call	fill_to_end
  jmp	dl_show_line
dl_eot:
  jmp	dl_show_line
dl_highlight_on:
  mov	eax,[ebp+in_block.icolor2]
  call	mov_color
  mov	al,'<'
  stosb
  jmp	dl_tail
dl_highlight_off:
  stosb				;store '>'
  mov	eax,[ebp+in_block.icolor1]
dl_set_color:
  call	mov_color
  jmp	dl_tail
dl_string:
  mov	eax,[ebp+in_block.icolor2]
  call	mov_color
  xor	ebx,ebx
  mov	bl,[esi+str_def.scroll]	;get scroll
  mov	ah,[esi+str_def.wsize]	;get window size
  mov	[tmp_string_start],esi
  lea	esi,[esi+ebx+10]	;move to start of buf data
dl_lp2:
  cmp	cl,dl
  ja	dl_to_end
  cmp	cl,dh
  ja	dl_to_end
  movsb
  inc	cl		;move column number
  dec	ah
  jnz	dl_lp2		;move buffer string data
  mov	eax,[ebp+in_block.icolor1]
  call	mov_color
;move esi to end of string buffer
  mov	esi,[tmp_string_start]
  mov	ebx,[esi+str_def.bsize]	;get buffer size
  lea	esi,[esi+ebx+10]	;compute end of buffer
  jmp	dl_lp1
;
dl_show_line:
  mov	edx,edi		;compute size of line
  mov	ecx,lib_buf
  sub	edx,ecx		;compute size of line
  call	crt_write
  mov	al,[esi-1]	;get last char
dl_exit:
  ret
;---------------------------------
fill_to_end:
  cmp	cl,dl
  ja	fte_exit
  mov	al,' '
  stosb
  inc	cl
  jmp	short fill_to_end
fte_exit:
  ret

;-----------------------------------------------------------
 [section .data]

edit_click_button	db 0
edit_click_column	db 0
edit_click_row		db 0

tmp_string_start	dd 0

 [section .text]


%ifdef DEBUG

 extern env_stack
 extern mouse_enable

 global _start
 global main
_start:
main:    ;080487B4
  call	env_stack
  call	mouse_enable
  cld
  mov	ebp,test_block
  call	string_form

  mov	eax,1
  int	80h

  [section .data]

test_block:
 db 15	;ending row
 db 60  ;ending column
 db 1	;starting row
 db 1	;startng column
 dd string1_def ;string with cursor
 dd 30003634h	;text color
 dd 30003136h	;string color
 dd test_form	;form def ptr

test_form:
 db '  ** find file/directory/data **',0ah
 db 0ah
 db 'starting path '
string1_def:
 db -1  ;start of string def
 db 3	;row
 db 15	;column
 db 15	;current cursor posn
 db 0	;scroll
 db 4  ;window size
 db buf1_end - buf1_start ;buf size (max=127)
 db -2	;end of string def
buf1_start:
 db "12   "
buf1_end:
 db ' ',0ah,0ah

 db 'search string '
string2_def:
 db -1  ;start of string def
 db 5	;row
 db 15	;column
 db 15	;current cursor posn
 db 0	;scroll
 db 3  ;window size
 db buf2_end - buf2_start ;buf size (max=127)
 db -2	;end of string def
buf2_start:
 db 'no '
buf2_end:
 db ' ',0ah,0ah

 db '  <F1>=help <Enter>=do search  <ESC>=exit',0

 
  [section .text]

%endif
  [section .text]
