
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
;*******
;>1 str_conv
;  dword2octalascii - convert one dword to octal ascii and store
; INPUTS
;     ebx = dword of data
;     edi = storage point for octal ascii
; OUTPUT
;    eleven ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: octal2ascii.asm
;<
;  * ----------------------------------------------
;*******
  global dword2octalascii
dword2octalascii:
  xor	al,al
  mov	ecx, 11	;loop count
  rol	ebx,2
  call	conv_lp
  ret
;*******
;>1 str_conv
;  word2octalascii - convert one word to octal ascii and store
; INPUTS
;     ebx = word of data
;     edi = storage point for octal ascii
; OUTPUT
;    six ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: octal2ascii.asm
;<
;  * ----------------------------------------------
;*******
  global word2octalascii
word2octalascii:
  xor	al,al
  mov	ecx, 6	;loop count
  rol	ebx,17
  call	conv_lp
  ret
;****f* str_conv/byte2octalascii *
; NAME
;>1 str_conv
;  byte2octalascii - convert one byte to octal ascii and store
; INPUTS
;     ebx = byte of data
;     edi = storage point for octal ascii
; OUTPUT
;    six ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: octal2ascii.asm
;    The input word must be in a cleared ebx register.
;<
;  * ----------------------------------------------
;*******
  global byte2octalascii
byte2octalascii:
  mov	ecx, 3	;loop count
  rol	ebx,26
;-------------
conv_lp:
  mov	al,bl
  and	al,07		;isolate octal
  or	al,'0'
  stosb			;store ascii octal
  rol	ebx,3
  loop	conv_lp
  ret
;>1 str_conv
;  nibble2octalascii - convert 3-bits to octal ascii and store
; INPUTS
;     eax = octal value
;     edi = storage point for ascii
; OUTPUT
;    one ascii character stored at [edi]
;      edi incremented by one
;      eax is shifted right 3 bits
; NOTES
;    source file: octal2ascii.asm
;<
;  * ----------------------------------------------
;*******
nibble2octalascii:
  and	al,07h
  add	al,'0'
  stosb			;store ascii octal
  ret
  