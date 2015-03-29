
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
  extern lib_buf
  extern key_string2
  extern kbuf
  extern cursor_to_table
  extern move_cursor
  extern crt_str
  extern left_column,crt_rows,crt_columns
  extern mov_color
;  extern crt_clear

;****f* widget/form *
; NAME
;>1 widget
;  form - display and accept user inputs to fill form
; INPUTS
;    esi = ptr to list of pointers:
;     dd aux_process    ;user process, called after each display
;     dd edit_color     ;colors, list of colors
;     dd string_block1 	;strings, list of string fields on screen
;     dd display_tbl    ;display table, screen format table
;     
;    A form uses one screen.  It is defined by normal ascii
;    text with embedded control characters.  The control characters
;    are:
;     0 - end of table          5 - blank rest of screen
;     1 - color normal          6 - string, block# follows
;     2 - color field           7 - key, key# follows
;     3 - color active field    8 - process, process# follows
;     4 - color button          9 - end of line (eol)
;     
;     
;    As the user types or moves the mouse to fill out the
;    form, all data is stored in the form.  Upon exit the
;    form can be scanned by caller to obtain the data.
;     
;    string data will be stored in the table as entered.
;    button selection is indicated by color code.  When selected
;    the code "3" will indicate this button was selected.
;     
;    table codes use negative byte values in secondary
;    fields, thus, ascii characters in range of 80h+ are not available
;    as text.
; OUTPUT
;    eax = negative error# if problems
;    eax = positive, a return code defined as:
;          0 = unknown key press at kbuf
;          1 = escape pressed
;    see example form file form_samp.asm
; NOTES
;   source file: form.asm
;   see also string_form.asm for a simplier form.
;<
; * ----------------------------------------------
;*******
  [section .text]
  global form
form:
  lodsd				;get color ptr
  mov	[aux_process],eax
  lodsd
  mov	[color_ptr],eax
  lodsd
  mov	[top_str_blk],eax
  mov	[cursor_str_blk],eax
  lodsd
  mov	[table_ptr],eax
form_lp1:
  mov	ecx,[aux_process]	;get optional user process
  jecxz	form_skip
  call	ecx
form_skip:
;  mov	eax,[color_ptr]
;  mov	eax,[eax]		;get color
;  call	crt_clear
  mov	esi,[table_ptr]
  call	display_form
form_lp2:
  mov	ebp,[cursor_str_blk]
  call	key_string2		;output 0=unknown key typed  1=mouse click
  cmp	al,0
  je	key_hit    		;jmp if key event
  cmp	byte [kbuf],-1		;verify this was a mouse event
  jne	form_lp2		;jmp if not mouse event
  mov	al,[kbuf +1 ]		;get mouse button
  mov	[edit_click_button],al	;save mouse button
  mov	cl,[kbuf + 2]		;get mouse column
  mov	ch,[kbuf + 3]		;get mouse row
  mov	[edit_click_column],cl
  mov	[edit_click_row],ch
  mov	esi,[table_ptr]
; esi=table ptr  cl=click column ch=click row
  call	cursor_to_table		;find table location for mouse
; esi = ptr to click with text area
  call	find_table_process	;scan back to find process code
  jmp	el_process
key_hit:    
  call	decode_table_key	;ecx = index or err(0)
el_process:
  jecxz	ml_end2
  call	ecx			;call keyboard or mouse process !!!!
ml_end2:
  or	al,al
  jz	form_lp1		;loop if continue mode
  ret				;return code in -al-

;------------------------------------------------
; input:  [kbuf]
; output: ecx = process ptr or zero
;         esi = ptr to process number (negative)
;
decode_table_key:
  mov	al,[kbuf]
  cmp	al,0dh
  je	dtk_exit_key		;exit if 0dh
  cmp	al,0ah
  je	dtk_exit_key		;exit if 0ah
  cmp	al,1bh
  jne	dtk_15			;jmp if not escaped key
  cmp	byte [kbuf+1],0
  je	dtk_10			;jmp if esc key
  cmp	byte [kbuf + 2],0
  je	dtk_50			;jmp if possible alt key
  cmp	byte [kbuf + 3],0
  je	dtk_20			;jmp if possible arrow key
dtk_exit_key:
  jmp	short dtk_exit1
dtk_10:
  mov	ecx,exit_key
  jmp	short dtk_exit2		;jmp if escape key
;check for debian xterm alt keys
dtk_15:
  cmp	al,0c3h			;special debian xterm alt key
  jne	dtk_exit1		;jmp if unknown key
;we have found a xterm alt key
  mov	al,[kbuf+1]
  sub	al,0a0h
  jmp	short dtk_51		;go search table for key
