
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
;****f* str/str_insert *
; NAME
;>1 str
;  str_insert - inserts string into string
; INPUTS
;    esi = ptr to string1
;    edi = ptr to string 2
;    eax = ptr to insert point in string2
; OUTPUT
;    string1 is inserted into string2
; NOTES
;   source file: srt_insert.asm
;<
; * ----------------------------------------------
;*******
  global str_insert
str_insert:
	call	strlen1		;
	mov	edx,ecx		;save length of string1
	call	strlen2
	mov	ebp,ecx		;save length of string2
;
; make a hole in string2
;
	push	esi		;save string1 start
	add	edi,ebp		;di points at end of string2
	mov	esi,edi		;both si & di point at end of string2
	add	edi,edx		;di points at end of new string
	std
	sub	ecx,eax		;length of move 
	rep	movsb		;make hole, cx=len of string2
;
; ds:si now points at start of hole in string2
; dx= string1 length  bp=string2 length
;
	mov	edi,esi		;di now points at start of hole
	inc	edi
	cld
	pop	esi		;si now points at start of string1
	mov	ecx,edx		;get length of string1
	rep	movsb		;insert string1
	ret
;****f* str/strlen1 *
; NAME
;>1 str
;  strlen1 - get lenght of esi string
; INPUTS
;    esi = pointer to asciiz string
; OUTPUT
;    ecx = lenght of string
;    all registers restored except for ecx
; NOTES
;   source file: srt_insert.asm
;<
; * ----------------------------------------------
;*******
  global strlen1
strlen1:
	push	eax
	push	edi
	cld
	mov	edi,esi
	sub	al,al			;set al=0
	mov	ecx,-1
	repnz	scasb
	not	ecx
	dec	ecx
	pop	edi
	pop	eax
	ret
;****f* str/strlen2 *
; NAME
;>1 str
;  strlen2 - get lenght of edi string
; INPUTS
;    edi = pointer to asciiz string
; OUTPUT
;    ecx = lenght of string
;    all registers restored except ecx
; NOTES
;   source file: srt_insert.asm
;<
; * ----------------------------------------------
;*******
  global strlen2
strlen2:
	push	eax
	push	edi
	cld
	sub	al,al			;set al=0
	mov	ecx,-1
	repnz	scasb
	not	ecx
	dec	ecx
	pop	edi
	pop	eax
	ret
