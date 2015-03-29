
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
  extern byte_to_hexascii

  [section .text]
;****f* str_conv/dword_to_hexascii *
;
; NAME
;>1 str_conv
;  dword_to_hexascii - binary byte to hex ascii
; INPUTS
;    ecx = binary hex dword
;    edi = ptr to storage area
; OUTPUT
;    edi = ptr to end of stored string
;    (string always contains 8 ascii characters)
; NOTES
;    source file: dword_to_hexascii.asm
;<
;  * ----------------------------------------------
;*******
 global dword_to_hexascii
dword_to_hexascii:
  push	eax
  push	edx
;;  cld
  mov	dl,4		;loop count
dtha_lp:
  rol	ecx,8
  mov	eax,ecx
  and	eax,0ffh	;isolate byte
  call	byte_to_hexascii
  stosw
  dec	dl
  jnz	dtha_lp
  pop	edx
  pop	eax
  ret
