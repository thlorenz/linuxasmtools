
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
  [section .text]
;****f* str/str_end *
;
; NAME
;>1 str
;  str_end - scan to end of string
; INPUTS
;    esi = pointer to string
; OUTPUT
;    esi points at zero byte (end of string)
; NOTES
;    file str_end.asm
;<
;  * ----------------------------------------------
;*******
  global str_end
str_end:
  lodsb			;get char
  or	al,al
  jnz	str_end
  dec	esi
  ret
