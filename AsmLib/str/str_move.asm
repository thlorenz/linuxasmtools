
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
;****f* str/str_move *
;
; NAME
;>1 str
;  str_move - move asciiz string
; INPUTS
;    esi = input string ptr (asciiz)
;    edi = destination ptr
; OUTPUT
;    edi points at zero (end of moved asciiz string)
; NOTES
;    file str_move.asm
;<
;  * ----------------------------------------------
;*******
  global str_move
str_move:
  cld
ms_loop:
  lodsb
  stosb
  or	al,al
  jnz	ms_loop	;loop till done
  dec	edi
  ret
