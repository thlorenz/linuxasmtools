
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
;---------- window_lower ------------------

  extern x_configure_window
  extern x_get_input_focus
;---------------------
;>1 win_ctrl
;  window_lower - move window to bottom of stack
; INPUTS
;    eax = window id
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
;    if success
;      ecx = id of top window
;      edx = input id
;      ebx = 0 if in sync             
; NOTES
;   source file: window_lower.asm
;<
; * ----------------------------------------------
  
  global window_lower
window_lower:
  push	eax		;save window id
  mov	ebx,40h		;mask
  mov	esi,wl_list
  call	x_configure_window
  pop	ecx
  js	wl_exit		;exit if error
  push	ecx		;save id
  call	x_get_input_focus
  pop	edx
  js	wl_exit		;exit if error
  mov	ecx,[ecx+8]	;get focused window
wl_exit:
  ret
  [section .data]
wl_list:
  db	1		;below
  [section .text]
