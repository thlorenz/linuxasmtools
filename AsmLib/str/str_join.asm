
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
;****f* str/str_join *
; NAME
;>1 str
;  str_join - join two strings
; INPUTS
;    edi = string1
;    ebx = string1 length
;    esi = string2
;    edx = string2 length
; OUTPUT
;    edi points at new string
;    ecx is lenght of new string
; NOTES
;   source file: str_join.asm
;<
; * ----------------------------------------------
;*******
 global str_join
str_join:
	push	eax
	push	ebx
	push	edx
	push	esi
	push	edi
	cld
	add	edi,ebx
	mov	ecx,edx
	rep	movsb
	movsb			;pick up zero byte at end
	add	ebx,edx
	mov	ecx,ebx
	pop	edi
	pop	esi
	pop	edx
	pop	ebx
	pop	eax

