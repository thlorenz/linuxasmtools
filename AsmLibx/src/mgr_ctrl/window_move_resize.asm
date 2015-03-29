
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
;---------- window_move_resize ------------------

  extern x_configure_window
  extern x_get_geometry
  extern x_wm_hints 
;---------------------
;>1 mgr_ctrl
;  window_move_resize - window move/resize 
; INPUTS
;    eax = window id to move/resize
;    esi = ptr to block with:
;          dw new x pixel column
;          dw new y pixel row
;          dw new window width in pixels
;          dw new window height in pixels
; OUTPUT:
;    flag set (jns) if success
;    flag set (js) if err, eax=error code
;
; NOTES
;   source file: window_move_resize.asm
;   To resize our window, assume it is focused at
;   start of execution and get its id with:
;   x_get_input_focus.  
;<
; * ----------------------------------------------

  
  global window_move_resize
window_move_resize:
  push	eax		;save window id
  push	esi		;save list ptr
  mov	ebx,0fh		;mask bits for x,y,width,height
  call	x_configure_window
  pop	esi
  pop	eax

  push	eax
  push	esi
  call	x_wm_hints
  pop	esi
  pop	eax
  js	wmr_exit	;exit if error
  push	esi
  call	x_get_geometry
  pop	esi		;restore value list
  js	wmr_exit	;exit if error
  lea	edi,[ecx+16]	;point at window width (test)
  add	esi,4		;move to window width (request)
  mov	ecx,2
wmr_loop:
  cmpsw
  jne	wmr_err
  dec	ecx
  jnz	wmr_loop
  jmp	short wmr_exit
wmr_err:
  mov	eax,-1
  or	eax,eax
wmr_exit:
  ret
  [section .text]
