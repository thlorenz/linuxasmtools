
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

;****f* str_conv/dword_to_r_ascii *
; NAME
;>1 str_conv
;  dword_to_r_ascii - convert bin dword to right just ascii str
; INPUTS
;     eax = binary valuel
;     edi = end of storage area for ascii (decremented)
; OUTPUT
;     edi = ptr to start of ascii string
;     eax,ebx,ecx destroyed
; NOTES
;    source file: dword_to_r_ascii.asm
;<
;  * ----------------------------------------------
;*******
  global dword_to_r_ascii
dword_to_r_ascii:
  push	eax
  or eax,eax
  jns ItoA1
  neg	eax
ItoA1:
  push byte 10
  pop ecx
  std
  xchg eax,ebx
Connum1:
  xchg eax,ebx
  cdq
  div ecx
  xchg eax,ebx
  mov al,dl
  and al,0fh
  add al,'0'
  stosb
  or ebx,ebx
  jne Connum1
  pop	eax
  or	eax,eax
  jns	ita_exit
  mov	al,'-'
  stosb
ita_exit:
  cld
  ret
