%define DEBUG

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

  extern move_cursor
  extern crt_str
  extern crt_rows,crt_columns

  extern read_window_size

  extern mov_color
  extern crt_write

;****f* widget/form *
; NAME
;>1 widget
;  form2_show - show form for input of data
; INPUTS
;    ebp = ptr to info block
;          note: info block must be in writable
;                data section.  Text data must
;                also be writable.
;          note: string_form2 input can continue
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
;           .active_def resd 1 ;ptr to active entry on str def list
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
;         .mod_stuff resd 1 ;select color ptr, +2=toggle char stuff in msg
;         .process resd 1 ;process to handle this
;
; OUTPUT
;    kbuf = non recognized key
; NOTES
;   source file: string_form2.asm
;   see also string_form, and form.asm for a more complex form function.
;<
; * ----------------------------------------------

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
.type		resb 1  ;1=string (2=button 3=toggle)
.srow		resb 1	;row
.scol		resb 1	;col
.scur		resb 1	;cursor column
.scroll		resb 1	;scroll counter
.wsize		resb 1	;columns in string window
.bsize		resd 1	;size of buffer, (max=127)
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
.mod_stuff resd 1 ;color for select, +2=toggle char. stuff for msg
.process resd 1 ;process to handle this
;in_def_size:
endstruc

;----------------------------------
  global form2_show
form2_show:
  cmp	byte [crt_rows],0	;do we know screen size?
  jne	f2_ready		;jmp if screen size known
  call	read_window_size	;read screen size
f2_ready:
  call	display_form
  ret

;------------------------------------------------
; display the contents table
;  inputs:  esi = ptr to table
;
display_form:
  mov	esi,[ebp+in_block.itext]	;get text ptr
  mov	cl,[ebp+in_block.istart_row]	;get starting row
df_next_line:
  push	ecx		;save row
  call	display_line	;out 0=end form 0ah=eol -1=end win
  pop	ecx		;restore row
  inc	cl 		;bump  row
  or	al,al
  jnz	df_tail		;loop till done
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
  mov	edi,lib_buf		;setup stuff ptr
  cmp	cl,[crt_rows]		;get display rows
  ja	dl_10			;jmp if at end
  cmp	cl,[ebp+in_block.iendrow] ;at last row?
  jbe	dl_20		;jmp if at end of win
dl_10:
  xor	eax,eax
  dec	eax
  jmp	dl_exit				;exit
dl_20:
  mov	ah,cl		;get current row
  mov	al,[ebp+in_block.istart_col]	;display from column 1
  push	ecx
  call	move_cursor
  pop	ecx
  mov	dl,[ebp+in_block.iendcol]	;setup ending col
  mov	dh,[crt_columns]		;setup end of  screen
  mov	cl,[ebp+in_block.istart_col]	;get starting col
;dl=end column  dh=screen end column  cl=current column
dl_lp1:
  cmp	cl,dl			;window end? cl=col dl=win end col
  ja	dl_end1			;jmp if at end of win
  cmp	cl,dh			;end of screen? dh=screen end
  ja	dl_end1			;at end of screen
  lodsb				;get next char
  cmp	al,0ah			;end of line
  je	dl_eol			;jmp if eol
  cmp	al,0			;end of text
  je	dl_end_of_text		;jmp if end of text
  test	al,80h			;string def
  jnz	dl_string		;jmp if string
  cmp	al,8			;color code?
  jb	dl_color		;jmp if color code
  stosb				;store alpha
dl_tail:
  inc	cl			;move to next column
  jmp	short dl_lp1		;continue
;scan to end of text line, then display buffer
dl_end1:
  jmp	dl_show_line
;fill to end of window with blanks
dl_eol:
dl_end_of_text:
  dec	cl	
  call	fill_to_end
  jmp	dl_show_line
dl_eot:
  jmp	dl_show_line
dl_color:
  movzx	eax,al
  shl	eax,2		;multiply color by 4
  lea	eax,[ebp+eax+in_block.icolor1-4]
  mov	eax,[eax]	;get color
  call	mov_color
  jmp	dl_lp1
dl_string:
  push	esi
  mov	esi,[ebp+in_block.top_def] ;get index top ptr
dl_look:
  mov	ebx,[esi]	;get ptr to def
  or	ebx,ebx
  jz	str_skip	;if error, ignore this entry
  cmp	[ebx],al	;is this our str_def
  je	dl_got		;jmp if found def
  add	esi,4
  jmp	dl_look

dl_got:
  mov	esi,ebx		;esi = str_def ptr
;  mov	eax,[ebp+in_block.icolor2]
;  call	mov_color	;str def color
  xor	ebx,ebx
  mov	bl,[esi+str_def.scroll]	;get scroll
  mov	ah,[esi+str_def.wsize]	;get string size
  mov	[tmp_string_start],esi
  mov	esi,[esi+str_def.buf]
;dl=end column  dh=screen end column  cl=current column
dl_lp2:
  cmp	cl,dl
  je	dl_show_line1	;jmp if end of window
  cmp	cl,dh		
  ja	dl_show_line1	;jmp if end of screen
  movsb
  inc	cl		;move column number
  dec	ah
  jnz	dl_lp2		;move buffer string data
;  dec	cl
str_skip:
  pop	esi
  jmp	dl_lp1
dl_show_line1:
  pop	esi
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
;dl=end column  dh=screen end column  cl=current column
fill_to_end:
  cmp	cl,dl	;cl=col cl=win end col
  jae	fte_exit ;jmp if at end of win
  cmp	cl,dh	;dh=screen end
  jae	fte_exit ;exit if at end of screen
  mov	al,' ' ;
  stosb
  inc	cl
  jmp	short fill_to_end
fte_exit:
  ret

;-----------------------------------------------------------
 [section .data]

tmp_string_start	dd 0

 [section .text]
