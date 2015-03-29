
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
;****f* str_conv/dword_to_lpadded_ascii *
; NAME
;>1 str_conv
;  dword_to_lpadded_ascii - binary dword to left justified ascii string
;     any zeros at start of string are replaced with pad char.
; INPUTS
;     eax = binary value
;     edi = start of storage area
;     cl  = number of bytes to store
;           pad front to force cl bytes.
;     ch  = pad character
; OUTPUT
;    edi = ptr to end of stored string
;    eax,ebx,ecx destroyed
; NOTES
;    source file: dword_to_lpadded_ascii.asm
;<
;  * ----------------------------------------------
;*******
  global dword_to_lpadded_ascii
dword_to_lpadded_ascii:
  push	byte 10
  pop	ebx		;set ecx=10
dta_recurse:
  xor	edx,edx
  div	ebx
  or	dl,'0'
  push	edx
  dec	cl
  jz	dta_store
  call	dta_recurse
dta_store:
  pop	eax		;get ascii char
  cmp	cl,0		;check if past leading zeros
  jne	dta_cont	;jmp if past leading zeros
  cmp	al,'0'		;end of leading zeros?
  je	dta_pad		;jmp if leading zero
  inc	cl		;set flag - end of pad
  jmp	short dta_cont
dta_pad:
  mov	al,ch		;get pad char
dta_cont:
  stosb
  ret


%ifdef DEBUG

 global main,_start
main:
_start:
  xor	eax,eax
  mov	edi,stuff
  mov	cl,4
  mov	ch,'0'
  call	dword_to_lpadded_ascii

  mov	eax,1
  mov	edi,stuff
  mov	cl,4
  mov	ch,' '
  call	dword_to_lpadded_ascii

  mov	eax,-1
  mov	edi,stuff
  mov	cl,12
  mov	ch,'0'
  call	dword_to_lpadded_ascii
err:
  mov	eax,1
  int	80h

;--------------
  [section .data]
stuff: dd	0,0,0
;--------------
 [section .text]

%endif
