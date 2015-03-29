
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
;****f* date/leap_check *
; NAME
;>1 date
;  leap_check - check for leap year
; INPUTS
;    eax = binary year
; OUTPUT
;    carry set if leap year
;    eax - modified
; NOTES
;   source file: leap_check.asm
;<
; * ----------------------------------------------
;*******
  [section .text]
;
  global leap_check
leap_check:
	push	edx
        push	ecx

	or	eax,eax
 	jz	not_leap	;do not allow divide into zero
;	cmp	eax,400
;	jb	is_exit		;exit if error
	push	eax
	mov	ecx,400
	xor	edx,edx		;clear dx
	div	ecx
	or	edx,edx		;check if centenial leap
	pop	eax
	jz	got_leap	;jmp if leap
	and	eax,3
	jnz	not_leap	;jmp if year not divisable by 4	
	mov	ecx,100
	xor	edx,edx
	div	ecx
	or	edx,edx
	jnz	not_leap	;jmp if not leap
got_leap:
	stc
	jmp	is_exit
not_leap:
	clc
is_exit:
	pop	ecx
        pop	edx
	ret

