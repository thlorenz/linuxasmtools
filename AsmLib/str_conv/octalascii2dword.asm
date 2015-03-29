
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
;>1 str_conv
;  octalascii2dword - convert asciiz octal string to dword
; INPUTS
;    esi = ptr to octal ascii data
; OUTPUT
;    ebx = contains octal value
; NOTES
;   source file: octalascii2dword.asm
;   This routine is also used to convert a string
;   to a byte or word  value.
;<
; * ----------------------------------------------

  global octalascii2dword
octalascii2dword:
  xor	ebx,ebx		;clear build area
oa_lp:
  lodsb			;get next ascii char
  or	al,al		;end of string?
  jz	oa_done		;jmp if end of string
  shl	ebx,3		;move any accumulate bits
  and	al,7		;isolate low 7 bits 0-7
  or	bl,al		;add to sum
  jmp	short oa_lp	;loop till done
oa_done:
  ret
