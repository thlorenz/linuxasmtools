
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
;---------- window_write_line ------------------

%ifndef DEBUG
%include "../../include/window.inc"
%endif
  extern x_write_block
;---------------------
;>1 win_text
;  window_write_line - write line at char address
; INPUTS
;  ebp = window block ptr
;  ecx = char column (x location) 0=first col
;  edx = char row (y location) 0=first line
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
;   source file: window_write_line.asm
;<
; * ----------------------------------------------

  global window_write_line
window_write_line:
 push	edx		;save row
 mov	eax,[ebp+win.s_char_width]
; dec	ecx		;make column zero based
 mul	ecx		;compute pixel column
 mov	ecx,eax		;pixel column -> ecx

 pop	eax		;restore row
; dec	eax		;make row zero based
 mul	dword [ebp+win.s_char_height]
 add	eax,[ebp+win.s_char_ascent]
 mov	edx,eax		;pixel row -> edx
 
 mov	eax,[ebp+win.s_win_id]	;window xx00001
 mov	ebx,eax
 inc	ebx		;gc xx00002
;ecx=x loc  edx=y loc  esi=msg  edi=msg len
 call	x_write_block
  ret

