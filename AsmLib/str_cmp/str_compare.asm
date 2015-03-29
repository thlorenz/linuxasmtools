
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
;****f* str_cmp/str_compare *
;
; NAME
;>1 str_cmp
;  str_compare - compare two strings, use case
; INPUTS
;    esi = string1
;    edi = string2
;    assumes direction flag set to -cld- forward state
; OUTPUT
;    flags set for je or jne
;    esi & edi point at end of strings if match
; NOTES
;   source file: str_compare.asm
;<
; * ----------------------------------------------
;*******
  global str_compare
str_compare:
	push	ecx
sc_lp:  cmp	byte [esi],0
	je	sc_done1		;jmp if at end of string1
	cmpsb
	je	sc_lp			;continue if matching
	jmp	short sc_exit		;exit with flag set not-equal
sc_done1:
	cmp	byte [edi],0		;if at end of string2 also, then match
sc_exit:
	pop	ecx
	ret
