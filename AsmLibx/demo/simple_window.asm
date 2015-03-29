
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
  extern crt_str
  extern str_move
  extern x_wait_event
  extern x_get_input_focus
  extern x_freegc
  extern socket_fd  
  extern window_pre
  extern window_create
  extern window_id_color
  extern _white,_black,_skyblue,_maroon
  extern window_font
  extern window_write_pline
  extern window_write_pline
  extern  window_clear
  extern window_kill

%include "../include/window.inc"
;---------------------
;>1 demo
;  simple-window - display window
; INPUTS
;  none
;
; OUTPUT:
;    window with different colors and fonts are
;    displayed
;              
; NOTES
;   source file: /demo/simple-window.asm
;<
; * ----------------------------------------------
  
  global main,_start
main:
_start:
  call	env_stack
  mov	ebp,win_block
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  mov	ebx,10		;font
  mov	ecx,12		;blue	;window background color
  call	window_pre	;get initial conditions
  jns	win_10
  jmp	error_exit
win_10:
  mov	esi,config_list
  call	window_create
  js	error_exit

  mov	ecx,[_white]	;background color
  mov	ebx,[_black]
  call	window_id_color
  js	error_exit

  mov	[ebp+win.s_font],dword 10
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  call	window_font
  js	error_exit

;write a text string to our new window
  mov	ecx,30		;x location,  column
  mov	edx,30		;y location,  row
  mov	esi,string1
  mov	edi,string1_len
  call	window_write_pline
  js	error_exit
;change font
  mov	[ebp+win.s_font],dword 12
  mov	eax,the_buffer
  mov	edx,the_buffer_size
  call	window_font
  js	error_exit
;change active colors
  mov	ecx,[_skyblue]	;background color
  mov	ebx,[_maroon]
  call	window_id_color
  js	error_exit
;write a text string to window
  mov	ecx,30		;column
  mov	edx,70	;row
  mov	esi,string2
  mov	edi,string2_len
  call	window_write_pline

  mov	eax,the_buffer
  mov	edx,the_buffer_size
  mov	[ebp+win.s_font],dword 9
  call	window_font
  js	error_exit
;write another string
  mov	ecx,30		;column
  mov	edx,110	;row
  mov	esi,string3
  mov	edi,string3_len
  call	window_write_pline
  js	error_exit

  jmp	wait_for_event
;
error_exit:
  mov	ecx,err_msg
  call	crt_str
;
; wait for event ----------------------
;
wait_for_event:
;  mov	eax,[socket_fd]
  call	x_wait_event
;
;
;------- close window -----------------
;
  call	window_kill

;000:>:0x0013:32: Reply to GetInputFocus: revert-to=PointerRoot(0x01) focus=0x02e00001
done:
  mov	eax,1
  int	byte 80h


;------
config_list:
  dw 10		;column
  dw 20		;pix row
  dw 300	;width
  dw 300	;height

err_msg: db 0ah,'simple-window error',0ah,0

blue	db 'blue',0

string1: db 'font 10'
string1_len equ $ - string1

string2: db 'font 12'
string2_len equ $ -  string2

string3: db 'font 09'
string3_len equ $ - string3
  
  [section .bss]
 align 4

the_buffer resb 184000
the_buffer_size equ $ - the_buffer

win_block: resb win_struc_size

 [section .text]



