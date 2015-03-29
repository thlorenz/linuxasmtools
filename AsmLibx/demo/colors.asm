
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
  extern env_stack
  extern str_move
  extern x_wait_event
  extern x_freegc
  extern socket_fd  
  extern window_pre
  extern window_create
  extern window_color
  extern window_id_color
  extern window_write_line
  extern  window_kill
  extern crt_str
  extern x_check_event
  extern delay
  extern lib_buf
%include "../include/window.inc"

  extern color_id_table
;---------------------
;>1 demo
;  colors - display default AsmLibx colors
; INPUTS
;  none
;
; OUTPUT:
;    colors are display in tabular form
;              
; NOTES
;   source file: /demo/colors.asm
;<
; * ----------------------------------------------

  
  global main,_start
main:
_start:
  cld
  call	env_stack
  mov	ebp,win_block
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  mov	ecx,0		;window color
  mov	ebx,10		;font#
  call	window_pre	;get initial conditions
  jns	win_10
  jmp	error_exit
win_10:
;setup parameters for window_create

  mov	ax,[ebp+win.s_root_width]
  mov	[wc_block+4],ax	;set width
  mov	ax,[ebp+win.s_root_height]
  mov	[wc_block+6],ax	;set height
  mov	esi,wc_block
  call	window_create
  js	error_exit
;check if we are idle
flush1:
  call	x_check_event
  jz	do_writes	;jmp if idle state
  call	x_wait_event
  jmp	short flush1
  jmp	error_exit
do_writes:
  mov	ecx,White		;background color
  mov	ebx,Black		;foreground color
  call	window_color
  js	error_exit

;write a text string to our new window
  mov	ecx,10		;x location,  column
  mov	edx,1		;y location,  row
  mov	esi,title1
  mov	edi,title1_end - title1
  call	window_write_line
  js	error_exit

  mov	ecx,10		;x location,  column
  mov	edx,2		;y location,  row
  mov	esi,title2
  mov	edi,title2_end - title2
  call	window_write_line
  js	error_exit

;setup outer loop
  mov	eax,color_id_table
  mov	[outter_back_color_id],eax
  mov	[outter_back_color_txt_ptr],dword outter_color_table
  mov	[line],dword 4

outter_loop:
;set color for color name at start of line
  mov	ecx,White		;background color
  mov	ebx,Black		;foreground color
  call	window_color
  js	error_exit

;display name of background color for this row
  mov	ecx,dword 1	;x location,  column
  mov	edx,[line]	;y location,  row
  mov	esi,[outter_back_color_txt_ptr] ;get color text
  mov	edi,8
  call	window_write_line
  js	error_exit

;setup for new inner loop
  mov	eax,color_id_table
  mov	[inner_fore_color_id],eax
  mov	[inner_fore_color_txt_ptr],dword inner_color_table
  mov	[column],dword 8

inner_loop:
;change active colors
  mov	ebx,[inner_fore_color_id]
  mov	ebx,[ebx]	;foreground color
  mov	ecx,[outter_back_color_id]
  mov	ecx,[ecx]	;background color
  call	window_id_color
  js	error_exit

  mov	ecx,[column]	;x location,  column
  mov	edx,[line]	;y location,  row
  mov	esi,[inner_fore_color_txt_ptr] ;get color text
  mov	edi,4
  call	window_write_line
  js	error_exit

;inner loop tail
  add	[inner_fore_color_id],dword 4
  add	[inner_fore_color_txt_ptr],dword 4
  add	[column],dword 4
  mov	eax,[inner_fore_color_txt_ptr]
  cmp	[eax],dword 0			;end of inner loop?
  jnz	inner_loop
;outter loop tail
  add	[line],byte 1		;bump line
  add	[outter_back_color_id],dword 4 ;move color id pointer
  add	[outter_back_color_txt_ptr],dword 8 ;move to next color
  mov	eax,[outter_back_color_txt_ptr]
  cmp	[eax],dword 0
  jnz	outter_loop		;loop till all lines shown
  jmp	wrap_up

error_exit:
  mov	ecx,error_msg
  call	crt_str
wrap_up:
  call	x_check_event
  jz	none1
  nop
none1:

  call	x_wait_event
  cmp	byte [lib_buf],0ch	;is this a expose event
  je	wrap_up

  call	window_kill

;000:>:0x0013:32: Reply to GetInputFocus: revert-to=PointerRoot(0x01) focus=0x02e00001
done:
  mov	eax,1
  int	byte 80h

 [section .data]
;------
error_msg: db 0ah,'win create err',0ah,0

font_string: db '10x20',0
white:	     db 'white',0

outter_back_color_id:	dd 0
outter_back_color_txt_ptr: dd 0
line			dd 0

inner_fore_color_id:	dd 0
inner_fore_color_txt_ptr dd 0
column			dd 0


title1: db 'colors for AsmLibx - Press any key to continue'
title1_end:
title2: db '----------------------------------------------'
title2_end:

inner_color_table:
 db 'whit'
 db 'grey'
 db 'skyb'
 db 'blue'
 db 'navy'
 db 'cyan'
 db 'gren'
 db 'yelo'
 db 'gold'
 db 'tan '
 db 'brwn'
 db 'orng'
 db 'red '
 db 'mron'
 db 'pink'
 db 'vlet'
 db 'purp'
 db 'blck'
 dd 0		;end of table

outter_color_table:
 db 'white   '
 db 'grey    '
 db 'skyblue '
 db 'blue    '
 db 'navy    '
 db 'cyan    '
 db 'green   '
 db 'yellow  '
 db 'gold    '
 db 'tan     '
 db 'brown   '
 db 'orange  '
 db 'red     '
 db 'maroon  '
 db 'pink    '
 db 'violet  '
 db 'purple  '
 db 'black   '
 dd 0		;end of table

  [section .bss]
 align 4

win_block: resb win_struc_size

wc_block: resw 1	;x loc
	  resw 1	;y
	  resw 1	;width
	  resw 1	;height

the_buffer: resb 24000
the_buffer_size equ $ - the_buffer
 [section .text]



