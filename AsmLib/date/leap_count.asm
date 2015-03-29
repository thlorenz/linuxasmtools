
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
;****f* date/leap_count *
; NAME
;>1 date
;  leap_count - count leap years from 1970 till target
; INPUTS
;    eax = binary year (target)
; OUTPUT
;    eax = leap years between 1970 and target, excluding target
; NOTES
;   source file: leap_count.asm
;   note: the input year is not included in totals
;         it is assumed date is jan 1 and leap has
;         not occured yet.
;<
; * ----------------------------------------------
;*******
  [section .text]
;
  global leap_count
leap_count:
	push	edx
        push	ecx
	
	push	eax
	mov	ecx,400
	xor	edx,edx		;clear dx
	div	ecx
	mov	ebx,eax		;save leap count
	pop	eax
	push	eax
        shr	eax,2
	add	ebx,eax		;add years/4
	pop	eax
	test	eax,3		;check if this year is leap
	jnz	lc_10		;jmp if this is not a leap
	dec	ebx		;remove this year from count
lc_10:	
	mov	ecx,100
	xor	edx,edx
	div	ecx
	sub	ebx,eax		;remove number of 100 year increments
	or	edx,edx		;is this year a 100 multiple
	jnz	lc_20
	dec	ebx
lc_20:
	mov	eax,ebx
	sub	eax,477		;number of leaps from 0-1970
	pop	ecx
        pop	edx
	ret

