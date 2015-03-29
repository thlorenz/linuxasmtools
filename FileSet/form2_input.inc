;%define DEBUG

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
  extern read_stdin
  extern lib_buf
  extern kbuf
  extern crt_rows,crt_columns
  extern key_decode3

;****f* widget/form *
; NAME
;>1 widget
;  form2_input - get string data for form
; INPUTS
;    ebp = ptr to info block
;          note: info block must be in writable
;                data section.  Text data must
;                also be writable.
;          note: form2 input can continue
;                by calling with same input block
;
;          info block is defined as follows:
;
;          struc in_block
;           .iendrow resb 1 ;rows in window
;           .iendcol resb 1 ;ending column
;           .istart_row resb 1 ;starting row
;           .istart_col resb 1 ;startng column
;           .itext  resd 1 ;ptr to text
;           .top_def  resd 1 ;top str def list
;           .active_str_def resd 1 ;ptr to active entry on str def list
;           .icolor1 resd 1 ;selected string color
;           .icolor2 resd 1 ;str block color
;           .icolor3 resd 1 ;other colors follow here
;          endstruc
;
;          the text pointed at by .itext has normal text and
;          codes to indicate string or colors. negative byte
;          values are used for strings and the values 1-6 are
;          used for colors
;
;          The cursor color is selected by shell, it uses
;          the normal color and inverts. To set cursor color
;          change the color for selected string (icolor1)
;
;          Each string has a descriptive block, see str_def.
;
;          The first string block is indicated by using code
;          of -1. the next is -2, etc.
; 
;          struc str_def
;           .type  resb 1  ;-x=string id 2=button 3=toggle
;           .srow  resb 1 ;row
;           .scol  resb 1 ;col
;           .scur  resb 1 ;cursor column
;           .scroll resb 1 ;scroll counter
;           .wsize  resb 1 ;columns in string window
;           .bsize  resd 1 ;size of buffer
;           .buf    resd 1 ;ptr to buffer
;          endstruc
;
;         Other input data types (toggle,button) are also
;         created and pointers put in the def-list
;         They are defined as follows:
;
;         struc in_def
;         .type  resb 1 ;2=button 3=toggle
;         .srow  resb 1 ;row
;         .scol  resb 1 ;column
;         .mod_col resb 1 ;toggle mod column
;         .mod_char resb 1 ;character for "on"
;         .wsize resb 1 ;size of item
;         .mod_stuff resd 1 ;ptr to color#, +2=toggle char
;         .process resd 1 ;process to handle this
;
; OUTPUT
;    eax = negative (redisplay request)
;        = 0 (unknown key in kbuf)
;        = process to call
;    kbuf = non recognized key
;
;    The state of toggles can be extraced from form by checking
;    at .mod_stuff
;
; NOTES
;   source file: form2.asm
;   see also string_form, and form.asm for a more complex form function.
;<
; * ----------------------------------------------

%ifndef DEBUG

struc in_block
.iendrow	resb 1	;rows in window
.iendcol	resb 1	;ending column
.istart_row	resb 1	;starting row
.istart_col	resb 1	;startng column
.itext		resd 1	;start of text
.top_def	resd 1	;top str def list
.active_def	resd 1	;ptr to active entry on str def list
.icolor1	resd 1	;color 1 (selected string color)
.icolor2	resd 1	;color 2
.icolor3	resd 1  ;color 3
.icolor4	resd 1
endstruc

struc str_def
.type		resb 1  ;-x=string (2=button 3=toggle)
.srow		resb 1	;row
.scol		resb 1	;col
.scur		resb 1	;cursor column
.scroll		resb 1	;scroll counter
.wsize		resb 1	;columns in string window
.bsize		resd 1	;size of buffer
.buf		resd 1	;ptr to buffer
;str_def_size:
endstruc

