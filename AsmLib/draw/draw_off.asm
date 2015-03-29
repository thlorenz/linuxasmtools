
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
  extern crt_str

;-----------------------------------------------------
;>1 draw
; draw_off - disable line drawing characters
; inputs:
;    none
; outputs:
;    none
; notes:
;   source file  draw_off.asm
;<
;-----------------------------------------------------------
  global draw_off
draw_off:
  mov	ecx,g0_select
  call	crt_str
  ret
g0_select: db 0fh,0
