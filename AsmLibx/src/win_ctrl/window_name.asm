
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
;---------- window_name ------------------

%include "../../include/window.inc"
  extern x_change_string_property
;---------------------
;>1 win_ctrl
;  window_name - set window name and title
; INPUTS
;  ebp = window block ptr
;  esi = ptr to window name (appears in title)
; OUTPUT:
;    error = sign flag set for js
;    success
;      ebp = window block with following filled in:
;              
; NOTES
;   source file: window_name.asm
;<
; * ----------------------------------------------

  global window_name
window_name:
  mov	eax,[ebp+win.s_win_id]
  mov	ebx,27h			;WM_NAME
;  mov	esi,name_string
  call	x_change_string_property
  ret

