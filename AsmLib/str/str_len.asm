
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

;****f* str/str_len *
; NAME
;>1 str
;  str_len - find length of asciiz string
; INPUTS
;    esi = input string ptr (asciiz)
; OUTPUT
;    ecx = string length
;    all other registers unchanged.
; NOTES
;  source file: str_len.asm
;<
; * ----------------------------------------------
;*******
  global str_len
str_len:
  push	eax
  push	esi
  mov	ecx,esi
str_lp:
  lodsb
  or	al,al
  jnz	str_lp
  dec	esi
  sub	esi,ecx
  pop	ecx
  xchg	esi,ecx
  pop	eax
  ret
