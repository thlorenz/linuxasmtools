
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
;****f* str_conv/hexascii_to_dword *
; NAME
;>1 str_conv
;  hexascii_to_dword - convert up to 8 hexascii to bin
; INPUTS
;    esi = ptr to hex asciiz string
;    (max string length is 8)
; OUTPUT
;    ecx = binary value of hex string
; NOTES
;    source file: hexascii_to_bin.asm
;<
;  * ----------------------------------------------
;*******
 global hexascii_to_dword
hexascii_to_dword:
	push	eax
	push	ebx
	cld
	xor	ebx,ebx		;clear accumulator
ha_loop:
	lodsb
	mov	cl,4
	cmp	al,'a'
	jb	ha_ok1
	sub	al,20h		;convert to upper case if alpha
ha_ok1:	sub	al,'0'		;check if legal
	jc	ha_exit		;jmp if out of range
	cmp	al,9
	jle	ha_got		;jmp if number is 0-9
	sub	al,7		;convert to number from A-F or 10-15
	cmp	al,15		;check if legal
	ja	ha_exit		;jmp if illegal hex char
ha_got:	shl	ebx,cl
	or	bl,al
	jmp	ha_loop
ha_exit:
	mov	ecx,ebx
	pop	ebx		
	pop	eax
	ret	
;****f* str_conv/hexascii_to_byte *
; NAME
;>1 str_conv
;  hexascii_to_byte - convert up to 2 hexascii to bin
; INPUTS
;    esi = ptr to hex asciiz string
;    (max string length is 2)
; OUTPUT
;    al = binary value of hex string if no carry flag
;    if carry flag set the input data is bad
; NOTES
;    source file: hexascii_to_bin.asm
;<
;  * ----------------------------------------------
;*******
  global hexascii_to_byte
hexascii_to_byte:
	cld
	push	ecx
	mov	ch,0
	call	hexascii_to_nibble
	jc	at1_exit	;jmp if conversion error
	call	hexascii_to_nibble
	mov	al,ch
at1_exit:
	pop	ecx
	ret
;****f* str_conv/hexascii_to_nibble *
; NAME
;>1 str_conv
;  hexascii_to_nibble - convert hexascii char to bin
; INPUTS
;    al = contains one hexascii char
;    ch = (accumulator for hex, will be shifted left)
; OUTPUT
;    ch = hex nibble in lower 4 bits
;    if carry flag set the input data is bad
; NOTES
;    source file: hexascii_to_bin.asm
;<
;  * ----------------------------------------------
;*******
  global hexascii_to_nibble
hexascii_to_nibble:
	lodsb
	mov	cl,4
	cmp	al,'a'
	jb	hn_ok1
	sub	al,20h		;convert to upper case if alpha
hn_ok1:	sub	al,'0'		;check if legal
	jc	hn_abort	;jmp if out of range
	cmp	al,9
	jle	hn_got		;jmp if number is 0-9
	sub	al,7		;convert to number from A-F or 10-15
	cmp	al,15		;check if legal
	ja	hn_abort	;jmp if illegal hex char
hn_got:	shl	ch,cl
	or	ch,al
	clc
	jmp	hn_exit
hn_abort:
	stc
hn_exit:		
	ret	

