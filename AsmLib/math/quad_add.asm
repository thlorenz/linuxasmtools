
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
;
;>1 math
;  quad_add - add 64 bit values
; INPUTS
;    edx,eax = value 1
;    ecx,ebx = value 2
; OUTPUT:
;    edx,eax = result
;           carry set if overflow
; NOTES
;   source file: quad_add.asm
;<
; * ----------------------------------------------
  global quad_add
quad_add:
	add	eax,ebx
	adc	edx,ecx
	ret
