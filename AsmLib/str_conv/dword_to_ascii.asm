
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
;>1 str_conv
;  byte_to_ascii - convert binary byte to left justified ascii string
; INPUTS
;     al  = binary value
;     edi = start of storage area
; OUTPUT
;    edi = ptr to end of stored string
;    eax,ebx,ecx destroyed
; NOTES
;    source file: dword_to_ascii.asm
;<
;  * ----------------------------------------------
;*******
  global byte_to_ascii
byte_to_ascii:
  xor	ebx,ebx
  mov	bl,al
  mov	eax,ebx
  jmp	short dword_to_ascii

;>1 str_conv
;  word_to_ascii - convert binary word to left justified ascii string
; INPUTS
;      ax = binary value
;     edi = start of storage area
; OUTPUT
;    edi = ptr to end of stored string
;    eax,ebx,ecx destroyed
; NOTES
;    source file: dword_to_ascii.asm
;<
;  * ----------------------------------------------
;*******
  global word_to_ascii
word_to_ascii:
  xor	ebx,ebx
  mov	bx,ax
  mov	eax,ebx
  jmp	short dword_to_ascii

;>1 str_conv
;  dword_to_ascii - convert binary dword to left justified ascii string
; INPUTS
;     eax = binary value
;     edi = start of storage area
; OUTPUT
;    edi = ptr to end of stored string
;    eax,ebx,ecx destroyed
; NOTES
;    source file: dword_to_ascii.asm
;<
;  * ----------------------------------------------
;*******
  global dword_to_ascii
dword_to_ascii:
  push	byte 10
  pop	ecx		;set ecx=10
dta_recurse:
  xor	edx,edx
  div	ecx
  push	edx
  or	eax,eax
  jz	dta_store
  call	dta_recurse
dta_store:
  pop	eax
  or	al,'0'
  stosb
  ret

;---------------------------
%ifdef DEBUG

 global main,_start
main:
_start:
  mov	eax,0
  mov	edi,stuff
  call	dword_to_ascii
  mov	eax,-1
  mov	edi,stuff
  call	dword_to_ascii
err:
  mov	eax,1
  int	80h

;--------------
  [section .data]
stuff: dd	0,0,0
;--------------
 [section .text]

%endif