struc in_def
.type  resb 1 ;2=button 3=toggle
.srow  resb 1 ;row
.scol  resb 1 ;column
.mod_col resb 1 ;toggle mod column
.mod_char resb 1 ;character for "on"
.wsize resb 1 ;size of item
.mod_stuff resd 1 ;used to set select color, +2=toggle char loc
.process resd 1 ;process to handle this
;in_def_size:
endstruc

%endif

;---------------------------------------------------------
;input: ebp=in_block ptr
;output: eax = processing, or zero if not found.
  global form2_input
form2_input:
  push	ebp			;save in_block ptr
  mov	esi,[ebp+in_block.active_def] ;get index
  mov	esi,[esi]		;get def
  mov	al,[esi+in_def.type]	;get type
  test	al,80h			;string
  jnz	fi_string		;jmp if string
  call	read_stdin		;handle button or toggle
  jmp	fi_decode

fi_string:
  call	get_string_setup	;returns ebp -> str_block
  call	get_text		;output 0=unknown key typed  1=mouse click
  jmp	short fi_decode

fi_decode:
  pop	ebp			;restore in_block ptr
  cmp	byte [kbuf],-1		;verify this was a mouse event
  jne	keyhit			;jmp if not mouse event
;add mouse processing here
  call	handle_mouse
  or	eax,eax
  js	fi_unknown
  jmp	short fi_process
keyhit:
  mov	esi,keyboard_decode
  call	key_decode3		;returns process to call in eax
  or	eax,eax
  jz	fi_unknown		;exit if key not found
  call	eax			;out: 0=rediisplay -x=unknown key
  jmp	short fi_process
fi_unknown:
  or	eax,byte -1		;set unknown key/mouse flag
fi_process:
  ret


;------------------------------------------------
; mouse only process, selects string block
; ebp = ptr to in_block
;
;out: set active_def if entry decoded
;     jmp to "enter" if entry decoded
;     else return -1
handle_mouse:
  mov	al,[kbuf +1 ]		;get mouse button
;  mov	[edit_click_button],al	;save mouse button
  mov	cl,[kbuf + 2]		;get mouse column
  mov	ch,[kbuf + 3]		;get mouse row
;  mov	[edit_click_column],cl
;  mov	[edit_click_row],ch
;scan for click row
  mov	esi,[ebp+in_block.top_def] ;index top ptr
pm_lp:
  lodsd
  or	eax,eax			;check if at end
  jz	pm_exit1		;jmp if end of index 
  cmp	ch,[eax+in_def.srow]	;does row match
  jne	pm_lp			;jmp if wrong row
  cmp	cl,[eax+in_def.scol]
  jb	pm_lp			;jmp if column wrong
  mov	dl,[eax+in_def.wsize]	;get entry size
  add	dl,[eax+in_def.scol]	;compute ending column
  cmp	cl,dl
  ja	pm_lp			;jmp if beyond entry
;unselect previous selection
  sub	esi,4			;move back to click def index
  push	esi			;save selection
  mov	esi,[ebp+in_block.active_def]
  call	unselect
  pop	esi
;set this def active
  call	select
  mov	[ebp+in_block.active_def],esi
  test	[eax+in_def.type],byte 80h	;string def?
  jz	enter
pm_exit1:
  or	eax,byte -1			;return no match to caller
pm_exit2:
  ret
;------------
continue:
  or	eax,byte -1
  ret
;------------------------------------------------
;input: ebp = str_block ptr
get_string_setup:
  lea	eax,[ebp+in_block.icolor1]
  mov	[color_ptr_],eax

  mov	ebp,[ebp+in_block.active_def] ;get index ptr
  mov	ebp,[ebp]		;get def
  mov	eax,[ebp+str_def.buf]	;get buffer ptr
  mov	[data_buf_ptr],eax
  mov	eax,[ebp+str_def.bsize]	;buffer size
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

exit:
  or	eax,byte -1
  ret

