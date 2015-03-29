
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
;  quad_compare - unsigned 64 bit compare
; INPUTS
;          ax,bx = first number
;          cx,dx = second number
; OUTPUT:
;           zf (zero flag) = 1 if equal
;           if 1 greater than 2  zf=0 and carry=0
;           if 1 less than 2     zf=0 and carry=1
;           registers are unchanged
; NOTES
;   source file: quad_compare.asm
;<
; * ----------------------------------------------
  global quad_compare
quad_compare:
	cmp	eax,ecx
	jnz	comp64_end
	cmp	ebx,edx
comp64_end:
	ret
