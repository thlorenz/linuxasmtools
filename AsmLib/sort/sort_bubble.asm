
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
;****f* sort/sort_bubble *
; NAME
;>1 sort
;  sort_bubble - bubble sort a list of ptr to text blocks
; INPUTS
;    ebp = ptr to list of record pointers, terminated by zero ptr
; OUTPUT
;    pointer list reordered
; NOTES
;   source file: sort_bubble.asm
;<
; * ----------------------------------------------
;*******
 global sort_bubble
sort_bubble:
;	cld
sn_loop1:
	mov	byte [exchange_flag],0
	mov	ebx,ebp
	add	ebx,4
;
; registers -  ebp - index ptr with lowest name  (esi points at name)
;              ebx - index of challenger         (edi points at challenger name)
;
sn_loop2:
	cmp	dword [ebx],0		;check if done
	je	sn1_done
	mov	esi,[ebp]		;point esi at lowest text string
        mov	edi,[ebx]
        mov	ecx,100			;length of sort
	repe	cmpsb			;check the strings
	jbe	next_challenger
put_on_top:
	mov	eax,[ebp]	;get old lowest
	xchg	eax,[ebx]	;put at challenger's space
	mov	[ebp],eax	;put challenger at top
	mov	byte [exchange_flag],1
next_challenger:
	add	ebx,4
	add	ebp,4
	jmp	sn_loop2
sn1_done:
	cmp	byte [exchange_flag],0
	jne	sn_loop1
sort_exit:	
	ret


  [section .data]
exchange_flag	db	0
  [section .text]
