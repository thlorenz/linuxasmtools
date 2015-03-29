
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
;  dword2hexstr - convert one dword to hex ascii and store
; INPUTS
;     ebx = dword of data
;     edi = storage point for hex ascii
; OUTPUT
;    eleven ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: hex2str.asm
;    See also: dword2hexascii
;<
;  * ----------------------------------------------
;*******
  global dword2hexstr
dword2hexstr:
  xor	al,al
  mov	ecx, 8	;loop count
  rol	ebx,4
  call	conv_lp
  ret
;*******
;>1 str_conv
;  word2hexstr - convert one word to hex ascii and store
; INPUTS
;     ebx = word of data
;     edi = storage point for hex ascii
; OUTPUT
;    six ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: hex2str.asm
;    The input word must be in a cleared ebx register
;    See also: word2hexascii
;<
;  * ----------------------------------------------
;*******
  global word2hexstr
word2hexstr:
  xor	al,al
  mov	ecx, 4	;loop count
  rol	ebx,20
  call	conv_lp
  ret
;****f* str_conv/byte2hexstr *
; NAME
;>1 str_conv
;  byte2hexstr - convert one byte to hex ascii and store
; INPUTS
;     ebx = byte of data
;     edi = storage point for hex ascii
; OUTPUT
;    six ascii characters stored at [edi]
;      edi points beyond last stored char.
;      ebx unchanged, eax,ecx modified
; NOTES
;    source file: hex2str.asm
;    The input word must be in a cleared ebx register.
;    See also: word2hexascii
;<
;  * ----------------------------------------------
;*******
  global byte2hexstr
byte2hexstr:
  mov	ecx, 2	;loop count
  rol	ebx,28
;-------------
conv_lp:
  mov	al,bl
  call	nibble2hexstr
  rol	ebx,4
  loop	conv_lp
  ret
;>1 str_conv
;  nibble2hexstr - convert 4-bits to hex ascii and store
; INPUTS
;     al  = hex value
;     edi = storage point for ascii
; OUTPUT
;    one ascii character stored at [edi]
;      edi incremented by one
;      eax is shifted right 3 bits
; NOTES
;    source file: hex2str.asm
;    See also: nibble2hexascii
;<
;  * ----------------------------------------------
;*******
nibble2hexstr:
  and	al,0fh
  add	al,'0'
  cmp	al,'9'
  jle	n_ok
  add	al,"A"-'9'-1
n_ok:
  stosb
  ret
  