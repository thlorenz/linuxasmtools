
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

	extern	strlen1
;****f* str_cmp/str_match *
;
; NAME
;>1 str_cmp
;  str_match - compare asciiz string to buffer data, use case
; INPUTS
;    esi = string1 (asciiz string)
;    edi = string2 buffer
;    assumes direction flag set to -cld- forward state
; OUTPUT
;    flags set for je or jne
;    esi & edi point at end of strings if match
; NOTES
;   source file: str_match.asm
;<
; * ----------------------------------------------
;*******
  global str_match
str_match:
	push	ecx
	call	strlen1			;find length of string1
	repe	cmpsb
	pop	ecx
	ret
