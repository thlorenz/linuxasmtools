
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
  extern crt_char_at
  extern crt_left_column,data_end_ptr,win_columns,lib_buf

 [section .text]


;****f* crt/color_cursor *
; NAME
;>1 crt
;  color_cursor - place a colored cursor on the screen
; INPUTS
;     eax = cursor color 
;     bh = row
;     bl = column
;     ecx = ptr to data under cursor (display char)
; OUTPUT
;     solid character displayed
; NOTES
;    source file crt_screen.asm
;    data under cursor is expected to be normal ascii
;<
;  * ------------------------------------------------
;*******
  global color_cursor
color_cursor:
  mov	cl,[ecx]		;get char under cursor
  cmp	cl,0ah
  je	cc_x05			;jmp   if 0ah
  cmp	cl,09h			;check if tab
  jne	cc_x10
cc_x05:
  mov	cl,' '
cc_x10:
  call	crt_char_at	;display message
  ret  

;-------------------------------------------------------
;

