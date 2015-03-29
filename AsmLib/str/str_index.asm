
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
;****f* str/str_index *
;
; NAME
;>1 str
;  str_index - index into list of asciiz string
; INPUTS
;    ecx = string number to find, 0=first string
;    esi = pointer to buffer with strings ending
;          with a zero byte.  The end of all strings
;          is another zero byte, thus the table ends
;          with 0,0
; OUTPUT
;    esi points at string found or 0 if not found
; NOTES
;    file str_index.asm
;<
;  * ----------------------------------------------
;*******
  global str_index
str_index:
  jecxz	ms_exit				;exit if first string selected
ms_lp1:
  cmp	byte [esi],0
  jne	ms_lp2
  xor	esi,esi				;indicate not found  
  jmp	short ms_exit
ms_lp2:
  lodsb
  or	al,al
  jnz	ms_lp2	;loop till done
  loop	ms_lp1
ms_exit:
  ret
