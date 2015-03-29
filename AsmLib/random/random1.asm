
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
;****f* random/scale_word *
; NAME
;>1 random
;  scale_dword - adjust random number to fit in range
; INPUTS
;    ebx = low value of range
;    ebp = high value of range
;    eax = number to scale
; OUTPUT
;    eax = scalled number
; NOTES
;   source file: random1.asm
;
;         The number is scaled using the formula
;    
;          input value              x
;          ----------- =  -----------------------
;           0ffffh        (high range - low range)
;    
;           scaled number = x + low range
;<
; * ----------------------------------------------
;*******
  global scale_dword
scale_dword:
	push	ecx
	push	edx
	mov	ecx,ebp
	sub	ecx,ebx		;compute range delta
	mul	ecx		;(input value) * (delta)
	mov	eax,edx
      	add	eax,ebx		;result + low range = scaled number
	pop	edx
	pop	ecx
	ret


