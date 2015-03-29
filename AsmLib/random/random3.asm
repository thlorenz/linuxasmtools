
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

;****f* random/random_seed *
; NAME
;>1 random
;  random_seed - get low clock bits to use as random number
; INPUTS
;   none
; OUTPUT
;   eax = microseconds counter,
; NOTES
;  source file random3.asm
;<
; * ----------------------------------------------
;*******
  global random_seed
random_seed:
	xor	ecx, ecx	;no time zone record 
	mov	ebx, time_data	;store seconds & microseconds here
	mov	eax,78
	int	80h
	mov	eax,[time_data + 4]	;get microseconds
	ret	

;----------
  [section .data]
time_data dd	0,0
  [section .text]
