
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
;---------- window_write_pline ------------------

%ifndef DEBUG
%include "../../include/window.inc"
  extern x_write_block
%endif
;---------------------
;>1 win_text
;  window_write_pline - write line at pixel address
; INPUTS
;  ebp = window block ptr
;  ecx = x pixel column
;  edx = y pixel row
;  esi = text string to display
;  edi = string length
;
; OUTPUT:
;    error = sign flag set for js
;        eax = negative error code
;    success
;        eax = write count
;              
; NOTES
;   source file: window_write_pline.asm
;<
; * ----------------------------------------------

  global window_write_pline
window_write_pline:
 mov	eax,[ebp+win.s_win_id]	;window xx00001
 mov	ebx,eax
 inc	ebx		;gc xx00002
 call	x_write_block
  ret

