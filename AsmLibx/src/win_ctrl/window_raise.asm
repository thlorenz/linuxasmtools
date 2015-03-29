
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
;---------- window_raise ------------------

  extern x_configure_window
  extern x_get_input_focus
;---------------------
;>1 win_ctrl
;  window_raise - raise window to top
; INPUTS
;    eax = window id
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success
;      ecx = id of raised window
;      edx = input id
;      ebx = 0 if in sync             
; NOTES
;   source file: window_raise.asm
;<
; * ----------------------------------------------
  
  global window_raise
window_raise:
  push	eax		;save window id
  mov	ebx,40h		;mask
  mov	esi,wr_list
  call	x_configure_window
  pop	ecx
  js	wr_exit		;exit if error
  push	ecx		;save id
  call	x_get_input_focus
  pop	edx
  js	wr_exit		;exit if error
  mov	ecx,[ecx+8]	;get focused window
wr_exit:
  ret
  [section .data]
wr_list:
  db	0		;lower
  [section .text]