;------------------------------------------------
; keyboard only process, selects next string.
; input: ebp=in_block ptr
arrow_up:
  mov	esi,[ebp+in_block.active_def] ;get ptr to active def
  mov	edi,[ebp+in_block.top_def]	;get start of string defs
  cmp	esi,edi
  jbe	au_exit		;exit if at top
;remove selected color from old field (non-string only)
  call	unselect
  sub	esi,4
  mov	[ebp+in_block.active_def],esi
;add selected color to new field (non-string only)
  call	select
au_exit:
  xor	eax,eax
  ret
;------------------------------------------------
; keyboard only process, selectes previous string.
; input: ebp=in_block ptr
arrow_down:
  mov	esi,[ebp+in_block.active_def] ;get ptr to active def
  add	esi,4		;move down
  cmp	[esi],dword 0	;at end?
  je	ad_exit		;exit if can't go down
  mov	[ebp+in_block.active_def],esi
;add selected color to new field (non-string)
  call	select
;remove selected color from old field, (non-string)
  sub	esi,4
  call	unselect
ad_exit:
  xor	eax,eax
  ret
;------------
select:
  mov	ebx,[esi]	;get def
  test  [ebx+in_def.type],byte 80h ;string
  jnz	select_exit	;exit if string
  mov	ebx,[ebx+in_def.mod_stuff]
  mov	[ebx],byte 2	;change color number
select_exit:
  ret
;-----------
unselect:
  mov	ebx,[esi]	;get def
  test  [ebx+in_def.type],byte 80h ;string
  jnz	select_exit	;exit if string
  mov	ebx,[ebx+in_def.mod_stuff]
  mov	[ebx],byte 4	;change color number
unselect_exit:
  ret

;-----------------------------------------------------------
enter:
  mov	esi,[ebp+in_block.active_def]	;get index ptr
  mov	esi,[esi]			;get def
  test	[esi+in_def.type],byte 80h	;string def
  jnz	arrow_down			;jmp if string field
  cmp	[esi+in_def.type],byte 3	;toggle?
  jne	button_process
;this is a toggle, handle here
  mov	al,[esi+in_def.mod_char]
  mov	ebx,[esi+in_def.mod_stuff]
  add	ebx,byte 2
  cmp	[ebx],al
  jne	do_stuff
  mov	al,' '
do_stuff:
  mov	[ebx],al
  xor	eax,eax
;  jmp	short enter_exit
button_process:
  mov	eax,[esi+in_def.process]	;get process
enter_exit:
  ret
;-----------------------------------------------------------
 [section .data]

edit_click_button	db 0
edit_click_column	db 0
edit_click_row		db 0

;-----------------
  [section .data]
keyboard_decode:
  db 1bh,5bh,41h,0		;15 pad_up
  dd arrow_up

  db 1bh,4fh,41h,0		;15 pad_up
  dd arrow_up

  db 1bh,4fh,78h,0		;15 pad_up
  dd arrow_up

  db 1bh,5bh,44h,0		;17 pad_left
  dd arrow_up

  db 1bh,4fh,74h,0		;143 pad_left
  dd arrow_up

  db 1bh,5bh,42h,0		;20 pad_down
  dd arrow_down

  db 1bh,4fh,42h,0		;20 pad_down
  dd arrow_down

  db 1bh,4fh,72h,0		;20 pad_down
  dd arrow_down

  db 1bh,5bh,43h,0		;18 pad_right
  dd arrow_down

  db 1bh,4fh,76h,0		;144 pad_right
  dd arrow_down

  db 09h,0			;tab
  dd arrow_down

  db 1bh,5bh,5ah,0		;shift tab
  dd arrow_up

  db 0ah,0			;enter
  dd enter

  db 0dh,0			;enter
  dd enter

  db ' ',0			;space
  dd enter

  db 1bh,0			;escape
  dd exit

  db 0		;end of table

 [section .text]