;
dtk_20:
  mov	al,[kbuf + 2]		;get arrow key code
  mov	ecx,arrow_up
  cmp	al,41h
  je	dtk_exit2		;jmp if up arrow
  cmp	al,78h
  je	dtk_exit2		;jmp if up arrow
  mov	ecx,arrow_down
  cmp	al,42h
  je	dtk_exit2		;jmp if down arrow
  cmp	al,72h
  je	dtk_exit2		;jmp if down arrow
dtk_exit1x:
  jmp	dtk_exit1
;
dtk_50:
  mov	al,[kbuf+1]		;get alt code
  cmp	al,61h
  jb	dtk_exit1		;jmp if out of range
  cmp	al,7ah
  ja	dtk_exit1		;jmp if out of range
  sub	al,60h
dtk_51:
  neg	al			;convert to table code
  mov	ah,al
;
; scan the table for this alt key
;
  mov	esi,[table_ptr]
dtk_55:
  lodsb
  cmp	al,7			;check for key field
  je	dtk_60			;jmp if key field found
  or	al,al
  jnz	dtk_55
  jz	dtk_exit1		;exit if no match
;
dtk_60:
  lodsb
  cmp	al,ah
  jne	dtk_55			;loop if no key match
;
; we have found our key, now get process
;
  lodsb
  cmp	al,8
  jne	dtk_exit1		;jmp if no process specified
dtk_entry:	;------ entered from find_table_process
  xor	eax,eax
  lodsb				;get process number
  neg	al			;convert process number to postive value
  shl	eax,2
  add	eax,process_table -4
  mov	ecx,[eax]
  dec	esi			;point at process#
  jmp	dtk_exit2  
dtk_exit1:
  xor	ecx,ecx
dtk_exit2:
  ret

;------------------------------------------------
; inputs: esi - points at click location inside table
; output: ecx = process
;
find_table_process:
ftp_lp:
  dec	esi
  mov	al,byte [esi-1]		;get previous byte
  cmp	al,8
  ja	ftp_lp			;jmp if not code
  cmp	al,3
  jb	ftp_err
  cmp	al,4
  ja	ftp_err
;we have found color code at left edge of button.
;continue on to process code
fp_lp2:
  dec	esi
  cmp	[esi-1],byte 8
  jne	fp_lp2			;loop till 8 (process code found)
  jmp	dtk_entry
ftp_err:
  xor	eax,eax			;continue flag
  xor	ecx,ecx			;null process
  ret
;------------------------------------------------
process_table:
  dd	tprocess_string	;-1
  dd	tprocess_button	;-2
  dd	tprocess_buttons	;-3
  dd	tnull_process	;-4
  dd	return_code1	;-5
  dd	return_code2	;-6
  dd	return_code3	;-7
  dd	return_code4	;-8
  dd	return_code5	;-9
;------------------------------------------------
exit_key:
  mov	al,1		;exit code
  ret
;------------------------------------------------
; keyboard only process, selects next string.
arrow_up:
  mov	eax,[cursor_str_blk]
  cmp	eax,[top_str_blk]
  je	au_exit
  sub	dword [cursor_str_blk],16	;move cursor up
au_exit:
  xor	eax,eax			;set exit code to continue
  ret

;------------------------------------------------
; keyboard only process, selectes previous string.
arrow_down:
  mov	eax,[cursor_str_blk]
  add	eax,16
  cmp	dword [eax],0
  je	ad_exit
  add	dword [cursor_str_blk],16
ad_exit:
  xor	eax,eax			;set exit code to continue
  ret
;------------------------------------------------
; mouse only process, selects string block
; esi = ptr to table process # for string
;
tprocess_string:
  mov	ecx,esi		;save ptr to current table loc
  mov	ebx,[top_str_blk]	;first string block
  mov	esi,[table_ptr]		;top of table
;
; now count string blocks referenced in the table
;
ts_lp1:
  lodsb
  cmp	al,6		;check if this is string block
  jne	ts_lp1		;loop till string found
ts_lp2:
  lodsb
  cmp	al,8		;is this process code
  jne	ts_lp2		;loop till process found
  cmp	esi,ecx		;are we at match point
  je	ts_set_str
  add	ebx,16		;move to next string block
  jmp	ts_lp1
ts_set_str:
  mov	[cursor_str_blk],ebx
  xor	eax,eax		;set exit code to continue
  ret

;------------------------------------------------
; mouse & keyboard process, esi = ptr to table
;  button color 3 = selected  button color 4 = not selected
tprocess_button:
  inc	esi		;move to color
  xor	byte [esi],7	;toggle color between 2 & 3
  xor	eax,eax		;set exit code to continue
  ret

;------------------------------------------------
; mouse & keyboard process, esi = ptr to table
; only one button on this line can be selected.
;
tprocess_buttons:
  inc	esi		;move forward to color
  mov	ecx,esi		;save ptr to button color
;
; scan to start of line
;
tb_lp1:
  dec	esi
  cmp	byte [esi],9
  jne	tb_lp1		;loop till start of line found
;
; scan forward to next button
;
  lodsb			;move past eol (9)
tb_lp2:
  lodsb
  cmp	al,9		;end of line?
  je	tb_exit		;exit if done
  cmp	al,8		;check for process code
  jne	tb_lp2
  lodsb
  cmp	al,-3		;process_buttons code
  jne	tb_lp2		;loop till button found  
;
; we have found a button, check if it is our button
; 
  cmp	esi,ecx
  je	tb_match
;
; this is not our button, set its color to not selected
;
  mov	byte [esi],4	;force button color
  jmp	tb_lp2
;
; we have found our button, set it to active color
;
tb_match:
  mov	byte [esi],3
  jmp	tb_lp2

tnull_process:
tb_exit:
  xor	eax,eax		;set exit code to continue
  ret

;------------------------------------------------
return_code1:
  mov	al,1
  ret
;------------------------------------------------
return_code2:
  mov	al,2
  ret
;------------------------------------------------
return_code3:
  mov	al,3
  ret
;------------------------------------------------
return_code4:
  mov	al,4
  ret
;------------------------------------------------
return_code5:
  mov	al,5
  ret
;------------------------------------------------
; display the contents table
;  inputs:  esi = ptr to table
;
display_form:
  mov	dh,1			;row
df_next_line:
  mov	edi,lib_buf		;storage buffer
  mov	dl,1			;column
  mov	ecx,[left_column]	;get scroll count
df_lp:
  lodsb
  test	al,80h
  jnz	df_lp			;jmp/ignore special processing codes
  cmp	al,9
  jbe	df_20			;jmp if function found
  jecxz	df_10			;jmp if left column scroll not needed
  dec	ecx
  jmp	short df_lp
df_10:
  stosb				;store data
  inc	dl
  jmp	df_lp
;
; we have found a code in range 0-9
;
df_20:
  cbw				;convert byte to word
  cwde
  shl	eax,2
  add	eax,jtable
  jmp	[eax]

jtable:
  dd	df_90			;0 exit
  dd	df_21			;color1
  dd	df_22			;color2
  dd	df_23			;color3
  dd	df_24			;color4
  dd	df_40			;5 end of display data
  dd	df_lp			;6 ignore strings
  dd	df_lp			;7 ignore key defs
  dd	df_lp			;8 ignore process codes
  dd	df_30			;9 line tail

df_21:
  mov	ebx,[color_ptr]
  mov	ebx,[ebx]		;get normal text color #1
  jmp	df_50			;jmp if color 1
df_22:
  mov	ebx,[color_ptr]
  mov	ebx,[ebx+4]		;get color 2
  jmp	df_50
df_23:
  mov	ebx,[color_ptr]
  mov	ebx,[ebx+8]		;get color 3
  jmp	df_50
df_24:
  mov	ebx,[color_ptr]
  mov	ebx,[ebx+12]		;get color 4
  jmp	df_50
;
; write blanks to end of line, init for next line
;
df_30:
  call	complete_line
  inc	dh			;bump row
  jmp	df_next_line
;
; we are at end of data, fill remaining lines with blanks
;
df_40:
  mov	dl,[crt_rows]
  inc	dl
  cmp	dl,dh
  jbe	df_90			;exit if done
  mov	edi,lib_buf		;storage buffer
  mov	ecx,[left_column]	;get scroll count
  mov	dl,1			;start from column 1
  call	complete_line
  inc	dh
  jmp	df_40
;
; handle colors
;
df_50:
  mov	eax,ebx
  push	edx
  call	mov_color
  pop	edx
  jmp	df_lp
;
df_90:
  ret

;---------------------------------------
; fill blanks to end of screen, display line,  and init for next line
;
complete_line:
  push	edx
;
; write blanks to end of line
;
  mov	al,' '
cl_10:
  cmp	dl,[crt_columns] ;check if at end of line
  ja	cl_20		;jmp if at end
  stosb
  inc	dl
  jmp	short cl_10	;loop till line filled out
cl_20:
  mov	byte [edi],0	;terminate text in lib_buf
  mov	eax,edx
  mov	al,1		;display from column 1
  call	move_cursor
  mov	ecx,lib_buf
  call	crt_str
  pop	edx
  ret

;---------------------------------------------------------

 [section .data]

color_ptr		dd	0	;ptr to colors 1,2,3,4
top_str_blk		dd	0	;ptr to first string block
cursor_str_blk		dd	0	;current block
table_ptr		dd	0	;points at top of table

aux_process		dd	0	;optional process, user supplied

 global edit_click_button,edit_click_row,edit_click_column
edit_click_button	db	0
edit_click_row		db	0
edit_click_column	db	0

 [section .text]
